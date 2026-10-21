-- Contrato de `guard_session_completion_v1` (20261021130000_guard_session_completion_columns.sql).
-- Ejecutar sólo en un PostgreSQL desechable. Orden:
-- session_exercises_fixture.sql → 20261015144656_session_exercises.sql →
-- 20261021130000_guard_session_completion_columns.sql → este fichero.
begin;
create role service_role;
grant select, insert, update on workout_sessions to authenticated, anon, service_role;
insert into workout_sessions(id,user_id,routine_day_id,session_date) values
 ('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000031',now()),
 ('00000000-0000-0000-0000-000000000042','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000031',now());
update workout_sessions set completed_at=now(), coaching_analysis='[]' where id='00000000-0000-0000-0000-000000000042';

-- Cliente (authenticated): ni cerrar, ni forjar coaching, ni reabrir.
set local role authenticated;
do $$ begin
 begin update workout_sessions set completed_at=now() where id='00000000-0000-0000-0000-000000000041'; raise exception 'client close accepted'; exception when insufficient_privilege then null; end;
 begin update workout_sessions set coaching_analysis='[{"forged":true}]' where id='00000000-0000-0000-0000-000000000041'; raise exception 'client coaching accepted'; exception when insufficient_privilege then null; end;
 begin update workout_sessions set completed_at=null where id='00000000-0000-0000-0000-000000000042'; raise exception 'client reopen accepted'; exception when insufficient_privilege then null; end;
 begin update workout_sessions set coaching_analysis=null where id='00000000-0000-0000-0000-000000000042'; raise exception 'client coaching wipe accepted'; exception when insufficient_privilege then null; end;
 begin insert into workout_sessions(id,user_id,routine_day_id,session_date,completed_at) values ('00000000-0000-0000-0000-000000000043','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000031',now(),now()); raise exception 'client closed insert accepted'; exception when insufficient_privilege then null; end;
 begin insert into workout_sessions(id,user_id,routine_day_id,session_date,coaching_analysis) values ('00000000-0000-0000-0000-000000000043','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000031',now(),'[]'); raise exception 'client coaching insert accepted'; exception when insufficient_privilege then null; end;

 -- Lo que el cliente sí hace: insertar la sesión abierta. Y tocar otras columnas sigue permitido.
 insert into workout_sessions(id,user_id,routine_day_id,session_date) values ('00000000-0000-0000-0000-000000000044','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000031',now());
 update workout_sessions set session_date=now() where id='00000000-0000-0000-0000-000000000041';
 -- Reescribir el mismo valor no es un cambio.
 update workout_sessions set completed_at=completed_at, coaching_analysis=coaching_analysis where id='00000000-0000-0000-0000-000000000042';
end $$;
reset role;

-- anon tampoco.
set local role anon;
do $$ begin
 begin update workout_sessions set completed_at=now() where id='00000000-0000-0000-0000-000000000041'; raise exception 'anon close accepted'; exception when insufficient_privilege then null; end;
end $$;
reset role;

-- La Edge Function (service_role) cierra y guarda el coaching.
set local role service_role;
update workout_sessions set completed_at=now(), coaching_analysis='[{"exercise_id":"x"}]'
 where id='00000000-0000-0000-0000-000000000041' and completed_at is null;
reset role;
do $$ begin
 if not exists(select 1 from workout_sessions where id='00000000-0000-0000-0000-000000000041' and completed_at is not null and coaching_analysis is not null) then
   raise exception 'service_role finalize blocked';
 end if;
 if exists(select 1 from workout_sessions where id='00000000-0000-0000-0000-000000000042' and completed_at is null) then
   raise exception 'closed session reopened';
 end if;
end $$;
rollback;
