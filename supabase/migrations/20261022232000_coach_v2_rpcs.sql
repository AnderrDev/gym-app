-- Coach v2, fases 2–3 (docs/coach/PLAN_COACH_V2.md): entradas del motor v2 y
-- la sugerencia vigente por ejercicio para precargar el siguiente entreno.

-- 1. Entradas del motor v2: objetivos (con rango), series de la sesión,
-- clasificación del catálogo e historial de métricas (≤6 exposiciones
-- cerradas por ejercicio, de cualquier rutina).
CREATE FUNCTION public.get_coaching_inputs_v2(p_user_id uuid, p_session_id uuid)
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
      SELECT jsonb_agg(jsonb_build_object('exercise_id', e.id, 'movement_type', e.movement_type,
        'body_region', e.body_region, 'load_increment_kg', e.load_increment_kg))
      FROM public.exercises e WHERE e.id IN (SELECT exercise_id FROM targets)), '[]'::jsonb),
    'history', coalesce((SELECT jsonb_agg(to_jsonb(h) ORDER BY h.exercise_id, h.session_date DESC) FROM history h), '[]'::jsonb)
  ) INTO result;
  RETURN result;
END $$;

REVOKE ALL ON FUNCTION public.get_coaching_inputs_v2(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_coaching_inputs_v2(uuid, uuid) TO authenticated;

-- 2. Sugerencia vigente del coach por ejercicio (la última con peso), con
-- ajuste por pausa: <14 días sin cambio; 14–27 −7,5 %; 28–55 −15 %;
-- ≥56 −25 % (redondeado al incremento del ejercicio). Solo lo del usuario.
CREATE FUNCTION public.get_next_targets_v1(p_exercise_ids uuid[])
RETURNS TABLE (
  exercise_id uuid,
  suggested_weight numeric,
  suggested_reps integer,
  recommendation text,
  reason_code text,
  source_session_date date,
  days_since integer,
  layoff_adjusted boolean
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH latest AS (
    SELECT DISTINCT ON (ce.exercise_id)
           ce.exercise_id, ce.suggested_weight, ce.suggested_reps, ce.recommendation, ce.reason_code,
           ws.session_date, (current_date - ws.session_date) AS days_since,
           coalesce(e.load_increment_kg, 2.5) AS step
    FROM public.coaching_events ce
    JOIN public.workout_sessions ws ON ws.id = ce.session_id
    JOIN public.exercises e ON e.id = ce.exercise_id
    WHERE auth.uid() IS NOT NULL AND ce.user_id = auth.uid()
      AND ce.exercise_id = ANY (p_exercise_ids)
      AND ce.suggested_weight IS NOT NULL
      AND ws.completed_at IS NOT NULL
    ORDER BY ce.exercise_id, ws.session_date DESC, ws.completed_at DESC, ce.created_at DESC
  )
  SELECT l.exercise_id,
         CASE WHEN l.days_since < 14 OR l.suggested_weight = 0 THEN l.suggested_weight
              ELSE greatest(0, round(l.suggested_weight * CASE WHEN l.days_since < 28 THEN 0.925
                                                               WHEN l.days_since < 56 THEN 0.85
                                                               ELSE 0.75 END / l.step) * l.step) END,
         l.suggested_reps, l.recommendation, l.reason_code, l.session_date, l.days_since,
         l.days_since >= 14 AND l.suggested_weight > 0
  FROM latest l;
$$;

REVOKE ALL ON FUNCTION public.get_next_targets_v1(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_next_targets_v1(uuid[]) TO authenticated;
