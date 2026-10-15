-- Per-session targets; routine definitions and existing closed sessions stay intact.
ALTER TABLE public.workout_sessions ADD COLUMN exercise_plan jsonb
  CHECK (exercise_plan IS NULL OR (jsonb_typeof(exercise_plan) = 'array' AND jsonb_array_length(exercise_plan) <= 100));

CREATE FUNCTION public.get_session_exercises_v1(p_session_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE s public.workout_sessions; plan jsonb;
BEGIN
  SELECT * INTO s FROM public.workout_sessions WHERE id=p_session_id FOR UPDATE;
  IF NOT FOUND OR auth.uid() IS NULL OR s.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden: session ownership' USING ERRCODE='42501';
  END IF;
  IF s.exercise_plan IS NOT NULL THEN RETURN s.exercise_plan; END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id',e.id,'routine_day_id',re.routine_day_id,'name',e.name,'muscle_group',e.muscle_group,
    'target_sets',re.target_sets,'target_reps',re.target_reps,'target_weight',re.target_weight,
    'rest_timer_seconds',coalesce(re.rest_timer_seconds,90),'is_extra',false,
    'replaces_exercise_name',NULL,'replaced_by_exercise_name',NULL) ORDER BY coalesce((to_jsonb(re)->>'order')::integer,0), re.id),'[]'::jsonb)
  INTO plan FROM public.routine_exercises re JOIN public.exercises e ON e.id=re.exercise_id
  WHERE re.routine_day_id=s.routine_day_id;
  IF s.completed_at IS NULL THEN
    IF jsonb_array_length(plan)>100 THEN RAISE EXCEPTION 'too many exercises' USING ERRCODE='23514'; END IF;
    UPDATE public.workout_sessions SET exercise_plan=plan WHERE id=s.id;
  END IF;
  RETURN plan;
END $$;

CREATE FUNCTION public.adapt_session_exercise_v1(p_session_id uuid,p_exercise_id uuid,
 p_target_sets integer,p_target_reps integer,p_target_weight numeric,p_replace_exercise_id uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE s public.workout_sessions; plan jsonb; original jsonb; e public.exercises; done integer;
BEGIN
  -- Shared row lock serializes initialization, additions and target edits.
  plan := public.get_session_exercises_v1(p_session_id);
  SELECT * INTO s FROM public.workout_sessions WHERE id=p_session_id;
  IF s.completed_at IS NOT NULL THEN RAISE EXCEPTION 'session closed' USING ERRCODE='23514'; END IF;
  IF p_target_sets IS NULL OR p_target_sets NOT BETWEEN 1 AND 100 OR
     p_target_reps IS NULL OR p_target_reps NOT BETWEEN 1 AND 1000 OR
     p_target_weight IS NULL OR NOT (p_target_weight BETWEEN 0 AND 10000) THEN
    RAISE EXCEPTION 'invalid exercise targets' USING ERRCODE='23514';
  END IF;
  SELECT * INTO e FROM public.exercises WHERE id=p_exercise_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'exercise not found' USING ERRCODE='23503'; END IF;
  IF EXISTS(SELECT 1 FROM jsonb_array_elements(plan) x WHERE x->>'id'=p_exercise_id::text) THEN
    RAISE EXCEPTION 'exercise already in session' USING ERRCODE='23505';
  END IF;
  IF jsonb_array_length(plan)>=100 THEN RAISE EXCEPTION 'too many exercises' USING ERRCODE='23514'; END IF;
  IF p_replace_exercise_id IS NOT NULL THEN
    SELECT x INTO original FROM jsonb_array_elements(plan) x WHERE x->>'id'=p_replace_exercise_id::text;
    IF original IS NULL THEN RAISE EXCEPTION 'replacement source missing' USING ERRCODE='23503'; END IF;
    SELECT count(*) INTO done FROM public.set_logs WHERE session_id=p_session_id AND exercise_id=p_replace_exercise_id;
    IF done >= (original->>'target_sets')::integer THEN RAISE EXCEPTION 'no remaining sets' USING ERRCODE='23514'; END IF;
    SELECT jsonb_agg(CASE WHEN x->>'id'=p_replace_exercise_id::text THEN
      x || jsonb_build_object('target_sets',done,'replaced_by_exercise_name',e.name) ELSE x END ORDER BY ord)
    INTO plan FROM jsonb_array_elements(plan) WITH ORDINALITY a(x,ord);
  END IF;
  plan := plan || jsonb_build_array(jsonb_build_object('id',e.id,'routine_day_id',s.routine_day_id,
    'name',e.name,'muscle_group',e.muscle_group,'target_sets',p_target_sets,'target_reps',p_target_reps,
    'target_weight',p_target_weight,'rest_timer_seconds',90,'is_extra',CASE WHEN p_replace_exercise_id IS NULL THEN true ELSE coalesce((original->>'is_extra')::boolean,false) END,
    'replaces_exercise_name',original->>'name','replaced_by_exercise_name',NULL));
  UPDATE public.workout_sessions SET exercise_plan=plan WHERE id=p_session_id;
  RETURN plan;
END $$;

CREATE FUNCTION public.update_session_exercise_target_v1(p_session_id uuid,p_exercise_id uuid,
 p_target_weight numeric,p_target_reps integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE plan jsonb;
BEGIN
  plan := public.get_session_exercises_v1(p_session_id);
  IF (SELECT completed_at IS NOT NULL FROM public.workout_sessions WHERE id=p_session_id) THEN
    RAISE EXCEPTION 'session closed' USING ERRCODE='23514'; END IF;
  IF p_target_reps IS NULL OR p_target_reps NOT BETWEEN 1 AND 1000 OR
     p_target_weight IS NULL OR NOT(p_target_weight BETWEEN 0 AND 10000) THEN
    RAISE EXCEPTION 'invalid exercise targets' USING ERRCODE='23514'; END IF;
  IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(plan) x WHERE x->>'id'=p_exercise_id::text AND (x->>'target_sets')::integer>0) THEN
    RAISE EXCEPTION 'active exercise not found' USING ERRCODE='23503'; END IF;
  SELECT jsonb_agg(CASE WHEN x->>'id'=p_exercise_id::text THEN
    x || jsonb_build_object('target_weight',p_target_weight,'target_reps',p_target_reps) ELSE x END ORDER BY ord)
  INTO plan FROM jsonb_array_elements(plan) WITH ORDINALITY a(x,ord);
  UPDATE public.workout_sessions SET exercise_plan=plan WHERE id=p_session_id;
  RETURN plan;
END $$;

REVOKE ALL ON FUNCTION public.get_session_exercises_v1(uuid) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.adapt_session_exercise_v1(uuid,uuid,integer,integer,numeric,uuid) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.update_session_exercise_target_v1(uuid,uuid,numeric,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_session_exercises_v1(uuid),
 public.adapt_session_exercise_v1(uuid,uuid,integer,integer,numeric,uuid),
 public.update_session_exercise_target_v1(uuid,uuid,numeric,integer) TO authenticated;

-- Retain the deployed view's exact projection, types and order (ws.* expansion
-- otherwise moves summary columns when a session column is added).
DO $$ DECLARE old_sql text; projection text;
BEGIN
  SELECT pg_get_viewdef('public.view_workout_sessions_summary'::regclass,true) INTO old_sql;
  SELECT string_agg(CASE a.attname
    WHEN 'total_target_sets' THEN 'coalesce(p.target,legacy.total_target_sets)::' || format_type(a.atttypid,a.atttypmod) || ' AS total_target_sets'
    WHEN 'total_completed_sets' THEN 'coalesce(p.done,legacy.total_completed_sets)::' || format_type(a.atttypid,a.atttypmod) || ' AS total_completed_sets'
    WHEN 'is_strictly_completed' THEN 'CASE WHEN ws.exercise_plan IS NULL THEN legacy.is_strictly_completed ELSE ws.completed_at IS NOT NULL AND p.done >= p.target END AS is_strictly_completed'
    ELSE format('legacy.%I',a.attname) END, ', ' ORDER BY a.attnum)
  INTO projection FROM pg_attribute a WHERE a.attrelid='public.view_workout_sessions_summary'::regclass AND a.attnum>0 AND NOT a.attisdropped;
  EXECUTE format('CREATE OR REPLACE VIEW public.view_workout_sessions_summary WITH (security_invoker=true) AS SELECT %s FROM (%s) legacy JOIN public.workout_sessions ws ON ws.id=legacy.id LEFT JOIN LATERAL (SELECT coalesce(sum((x->>''target_sets'')::integer),0)::bigint target, coalesce(sum(least((x->>''target_sets'')::integer,(SELECT count(*) FROM public.set_logs sl WHERE sl.session_id=ws.id AND sl.exercise_id=(x->>''id'')::uuid))),0)::bigint done FROM jsonb_array_elements(ws.exercise_plan) x WHERE ws.exercise_plan IS NOT NULL) p ON ws.exercise_plan IS NOT NULL',projection,rtrim(old_sql,'; ' || chr(10)));
END $$;

CREATE OR REPLACE FUNCTION public.get_coaching_inputs_v1(p_user_id uuid,p_session_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE result jsonb;
BEGIN
 IF auth.uid() IS NULL OR p_user_id IS DISTINCT FROM auth.uid() THEN RAISE EXCEPTION 'forbidden: p_user_id mismatch' USING ERRCODE='42501'; END IF;
 WITH s AS (SELECT * FROM public.workout_sessions WHERE id=p_session_id AND user_id=p_user_id),
 targets AS (
 SELECT (x->>'id')::uuid exercise_id,(x->>'target_sets')::int target_sets,(x->>'target_reps')::int target_reps,(x->>'target_weight')::numeric target_weight
 FROM s CROSS JOIN LATERAL jsonb_array_elements(s.exercise_plan) x WHERE (x->>'target_sets')::integer>0
 UNION ALL SELECT re.exercise_id,re.target_sets,re.target_reps,re.target_weight FROM s JOIN public.routine_exercises re ON re.routine_day_id=s.routine_day_id WHERE s.exercise_plan IS NULL),
 current_logs AS (SELECT sl.exercise_id,sl.actual_weight,sl.actual_reps,sl.set_index,ex.name FROM s JOIN public.set_logs sl ON sl.session_id=s.id JOIN public.exercises ex ON ex.id=sl.exercise_id ORDER BY sl.set_index),
 previous_logs AS (
 SELECT sl.exercise_id,sl.actual_weight,sl.actual_reps,sl.set_index FROM s JOIN targets t ON true
 CROSS JOIN LATERAL (SELECT ws.id FROM public.workout_sessions ws WHERE ws.user_id=p_user_id AND ws.completed_at IS NOT NULL AND ws.session_date<s.session_date AND EXISTS(SELECT 1 FROM public.set_logs l WHERE l.session_id=ws.id AND l.exercise_id=t.exercise_id) ORDER BY ws.session_date DESC,ws.id LIMIT 1) prev
 JOIN public.set_logs sl ON sl.session_id=prev.id AND sl.exercise_id=t.exercise_id ORDER BY sl.set_index)
 SELECT jsonb_build_object('session',(SELECT jsonb_build_object('id',id,'user_id',user_id,'routine_day_id',routine_day_id,'session_date',session_date) FROM s),
 'current_logs',coalesce((SELECT jsonb_agg(to_jsonb(c)) FROM current_logs c),'[]'::jsonb),
 'routine_exercises',coalesce((SELECT jsonb_agg(to_jsonb(t)) FROM targets t),'[]'::jsonb),
 'previous_logs',coalesce((SELECT jsonb_agg(to_jsonb(p)) FROM previous_logs p),'[]'::jsonb)) INTO result;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.get_coaching_inputs_v1(uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_coaching_inputs_v1(uuid,uuid) TO authenticated;

-- Existing table-level UPDATE grants must not let clients forge the snapshot.
-- Invoker trigger sees authenticated for direct writes, and the trusted function
-- owner while one of the SECURITY DEFINER RPCs performs its validated update.
CREATE FUNCTION public.guard_session_exercise_plan_v1()
RETURNS trigger LANGUAGE plpgsql SET search_path=public AS $$
BEGIN
 IF current_user IN ('authenticated','anon') AND
   ((TG_OP='INSERT' AND NEW.exercise_plan IS NOT NULL) OR
    (TG_OP='UPDATE' AND NEW.exercise_plan IS DISTINCT FROM OLD.exercise_plan)) THEN
   RAISE EXCEPTION 'exercise_plan is managed by session RPCs' USING ERRCODE='42501';
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.guard_session_exercise_plan_v1() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER guard_session_exercise_plan_v1 BEFORE INSERT OR UPDATE ON public.workout_sessions
FOR EACH ROW EXECUTE FUNCTION public.guard_session_exercise_plan_v1();

-- Serialize log writes with plan adaptation. Retained originals are immutable:
-- their preserved log count is now their target, so stale clients cannot alter it.
CREATE FUNCTION public.guard_session_set_log_v1()
RETURNS trigger LANGUAGE plpgsql SET search_path=public AS $$
DECLARE s public.workout_sessions; entry jsonb; sid uuid; eid uuid;
BEGIN
 sid := CASE WHEN TG_OP='DELETE' THEN OLD.session_id ELSE NEW.session_id END;
 eid := CASE WHEN TG_OP='DELETE' THEN OLD.exercise_id ELSE NEW.exercise_id END;
 -- Identity moves involving snapshots are rejected; lock both parents in UUID
 -- order before inspecting either so legacy moves cannot race initialization.
 IF TG_OP='UPDATE' AND (NEW.session_id,NEW.exercise_id,NEW.set_index)
   IS DISTINCT FROM (OLD.session_id,OLD.exercise_id,OLD.set_index) THEN
   PERFORM 1 FROM public.workout_sessions WHERE id IN (OLD.session_id,NEW.session_id) ORDER BY id FOR UPDATE;
   IF EXISTS(SELECT 1 FROM public.workout_sessions WHERE id IN (OLD.session_id,NEW.session_id) AND exercise_plan IS NOT NULL) THEN
     RAISE EXCEPTION 'snapshot log identity is immutable' USING ERRCODE='23514';
   END IF;
 END IF;
 SELECT * INTO s FROM public.workout_sessions WHERE id=sid FOR UPDATE;
 IF s.exercise_plan IS NOT NULL THEN
   IF s.completed_at IS NOT NULL THEN RAISE EXCEPTION 'session closed' USING ERRCODE='23514'; END IF;
   SELECT x INTO entry FROM jsonb_array_elements(s.exercise_plan) x WHERE x->>'id'=eid::text;
   IF entry IS NULL THEN RAISE EXCEPTION 'exercise outside session plan' USING ERRCODE='23514'; END IF;
   IF entry->>'replaced_by_exercise_name' IS NOT NULL THEN
     RAISE EXCEPTION 'retained original logs are immutable' USING ERRCODE='23514';
   END IF;
 END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.guard_session_set_log_v1() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER guard_session_set_log_v1 BEFORE INSERT OR UPDATE OR DELETE ON public.set_logs
FOR EACH ROW EXECUTE FUNCTION public.guard_session_set_log_v1();
