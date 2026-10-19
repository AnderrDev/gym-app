-- Minimal isolated PostgreSQL fixture; never run against an existing database.
create role authenticated;
create role anon;
create schema auth;
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create table exercises(id uuid primary key, name text, muscle_group text);
create table routine_exercises(id uuid primary key, routine_day_id uuid, exercise_id uuid, target_sets int, target_reps int, target_weight numeric, rest_timer_seconds int);
create table workout_sessions(id uuid primary key, user_id uuid, routine_day_id uuid, session_date date, completed_at timestamptz, coaching_analysis jsonb);
create table set_logs(id uuid primary key, session_id uuid, exercise_id uuid, set_index int, actual_weight numeric, actual_reps int);
create view view_workout_sessions_summary as select ws.*, 0::bigint total_target_sets, 0::bigint total_completed_sets, false is_strictly_completed from workout_sessions ws;
create temporary table session_summary_projection_before as
select attnum,attname,atttypid,atttypmod from pg_attribute
where attrelid='public.view_workout_sessions_summary'::regclass and attnum>0 and not attisdropped;
