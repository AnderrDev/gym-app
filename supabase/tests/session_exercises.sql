-- Run in a disposable database or wrap fixtures in this rollback-only transaction.
begin;
-- Fixture captures the view before applying migration, in this same connection.
do $$ begin
 if to_regclass('pg_temp.session_summary_projection_before') is not null then
  if exists((select attnum,attname,atttypid,atttypmod from pg_attribute where attrelid='public.view_workout_sessions_summary'::regclass and attnum>0 and not attisdropped except select * from session_summary_projection_before)
   union all (select * from session_summary_projection_before except select attnum,attname,atttypid,atttypmod from pg_attribute where attrelid='public.view_workout_sessions_summary'::regclass and attnum>0 and not attisdropped)) then raise exception 'view projection changed'; end if;
 end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001', true);
insert into exercises values ('00000000-0000-0000-0000-000000000011','Original','Pecho'),('00000000-0000-0000-0000-000000000012','Sustituto','Pecho'),('00000000-0000-0000-0000-000000000013','Extra','Pierna');
insert into routine_exercises values ('00000000-0000-0000-0000-000000000021','00000000-0000-0000-0000-000000000031','00000000-0000-0000-0000-000000000011',3,10,20,90);
insert into workout_sessions(id,user_id,routine_day_id,session_date) values ('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000031',now());
do $$ declare p jsonb; n int; begin
 if to_regprocedure('public.get_session_exercises_v1(uuid)') is null then raise exception 'contract: session exercises RPC missing'; end if;
 p := get_session_exercises_v1('00000000-0000-0000-0000-000000000041');
 if jsonb_array_length(p) <> 1 then raise exception 'snapshot count'; end if;
 update routine_exercises set target_sets=99;
 if get_session_exercises_v1('00000000-0000-0000-0000-000000000041') <> p then raise exception 'snapshot changed'; end if;
 insert into set_logs values ('00000000-0000-0000-0000-000000000051','00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000011',1,20,10);
 p := adapt_session_exercise_v1('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000012',2,8,15,'00000000-0000-0000-0000-000000000011');
 if jsonb_array_length(p)<>2 or (p->0->>'target_sets')::int<>1 then raise exception 'partial replacement'; end if;
 select count(*) into n from set_logs; if n<>1 then raise exception 'logs lost'; end if;
 begin perform adapt_session_exercise_v1('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000012',2,8,15); raise exception 'duplicate accepted'; exception when unique_violation then null; end;
 p := adapt_session_exercise_v1('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000013',1,8,15);
 p := update_session_exercise_target_v1('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000012',17,12);
 if (p->1->>'target_weight')::numeric<>17 then raise exception 'target update'; end if;
 insert into set_logs select md5(i::text)::uuid,'00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000013',i,15,8 from generate_series(1,5) i;
 select total_completed_sets into n from view_workout_sessions_summary; if n<>2 then raise exception 'extras masked missing exercise: %', n; end if;
 if (get_coaching_inputs_v1(auth.uid(),'00000000-0000-0000-0000-000000000041')->'routine_exercises'->1->>'target_weight')::numeric <> 17 then raise exception 'coaching targets'; end if;
 perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
 begin perform get_session_exercises_v1('00000000-0000-0000-0000-000000000041'); raise exception 'ownership bypass'; exception when insufficient_privilege then null; end;
 perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
 update workout_sessions set completed_at=now();
 begin perform update_session_exercise_target_v1('00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000012',20,8); raise exception 'closed session mutated'; exception when check_violation then null; end;
end $$;
-- Edge cases are independent of the partially replaced session above.
insert into workout_sessions(id,user_id,routine_day_id,session_date) values
 ('00000000-0000-0000-0000-000000000042',auth.uid(),'00000000-0000-0000-0000-000000000031',now());
do $$ declare p jsonb; v numeric; begin
 p := adapt_session_exercise_v1('00000000-0000-0000-0000-000000000042','00000000-0000-0000-0000-000000000012',2,8,15,'00000000-0000-0000-0000-000000000011');
 if (p->0->>'target_sets')::int<>0 or p->0->>'replaced_by_exercise_name'<>'Sustituto' then raise exception 'zero-log original lost'; end if;
 if exists(select 1 from jsonb_array_elements(get_coaching_inputs_v1(auth.uid(),'00000000-0000-0000-0000-000000000042')->'routine_exercises') x where (x->>'target_sets')::integer=0) then raise exception 'phantom coaching original'; end if;
 begin perform adapt_session_exercise_v1('00000000-0000-0000-0000-000000000042','00000000-0000-0000-0000-000000000013',1,8,15,'00000000-0000-0000-0000-000000000011'); raise exception 'fully replaced original reused'; exception when check_violation then null; end;
 foreach v in array array['NaN'::numeric,'Infinity'::numeric,'-Infinity'::numeric,-1,10001] loop
 begin perform adapt_session_exercise_v1('00000000-0000-0000-0000-000000000042','00000000-0000-0000-0000-000000000013',1,8,v); raise exception 'invalid weight accepted'; exception when check_violation then null; end;
 end loop;
 begin perform adapt_session_exercise_v1('00000000-0000-0000-0000-000000000042','00000000-0000-0000-0000-000000000013',0,8,0); raise exception 'zero target accepted'; exception when check_violation then null; end;
 begin perform update_session_exercise_target_v1('00000000-0000-0000-0000-000000000042','00000000-0000-0000-0000-000000000012',0,1001); raise exception 'invalid reps accepted'; exception when check_violation then null; end;
 update workout_sessions set exercise_plan=null,completed_at=now() where id='00000000-0000-0000-0000-000000000042';
 perform get_session_exercises_v1('00000000-0000-0000-0000-000000000042');
 if (select exercise_plan is not null from workout_sessions where id='00000000-0000-0000-0000-000000000042') then raise exception 'legacy closed read mutated'; end if;
 if has_function_privilege('anon','public.get_session_exercises_v1(uuid)','EXECUTE') then raise exception 'anonymous execute granted'; end if;
end $$;
-- Replacing an added extra retains its extra lineage.
insert into workout_sessions(id,user_id,routine_day_id,session_date) values
 ('00000000-0000-0000-0000-000000000043',auth.uid(),'00000000-0000-0000-0000-000000000031',now());
do $$ declare p jsonb; begin
 perform adapt_session_exercise_v1('00000000-0000-0000-0000-000000000043','00000000-0000-0000-0000-000000000012',2,8,15);
 p := adapt_session_exercise_v1('00000000-0000-0000-0000-000000000043','00000000-0000-0000-0000-000000000013',2,8,15,'00000000-0000-0000-0000-000000000012');
 if (p->2->>'is_extra')::boolean IS DISTINCT FROM true then raise exception 'replacement lost extra lineage'; end if;
end $$;
-- Stale clients cannot mutate retained originals or logs in closed snapshots.
update workout_sessions set completed_at=null where id='00000000-0000-0000-0000-000000000041';
do $$ declare n int; begin
 begin delete from set_logs where id='00000000-0000-0000-0000-000000000051'; raise exception 'stale delete accepted'; exception when check_violation then null; end;
 begin update set_logs set actual_reps=1 where id='00000000-0000-0000-0000-000000000051'; raise exception 'stale update accepted'; exception when check_violation then null; end;
 begin update set_logs set exercise_id='00000000-0000-0000-0000-000000000013' where id='00000000-0000-0000-0000-000000000051'; raise exception 'snapshot identity change accepted'; exception when check_violation then null; end;
 begin insert into set_logs values ('00000000-0000-0000-0000-000000000052','00000000-0000-0000-0000-000000000043','00000000-0000-0000-0000-000000000012',2,15,8); raise exception 'retained insert accepted'; exception when check_violation then null; end;
 begin insert into set_logs values ('00000000-0000-0000-0000-000000000053','00000000-0000-0000-0000-000000000043','00000000-0000-0000-0000-000000000099',1,15,8); raise exception 'unknown exercise accepted'; exception when check_violation then null; end;
 update workout_sessions set completed_at=now() where id='00000000-0000-0000-0000-000000000041';
 begin insert into set_logs values ('00000000-0000-0000-0000-000000000054','00000000-0000-0000-0000-000000000041','00000000-0000-0000-0000-000000000012',1,15,8); raise exception 'closed insert accepted'; exception when check_violation then null; end;
 begin update set_logs set actual_reps=2 where id=md5('1')::uuid; raise exception 'closed update accepted'; exception when check_violation then null; end;
 begin delete from set_logs where id=md5('1')::uuid; raise exception 'closed delete accepted'; exception when check_violation then null; end;
 select count(*) into n from set_logs where id='00000000-0000-0000-0000-000000000051'; if n<>1 then raise exception 'original logs changed'; end if;
end $$;
-- Previous actual exercise performance can come from another routine day.
insert into workout_sessions(id,user_id,routine_day_id,session_date,completed_at) values
 ('00000000-0000-0000-0000-000000000044',auth.uid(),'00000000-0000-0000-0000-000000000032',now()-interval '1 day',now());
insert into set_logs values ('00000000-0000-0000-0000-000000000055','00000000-0000-0000-0000-000000000044','00000000-0000-0000-0000-000000000013',1,37,9);
do $$ begin
 if not exists(select 1 from jsonb_array_elements(get_coaching_inputs_v1(auth.uid(),'00000000-0000-0000-0000-000000000043')->'previous_logs') x where x->>'exercise_id'='00000000-0000-0000-0000-000000000013' and (x->>'actual_weight')::numeric=37) then raise exception 'cross-day actual exercise history missing'; end if;
end $$;
grant update on workout_sessions to authenticated;
grant select on workout_sessions to authenticated;
set local role authenticated;
do $$ begin
 begin update public.workout_sessions set exercise_plan='[]'::jsonb where id='00000000-0000-0000-0000-000000000041'; raise exception 'direct snapshot forgery accepted'; exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
