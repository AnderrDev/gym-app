-- Run as postgres in the correct project's SQL editor AFTER the migration.
-- No signup/email/network calls. Every fixture is rolled back, including auth user.
BEGIN;
CREATE TEMP TABLE session_exercise_smoke_ids AS
SELECT gen_random_uuid() uid, gen_random_uuid() routine_id, gen_random_uuid() day_id,
 gen_random_uuid() session_id, gen_random_uuid() other_uid,
 (SELECT array_agg(id ORDER BY id) FROM (SELECT id FROM public.exercises ORDER BY id LIMIT 3) e) exercises;
GRANT SELECT ON session_exercise_smoke_ids TO authenticated;
DO $$ DECLARE f record; BEGIN
 SELECT * INTO f FROM session_exercise_smoke_ids;
 IF cardinality(f.exercises)<3 OR f.exercises IS NULL THEN RAISE EXCEPTION 'Need 3 existing catalog exercises'; END IF;
 INSERT INTO auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
 VALUES(f.uid,'authenticated','authenticated','qa+'||f.uid||'@example.invalid','{"provider":"email","providers":["email"]}',jsonb_build_object('full_name','Session exercises rollback QA'),now(),now());
 INSERT INTO public.profiles(id,full_name) VALUES(f.uid,'Session exercises rollback QA') ON CONFLICT(id) DO NOTHING;
 INSERT INTO public.routines(id,name,creator_id,is_public) VALUES(f.routine_id,'Rollback session QA',f.uid,false);
 INSERT INTO public.routine_days(id,routine_id,day_of_week,name) VALUES(f.day_id,f.routine_id,1,'Rollback QA');
 INSERT INTO public.routine_exercises(id,routine_day_id,exercise_id,"order",target_sets,target_reps,target_weight,rest_timer_seconds)
 VALUES(gen_random_uuid(),f.day_id,f.exercises[1],1,3,10,20,90);
 INSERT INTO public.workout_sessions(id,user_id,routine_day_id,session_date) VALUES(f.session_id,f.uid,f.day_id,current_date);
 PERFORM set_config('request.jwt.claim.sub',f.uid::text,true);
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',f.uid,'role','authenticated')::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$ DECLARE f record; p jsonb; n int; c record; BEGIN
 SELECT * INTO f FROM session_exercise_smoke_ids;
 p:=public.get_session_exercises_v1(f.session_id);
 IF jsonb_array_length(p)<>1 OR (p->0->>'target_sets')::int<>3 THEN RAISE EXCEPTION 'initial snapshot'; END IF;
 INSERT INTO public.set_logs(id,session_id,exercise_id,set_index,actual_weight,actual_reps)
 VALUES(gen_random_uuid(),f.session_id,f.exercises[1],1,20,10);
 p:=public.adapt_session_exercise_v1(f.session_id,f.exercises[2],2,8,15,f.exercises[1]);
 IF jsonb_array_length(p)<>2 OR (p->0->>'target_sets')::int<>1 THEN RAISE EXCEPTION 'partial replacement'; END IF;
 p:=public.adapt_session_exercise_v1(f.session_id,f.exercises[3],1,12,10);
 INSERT INTO public.set_logs(id,session_id,exercise_id,set_index,actual_weight,actual_reps)
 SELECT gen_random_uuid(),f.session_id,f.exercises[3],i,10,12 FROM generate_series(1,5) i;
 SELECT count(*) INTO n FROM public.set_logs WHERE session_id=f.session_id;
 IF n<>6 THEN RAISE EXCEPTION 'raw logs lost'; END IF;
 SELECT * INTO c FROM public.view_workout_sessions_summary WHERE id=f.session_id;
 IF c.total_target_sets<>4 OR c.total_completed_sets<>2 OR c.is_strictly_completed THEN RAISE EXCEPTION 'completion cap'; END IF;
 p:=public.update_session_exercise_target_v1(f.session_id,f.exercises[2],17,9);
 IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_coaching_inputs_v1(f.uid,f.session_id)->'routine_exercises') x WHERE x->>'exercise_id'=f.exercises[2]::text AND (x->>'target_weight')::numeric=17) THEN RAISE EXCEPTION 'coaching targets'; END IF;
 BEGIN DELETE FROM public.set_logs WHERE session_id=f.session_id AND exercise_id=f.exercises[1]; RAISE EXCEPTION 'retained delete accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
 BEGIN PERFORM public.adapt_session_exercise_v1(f.session_id,f.exercises[2],2,8,15); RAISE EXCEPTION 'duplicate accepted'; EXCEPTION WHEN unique_violation THEN NULL; END;
END $$;
RESET ROLE;
-- Change the routine after initialization; the session must retain its copy.
UPDATE public.routine_exercises SET target_sets=99 WHERE routine_day_id=(SELECT day_id FROM session_exercise_smoke_ids);
SET LOCAL ROLE authenticated;
DO $$ DECLARE f record; BEGIN
 SELECT * INTO f FROM session_exercise_smoke_ids;
 IF (public.get_session_exercises_v1(f.session_id)->0->>'target_sets')::int<>1 THEN RAISE EXCEPTION 'snapshot changed with routine'; END IF;
 PERFORM set_config('request.jwt.claim.sub',f.other_uid::text,true);
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',f.other_uid,'role','authenticated')::text,true);
 BEGIN PERFORM public.get_session_exercises_v1(f.session_id); RAISE EXCEPTION 'ownership bypass'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 PERFORM set_config('request.jwt.claim.sub',f.uid::text,true);
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',f.uid,'role','authenticated')::text,true);
 UPDATE public.workout_sessions SET completed_at=now() WHERE id=f.session_id;
 BEGIN PERFORM public.update_session_exercise_target_v1(f.session_id,f.exercises[2],20,10); RAISE EXCEPTION 'closed target accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
 BEGIN INSERT INTO public.set_logs(id,session_id,exercise_id,set_index,actual_weight,actual_reps) VALUES(gen_random_uuid(),f.session_id,f.exercises[2],1,20,10); RAISE EXCEPTION 'closed log accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
END $$;
RESET ROLE;
ROLLBACK;
SELECT 'session exercise live rollback smoke PASS' AS result;
