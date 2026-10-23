-- Carga de datos, sin cambios de esquema ni asignación a usuarios.
-- Rangos completos/RIR: docs/routines/recomposicion-ulppl-12-semanas.md.
-- Revisión 4.1: si la rutina ya existe se sincroniza en sitio (mismos días,
-- se conserva target_weight de los ejercicios que siguen; se borran los que
-- salen). set_logs referencian exercise_id, no routine_exercises, y las
-- sesiones abiertas usan su exercise_plan congelado, así que el historial no
-- se toca. Idempotente.
BEGIN;
SELECT pg_advisory_xact_lock(hashtext('seed_recomposicion_ulppl_12_semanas_v1'));
CREATE TEMP TABLE plan_import (
 day_of_week int, day_name text, exercise_order int, exercise_name text,
 muscle_group text, sets int, reps_min int, reps_max int, rest_seconds int, rir text
) ON COMMIT DROP;
INSERT INTO plan_import VALUES
(1,'Upper · Fuerza de tren superior',1,'Press banca barra','Pecho',3,5,8,180,'1–2'),
(1,'Upper · Fuerza de tren superior',2,'Jalón al pecho','Espalda',3,6,10,180,'1–2'),
(1,'Upper · Fuerza de tren superior',3,'Remo máquina pecho soportado','Espalda',3,8,12,120,'1–2'),
(1,'Upper · Fuerza de tren superior',4,'Press inclinado mancuernas','Pecho',3,8,12,120,'1–2'),
(1,'Upper · Fuerza de tren superior',5,'Elevación lateral mancuerna','Hombros',3,12,20,90,'1–2'),
(1,'Upper · Fuerza de tren superior',6,'Curl predicador','Bíceps',2,10,15,90,'1–2'),
(1,'Upper · Fuerza de tren superior',7,'Extensión de tríceps sobre la cabeza en polea','Tríceps',2,10,15,75,'1–2'),
(2,'Lower · Fuerza de tren inferior',1,'Hack squat','Piernas',3,5,8,180,'1–2'),
(2,'Lower · Fuerza de tren inferior',2,'Peso muerto rumano','Piernas',3,6,10,180,'1–2'),
(2,'Lower · Fuerza de tren inferior',3,'Curl femoral sentado','Piernas',3,10,15,90,'1–2'),
(2,'Lower · Fuerza de tren inferior',4,'Prensa de piernas','Piernas',2,10,12,120,'1–2'),
(2,'Lower · Fuerza de tren inferior',5,'Gemelos de pie','Pantorrillas',3,10,15,75,'1–2'),
(2,'Lower · Fuerza de tren inferior',6,'Aductores en máquina','Piernas',1,12,20,75,'1–2'),
(2,'Lower · Fuerza de tren inferior',7,'Pallof press','Abdomen',2,10,15,60,'1–2'),
(4,'Push · Hipertrofia de empuje',1,'Press inclinado en Smith','Pecho',3,8,12,120,'1–2'),
(4,'Push · Hipertrofia de empuje',2,'Press declinado en máquina','Pecho',3,8,12,120,'1–2'),
(4,'Push · Hipertrofia de empuje',3,'Pec deck','Pecho',2,12,15,90,'1'),
(4,'Push · Hipertrofia de empuje',4,'Press de hombros en máquina','Hombros',2,8,12,120,'1–2'),
(4,'Push · Hipertrofia de empuje',5,'Elevación lateral en polea','Hombros',4,12,20,90,'1'),
(4,'Push · Hipertrofia de empuje',6,'Extensión de tríceps sobre la cabeza en polea','Tríceps',2,10,15,90,'1'),
(4,'Push · Hipertrofia de empuje',7,'Tríceps cuerda','Tríceps',1,12,15,75,'1'),
(5,'Pull · Hipertrofia de tracción',1,'Jalón polea neutro estrecho','Espalda',3,8,12,120,'1–2'),
(5,'Pull · Hipertrofia de tracción',2,'Remo en polea baja','Espalda',3,8,12,120,'1–2'),
(5,'Pull · Hipertrofia de tracción',3,'Pullover polea','Espalda',2,12,15,90,'1–2'),
(5,'Pull · Hipertrofia de tracción',4,'Pájaros en pec deck inverso','Hombros',3,12,20,75,'1'),
(5,'Pull · Hipertrofia de tracción',5,'Curl inclinado mancuernas','Bíceps',3,10,12,90,'1'),
(5,'Pull · Hipertrofia de tracción',6,'Curl martillo','Bíceps',2,10,15,75,'1'),
(6,'Legs · Hipertrofia de piernas',1,'Prensa de piernas','Piernas',2,8,12,180,'1–2'),
(6,'Legs · Hipertrofia de piernas',2,'Curl femoral acostado','Piernas',3,10,15,90,'1–2'),
(6,'Legs · Hipertrofia de piernas',3,'Sentadilla búlgara mancuernas','Piernas',2,8,12,120,'1–2'),
(6,'Legs · Hipertrofia de piernas',4,'Hip thrust en máquina','Glúteos',2,8,12,120,'1–2'),
(6,'Legs · Hipertrofia de piernas',5,'Extensiones cuádriceps','Piernas',3,12,15,90,'1'),
(6,'Legs · Hipertrofia de piernas',6,'Gemelo sentado','Pantorrillas',3,12,20,75,'1–2'),
(6,'Legs · Hipertrofia de piernas',7,'Abducción de cadera en máquina','Glúteos',2,12,20,75,'1–2'),
(6,'Legs · Hipertrofia de piernas',8,'Crunch en polea','Abdomen',2,10,15,60,'1–2');
DO $$
DECLARE rid uuid; did uuid; eid uuid; d record; e record;
BEGIN
 SELECT id INTO rid FROM public.routines WHERE name='Recomposición corporal · ULPPL 5 días · 12 semanas' AND creator_id IS NULL LIMIT 1;
 IF rid IS NULL THEN
  INSERT INTO public.routines(name,creator_id,is_public)
  VALUES ('Recomposición corporal · ULPPL 5 días · 12 semanas',NULL,true) RETURNING id INTO rid;
 ELSIF NOT EXISTS (SELECT 1 FROM public.routines WHERE id=rid AND is_public=true) THEN
  RAISE EXCEPTION 'La rutina existente no es pública';
 END IF;
 FOR d IN SELECT DISTINCT day_of_week,day_name FROM plan_import ORDER BY day_of_week LOOP
  SELECT id INTO did FROM public.routine_days WHERE routine_id=rid AND day_of_week=d.day_of_week ORDER BY id LIMIT 1;
  IF did IS NULL THEN
   INSERT INTO public.routine_days(routine_id,day_of_week,name) VALUES(rid,d.day_of_week,d.day_name) RETURNING id INTO did;
  END IF;
  -- Fuera lo que ya no está en el plan (comparación por nombre del ejercicio).
  DELETE FROM public.routine_exercises re USING public.exercises x
  WHERE re.routine_day_id=did AND x.id=re.exercise_id
    AND NOT EXISTS (SELECT 1 FROM plan_import p WHERE p.day_of_week=d.day_of_week AND lower(p.exercise_name)=lower(x.name));
  FOR e IN SELECT * FROM plan_import WHERE day_of_week=d.day_of_week ORDER BY exercise_order LOOP
   UPDATE public.routine_exercises re SET "order"=e.exercise_order,target_sets=e.sets,target_reps=e.reps_min,target_reps_max=e.reps_max,rest_timer_seconds=e.rest_seconds
   FROM public.exercises x
   WHERE re.routine_day_id=did AND x.id=re.exercise_id AND lower(x.name)=lower(e.exercise_name);
   IF NOT FOUND THEN
    SELECT id INTO eid FROM public.exercises WHERE lower(name)=lower(e.exercise_name) ORDER BY id LIMIT 1;
    IF eid IS NULL THEN
     INSERT INTO public.exercises(name,muscle_group,description)
     VALUES(e.exercise_name,e.muscle_group,'Mantener técnica controlada y ajustar la carga al objetivo de repeticiones.') RETURNING id INTO eid;
    END IF;
    INSERT INTO public.routine_exercises(routine_day_id,exercise_id,"order",target_sets,target_reps,target_reps_max,target_weight,rest_timer_seconds)
    VALUES(did,eid,e.exercise_order,e.sets,e.reps_min,e.reps_max,0,e.rest_seconds);
   END IF;
  END LOOP;
 END LOOP;
END $$;
DO $$
DECLARE rid uuid; total_exercises int; total_sets int; total_days int;
BEGIN
 SELECT id INTO STRICT rid FROM public.routines WHERE name='Recomposición corporal · ULPPL 5 días · 12 semanas' AND creator_id IS NULL;
 SELECT count(DISTINCT d.id),count(re.id),sum(re.target_sets) INTO total_days,total_exercises,total_sets
 FROM public.routine_days d JOIN public.routine_exercises re ON re.routine_day_id=d.id WHERE d.routine_id=rid;
 IF (total_days,total_exercises,total_sets) IS DISTINCT FROM (5,35,88) THEN
 RAISE EXCEPTION 'Plan inesperado: % días, % ejercicios, % series',total_days,total_exercises,total_sets; END IF;
END $$;
COMMIT;
SELECT r.id,r.name,r.is_public,d.day_of_week,d.name AS day_name,count(re.id) AS exercises,sum(re.target_sets) AS sets
FROM public.routines r JOIN public.routine_days d ON d.routine_id=r.id JOIN public.routine_exercises re ON re.routine_day_id=d.id
WHERE r.name='Recomposición corporal · ULPPL 5 días · 12 semanas' AND r.creator_id IS NULL
GROUP BY r.id,d.id ORDER BY d.day_of_week;
