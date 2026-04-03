-- ============================================================
-- Smart Gym Tracker — Schema completo
-- Versión: 2.0 (Flujo semanal con routine_days)
-- ============================================================

-- ─────────────────────────────────────── LIMPIAR (dev only) ──
-- DROP TABLE IF EXISTS public.set_logs CASCADE;
-- DROP TABLE IF EXISTS public.workout_sessions CASCADE;
-- DROP TABLE IF EXISTS public.routine_exercises CASCADE;
-- DROP TABLE IF EXISTS public.routine_days CASCADE;
-- DROP TABLE IF EXISTS public.user_routines CASCADE;
-- DROP TABLE IF EXISTS public.exercises CASCADE;
-- DROP TABLE IF EXISTS public.routines CASCADE;
-- DROP TABLE IF EXISTS public.profiles CASCADE;

-- ─────────────────────────────────────────── 1. PROFILES ────
CREATE TABLE IF NOT EXISTS public.profiles (
  id        UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Trigger: auto-crear perfil cuando se registra usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ──────────────────────────────────────── 2. EXERCISES (cat) ─
-- Catálogo maestro de ejercicios (reutilizable entre rutinas)
CREATE TABLE IF NOT EXISTS public.exercises (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  description TEXT,
  muscle_group TEXT
);

ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "exercises_select" ON public.exercises FOR SELECT USING (true);

-- ─────────────────────────────────────────── 3. ROUTINES ────
CREATE TABLE IF NOT EXISTS public.routines (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  creator_id  UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.routines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "routines_select" ON public.routines FOR SELECT USING (true);
CREATE POLICY "routines_insert" ON public.routines
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- ──────────────────────────────────── 4. USER_ROUTINES ──────
-- Asignación de rutina a usuario
CREATE TABLE IF NOT EXISTS public.user_routines (
  user_id     UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  routine_id  UUID REFERENCES public.routines(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, routine_id)
);

ALTER TABLE public.user_routines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_routines_select" ON public.user_routines
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_routines_insert" ON public.user_routines
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ──────────────────────────────────── 5. ROUTINE_DAYS ───────
-- Días de entrenamiento de una rutina (Lunes=Pecho, Martes=Espalda...)
CREATE TABLE IF NOT EXISTS public.routine_days (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_id  UUID REFERENCES public.routines(id) ON DELETE CASCADE NOT NULL,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Lun, 7=Dom
  name        TEXT NOT NULL   -- "Pecho y Tríceps", "Espalda y Bíceps"
);

ALTER TABLE public.routine_days ENABLE ROW LEVEL SECURITY;
CREATE POLICY "routine_days_select" ON public.routine_days FOR SELECT USING (true);

-- ────────────────────────────────── 6. ROUTINE_EXERCISES ────
-- Ejercicios configurados para cada día de rutina
CREATE TABLE IF NOT EXISTS public.routine_exercises (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_day_id  UUID REFERENCES public.routine_days(id) ON DELETE CASCADE NOT NULL,
  exercise_id     UUID REFERENCES public.exercises(id) ON DELETE CASCADE NOT NULL,
  "order"         INT NOT NULL DEFAULT 0,
  target_sets     INT NOT NULL DEFAULT 3,
  target_reps     INT NOT NULL DEFAULT 10,
  target_weight   DECIMAL DEFAULT 0
);

ALTER TABLE public.routine_exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "routine_exercises_select" ON public.routine_exercises FOR SELECT USING (true);

-- ─────────────────────────────── 7. WORKOUT_SESSIONS ────────
-- Registro de una sesión (= ejecución de un routine_day en una fecha)
CREATE TABLE IF NOT EXISTS public.workout_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  routine_day_id  UUID REFERENCES public.routine_days(id),
  session_date    DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_date
  ON public.workout_sessions(user_id, session_date);

ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sessions_select" ON public.workout_sessions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "sessions_insert" ON public.workout_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "sessions_update" ON public.workout_sessions
  FOR UPDATE USING (auth.uid() = user_id);

-- ──────────────────────────────────────── 8. SET_LOGS ───────
-- Series individuales registradas en una sesión
CREATE TABLE IF NOT EXISTS public.set_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id  UUID REFERENCES public.workout_sessions(id) ON DELETE CASCADE NOT NULL,
  exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE NOT NULL,
  set_index   INT NOT NULL,
  actual_weight DECIMAL NOT NULL DEFAULT 0,
  actual_reps   INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.set_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "set_logs_select" ON public.set_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.workout_sessions ws
      WHERE ws.id = set_logs.session_id AND ws.user_id = auth.uid()
    )
  );
CREATE POLICY "set_logs_insert" ON public.set_logs
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.workout_sessions ws
      WHERE ws.id = set_logs.session_id AND ws.user_id = auth.uid()
    )
  );
