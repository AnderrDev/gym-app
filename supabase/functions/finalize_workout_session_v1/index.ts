import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { jsonResponse, preflight } from "../_shared/cors.ts";
import { logError, logInfo, requireUser } from "../_shared/auth.ts";
import { enforceRateLimit } from "../_shared/rate_limit.ts";

const MAX_COACHING_BYTES = 64 * 1024;
const RATE_LIMIT = {
  functionName: "finalize_workout_session_v1",
  windowSeconds: 60,
  maxCalls: 30,
} as const;

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
  const { userId, token, admin } = auth;

  const rate = await enforceRateLimit(admin, userId, RATE_LIMIT);
  if (!rate.ok) return rate.response;

  let payload: { session_id?: string; coaching_analysis?: unknown };
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

  logInfo("FINALIZE_START", { user_id: userId, session_id: sessionId });

  const updateData: Record<string, unknown> = {
    completed_at: new Date().toISOString(),
  };

  // Si falla la generación de coaching, NO bloqueamos el cierre de la
  // sesión (UX prioritaria) pero devolvemos `warning_code` en la
  // respuesta para que el cliente pueda reintentar o avisar al usuario.
  let coachingWarning: string | null = null;

  if (payload.coaching_analysis !== undefined) {
    const serialized = JSON.stringify(payload.coaching_analysis);
    if (serialized.length > MAX_COACHING_BYTES) {
      return jsonResponse(413, {
        success: false,
        code: "COACHING_TOO_LARGE",
        error: { message: `coaching_analysis exceeds ${MAX_COACHING_BYTES} bytes` },
      });
    }
    if (!Array.isArray(payload.coaching_analysis)) {
      return jsonResponse(400, {
        success: false,
        code: "VALIDATION_ERROR",
        error: { message: "coaching_analysis must be an array" },
      });
    }
    updateData.coaching_analysis = payload.coaching_analysis;
  } else {
    try {
      const { data: coachingResult, error: coachingError } = await admin.functions
        .invoke("generate_coaching_v1", {
          body: { session_id: sessionId },
          headers: { Authorization: `Bearer ${token}` },
        });

      if (!coachingError && coachingResult?.data?.analysis) {
        updateData.coaching_analysis = coachingResult.data.analysis;
      } else {
        coachingWarning = "COACHING_GENERATION_FAILED";
        logInfo("COACHING_INVOKE_NO_DATA", {
          session_id: sessionId,
          has_error: Boolean(coachingError),
        });
      }
    } catch (_e) {
      coachingWarning = "COACHING_GENERATION_FAILED";
      logInfo("COACHING_INVOKE_FAILED", { session_id: sessionId });
    }
  }

  const { data: updatedRows, error: updateError } = await admin
    .from("workout_sessions")
    .update(updateData)
    .eq("id", sessionId)
    .eq("user_id", userId)
    .is("completed_at", null)
    .select("id")
    .limit(1);

  if (updateError) {
    logError("DB_UPDATE_ERROR", { message: updateError.message });
    return jsonResponse(500, {
      success: false,
      code: "DB_UPDATE_ERROR",
      error: { message: updateError.message },
    });
  }

  if (!updatedRows || updatedRows.length === 0) {
    return jsonResponse(404, {
      success: false,
      code: "NOT_FOUND_OR_COMPLETED",
      error: { message: "Session not found or already completed" },
    });
  }

  // Best-effort summary desde la vista. Si falla, devolvemos sin él para
  // no bloquear la confirmación de cierre (el dashboard recargará igual).
  const { data: summaryRow } = await admin
    .from("view_workout_sessions_summary")
    .select(
      "id, user_id, routine_day_id, session_date, completed_at, total_target_sets, total_completed_sets, is_strictly_completed",
    )
    .eq("id", sessionId)
    .maybeSingle();

  const data: Record<string, unknown> = { session_id: sessionId };
  if (summaryRow) data.summary = summaryRow;
  if (coachingWarning) data.warning_code = coachingWarning;

  return jsonResponse(200, {
    success: true,
    code: "SESSION_COMPLETED",
    data,
  });
});
