-- ============================================================
-- Security & performance advisors cleanup.
-- 1. security_invoker = true en routines_view y view_workout_sessions_summary
--    para que la vista respete la RLS del caller, no la del owner.
-- 2. REVOKE EXECUTE de anon en RPCs SECURITY DEFINER (no las invoca un
--    cliente sin sesión; las protegemos en profundidad).
-- 3. Reescribir auth.uid() como (select auth.uid()) en 11 políticas RLS
--    para que Postgres lo evalúe una vez, no por fila (auth_rls_initplan).
-- ============================================================

-- ── 1. security_invoker en vistas ────────────────────────────
ALTER VIEW public.routines_view SET (security_invoker = true);
ALTER VIEW public.view_workout_sessions_summary SET (security_invoker = true);

-- ── 2. REVOKE EXECUTE de anon en RPCs SECURITY DEFINER ──────
-- Todas estas son llamadas desde la app autenticada o desde Edge Functions.
-- handle_new_user es un trigger; no debería estar expuesto como RPC.
REVOKE EXECUTE ON FUNCTION public.get_last_exercise_performance(UUID, UUID)
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_last_exercise_performances(UUID, UUID[])
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_coaching_inputs_v1(UUID, UUID)
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.compute_weekly_insights_v1(UUID, UUID, DATE)
  FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_new_user()
  FROM anon, authenticated, PUBLIC;

-- ── 3. Rewrite RLS: auth.uid() → (select auth.uid()) ────────

-- routines (4 policies)
DROP POLICY IF EXISTS "routines_select" ON public.routines;
CREATE POLICY "routines_select" ON public.routines
  FOR SELECT USING (is_public = true OR (select auth.uid()) = creator_id);

DROP POLICY IF EXISTS "routines_insert" ON public.routines;
CREATE POLICY "routines_insert" ON public.routines
  FOR INSERT WITH CHECK ((select auth.uid()) = creator_id);

DROP POLICY IF EXISTS "routines_update" ON public.routines;
CREATE POLICY "routines_update" ON public.routines
  FOR UPDATE USING ((select auth.uid()) = creator_id);

DROP POLICY IF EXISTS "routines_delete" ON public.routines;
CREATE POLICY "routines_delete" ON public.routines
  FOR DELETE USING ((select auth.uid()) = creator_id);

-- routine_days (1 policy)
DROP POLICY IF EXISTS "routine_days_select" ON public.routine_days;
CREATE POLICY "routine_days_select" ON public.routine_days
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_days.routine_id
        AND (r.is_public = true OR r.creator_id = (select auth.uid()))
    )
  );

-- routine_exercises (1 policy)
DROP POLICY IF EXISTS "routine_exercises_select" ON public.routine_exercises;
CREATE POLICY "routine_exercises_select" ON public.routine_exercises
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routine_days rd
      JOIN public.routines r ON rd.routine_id = r.id
      WHERE rd.id = routine_exercises.routine_day_id
        AND (r.is_public = true OR r.creator_id = (select auth.uid()))
    )
  );

-- user_routines (4 policies)
DROP POLICY IF EXISTS "user_routines_select" ON public.user_routines;
CREATE POLICY "user_routines_select" ON public.user_routines
  FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "user_routines_insert" ON public.user_routines;
CREATE POLICY "user_routines_insert" ON public.user_routines
  FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "user_routines_update" ON public.user_routines;
CREATE POLICY "user_routines_update" ON public.user_routines
  FOR UPDATE USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "user_routines_delete" ON public.user_routines;
CREATE POLICY "user_routines_delete" ON public.user_routines
  FOR DELETE USING ((select auth.uid()) = user_id);

-- set_logs (1 policy: solo update; select/insert ya estaban optimizadas)
DROP POLICY IF EXISTS "set_logs_update" ON public.set_logs;
CREATE POLICY "set_logs_update" ON public.set_logs
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.workout_sessions ws
      WHERE ws.id = set_logs.session_id
        AND ws.user_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workout_sessions ws
      WHERE ws.id = set_logs.session_id
        AND ws.user_id = (select auth.uid())
    )
  );
