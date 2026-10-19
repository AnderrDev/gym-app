-- Carga de datos, sin cambios de esquema ni asignación a usuarios.
-- Rangos completos/RIR: docs/routines/recomposicion-ulppl-12-semanas.md.
BEGIN;
SELECT pg_advisory_xact_lock(hashtext('seed_recomposicion_ulppl_12_semanas_v1'));
CREATE TEMP TABLE plan_import (
 day_of_week int, day_name text, exercise_order int, exercise_name text,
 muscle_group text, sets int, reps_min int, reps_max int, rest_seconds int, rir text
) ON COMMIT DROP;
INSERT INTO plan_import VALUES
(1,'Upper · Fuerza de tren superior',1,'Press banca barra','Pecho',3,5,8,180,'1–2'),
(1,'Upper · Fuerza de tren superior',2,'Jalón al pecho','Espalda',3,6,10,180,'1–2'),
(1,'Upper · Fuerza de tren superior',3,'Remo máquina pecho soportado','Espalda',3,8,10,120,'1–2'),
(1,'Upper · Fuerza de tren superior',4,'Press inclinado mancuernas','Pecho',2,8,12,120,'1–2'),
(1,'Upper · Fuerza de tren superior',5,'Elevación lateral mancuerna','Hombros',2,12,20,90,'1–2'),
(1,'Upper · Fuerza de tren superior',6,'Curl de bíceps con barra EZ','Bíceps',2,8,12,90,'1–2'),
(1,'Upper · Fuerza de tren superior',7,'Extensión tríceps en polea','Tríceps',2,10,15,75,'1–2'),
(2,'Lower · Fuerza de tren inferior',1,'Sentadilla libre','Piernas',3,5,8,180,'1–2'),
(2,'Lower · Fuerza de tren inferior',2,'Peso muerto rumano','Piernas',3,6,10,180,'1–2'),
(2,'Lower · Fuerza de tren inferior',3,'Prensa de piernas','Piernas',2,10,12,120,'1–2'),
(2,'Lower · Fuerza de tren inferior',4,'Curl femoral sentado','Piernas',2,10,15,90,'1–2'),
(2,'Lower · Fuerza de tren inferior',5,'Gemelos de pie','Pantorrillas',3,10,15,75,'1–2'),
(2,'Lower · Fuerza de tren inferior',6,'Crunch en polea','Abdomen',2,12,15,60,'1–2'),
(4,'Push · Hipertrofia de empuje',1,'Press inclinado en máquina','Pecho',3,8,12,120,'1–2'),
(4,'Push · Hipertrofia de empuje',2,'Aperturas en polea','Pecho',2,12,15,90,'1'),
(4,'Push · Hipertrofia de empuje',3,'Press de hombros en máquina','Hombros',2,8,12,120,'1–2'),
(4,'Push · Hipertrofia de empuje',4,'Elevación lateral en polea','Hombros',3,12,20,90,'1'),
(4,'Push · Hipertrofia de empuje',5,'Extensión de tríceps sobre la cabeza en polea','Tríceps',3,10,15,90,'1'),
(4,'Push · Hipertrofia de empuje',6,'Tríceps cuerda','Tríceps',2,12,15,75,'1'),
(5,'Pull · Hipertrofia de tracción',1,'Jalón polea neutro estrecho','Espalda',3,8,12,120,'1–2'),
(5,'Pull · Hipertrofia de tracción',2,'Remo en polea baja','Espalda',3,8,12,120,'1–2'),
(5,'Pull · Hipertrofia de tracción',3,'Pullover polea','Espalda',2,12,15,90,'1–2'),
(5,'Pull · Hipertrofia de tracción',4,'Pájaros en pec deck inverso','Hombros',3,12,20,75,'1'),
(5,'Pull · Hipertrofia de tracción',5,'Curl inclinado mancuernas','Bíceps',3,10,12,90,'1'),
(5,'Pull · Hipertrofia de tracción',6,'Curl martillo','Bíceps',2,10,15,75,'1'),
(6,'Legs · Hipertrofia de piernas',1,'Prensa de piernas','Piernas',3,8,12,180,'1–2'),
(6,'Legs · Hipertrofia de piernas',2,'Curl femoral acostado','Piernas',3,10,15,90,'1–2'),
(6,'Legs · Hipertrofia de piernas',3,'Sentadilla búlgara mancuernas','Piernas',2,8,12,120,'1–2'),
(6,'Legs · Hipertrofia de piernas',4,'Hip thrust en máquina','Glúteos',2,8,12,120,'1–2'),
(6,'Legs · Hipertrofia de piernas',5,'Extensiones cuádriceps','Piernas',2,12,15,90,'1'),
(6,'Legs · Hipertrofia de piernas',6,'Gemelo sentado','Pantorrillas',3,12,20,75,'1–2'),
(6,'Legs · Hipertrofia de piernas',7,'Elevación de piernas','Abdomen',2,10,15,60,'1–2');
DO $$
DECLARE rid uuid; did uuid; eid uuid; d record; e record;
BEGIN
 SELECT id INTO rid FROM public.routines WHERE name='Recomposición corporal · ULPPL 5 días · 12 semanas' AND creator_id IS NULL LIMIT 1;
 IF rid IS NOT NULL THEN
   IF NOT EXISTS (SELECT 1 FROM public.routines WHERE id=rid AND is_public=true)
   THEN RAISE EXCEPTION 'La rutina existente no es pública'; END IF;
   RETURN; -- Nunca sobrescribir progresiones al repetir la carga.
 END IF;
 INSERT INTO public.routines(name,creator_id,is_public)
 VALUES ('Recomposición corporal · ULPPL 5 días · 12 semanas',NULL,true) RETURNING id INTO rid;
 FOR d IN SELECT DISTINCT day_of_week,day_name FROM plan_import ORDER BY day_of_week LOOP
  INSERT INTO public.routine_days(routine_id,day_of_week,name) VALUES(rid,d.day_of_week,d.day_name) RETURNING id INTO did;
  FOR e IN SELECT * FROM plan_import WHERE day_of_week=d.day_of_week ORDER BY exercise_order LOOP
   SELECT id INTO eid FROM public.exercises WHERE lower(name)=lower(e.exercise_name) ORDER BY id LIMIT 1;
   IF eid IS NULL THEN
    INSERT INTO public.exercises(name,muscle_group,description)
    VALUES(e.exercise_name,e.muscle_group,'Mantener técnica controlada y ajustar la carga al objetivo de repeticiones.') RETURNING id INTO eid;
   END IF;
   INSERT INTO public.routine_exercises(routine_day_id,exercise_id,"order",target_sets,target_reps,target_weight,rest_timer_seconds)
   VALUES(did,eid,e.exercise_order,e.sets,e.reps_min,0,e.rest_seconds);
  END LOOP;
 END LOOP;
END $$;
DO $$
DECLARE rid uuid; total_exercises int; total_sets int; total_days int;
BEGIN
 SELECT id INTO STRICT rid FROM public.routines WHERE name='Recomposición corporal · ULPPL 5 días · 12 semanas' AND creator_id IS NULL;
 SELECT count(DISTINCT d.id),count(re.id),sum(re.target_sets) INTO total_days,total_exercises,total_sets
 FROM public.routine_days d JOIN public.routine_exercises re ON re.routine_day_id=d.id WHERE d.routine_id=rid;
 IF (total_days,total_exercises,total_sets) IS DISTINCT FROM (5,32,80) THEN
 RAISE EXCEPTION 'Plan inesperado: % días, % ejercicios, % series',total_days,total_exercises,total_sets; END IF;
END $$;
COMMIT;
SELECT r.id,r.name,r.is_public,d.day_of_week,d.name AS day_name,count(re.id) AS exercises,sum(re.target_sets) AS sets
FROM public.routines r JOIN public.routine_days d ON d.routine_id=r.id JOIN public.routine_exercises re ON re.routine_day_id=d.id
WHERE r.name='Recomposición corporal · ULPPL 5 días · 12 semanas' AND r.creator_id IS NULL
GROUP BY r.id,d.id ORDER BY d.day_of_week;
