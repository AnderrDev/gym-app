-- ──────────────────────────────────────────────────────────────────────────
-- Extiende `exercises` con media e instrucciones
-- ──────────────────────────────────────────────────────────────────────────
-- Feature: detalle de ejercicio con preview visual (foto/animación), tutorial
-- en video (URL externa, ej. YouTube), instrucciones paso-a-paso y consejos.
-- Modelo híbrido: image/animation viven en bucket Supabase `exercise-media`
-- (URLs públicas almacenadas como text); video puede vivir afuera.
--
-- Todos los campos son nullable: una entrada del catálogo puede tener sólo
-- algunos rellenos. La UI debe degradar elegantemente cuando faltan.

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS image_url      text,
  ADD COLUMN IF NOT EXISTS animation_url  text,
  ADD COLUMN IF NOT EXISTS video_url      text,
  ADD COLUMN IF NOT EXISTS instructions   text,
  ADD COLUMN IF NOT EXISTS tips           text,
  ADD COLUMN IF NOT EXISTS equipment      text,
  ADD COLUMN IF NOT EXISTS difficulty     text;

-- Validamos el set de dificultad para evitar typos. El check es laxo (acepta
-- null) y normalizado a minúsculas en la app.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'exercises_difficulty_check'
  ) THEN
    ALTER TABLE public.exercises
      ADD CONSTRAINT exercises_difficulty_check
      CHECK (
        difficulty IS NULL
        OR difficulty IN ('principiante', 'intermedio', 'avanzado')
      );
  END IF;
END $$;

-- Refrescamos la vista del catálogo (si alguna depende). `routines_view` no
-- usa estas columnas, así que no requiere recompilarse.

COMMENT ON COLUMN public.exercises.image_url     IS 'URL pública de imagen estática (preferentemente bucket exercise-media)';
COMMENT ON COLUMN public.exercises.animation_url IS 'URL pública de GIF o MP4 corto demostrando el movimiento';
COMMENT ON COLUMN public.exercises.video_url     IS 'URL externa (ej. YouTube) para tutorial extendido';
COMMENT ON COLUMN public.exercises.instructions  IS 'Pasos para ejecutar el ejercicio. Markdown-lite: párrafos separados por blank line, bullets con prefijo "- "';
COMMENT ON COLUMN public.exercises.tips          IS 'Consejos y errores comunes. Misma sintaxis Markdown-lite que instructions';
COMMENT ON COLUMN public.exercises.equipment     IS 'Equipo necesario, ej. "Barra olímpica", "Mancuernas", "Polea alta"';
COMMENT ON COLUMN public.exercises.difficulty    IS 'principiante | intermedio | avanzado';
