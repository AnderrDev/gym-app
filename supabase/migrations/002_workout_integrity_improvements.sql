-- ──────────────────────────────────────────────────────────
-- Migración 002: Integridad y Coaching
-- ──────────────────────────────────────────────────────────

-- 1. Añadir columnas a workout_sessions
ALTER TABLE public.workout_sessions 
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS coaching_analysis JSONB;

-- 2. Crear vista de resumen de progreso
-- Esta vista ayuda a obtener los contadores de series sin lógica compleja en Flutter
CREATE OR REPLACE VIEW public.view_workout_sessions_summary AS
WITH target_stats AS (
  -- Sumar series objetivo por cada sesión basándose en el routine_day
  SELECT 
    ws.id as session_id,
    COALESCE(SUM(re.target_sets), 0) as total_target_sets
  FROM public.workout_sessions ws
  JOIN public.routine_exercises re ON re.routine_day_id = ws.routine_day_id
  GROUP BY ws.id
),
completed_stats AS (
  -- Contar series realmente registradas en set_logs
  SELECT 
    session_id,
    COUNT(*) as total_completed_sets
  FROM public.set_logs
  GROUP BY session_id
)
SELECT 
  ws.*,
  COALESCE(ts.total_target_sets, 0) as total_target_sets,
  COALESCE(cs.total_completed_sets, 0) as total_completed_sets,
  (COALESCE(cs.total_completed_sets, 0) >= COALESCE(ts.total_target_sets, 0) AND ws.completed_at IS NOT NULL) as is_strictly_completed
FROM public.workout_sessions ws
LEFT JOIN target_stats ts ON ts.session_id = ws.id
LEFT JOIN completed_stats cs ON cs.session_id = ws.id;

-- 3. Políticas RLS para la vista (Las vistas heredan RLS de las tablas base, 
-- pero es buena práctica asegurar que las tablas base tengan las políticas correctas).
-- Ya existen en schema.sql.
