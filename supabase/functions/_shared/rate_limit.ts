import { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { jsonResponse } from "./cors.ts";
import { logError, logInfo } from "./auth.ts";

export type RateLimitConfig = {
  /**
   * Identificador estable de la function. Forma parte del bucket — cambiarlo
   * resetea el contador efectivo.
   */
  functionName: string;
  /** Ventana fija en segundos (típicamente 60). */
  windowSeconds: number;
  /** Llamadas máximas dentro de la ventana. */
  maxCalls: number;
};

export type RateLimitResult =
  | { ok: true }
  | { ok: false; response: Response };

/**
 * Verifica e incrementa atómicamente el bucket del usuario para esta function.
 * Devuelve `{ok: true}` si la llamada queda dentro del límite, o un `Response`
 * 429 listo para devolver si no.
 *
 * Política de fallo: si la RPC falla por motivos de plataforma (DB caída,
 * timeout) preferimos *fail open* — el usuario no debería verse bloqueado por
 * problemas internos. El error queda logueado para alertar.
 */
export async function enforceRateLimit(
  admin: SupabaseClient,
  userId: string,
  cfg: RateLimitConfig,
): Promise<RateLimitResult> {
  const { data, error } = await admin.rpc("enforce_rate_limit", {
    p_user_id: userId,
    p_function: cfg.functionName,
    p_window_seconds: cfg.windowSeconds,
    p_max_calls: cfg.maxCalls,
  });

  if (error) {
    logError("RATE_LIMIT_RPC_ERROR", {
      function_name: cfg.functionName,
      message: error.message,
    });
    return { ok: true };
  }

  const row = Array.isArray(data) ? data[0] : data;
  if (!row || row.allowed === true) {
    return { ok: true };
  }

  logInfo("RATE_LIMIT_EXCEEDED", {
    function_name: cfg.functionName,
    user_id: userId,
    current_count: row.current_count,
  });

  return {
    ok: false,
    response: jsonResponse(429, {
      success: false,
      code: "RATE_LIMIT_EXCEEDED",
      error: {
        message:
          `Demasiadas llamadas a ${cfg.functionName}. Intenta de nuevo más tarde.`,
        reset_at: row.reset_at,
        limit: cfg.maxCalls,
        window_seconds: cfg.windowSeconds,
      },
    }),
  };
}
