-- Coach v2, fase 1a (docs/coach/PLAN_COACH_V2.md): catálogo de ejercicios
-- clasificado y rango de repeticiones en la rutina. Solo añade columnas y
-- datos; ningún contrato existente cambia.

-- 1. Variantes de grupo muscular: una sola grafía por grupo.
UPDATE public.exercises SET muscle_group='Piernas' WHERE muscle_group='Pierna';
UPDATE public.exercises SET muscle_group='Hombros' WHERE muscle_group='Hombro';
UPDATE public.exercises SET muscle_group='Tríceps' WHERE muscle_group='Triceps';

-- 2. Clasificación que usa el motor para elegir incrementos y priors.
ALTER TABLE public.exercises
  ADD COLUMN movement_type text CHECK (movement_type IN ('compound','isolation')),
  ADD COLUMN body_region text CHECK (body_region IN ('upper','lower','core')),
  -- Salto mínimo de carga que permite el equipo (kg). NULL = sin carga
  -- externa: el motor progresa solo por repeticiones.
  ADD COLUMN load_increment_kg numeric CHECK (load_increment_kg IS NULL OR load_increment_kg > 0);

UPDATE public.exercises SET body_region = CASE
  WHEN muscle_group IN ('Piernas','Glúteos','Pantorrillas') THEN 'lower'
  WHEN muscle_group = 'Abdomen' THEN 'core'
  ELSE 'upper' END;

-- Multiarticulares: presses, remos, jalones, sentadillas, prensas, bisagras.
UPDATE public.exercises SET movement_type = CASE
  WHEN lower(name) ~ '(^press |press banca|^remo|^jal[oó]n|dominada|fondos|sentadilla|hack squat|prensa|peso muerto|hip thrust|zancada|step-up)'
   AND lower(name) !~ '(franc[eé]s|pallof)'
  THEN 'compound' ELSE 'isolation' END;

UPDATE public.exercises SET load_increment_kg = CASE
  WHEN lower(name) ~ '(plancha|circuito core|elevaci[oó]n de piernas|back extension)' THEN NULL
  WHEN lower(coalesce(equipment,'') || ' ' || name) ~ 'mancuerna' THEN 2
  WHEN body_region = 'lower' AND movement_type = 'compound'
   AND lower(coalesce(equipment,'') || ' ' || name) ~ '(m[aá]quina|prensa|hack)' THEN 5
  ELSE 2.5 END;

-- 3. Rango de repeticiones para la doble progresión: target_reps es el
-- mínimo; NULL en el máximo = rango de un solo valor (comportamiento actual).
-- Sin CHECK contra target_reps: los editores actuales cambian target_reps sin
-- conocer el máximo y no deben fallar. El motor usa greatest(máximo, mínimo).
ALTER TABLE public.routine_exercises
  ADD COLUMN target_reps_max integer CHECK (target_reps_max IS NULL OR target_reps_max BETWEEN 1 AND 1000);

-- 4. El snapshot de la sesión lleva el máximo del rango (clave nueva y
-- opcional en cada elemento de exercise_plan; los clientes la ignoran).
CREATE OR REPLACE FUNCTION public.get_session_exercises_v1(p_session_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE s public.workout_sessions; plan jsonb;
BEGIN
  SELECT * INTO s FROM public.workout_sessions WHERE id=p_session_id FOR UPDATE;
  IF NOT FOUND OR auth.uid() IS NULL OR s.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden: session ownership' USING ERRCODE='42501';
  END IF;
  IF s.exercise_plan IS NOT NULL THEN RETURN s.exercise_plan; END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id',e.id,'routine_day_id',re.routine_day_id,'name',e.name,'muscle_group',e.muscle_group,
    'target_sets',re.target_sets,'target_reps',re.target_reps,'target_reps_max',re.target_reps_max,
    'target_weight',re.target_weight,
    'rest_timer_seconds',coalesce(re.rest_timer_seconds,90),'is_extra',false,
    'replaces_exercise_name',NULL,'replaced_by_exercise_name',NULL) ORDER BY coalesce((to_jsonb(re)->>'order')::integer,0), re.id),'[]'::jsonb)
  INTO plan FROM public.routine_exercises re JOIN public.exercises e ON e.id=re.exercise_id
  WHERE re.routine_day_id=s.routine_day_id;
  IF s.completed_at IS NULL THEN
    IF jsonb_array_length(plan)>100 THEN RAISE EXCEPTION 'too many exercises' USING ERRCODE='23514'; END IF;
    UPDATE public.workout_sessions SET exercise_plan=plan WHERE id=s.id;
  END IF;
  RETURN plan;
END $$;
