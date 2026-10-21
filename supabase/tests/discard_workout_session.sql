-- Contrato de `discard_workout_session_v1` (20261021120000_fix_discard_session_with_replaced_exercise.sql).
-- Ejecutar sólo en un PostgreSQL desechable. Orden:
-- session_exercises_fixture.sql → 20261015144656_session_exercises.sql →
-- 20261020120000_add_discard_workout_session_rpc.sql →
-- 20261021120000_fix_discard_session_with_replaced_exercise.sql → este fichero.
begin;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001', true);
insert into exercises values ('00000000-0000-0000-0000-000000000011','Original','Pecho'),('00000000-0000-0000-0000-000000000012','Sustituto','Pecho');
insert into routine_exercises values ('00000000-0000-0000-0000-000000000021','00000000-0000-0000-0000-000000000031','00000000-0000-0000-0000-000000000011',3,10,20,90);
insert into workout_sessions(id,user_id,routine_day_id,session_date) values
 ('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000031',now()),
 ('00000000-0000-0000-0000-000000000042','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000031',now()),
 ('00000000-0000-0000-0000-000000000043','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000031',now());

do $$ declare p jsonb; ok boolean; n int; begin
 -- Permisos: sólo authenticated.
 if has_function_privilege('anon','public.discard_workout_session_v1(uuid)','execute') then raise exception 'anon can execute'; end if;
 if not has_function_privilege('authenticated','public.discard_workout_session_v1(uuid)','execute') then raise exception 'authenticated cannot execute'; end if;

 -- Sesión abierta con plan; se registran series del original y LUEGO se sustituye.
 perform get_session_exercises_v1('00000000-0000-0000-0000-000000000041');
 insert into set_logs values
  ('00000000-0000-0000-0000-000000000051','00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000011',1,20,10),
  ('00000000-0000-0000-0000-000000000052','00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000011',2,20,10);
 p := adapt_session_exercise_v1('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000012',1,8,15,'00000000-0000-0000-0000-000000000011');
 if p->0->>'replaced_by_exercise_name' <> 'Sustituto' then raise exception 'fixture: original not replaced'; end if;
 insert into set_logs values ('00000000-0000-0000-0000-000000000053','00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000012',1,15,8);

 -- Precondición: un DELETE ingenuo choca con el trigger (el bug B1).
 begin delete from set_logs where session_id='00000000-0000-0000-0000-000000000041'; raise exception 'naive delete accepted'; exception when check_violation then null; end;

 -- Ajena → P0002 sin borrar nada.
 begin perform discard_workout_session_v1('00000000-0000-0000-0000-000000000043'); raise exception 'foreign session discarded'; exception when no_data_found then null; end;
 if not exists(select 1 from workout_sessions where id='00000000-0000-0000-0000-000000000043') then raise exception 'foreign session deleted'; end if;

 ok := discard_workout_session_v1('00000000-0000-0000-0000-000000000041');
 if ok is distinct from true then raise exception 'discard returned %', ok; end if;
 select count(*) into n from set_logs where session_id='00000000-0000-0000-0000-000000000041'; if n<>0 then raise exception 'set_logs kept: %', n; end if;
 if exists(select 1 from workout_sessions where id='00000000-0000-0000-0000-000000000041') then raise exception 'session kept'; end if;

 -- Idempotente: ya no existe → false.
 ok := discard_workout_session_v1('00000000-0000-0000-0000-000000000041');
 if ok is distinct from false then raise exception 'retry returned %', ok; end if;

 -- Cerrada → 23514 y sigue intacta.
 update workout_sessions set completed_at=now() where id='00000000-0000-0000-0000-000000000042';
 begin perform discard_workout_session_v1('00000000-0000-0000-0000-000000000042'); raise exception 'closed session discarded'; exception when check_violation then null; end;
 if not exists(select 1 from workout_sessions where id='00000000-0000-0000-0000-000000000042') then raise exception 'closed session deleted'; end if;

 -- Sin usuario → 42501.
 perform set_config('request.jwt.claim.sub','',true);
 begin perform discard_workout_session_v1('00000000-0000-0000-0000-000000000042'); raise exception 'anonymous discard accepted'; exception when insufficient_privilege then null; end;
end $$;
rollback;
