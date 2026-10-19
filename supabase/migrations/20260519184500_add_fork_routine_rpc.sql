-- ──────────────────────────────────────────────────────────────────────────
-- fork_routine_v1
-- ──────────────────────────────────────────────────────────────────────────
-- Permite a un usuario crear una copia ("fork") de una rutina que puede ver
-- (propia o pública). La copia queda con `creator_id = auth.uid()` e
-- `is_public = false`, y replica todos los días y ejercicios manteniendo
-- targets y orden. Sirve como base del flujo "Crear mi copia" cuando un
-- usuario quiere modificar una rutina pública sin tener permisos de UPDATE
-- sobre la original.
--
-- Atómica (PLPGSQL bloque single-transaction). SECURITY DEFINER porque
-- necesitamos validar visibilidad del source y persistir el creator_id sin
-- depender de las RLS WITH CHECK del invoker (que sólo dejarían insertar si
-- ya fuese owner). El gate sigue siendo `auth.uid()`.

CREATE OR REPLACE FUNCTION public.fork_routine_v1(
  p_source_routine_id uuid,
  p_new_name text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_source RECORD;
  v_new_routine_id uuid;
  v_new_name text;
  v_day RECORD;
  v_new_day_id uuid;
BEGIN
  -- Requiere usuario autenticado.
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'fork_routine_v1: not authenticated'
      USING ERRCODE = '28000';
  END IF;

  -- Validamos visibilidad: la rutina debe ser pública o pertenecer al caller.
  SELECT r.id, r.name, r.is_public, r.creator_id
    INTO v_source
    FROM public.routines r
   WHERE r.id = p_source_routine_id
     AND (r.is_public = true OR r.creator_id = v_uid);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'fork_routine_v1: source routine not found or not visible'
      USING ERRCODE = '42501';
  END IF;

  -- Nombre por defecto: "<name> (mi copia)". El cliente puede sobreescribir.
  v_new_name := COALESCE(
    NULLIF(BTRIM(p_new_name), ''),
    v_source.name || ' (mi copia)'
  );

  -- 1) Routine
  INSERT INTO public.routines (name, is_public, creator_id)
       VALUES (v_new_name, false, v_uid)
    RETURNING id INTO v_new_routine_id;

  -- 2) Días + ejercicios (copiamos preservando day_of_week, order y targets).
  FOR v_day IN
    SELECT id, day_of_week, name
      FROM public.routine_days
     WHERE routine_id = p_source_routine_id
     ORDER BY day_of_week ASC
  LOOP
    INSERT INTO public.routine_days (routine_id, day_of_week, name)
         VALUES (v_new_routine_id, v_day.day_of_week, v_day.name)
      RETURNING id INTO v_new_day_id;

    INSERT INTO public.routine_exercises (
      routine_day_id, exercise_id, "order",
      target_sets, target_reps, target_weight, rest_timer_seconds
    )
    SELECT v_new_day_id, re.exercise_id, re."order",
           re.target_sets, re.target_reps, re.target_weight, re.rest_timer_seconds
      FROM public.routine_exercises re
     WHERE re.routine_day_id = v_day.id;
  END LOOP;

  RETURN v_new_routine_id;
END;
$$;

-- Supabase concede EXECUTE por default a anon/authenticated/service_role al
-- crear funciones. Revocamos el rol `anon` (la función igual rechaza llamadas
-- sin auth, pero defensa en profundidad) y dejamos sólo authenticated +
-- service_role + el owner postgres.
REVOKE ALL ON FUNCTION public.fork_routine_v1(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fork_routine_v1(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.fork_routine_v1(uuid, text) TO authenticated;

COMMENT ON FUNCTION public.fork_routine_v1(uuid, text) IS
  'Crea una copia privada de una rutina visible para el caller (pública o propia). Devuelve el id de la nueva rutina.';
