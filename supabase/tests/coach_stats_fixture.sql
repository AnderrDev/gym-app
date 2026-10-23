-- Datos previos a las migraciones del coach v2, para probar el backfill.
-- Ejecutar sólo en un PostgreSQL desechable. Orden completo en coach_stats.sql.
create role service_role;
alter table exercises add column equipment text;
insert into exercises(id,name,muscle_group,equipment) values
 ('00000000-0000-0000-0000-0000000000e1','Press banca barra','Pecho','Barra olímpica + banco plano'),
 ('00000000-0000-0000-0000-0000000000e2','Prensa de piernas','Piernas',null),
 ('00000000-0000-0000-0000-0000000000e3','Plancha RKC','Abdomen','Peso corporal'),
 ('00000000-0000-0000-0000-0000000000e4','Curl martillo','Bíceps','Mancuernas'),
 ('00000000-0000-0000-0000-0000000000e5','Hack squat','Pierna','Máquina hack squat');
insert into routine_exercises(id,routine_day_id,exercise_id,target_sets,target_reps,target_weight,rest_timer_seconds) values
 ('00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-0000000000e1',3,8,60,120);

-- Usuario 1: dos sesiones viejas (sin snapshot) del mismo ejercicio.
insert into workout_sessions(id,user_id,routine_day_id,session_date) values
 ('00000000-0000-0000-0000-0000000000c1','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1','2026-10-01'),
 ('00000000-0000-0000-0000-0000000000c2','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1','2026-10-05'),
 ('00000000-0000-0000-0000-0000000000c9','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000d1','2026-10-02');
insert into set_logs(id,session_id,exercise_id,set_index,actual_weight,actual_reps) values
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c1','00000000-0000-0000-0000-0000000000e1',1,60,8),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c1','00000000-0000-0000-0000-0000000000e1',2,60,8),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c1','00000000-0000-0000-0000-0000000000e1',3,60,7),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c2','00000000-0000-0000-0000-0000000000e1',1,62.5,8),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c2','00000000-0000-0000-0000-0000000000e1',2,62.5,8),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c2','00000000-0000-0000-0000-0000000000e1',3,62.5,8),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c9','00000000-0000-0000-0000-0000000000e1',1,40,10);
-- c1 guarda el formato viejo de cliente (frase y código invertidos, camelCase).
update workout_sessions set completed_at='2026-10-01 19:00+00',
 coaching_analysis='[{"exerciseId":"00000000-0000-0000-0000-0000000000e1","recommendation":"Sigue así","feedback":"MAINTAIN"}]'
 where id='00000000-0000-0000-0000-0000000000c1';
update workout_sessions set completed_at='2026-10-05 19:00+00',
 coaching_analysis='[{"exercise_id":"00000000-0000-0000-0000-0000000000e1","recommendation":"INCREASE_WEIGHT","performance_score":1.05},{"exercise_id":"no-uuid","recommendation":"MAINTAIN"}]'
 where id='00000000-0000-0000-0000-0000000000c2';
update workout_sessions set completed_at='2026-10-02 19:00+00', coaching_analysis='[]'
 where id='00000000-0000-0000-0000-0000000000c9';
