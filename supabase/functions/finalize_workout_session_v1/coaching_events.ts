// Filas de `coaching_events` a partir del análisis que devuelve
// generate_coaching_v1. Función pura: el handler hace el upsert.

export type CoachingEventRow = {
  session_id: string;
  user_id: string;
  exercise_id: string;
  engine_version: string;
  recommendation: string;
  reason_code: string | null;
  suggested_weight: number | null;
  suggested_reps: number | null;
  performance_score: number | null;
  features: Record<string, unknown>;
};

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function num(v: unknown): number | null {
  return typeof v === "number" && Number.isFinite(v) ? v : null;
}

export function toCoachingEvents(
  sessionId: string,
  userId: string,
  analysis: unknown,
): CoachingEventRow[] {
  if (!Array.isArray(analysis)) return [];
  const rows: CoachingEventRow[] = [];
  for (const raw of analysis) {
    if (!raw || typeof raw !== "object") continue;
    const item = raw as Record<string, unknown>;
    const exerciseId = item.exercise_id;
    const recommendation = item.recommendation;
    if (typeof exerciseId !== "string" || !UUID.test(exerciseId)) continue;
    if (typeof recommendation !== "string" || recommendation === "") continue;
    rows.push({
      session_id: sessionId,
      user_id: userId,
      exercise_id: exerciseId,
      engine_version: typeof item.engine_version === "string" ? item.engine_version : "1.0",
      recommendation,
      reason_code: typeof item.reason_code === "string" ? item.reason_code : null,
      suggested_weight: num(item.suggested_weight),
      suggested_reps: num(item.suggested_reps),
      performance_score: num(item.performance_score),
      features: {
        completed_sets: item.completed_sets ?? null,
        target_sets: item.target_sets ?? null,
        weight_met: item.weight_met ?? null,
        reps_met: item.reps_met ?? null,
      },
    });
  }
  return rows;
}
