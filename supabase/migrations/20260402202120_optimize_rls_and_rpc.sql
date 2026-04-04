-- Reconstructed from remote state to align local repo migrations with deployed Supabase.

-- RPC used by Flutter datasource for progressive overload prefill.
CREATE OR REPLACE FUNCTION public.get_last_exercise_performance(
  p_user_id UUID,
  p_exercise_id UUID
)
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT row_to_json(sl)::jsonb
  FROM (
    SELECT
      sl2.id,
      sl2.session_id,
      sl2.exercise_id,
      sl2.set_index,
      sl2.actual_weight,
      sl2.actual_reps,
      sl2.created_at
    FROM public.set_logs sl2
    JOIN public.workout_sessions ws ON ws.id = sl2.session_id
    WHERE ws.user_id = p_user_id
      AND sl2.exercise_id = p_exercise_id
    ORDER BY sl2.created_at DESC
    LIMIT 1
  ) sl;
$function$;
