// Banco de escenarios del coach v2: cientos de atletas simulados por perfil,
// ejecutando el motor real (`engine_v2.ts`) sin base de datos. Reproduce la
// semántica del servidor: historial = filas de `exercise_session_stats` de
// las ≤6 exposiciones cerradas anteriores; sugerencia vigente = la última con
// peso, con el ajuste por pausa de `get_next_targets_v1`.
//
//   deno run --allow-read scripts/local_coach_sim/scenarios.ts [atletas_por_perfil]
//
// El motor se puede sustituir (p. ej. una variante candidata) con
// `runScenarios(engine)` para comparar antes/después con las mismas semillas.
import {
  analyzeSessionV2,
  type CoachingInputsV2,
  type CoachingItemV2,
  type HistoryRow,
} from "../../supabase/functions/generate_coaching_v1/engine_v2.ts";

export type Engine = (inputs: CoachingInputsV2) => CoachingItemV2[];

// ── Aleatoriedad determinista ────────────────────────────────────────────
function rng(seed: number) {
  let s = seed | 0;
  const next = () => {
    s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  const normal = () => {
    const u = Math.max(next(), 1e-9), v = next();
    return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
  };
  return { next, normal };
}

// ── Ejercicios tipo ──────────────────────────────────────────────────────
type Archetype = {
  key: string; name: string; movement: "compound" | "isolation"; region: "upper" | "lower" | "core";
  increment: number | null; sets: number; min: number; max: number; e1rm: number; bodyweight?: boolean;
};

const ARCHETYPES: Archetype[] = [
  { key: "banca", name: "Press banca", movement: "compound", region: "upper", increment: 2.5, sets: 3, min: 6, max: 8, e1rm: 90 },
  { key: "sentadilla", name: "Sentadilla", movement: "compound", region: "lower", increment: 2.5, sets: 3, min: 5, max: 8, e1rm: 120 },
  { key: "prensa", name: "Prensa", movement: "compound", region: "lower", increment: 5, sets: 3, min: 10, max: 12, e1rm: 220 },
  { key: "inclinado_mancuernas", name: "Inclinado mancuernas", movement: "compound", region: "upper", increment: 2, sets: 3, min: 8, max: 12, e1rm: 44 },
  { key: "elevacion_lateral", name: "Elevación lateral", movement: "isolation", region: "upper", increment: 2, sets: 3, min: 12, max: 15, e1rm: 14 },
  { key: "dominadas", name: "Dominadas", movement: "compound", region: "upper", increment: null, sets: 3, min: 6, max: 10, e1rm: 10, bodyweight: true },
];

// ── Perfiles de atleta ───────────────────────────────────────────────────
export type Profile = {
  key: string;
  label: string;
  weeks: number;
  /** Crecimiento de fuerza por semana (fracción), con ruido entre atletas. */
  growth: [number, number];
  /** Variabilidad día a día de la fuerza (desviación típica, fracción). */
  dayNoise: number;
  /** Caída de reps por serie (fatiga). */
  fatigue: [number, number];
  /** "cap": para en el máximo del rango; "amrap": hace todas las que puede. */
  behavior: "cap" | "amrap";
  /** Probabilidad de usar el peso que sugiere el coach. */
  compliance: number;
  /** Si no sigue al coach: incrementos que suma por ego (0 = repite su último peso). */
  ego: number;
  /** Rango de reps de la rutina o un solo objetivo (el mínimo). */
  rangeMode: "range" | "single";
  /** Peso inicial de la rutina respecto al ideal para el mínimo de reps. */
  startCalibration: [number, number];
  /** Días entre sesiones: fijo (L-X-V) o irregular. */
  attendance: "regular" | "irregular";
  /** Pausa larga: [semana de inicio, días]. */
  layoff?: [number, number];
  /** Bajada real de fuerza: [semana de inicio, semanas, caída total]. */
  regression?: [number, number, number];
};

export const PROFILES: Profile[] = [
  { key: "novato", label: "Novato (gana rápido, mucho ruido)", weeks: 16, growth: [0.02, 0.035], dayNoise: 0.05, fatigue: [0.8, 1.4], behavior: "cap", compliance: 0.95, ego: 0, rangeMode: "range", startCalibration: [0.75, 0.95], attendance: "regular" },
  { key: "intermedio", label: "Intermedio (progreso típico)", weeks: 16, growth: [0.005, 0.012], dayNoise: 0.035, fatigue: [0.6, 1.1], behavior: "cap", compliance: 0.95, ego: 0, rangeMode: "range", startCalibration: [0.9, 1.0], attendance: "regular" },
  { key: "avanzado", label: "Avanzado (progreso lento)", weeks: 16, growth: [0.001, 0.004], dayNoise: 0.03, fatigue: [0.5, 0.9], behavior: "cap", compliance: 0.95, ego: 0, rangeMode: "range", startCalibration: [0.95, 1.0], attendance: "regular" },
  { key: "estancado", label: "Estancado (sin ganancia)", weeks: 16, growth: [0, 0], dayNoise: 0.03, fatigue: [0.6, 1.0], behavior: "cap", compliance: 0.95, ego: 0, rangeMode: "range", startCalibration: [0.95, 1.0], attendance: "regular" },
  { key: "regresion", label: "Regresión real (enfermedad: −12 % en 4 semanas)", weeks: 16, growth: [0.006, 0.01], dayNoise: 0.03, fatigue: [0.6, 1.0], behavior: "cap", compliance: 0.95, ego: 0, rangeMode: "range", startCalibration: [0.9, 1.0], attendance: "regular", regression: [6, 4, 0.12] },
  { key: "pausa", label: "Pausa de 5 semanas a mitad", weeks: 20, growth: [0.006, 0.01], dayNoise: 0.035, fatigue: [0.6, 1.0], behavior: "cap", compliance: 0.95, ego: 0, rangeMode: "range", startCalibration: [0.9, 1.0], attendance: "regular", layoff: [8, 35] },
  { key: "irregular", label: "Asistencia irregular (2–20 días entre sesiones)", weeks: 16, growth: [0.006, 0.01], dayNoise: 0.035, fatigue: [0.6, 1.0], behavior: "cap", compliance: 0.95, ego: 0, rangeMode: "range", startCalibration: [0.9, 1.0], attendance: "irregular" },
  { key: "amrap", label: "Va al fallo (no para en el máximo)", weeks: 16, growth: [0.005, 0.012], dayNoise: 0.035, fatigue: [0.8, 1.3], behavior: "amrap", compliance: 0.95, ego: 0, rangeMode: "range", startCalibration: [0.9, 1.0], attendance: "regular" },
  { key: "no_sigue", label: "Sigue al coach la mitad de las veces", weeks: 16, growth: [0.005, 0.012], dayNoise: 0.035, fatigue: [0.6, 1.1], behavior: "cap", compliance: 0.5, ego: 0, rangeMode: "range", startCalibration: [0.9, 1.0], attendance: "regular" },
  { key: "ego", label: "Ego: sube un incremento cuando no sigue al coach", weeks: 16, growth: [0.005, 0.012], dayNoise: 0.035, fatigue: [0.6, 1.1], behavior: "cap", compliance: 0.5, ego: 1, rangeMode: "range", startCalibration: [0.9, 1.0], attendance: "regular" },
  { key: "sin_rango", label: "Rutina sin rango (un solo objetivo de reps)", weeks: 16, growth: [0.005, 0.012], dayNoise: 0.035, fatigue: [0.6, 1.1], behavior: "cap", compliance: 0.95, ego: 0, rangeMode: "single", startCalibration: [0.9, 1.0], attendance: "regular" },
  { key: "mal_calibrado", label: "Rutina con peso inicial muy alto (+20 %)", weeks: 16, growth: [0.005, 0.012], dayNoise: 0.035, fatigue: [0.6, 1.1], behavior: "cap", compliance: 0.95, ego: 0, rangeMode: "range", startCalibration: [1.15, 1.25], attendance: "regular" },
];

// ── Métricas ─────────────────────────────────────────────────────────────
export type Metrics = {
  profile: string;
  label: string;
  sessions: number;
  /** Sugerencias seguidas en las que la vez siguiente se cumplieron series y reps mínimas. */
  hitWhenFollowed: number;
  /** Exposiciones con alguna serie por debajo del mínimo. */
  failRate: number;
  /** Carga de trabajo / carga ideal para el mínimo de reps (al final). 1 = exacto. */
  loadTracking: number;
  /** Ganancia de carga / ganancia de fuerza real (al final). 1 = la carga sigue a la fuerza. */
  progressCapture: number;
  /** Bajadas de carga por cada 10 exposiciones. */
  decreasesPer10: number;
  /** Cambios de dirección (sube→baja o baja→sube) por cada 10 exposiciones. */
  reversalsPer10: number;
  /** Racha máxima de bajadas seguidas. */
  maxDropStreak: number;
  /** Mayor subida sugerida de una vez (%). */
  maxJumpPct: number;
  /** Exposiciones en que el coach sugirió una carga imposible para el mínimo de reps ese día. */
  impossibleRate: number;
  /** Sesiones desde el inicio de la regresión hasta la primera bajada (solo perfil "regresion"). */
  regressionLag: number | null;
  reasons: Record<string, number>;
};

type ExerciseState = {
  arch: Archetype;
  id: string;
  e1rmBase: number;
  growth: number;
  fatigue: number;
  min: number;
  max: number | null;
  routineWeight: number;
  history: HistoryRow[];
  lastWeight: number | null;
  last: { item: CoachingItemV2; date: string } | null;
  pendingFollowed: boolean | null;
};

const DAY = 86_400_000;
const iso = (d: number) => new Date(d).toISOString().slice(0, 10);

/** Ajuste por pausa de get_next_targets_v1: [días mínimos, factor], de mayor a menor. */
export type LayoffTable = Array<[number, number]>;
/** Tabla hasta 2026-10-24 (migración 20261022232000). */
export const LAYOFF_V1: LayoffTable = [[56, 0.75], [28, 0.85], [14, 0.925]];
/** Tabla actual (migración 20261024163000). */
export const LAYOFF_PROD: LayoffTable = [[56, 0.8], [28, 0.9], [21, 0.95]];

function layoffAdjust(weight: number, days: number, step: number, table: LayoffTable) {
  const row = table.find(([d]) => days >= d);
  if (!row || weight === 0) return weight;
  return Math.max(0, Math.round((weight * row[1]) / step) * step);
}

function epley(w: number, r: number) { return w * (1 + r / 30); }

/** Carga con la que, con fuerza `e1rm`, se hacen exactamente `reps`. */
function loadFor(e1rm: number, reps: number) { return e1rm / (1 + reps / 30); }

/** Incrementos de carga por ejercicio tipo (clave del arquetipo → kg); para probar
 *  cambios de catálogo como discos de 1,25 kg. */
export type IncrementOverrides = Record<string, number | null>;

function simulateAthlete(profile: Profile, seed: number, engine: Engine, layoff: LayoffTable, increments: IncrementOverrides) {
  const r = rng(seed);
  const between = (a: number, b: number) => a + (b - a) * r.next();
  const exercises: ExerciseState[] = ARCHETYPES
    .map((a) => (a.key in increments ? { ...a, increment: increments[a.key] } : a))
    .map((arch, i) => {
    const e1rmBase = arch.e1rm * between(0.8, 1.2);
    const min = arch.min;
    const max = profile.rangeMode === "range" ? arch.max : null;
    const ideal = arch.bodyweight ? 0 : loadFor(e1rmBase, min);
    const step = arch.increment ?? 2.5;
    const routineWeight = arch.bodyweight ? 0 : Math.round((ideal * between(...profile.startCalibration)) / step) * step;
    return {
      arch, id: `${arch.key}-${i}`, e1rmBase, growth: between(...profile.growth), fatigue: between(...profile.fatigue),
      min, max, routineWeight, history: [], lastWeight: null, last: null, pendingFollowed: null,
    };
  });

  // Calendario.
  const start = Date.UTC(2026, 0, 5);
  const dates: number[] = [];
  let t = start;
  const end = start + profile.weeks * 7 * DAY;
  while (t < end) {
    const week = (t - start) / (7 * DAY);
    if (profile.layoff && week >= profile.layoff[0] && week < profile.layoff[0] + profile.layoff[1] / 7) {
      t += profile.layoff[1] * DAY;
      continue;
    }
    dates.push(t);
    t += (profile.attendance === "irregular" ? Math.round(between(2, 20)) : [2, 2, 3][dates.length % 3]) * DAY;
  }

  const stats = {
    sessions: 0, followedHits: 0, followedTotal: 0, fails: 0, exposures: 0, decreases: 0, reversals: 0,
    maxDropStreak: 0, maxJumpPct: 0, impossible: 0, regressionLag: null as number | null,
    reasons: {} as Record<string, number>,
  };
  const regStart = profile.regression ? start + profile.regression[0] * 7 * DAY : null;
  let regressionSessions = 0;
  const firstCapacity = new Map<string, number>();
  const finalTracking: number[] = [];
  const captures: number[] = [];
  const dir = new Map<string, number>();
  const dropStreak = new Map<string, number>();

  for (const date of dates) {
    stats.sessions++;
    const week = (date - start) / (7 * DAY);
    const dateIso = iso(date);
    const dayFactor = 1 + r.normal() * profile.dayNoise;
    let detraining = 1;
    if (profile.layoff && week >= profile.layoff[0]) detraining = 0.93;
    let regFactor = 1;
    if (profile.regression && week >= profile.regression[0]) {
      const [, len, drop] = profile.regression;
      regFactor = 1 - drop * Math.min(1, (week - profile.regression[0]) / len);
    }
    if (regStart && date >= regStart) regressionSessions++;

    const targets: CoachingInputsV2["targets"] = [];
    const logs: NonNullable<CoachingInputsV2["current_logs"]> = [];
    const meta = new Map<string, { weight: number; followed: boolean; capacity: number; trueE1rm: number }>();

    for (const ex of exercises) {
      const trueE1rm = ex.e1rmBase * (1 + ex.growth * week) * detraining * regFactor;
      const todayE1rm = trueE1rm * dayFactor;
      const step = ex.arch.increment ?? 2.5;
      let weight = ex.routineWeight;
      let followed = false;
      let aim = Math.max(ex.max ?? ex.min, ex.min);
      if (ex.last && ex.last.item.suggested_weight != null) {
        const gap = Math.round((date - Date.parse(ex.last.date)) / DAY);
        const suggested = layoffAdjust(ex.last.item.suggested_weight, gap, step, layoff);
        if (r.next() < profile.compliance) {
          weight = suggested;
          followed = true;
          aim = Math.max(aim, ex.last.item.suggested_reps ?? 0);
        } else {
          weight = (ex.lastWeight ?? ex.routineWeight) + profile.ego * step;
        }
      }
      if (ex.arch.bodyweight) weight = 0;
      // ¿Era imposible para el mínimo con la fuerza de hoy?
      if (followed && !ex.arch.bodyweight && weight > loadFor(todayE1rm, ex.min) * 1.03) stats.impossible++;
      const capacity = ex.arch.bodyweight ? 0 : loadFor(trueE1rm, ex.min);
      if (!firstCapacity.has(ex.id)) firstCapacity.set(ex.id, capacity);

      for (let i = 0; i < ex.arch.sets; i++) {
        const base = ex.arch.bodyweight ? Math.floor(todayE1rm) : Math.floor(30 * (todayE1rm / weight - 1));
        const reps = Math.max(0, base - Math.round(i * ex.fatigue) + (r.next() < 0.15 ? -1 : r.next() > 0.9 ? 1 : 0));
        const done = profile.behavior === "cap" ? Math.min(reps, aim) : reps;
        logs.push({ exercise_id: ex.id, actual_weight: weight, actual_reps: done, set_index: i + 1, name: ex.arch.name });
      }
      targets.push({ exercise_id: ex.id, target_sets: ex.arch.sets, target_reps: ex.min, target_reps_max: ex.max, target_weight: ex.routineWeight });
      meta.set(ex.id, { weight, followed, capacity, trueE1rm });
    }

    const catalog = exercises.map((ex) => ({
      exercise_id: ex.id, name: ex.arch.name, movement_type: ex.arch.movement, body_region: ex.arch.region,
      load_increment_kg: ex.arch.increment,
    }));
    const history = exercises.flatMap((ex) => ex.history.slice(0, 6));
    const items = engine({ session: { id: `s${stats.sessions}`, user_id: "u", session_date: dateIso }, targets, current_logs: logs, catalog, history });

    for (const ex of exercises) {
      const m = meta.get(ex.id)!;
      const own = logs.filter((l) => l.exercise_id === ex.id);
      const reps = own.map((l) => l.actual_reps);
      const minReps = Math.min(...reps);
      const top = Math.max(...own.map((l) => l.actual_weight));
      stats.exposures++;
      const failed = minReps < ex.min;
      if (failed) stats.fails++;
      // Etiqueta de la sugerencia anterior.
      if (ex.pendingFollowed) {
        stats.followedTotal++;
        if (!failed) stats.followedHits++;
      }
      ex.pendingFollowed = m.followed ? true : null;
      // Dirección de la carga.
      if (ex.lastWeight != null && !ex.arch.bodyweight) {
        const d = Math.sign(m.weight - ex.lastWeight);
        if (d < 0) {
          stats.decreases++;
          dropStreak.set(ex.id, (dropStreak.get(ex.id) ?? 0) + 1);
          stats.maxDropStreak = Math.max(stats.maxDropStreak, dropStreak.get(ex.id)!);
          if (regStart && date >= regStart && stats.regressionLag == null) stats.regressionLag = regressionSessions;
        } else if (d > 0) dropStreak.set(ex.id, 0);
        if (d !== 0) {
          const prev = dir.get(ex.id);
          if (prev != null && prev !== d) stats.reversals++;
          dir.set(ex.id, d);
        }
        if (d > 0 && ex.lastWeight > 0) stats.maxJumpPct = Math.max(stats.maxJumpPct, (m.weight / ex.lastWeight - 1) * 100);
      }
      ex.lastWeight = m.weight;

      const item = items.find((i) => i.exercise_id === ex.id);
      if (item) {
        stats.reasons[item.reason_code] = (stats.reasons[item.reason_code] ?? 0) + 1;
        ex.last = { item, date: dateIso };
      }
      // Fila de historial como la escribe refresh_exercise_session_stats_v1.
      const reliable = own.filter((l) => l.actual_weight > 0 && l.actual_reps >= 1 && l.actual_reps <= 12);
      const anyE = own.filter((l) => l.actual_weight > 0 && l.actual_reps > 0);
      const best = (reliable.length ? reliable : anyE).reduce<number | null>((b, l) => Math.max(b ?? 0, epley(l.actual_weight, l.actual_reps)), null);
      ex.history.unshift({
        exercise_id: ex.id, session_date: dateIso, top_weight: top, min_reps: minReps, sets_done: own.length,
        sets_target: ex.arch.sets, target_reps: ex.min, best_e1rm: best == null ? null : Math.round(best * 100) / 100,
        low_confidence: reliable.length === 0 && anyE.length > 0,
        at_range_top: own.length >= ex.arch.sets && minReps >= Math.max(ex.max ?? ex.min, ex.min),
      });
    }
  }

  // Seguimiento final de la carga respecto a la fuerza real.
  const lastWeek = (dates[dates.length - 1] - start) / (7 * DAY);
  for (const ex of exercises) {
    if (ex.arch.bodyweight || ex.lastWeight == null) continue;
    const trueNow = ex.e1rmBase * (1 + ex.growth * lastWeek) * (profile.layoff ? 0.93 : 1) *
      (profile.regression ? 1 - profile.regression[2] : 1);
    const ideal = loadFor(trueNow, ex.min);
    finalTracking.push(ex.lastWeight / ideal);
    const strengthGain = ideal / firstCapacity.get(ex.id)! - 1;
    const loadGain = ex.lastWeight / ex.routineWeight - 1;
    if (strengthGain > 0.03) captures.push(loadGain / strengthGain);
  }
  return { stats, finalTracking, captures };
}

const mean = (xs: number[]) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : NaN);

export function runScenarios(
  engine: Engine = analyzeSessionV2, athletes = 200, profiles = PROFILES, layoff: LayoffTable = LAYOFF_PROD,
  increments: IncrementOverrides = {},
): Metrics[] {
  return profiles.map((profile, pi) => {
    const agg = { sessions: 0, followedHits: 0, followedTotal: 0, fails: 0, exposures: 0, decreases: 0, reversals: 0, maxDrop: 0, maxJump: 0, impossible: 0, lags: [] as number[], reasons: {} as Record<string, number>, tracking: [] as number[], capture: [] as number[] };
    for (let a = 0; a < athletes; a++) {
      const { stats, finalTracking, captures } = simulateAthlete(profile, 1000 * (pi + 1) + a, engine, layoff, increments);
      agg.sessions += stats.sessions; agg.followedHits += stats.followedHits; agg.followedTotal += stats.followedTotal;
      agg.fails += stats.fails; agg.exposures += stats.exposures; agg.decreases += stats.decreases; agg.reversals += stats.reversals;
      agg.maxDrop = Math.max(agg.maxDrop, stats.maxDropStreak); agg.maxJump = Math.max(agg.maxJump, stats.maxJumpPct);
      agg.impossible += stats.impossible;
      if (stats.regressionLag != null) agg.lags.push(stats.regressionLag);
      for (const [k, v] of Object.entries(stats.reasons)) agg.reasons[k] = (agg.reasons[k] ?? 0) + v;
      agg.tracking.push(...finalTracking); agg.capture.push(...captures);
    }
    return {
      profile: profile.key, label: profile.label, sessions: agg.sessions,
      hitWhenFollowed: agg.followedHits / agg.followedTotal,
      failRate: agg.fails / agg.exposures,
      loadTracking: mean(agg.tracking),
      progressCapture: mean(agg.capture),
      decreasesPer10: (agg.decreases / agg.exposures) * 10,
      reversalsPer10: (agg.reversals / agg.exposures) * 10,
      maxDropStreak: agg.maxDrop,
      maxJumpPct: agg.maxJump,
      impossibleRate: agg.impossible / agg.exposures,
      regressionLag: profile.regression ? mean(agg.lags) : null,
      reasons: agg.reasons,
    };
  });
}

export function printTable(rows: Metrics[]) {
  const pct = (x: number) => `${(x * 100).toFixed(1)}%`;
  const header = ["perfil", "sesiones", "acierto", "fallos", "carga/ideal", "captura", "bajadas/10", "vaivenes/10", "racha↓", "salto máx", "imposibles", "lag regr."];
  console.log(header.join(" | "));
  for (const m of rows) {
    console.log([
      m.profile, m.sessions, pct(m.hitWhenFollowed), pct(m.failRate), m.loadTracking.toFixed(2),
      Number.isFinite(m.progressCapture) ? m.progressCapture.toFixed(2) : "—",
      m.decreasesPer10.toFixed(2), m.reversalsPer10.toFixed(2), m.maxDropStreak, `${m.maxJumpPct.toFixed(1)}%`,
      pct(m.impossibleRate), m.regressionLag == null ? "—" : m.regressionLag.toFixed(1),
    ].join(" | "));
  }
}

if (import.meta.main) {
  const athletes = Number(Deno.args[0] ?? 200);
  const rows = runScenarios(analyzeSessionV2, athletes);
  printTable(rows);
  console.log("\nMotivos por perfil (top 4):");
  for (const m of rows) {
    const top = Object.entries(m.reasons).sort((a, b) => b[1] - a[1]).slice(0, 4).map(([k, v]) => `${k} ${v}`).join(", ");
    console.log(`  ${m.profile}: ${top}`);
  }
}
