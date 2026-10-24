// Motor de coaching v2 (docs/coach/PLAN_COACH_V2.md, fase 2): doble
// progresión con peso sugerido, detección de estancamiento y regresión, y
// esfuerzo deducido de las series (no se pide RIR). Función pura sin I/O.
// Mantiene los 4 códigos de `recommendation`; lo nuevo va en campos aditivos.
import type { CoachingItem, Recommendation } from "./engine.ts";

export const ENGINE_V2_VERSION = "2.0";

export type ReasonCode =
  | "NO_DATA"
  | "INCOMPLETE_SETS"
  | "COLD_START_ADD_REPS"
  | "COLD_START_CONFIRM"
  | "DOUBLE_PROGRESSION_TOP"
  | "CONFIRM_TOP"
  | "IN_RANGE_ADD_REPS"
  | "BODYWEIGHT_ADD_REPS"
  | "FIRST_MISS"
  | "TOO_HEAVY"
  | "RESET_AFTER_MISSES"
  | "REGRESSION"
  | "PLATEAU"
  | "BUILDING_REPS";

export type Confidence = "low" | "medium" | "high";

export type CoachingItemV2 = CoachingItem & {
  suggested_weight: number | null;
  suggested_reps: number | null;
  reason_code: ReasonCode;
  confidence: Confidence;
};

export type HistoryRow = {
  exercise_id: string;
  session_date: string;
  top_weight: number;
  min_reps: number;
  sets_done: number;
  sets_target: number | null;
  target_reps: number | null;
  best_e1rm: number | null;
  low_confidence: boolean;
  at_range_top: boolean | null;
};

export type CoachingInputsV2 = {
  session?: { id: string; user_id: string; session_date: string } | null;
  targets?: Array<{
    exercise_id: string;
    target_sets: number;
    target_reps: number;
    target_reps_max: number | null;
    target_weight: number | null;
  }>;
  current_logs?: Array<{
    exercise_id: string;
    actual_weight: number;
    actual_reps: number;
    set_index: number;
    name?: string | null;
  }>;
  catalog?: Array<{
    exercise_id: string;
    name?: string | null;
    movement_type: string | null;
    body_region: string | null;
    load_increment_kg: number | null;
  }>;
  /** Exposiciones anteriores cerradas, la más reciente primero (≤6 por ejercicio). */
  history?: HistoryRow[];
};

/** Tope de subida por sesión (ACSM: 2–10 %). */
const MAX_JUMP = 0.10;
/** Caída de reps entre la primera y la última serie que indica series al límite. */
const STRONG_DROPOFF = 3;

const round2 = (x: number) => Math.round(x * 100) / 100;

function roundTo(x: number, step: number, mode: "nearest" | "down" = "nearest"): number {
  const n = x / step;
  return round2((mode === "down" ? Math.floor(n + 1e-9) : Math.round(n)) * step);
}

export function formatKg(x: number): string {
  return `${Number.isInteger(x) ? x : x.toFixed(1).replace(/\.0$/, "")}`.replace(".", ",") + " kg";
}

function epley(w: number, r: number): number {
  return w * (1 + r / 30);
}

function daysBetween(from: string, to: string): number {
  return Math.round((Date.parse(to) - Date.parse(from)) / 86_400_000);
}

/** e1RM suavizado (EWMA, α = 0.5) en orden cronológico. */
function ewma(values: number[]): number[] {
  const out: number[] = [];
  for (const v of values) out.push(out.length === 0 ? v : 0.5 * v + 0.5 * out[out.length - 1]);
  return out;
}

/// Ajustes del motor. Los valores por defecto son los elegidos con el banco
/// de escenarios (scripts/local_coach_sim/scenarios.ts y compare.ts), que
/// prueba variantes con los mismos atletas simulados.
export type EngineOptions = {
  /** Cuándo se da el rango por completado: todas las series en el máximo, o
   *  la primera serie en el máximo con las demás a ≤1 rep de media (fatiga). */
  progression?: "all_sets" | "top_set";
  /** Rutinas sin rango (un solo objetivo): subir en cuanto se cumple o pedir
   *  una segunda sesión que lo confirme. */
  singleTarget?: "immediate" | "confirm";
  /** Estancamiento: e1RM plano (EWMA) o, además, ni carga ni reps han subido
   *  en las últimas 4 exposiciones. */
  plateau?: "e1rm" | "load_and_reps";
};

export function analyzeSessionV2(inputs: CoachingInputsV2, options: EngineOptions = {}): CoachingItemV2[] {
  const progression = options.progression ?? "all_sets";
  // Elegidos con el banco (2026-10-24): sin rango, confirmar baja los fallos
  // del 36 % al 27 %; el estancamiento por carga y reps reduce las falsas
  // alarmas un 35–50 % en quien progresa.
  const singleTarget = options.singleTarget ?? "confirm";
  const plateauRule = options.plateau ?? "load_and_reps";
  const logs = inputs.current_logs ?? [];
  const history = inputs.history ?? [];
  const catalog = new Map((inputs.catalog ?? []).map((c) => [c.exercise_id, c]));
  const sessionDate = inputs.session?.session_date ?? null;

  return (inputs.targets ?? []).filter((t) => (t.target_sets ?? 0) > 0).map((t) => {
    const sets = logs.filter((l) => l.exercise_id === t.exercise_id)
      .sort((a, b) => a.set_index - b.set_index);
    const past = history.filter((h) => h.exercise_id === t.exercise_id);
    const info = catalog.get(t.exercise_id);
    const name = sets[0]?.name ?? info?.name ?? "Ejercicio";

    const targetSets = t.target_sets;
    const repsMin = Number(t.target_reps ?? 0);
    const repsMax = Math.max(Number(t.target_reps_max ?? repsMin), repsMin);
    const hasRange = repsMax > repsMin;
    const targetWeight = Number(t.target_weight ?? 0);

    const done = sets.length;
    const reps = sets.map((s) => Number(s.actual_reps ?? 0));
    const weights = sets.map((s) => Number(s.actual_weight ?? 0));
    // Peso de trabajo: el de más series (empate → el más pesado). Una serie
    // suelta más pesada (un intento de 110×3 entre series de 100×6) no debe
    // ser la referencia de la progresión.
    const counts = new Map<number, number>();
    for (const w of weights) counts.set(w, (counts.get(w) ?? 0) + 1);
    const top = done > 0
      ? [...counts.entries()].sort((a, b) => b[1] - a[1] || b[0] - a[0])[0][0]
      : 0;
    const heaviest = done > 0 ? Math.max(...weights) : 0;
    const workReps = sets.filter((s) => Number(s.actual_weight ?? 0) === top).map((s) => Number(s.actual_reps ?? 0));
    const minReps = done > 0 ? Math.min(...workReps) : 0;
    const avgReps = done > 0 ? reps.reduce((a, b) => a + b, 0) / done : 0;
    const dropoff = done > 1 ? reps[0] - reps[done - 1] : 0;
    const bodyweight = done > 0 && heaviest === 0;
    // Clasificado y sin incremento = sin carga externa (plancha, etc.).
    const noLoad = bodyweight || (info?.movement_type != null && info.load_increment_kg == null);
    const increment = Number(info?.load_increment_kg ?? 2.5);

    const e1rmSets = sets.filter((s) => s.actual_weight > 0 && s.actual_reps >= 1);
    const reliable = e1rmSets.filter((s) => s.actual_reps <= 12);
    const e1rm = (reliable.length ? reliable : e1rmSets)
      .reduce<number | null>((m, s) => Math.max(m ?? 0, epley(s.actual_weight, s.actual_reps)), null);

    const series = [...past].reverse().map((h) => h.best_e1rm).filter((v): v is number => v != null);
    const smoothed = ewma(series);
    const expected = smoothed.length ? smoothed[smoothed.length - 1] : null;

    // Carga que el e1RM de hoy permite para `reps` (redondeada hacia abajo).
    // Epley pierde fiabilidad por encima de 12 reps: ahí no se acota.
    const fit = (r: number) => e1rm != null && !noLoad && reliable.length > 0 && r <= 12
      ? roundTo(e1rm / (1 + r / 30), increment, "down")
      : Infinity;

    const weightMet = heaviest >= targetWeight;
    const repsMet = done > 0 && minReps >= repsMin;

    let recommendation: Recommendation = "MAINTAIN";
    let reason: ReasonCode = "NO_DATA";
    let suggestedWeight: number | null = done > 0 ? top : (targetWeight || null);
    let suggestedReps: number | null = repsMin || null;
    let feedback = "";

    const isMissAt = (h: HistoryRow, w: number) =>
      Math.abs(h.top_weight - w) < 0.01 && h.min_reps < Number(h.target_reps ?? repsMin);

    if (done === 0) {
      reason = "NO_DATA";
      feedback = "Sin series registradas: repite el objetivo la próxima vez.";
    } else if (done < targetSets) {
      reason = "INCOMPLETE_SETS";
      feedback = `Completa las ${targetSets} series con ${formatKg(top)} antes de subir carga.`;
    } else if (past.length === 0) {
      // Arranque en frío: sin historial no se sube carga.
      if (minReps >= repsMax) {
        reason = "COLD_START_CONFIRM";
        suggestedReps = repsMax;
        feedback = `Buen comienzo. Repite ${formatKg(top)} para confirmar antes de subir.`;
      } else if (minReps >= repsMin) {
        recommendation = "INCREASE_REPS";
        reason = "COLD_START_ADD_REPS";
        suggestedReps = Math.min(repsMax, minReps + 1);
        feedback = `Primera referencia. Mantén ${formatKg(top)} y busca ${suggestedReps} reps.`;
      } else {
        reason = "FIRST_MISS";
        feedback = `Primera referencia. Mantén ${formatKg(top)} hasta completar ${repsMin} reps.`;
      }
    } else if (noLoad && minReps >= repsMax) {
      recommendation = "INCREASE_REPS";
      reason = "BODYWEIGHT_ADD_REPS";
      suggestedReps = minReps + 1;
      feedback = `Sin carga que subir: apunta a ${suggestedReps} reps por serie.`;
    } else {
      // Si el salto mínimo es grande para la carga (aislamientos ligeros), se
      // piden 2 reps por encima del rango antes de subir.
      const bigStep = top > 0 && increment > top * MAX_JUMP;
      const topThreshold = repsMax + (bigStep ? 2 : 0);
      const prev = past[0];
      const prevTopSameWeight = prev && Math.abs(prev.top_weight - top) < 0.01 && prev.at_range_top === true;

      const shortfall = workReps.reduce((sum, r) => sum + Math.max(0, topThreshold - r), 0);
      const rangeDone = progression === "top_set"
        ? workReps[0] >= topThreshold && minReps >= repsMin && shortfall <= workReps.length
        : minReps >= topThreshold;
      const needsConfirm = (!hasRange && singleTarget === "confirm") || dropoff >= STRONG_DROPOFF;

      if (rangeDone) {
        if (needsConfirm && !prevTopSameWeight) {
          reason = "CONFIRM_TOP";
          suggestedReps = repsMax;
          feedback = dropoff >= STRONG_DROPOFF
            ? `Llegaste al máximo pero muy al límite. Repite ${formatKg(top)} para confirmar.`
            : `Cumpliste el objetivo. Repite ${formatKg(top)} una vez más para confirmarlo antes de subir.`;
        } else {
          const step = Math.max(increment, roundTo(top * 0.025, increment));
          const capped = bigStep ? top + increment : Math.min(top + step, top * (1 + MAX_JUMP));
          const next = roundTo(capped, increment, "down");
          recommendation = "INCREASE_WEIGHT";
          reason = "DOUBLE_PROGRESSION_TOP";
          suggestedWeight = next > top ? next : round2(top + increment);
          suggestedReps = repsMin;
          feedback = `Completaste el rango: sube a ${formatKg(suggestedWeight)} y vuelve a ${repsMin} reps.`;
        }
      } else if (minReps >= repsMin) {
        recommendation = "INCREASE_REPS";
        reason = "IN_RANGE_ADD_REPS";
        suggestedReps = Math.min(topThreshold, minReps + 1);
        feedback = `Mantén ${formatKg(top)} y suma una rep: busca ${suggestedReps}.`;
      } else if (prev && isMissAt(prev, top) && minReps > prev.min_reps && minReps >= Math.max(4, repsMin * 0.6)) {
        // Sigue sin llegar al mínimo pero suma reps sesión a sesión: progresa.
        recommendation = "INCREASE_REPS";
        reason = "BUILDING_REPS";
        suggestedReps = Math.min(repsMin, minReps + 1);
        feedback = `Vas sumando reps con ${formatKg(top)}: busca ${suggestedReps} la próxima vez.`;
      } else if (prev && isMissAt(prev, top)) {
        recommendation = "DECREASE_WEIGHT";
        reason = "RESET_AFTER_MISSES";
        // Entre −5 % y −10 %: lo que permita la fuerza de hoy para el mínimo.
        const byStrength = Math.min(fit(repsMin), roundTo(top * 0.95, increment), round2(top - increment));
        suggestedWeight = Math.min(Math.max(roundTo(top * 0.9, increment), byStrength), round2(top - increment));
        feedback = `Dos sesiones sin llegar a ${repsMin} reps: baja a ${formatKg(Math.max(suggestedWeight, 0))} y reconstruye.`;
      } else if (minReps < Math.max(4, repsMin * 0.6)) {
        recommendation = "DECREASE_WEIGHT";
        reason = "TOO_HEAVY";
        suggestedWeight = Math.min(roundTo(top * 0.95, increment), round2(top - increment), fit(repsMin));
        feedback = `Carga demasiado alta para ${repsMin} reps: baja a ${formatKg(Math.max(suggestedWeight, 0))}.`;
      } else if (fit(repsMin) < top) {
        // Hoy no da para el mínimo con este peso: se ajusta a lo que permite el e1RM.
        recommendation = "DECREASE_WEIGHT";
        reason = "TOO_HEAVY";
        suggestedWeight = fit(repsMin);
        feedback = `Para ${repsMin} reps tu fuerza de hoy da para ${formatKg(suggestedWeight)}.`;
      } else {
        reason = "FIRST_MISS";
        feedback = `Repite ${formatKg(top)} e intenta llegar a ${repsMin} reps en todas las series.`;
      }

      // Regresión / estancamiento sobre el e1RM (solo si no se sube carga).
      // Si la mejor serie llegó al máximo del rango, el atleta paró ahí: el
      // e1RM es una cota inferior y no sirve para diagnosticar (simulación
      // 2026-10-24: el curl caía 2 kg por sesión hasta 0 con 12/12/12).
      const capped = workReps.length > 0 && Math.max(...workReps) >= repsMax;
      const failing = minReps < repsMin;
      const prevMissed = prev != null && prev.min_reps < Number(prev.target_reps ?? repsMin);
      if (recommendation !== "INCREASE_WEIGHT" && !noLoad && e1rm != null && series.length >= 2 && !capped) {
        const peak = Math.max(...series);
        // Regresión: falla hoy y fallaba la vez anterior (un mal día no basta).
        if (e1rm <= peak * 0.95 && failing && prevMissed &&
            reason !== "RESET_AFTER_MISSES" && reason !== "BUILDING_REPS") {
          recommendation = "DECREASE_WEIGHT";
          reason = "REGRESSION";
          suggestedWeight = Math.min(roundTo(top * 0.95, increment), round2(top - increment), fit(repsMin));
          suggestedReps = repsMin;
          feedback = `Tu fuerza estimada bajó respecto a tu mejor marca: baja a ${formatKg(Math.max(suggestedWeight, 0))} y recupera.`;
        } else if (series.length >= 3) {
          const all = ewma([...series, e1rm]);
          const before = all[all.length - 4] ?? all[0];
          // Sin subir carga ni reps en 4 exposiciones (hoy + 3 anteriores).
          const recent = past.slice(0, 3);
          const stuck = recent.length === 3 &&
            recent.every((h) => h.top_weight >= top - 0.01) &&
            minReps <= Math.max(...recent.map((h) => h.min_reps));
          if (all[all.length - 1] <= before * 1.01 && (plateauRule === "e1rm" || stuck) &&
              reason !== "RESET_AFTER_MISSES" && reason !== "TOO_HEAVY" && reason !== "BUILDING_REPS") {
            reason = "PLATEAU";
            feedback = `Llevas varias sesiones sin progresar con ${formatKg(top)}. Prueba a variar el rango de reps o descansar mejor.`;
          }
        }
      }
    }

    if (suggestedWeight != null) suggestedWeight = Math.max(0, round2(suggestedWeight));
    // Un ejercicio con carga nunca baja de su incremento mínimo (antes podía
    // acabar en 0 kg y tratarse como peso corporal).
    if (suggestedWeight != null && top > 0 && !noLoad && suggestedWeight < increment) {
      suggestedWeight = Math.min(top, increment);
      if (recommendation === "DECREASE_WEIGHT" && suggestedWeight >= top) {
        recommendation = "MAINTAIN";
        reason = "FIRST_MISS";
        feedback = `Repite ${formatKg(top)} e intenta llegar a ${repsMin} reps en todas las series.`;
      }
    }

    const daysSincePrev = past[0] && sessionDate ? daysBetween(past[0].session_date, sessionDate) : null;
    let confidence: Confidence = past.length === 0 ? "low" : past.length < 3 ? "medium" : "high";
    if ((reliable.length === 0 && e1rmSets.length > 0) || (daysSincePrev != null && daysSincePrev > 28)) {
      confidence = confidence === "high" ? "medium" : "low";
    }

    const score = e1rm != null && expected != null && expected > 0
      ? e1rm / expected
      : repsMin > 0 ? avgReps / repsMin : 1;

    return {
      exercise_id: t.exercise_id,
      exercise_name: name,
      completed_sets: done,
      target_sets: targetSets,
      weight_met: weightMet,
      reps_met: repsMet,
      recommendation,
      feedback,
      performance_score: round2(Math.min(1.5, Math.max(0, score))),
      engine_version: ENGINE_V2_VERSION,
      suggested_weight: suggestedWeight,
      suggested_reps: suggestedReps,
      reason_code: reason,
      confidence,
    };
  });
}
