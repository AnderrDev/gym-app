-- Reconstructed from remote state to align local repo migrations with deployed Supabase.

ALTER TABLE public.routine_exercises
ADD COLUMN IF NOT EXISTS rest_timer_seconds INTEGER NOT NULL DEFAULT 90;

-- Performance indexes observed in remote
CREATE INDEX IF NOT EXISTS idx_routine_exercises_routine_day_id
  ON public.routine_exercises(routine_day_id);
CREATE INDEX IF NOT EXISTS idx_routine_exercises_exercise_id
  ON public.routine_exercises(exercise_id);

CREATE INDEX IF NOT EXISTS idx_set_logs_session_id
  ON public.set_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_set_logs_exercise_id
  ON public.set_logs(exercise_id);

CREATE INDEX IF NOT EXISTS idx_user_routines_user_id
  ON public.user_routines(user_id);
CREATE INDEX IF NOT EXISTS idx_user_routines_routine_id
  ON public.user_routines(routine_id);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_id
  ON public.workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_routine_day_id
  ON public.workout_sessions(routine_day_id);
