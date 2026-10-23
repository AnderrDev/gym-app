import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { jsonResponse, preflight } from "../_shared/cors.ts";
import { logError, logInfo, requireUser, userClient } from "../_shared/auth.ts";
import { enforceRateLimit } from "../_shared/rate_limit.ts";
import { analyzeSession, type CoachingInputs } from "./engine.ts";

const RATE_LIMIT = {
  functionName: "generate_coaching_v1",
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
  const { userId, admin, token } = auth;

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

  // La RPC valida `p_user_id = auth.uid()` — sólo resuelve al uid real si la
  // call viaja con el JWT del usuario, no con service_role.
  const { data: rpcPayload, error: rpcError } = await userClient(token)
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

  const analysis = analyzeSession(inputs);

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
