-- ============================================================
-- Eliminar cuenta (App Store 5.1.1(v)).
--
-- Decisión de producto: al borrar la cuenta, las rutinas PÚBLICAS del
-- usuario se anonimizan (`creator_id = NULL`) y siguen disponibles para quien
-- las tenga asignadas o las quiera copiar. Todo lo demás se borra: series,
-- sesiones, asignaciones, rutinas privadas (días + ejercicios de rutina),
-- rate limits y perfil. La Edge Function `delete_account_v1` llama a
-- `delete_account_data_v1` con service_role y después borra `auth.users`.
--
-- Columna de dueño de `routines`: es `creator_id` (nullable). Evidencia:
--   * Las políticas RLS `routines_*` (20260514211812) y las de
--     routine_days/routine_exercises (20260516001027) usan `creator_id`; una
--     política se valida contra el catálogo al crearse, así que la columna
--     existe en la base desplegada.
--   * `routines_view`, `fork_routine_v1`, seeds y el cliente
--     (`routine_management_remote_data_source.dart`) leen/escriben
--     `creator_id`.
--   * `supabase/seeds/recomposition_ulppl_12_weeks.sql` inserta rutinas de
--     catálogo con `creator_id = NULL`, así que ya acepta NULL (el DROP NOT
--     NULL de abajo es sólo defensivo).
--   * `reorder_routine_exercises` (20260520180000) usa `r.user_id`: plpgsql
--     no valida columnas al crear la función, así que el error sólo saltaría
--     al ejecutarla. Se reescribe abajo con `creator_id`.
--
-- Parte del esquema base se creó desde el dashboard y no está en el repo, por
-- eso los cambios de FK se hacen buscando las constraints en `pg_constraint`
-- en lugar de asumir nombres.
-- ============================================================

-- ── 1. routines.creator_id: nullable + FK ON DELETE SET NULL ─────────────
DO $$
DECLARE
  v_fk record;
  v_ref_col text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name = 'routines'
       AND column_name = 'creator_id'
  ) THEN
    RAISE EXCEPTION 'delete_account: public.routines.creator_id no existe; revisar el esquema antes de aplicar';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name = 'routines'
       AND column_name = 'creator_id'
       AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE public.routines ALTER COLUMN creator_id DROP NOT NULL;
  END IF;

  -- Cualquier FK de una sola columna sobre creator_id (hacia auth.users o
  -- public.profiles) se recrea con ON DELETE SET NULL. Así borrar el usuario
  -- desde el dashboard tampoco queda bloqueado por sus rutinas.
  FOR v_fk IN
    SELECT c.conname, c.confrelid::regclass AS ref_table, c.confkey, c.confdeltype
      FROM pg_constraint c
      JOIN pg_attribute a
        ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
     WHERE c.conrelid = 'public.routines'::regclass
       AND c.contype = 'f'
       AND array_length(c.conkey, 1) = 1
       AND a.attname = 'creator_id'
  LOOP
    IF v_fk.confdeltype = 'n' THEN
      CONTINUE; -- ya es ON DELETE SET NULL
    END IF;
    SELECT attname INTO v_ref_col
      FROM pg_attribute
     WHERE attrelid = v_fk.ref_table AND attnum = v_fk.confkey[1];
    EXECUTE format('ALTER TABLE public.routines DROP CONSTRAINT %I', v_fk.conname);
    EXECUTE format(
      'ALTER TABLE public.routines ADD CONSTRAINT %I FOREIGN KEY (creator_id) '
      'REFERENCES %s (%I) ON DELETE SET NULL',
      v_fk.conname, v_fk.ref_table, v_ref_col
    );
  END LOOP;
END $$;

-- ── 2. FKs de tablas 100 % del usuario: ON DELETE CASCADE ───────────────
-- `profiles.id`, `workout_sessions.user_id` y `user_routines.user_id` son
-- datos exclusivos del usuario. Si su FK hacia auth.users/profiles es
-- NO ACTION/RESTRICT, `auth.admin.deleteUser` falla en cuanto se cuela una
-- fila (p. ej. el SyncWorker sube una sesión entre la RPC y el borrado).
-- CASCADE es la semántica correcta para estas tres y deja de bloquear el
-- borrado desde el dashboard. FKs que no aparecen no se tocan.
DO $$
DECLARE
  v_fk record;
  v_ref_col text;
  v_col text;
BEGIN
  FOR v_fk IN
    SELECT c.conname, c.conrelid::regclass AS tbl, c.conkey,
           c.confrelid::regclass AS ref_table, c.confkey
      FROM pg_constraint c
      JOIN pg_attribute a
        ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
     WHERE c.contype = 'f'
       AND array_length(c.conkey, 1) = 1
       AND c.confdeltype IN ('a', 'r') -- NO ACTION / RESTRICT
       AND c.confrelid IN ('auth.users'::regclass, 'public.profiles'::regclass)
       AND (
         (c.conrelid = 'public.profiles'::regclass AND a.attname = 'id')
         OR (c.conrelid = 'public.workout_sessions'::regclass AND a.attname = 'user_id')
         OR (c.conrelid = 'public.user_routines'::regclass AND a.attname = 'user_id')
       )
  LOOP
    SELECT attname INTO v_col
      FROM pg_attribute WHERE attrelid = v_fk.tbl AND attnum = v_fk.conkey[1];
    SELECT attname INTO v_ref_col
      FROM pg_attribute WHERE attrelid = v_fk.ref_table AND attnum = v_fk.confkey[1];
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', v_fk.tbl, v_fk.conname);
    EXECUTE format(
      'ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES %s (%I) ON DELETE CASCADE',
      v_fk.tbl, v_fk.conname, v_col, v_fk.ref_table, v_ref_col
    );
  END LOOP;
END $$;

-- ── 3. reorder_routine_exercises: dueño real = creator_id ───────────────
-- Una rutina anonimizada (creator_id NULL) no es editable por nadie: se
-- responde not_authorized igual que con una rutina ajena.
CREATE OR REPLACE FUNCTION public.reorder_routine_exercises(
  p_day_id      uuid,
  p_ordered_ids uuid[]
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authorized' USING ERRCODE = '42501';
  END IF;

  SELECT r.creator_id
    INTO v_owner
    FROM public.routine_days rd
    JOIN public.routines r ON r.id = rd.routine_id
   WHERE rd.id = p_day_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'routine_day_not_found' USING ERRCODE = 'P0002';
  END IF;

  IF v_owner IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'not_authorized' USING ERRCODE = '42501';
  END IF;

  UPDATE public.routine_exercises re
     SET "order" = ord.idx - 1
    FROM unnest(p_ordered_ids) WITH ORDINALITY AS ord(exercise_id, idx)
   WHERE re.routine_day_id = p_day_id
     AND re.exercise_id    = ord.exercise_id;
END;
$$;

REVOKE ALL ON FUNCTION public.reorder_routine_exercises(uuid, uuid[]) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.reorder_routine_exercises(uuid, uuid[]) FROM anon;
GRANT EXECUTE ON FUNCTION public.reorder_routine_exercises(uuid, uuid[]) TO authenticated;

-- ── 4. delete_account_data_v1 ───────────────────────────────────────────
-- Borra/anonimiza todos los datos de `p_user_id` en una transacción. NO toca
-- auth.users (eso lo hace la Edge Function con la Admin API). Idempotente:
-- repetirla sobre un usuario ya limpio devuelve todos los conteos a 0.
-- Sólo service_role puede ejecutarla: no compara contra auth.uid() porque la
-- llama la Edge Function tras validar el JWT del propio usuario.
CREATE OR REPLACE FUNCTION public.delete_account_data_v1(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_set_logs integer := 0;
  v_sessions integer := 0;
  v_assignments integer := 0;
  v_anonymized integer := 0;
  v_routine_exercises integer := 0;
  v_routine_days integer := 0;
  v_private integer := 0;
  v_rate_limits integer := 0;
  v_profiles integer := 0;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'delete_account_data_v1: p_user_id is required'
      USING ERRCODE = '22004';
  END IF;

  -- Serializa borrados concurrentes del mismo usuario (doble tap, reintento).
  PERFORM pg_advisory_xact_lock(hashtext('delete_account_data_v1'), hashtext(p_user_id::text));

  -- 1) Series. `guard_session_set_log_v1` rechaza borrar logs de sesiones
  --    cerradas con `exercise_plan`; quitar el plan antes (permitido fuera de
  --    los roles cliente por `guard_session_exercise_plan_v1`) deja que el
  --    trigger trate las sesiones como legacy. Las sesiones se borran justo
  --    después, así que el plan no se pierde para nadie.
  UPDATE public.workout_sessions
     SET exercise_plan = NULL
   WHERE user_id = p_user_id
     AND exercise_plan IS NOT NULL;

  DELETE FROM public.set_logs sl
   USING public.workout_sessions ws
   WHERE sl.session_id = ws.id
     AND ws.user_id = p_user_id;
  GET DIAGNOSTICS v_set_logs = ROW_COUNT;

  -- 2) Sesiones.
  DELETE FROM public.workout_sessions WHERE user_id = p_user_id;
  GET DIAGNOSTICS v_sessions = ROW_COUNT;

  -- 3) Asignación de rutina del usuario.
  DELETE FROM public.user_routines WHERE user_id = p_user_id;
  GET DIAGNOSTICS v_assignments = ROW_COUNT;

  -- 4) Anonimizar: públicas, y también privadas que otro usuario tenga
  --    asignadas o con sesiones registradas (no existe flujo para eso, pero
  --    si pasa no le rompemos nada). Se conserva `is_public`: una privada
  --    anonimizada no se publica; sólo deja de tener dueño. Sin dueño nadie
  --    puede editarla (las políticas comparan creator_id = auth.uid()).
  UPDATE public.routines r
     SET creator_id = NULL
   WHERE r.creator_id = p_user_id
     AND (
       r.is_public = true
       OR EXISTS (
         SELECT 1 FROM public.user_routines ur WHERE ur.routine_id = r.id
       )
       OR EXISTS (
         SELECT 1
           FROM public.routine_days rd
           JOIN public.workout_sessions ws ON ws.routine_day_id = rd.id
          WHERE rd.routine_id = r.id
       )
     );
  GET DIAGNOSTICS v_anonymized = ROW_COUNT;

  -- 5) Rutinas privadas restantes con sus días y ejercicios. Borrado
  --    explícito hijo → padre para no depender de cascadas no versionadas.
  DELETE FROM public.routine_exercises re
   USING public.routine_days rd, public.routines r
   WHERE re.routine_day_id = rd.id
     AND rd.routine_id = r.id
     AND r.creator_id = p_user_id;
  GET DIAGNOSTICS v_routine_exercises = ROW_COUNT;

  DELETE FROM public.routine_days rd
   USING public.routines r
   WHERE rd.routine_id = r.id
     AND r.creator_id = p_user_id;
  GET DIAGNOSTICS v_routine_days = ROW_COUNT;

  DELETE FROM public.routines WHERE creator_id = p_user_id;
  GET DIAGNOSTICS v_private = ROW_COUNT;

  -- 6) Rate limits (también caerían por ON DELETE CASCADE con auth.users).
  DELETE FROM public.function_rate_limits WHERE user_id = p_user_id;
  GET DIAGNOSTICS v_rate_limits = ROW_COUNT;

  -- 7) Perfil.
  DELETE FROM public.profiles WHERE id = p_user_id;
  GET DIAGNOSTICS v_profiles = ROW_COUNT;

  RETURN jsonb_build_object(
    'set_logs', v_set_logs,
    'workout_sessions', v_sessions,
    'user_routines', v_assignments,
    'routines_anonymized', v_anonymized,
    'routines_deleted', v_private,
    'routine_days_deleted', v_routine_days,
    'routine_exercises_deleted', v_routine_exercises,
    'rate_limits', v_rate_limits,
    'profiles', v_profiles
  );
END;
$$;

REVOKE ALL ON FUNCTION public.delete_account_data_v1(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_account_data_v1(uuid) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_account_data_v1(uuid) TO service_role;

COMMENT ON FUNCTION public.delete_account_data_v1(uuid) IS
  'Borra los datos del usuario y anonimiza sus rutinas públicas. Sólo service_role (Edge Function delete_account_v1).';
