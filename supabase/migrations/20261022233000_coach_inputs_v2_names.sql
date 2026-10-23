-- El catálogo de get_coaching_inputs_v2 incluye el nombre del ejercicio, para
-- que los ejercicios sin series no salgan como "Ejercicio" en el coaching.
CREATE OR REPLACE FUNCTION public.get_coaching_inputs_v2(p_user_id uuid, p_session_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE s public.workout_sessions; result jsonb;
BEGIN
  IF auth.uid() IS NULL OR p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden: p_user_id mismatch' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO s FROM public.workout_sessions WHERE id = p_session_id AND user_id = p_user_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('session', NULL); END IF;

  WITH targets AS (
    SELECT (x->>'id')::uuid AS exercise_id, (x->>'target_sets')::integer AS target_sets,
           (x->>'target_reps')::integer AS target_reps, (x->>'target_reps_max')::integer AS target_reps_max,
           (x->>'target_weight')::numeric AS target_weight
    FROM jsonb_array_elements(s.exercise_plan) x
    WHERE s.exercise_plan IS NOT NULL AND (x->>'target_sets')::integer > 0
    UNION ALL
    SELECT re.exercise_id, re.target_sets, re.target_reps, re.target_reps_max, re.target_weight
    FROM public.routine_exercises re
    WHERE s.exercise_plan IS NULL AND re.routine_day_id = s.routine_day_id
  ),
  history AS (
    SELECT h.* FROM targets t
    CROSS JOIN LATERAL (
      SELECT st.exercise_id, st.session_date, st.top_weight, st.min_reps, st.sets_done, st.sets_target,
             st.target_reps, st.best_e1rm, st.low_confidence, st.at_range_top
      FROM public.exercise_session_stats st
      JOIN public.workout_sessions ws ON ws.id = st.session_id
      WHERE st.user_id = p_user_id AND st.exercise_id = t.exercise_id
        AND st.session_id <> s.id AND ws.completed_at IS NOT NULL
        AND ws.session_date <= s.session_date
      ORDER BY ws.session_date DESC, ws.completed_at DESC
      LIMIT 6
    ) h
  )
  SELECT jsonb_build_object(
    'session', jsonb_build_object('id', s.id, 'user_id', s.user_id, 'session_date', s.session_date),
    'targets', coalesce((SELECT jsonb_agg(to_jsonb(t)) FROM targets t), '[]'::jsonb),
    'current_logs', coalesce((
      SELECT jsonb_agg(jsonb_build_object('exercise_id', sl.exercise_id, 'actual_weight', sl.actual_weight,
        'actual_reps', sl.actual_reps, 'set_index', sl.set_index, 'name', e.name) ORDER BY sl.exercise_id, sl.set_index)
      FROM public.set_logs sl JOIN public.exercises e ON e.id = sl.exercise_id
      WHERE sl.session_id = s.id), '[]'::jsonb),
    'catalog', coalesce((
      SELECT jsonb_agg(jsonb_build_object('exercise_id', e.id, 'name', e.name, 'movement_type', e.movement_type,
        'body_region', e.body_region, 'load_increment_kg', e.load_increment_kg))
      FROM public.exercises e WHERE e.id IN (SELECT exercise_id FROM targets)), '[]'::jsonb),
    'history', coalesce((SELECT jsonb_agg(to_jsonb(h) ORDER BY h.exercise_id, h.session_date DESC) FROM history h), '[]'::jsonb)
  ) INTO result;
  RETURN result;
END $$;

