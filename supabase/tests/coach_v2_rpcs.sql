-- Contrato de get_coaching_inputs_v2 y get_next_targets_v1 (20261022232000).
-- Ejecutar sólo en un PostgreSQL desechable, tras coach_stats_fixture.sql y
-- las migraciones del coach (ver scripts/run_coach_sql_tests.sh).
\set ON_ERROR_STOP on
begin;
create function pg_temp.check(ok boolean, what text) returns void language plpgsql as $$
begin if ok is not true then raise exception 'FALLA: %', what; end if; end $$;

-- Sesión abierta con snapshot (rango 8–10) y una serie.
insert into workout_sessions(id,user_id,routine_day_id,session_date,exercise_plan) values
 ('00000000-0000-0000-0000-0000000000c6','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1','2026-10-09',
  '[{"id":"00000000-0000-0000-0000-0000000000e1","target_sets":3,"target_reps":8,"target_reps_max":10,"target_weight":62.5},
    {"id":"00000000-0000-0000-0000-0000000000e4","target_sets":0,"target_reps":10,"target_weight":12}]');
insert into set_logs(id,session_id,exercise_id,set_index,actual_weight,actual_reps) values
 (gen_random_uuid(),'00000000-0000-0000-0000-0000000000c6','00000000-0000-0000-0000-0000000000e1',1,62.5,9);

-- Sugerencias v2 ya registradas: una reciente y otra con pausa de 30 días.
insert into workout_sessions(id,user_id,routine_day_id,session_date,completed_at) values
 ('00000000-0000-0000-0000-0000000000c7','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1',current_date-3,now()),
 ('00000000-0000-0000-0000-0000000000c8','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000d1',current_date-30,now()),
 ('00000000-0000-0000-0000-0000000000ca','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000d1',current_date-1,now());
insert into coaching_events(session_id,user_id,exercise_id,engine_version,recommendation,reason_code,suggested_weight,suggested_reps) values
 ('00000000-0000-0000-0000-0000000000c7','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000e1','2.0','INCREASE_WEIGHT','DOUBLE_PROGRESSION_TOP',65,8),
 ('00000000-0000-0000-0000-0000000000c7','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000e1','1.0','MAINTAIN',null,null,null),
 ('00000000-0000-0000-0000-0000000000c8','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000e2','2.0','INCREASE_REPS','IN_RANGE_ADD_REPS',100,11),
 ('00000000-0000-0000-0000-0000000000ca','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000e4','2.0','MAINTAIN','FIRST_MISS',14,10);

grant select on workout_sessions, set_logs, routine_exercises, exercises to authenticated;
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-0000-0000-000000000001';

-- Entradas v2.
create temp table i as select public.get_coaching_inputs_v2('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c6') j;
select pg_temp.check((select jsonb_array_length(j->'targets') from i)=1,'sustituidos fuera');
select pg_temp.check((select (j->'targets'->0->>'target_reps_max')::int from i)=10,'rango en objetivos');
select pg_temp.check((select jsonb_array_length(j->'current_logs') from i)=1,'series de la sesión');
select pg_temp.check((select (j->'catalog'->0->>'load_increment_kg')::numeric from i)=2.5,'catálogo');
select pg_temp.check((select j->'catalog'->0->>'name' from i)='Press banca barra','nombre en el catálogo');
select pg_temp.check((select jsonb_array_length(j->'history') from i)=2,'historial (c1, c2; c6 abierta no cuenta)');
select pg_temp.check((select j->'history'->0->>'session_date' from i)='2026-10-05','más reciente primero');
do $$ begin
 perform public.get_coaching_inputs_v2('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000c6');
 raise exception 'aceptó otro usuario';
exception when insufficient_privilege then null; end $$;

-- Sugerencias.
create temp table n as select * from public.get_next_targets_v1(array[
 '00000000-0000-0000-0000-0000000000e1','00000000-0000-0000-0000-0000000000e2','00000000-0000-0000-0000-0000000000e4']::uuid[]);
select pg_temp.check((select count(*) from n)=2,'solo lo del usuario y con peso');
select pg_temp.check((select (suggested_weight,suggested_reps,reason_code,layoff_adjusted) is not distinct from (65::numeric,8,'DOUBLE_PROGRESSION_TOP',false)
  from n where exercise_id='00000000-0000-0000-0000-0000000000e1'),'sugerencia reciente intacta');
-- 30 días de pausa: 100 × 0,85 = 85, redondeado al incremento de la prensa (5).
select pg_temp.check((select (suggested_weight,days_since,layoff_adjusted) is not distinct from (85::numeric,30,true)
  from n where exercise_id='00000000-0000-0000-0000-0000000000e2'),'ajuste por pausa');
reset role;

select 'coach_v2_rpcs OK';
rollback;
