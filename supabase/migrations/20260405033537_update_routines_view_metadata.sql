-- Crear una vista para simplificar el acceso a rutinas con su metadata completa
CREATE OR REPLACE VIEW public.routines_view AS
SELECT
    r.id,
    r.name,
    r.creator_id,
    r.created_at,
    r.is_public,
    p.full_name as creator_name,
    (
        SELECT COUNT(re.id)
        FROM public.routine_days rd
        JOIN public.routine_exercises re ON rd.id = re.routine_day_id
        WHERE rd.routine_id = r.id
    ) as exercise_count
FROM public.routines r
LEFT JOIN public.profiles p ON r.creator_id = p.id;

-- RLS: La vista hereda los permisos de las tablas subyacentes en PostgreSQL (standard)
-- Pero en Supabase, si la vista es consultada por PostgREST, se aplican las políticas de las tablas.
-- Aseguramos que profiles y rutinas tengan sus políticas.
