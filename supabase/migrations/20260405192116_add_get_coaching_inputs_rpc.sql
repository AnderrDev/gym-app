-- Batch RPC to fetch coaching inputs in a single call.

CREATE OR REPLACE FUNCTION public.get_coaching_inputs_v1(
  p_user_id UUID,
  p_session_id UUID
)
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $function$
WITH session_cte AS (
  SELECT id, user_id, routine_day_id, session_date
  FROM public.workout_sessions
  WHERE id = p_session_id
    AND user_id = p_user_id
  LIMIT 1
),
previous_session AS (
  SELECT id, session_date
  FROM public.workout_sessions ws
  WHERE ws.user_id = p_user_id
    AND ws.routine_day_id = (SELECT routine_day_id FROM session_cte)
    AND ws.completed_at IS NOT NULL
    AND ws.session_date < (SELECT session_date FROM session_cte)
  ORDER BY ws.session_date DESC
  LIMIT 1
),
current_logs AS (
  SELECT sl.exercise_id, sl.actual_weight, sl.actual_reps, sl.set_index, ex.name
  FROM public.set_logs sl
  JOIN public.exercises ex ON ex.id = sl.exercise_id
  WHERE sl.session_id = p_session_id
  ORDER BY sl.set_index ASC
),
routine_targets AS (
  SELECT re.exercise_id, re.target_sets, re.target_reps, re.target_weight
  FROM public.routine_exercises re
  WHERE re.routine_day_id = (SELECT routine_day_id FROM session_cte)
),
previous_logs AS (
  SELECT sl.exercise_id, sl.actual_weight, sl.actual_reps, sl.set_index
  FROM public.set_logs sl
  WHERE sl.session_id = (SELECT id FROM previous_session)
  ORDER BY sl.set_index ASC
)
SELECT jsonb_build_object(
  'session', (SELECT row_to_json(session_cte) FROM session_cte),
  'current_logs', COALESCE((SELECT jsonb_agg(to_jsonb(cl)) FROM current_logs cl), '[]'::jsonb),
  'routine_exercises', COALESCE((SELECT jsonb_agg(to_jsonb(rt)) FROM routine_targets rt), '[]'::jsonb),
  'previous_logs', COALESCE((SELECT jsonb_agg(to_jsonb(pl)) FROM previous_logs pl), '[]'::jsonb)
);
$function$;
