-- ============================================================
-- Security hardening: cierra IDOR en RPCs, search_path en
-- handle_new_user, y restringe profiles_select.
-- ============================================================
--
-- Hallazgos cubiertos por esta migración:
--   1. Las 4 RPCs SECURITY DEFINER aceptaban p_user_id sin
--      verificar auth.uid() == p_user_id → cualquier usuario
--      autenticado podía leer datos de otro pasando un UUID.
--   2. handle_new_user (trigger en auth.users) no fijaba
--      search_path → vector de privilege escalation conocido
--      cuando se ejecuta en otros schemas.
--   3. profiles_select USING (true) exponía full_name de todos
--      los usuarios. Lo limitamos a self + creators visibles.
-- ============================================================

-- ── 1. RPC: get_last_exercise_performance ───────────────────
-- (Antes: SQL puro, sin search_path, sin guard.)
CREATE OR REPLACE FUNCTION public.get_last_exercise_performance(
  p_user_id UUID,
  p_exercise_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  result JSONB;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden: p_user_id mismatch' USING ERRCODE = '42501';
  END IF;

  SELECT row_to_json(sl)::jsonb INTO result
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

  RETURN result;
END;
$function$;

-- ── 2. RPC: get_last_exercise_performances (batch) ──────────
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
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden: p_user_id mismatch' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
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
END;
$function$;

-- ── 3. RPC: get_coaching_inputs_v1 ──────────────────────────
CREATE OR REPLACE FUNCTION public.get_coaching_inputs_v1(
  p_user_id UUID,
  p_session_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  result JSONB;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden: p_user_id mismatch' USING ERRCODE = '42501';
  END IF;

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
  ) INTO result;

  RETURN result;
END;
$function$;

-- ── 4. RPC: compute_weekly_insights_v1 ──────────────────────
CREATE OR REPLACE FUNCTION public.compute_weekly_insights_v1(
  p_user_id UUID,
  p_routine_id UUID,
  p_week_start DATE DEFAULT NULL
)
RETURNS TABLE (
  week_start DATE,
  week_end DATE,
  planned_days INTEGER,
  completed_days INTEGER,
  completed_sessions INTEGER,
  adherence_rate NUMERIC,
  total_volume NUMERIC,
  previous_week_volume NUMERIC,
  volume_trend_percent NUMERIC,
  personal_records INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden: p_user_id mismatch' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  WITH params AS (
    SELECT COALESCE(
      p_week_start,
      (date_trunc('week', now() AT TIME ZONE 'utc')::date)
    ) AS week_start
  ),
  week_bounds AS (
    SELECT
      params.week_start,
      (params.week_start + 6) AS week_end,
      (params.week_start - 7) AS prev_week_start,
      (params.week_start - 1) AS prev_week_end
    FROM params
  ),
  routine_days_cte AS (
    SELECT id
    FROM public.routine_days
    WHERE routine_id = p_routine_id
  ),
  sessions_week AS (
    SELECT ws.*
    FROM public.workout_sessions ws
    JOIN week_bounds wb ON true
    WHERE ws.user_id = p_user_id
      AND ws.routine_day_id IN (SELECT id FROM routine_days_cte)
      AND ws.session_date BETWEEN wb.week_start AND wb.week_end
  ),
  completed_sessions_cte AS (
    SELECT *
    FROM sessions_week
    WHERE completed_at IS NOT NULL
  ),
  volume_week AS (
    SELECT COALESCE(SUM(sl.actual_weight * sl.actual_reps), 0) AS total_volume
    FROM public.set_logs sl
    JOIN public.workout_sessions ws ON ws.id = sl.session_id
    JOIN week_bounds wb ON true
    WHERE ws.user_id = p_user_id
      AND ws.routine_day_id IN (SELECT id FROM routine_days_cte)
      AND ws.session_date BETWEEN wb.week_start AND wb.week_end
  ),
  volume_prev AS (
    SELECT COALESCE(SUM(sl.actual_weight * sl.actual_reps), 0) AS total_volume
    FROM public.set_logs sl
    JOIN public.workout_sessions ws ON ws.id = sl.session_id
    JOIN week_bounds wb ON true
    WHERE ws.user_id = p_user_id
      AND ws.routine_day_id IN (SELECT id FROM routine_days_cte)
      AND ws.session_date BETWEEN wb.prev_week_start AND wb.prev_week_end
  ),
  weekly_logs AS (
    SELECT sl.exercise_id, MAX(sl.actual_weight) AS max_weight
    FROM public.set_logs sl
    JOIN public.workout_sessions ws ON ws.id = sl.session_id
    JOIN week_bounds wb ON true
    WHERE ws.user_id = p_user_id
      AND ws.routine_day_id IN (SELECT id FROM routine_days_cte)
      AND ws.session_date BETWEEN wb.week_start AND wb.week_end
    GROUP BY sl.exercise_id
  ),
  previous_logs AS (
    SELECT sl.exercise_id, MAX(sl.actual_weight) AS max_weight
    FROM public.set_logs sl
    JOIN public.workout_sessions ws ON ws.id = sl.session_id
    JOIN week_bounds wb ON true
    WHERE ws.user_id = p_user_id
      AND ws.routine_day_id IN (SELECT id FROM routine_days_cte)
      AND ws.session_date < wb.week_start
    GROUP BY sl.exercise_id
  ),
  pr_counts AS (
    SELECT COUNT(*)::INTEGER AS personal_records
    FROM weekly_logs wl
    LEFT JOIN previous_logs pl ON pl.exercise_id = wl.exercise_id
    WHERE wl.max_weight > COALESCE(pl.max_weight, 0)
      AND wl.max_weight > 0
  )
  SELECT
    wb.week_start,
    wb.week_end,
    (SELECT COUNT(*)::INTEGER FROM routine_days_cte) AS planned_days,
    (SELECT COUNT(DISTINCT routine_day_id)::INTEGER FROM completed_sessions_cte) AS completed_days,
    (SELECT COUNT(*)::INTEGER FROM completed_sessions_cte) AS completed_sessions,
    CASE
      WHEN (SELECT COUNT(*) FROM routine_days_cte) = 0 THEN 0::numeric
      ELSE ROUND(
        ((SELECT COUNT(DISTINCT routine_day_id) FROM completed_sessions_cte)::numeric
          / (SELECT COUNT(*) FROM routine_days_cte)::numeric) * 100,
        2
      )
    END AS adherence_rate,
    ROUND(vw.total_volume::numeric, 2) AS total_volume,
    ROUND(vp.total_volume::numeric, 2) AS previous_week_volume,
    CASE
      WHEN vp.total_volume <= 0 THEN CASE WHEN vw.total_volume > 0 THEN 100 ELSE 0 END
      ELSE ROUND(((vw.total_volume - vp.total_volume) / vp.total_volume) * 100, 2)
    END AS volume_trend_percent,
    (SELECT personal_records FROM pr_counts) AS personal_records
  FROM week_bounds wb
  CROSS JOIN volume_week vw
  CROSS JOIN volume_prev vp;
END;
$function$;

-- ── 5. handle_new_user: añadir search_path ──────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$function$;

-- ── 6. profiles_select: cerrar enumeración ──────────────────
-- Antes: USING (true) → cualquier usuario podía leer full_name
-- de todos. Ahora: solo self o creators de rutinas visibles.
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (
    auth.uid() = id
    OR EXISTS (
      SELECT 1 FROM public.routines r
      WHERE r.creator_id = profiles.id
        AND (r.is_public = true OR r.creator_id = auth.uid())
    )
  );
