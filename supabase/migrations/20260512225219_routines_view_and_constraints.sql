-- View routines_view: rutinas con conteo de ejercicios y nombre del creador.
-- Idempotente: la UI consume `from('routines_view')` desde antes de esta migración.
CREATE OR REPLACE VIEW public.routines_view AS
SELECT
  r.id,
  r.name,
  r.is_public,
  r.creator_id,
  p.full_name AS creator_name,
  COALESCE((
    SELECT COUNT(*)
    FROM public.routine_exercises re
    JOIN public.routine_days rd ON rd.id = re.routine_day_id
    WHERE rd.routine_id = r.id
  ), 0)::int AS exercise_count
FROM public.routines r
LEFT JOIN public.profiles p ON p.id = r.creator_id;

GRANT SELECT ON public.routines_view TO authenticated, anon;

-- UNIQUE(routine_day_id, exercise_id): evita duplicados por doble-tap.
-- Idempotente vía DO block (no podemos usar IF NOT EXISTS con ADD CONSTRAINT).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'routine_exercises_day_exercise_uniq'
  ) THEN
    ALTER TABLE public.routine_exercises
      ADD CONSTRAINT routine_exercises_day_exercise_uniq
      UNIQUE (routine_day_id, exercise_id);
  END IF;
END $$;
