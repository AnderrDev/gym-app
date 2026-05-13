import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";
import { jsonResponse } from "./cors.ts";

export type AuthSuccess = {
  ok: true;
  userId: string;
  token: string;
  admin: SupabaseClient;
};

export type AuthFailure = {
  ok: false;
  response: Response;
};

export type AuthResult = AuthSuccess | AuthFailure;

export function logInfo(code: string, details: Record<string, unknown>): void {
  console.log(JSON.stringify({ level: "info", code, ...details }));
}

export function logError(code: string, details: Record<string, unknown>): void {
  console.error(JSON.stringify({ level: "error", code, ...details }));
}

function adminClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}

/**
 * Reads the Authorization header, validates the JWT against Supabase Auth via
 * `auth.getUser(token)` and returns the authenticated user_id. Refuses anon /
 * service_role tokens by requiring a real user record. The gateway already
 * validates the JWT signature when `verify_jwt: true`; this re-validation is
 * defense in depth.
 */
export async function requireUser(req: Request): Promise<AuthResult> {
  const header = req.headers.get("Authorization") ?? "";
  if (!header.toLowerCase().startsWith("bearer ")) {
    logError("AUTH_MISSING_BEARER", {});
    return {
      ok: false,
      response: jsonResponse(401, {
        success: false,
        code: "UNAUTHORIZED",
        error: { message: "Missing Authorization Bearer token" },
      }),
    };
  }

  const token = header.slice("bearer ".length).trim();
  if (!token) {
    return {
      ok: false,
      response: jsonResponse(401, {
        success: false,
        code: "UNAUTHORIZED",
        error: { message: "Empty Bearer token" },
      }),
    };
  }

  const admin = adminClient();
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data?.user?.id) {
    logError("AUTH_INVALID_TOKEN", { reason: error?.message ?? "no_user" });
    return {
      ok: false,
      response: jsonResponse(401, {
        success: false,
        code: "UNAUTHORIZED",
        error: { message: "Invalid or expired token" },
      }),
    };
  }

  return { ok: true, userId: data.user.id, token, admin };
}
