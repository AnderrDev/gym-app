-- Re-añade las policies INSERT/UPDATE/DELETE para `routine_days` y
-- `routine_exercises`. La migración `20260514211812_security_advisors_cleanup`
-- consolidó las policies pero sólo dejó la de SELECT, dejando los writes
-- bloqueados por RLS para todos los users (sólo service_role podía escribir).
--
-- Síntoma reportado: al tocar "Añadir Día" sobre una rutina propia, Supabase
-- devolvía `new row violates row level security for the table routine_days`.

-- ── routine_days ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "routine_days_insert" ON public.routine_days;
CREATE POLICY "routine_days_insert" ON public.routine_days
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_days.routine_id
        AND r.creator_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "routine_days_update" ON public.routine_days;
CREATE POLICY "routine_days_update" ON public.routine_days
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_days.routine_id
        AND r.creator_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_days.routine_id
        AND r.creator_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "routine_days_delete" ON public.routine_days;
CREATE POLICY "routine_days_delete" ON public.routine_days
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_days.routine_id
        AND r.creator_id = (select auth.uid())
    )
  );

-- ── routine_exercises ────────────────────────────────────────────────────
DROP POLICY IF EXISTS "routine_exercises_insert" ON public.routine_exercises;
CREATE POLICY "routine_exercises_insert" ON public.routine_exercises
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.routine_days rd
      JOIN public.routines r ON rd.routine_id = r.id
      WHERE rd.id = routine_exercises.routine_day_id
        AND r.creator_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "routine_exercises_update" ON public.routine_exercises;
CREATE POLICY "routine_exercises_update" ON public.routine_exercises
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.routine_days rd
      JOIN public.routines r ON rd.routine_id = r.id
      WHERE rd.id = routine_exercises.routine_day_id
        AND r.creator_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.routine_days rd
      JOIN public.routines r ON rd.routine_id = r.id
      WHERE rd.id = routine_exercises.routine_day_id
        AND r.creator_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "routine_exercises_delete" ON public.routine_exercises;
CREATE POLICY "routine_exercises_delete" ON public.routine_exercises
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.routine_days rd
      JOIN public.routines r ON rd.routine_id = r.id
      WHERE rd.id = routine_exercises.routine_day_id
        AND r.creator_id = (select auth.uid())
    )
  );
