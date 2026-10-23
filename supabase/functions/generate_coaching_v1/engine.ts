// Motor de coaching: función pura sin I/O. `index.ts` resuelve auth, rate
// limit y la RPC `get_coaching_inputs_v1`; aquí sólo se decide la
// recomendación por ejercicio a partir de esas entradas.
import { shouldReduceWeight } from "./weight_reduction.ts";

/// Versión del motor: viaja en cada item y en `coaching_events`.
export const ENGINE_VERSION = "1.0";

export type Recommendation =
  | "INCREASE_WEIGHT"
  | "INCREASE_REPS"
  | "MAINTAIN"
  | "DECREASE_WEIGHT";

export type CoachingInputs = {
  session?: {
    id: string;
    user_id: string;
    routine_day_id: string;
    session_date: string;
  } | null;
  current_logs?: Array<{
    exercise_id: string;
    actual_weight: number;
    actual_reps: number;
    set_index: number;
    name?: string | null;
  }>;
  routine_exercises?: Array<{
    exercise_id: string;
    target_sets: number;
    target_reps: number;
    target_weight: number;
  }>;
  previous_logs?: Array<{
    exercise_id: string;
    actual_weight: number;
    actual_reps: number;
    set_index: number;
  }>;
};

export type CoachingItem = {
  exercise_id: string;
  exercise_name: string;
  completed_sets: number;
  target_sets: number;
  weight_met: boolean;
  reps_met: boolean;
  recommendation: Recommendation;
  feedback: string;
  performance_score: number;
  engine_version: string;
};

type Log = { actual_weight: number; actual_reps: number };

function average(logs: Log[], pick: (l: Log) => number): number {
  if (logs.length === 0) return 0;
  return logs.reduce((sum, l) => sum + Number(pick(l) ?? 0), 0) / logs.length;
}

export function analyzeSession(inputs: CoachingInputs): CoachingItem[] {
  const currentLogs = inputs.current_logs ?? [];
  const previousLogs = inputs.previous_logs ?? [];

  return (inputs.routine_exercises ?? []).map((target) => {
    const exerciseCurrentLogs = currentLogs.filter((l) => l.exercise_id === target.exercise_id);
    const exercisePreviousLogs = previousLogs.filter((l) => l.exercise_id === target.exercise_id);

    const completedSets = exerciseCurrentLogs.length;
    const targetSets = target.target_sets ?? 0;
    const targetWeight = Number(target.target_weight ?? 0);
    const targetReps = Number(target.target_reps ?? 0);

    const avgCurrentWeight = average(exerciseCurrentLogs, (l) => l.actual_weight);
    const avgCurrentReps = average(exerciseCurrentLogs, (l) => l.actual_reps);
    const prevCount = exercisePreviousLogs.length;
    const avgPrevWeight = average(exercisePreviousLogs, (l) => l.actual_weight);
    const avgPrevReps = average(exercisePreviousLogs, (l) => l.actual_reps);

    const weightMet = avgCurrentWeight >= targetWeight;
    const repsMet = avgCurrentReps >= targetReps;

    let recommendation: Recommendation = "MAINTAIN";
    let feedback = "Buen trabajo, mantén el peso actual.";
    let performanceScore = 0.9;

    if (completedSets < targetSets) {
      recommendation = "MAINTAIN";
      feedback = "Completa todas las series objetivo antes de subir carga.";
      performanceScore = 0.65;
    } else if (prevCount === 0) {
      recommendation = repsMet ? "INCREASE_WEIGHT" : "INCREASE_REPS";
      feedback = repsMet
        ? "Primera referencia sólida, puedes subir peso en la próxima sesión."
        : "Consolida repeticiones antes de subir peso.";
      performanceScore = repsMet ? 1.0 : 0.85;
    } else if (avgCurrentWeight > avgPrevWeight && avgCurrentReps >= avgPrevReps) {
      recommendation = "INCREASE_WEIGHT";
      feedback = "Superaste tu sesión anterior, sube el peso ligeramente.";
      performanceScore = 1.05;
    } else if (avgCurrentWeight >= avgPrevWeight && avgCurrentReps < targetReps) {
      recommendation = "INCREASE_REPS";
      feedback = "Mantén el peso e intenta sumar repeticiones.";
      performanceScore = 0.88;
    } else if (shouldReduceWeight(avgCurrentWeight, avgCurrentReps, targetWeight, targetReps)) {
      recommendation = "DECREASE_WEIGHT";
      feedback = "Baja un poco la carga para priorizar técnica y rango completo.";
      performanceScore = 0.55;
    }

    return {
      exercise_id: target.exercise_id,
      exercise_name: exerciseCurrentLogs[0]?.name ?? "Ejercicio",
      completed_sets: completedSets,
      target_sets: targetSets,
      weight_met: weightMet,
      reps_met: repsMet,
      recommendation,
      feedback,
      performance_score: performanceScore,
      engine_version: ENGINE_VERSION,
    };
  });
}
