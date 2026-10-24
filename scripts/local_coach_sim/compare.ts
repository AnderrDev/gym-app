// Compara variantes del motor v2 con los mismos atletas simulados (mismas
// semillas). Uso: deno run --allow-read scripts/local_coach_sim/compare.ts [atletas]
import { analyzeSessionV2, type EngineOptions } from "../../supabase/functions/generate_coaching_v1/engine_v2.ts";
import { LAYOFF_PROD, LAYOFF_V1, type LayoffTable, type Metrics, PROFILES, runScenarios } from "./scenarios.ts";

const athletes = Number(Deno.args[0] ?? 200);
// "antes" = motor y tabla de pausa previos al banco (2026-10-24).
const BEFORE: EngineOptions = { singleTarget: "immediate", plateau: "e1rm" };

const VARIANTS: Array<{ key: string; label: string; options: EngineOptions; layoff: LayoffTable }> = [
  { key: "antes", label: "Motor y pausa previos al banco", options: BEFORE, layoff: LAYOFF_V1 },
  { key: "top_set", label: "antes + rango completado = 1.ª serie en el máximo, resto ≤1 rep (descartada)", options: { ...BEFORE, progression: "top_set" }, layoff: LAYOFF_V1 },
  { key: "confirm", label: "antes + sin rango: confirmar 2 sesiones antes de subir", options: { ...BEFORE, singleTarget: "confirm" }, layoff: LAYOFF_V1 },
  { key: "pausa_suave", label: "antes + pausa: 21–27 d −5 %, 28–55 −10 %, ≥56 −20 %", options: BEFORE, layoff: LAYOFF_PROD },
  { key: "plateau", label: "antes + estancamiento solo si ni carga ni reps suben en 4 sesiones", options: { ...BEFORE, plateau: "load_and_reps" }, layoff: LAYOFF_V1 },
  { key: "ahora", label: "Valores por defecto actuales (confirm + pausa suave + plateau)", options: {}, layoff: LAYOFF_PROD },
];

const results = new Map<string, Metrics[]>();
for (const v of VARIANTS) {
  results.set(v.key, runScenarios((inputs) => analyzeSessionV2(inputs, v.options), athletes, PROFILES, v.layoff));
}

const cols: Array<[string, (m: Metrics) => number, (x: number) => string, "up" | "down" | "one"]> = [
  ["acierto", (m) => m.hitWhenFollowed, (x) => `${(x * 100).toFixed(1)}%`, "up"],
  ["fallos", (m) => m.failRate, (x) => `${(x * 100).toFixed(1)}%`, "down"],
  ["captura", (m) => m.progressCapture, (x) => (Number.isFinite(x) ? x.toFixed(2) : "—"), "one"],
  ["carga/ideal", (m) => m.loadTracking, (x) => x.toFixed(2), "one"],
  ["vaivenes/10", (m) => m.reversalsPer10, (x) => x.toFixed(2), "down"],
  ["imposibles", (m) => m.impossibleRate, (x) => `${(x * 100).toFixed(1)}%`, "down"],
  ["avisos de estancamiento", (m) => (m.reasons.PLATEAU ?? 0) / (m.sessions * 6), (x) => `${(x * 100).toFixed(1)}%`, "down"],
];

for (const [name, get, fmt] of cols) {
  console.log(`\n## ${name}`);
  console.log(["perfil", ...VARIANTS.map((v) => v.key)].join(" | "));
  for (let i = 0; i < PROFILES.length; i++) {
    console.log([PROFILES[i].key, ...VARIANTS.map((v) => fmt(get(results.get(v.key)![i])))].join(" | "));
  }
}
console.log("\nVariantes:");
for (const v of VARIANTS) console.log(`  ${v.key}: ${v.label}`);
