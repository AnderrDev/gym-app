// Simulación del coach v2 contra un Supabase LOCAL (nunca producción).
//
// Crea un usuario de prueba con una rutina de 2 días con rangos de reps,
// simula ~9 semanas de entrenos con un atleta modelado (fuerza que sube,
// fatiga entre series, una pausa de 18 días, un mal día y un ejercicio
// estancado) y cierra cada sesión con la Edge Function real
// `finalize_workout_session_v1`, que genera el coaching (v2 + v1 en sombra),
// registra `coaching_events` y recalcula `exercise_session_stats`.
//
// Uso (ver README.md de esta carpeta):
//   deno run --allow-net --allow-env scripts/local_coach_sim/simulate.ts
// Variables: API_URL, ANON_KEY, SERVICE_ROLE_KEY (de `supabase status -o env`).
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const API_URL = Deno.env.get("API_URL") ?? "http://127.0.0.1:56321";
const ANON_KEY = Deno.env.get("ANON_KEY") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY") ?? "";

// Credenciales de la cuenta de prueba: SOLO existen en el Supabase local.
export const SIM_EMAIL = "coach.sim@gym.test";
export const SIM_PASSWORD = "CoachSim-Local-2026";

if (!/^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/.test(API_URL)) {
  throw new Error(`Este script solo corre contra un Supabase local, no contra ${API_URL}`);
}
if (!ANON_KEY || !SERVICE_ROLE_KEY) throw new Error("Faltan ANON_KEY / SERVICE_ROLE_KEY");

// ── Atleta y catálogo ───────────────────────────────────────────────────
type Ex = {
  id: string; name: string; muscle: string; movement: "compound" | "isolation";
  region: "upper" | "lower" | "core"; increment: number | null; equipment: string;
  day: "A" | "B"; sets: number; reps: number; repsMax: number | null; weight: number;
  e1rm: number;           // fuerza real inicial (kg); peso corporal: reps máximas
  weeklyGrowth: number;   // fracción por semana (0 = estancado)
};

const EXERCISES: Ex[] = [
  { id: "c0ac0000-0000-4000-8000-000000000001", name: "Press banca barra", muscle: "Pecho", movement: "compound", region: "upper", increment: 2.5, equipment: "Barra olímpica + banco plano", day: "A", sets: 3, reps: 6, repsMax: 8, weight: 80, e1rm: 100, weeklyGrowth: 0.008 },
  { id: "c0ac0000-0000-4000-8000-000000000002", name: "Remo con barra", muscle: "Espalda", movement: "compound", region: "upper", increment: 2.5, equipment: "Barra olímpica", day: "A", sets: 3, reps: 8, repsMax: 10, weight: 65, e1rm: 90, weeklyGrowth: 0.008 },
  { id: "c0ac0000-0000-4000-8000-000000000003", name: "Press inclinado mancuernas", muscle: "Pecho", movement: "compound", region: "upper", increment: 2, equipment: "Mancuernas + banco inclinado", day: "A", sets: 3, reps: 8, repsMax: 12, weight: 32, e1rm: 46, weeklyGrowth: 0.006 },
  { id: "c0ac0000-0000-4000-8000-000000000004", name: "Curl martillo", muscle: "Bíceps", movement: "isolation", region: "upper", increment: 2, equipment: "Mancuernas", day: "A", sets: 3, reps: 10, repsMax: 12, weight: 14, e1rm: 19, weeklyGrowth: 0 },
  { id: "c0ac0000-0000-4000-8000-000000000005", name: "Fondos", muscle: "Tríceps", movement: "compound", region: "upper", increment: null, equipment: "Paralelas (peso corporal)", day: "A", sets: 3, reps: 8, repsMax: 12, weight: 0, e1rm: 11, weeklyGrowth: 0.03 },
  { id: "c0ac0000-0000-4000-8000-000000000006", name: "Sentadilla libre", muscle: "Piernas", movement: "compound", region: "lower", increment: 2.5, equipment: "Barra olímpica + rack", day: "B", sets: 3, reps: 5, repsMax: 8, weight: 95, e1rm: 120, weeklyGrowth: 0.01 },
  { id: "c0ac0000-0000-4000-8000-000000000007", name: "Prensa de piernas", muscle: "Piernas", movement: "compound", region: "lower", increment: 5, equipment: "Máquina prensa inclinada 45°", day: "B", sets: 3, reps: 10, repsMax: 12, weight: 160, e1rm: 220, weeklyGrowth: 0.01 },
  { id: "c0ac0000-0000-4000-8000-000000000008", name: "Curl femoral", muscle: "Piernas", movement: "isolation", region: "lower", increment: 2.5, equipment: "Máquina de curl femoral", day: "B", sets: 3, reps: 10, repsMax: 15, weight: 40, e1rm: 58, weeklyGrowth: 0.005 },
];

// Días desde el inicio (hace 62 días). Tras el día 32 hay una pausa de 18
// días; el día 57 es un "mal día" (fuerza −10 % solo esa sesión).
export const DEFAULT_SCHEDULE = [0, 2, 4, 7, 9, 11, 14, 16, 18, 21, 23, 25, 28, 30, 32, 50, 52, 54, 57, 59, 61];
const DETRAINING = 0.95;

export type SimOptions = {
  email?: string;
  /** Días (desde el inicio) en los que entrena; el último debe ser ≤ hoy. */
  schedule?: number[];
  /** Día con fuerza −10 % (null = ninguno). */
  badDay?: number | null;
  /** A partir de este día, fuerza −5 % (null = sin pérdida por pausa). */
  layoffAfter?: number | null;
  seed?: number;
  /** Espera entre cierres: el rate limit de finalize y de coaching es 30/min por usuario. */
  paceMs?: number;
  quiet?: boolean;
};

// PRNG determinista (mulberry32): cada ejecución con la misma semilla da lo mismo.
function makeRand(seed: number) {
  let s = seed;
  return () => {
    s |= 0; s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const daysBetween = (a: string, b: string) => Math.round((Date.parse(b) - Date.parse(a)) / 86_400_000);

// Mismo ajuste por pausa que get_next_targets_v1, pero con la fecha simulada.
function layoffAdjust(weight: number, days: number, step: number): number {
  if (days < 21 || weight === 0) return weight;
  const f = days < 28 ? 0.95 : days < 56 ? 0.90 : 0.80;
  return Math.max(0, Math.round((weight * f) / step) * step);
}

// ── Preparación ──────────────────────────────────────────────────────────
async function setup(admin: SupabaseClient, email: string) {
  // Usuario de prueba (se recrea en cada ejecución: borra su historial).
  const { data: list } = await admin.auth.admin.listUsers({ perPage: 1000 });
  const old = list?.users.find((u) => u.email === email);
  if (old) await admin.auth.admin.deleteUser(old.id);
  const { data: created, error } = await admin.auth.admin.createUser({
    email, password: SIM_PASSWORD, email_confirm: true,
    user_metadata: { full_name: "Atleta Simulado" },
  });
  if (error || !created.user) throw error ?? new Error("No se creó el usuario");
  const userId = created.user.id;
  await admin.from("profiles").upsert({ id: userId, full_name: "Atleta Simulado" });

  const must = (r: { error: unknown }, what: string) => { if (r.error) throw new Error(`${what}: ${JSON.stringify(r.error)}`); };
  must(await admin.from("exercises").upsert(EXERCISES.map((e) => ({
    id: e.id, name: e.name, muscle_group: e.muscle, equipment: e.equipment,
    movement_type: e.movement, body_region: e.region, load_increment_kg: e.increment,
  }))), "ejercicios");
  // Rutina propia de cada usuario de prueba.
  const routineId = crypto.randomUUID();
  const dayIds = { A: crypto.randomUUID(), B: crypto.randomUUID() };
  must(await admin.from("routines").insert({ id: routineId, name: "Coach sim · Torso / Pierna", creator_id: userId, is_public: false }), "rutina");
  must(await admin.from("routine_days").insert([
    { id: dayIds.A, routine_id: routineId, day_of_week: 1, name: "Torso" },
    { id: dayIds.B, routine_id: routineId, day_of_week: 2, name: "Pierna" },
  ]), "días");
  must(await admin.from("routine_exercises").insert(EXERCISES.map((e, i) => ({
    routine_day_id: dayIds[e.day], exercise_id: e.id, order: i, target_sets: e.sets,
    target_reps: e.reps, target_reps_max: e.repsMax, target_weight: e.weight, rest_timer_seconds: 120,
  }))), "objetivos");
  must(await admin.from("user_routines").upsert({ user_id: userId, routine_id: routineId }), "asignación");
  return { userId, dayIds };
}

// ── Simulación ───────────────────────────────────────────────────────────
type Row = { day: number; date: string; dayName: string; lines: string[] };

export async function simulate(opts: SimOptions = {}) {
  const email = opts.email ?? SIM_EMAIL;
  const schedule = opts.schedule ?? DEFAULT_SCHEDULE;
  const badDay = opts.badDay === undefined ? 57 : opts.badDay;
  const layoffAfter = opts.layoffAfter === undefined ? 32 : opts.layoffAfter;
  const rand = makeRand(opts.seed ?? 20261024);
  const noise = () => (rand() < 0.2 ? -1 : rand() > 0.85 ? 1 : 0);
  const log = opts.quiet ? () => {} : console.log;

  const admin = createClient(API_URL, SERVICE_ROLE_KEY, { auth: { persistSession: false } });
  const { userId, dayIds } = await setup(admin, email);
  const user = createClient(API_URL, ANON_KEY, { auth: { persistSession: false } });
  const { data: auth, error: authError } = await user.auth.signInWithPassword({ email, password: SIM_PASSWORD });
  if (authError || !auth.session) throw authError ?? new Error("Sin sesión");
  const token = auth.session.access_token;

  const span = schedule[schedule.length - 1] + 1;
  const start = new Date(); start.setUTCDate(start.getUTCDate() - span);
  const report: Row[] = [];
  const finalizeMs: number[] = [];
  let alternate = 0;

  for (const offset of schedule) {
    const date = new Date(start); date.setUTCDate(start.getUTCDate() + offset);
    const sessionDate = isoDate(date);
    const day: "A" | "B" = alternate++ % 2 === 0 ? "A" : "B";
    const weeks = offset / 7;
    const strengthFactor = (layoffAfter != null && offset > layoffAfter ? DETRAINING : 1) * (offset === badDay ? 0.9 : 1);

    // 1. Sesión abierta y su plan congelado (como el cliente).
    const { data: session, error: sErr } = await user.from("workout_sessions")
      .insert({ user_id: userId, routine_day_id: dayIds[day], session_date: sessionDate }).select("id").single();
    if (sErr || !session) throw new Error(`sesión ${sessionDate}: ${JSON.stringify(sErr)}`);
    const { data: plan, error: pErr } = await user.rpc("get_session_exercises_v1", { p_session_id: session.id });
    if (pErr) throw new Error(`plan: ${pErr.message}`);

    const row: Row = { day: offset, date: sessionDate, dayName: day === "A" ? "Torso" : "Pierna", lines: [] };
    for (const entry of plan as Array<Record<string, unknown>>) {
      const ex = EXERCISES.find((e) => e.id === entry.id)!;
      // 2. Sugerencia vigente del motor v2 (la más reciente con peso).
      const { data: last } = await admin.from("coaching_events")
        .select("suggested_weight, suggested_reps, reason_code, workout_sessions!coaching_events_session_id_fkey(session_date)")
        .eq("user_id", userId).eq("exercise_id", ex.id).eq("engine_version", "2.0")
        .not("suggested_weight", "is", null).order("created_at", { ascending: false }).limit(1);
      const sug = last?.[0] as { suggested_weight: number; suggested_reps: number | null; reason_code: string; workout_sessions: { session_date: string } } | undefined;
      const targetWeight = Number(entry.target_weight ?? 0);
      const repsMax = Math.max(Number(entry.target_reps_max ?? entry.target_reps), Number(entry.target_reps));
      let weight = targetWeight;
      let note = "objetivo";
      if (sug) {
        const gap = daysBetween(sug.workout_sessions.session_date, sessionDate);
        weight = layoffAdjust(Number(sug.suggested_weight), gap, ex.increment ?? 2.5);
        note = `coach ${sug.reason_code}${gap >= 14 ? ` (pausa ${gap} d)` : ""}`;
      }
      const aim = Math.max(repsMax, Number(sug?.suggested_reps ?? 0));

      // 3. El atleta hace sus series: fuerza real, fatiga y algo de ruido.
      const e1rm = ex.e1rm * (1 + ex.weeklyGrowth * weeks) * strengthFactor;
      const reps: number[] = [];
      for (let i = 0; i < ex.sets; i++) {
        const fatigue = Math.round(i * 0.8);
        const possible = weight > 0 ? Math.floor(30 * (e1rm / weight - 1)) : Math.floor(e1rm);
        reps.push(Math.max(1, Math.min(aim, possible - fatigue + noise())));
      }
      const { error: lErr } = await user.from("set_logs").insert(reps.map((r, i) => ({
        session_id: session.id, exercise_id: ex.id, set_index: i + 1, actual_weight: weight, actual_reps: r,
      })));
      if (lErr) throw new Error(`series ${ex.name}: ${lErr.message}`);
      row.lines.push(`${ex.name.padEnd(27)} ${String(weight).padStart(5)} kg × ${reps.join("/")}  ← ${note}`);
    }

    // 4. Cierre real: Edge Function con el JWT del usuario.
    const t0 = performance.now();
    const res = await fetch(`${API_URL}/functions/v1/finalize_workout_session_v1`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, apikey: ANON_KEY, "Content-Type": "application/json" },
      body: JSON.stringify({ session_id: session.id }),
    });
    const body = await res.json();
    finalizeMs.push(performance.now() - t0);
    if (!res.ok || body.data?.warning_code) throw new Error(`finalize ${sessionDate}: ${res.status} ${JSON.stringify(body)}`);
    report.push(row);
    await new Promise((r) => setTimeout(r, opts.paceMs ?? 400));
  }

  for (const r of report) {
    log(`\n${r.date} (día ${r.day}) · ${r.dayName}`);
    for (const l of r.lines) log(`  ${l}`);
  }

  // 5. Lo que verá la app hoy: la RPC real, como el usuario.
  const { data: next, error: nErr } = await user.rpc("get_next_targets_v1", { p_exercise_ids: EXERCISES.map((e) => e.id) });
  if (nErr) throw new Error(`get_next_targets_v1: ${nErr.message}`);
  log("\nPróximo entreno (get_next_targets_v1, como el usuario):");
  for (const n of next as Array<Record<string, unknown>>) {
    const ex = EXERCISES.find((e) => e.id === n.exercise_id)!;
    log(`  ${ex.name.padEnd(27)} ${n.suggested_weight} kg × ${n.suggested_reps ?? "-"}  ${n.reason_code}  (hace ${n.days_since} d)`);
  }
  log(`\nUsuario de prueba: ${email} (id ${userId}) · contraseña en scripts/local_coach_sim/README.md`);
  return { userId, token, finalizeMs, exerciseIds: EXERCISES.map((e) => e.id) };
}

if (import.meta.main) await simulate();
