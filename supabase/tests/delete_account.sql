-- Contrato de `delete_account_data_v1` (20261020130000_delete_account.sql).
-- Ejecutar sólo sobre `delete_account_fixture.sql` en una base desechable o
-- envuelto en esta transacción con rollback.
begin;
-- A = usuario que se borra, B = otro usuario.
insert into auth.users values ('00000000-0000-0000-0000-00000000000a'),('00000000-0000-0000-0000-00000000000b');
insert into profiles values ('00000000-0000-0000-0000-00000000000a','Ana'),('00000000-0000-0000-0000-00000000000b','Beto');
insert into exercises values ('00000000-0000-0000-0000-0000000000e1','Press','Pecho'),('00000000-0000-0000-0000-0000000000e2','Remo','Espalda');
insert into routines values
 ('00000000-0000-0000-0000-0000000000a1','A pública',true,'00000000-0000-0000-0000-00000000000a'),
 ('00000000-0000-0000-0000-0000000000a2','A privada',false,'00000000-0000-0000-0000-00000000000a'),
 ('00000000-0000-0000-0000-0000000000a3','A privada asignada a B',false,'00000000-0000-0000-0000-00000000000a'),
 ('00000000-0000-0000-0000-0000000000b1','B pública',true,'00000000-0000-0000-0000-00000000000b');
insert into routine_days values
 ('00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-0000000000a1',1,'Día A pública'),
 ('00000000-0000-0000-0000-0000000000d2','00000000-0000-0000-0000-0000000000a2',1,'Día A privada'),
 ('00000000-0000-0000-0000-0000000000d3','00000000-0000-0000-0000-0000000000a3',1,'Día A privada asignada'),
 ('00000000-0000-0000-0000-0000000000d4','00000000-0000-0000-0000-0000000000b1',1,'Día B');
insert into routine_exercises(routine_day_id,exercise_id,"order",target_sets,target_reps,target_weight,rest_timer_seconds) values
 ('00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-0000000000e1',0,3,10,20,90),
 ('00000000-0000-0000-0000-0000000000d1','00000000-0000-0000-0000-0000000000e2',1,3,10,20,90),
 ('00000000-0000-0000-0000-0000000000d2','00000000-0000-0000-0000-0000000000e1',0,3,10,20,90),
 ('00000000-0000-0000-0000-0000000000d3','00000000-0000-0000-0000-0000000000e1',0,3,10,20,90),
 ('00000000-0000-0000-0000-0000000000d4','00000000-0000-0000-0000-0000000000e1',0,3,10,20,90);
insert into user_routines values
 ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000000b1'),
 ('00000000-0000-0000-0000-00000000000b','00000000-0000-0000-0000-0000000000a3');
-- Sesión de A con plan (se cierra después de registrar series: así el
-- trigger guard_session_set_log_v1 bloquearía un DELETE ingenuo).
insert into workout_sessions(id,user_id,routine_day_id,session_date,exercise_plan) values
 ('00000000-0000-0000-0000-000000000051','00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000000d1',current_date - 1,
  '[{"id":"00000000-0000-0000-0000-0000000000e1","target_sets":3}]'::jsonb),
 ('00000000-0000-0000-0000-000000000052','00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000000d2',current_date,null),
 ('00000000-0000-0000-0000-000000000053','00000000-0000-0000-0000-00000000000b','00000000-0000-0000-0000-0000000000d1',current_date,null);
insert into set_logs(session_id,exercise_id,set_index,actual_weight,actual_reps) values
 ('00000000-0000-0000-0000-000000000051','00000000-0000-0000-0000-0000000000e1',1,20,10),
 ('00000000-0000-0000-0000-000000000051','00000000-0000-0000-0000-0000000000e1',2,20,10),
 ('00000000-0000-0000-0000-000000000052','00000000-0000-0000-0000-0000000000e1',1,20,10),
 ('00000000-0000-0000-0000-000000000053','00000000-0000-0000-0000-0000000000e1',1,20,10);
update workout_sessions set completed_at = now() where id = '00000000-0000-0000-0000-000000000051';
insert into function_rate_limits values ('00000000-0000-0000-0000-00000000000a','delete_account_v1',now(),1);

do $$
declare r jsonb; again jsonb;
begin
 -- Permisos: sólo service_role.
 if has_function_privilege('authenticated','public.delete_account_data_v1(uuid)','execute') then raise exception 'authenticated can execute'; end if;
 if has_function_privilege('anon','public.delete_account_data_v1(uuid)','execute') then raise exception 'anon can execute'; end if;
 if not has_function_privilege('service_role','public.delete_account_data_v1(uuid)','execute') then raise exception 'service_role cannot execute'; end if;

 -- FK de creator_id pasa a SET NULL y la columna admite NULL.
 if not exists(select 1 from pg_constraint where conrelid='public.routines'::regclass and contype='f' and confdeltype='n') then raise exception 'creator_id FK not SET NULL'; end if;
 if exists(select 1 from information_schema.columns where table_name='routines' and column_name='creator_id' and is_nullable='NO') then raise exception 'creator_id still NOT NULL'; end if;

 r := public.delete_account_data_v1('00000000-0000-0000-0000-00000000000a');
 if r <> '{"set_logs":3,"workout_sessions":2,"user_routines":1,"routines_anonymized":2,"routines_deleted":1,"routine_days_deleted":1,"routine_exercises_deleted":1,"rate_limits":1,"profiles":1}'::jsonb then
   raise exception 'unexpected counts %', r;
 end if;

 if exists(select 1 from profiles where id='00000000-0000-0000-0000-00000000000a') then raise exception 'profile kept'; end if;
 if exists(select 1 from workout_sessions where user_id='00000000-0000-0000-0000-00000000000a') then raise exception 'sessions kept'; end if;
 if exists(select 1 from user_routines where user_id='00000000-0000-0000-0000-00000000000a') then raise exception 'assignment kept'; end if;
 if exists(select 1 from routines where id='00000000-0000-0000-0000-0000000000a2') then raise exception 'private routine kept'; end if;
 if exists(select 1 from routine_days where id='00000000-0000-0000-0000-0000000000d2') then raise exception 'private day kept'; end if;
 -- Pública anonimizada, con días/ejercicios y las series de B intactos.
 if not exists(select 1 from routines where id='00000000-0000-0000-0000-0000000000a1' and creator_id is null and is_public) then raise exception 'public routine not anonymized'; end if;
 if (select count(*) from routine_exercises where routine_day_id='00000000-0000-0000-0000-0000000000d1') <> 2 then raise exception 'public routine exercises lost'; end if;
 if (select count(*) from set_logs where session_id='00000000-0000-0000-0000-000000000053') <> 1 then raise exception 'B logs lost'; end if;
 -- Privada asignada a B: anonimizada, sigue privada.
 if not exists(select 1 from routines where id='00000000-0000-0000-0000-0000000000a3' and creator_id is null and not is_public) then raise exception 'shared private routine not anonymized'; end if;
 if not exists(select 1 from user_routines where user_id='00000000-0000-0000-0000-00000000000b') then raise exception 'B assignment lost'; end if;
 if not exists(select 1 from routines where id='00000000-0000-0000-0000-0000000000b1' and creator_id='00000000-0000-0000-0000-00000000000b') then raise exception 'B routine touched'; end if;

 -- Idempotente.
 again := public.delete_account_data_v1('00000000-0000-0000-0000-00000000000a');
 if exists(select 1 from jsonb_each(again) where value <> '0'::jsonb) then raise exception 'not idempotent %', again; end if;

 -- auth.users ya se puede borrar (lo hace la Admin API en la Edge Function).
 delete from auth.users where id='00000000-0000-0000-0000-00000000000a';
end $$;

-- Nadie puede reordenar una rutina anonimizada.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000000b', true);
do $$ begin
 begin
   perform public.reorder_routine_exercises('00000000-0000-0000-0000-0000000000d1', array['00000000-0000-0000-0000-0000000000e2'::uuid]);
   raise exception 'reorder on anonymized routine allowed';
 exception when insufficient_privilege then null;
 end;
 -- El dueño real sí puede (creator_id, no user_id).
 perform public.reorder_routine_exercises('00000000-0000-0000-0000-0000000000d4', array['00000000-0000-0000-0000-0000000000e1'::uuid]);
end $$;

-- Borrar un usuario directamente (dashboard) también deja de estar bloqueado.
do $$ begin
 delete from workout_sessions where user_id='00000000-0000-0000-0000-00000000000b' and id <> '00000000-0000-0000-0000-000000000053';
 delete from set_logs where session_id='00000000-0000-0000-0000-000000000053';
 delete from auth.users where id='00000000-0000-0000-0000-00000000000b';
 if exists(select 1 from routines where creator_id='00000000-0000-0000-0000-00000000000b') then raise exception 'cascade to routines did not SET NULL'; end if;
 if exists(select 1 from workout_sessions where user_id='00000000-0000-0000-0000-00000000000b') then raise exception 'sessions not cascaded'; end if;
end $$;
rollback;
