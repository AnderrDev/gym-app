-- Reemplaza 'TU_UUID_AQUI' por tu uuid de Supabase, puedes buscarlo usando:
-- SELECT id, email FROM auth.users;

-- Ejemplo:
-- set session_replication_role = replica; -- Si tienes problemas relacionales iniciales

-- 1. Identifica el usuario existente. Supongamos que lo encontramos usando el primer usuario
DO $$
DECLARE
    user_id UUID;
    v_routine_id UUID;
    v_ex1_id UUID;
    v_ex2_id UUID;
BEGIN
    SELECT id INTO user_id FROM auth.users LIMIT 1;
    
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'No hay usuarios en auth.users. Crea uno en la app primero.';
    END IF;

    -- 2. Insertamos la Rutina 
    INSERT INTO public.routines (name, creator_id)
    VALUES ('Mi Primera Rutina Pro', user_id)
    RETURNING id INTO v_routine_id;

    -- 3. Crear Ejercicios base The Glosary
    INSERT INTO public.exercises (name, description)
    VALUES ('Sentadilla', 'Ejercicio compuesto tren inferior')
    RETURNING id INTO v_ex1_id;

    INSERT INTO public.exercises (name, description)
    VALUES ('Press Banca', 'Pecho y Tríceps')
    RETURNING id INTO v_ex2_id;

    -- 4. Anidar ejercicios dentro de la rutina (routine_exercises)
    INSERT INTO public.routine_exercises (routine_id, exercise_id, "order", target_sets, target_reps, target_weight)
    VALUES 
    (v_routine_id, v_ex1_id, 1, 4, 10, 80.0),
    (v_routine_id, v_ex2_id, 2, 3, 8, 100.0);

    -- 5. ASIGNAR LA RUTINA AL USUARIO PARA VERLA EN EL DASHBOARD (user_routines)
    INSERT INTO public.user_routines (user_id, routine_id)
    VALUES (user_id, v_routine_id);
    
    RAISE NOTICE 'Rutina asignada exitosamente al usuario %', user_id;
END $$;
