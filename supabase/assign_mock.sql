-- ============================================================
-- Smart Gym Tracker — Mock Data (idempotente)
-- Crea/asegura una rutina de fuerza completa para el primer
-- usuario registrado. Re-ejecutable sin generar duplicados.
-- ============================================================
-- REQUISITO: Ejecutar schema.sql primero.
-- REQUISITO: Debe existir al menos un usuario registrado.
-- ============================================================

DO $$
DECLARE
  v_user_id        UUID;
  v_routine_id     UUID;

  v_day_lun        UUID;
  v_day_mar        UUID;
  v_day_jue        UUID;
  v_day_vie        UUID;

  v_press_banca    UUID;
  v_fondos         UUID;
  v_triceps_polea  UUID;
  v_peso_muerto    UUID;
  v_jalon_pecho    UUID;
  v_remo_barra     UUID;
  v_curl_barra     UUID;
  v_sentadilla     UUID;
  v_prensa         UUID;
  v_extension_cuad UUID;
  v_press_militar  UUID;
  v_elevaciones_lat UUID;
  v_press_arnold   UUID;

BEGIN
  -- ── 1. Primer usuario ────────────────────────────────────
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at LIMIT 1;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No hay usuarios registrados. Crea una cuenta primero.';
  END IF;
  RAISE NOTICE 'Asignando mock al usuario %', v_user_id;

  INSERT INTO public.profiles (id, full_name)
  VALUES (v_user_id, 'Atleta de Prueba')
  ON CONFLICT (id) DO NOTHING;

  -- ── 2. Catálogo de ejercicios (idempotente por nombre) ───
  -- Cada ejercicio: si existe lo reusamos; si no, lo insertamos.

  SELECT id INTO v_press_banca FROM public.exercises WHERE name = 'Press Banca' LIMIT 1;
  IF v_press_banca IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Press Banca', 'Ejercicio compuesto para pecho', 'Pecho')
    RETURNING id INTO v_press_banca;
  END IF;

  SELECT id INTO v_fondos FROM public.exercises WHERE name = 'Fondos en paralelas' LIMIT 1;
  IF v_fondos IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Fondos en paralelas', 'Pecho inferior y tríceps', 'Pecho')
    RETURNING id INTO v_fondos;
  END IF;

  SELECT id INTO v_triceps_polea FROM public.exercises WHERE name = 'Tríceps en polea' LIMIT 1;
  IF v_triceps_polea IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Tríceps en polea', 'Aislamiento de tríceps', 'Tríceps')
    RETURNING id INTO v_triceps_polea;
  END IF;

  SELECT id INTO v_peso_muerto FROM public.exercises WHERE name = 'Peso Muerto' LIMIT 1;
  IF v_peso_muerto IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Peso Muerto', 'Ejercicio compuesto cadena posterior', 'Espalda')
    RETURNING id INTO v_peso_muerto;
  END IF;

  SELECT id INTO v_jalon_pecho FROM public.exercises WHERE name = 'Jalón al pecho' LIMIT 1;
  IF v_jalon_pecho IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Jalón al pecho', 'Dorsales con polea alta', 'Espalda')
    RETURNING id INTO v_jalon_pecho;
  END IF;

  SELECT id INTO v_remo_barra FROM public.exercises WHERE name = 'Remo con barra' LIMIT 1;
  IF v_remo_barra IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Remo con barra', 'Espalda media y grosor', 'Espalda')
    RETURNING id INTO v_remo_barra;
  END IF;

  SELECT id INTO v_curl_barra FROM public.exercises WHERE name = 'Curl con barra' LIMIT 1;
  IF v_curl_barra IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Curl con barra', 'Aislamiento de bíceps', 'Bíceps')
    RETURNING id INTO v_curl_barra;
  END IF;

  SELECT id INTO v_sentadilla FROM public.exercises WHERE name = 'Sentadilla' LIMIT 1;
  IF v_sentadilla IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Sentadilla', 'Rey de los ejercicios de piernas', 'Piernas')
    RETURNING id INTO v_sentadilla;
  END IF;

  SELECT id INTO v_prensa FROM public.exercises WHERE name = 'Prensa de piernas' LIMIT 1;
  IF v_prensa IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Prensa de piernas', 'Cuádriceps con menor estrés lumbar', 'Piernas')
    RETURNING id INTO v_prensa;
  END IF;

  SELECT id INTO v_extension_cuad FROM public.exercises WHERE name = 'Extensión de cuádriceps' LIMIT 1;
  IF v_extension_cuad IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Extensión de cuádriceps', 'Aislamiento cuádriceps', 'Piernas')
    RETURNING id INTO v_extension_cuad;
  END IF;

  SELECT id INTO v_press_militar FROM public.exercises WHERE name = 'Press Militar' LIMIT 1;
  IF v_press_militar IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Press Militar', 'Press de hombros con barra', 'Hombros')
    RETURNING id INTO v_press_militar;
  END IF;

  SELECT id INTO v_elevaciones_lat FROM public.exercises WHERE name = 'Elevaciones laterales' LIMIT 1;
  IF v_elevaciones_lat IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Elevaciones laterales', 'Deltoides medios', 'Hombros')
    RETURNING id INTO v_elevaciones_lat;
  END IF;

  SELECT id INTO v_press_arnold FROM public.exercises WHERE name = 'Press Arnold' LIMIT 1;
  IF v_press_arnold IS NULL THEN
    INSERT INTO public.exercises (name, description, muscle_group)
    VALUES ('Press Arnold', 'Press de hombros con rotación', 'Hombros')
    RETURNING id INTO v_press_arnold;
  END IF;

  -- ── 3. Rutina (única por creator+name) ───────────────────
  SELECT id INTO v_routine_id FROM public.routines
    WHERE creator_id = v_user_id AND name = 'Rutina de Fuerza 4 días'
    LIMIT 1;
  IF v_routine_id IS NULL THEN
    INSERT INTO public.routines (name, creator_id, is_public)
    VALUES ('Rutina de Fuerza 4 días', v_user_id, true)
    RETURNING id INTO v_routine_id;
  END IF;

  -- ── 4. Días (uno por day_of_week dentro de la rutina) ────
  SELECT id INTO v_day_lun FROM public.routine_days
    WHERE routine_id = v_routine_id AND day_of_week = 1 LIMIT 1;
  IF v_day_lun IS NULL THEN
    INSERT INTO public.routine_days (routine_id, day_of_week, name)
    VALUES (v_routine_id, 1, 'Pecho y Tríceps')
    RETURNING id INTO v_day_lun;
  END IF;

  SELECT id INTO v_day_mar FROM public.routine_days
    WHERE routine_id = v_routine_id AND day_of_week = 2 LIMIT 1;
  IF v_day_mar IS NULL THEN
    INSERT INTO public.routine_days (routine_id, day_of_week, name)
    VALUES (v_routine_id, 2, 'Espalda y Bíceps')
    RETURNING id INTO v_day_mar;
  END IF;

  SELECT id INTO v_day_jue FROM public.routine_days
    WHERE routine_id = v_routine_id AND day_of_week = 4 LIMIT 1;
  IF v_day_jue IS NULL THEN
    INSERT INTO public.routine_days (routine_id, day_of_week, name)
    VALUES (v_routine_id, 4, 'Piernas')
    RETURNING id INTO v_day_jue;
  END IF;

  SELECT id INTO v_day_vie FROM public.routine_days
    WHERE routine_id = v_routine_id AND day_of_week = 5 LIMIT 1;
  IF v_day_vie IS NULL THEN
    INSERT INTO public.routine_days (routine_id, day_of_week, name)
    VALUES (v_routine_id, 5, 'Hombros')
    RETURNING id INTO v_day_vie;
  END IF;

  -- ── 5. Ejercicios por día (idempotente por (day, exercise)) ─
  -- Insertamos con NOT EXISTS para no duplicar; no actualizamos
  -- targets para no pisar progresiones del usuario.

  INSERT INTO public.routine_exercises (routine_day_id, exercise_id, "order", target_sets, target_reps, target_weight)
  SELECT * FROM (VALUES
    (v_day_lun, v_press_banca,    1, 4,  8,  80.0),
    (v_day_lun, v_fondos,         2, 3, 12,   0.0),
    (v_day_lun, v_triceps_polea,  3, 3, 15,  20.0),
    (v_day_mar, v_peso_muerto,    1, 3,  5, 120.0),
    (v_day_mar, v_jalon_pecho,    2, 4, 10,  60.0),
    (v_day_mar, v_remo_barra,     3, 3,  8,  70.0),
    (v_day_mar, v_curl_barra,     4, 3, 12,  30.0),
    (v_day_jue, v_sentadilla,     1, 4,  6, 100.0),
    (v_day_jue, v_prensa,         2, 3, 12, 150.0),
    (v_day_jue, v_extension_cuad, 3, 3, 15,  40.0),
    (v_day_vie, v_press_militar,  1, 4,  8,  50.0),
    (v_day_vie, v_elevaciones_lat,2, 4, 15,  12.0),
    (v_day_vie, v_press_arnold,   3, 3, 10,  20.0)
  ) AS v(routine_day_id, exercise_id, ord, target_sets, target_reps, target_weight)
  WHERE NOT EXISTS (
    SELECT 1 FROM public.routine_exercises re
    WHERE re.routine_day_id = v.routine_day_id
      AND re.exercise_id = v.exercise_id
  );

  -- ── 6. Asignar la rutina al usuario ──────────────────────
  INSERT INTO public.user_routines (user_id, routine_id)
  VALUES (v_user_id, v_routine_id)
  ON CONFLICT (user_id) DO UPDATE SET routine_id = EXCLUDED.routine_id;

  RAISE NOTICE '✅ Mock asignado idempotentemente a %', v_user_id;
END $$;
