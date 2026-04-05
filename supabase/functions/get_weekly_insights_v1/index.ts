import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

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

  const weekStartStr = weekStartDate ? toDateOnly(weekStartDate) : null;

  logInfo("INSIGHTS_REQUEST", {
    user_id: userId,
    routine_id: payload.routine_id,
    week_start: weekStartStr,
  });

  const { data: rpcRows, error: rpcError } = await supabase
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
    return json(500, {
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
    ...responseData,
  });

  return json(200, {
    success: true,
    code: "WEEKLY_INSIGHTS_READY",
    data: responseData,
  });
});
