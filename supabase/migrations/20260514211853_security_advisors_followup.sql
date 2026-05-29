-- ============================================================
-- Follow-up advisors:
--   1. REVOKE de PUBLIC en las 4 RPCs (anon hereda EXECUTE via PUBLIC;
--      con solo REVOKE FROM anon no es suficiente).
--   2. profiles_select: rewrite auth.uid() → (select auth.uid()).
-- ============================================================

-- 1. RPCs: revocar PUBLIC y reafirmar el grant solo para authenticated
--    + service_role (que invoca desde Edge Functions).
REVOKE EXECUTE ON FUNCTION public.get_last_exercise_performance(UUID, UUID)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_last_exercise_performance(UUID, UUID)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_last_exercise_performances(UUID, UUID[])
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_last_exercise_performances(UUID, UUID[])
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_coaching_inputs_v1(UUID, UUID)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_coaching_inputs_v1(UUID, UUID)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.compute_weekly_insights_v1(UUID, UUID, DATE)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.compute_weekly_insights_v1(UUID, UUID, DATE)
  TO authenticated, service_role;

-- 2. profiles_select: (select auth.uid()) para evitar re-evaluación por fila.
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (
    (select auth.uid()) = id
    OR EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.creator_id = profiles.id
        AND (r.is_public = true OR r.creator_id = (select auth.uid()))
    )
  );
