-- ============================================================
-- Constraints, índices y tipado JSONB.
-- Cierra brechas detectadas en la auditoría 2026-05-12:
--   1. idx_routines_creator_id — la query "mis rutinas" hacía seq scan.
--   2. CHECK no-negatividad en set_logs (set_index, actual_reps, actual_weight).
--   3. workout_sessions.routine_day_id NOT NULL si los datos lo permiten.
--   4. CHECK jsonb_typeof en workout_sessions.coaching_analysis
--      (array o null) para evitar payloads malformados.
-- ============================================================

-- 1. Índice para "rutinas creadas por mí" -----------------------
CREATE INDEX IF NOT EXISTS idx_routines_creator_id
  ON public.routines (creator_id);

-- 2. CHECKs de no-negatividad en set_logs ----------------------
-- Usamos NOT VALID + VALIDATE para que la migración no falle si hay
-- legacy con valores fuera de rango: en ese caso el VALIDATE lanza
-- y queda pendiente de limpieza manual antes de re-ejecutar.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'set_logs_set_index_nonneg'
      AND conrelid = 'public.set_logs'::regclass
  ) THEN
    ALTER TABLE public.set_logs
      ADD CONSTRAINT set_logs_set_index_nonneg
      CHECK (set_index >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'set_logs_actual_reps_nonneg'
      AND conrelid = 'public.set_logs'::regclass
  ) THEN
    ALTER TABLE public.set_logs
      ADD CONSTRAINT set_logs_actual_reps_nonneg
      CHECK (actual_reps >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'set_logs_actual_weight_nonneg'
      AND conrelid = 'public.set_logs'::regclass
  ) THEN
    ALTER TABLE public.set_logs
      ADD CONSTRAINT set_logs_actual_weight_nonneg
      CHECK (actual_weight >= 0) NOT VALID;
  END IF;
END $$;

ALTER TABLE public.set_logs VALIDATE CONSTRAINT set_logs_set_index_nonneg;
ALTER TABLE public.set_logs VALIDATE CONSTRAINT set_logs_actual_reps_nonneg;
ALTER TABLE public.set_logs VALIDATE CONSTRAINT set_logs_actual_weight_nonneg;

-- 3. workout_sessions.routine_day_id NOT NULL ------------------
-- Solo si no hay filas huérfanas. Si las hay, dejamos un warning
-- y NO forzamos el NOT NULL (evita romper la migración en prod).
DO $$
DECLARE
  orphan_count BIGINT;
BEGIN
  SELECT COUNT(*) INTO orphan_count
  FROM public.workout_sessions
  WHERE routine_day_id IS NULL;

  IF orphan_count = 0 THEN
    ALTER TABLE public.workout_sessions
      ALTER COLUMN routine_day_id SET NOT NULL;
  ELSE
    RAISE WARNING 'workout_sessions tiene % filas con routine_day_id NULL; '
      'limpia esos registros y re-ejecuta esta migración para imponer NOT NULL.',
      orphan_count;
  END IF;
END $$;

-- 4. CHECK jsonb_typeof en coaching_analysis -------------------
-- coaching_analysis SIEMPRE debe ser array o null; el contrato del
-- Edge Function `generate_coaching_v1` lo emite así, y la UI lo
-- itera asumiendo array.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'workout_sessions_coaching_analysis_is_array'
      AND conrelid = 'public.workout_sessions'::regclass
  ) THEN
    ALTER TABLE public.workout_sessions
      ADD CONSTRAINT workout_sessions_coaching_analysis_is_array
      CHECK (
        coaching_analysis IS NULL
        OR jsonb_typeof(coaching_analysis) = 'array'
      ) NOT VALID;
  END IF;
END $$;

ALTER TABLE public.workout_sessions
  VALIDATE CONSTRAINT workout_sessions_coaching_analysis_is_array;
