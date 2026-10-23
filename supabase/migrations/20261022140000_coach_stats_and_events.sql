-- Coach v2, fase 1b (docs/coach/PLAN_COACH_V2.md): métricas por ejercicio y
-- sesión, y registro de cada recomendación con su resultado posterior. Solo
-- escribe el servidor (service_role); el usuario puede leer lo suyo.

-- 1. Una fila por sesión × ejercicio con series registradas.
CREATE TABLE public.exercise_session_stats (
  session_id uuid NOT NULL REFERENCES public.workout_sessions(id) ON DELETE CASCADE,
  exercise_id uuid NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  session_date date NOT NULL,
  -- Exposición anterior del mismo ejercicio (cualquier rutina) y su orden.
  prev_session_id uuid,
  exposure_n integer NOT NULL,
  days_since_prev integer,
  -- Prescripción de la sesión (snapshot) o de la rutina en sesiones viejas.
  sets_target integer,
  target_reps integer,
  target_reps_max integer,
  target_weight numeric,
  -- Lo realizado.
  sets_done integer NOT NULL,
  top_weight numeric NOT NULL,
  min_reps integer NOT NULL,
  total_reps integer NOT NULL,
  volume_load numeric NOT NULL,
  -- e1RM de Epley de la mejor serie con ≤12 reps; asume series cerca del
  -- fallo (no se captura RIR). low_confidence: solo había series de >12 reps.
  best_e1rm numeric,
  low_confidence boolean NOT NULL DEFAULT false,
  -- Señales de esfuerzo deducidas (fase 1c del plan).
  rep_shortfall numeric,      -- reps objetivo − reps medias (negativo = sobran)
  rep_dropoff integer,        -- reps de la primera serie − reps de la última
  at_range_top boolean,       -- todas las series objetivo en el máximo del rango
  is_bodyweight boolean NOT NULL,
  computed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (session_id, exercise_id)
);
CREATE INDEX exercise_session_stats_history_idx
  ON public.exercise_session_stats (user_id, exercise_id, session_date);

-- 2. Cada recomendación del motor y, al volver a entrenar ese ejercicio, qué
-- pasó. Son las etiquetas para medir el acierto y, en la fase 4, entrenar.
CREATE TABLE public.coaching_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  session_id uuid NOT NULL REFERENCES public.workout_sessions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  exercise_id uuid NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  engine_version text NOT NULL,
  recommendation text NOT NULL,
  reason_code text,
  suggested_weight numeric,
  suggested_reps integer,
  performance_score numeric,
  features jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  -- Resultado: la siguiente exposición del ejercicio.
  outcome_session_id uuid REFERENCES public.workout_sessions(id) ON DELETE SET NULL,
  followed boolean,           -- usó el peso sugerido (± un incremento); NULL sin sugerencia
  hit_target boolean,         -- completó series y reps objetivo
  e1rm_delta numeric,
  labeled_at timestamptz,
  UNIQUE (session_id, exercise_id, engine_version)
);
CREATE INDEX coaching_events_user_exercise_idx ON public.coaching_events (user_id, exercise_id, created_at);

ALTER TABLE public.exercise_session_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coaching_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.exercise_session_stats, public.coaching_events FROM anon, authenticated;
GRANT SELECT ON public.exercise_session_stats, public.coaching_events TO authenticated;
CREATE POLICY exercise_session_stats_select ON public.exercise_session_stats
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY coaching_events_select ON public.coaching_events
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- 3. Recalcula las métricas de una sesión (idempotente) y etiqueta el
-- resultado de las recomendaciones de la exposición anterior. La llama
-- finalize_workout_session_v1 antes de generar el coaching.
CREATE FUNCTION public.refresh_exercise_session_stats_v1(p_session_id uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE s public.workout_sessions; n integer;
BEGIN
  SELECT * INTO s FROM public.workout_sessions WHERE id = p_session_id;
  IF NOT FOUND THEN RETURN 0; END IF;

  DELETE FROM public.exercise_session_stats WHERE session_id = p_session_id;

  WITH targets AS (
    SELECT (x->>'id')::uuid AS exercise_id,
           (x->>'target_sets')::integer AS sets_target,
           (x->>'target_reps')::integer AS target_reps,
           (x->>'target_reps_max')::integer AS target_reps_max,
           (x->>'target_weight')::numeric AS target_weight
    FROM jsonb_array_elements(s.exercise_plan) x
    WHERE s.exercise_plan IS NOT NULL
    UNION ALL
    SELECT re.exercise_id, re.target_sets, re.target_reps, re.target_reps_max, re.target_weight
    FROM public.routine_exercises re
    WHERE s.exercise_plan IS NULL AND re.routine_day_id = s.routine_day_id
  ),
  logs AS (
    SELECT sl.exercise_id, sl.set_index, sl.actual_weight::numeric AS w, sl.actual_reps AS r,
           row_number() OVER (PARTITION BY sl.exercise_id ORDER BY sl.set_index) AS first_rank,
           row_number() OVER (PARTITION BY sl.exercise_id ORDER BY sl.set_index DESC) AS last_rank
    FROM public.set_logs sl WHERE sl.session_id = p_session_id
  ),
  agg AS (
    SELECT exercise_id,
           count(*)::integer AS sets_done,
           max(w) AS top_weight,
           min(r) AS min_reps,
           sum(r)::integer AS total_reps,
           sum(w * r) AS volume_load,
           avg(r) AS avg_reps,
           max(w * (1 + r / 30.0)) FILTER (WHERE w > 0 AND r BETWEEN 1 AND 12) AS e1rm_reliable,
           max(w * (1 + r / 30.0)) FILTER (WHERE w > 0 AND r > 0) AS e1rm_any,
           max(r) FILTER (WHERE first_rank = 1) - max(r) FILTER (WHERE last_rank = 1) AS rep_dropoff
    FROM logs GROUP BY exercise_id
  ),
  prev AS (
    SELECT a.exercise_id, p.session_id AS prev_session_id, p.session_date AS prev_date,
           coalesce(p.exposure_n, 0) + 1 AS exposure_n
    FROM agg a
    LEFT JOIN LATERAL (
      SELECT st.session_id, st.session_date, st.exposure_n
      FROM public.exercise_session_stats st
      JOIN public.workout_sessions ws ON ws.id = st.session_id
      WHERE st.user_id = s.user_id AND st.exercise_id = a.exercise_id
        AND (ws.session_date, coalesce(ws.completed_at, 'infinity'))
          < (s.session_date, coalesce(s.completed_at, 'infinity'))
      ORDER BY ws.session_date DESC, ws.completed_at DESC NULLS LAST
      LIMIT 1
    ) p ON true
  )
  INSERT INTO public.exercise_session_stats (
    session_id, exercise_id, user_id, session_date, prev_session_id, exposure_n, days_since_prev,
    sets_target, target_reps, target_reps_max, target_weight,
    sets_done, top_weight, min_reps, total_reps, volume_load,
    best_e1rm, low_confidence, rep_shortfall, rep_dropoff, at_range_top, is_bodyweight)
  SELECT p_session_id, a.exercise_id, s.user_id, s.session_date, pv.prev_session_id, pv.exposure_n,
         s.session_date - pv.prev_date,
         t.sets_target, t.target_reps, t.target_reps_max, t.target_weight,
         a.sets_done, a.top_weight, a.min_reps, a.total_reps, a.volume_load,
         round(coalesce(a.e1rm_reliable, a.e1rm_any), 2),
         a.e1rm_reliable IS NULL AND a.e1rm_any IS NOT NULL,
         round(t.target_reps - a.avg_reps, 2),
         a.rep_dropoff,
         CASE WHEN t.target_reps IS NULL THEN NULL
              ELSE a.sets_done >= coalesce(t.sets_target, 0)
                   AND a.min_reps >= greatest(coalesce(t.target_reps_max, t.target_reps), t.target_reps) END,
         a.top_weight = 0
  FROM agg a
  JOIN prev pv ON pv.exercise_id = a.exercise_id
  JOIN public.exercises e ON e.id = a.exercise_id
  LEFT JOIN (SELECT DISTINCT ON (exercise_id) * FROM targets ORDER BY exercise_id, sets_target DESC NULLS LAST) t
    ON t.exercise_id = a.exercise_id;
  GET DIAGNOSTICS n = ROW_COUNT;

  -- Etiqueta las recomendaciones hechas en la exposición anterior.
  UPDATE public.coaching_events ce SET
    outcome_session_id = st.session_id,
    hit_target = st.sets_done >= coalesce(st.sets_target, 0)
                 AND st.min_reps >= coalesce(st.target_reps, 0),
    followed = CASE WHEN ce.suggested_weight IS NULL THEN NULL
                    ELSE abs(st.top_weight - ce.suggested_weight) <= coalesce(e.load_increment_kg, 2.5) END,
    e1rm_delta = st.best_e1rm - prev_st.best_e1rm,
    labeled_at = now()
  FROM public.exercise_session_stats st
  JOIN public.exercises e ON e.id = st.exercise_id
  LEFT JOIN public.exercise_session_stats prev_st
    ON prev_st.session_id = st.prev_session_id AND prev_st.exercise_id = st.exercise_id
  WHERE st.session_id = p_session_id
    AND ce.session_id = st.prev_session_id
    AND ce.exercise_id = st.exercise_id;

  RETURN n;
END $$;

REVOKE ALL ON FUNCTION public.refresh_exercise_session_stats_v1(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_exercise_session_stats_v1(uuid) TO service_role;

-- 4. Histórico: las recomendaciones ya guardadas (motor 1.0) pasan a eventos
-- y las sesiones cerradas se recalculan en orden, lo que las etiqueta.
INSERT INTO public.coaching_events (session_id, user_id, exercise_id, engine_version,
  recommendation, performance_score, features, created_at)
SELECT ws.id, ws.user_id, coalesce(item->>'exercise_id', item->>'exerciseId')::uuid, '1.0',
       -- Formato viejo de clientes: frase en recommendation, código en feedback.
       CASE WHEN item->>'recommendation' ~ '^[A-Z_]+$' THEN item->>'recommendation'
            WHEN item->>'feedback' ~ '^[A-Z_]+$' THEN item->>'feedback'
            ELSE 'UNKNOWN' END,
       CASE WHEN jsonb_typeof(item->'performance_score') = 'number' THEN (item->>'performance_score')::numeric END,
       jsonb_build_object('backfilled', true, 'item', item),
       ws.completed_at
FROM public.workout_sessions ws
CROSS JOIN LATERAL jsonb_array_elements(ws.coaching_analysis) AS item
WHERE ws.completed_at IS NOT NULL
  AND jsonb_typeof(ws.coaching_analysis) = 'array'
  AND coalesce(item->>'exercise_id', item->>'exerciseId') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  AND EXISTS (SELECT 1 FROM public.exercises e
              WHERE e.id = coalesce(item->>'exercise_id', item->>'exerciseId')::uuid)
ON CONFLICT (session_id, exercise_id, engine_version) DO NOTHING;

DO $$ DECLARE r record;
BEGIN
  FOR r IN SELECT id FROM public.workout_sessions WHERE completed_at IS NOT NULL
           ORDER BY session_date, completed_at
  LOOP
    PERFORM public.refresh_exercise_session_stats_v1(r.id);
  END LOOP;
END $$;
