-- Ajuste por pausa más suave en get_next_targets_v1 (banco de escenarios,
-- 2026-10-24): con la tabla anterior (14 d −7,5 %, 28 d −15 %, 56 d −25 %)
-- un atleta con asistencia irregular (2–20 días entre sesiones) acababa con
-- MENOS carga que al empezar y con 2 vaivenes cada 10 sesiones. La fuerza se
-- conserva bien ~3 semanas; ahora: <21 d sin cambio, 21–27 −5 %, 28–55 −10 %,
-- ≥56 −20 %. Misma firma y mismos permisos.
CREATE OR REPLACE FUNCTION public.get_next_targets_v1(p_exercise_ids uuid[])
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
         CASE WHEN l.days_since < 21 OR l.suggested_weight = 0 THEN l.suggested_weight
              ELSE greatest(0, round(l.suggested_weight * CASE WHEN l.days_since < 28 THEN 0.95
                                                               WHEN l.days_since < 56 THEN 0.90
                                                               ELSE 0.80 END / l.step) * l.step) END,
         l.suggested_reps, l.recommendation, l.reason_code, l.session_date, l.days_since,
         l.days_since >= 21 AND l.suggested_weight > 0
  FROM latest l;
$$;

