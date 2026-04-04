-- Enforce business rule: one active workout session per user.
-- Active session = completed_at IS NULL.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.workout_sessions
    WHERE completed_at IS NULL
    GROUP BY user_id
    HAVING COUNT(*) > 1
  ) THEN
    RAISE EXCEPTION 'Cannot enforce single active session: duplicate active sessions exist per user';
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_workout_sessions_single_active_per_user
  ON public.workout_sessions(user_id)
  WHERE completed_at IS NULL;
