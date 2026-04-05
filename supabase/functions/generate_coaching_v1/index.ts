import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

function logInfo(code: string, details: Record<string, unknown>): void {
  console.log(JSON.stringify({ level: "info", code, ...details }));
}

function logError(code: string, details: Record<string, unknown>): void {
  console.error(JSON.stringify({ level: "error", code, ...details }));
}

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

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-user-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Extract user_id from JWT without validation (already validated by client)
function extractUserIdFromJWT(token: string): string | null {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;

    const payload = JSON.parse(atob(parts[1]));
    // Try 'sub' field (standard JWT), or 'id' field (Supabase custom)
    return payload.sub ?? payload.id ?? null;
  } catch {
    return null;
  }
}

Deno.serve(async (req: Request) => {
  // Handle CORS pre-flight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json(405, { success: false, code: "METHOD_NOT_ALLOWED", error: { message: "Use POST" } });
  }

  // Try to get token from Authorization header OR from custom X-User-Token header
  let token = req.headers.get("Authorization");
  if (token?.startsWith("Bearer ")) {
    token = token.substring(7);
  } else {
    token = req.headers.get("X-User-Token") ?? null;
  }

  let userId = "unknown";
  if (token) {
    const extracted = extractUserIdFromJWT(token);
    if (extracted) {
      userId = extracted;
      logInfo("USER_FROM_JWT", { user_id: userId });
    }
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  let payload: { session_id?: string; user_id?: string };
  try {
    payload = await req.json();
  } catch {
    return json(400, { success: false, code: "INVALID_JSON", error: { message: "Invalid request body" } });
  }

  const sessionId = payload.session_id;
  if (!sessionId) {
    return json(400, { success: false, code: "VALIDATION_ERROR", error: { message: "session_id is required" } });
  }

  if (userId === "unknown" && payload.user_id) {
    userId = payload.user_id;
    logInfo("USER_FROM_PAYLOAD", { user_id: userId });
  }

  if (userId === "unknown") {
    return json(401, {
      success: false,
      code: "UNAUTHORIZED",
      error: { message: "Missing user context" },
    });
  }

  logInfo("COACHING_REQUEST", { user_id: userId, session_id: sessionId });

  const { data: rpcPayload, error: rpcError } = await supabase
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
    return json(500, {
      success: false,
      code: "COACHING_INPUTS_ERROR",
      error: { message: rpcError.message },
    });
  }

  const inputs = (rpcPayload ?? {}) as CoachingInputs;
  const sessionRow = inputs.session ?? null;

  if (!sessionRow) {
    return json(404, { success: false, code: "SESSION_NOT_FOUND", error: { message: "Session not found" } });
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

  return json(200, {
    success: true,
    code: "COACHING_GENERATED",
    data: {
      session_id: sessionId,
      analysis,
    },
  });
});
