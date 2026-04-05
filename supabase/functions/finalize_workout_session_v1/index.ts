import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

function logInfo(code: string, details: Record<string, unknown>): void {
  console.log(JSON.stringify({ level: "info", code, ...details }));
}

function logError(code: string, details: Record<string, unknown>): void {
  console.error(JSON.stringify({ level: "error", code, ...details }));
}

// Extract user_id from JWT without signature verification (signature validation should be done by Supabase Gateway if verify_jwt is true)
// We use this when verify_jwt is false for debugging or specific architecture needs.
function extractUserIdFromJWT(token: string): string | null {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) {
      logError("JWT_PARTS_INVALID", { parts: parts.length, token_preview: token.substring(0, 10) });
      return null;
    }

    const payloadRaw = atob(parts[1]);
    const payload = JSON.parse(payloadRaw);
    
    // Log payload for debugging (BE CAREFUL with PII, but here we need to see 'sub', 'aud', 'exp')
    logInfo("JWT_DEBUG_PAYLOAD", { 
      sub: payload.sub, 
      aud: payload.aud, 
      iss: payload.iss,
      exp: payload.exp,
      role: payload.role
    });
    
    const userId = payload.sub ?? payload.id ?? null;
    return userId;
  } catch (e) {
    logError("JWT_PARSE_ERROR", { error: String(e) });
    return null;
  }
}

Deno.serve(async (req: Request) => {
  // CORS handling
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-user-token" } });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ success: false, code: "METHOD_NOT_ALLOWED", error: { message: "Use POST" } }),
      { status: 405, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } },
    );
  }

  // Debug headers
  const authHeader = req.headers.get("Authorization");
  const xUserToken = req.headers.get("X-User-Token");
  const apiKey = req.headers.get("apikey");
  
  logInfo("HEADERS_DEBUG", { 
    hasAuth: !!authHeader, 
    authPrefix: authHeader?.substring(0, 15),
    hasXUser: !!xUserToken,
    hasApiKey: !!apiKey 
  });

  let token = authHeader;
  if (token?.startsWith("Bearer ")) {
    token = token.substring(7);
  } else {
    token = xUserToken ?? null;
  }

  let userId = "unknown";
  if (token) {
    const extracted = extractUserIdFromJWT(token);
    if (extracted) {
      userId = extracted;
      logInfo("USER_IDENTIFIED", { user_id: userId });
    } else {
      logError("USER_IDENTIFICATION_FAILED", { token_length: token.length });
    }
  } else {
    logError("NO_TOKEN_FOUND", {});
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  let payload: { session_id?: string; coaching_analysis?: unknown };
  try {
    payload = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ success: false, code: "INVALID_JSON", error: { message: "Invalid request body" } }),
      { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } },
    );
  }

  const sessionId = payload.session_id;
  if (!sessionId) {
    return new Response(
      JSON.stringify({ success: false, code: "VALIDATION_ERROR", error: { message: "session_id is required" } }),
      { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } },
    );
  }

  if (userId === "unknown") {
    return new Response(
      JSON.stringify({ success: false, code: "UNAUTHORIZED", error: { message: "Invalid or missing user token" } }),
      { status: 401, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } },
    );
  }

  logInfo("FINALIZE_START", { user_id: userId, session_id: sessionId });

  const updateData: Record<string, unknown> = {
    completed_at: new Date().toISOString(),
  };

  // Logic for coaching analysis
  if (payload.coaching_analysis !== undefined) {
    updateData.coaching_analysis = payload.coaching_analysis;
  } else {
    try {
      const { data: coachingResult, error: coachingError } = await supabase.functions.invoke(
        "generate_coaching_v1",
        {
          body: { session_id: sessionId, user_id: userId },
          headers: token ? { "X-User-Token": token } : undefined,
        },
      );

      if (!coachingError && coachingResult?.data?.analysis) {
        updateData.coaching_analysis = coachingResult.data.analysis;
      }
    } catch (e) {
      logInfo("COACHING_INVOKE_FAILED", { error: String(e) });
    }
  }

  const { data: updatedRows, error: updateError } = await supabase
    .from("workout_sessions")
    .update(updateData)
    .eq("id", sessionId)
    .eq("user_id", userId)
    .is("completed_at", null)
    .select("id")
    .limit(1);

  if (updateError) {
    logError("DB_UPDATE_ERROR", { message: updateError.message });
    return new Response(
      JSON.stringify({ success: false, code: "DB_UPDATE_ERROR", error: { message: updateError.message } }),
      { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } },
    );
  }

  if (!updatedRows || updatedRows.length === 0) {
    return new Response(
      JSON.stringify({ success: false, code: "NOT_FOUND_OR_COMPLETED", error: { message: "Session not found or already completed" } }),
      { status: 404, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } },
    );
  }

  return new Response(
    JSON.stringify({ success: true, code: "SESSION_COMPLETED", data: { session_id: sessionId } }),
    { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } },
  );
});
