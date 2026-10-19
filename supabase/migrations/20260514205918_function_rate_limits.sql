-- ============================================================
-- Rate limiting para Edge Functions.
-- Modelo: fixed-window counter por (user_id, function_name, window_start).
-- La función `enforce_rate_limit` hace upsert atómico y devuelve si la
-- llamada queda dentro del límite. Las Edge Functions la invocan justo
-- después de `requireUser` para abortar con 429 si el usuario excede su
-- presupuesto.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.function_rate_limits (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  function_name TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, function_name, window_start)
);

-- Índice para limpieza periódica de ventanas viejas (job opcional).
CREATE INDEX IF NOT EXISTS idx_function_rate_limits_window_start
  ON public.function_rate_limits (window_start);

-- RLS: tabla interna. Nadie la lee directamente desde el cliente; la
-- function `enforce_rate_limit` (SECURITY DEFINER) y el service_role la
-- manipulan. Sin políticas → todo bloqueado para roles autenticados.
ALTER TABLE public.function_rate_limits ENABLE ROW LEVEL SECURITY;

-- ── enforce_rate_limit -----------------------------------------------
-- Devuelve (allowed, current_count, reset_at).
--   allowed     = true si current_count <= p_max_calls
--   current_count = número de invocaciones en la ventana actual
--   reset_at    = momento en que la ventana actual termina
-- Hace el INSERT/UPDATE atómico contra el bucket de la ventana actual.
CREATE OR REPLACE FUNCTION public.enforce_rate_limit(
  p_user_id UUID,
  p_function TEXT,
  p_window_seconds INTEGER,
  p_max_calls INTEGER
)
RETURNS TABLE (
  allowed BOOLEAN,
  current_count INTEGER,
  reset_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_window_start TIMESTAMPTZ;
  v_count INTEGER;
BEGIN
  -- Validación de input: la función la llama el helper TS, no clientes.
  IF p_window_seconds <= 0 OR p_max_calls <= 0 THEN
    RAISE EXCEPTION 'invalid rate limit config' USING ERRCODE = '22023';
  END IF;

  v_window_start := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds
  );

  INSERT INTO public.function_rate_limits(
    user_id, function_name, window_start, count
  )
  VALUES (p_user_id, p_function, v_window_start, 1)
  ON CONFLICT (user_id, function_name, window_start)
  DO UPDATE SET count = public.function_rate_limits.count + 1
  RETURNING public.function_rate_limits.count INTO v_count;

  RETURN QUERY
  SELECT
    v_count <= p_max_calls,
    v_count,
    v_window_start + make_interval(secs => p_window_seconds);
END;
$function$;

-- Solo el service_role debe invocar esta RPC; revocamos al rol authenticated
-- para que un cliente comprometido no pueda saturar artificialmente su
-- propio bucket.
REVOKE EXECUTE ON FUNCTION public.enforce_rate_limit(UUID, TEXT, INTEGER, INTEGER)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.enforce_rate_limit(UUID, TEXT, INTEGER, INTEGER)
  TO service_role;
