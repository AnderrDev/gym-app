-- Batch RPC to fetch latest performance per exercise for a user.

CREATE OR REPLACE FUNCTION public.get_last_exercise_performances(
  p_user_id UUID,
  p_exercise_ids UUID[]
)
RETURNS TABLE (
  id UUID,
  session_id UUID,
  exercise_id UUID,
  set_index INTEGER,
  actual_weight NUMERIC,
  actual_reps INTEGER,
  created_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT DISTINCT ON (sl.exercise_id)
    sl.id,
    sl.session_id,
    sl.exercise_id,
    sl.set_index,
    sl.actual_weight,
    sl.actual_reps,
    sl.created_at
  FROM public.set_logs sl
  JOIN public.workout_sessions ws ON ws.id = sl.session_id
  WHERE ws.user_id = p_user_id
    AND sl.exercise_id = ANY(p_exercise_ids)
  ORDER BY sl.exercise_id, sl.created_at DESC;
$function$;
