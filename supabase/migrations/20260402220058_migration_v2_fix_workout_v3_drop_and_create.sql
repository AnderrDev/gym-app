-- Reconstructed from remote state to align local repo migrations with deployed Supabase.

ALTER TABLE public.workout_sessions
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS coaching_analysis JSONB;

CREATE OR REPLACE VIEW public.view_workout_sessions_summary AS
WITH target_stats AS (
  SELECT
    ws.id AS session_id,
    COALESCE(SUM(re.target_sets), 0) AS total_target_sets
  FROM public.workout_sessions ws
  JOIN public.routine_exercises re ON re.routine_day_id = ws.routine_day_id
  GROUP BY ws.id
),
completed_stats AS (
  SELECT
    session_id,
    COUNT(*) AS total_completed_sets
  FROM public.set_logs
  GROUP BY session_id
)
SELECT
  ws.*,
  COALESCE(ts.total_target_sets, 0) AS total_target_sets,
  COALESCE(cs.total_completed_sets, 0) AS total_completed_sets,
  (
    COALESCE(cs.total_completed_sets, 0) >= COALESCE(ts.total_target_sets, 0)
    AND ws.completed_at IS NOT NULL
  ) AS is_strictly_completed
FROM public.workout_sessions ws
LEFT JOIN target_stats ts ON ts.session_id = ws.id
LEFT JOIN completed_stats cs ON cs.session_id = ws.id;
