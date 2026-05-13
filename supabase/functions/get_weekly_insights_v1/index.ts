import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { jsonResponse, preflight } from "../_shared/cors.ts";
import { logError, logInfo, requireUser } from "../_shared/auth.ts";
import { enforceRateLimit } from "../_shared/rate_limit.ts";

const RATE_LIMIT = {
  functionName: "get_weekly_insights_v1",
  windowSeconds: 60,
  maxCalls: 60,
} as const;

type WeekPayload = {
  routine_id?: string;
  week_start?: string;
};

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

  let payload: WeekPayload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse(400, {
      success: false,
      code: "INVALID_JSON",
      error: { message: "Invalid request body" },
    });
  }

  if (!payload.routine_id) {
    return jsonResponse(400, {
      success: false,
      code: "VALIDATION_ERROR",
      error: { message: "routine_id is required" },
    });
  }

  const weekStartDate = payload.week_start ? toUTCDate(payload.week_start) : null;
  if (payload.week_start && weekStartDate == null) {
    return jsonResponse(400, {
      success: false,
      code: "VALIDATION_ERROR",
      error: { message: "week_start must be YYYY-MM-DD" },
    });
  }

  const weekStartStr = weekStartDate ? toDateOnly(weekStartDate) : null;

  logInfo("INSIGHTS_REQUEST", {
    user_id: userId,
    routine_id: payload.routine_id,
    week_start: weekStartStr,
  });

  const { data: rpcRows, error: rpcError } = await admin
    .rpc("compute_weekly_insights_v1", {
      p_user_id: userId,
      p_routine_id: payload.routine_id,
      p_week_start: weekStartStr,
    })
    .limit(1)
    .maybeSingle();

  if (rpcError) {
    logError("INSIGHTS_RPC_ERROR", {
      user_id: userId,
      routine_id: payload.routine_id,
      message: rpcError.message,
    });
    return jsonResponse(500, {
      success: false,
      code: "INSIGHTS_RPC_ERROR",
      error: { message: rpcError.message },
    });
  }

  const responseData = rpcRows ?? {
    week_start: weekStartStr,
    week_end: weekStartStr,
    planned_days: 0,
    completed_days: 0,
    completed_sessions: 0,
    adherence_rate: 0,
    total_volume: 0,
    previous_week_volume: 0,
    volume_trend_percent: 0,
    personal_records: 0,
  };

  logInfo("INSIGHTS_READY", {
    user_id: userId,
    routine_id: payload.routine_id,
  });

  return jsonResponse(200, {
    success: true,
    code: "WEEKLY_INSIGHTS_READY",
    data: responseData,
  });
});
