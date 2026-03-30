-- 1. Profiles (Extiende auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT
);

-- Habilitar RLS en perfiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. Routines (La Plantilla)
CREATE TABLE public.routines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  creator_id UUID REFERENCES public.profiles(id)
);

ALTER TABLE public.routines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Routines are viewable by everyone." ON public.routines FOR SELECT USING (true);

-- (Tabla de Ejercicios Maestros, necesaria para referenciar 'exercise_id')
CREATE TABLE public.exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT
);

ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Exercises are viewable by everyone." ON public.exercises FOR SELECT USING (true);

-- 3. User Routines (La Asignación)
CREATE TABLE public.user_routines (
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  routine_id UUID REFERENCES public.routines(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, routine_id)
);

ALTER TABLE public.user_routines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their assigned routines." ON public.user_routines FOR SELECT USING (auth.uid() = user_id);

-- 4. Routine Exercises (La Configuración y Objetivos)
CREATE TABLE public.routine_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_id UUID REFERENCES public.routines(id) ON DELETE CASCADE,
  exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
  "order" INT NOT NULL DEFAULT 0,
  target_sets INT NOT NULL,
  target_reps INT NOT NULL,
  target_weight DECIMAL
);

ALTER TABLE public.routine_exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Routine exercises are viewable by everyone." ON public.routine_exercises FOR SELECT USING (true);

-- 5. Workout Sessions (La Ejecución)
CREATE TABLE public.workout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  routine_id UUID REFERENCES public.routines(id) ON DELETE CASCADE,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  total_volume DECIMAL
);

ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own sessions." ON public.workout_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own sessions." ON public.workout_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own sessions." ON public.workout_sessions FOR UPDATE USING (auth.uid() = user_id);

-- 6. Set Logs (El Seguimiento Real)
CREATE TABLE public.set_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES public.workout_sessions(id) ON DELETE CASCADE,
  exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
  set_index INT NOT NULL,
  actual_weight DECIMAL NOT NULL,
  actual_reps INT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.set_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own set logs." ON public.set_logs FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.workout_sessions ws
    WHERE ws.id = set_logs.session_id AND ws.user_id = auth.uid()
  )
);
CREATE POLICY "Users insert own set logs." ON public.set_logs FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.workout_sessions ws
    WHERE ws.id = set_logs.session_id AND ws.user_id = auth.uid()
  )
);
