import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { jsonResponse, preflight } from "../_shared/cors.ts";
import { logError, logInfo, requireUser } from "../_shared/auth.ts";
import { enforceRateLimit } from "../_shared/rate_limit.ts";

const RATE_LIMIT = {
  functionName: "delete_account_v1",
  windowSeconds: 60,
  maxCalls: 5,
} as const;

/** Palabra que el usuario escribe en la app para confirmar el borrado. */
const CONFIRMATION_WORD = "ELIMINAR";

type DeletePayload = {
  confirm?: unknown;
};

type StepResult =
  | { ok: true; data: unknown }
  | { ok: false; message: string };

async function deleteAccountData(
  admin: SupabaseClient,
  userId: string,
): Promise<StepResult> {
  // `delete_account_data_v1` sólo es ejecutable por service_role: no compara
  // contra auth.uid(), así que el userId sale siempre del JWT validado.
  const { data, error } = await admin.rpc("delete_account_data_v1", {
    p_user_id: userId,
  });
  if (error) return { ok: false, message: error.message };
  return { ok: true, data };
}

async function deleteAuthUser(
  admin: SupabaseClient,
  userId: string,
): Promise<StepResult> {
  const { error } = await admin.auth.admin.deleteUser(userId);
  if (error) return { ok: false, message: error.message };
  return { ok: true, data: null };
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

  let payload: DeletePayload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse(400, {
      success: false,
      code: "INVALID_JSON",
      error: { message: "Invalid request body" },
    });
  }

  // Confirmación explícita: evita que un cliente con bug (o un replay de
  // otra function) borre la cuenta por accidente.
  if (payload?.confirm !== CONFIRMATION_WORD) {
    return jsonResponse(400, {
      success: false,
      code: "CONFIRMATION_REQUIRED",
      error: { message: `confirm must be "${CONFIRMATION_WORD}"` },
    });
  }

  logInfo("DELETE_ACCOUNT_REQUEST", { user_id: userId });

  const dataResult = await deleteAccountData(admin, userId);
  if (!dataResult.ok) {
    logError("DELETE_ACCOUNT_DATA_ERROR", {
      user_id: userId,
      message: dataResult.message,
    });
    return jsonResponse(500, {
      success: false,
      code: "DELETE_ACCOUNT_DATA_ERROR",
      error: { message: "No se pudieron borrar los datos de la cuenta" },
    });
  }

  let authResult = await deleteAuthUser(admin, userId);
  if (!authResult.ok) {
    // Lo más probable es una fila nueva que referencia al usuario (p. ej.
    // el SyncWorker del cliente subió una serie entre la RPC y este paso).
    // La RPC es idempotente: se repite una vez y se reintenta el borrado.
    logError("DELETE_AUTH_USER_RETRY", {
      user_id: userId,
      message: authResult.message,
    });
    const retryData = await deleteAccountData(admin, userId);
    if (retryData.ok) authResult = await deleteAuthUser(admin, userId);
  }

  if (!authResult.ok) {
    // Los datos ya se borraron pero el usuario de Auth sigue existiendo: el
    // cliente puede reintentar (todo el flujo es idempotente).
    logError("DELETE_AUTH_USER_ERROR", {
      user_id: userId,
      message: authResult.message,
    });
    return jsonResponse(500, {
      success: false,
      code: "DELETE_AUTH_USER_ERROR",
      error: { message: "No se pudo eliminar el usuario" },
    });
  }

  logInfo("DELETE_ACCOUNT_DONE", {
    user_id: userId,
    deleted: dataResult.data,
  });

  return jsonResponse(200, {
    success: true,
    code: "ACCOUNT_DELETED",
    data: {
      user_id: userId,
      deleted: dataResult.data,
    },
  });
});
