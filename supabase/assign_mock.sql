-- ============================================================
-- Smart Gym Tracker — Mock Data
-- Rutina de Fuerza completa con días y ejercicios
-- ============================================================
-- REQUISITO: Ejecutar schema.sql primero.
-- REQUISITO: Debe existir al menos un usuario registrado en la app.
-- ============================================================

DO $$
DECLARE
  v_user_id        UUID;
  v_routine_id     UUID;

  -- Días
  v_day_lun        UUID;   -- Lunes: Pecho y Tríceps
  v_day_mar        UUID;   -- Martes: Espalda y Bíceps
  v_day_jue        UUID;   -- Jueves: Piernas
  v_day_vie        UUID;   -- Viernes: Hombros

  -- Ejercicios (catálogo maestro)
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
  -- ── 1. Obtener el primer usuario ─────────────────────────
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No hay usuarios registrados. Crea una cuenta en la app primero.';
  END IF;

  RAISE NOTICE 'Creando datos para usuario: %', v_user_id;

  -- Asegurar que tiene perfil
  INSERT INTO public.profiles (id, full_name)
  VALUES (v_user_id, 'Atleta de Prueba')
  ON CONFLICT (id) DO NOTHING;

  -- ── 2. Catálogo de ejercicios ─────────────────────────────

  -- PECHO / TRICEPS
  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Press Banca', 'Ejercicio compuesto para pecho', 'Pecho')
  RETURNING id INTO v_press_banca;

  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Fondos en paralelas', 'Pecho inferior y tríceps', 'Pecho')
  RETURNING id INTO v_fondos;

  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Tríceps en polea', 'Aislamiento de tríceps', 'Tríceps')
  RETURNING id INTO v_triceps_polea;

  -- ESPALDA / BÍCEPS
  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Peso Muerto', 'Ejercicio compuesto cadena posterior', 'Espalda')
  RETURNING id INTO v_peso_muerto;

  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Jalón al pecho', 'Dorsales con polea alta', 'Espalda')
  RETURNING id INTO v_jalon_pecho;

  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Remo con barra', 'Espalda media y grosor', 'Espalda')
  RETURNING id INTO v_remo_barra;

  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Curl con barra', 'Aislamiento de bíceps', 'Bíceps')
  RETURNING id INTO v_curl_barra;

  -- PIERNAS
  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Sentadilla', 'Rey de los ejercicios de piernas', 'Piernas')
  RETURNING id INTO v_sentadilla;

  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Prensa de piernas', 'Cuádriceps con menor estrés lumbar', 'Piernas')
  RETURNING id INTO v_prensa;

  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Extensión de cuádriceps', 'Aislamiento cuádriceps', 'Piernas')
  RETURNING id INTO v_extension_cuad;

  -- HOMBROS
  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Press Militar', 'Press de hombros con barra', 'Hombros')
  RETURNING id INTO v_press_militar;

  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Elevaciones laterales', 'Deltoides medios', 'Hombros')
  RETURNING id INTO v_elevaciones_lat;

  INSERT INTO public.exercises (name, description, muscle_group)
  VALUES ('Press Arnold', 'Press de hombros con rotación', 'Hombros')
  RETURNING id INTO v_press_arnold;

  -- ── 3. Crear la rutina ───────────────────────────────────
  INSERT INTO public.routines (name, creator_id, is_public)
  VALUES ('Rutina de Fuerza 4 días', v_user_id, true)
  RETURNING id INTO v_routine_id;

  -- ── 4. Crear los días de la rutina ──────────────────────

  -- LUNES: Pecho y Tríceps
  INSERT INTO public.routine_days (routine_id, day_of_week, name)
  VALUES (v_routine_id, 1, 'Pecho y Tríceps')
  RETURNING id INTO v_day_lun;

  -- MARTES: Espalda y Bíceps
  INSERT INTO public.routine_days (routine_id, day_of_week, name)
  VALUES (v_routine_id, 2, 'Espalda y Bíceps')
  RETURNING id INTO v_day_mar;

  -- JUEVES: Piernas
  INSERT INTO public.routine_days (routine_id, day_of_week, name)
  VALUES (v_routine_id, 4, 'Piernas')
  RETURNING id INTO v_day_jue;

  -- VIERNES: Hombros
  INSERT INTO public.routine_days (routine_id, day_of_week, name)
  VALUES (v_routine_id, 5, 'Hombros')
  RETURNING id INTO v_day_vie;

  -- ── 5. Asignar ejercicios a cada día ─────────────────────

  -- LUNES — Pecho y Tríceps
  INSERT INTO public.routine_exercises (routine_day_id, exercise_id, "order", target_sets, target_reps, target_weight)
  VALUES
    (v_day_lun, v_press_banca,   1, 4,  8, 80.0),
    (v_day_lun, v_fondos,        2, 3, 12,  0.0),
    (v_day_lun, v_triceps_polea, 3, 3, 15, 20.0);

  -- MARTES — Espalda y Bíceps
  INSERT INTO public.routine_exercises (routine_day_id, exercise_id, "order", target_sets, target_reps, target_weight)
  VALUES
    (v_day_mar, v_peso_muerto, 1, 3,  5, 120.0),
    (v_day_mar, v_jalon_pecho, 2, 4, 10,  60.0),
    (v_day_mar, v_remo_barra,  3, 3,  8,  70.0),
    (v_day_mar, v_curl_barra,  4, 3, 12,  30.0);

  -- JUEVES — Piernas
  INSERT INTO public.routine_exercises (routine_day_id, exercise_id, "order", target_sets, target_reps, target_weight)
  VALUES
    (v_day_jue, v_sentadilla,    1, 4,  6, 100.0),
    (v_day_jue, v_prensa,        2, 3, 12, 150.0),
    (v_day_jue, v_extension_cuad,3, 3, 15,  40.0);

  -- VIERNES — Hombros
  INSERT INTO public.routine_exercises (routine_day_id, exercise_id, "order", target_sets, target_reps, target_weight)
  VALUES
    (v_day_vie, v_press_militar,   1, 4,  8, 50.0),
    (v_day_vie, v_elevaciones_lat, 2, 4, 15, 12.0),
    (v_day_vie, v_press_arnold,    3, 3, 10, 20.0);

  -- ── 6. Asignar la rutina al usuario ──────────────────────
  INSERT INTO public.user_routines (user_id, routine_id)
  VALUES (v_user_id, v_routine_id)
  ON CONFLICT DO NOTHING;

  -- ── 7. Sesiones históricas de ejemplo ────────────────────
  -- Semana pasada: Lunes y Martes completados
  INSERT INTO public.workout_sessions
    (user_id, routine_day_id, session_date, completed_at)
  VALUES
    (v_user_id, v_day_lun,
      CURRENT_DATE - INTERVAL '7 days' + (1 - EXTRACT(DOW FROM CURRENT_DATE)::INT + 7) % 7 * INTERVAL '1 day',
      NOW() - INTERVAL '8 days' + INTERVAL '1 hour'),
    (v_user_id, v_day_mar,
      CURRENT_DATE - INTERVAL '6 days' + (2 - EXTRACT(DOW FROM CURRENT_DATE)::INT + 7) % 7 * INTERVAL '1 day',
      NOW() - INTERVAL '7 days' + INTERVAL '1.5 hours');

  RAISE NOTICE '✅ Mock data creado exitosamente para usuario %', v_user_id;
  RAISE NOTICE '   Rutina: Rutina de Fuerza 4 días';
  RAISE NOTICE '   Días: Lunes (Pecho), Martes (Espalda), Jueves (Piernas), Viernes (Hombros)';
  RAISE NOTICE '   Sesiones históricas: 2 (semana pasada completadas)';

END $$;
