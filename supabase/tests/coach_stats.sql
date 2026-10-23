-- Contrato del coach v2, fase 1 (20261022130000 + 20261022140000).
-- Ejecutar sólo en un PostgreSQL desechable. Orden:
-- session_exercises_fixture.sql → 20261015144656_session_exercises.sql →
-- coach_stats_fixture.sql → 20261022130000_coach_catalog_and_rep_range.sql →
-- 20261022140000_coach_stats_and_events.sql → este fichero.
-- (scripts/run_coach_sql_tests.sh lo hace en un clúster temporal.)
\set ON_ERROR_STOP on
begin;

create function pg_temp.check(ok boolean, what text) returns void language plpgsql as $$
begin if ok is not true then raise exception 'FALLA: %', what; end if; end $$;

-- Catálogo.
select pg_temp.check((select muscle_group from exercises where id='00000000-0000-0000-0000-0000000000e5')='Piernas','grafía normalizada');
select pg_temp.check((select (movement_type,body_region,load_increment_kg) is not distinct from ('compound','upper',2.5) from exercises where id='00000000-0000-0000-0000-0000000000e1'),'press banca');
select pg_temp.check((select (movement_type,body_region,load_increment_kg) is not distinct from ('compound','lower',5) from exercises where id='00000000-0000-0000-0000-0000000000e2'),'prensa');
select pg_temp.check((select movement_type='isolation' and body_region='core' and load_increment_kg is null from exercises where id='00000000-0000-0000-0000-0000000000e3'),'plancha sin carga');
select pg_temp.check((select (movement_type,body_region,load_increment_kg) is not distinct from ('isolation','upper',2) from exercises where id='00000000-0000-0000-0000-0000000000e4'),'curl mancuerna');
select pg_temp.check((select (movement_type,load_increment_kg) is not distinct from ('compound',5) from exercises where id='00000000-0000-0000-0000-0000000000e5'),'hack squat');

-- Backfill: eventos del coaching guardado (el formato viejo se normaliza; el id inválido se descarta).
select pg_temp.check((select recommendation from coaching_events where session_id='00000000-0000-0000-0000-0000000000c1')='MAINTAIN','evento viejo normalizado');
select pg_temp.check((select count(*) from coaching_events where session_id='00000000-0000-0000-0000-0000000000c2')=1,'id inválido descartado');
select pg_temp.check((select performance_score from coaching_events where session_id='00000000-0000-0000-0000-0000000000c2')=1.05,'score');

-- Backfill: métricas en orden y etiqueta de la exposición anterior.
select pg_temp.check((select (exposure_n,prev_session_id,days_since_prev,best_e1rm,rep_dropoff,sets_done,min_reps) is not distinct from (1,null::uuid,null::int,76.00,1,3,7) from exercise_session_stats where session_id='00000000-0000-0000-0000-0000000000c1'),'stats c1');
select pg_temp.check((select (exposure_n,prev_session_id,days_since_prev,best_e1rm,at_range_top) is not distinct from (2,'00000000-0000-0000-0000-0000000000c1'::uuid,4,79.17,true) from exercise_session_stats where session_id='00000000-0000-0000-0000-0000000000c2'),'stats c2');
select pg_temp.check((select (outcome_session_id,hit_target,followed,e1rm_delta) is not distinct from ('00000000-0000-0000-0000-0000000000c2'::uuid,true,null::boolean,3.17) from coaching_events where session_id='00000000-0000-0000-0000-0000000000c1'),'etiqueta c1');
select pg_temp.check((select exposure_n from exercise_session_stats where session_id='00000000-0000-0000-0000-0000000000c9')=1,'otro usuario no cuenta como exposición');

-- Sesión nueva con snapshot y rango 8–10, refrescada por finalize (aún abierta).
insert into workout_sessions(id,user_id,routine_day_id,session_date,exercise_plan) values
 ('00000000-0000-0000-0000-0000000000c3','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1','2026-10-08',
  '[{"id":"00000000-0000-0000-0000-0000000000e1","target_sets":3,"target_reps":8,"target_reps_max":10,"target_weight":62.5}]');
insert into set_logs(id,session_id,exercise_id,set_index,actual_weight,actual_reps) values
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c3','00000000-0000-0000-0000-0000000000e1',1,62.5,10),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c3','00000000-0000-0000-0000-0000000000e1',2,62.5,10),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c3','00000000-0000-0000-0000-0000000000e1',3,62.5,10);
set local role service_role;
select pg_temp.check(public.refresh_exercise_session_stats_v1('00000000-0000-0000-0000-0000000000c3')=1,'refresh c3');
select pg_temp.check(public.refresh_exercise_session_stats_v1('00000000-0000-0000-0000-0000000000c3')=1,'refresh idempotente');
reset role;
select pg_temp.check((select count(*) from exercise_session_stats where session_id='00000000-0000-0000-0000-0000000000c3')=1,'una fila por ejercicio');
select pg_temp.check((select (exposure_n,days_since_prev,at_range_top,target_reps_max,rep_shortfall,rep_dropoff) is not distinct from (3,3,true,10,-2.00,0) from exercise_session_stats where session_id='00000000-0000-0000-0000-0000000000c3'),'stats c3 rango');
select pg_temp.check((select (outcome_session_id,hit_target) is not distinct from ('00000000-0000-0000-0000-0000000000c3'::uuid,true)
  from coaching_events where session_id='00000000-0000-0000-0000-0000000000c2'),'etiqueta c2');

-- Una sugerencia con peso: seguida pero sin llegar a las reps.
insert into coaching_events(session_id,user_id,exercise_id,engine_version,recommendation,suggested_weight) values
 ('00000000-0000-0000-0000-0000000000c3','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000e1','2.0','INCREASE_WEIGHT',65);
insert into workout_sessions(id,user_id,routine_day_id,session_date,exercise_plan) values
 ('00000000-0000-0000-0000-0000000000c4','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1','2026-10-10',
  '[{"id":"00000000-0000-0000-0000-0000000000e1","target_sets":3,"target_reps":8,"target_reps_max":10,"target_weight":65}]');
insert into set_logs(id,session_id,exercise_id,set_index,actual_weight,actual_reps) values
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c4','00000000-0000-0000-0000-0000000000e1',1,65,8),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c4','00000000-0000-0000-0000-0000000000e1',2,65,7),
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c4','00000000-0000-0000-0000-0000000000e1',3,65,6);
update workout_sessions set completed_at='2026-10-08 19:00+00' where id='00000000-0000-0000-0000-0000000000c3';
select public.refresh_exercise_session_stats_v1('00000000-0000-0000-0000-0000000000c4');
select pg_temp.check((select (followed,hit_target) is not distinct from (true,false) from coaching_events
  where session_id='00000000-0000-0000-0000-0000000000c3' and engine_version='2.0'),'sugerencia seguida sin llegar');
select pg_temp.check((select (rep_dropoff,at_range_top,rep_shortfall) is not distinct from (2,false,1.00) from exercise_session_stats
  where session_id='00000000-0000-0000-0000-0000000000c4'),'caída de reps');

-- Snapshot nuevo: lleva el máximo del rango de la rutina.
update routine_exercises set target_reps_max=10 where id='00000000-0000-0000-0000-0000000000a1';
insert into workout_sessions(id,user_id,routine_day_id,session_date) values
 ('00000000-0000-0000-0000-0000000000c5','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1','2026-10-12');
grant select, update on workout_sessions to authenticated;
grant select on routine_exercises, exercises to authenticated;
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-0000-0000-000000000001';
select pg_temp.check((select (x->>'target_reps_max')::int from jsonb_array_elements(public.get_session_exercises_v1('00000000-0000-0000-0000-0000000000c5')) x)=10,'snapshot con máximo');

-- Cliente: lee solo lo suyo, no escribe ni recalcula.
select pg_temp.check((select count(distinct user_id) from exercise_session_stats)=1,'RLS stats');
select pg_temp.check((select count(*) from coaching_events where user_id<>'00000000-0000-0000-0000-000000000001')=0,'RLS eventos');
do $$ begin
 begin insert into coaching_events(session_id,user_id,exercise_id,engine_version,recommendation)
   values ('00000000-0000-0000-0000-0000000000c5','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000e1','x','MAINTAIN');
   raise exception 'cliente insertó evento'; exception when insufficient_privilege then null; end;
 begin delete from exercise_session_stats; raise exception 'cliente borró stats'; exception when insufficient_privilege then null; end;
 begin perform public.refresh_exercise_session_stats_v1('00000000-0000-0000-0000-0000000000c1');
   raise exception 'cliente recalculó'; exception when insufficient_privilege then null; end;
end $$;
reset role;

-- Borrar la sesión arrastra sus métricas y eventos; la etiqueta que apuntaba a ella se limpia.
delete from set_logs where session_id='00000000-0000-0000-0000-0000000000c4';
delete from workout_sessions where id='00000000-0000-0000-0000-0000000000c4';
select pg_temp.check((select outcome_session_id is null from coaching_events
  where session_id='00000000-0000-0000-0000-0000000000c3' and engine_version='2.0'),'outcome a null');

select 'coach_stats OK';
rollback;
