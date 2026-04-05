import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

type SessionRow = {
  id: string;
  routine_day_id: string;
  session_date: string;
  completed_at: string | null;
};

type SetLogRow = {
  exercise_id: string;
  actual_weight: number;
  actual_reps: number;
  workout_sessions?: {
    session_date?: string;
    routine_day_id?: string;
  } | null;
};

type WeekPayload = {
  routine_id?: string;
  week_start?: string;
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

function toDateOnly(input: Date): string {
  const y = input.getUTCFullYear().toString().padStart(4, "0");
  const m = (input.getUTCMonth() + 1).toString().padStart(2, "0");
  const d = input.getUTCDate().toString().padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function toUTCDate(input: string): Date | null {
  const parsed = new Date(`${input}T00:00:00.000Z`);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return parsed;
}

function logInfo(code: string, details: Record<string, unknown>): void {
  console.log(JSON.stringify({ level: "info", code, ...details }));
}

function logError(code: string, details: Record<string, unknown>): void {
  console.error(JSON.stringify({ level: "error", code, ...details }));
}

// Extract user_id from JWT without validation (already validated by client)
function extractUserIdFromJWT(token: string): string | null {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;

    const payload = JSON.parse(atob(parts[1]));
    // Try 'sub' field (standard JWT), or 'id' field (Supabase custom)
    return payload.sub ?? payload.id ?? null;
  } catch (error) {
    console.error("Error decoding JWT:", error);
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

  let payload: WeekPayload;
  try {
    payload = await req.json();
  } catch {
    return json(400, { success: false, code: "INVALID_JSON", error: { message: "Invalid request body" } });
  }

  if (!payload.routine_id) {
    return json(400, { success: false, code: "VALIDATION_ERROR", error: { message: "routine_id is required" } });
  }

  const weekStartDate = payload.week_start ? toUTCDate(payload.week_start) : null;
  if (payload.week_start && weekStartDate == null) {
    return json(400, { success: false, code: "VALIDATION_ERROR", error: { message: "week_start must be YYYY-MM-DD" } });
  }

  const now = new Date();
  const fallbackStart = new Date(Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate() - ((now.getUTCDay() + 6) % 7),
  ));

  const weekStart = weekStartDate ?? fallbackStart;
  const weekEnd = new Date(weekStart);
  weekEnd.setUTCDate(weekEnd.getUTCDate() + 6);

  const prevWeekStart = new Date(weekStart);
  prevWeekStart.setUTCDate(prevWeekStart.getUTCDate() - 7);

  const prevWeekEnd = new Date(weekStart);
  prevWeekEnd.setUTCDate(prevWeekEnd.getUTCDate() - 1);

  const weekStartStr = toDateOnly(weekStart);
  const weekEndStr = toDateOnly(weekEnd);
  const prevWeekStartStr = toDateOnly(prevWeekStart);
  const prevWeekEndStr = toDateOnly(prevWeekEnd);

  logInfo("INSIGHTS_REQUEST", {
    user_id: userId,
    routine_id: payload.routine_id,
    week_start: weekStartStr,
    week_end: weekEndStr,
  });

  const { data: routineDays, error: routineDaysError } = await supabase
    .from("routine_days")
    .select("id")
    .eq("routine_id", payload.routine_id);

  if (routineDaysError) {
    logError("ROUTINE_DAYS_ERROR", {
      user_id: userId,
      routine_id: payload.routine_id,
      message: routineDaysError.message,
    });
    return json(500, { success: false, code: "ROUTINE_DAYS_ERROR", error: { message: routineDaysError.message } });
  }

  const routineDayIds = (routineDays ?? []).map((row) => row.id as string);

  if (routineDayIds.length === 0) {
    return json(200, {
      success: true,
      code: "WEEKLY_INSIGHTS_READY",
      data: {
        week_start: weekStartStr,
        week_end: weekEndStr,
        planned_days: 0,
        completed_days: 0,
        completed_sessions: 0,
        adherence_rate: 0,
        total_volume: 0,
        previous_week_volume: 0,
        volume_trend_percent: 0,
        personal_records: 0,
      },
    });
  }

  const { data: sessionsRaw, error: sessionsError } = await supabase
    .from("workout_sessions")
    .select("id,routine_day_id,session_date,completed_at")
    .eq("user_id", userId)
    .in("routine_day_id", routineDayIds)
    .gte("session_date", weekStartStr)
    .lte("session_date", weekEndStr);

  if (sessionsError) {
    logError("SESSIONS_ERROR", {
      user_id: userId,
      routine_id: payload.routine_id,
      message: sessionsError.message,
    });
    return json(500, { success: false, code: "SESSIONS_ERROR", error: { message: sessionsError.message } });
  }

  const sessions = (sessionsRaw ?? []) as SessionRow[];
  const completedSessions = sessions.filter((s) => s.completed_at != null);
  const completedDays = new Set(completedSessions.map((s) => s.routine_day_id)).size;
  const plannedDays = routineDayIds.length;
  const adherenceRate = plannedDays > 0 ? (completedDays / plannedDays) * 100 : 0;

  const getVolumeForRange = async (startDate: string, endDate: string): Promise<number> => {
    const { data: setRowsRaw, error: setRowsError } = await supabase
      .from("set_logs")
      .select("actual_weight,actual_reps,workout_sessions!inner(session_date,user_id,routine_day_id)")
        .eq("workout_sessions.user_id", userId)
      .in("workout_sessions.routine_day_id", routineDayIds)
      .gte("workout_sessions.session_date", startDate)
      .lte("workout_sessions.session_date", endDate);

    if (setRowsError) {
      throw setRowsError;
    }

    const setRows = (setRowsRaw ?? []) as SetLogRow[];
    return setRows.reduce<number>(
      (sum, row) => sum + (Number(row.actual_weight ?? 0) * Number(row.actual_reps ?? 0)),
      0,
    );
  };

  let totalVolume = 0;
  let previousWeekVolume = 0;

  try {
    totalVolume = await getVolumeForRange(weekStartStr, weekEndStr);
    previousWeekVolume = await getVolumeForRange(prevWeekStartStr, prevWeekEndStr);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logError("VOLUME_QUERY_ERROR", {
      user_id: userId,
      routine_id: payload.routine_id,
      message,
    });
    return json(500, { success: false, code: "VOLUME_QUERY_ERROR", error: { message } });
  }

  const volumeTrendPercent = previousWeekVolume <= 0
    ? (totalVolume > 0 ? 100 : 0)
    : ((totalVolume - previousWeekVolume) / previousWeekVolume) * 100;

  const { data: weeklyLogsRaw, error: weeklyLogsError } = await supabase
    .from("set_logs")
    .select("exercise_id,actual_weight,workout_sessions!inner(session_date,user_id,routine_day_id)")
    .eq("workout_sessions.user_id", userId)
    .in("workout_sessions.routine_day_id", routineDayIds)
    .gte("workout_sessions.session_date", weekStartStr)
    .lte("workout_sessions.session_date", weekEndStr);

  if (weeklyLogsError) {
    logError("WEEKLY_LOGS_ERROR", {
      user_id: userId,
      routine_id: payload.routine_id,
      message: weeklyLogsError.message,
    });
    return json(500, { success: false, code: "WEEKLY_LOGS_ERROR", error: { message: weeklyLogsError.message } });
  }

  const { data: previousLogsRaw, error: previousLogsError } = await supabase
    .from("set_logs")
    .select("exercise_id,actual_weight,workout_sessions!inner(session_date,user_id,routine_day_id)")
    .eq("workout_sessions.user_id", userId)
    .in("workout_sessions.routine_day_id", routineDayIds)
    .lt("workout_sessions.session_date", weekStartStr);

  if (previousLogsError) {
    logError("PREVIOUS_LOGS_ERROR", {
      user_id: userId,
      routine_id: payload.routine_id,
      message: previousLogsError.message,
    });
    return json(500, { success: false, code: "PREVIOUS_LOGS_ERROR", error: { message: previousLogsError.message } });
  }

  const weeklyLogs = (weeklyLogsRaw ?? []) as SetLogRow[];
  const previousLogs = (previousLogsRaw ?? []) as SetLogRow[];

  const weekMaxByExercise = new Map<string, number>();
  for (const row of weeklyLogs) {
    const prev = weekMaxByExercise.get(row.exercise_id) ?? 0;
    const value = Number(row.actual_weight ?? 0);
    if (value > prev) {
      weekMaxByExercise.set(row.exercise_id, value);
    }
  }

  const prevMaxByExercise = new Map<string, number>();
  for (const row of previousLogs) {
    const prev = prevMaxByExercise.get(row.exercise_id) ?? 0;
    const value = Number(row.actual_weight ?? 0);
    if (value > prev) {
      prevMaxByExercise.set(row.exercise_id, value);
    }
  }

  let personalRecords = 0;
  for (const [exerciseId, maxThisWeek] of weekMaxByExercise.entries()) {
    const prevMax = prevMaxByExercise.get(exerciseId) ?? 0;
    if (maxThisWeek > prevMax && maxThisWeek > 0) {
      personalRecords += 1;
    }
  }

  const responseData = {
    week_start: weekStartStr,
    week_end: weekEndStr,
    planned_days: plannedDays,
    completed_days: completedDays,
    completed_sessions: completedSessions.length,
    adherence_rate: Number(adherenceRate.toFixed(2)),
    total_volume: Number(totalVolume.toFixed(2)),
    previous_week_volume: Number(previousWeekVolume.toFixed(2)),
    volume_trend_percent: Number(volumeTrendPercent.toFixed(2)),
    personal_records: personalRecords,
  };

  logInfo("INSIGHTS_READY", {
    user_id: userId,
    routine_id: payload.routine_id,
    ...responseData,
  });

  return json(200, {
    success: true,
    code: "WEEKLY_INSIGHTS_READY",
    data: responseData,
  });
});
