import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { jsonResponse, preflight } from "../_shared/cors.ts";
import { logError, logInfo, requireUser } from "../_shared/auth.ts";
import { enforceRateLimit } from "../_shared/rate_limit.ts";

const RATE_LIMIT = {
  functionName: "generate_coaching_v1",
  windowSeconds: 60,
  maxCalls: 30,
} as const;

type SetRow = {
  exercise_id: string;
  actual_weight: number;
  actual_reps: number;
  exercises?: { name?: string } | null;
  workout_sessions?: { session_date?: string } | null;
};

type RoutineExerciseRow = {
  exercise_id: string;
  target_sets: number;
  target_reps: number;
  target_weight: number;
};

type CoachingInputs = {
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
  routine_exercises?: RoutineExerciseRow[];
  previous_logs?: Array<{
    exercise_id: string;
    actual_weight: number;
    actual_reps: number;
    set_index: number;
  }>;
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return preflight();

  if (req.method !== "POST") {
    return jsonResponse(405, {
      success: false,
      code: "METHOD_NOT_ALLOWED",
      error: { message: "Use POST" },
    });
  }

  const auth = await requireUser(req);
  if (!auth.ok) return auth.response;
  const { userId, admin } = auth;

  const rate = await enforceRateLimit(admin, userId, RATE_LIMIT);
  if (!rate.ok) return rate.response;

  let payload: { session_id?: string };
  try {
    payload = await req.json();
  } catch {
    return jsonResponse(400, {
      success: false,
      code: "INVALID_JSON",
      error: { message: "Invalid request body" },
    });
  }

  const sessionId = payload.session_id;
  if (!sessionId) {
    return jsonResponse(400, {
      success: false,
      code: "VALIDATION_ERROR",
      error: { message: "session_id is required" },
    });
  }

  logInfo("COACHING_REQUEST", { user_id: userId, session_id: sessionId });

  const { data: rpcPayload, error: rpcError } = await admin
    .rpc("get_coaching_inputs_v1", {
      p_user_id: userId,
      p_session_id: sessionId,
    })
    .maybeSingle();

  if (rpcError) {
    logError("COACHING_INPUTS_ERROR", {
      user_id: userId,
      session_id: sessionId,
      message: rpcError.message,
    });
    return jsonResponse(500, {
      success: false,
      code: "COACHING_INPUTS_ERROR",
      error: { message: rpcError.message },
    });
  }

  const inputs = (rpcPayload ?? {}) as CoachingInputs;
  const sessionRow = inputs.session ?? null;

  if (!sessionRow) {
    return jsonResponse(404, {
      success: false,
      code: "SESSION_NOT_FOUND",
      error: { message: "Session not found" },
    });
  }

  const currentLogs = (inputs.current_logs ?? []).map((row) => ({
    exercise_id: row.exercise_id,
    actual_weight: row.actual_weight,
    actual_reps: row.actual_reps,
    exercises: { name: row.name ?? undefined },
  })) as SetRow[];

  const routineExercises = (inputs.routine_exercises ?? []) as RoutineExerciseRow[];

  const previousLogs = (inputs.previous_logs ?? []).map((row) => ({
    exercise_id: row.exercise_id,
    actual_weight: row.actual_weight,
    actual_reps: row.actual_reps,
  })) as SetRow[];

  const analysis = routineExercises.map((target) => {
    const exerciseCurrentLogs = currentLogs.filter((l) => l.exercise_id === target.exercise_id);
    const exercisePreviousLogs = previousLogs.filter((l) => l.exercise_id === target.exercise_id);

    const completedSets = exerciseCurrentLogs.length;
    const targetSets = target.target_sets ?? 0;

    const avgCurrentWeight = completedSets > 0
      ? exerciseCurrentLogs.reduce((sum, l) => sum + Number(l.actual_weight ?? 0), 0) / completedSets
      : 0;
    const avgCurrentReps = completedSets > 0
      ? exerciseCurrentLogs.reduce((sum, l) => sum + Number(l.actual_reps ?? 0), 0) / completedSets
      : 0;

    const prevCount = exercisePreviousLogs.length;
    const avgPrevWeight = prevCount > 0
      ? exercisePreviousLogs.reduce((sum, l) => sum + Number(l.actual_weight ?? 0), 0) / prevCount
      : 0;
    const avgPrevReps = prevCount > 0
      ? exercisePreviousLogs.reduce((sum, l) => sum + Number(l.actual_reps ?? 0), 0) / prevCount
      : 0;

    const weightMet = avgCurrentWeight >= Number(target.target_weight ?? 0);
    const repsMet = avgCurrentReps >= Number(target.target_reps ?? 0);

    let recommendation = "MAINTAIN";
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
    } else if (avgCurrentWeight >= avgPrevWeight && avgCurrentReps < Number(target.target_reps ?? 0)) {
      recommendation = "INCREASE_REPS";
      feedback = "Mantén el peso e intenta sumar repeticiones.";
      performanceScore = 0.88;
    } else if (avgCurrentReps < Math.max(4, Number(target.target_reps ?? 0) * 0.6)) {
      recommendation = "DECREASE_WEIGHT";
      feedback = "Baja un poco la carga para priorizar técnica y rango completo.";
      performanceScore = 0.55;
    }

    const exerciseName = exerciseCurrentLogs[0]?.exercises?.name ?? "Ejercicio";

    return {
      exercise_id: target.exercise_id,
      exercise_name: exerciseName,
      completed_sets: completedSets,
      target_sets: targetSets,
      weight_met: weightMet,
      reps_met: repsMet,
      recommendation: recommendation,
      feedback: feedback,
      performance_score: performanceScore,
    };
  });

  logInfo("COACHING_READY", { user_id: userId, session_id: sessionId, items: analysis.length });

  return jsonResponse(200, {
    success: true,
    code: "COACHING_GENERATED",
    data: {
      session_id: sessionId,
      analysis,
    },
  });
});
