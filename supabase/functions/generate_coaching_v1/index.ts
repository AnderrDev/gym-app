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

  let payload: { session_id?: string };
  try {
    payload = await req.json();
  } catch {
    return json(400, { success: false, code: "INVALID_JSON", error: { message: "Invalid request body" } });
  }

  const sessionId = payload.session_id;
  if (!sessionId) {
    return json(400, { success: false, code: "VALIDATION_ERROR", error: { message: "session_id is required" } });
  }

  logInfo("COACHING_REQUEST", { user_id: userId, session_id: sessionId });

  const { data: sessionRow, error: sessionError } = await supabase
    .from("workout_sessions")
    .select("id,user_id,routine_day_id,session_date")
    .eq("id", sessionId)
    .eq("user_id", userId)
    .limit(1)
    .maybeSingle();

  if (sessionError) {
    logError("SESSION_LOOKUP_ERROR", { user_id: userId, session_id: sessionId, message: sessionError.message });
    return json(500, { success: false, code: "SESSION_LOOKUP_ERROR", error: { message: sessionError.message } });
  }

  if (!sessionRow) {
    return json(404, { success: false, code: "SESSION_NOT_FOUND", error: { message: "Session not found" } });
  }

  const { data: currentLogsRaw, error: currentLogsError } = await supabase
    .from("set_logs")
    .select("exercise_id,actual_weight,actual_reps,exercises(name)")
    .eq("session_id", sessionId)
    .order("set_index", { ascending: true });

  if (currentLogsError) {
    logError("CURRENT_LOGS_ERROR", { user_id: userId, session_id: sessionId, message: currentLogsError.message });
    return json(500, { success: false, code: "CURRENT_LOGS_ERROR", error: { message: currentLogsError.message } });
  }

  const currentLogs = (currentLogsRaw ?? []) as SetRow[];

  const { data: routineExercisesRaw, error: routineExercisesError } = await supabase
    .from("routine_exercises")
    .select("exercise_id,target_sets,target_reps,target_weight")
    .eq("routine_day_id", sessionRow.routine_day_id);

  if (routineExercisesError) {
    logError("ROUTINE_EXERCISES_ERROR", { user_id: userId, session_id: sessionId, message: routineExercisesError.message });
    return json(500, { success: false, code: "ROUTINE_EXERCISES_ERROR", error: { message: routineExercisesError.message } });
  }

  const routineExercises = (routineExercisesRaw ?? []) as RoutineExerciseRow[];

  const { data: previousSession, error: previousSessionError } = await supabase
    .from("workout_sessions")
    .select("id,session_date")
    .eq("user_id", userId)
    .eq("routine_day_id", sessionRow.routine_day_id)
    .not("completed_at", "is", null)
    .lt("session_date", sessionRow.session_date)
    .order("session_date", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (previousSessionError) {
    logError("PREVIOUS_SESSION_ERROR", { user_id: userId, session_id: sessionId, message: previousSessionError.message });
    return json(500, { success: false, code: "PREVIOUS_SESSION_ERROR", error: { message: previousSessionError.message } });
  }

  let previousLogs: SetRow[] = [];
  if (previousSession?.id) {
    const { data: prevLogsRaw, error: prevLogsError } = await supabase
      .from("set_logs")
      .select("exercise_id,actual_weight,actual_reps")
      .eq("session_id", previousSession.id)
      .order("set_index", { ascending: true });

    if (prevLogsError) {
      logError("PREVIOUS_LOGS_ERROR", { user_id: userId, session_id: sessionId, message: prevLogsError.message });
      return json(500, { success: false, code: "PREVIOUS_LOGS_ERROR", error: { message: prevLogsError.message } });
    }

    previousLogs = (prevLogsRaw ?? []) as SetRow[];
  }

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
