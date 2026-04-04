-- ============================================================
-- Smart Gym Tracker — Seed de Datos de Prueba (Free Log Mode)
-- Escenario: Historial rico (1 rutina completa la semana pasada, 2 rutinas antepasadas)
-- ============================================================

-- 2. Limpieza total
TRUNCATE TABLE public.profiles CASCADE;
TRUNCATE TABLE public.set_logs CASCADE;
TRUNCATE TABLE public.workout_sessions CASCADE;
TRUNCATE TABLE public.routine_exercises CASCADE;
TRUNCATE TABLE public.routine_days CASCADE;
TRUNCATE TABLE public.user_routines CASCADE;
TRUNCATE TABLE public.exercises CASCADE;
TRUNCATE TABLE public.routines CASCADE;

-- 1. Gestión de Usuario en Auth
DO $$
BEGIN
  DELETE FROM auth.users WHERE email = 'test@gym.com';
END $$;

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000', 
  '11111111-0000-0000-0000-000000000001', 
  'authenticated', 
  'authenticated', 
  'test@gym.com', 
  crypt('Test1234!', gen_salt('bf')), 
  NOW(), 
  NOW(), 
  NOW(), 
  '{"provider":"email","providers":["email"]}', 
  '{"full_name":"Test User"}', 
  NOW(), 
  NOW(), 
  '', 
  '', 
  '', 
  ''
);

-- 3. Catálogo de Ejercicios
INSERT INTO public.exercises (id, name, description, muscle_group) VALUES
  ('eeeeeeee-0000-0000-0000-000000000001', 'Press de Banca Plano', 'Barra libre', 'Pecho'),
  ('eeeeeeee-0000-0000-0000-000000000002', 'Aperturas en Polea', 'Polea media', 'Pecho'),
  ('eeeeeeee-0000-0000-0000-000000000003', 'Extensión de Tríceps', 'Empuje cuerda', 'Triceps'),
  ('eeeeeeee-0000-0000-0000-000000000004', 'Dominadas', 'Agarre prono', 'Espalda'),
  ('eeeeeeee-0000-0000-0000-000000000005', 'Sentadilla Libre', 'Barra espalda', 'Pierna'),
  ('eeeeeeee-0000-0000-0000-000000000006', 'Remo con Remo', 'Polea baja', 'Espalda');

-- 4. Rutina PPL
INSERT INTO public.routines (id, name, creator_id) VALUES
  ('22222222-0000-0000-0000-000000000001', 'Hipertrofia PPL', '11111111-0000-0000-0000-000000000001');

INSERT INTO public.routine_days (id, routine_id, day_of_week, name) VALUES
  ('dddddddd-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', 1, 'Empuje (Pecho/Tríceps)'),
  ('dddddddd-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000001', 3, 'Tirón (Espalda/Bíceps)'),
  ('dddddddd-0000-0000-0000-000000000003', '22222222-0000-0000-0000-000000000001', 5, 'Pierna');

INSERT INTO public.routine_exercises (routine_day_id, exercise_id, "order", target_sets, target_reps, target_weight) VALUES
  ('dddddddd-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', 1, 4, 10, 60),
  ('dddddddd-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000003', 2, 3, 12, 20),
  ('dddddddd-0000-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000004', 1, 4, 8, 80),
  ('dddddddd-0000-0000-0000-000000000003', 'eeeeeeee-0000-0000-0000-000000000005', 1, 4, 10, 100);

INSERT INTO public.user_routines (user_id, routine_id) VALUES 
  ('11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001');

-- 5. SESIONES (Semanas Previas)
-- Usamos un bloque anónimo para insertar sesiones con lógica de fecha
DO $$
DECLARE
  uid UUID := '11111111-0000-0000-0000-000000000001';
  sid UUID;
  d_empuje UUID := 'dddddddd-0000-0000-0000-000000000001';
  d_tiron UUID := 'dddddddd-0000-0000-0000-000000000002';
  d_pierna UUID := 'dddddddd-0000-0000-0000-000000000003';
  e_banca UUID := 'eeeeeeee-0000-0000-0000-000000000001';
  e_triceps UUID := 'eeeeeeee-0000-0000-0000-000000000003';
  e_domis UUID := 'eeeeeeee-0000-0000-0000-000000000004';
  e_senta UUID := 'eeeeeeee-0000-0000-0000-000000000005';
BEGIN
  -- SEMANA PASADA (1 Rutina Completa = 3 días)
  -- Lunes pasado: Completado con Coaching
  INSERT INTO public.workout_sessions (user_id, routine_day_id, session_date, completed_at, coaching_analysis) 
  VALUES (uid, d_empuje, CURRENT_DATE - 7, NOW() - INTERVAL '7 days', 
  '[{"exercise_id":"eeeeeeee-0000-0000-0000-000000000001", "exercise_name":"Press de Banca Plano", "performance_score":0.9, "feedback":"Excelente trabajo, mantén el peso.", "recommendation":"MANTAIN_WEIGHT"}]'::jsonb) 
  RETURNING id INTO sid;
  INSERT INTO public.set_logs (session_id, exercise_id, set_index, actual_weight, actual_reps) 
  VALUES (sid, e_banca, 1, 60, 10), (sid, e_banca, 2, 60, 10), (sid, e_banca, 3, 60, 10), (sid, e_banca, 4, 60, 10);

  -- Miércoles pasado: Incompleto (No debería decir completado)
  INSERT INTO public.workout_sessions (user_id, routine_day_id, session_date, completed_at) 
  VALUES (uid, d_tiron, CURRENT_DATE - 5, NULL) RETURNING id INTO sid;
  INSERT INTO public.set_logs (session_id, exercise_id, set_index, actual_weight, actual_reps) 
  VALUES (sid, e_domis, 1, 80, 8);

  -- Viernes pasado: Completado con Coaching (Superó expectativas)
  INSERT INTO public.workout_sessions (user_id, routine_day_id, session_date, completed_at, coaching_analysis) 
  VALUES (uid, d_pierna, CURRENT_DATE - 3, NOW() - INTERVAL '3 days',
  '[{"exercise_id":"eeeeeeee-0000-0000-0000-000000000005", "exercise_name":"Sentadilla Libre", "performance_score":1.1, "feedback":"¡Increíble! Sube 5kg.", "recommendation":"INCREASE_WEIGHT"}]'::jsonb) 
  RETURNING id INTO sid;
  INSERT INTO public.set_logs (session_id, exercise_id, set_index, actual_weight, actual_reps) 
  VALUES (sid, e_senta, 1, 100, 10), (sid, e_senta, 2, 100, 10), (sid, e_senta, 3, 100, 10), (sid, e_senta, 4, 100, 10);

  -- SEMANA ACTUAL (Para pruebas interactivas)
  -- Ayer: Sesión iniciada pero no terminada (debería decir "En progreso")
  INSERT INTO public.workout_sessions (user_id, routine_day_id, session_date, completed_at) 
  VALUES (uid, d_empuje, CURRENT_DATE - 1, NULL) RETURNING id INTO sid;
  INSERT INTO public.set_logs (session_id, exercise_id, set_index, actual_weight, actual_reps) 
  VALUES (sid, e_banca, 1, 62.5, 10);

  -- Hoy: Sesión por hacer
  -- (No insertamos nada, el usuario la iniciará en la app)

  -- ANTEPASADA (Historial histórico)
  INSERT INTO public.workout_sessions (user_id, routine_day_id, session_date, completed_at, coaching_analysis) 
  VALUES (uid, d_empuje, CURRENT_DATE - 14, NOW() - INTERVAL '14 days', 
  '[{"exercise_id":"eeeeeeee-0000-0000-0000-000000000001", "exercise_name":"Press de Banca Plano", "performance_score":0.8, "feedback":"Buen esfuerzo.", "recommendation":"MANTAIN_WEIGHT"}]'::jsonb) 
  RETURNING id INTO sid;
  INSERT INTO public.set_logs (session_id, exercise_id, set_index, actual_weight, actual_reps) VALUES (sid, e_banca, 1, 55, 12);
  
END $$;

-- 6. Garantizar Perfil
INSERT INTO public.profiles (id, full_name)
VALUES ('11111111-0000-0000-0000-000000000001', 'Test User')
ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
