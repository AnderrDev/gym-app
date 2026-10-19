-- Add is_public to routines if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='routines' AND column_name='is_public') THEN
    ALTER TABLE public.routines ADD COLUMN is_public BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Update user_routines to have simple PRIMARY KEY (user_id)
-- First drop existing constraint if any
ALTER TABLE public.user_routines DROP CONSTRAINT IF EXISTS user_routines_pkey;
-- Add primary key on user_id only
ALTER TABLE public.user_routines ADD PRIMARY KEY (user_id);

-- Update RLS Policies
DROP POLICY IF EXISTS "routines_select" ON public.routines;
CREATE POLICY "routines_select" ON public.routines
  FOR SELECT USING ((is_public = true) OR (auth.uid() = creator_id));

DROP POLICY IF EXISTS "routine_days_select" ON public.routine_days;
CREATE POLICY "routine_days_select" ON public.routine_days
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.id = routine_days.routine_id
      AND (r.is_public = true OR r.creator_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "routine_exercises_select" ON public.routine_exercises;
CREATE POLICY "routine_exercises_select" ON public.routine_exercises
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.routine_days rd
      JOIN public.routines r ON rd.routine_id = r.id
      WHERE rd.id = routine_exercises.routine_day_id
      AND (r.is_public = true OR r.creator_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "user_routines_update" ON public.user_routines;
CREATE POLICY "user_routines_update" ON public.user_routines
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_routines_delete" ON public.user_routines;
CREATE POLICY "user_routines_delete" ON public.user_routines
  FOR DELETE USING (auth.uid() = user_id);
