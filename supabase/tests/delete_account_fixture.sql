-- Esquema mínimo y aislado para probar `delete_account_data_v1` en un
-- PostgreSQL desechable. NUNCA ejecutar contra una base existente.
-- Orden: este fixture → 20261015144656_session_exercises.sql →
-- 20261020130000_delete_account.sql → delete_account.sql.
-- Las FKs se crean NO ACTION y `creator_id` NOT NULL a propósito: la
-- migración debe relajarlas.
create role authenticated;
create role anon;
create role service_role;
create schema auth;
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create table auth.users(id uuid primary key);
create table profiles(id uuid primary key references auth.users(id), full_name text);
create table exercises(id uuid primary key, name text, muscle_group text);
create table routines(id uuid primary key, name text, is_public boolean default false, creator_id uuid not null references profiles(id));
create table routine_days(id uuid primary key, routine_id uuid references routines(id) on delete cascade, day_of_week int, name text);
create table routine_exercises(id uuid primary key default gen_random_uuid(), routine_day_id uuid references routine_days(id) on delete cascade, exercise_id uuid references exercises(id), "order" int default 0, target_sets int, target_reps int, target_weight numeric, rest_timer_seconds int);
create table user_routines(user_id uuid primary key references auth.users(id), routine_id uuid references routines(id));
create table workout_sessions(id uuid primary key, user_id uuid references auth.users(id), routine_day_id uuid references routine_days(id), session_date date, completed_at timestamptz, coaching_analysis jsonb);
create table set_logs(id uuid primary key default gen_random_uuid(), session_id uuid references workout_sessions(id), exercise_id uuid references exercises(id), set_index int, actual_weight numeric, actual_reps int);
create table function_rate_limits(user_id uuid not null references auth.users(id) on delete cascade, function_name text not null, window_start timestamptz not null, count int not null default 0, primary key (user_id, function_name, window_start));
create view view_workout_sessions_summary as select ws.*, 0::bigint total_target_sets, 0::bigint total_completed_sets, false is_strictly_completed from workout_sessions ws;
