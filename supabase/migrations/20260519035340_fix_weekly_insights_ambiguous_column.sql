-- Fix: "column reference \"personal_records\" is ambiguous" al invocar
-- `compute_weekly_insights_v1`.
--
-- Causa: la función está declarada con `LANGUAGE plpgsql` y
-- `RETURNS TABLE (..., personal_records INTEGER)`. En plpgsql las columnas
-- del `RETURNS TABLE` quedan en scope como variables locales — al referenciar
-- `personal_records` dentro del subquery `SELECT personal_records FROM
-- pr_counts`, el planner ve dos candidatos (la columna del CTE y la variable
-- de RETURN TABLE) y aborta.
--
-- Fix: renombrar la columna del CTE a `pr_count` para que no choque con la
-- variable del RETURNS TABLE.

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
    -- Renombrado: antes era `personal_records`, chocaba con la variable
    -- homónima del RETURNS TABLE en contexto plpgsql.
    SELECT COUNT(*)::INTEGER AS pr_count
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
    (SELECT pr_count FROM pr_counts) AS personal_records
  FROM week_bounds wb
  CROSS JOIN volume_week vw
  CROSS JOIN volume_prev vp;
END;
$function$;

-- Mantener grants existentes (la migración IDOR los revoca de PUBLIC y los
-- da sólo a `authenticated`; replicar acá por idempotencia).
REVOKE EXECUTE ON FUNCTION public.compute_weekly_insights_v1(UUID, UUID, DATE)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.compute_weekly_insights_v1(UUID, UUID, DATE)
  TO authenticated;
