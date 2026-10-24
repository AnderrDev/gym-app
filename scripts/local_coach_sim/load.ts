// Carga de volumen contra el Supabase LOCAL: muchos usuarios a la vez y un
// atleta con un año de historial, todo por el camino real (PostgREST + Edge
// Functions). Mide latencias de cierre y de las lecturas del coach.
//
//   deno run --allow-net --allow-env scripts/local_coach_sim/load.ts [usuarios] [semanas_del_veterano]
import { createClient } from "npm:@supabase/supabase-js@2";
import { simulate } from "./simulate.ts";

const API_URL = Deno.env.get("API_URL") ?? "http://127.0.0.1:56321";
const ANON_KEY = Deno.env.get("ANON_KEY") ?? "";
const users = Number(Deno.args[0] ?? 20);
const veteranWeeks = Number(Deno.args[1] ?? 52);

const pct = (xs: number[], p: number) => {
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))];
};
const fmt = (xs: number[]) => `p50 ${pct(xs, 50).toFixed(0)} ms · p95 ${pct(xs, 95).toFixed(0)} ms · máx ${Math.max(...xs).toFixed(0)} ms (n=${xs.length})`;

// 1. Veterano: 3 sesiones/semana durante un año (pausa de 2 semanas en verano).
const veteranSchedule: number[] = [];
for (let w = 0; w < veteranWeeks; w++) {
  if (w >= 30 && w < 32) continue;
  veteranSchedule.push(w * 7, w * 7 + 2, w * 7 + 4);
}
const t0 = performance.now();
const veteran = simulate({
  email: "coach.sim.veterano@gym.test", schedule: veteranSchedule, badDay: null, layoffAfter: null,
  seed: 777, paceMs: 2100, quiet: true,
});

// 2. Muchos usuarios a la vez (concurrencia 10), ~9 semanas cada uno.
const crowd: Array<Awaited<ReturnType<typeof simulate>>> = [];
const queue = Array.from({ length: users }, (_, i) => i);
async function worker() {
  for (let i = queue.shift(); i != null; i = queue.shift()) {
    crowd.push(await simulate({ email: `coach.sim+${i}@gym.test`, seed: 5000 + i, paceMs: 400, quiet: true }));
  }
}
await Promise.all(Array.from({ length: 10 }, worker));
const crowdDone = performance.now();
const vet = await veteran;
const vetDone = performance.now();

console.log(`Usuarios simultáneos: ${users} × ${crowd[0]?.finalizeMs.length ?? 0} sesiones en ${((crowdDone - t0) / 1000).toFixed(0)} s`);
console.log(`  finalize: ${fmt(crowd.flatMap((c) => c.finalizeMs))}`);
console.log(`Veterano: ${vet.finalizeMs.length} sesiones en ${((vetDone - t0) / 1000).toFixed(0)} s`);
console.log(`  finalize (todas): ${fmt(vet.finalizeMs)}`);
console.log(`  finalize (últimas 20, historial largo): ${fmt(vet.finalizeMs.slice(-20))}`);

// 3. Lecturas de la app con el historial del veterano.
const client = createClient(API_URL, ANON_KEY, {
  auth: { persistSession: false },
  global: { headers: { Authorization: `Bearer ${vet.token}` } },
});
const nextMs: number[] = [];
for (let i = 0; i < 20; i++) {
  const t = performance.now();
  const { error } = await client.rpc("get_next_targets_v1", { p_exercise_ids: vet.exerciseIds });
  if (error) throw error;
  nextMs.push(performance.now() - t);
}
console.log(`  get_next_targets_v1: ${fmt(nextMs)}`);

const { data: last } = await client.from("workout_sessions").select("id").eq("user_id", vet.userId)
  .not("completed_at", "is", null).order("session_date", { ascending: false }).limit(1).single();
const inputsMs: number[] = [];
for (let i = 0; i < 20; i++) {
  const t = performance.now();
  const { error } = await client.rpc("get_coaching_inputs_v2", { p_user_id: vet.userId, p_session_id: last!.id });
  if (error) throw error;
  inputsMs.push(performance.now() - t);
}
console.log(`  get_coaching_inputs_v2: ${fmt(inputsMs)}`);
console.log(`\nVeterano: ${vet.userId} · última sesión ${last!.id}`);
