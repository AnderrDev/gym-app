-- Enforce business rule: one log per (session, exercise, set_index).

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.set_logs
    GROUP BY session_id, exercise_id, set_index
    HAVING COUNT(*) > 1
  ) THEN
    RAISE EXCEPTION 'Cannot enforce unique set log: duplicate (session_id, exercise_id, set_index) rows exist';
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_set_logs_session_exercise_set_index
  ON public.set_logs(session_id, exercise_id, set_index);
