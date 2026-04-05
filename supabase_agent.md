# Supabase Infrastructure Documentation

This document provides a comprehensive overview of the Supabase backend for the **gym_flutter** project. It is synchronized with the live project state as of April 2026.

**Project ID:** `benadgxgowycjxypyunc`

---

## 1. Database Schema (Public)

### Tables

#### `public.profiles`
User profile information linked to `auth.users`.
- **Columns**:
  - `id` (uuid, PK): Matches `auth.users.id`.
  - `full_name` (text, nullable).
- **RLS**: Enabled.
  - `profiles_select`: Anyone can view.
  - `profiles_insert`: User can only insert their own ID.
  - `profiles_update`: User can only update their own profile.

#### `public.exercises`
Reference table for available exercises.
- **Columns**:
  - `id` (uuid, PK, default: `gen_random_uuid()`).
  - `name` (text).
  - `description` (text, nullable).
  - `muscle_group` (text, nullable).
- **RLS**: Enabled.
  - `exercises_select`: Publicly viewable.

#### `public.routines`
Workout routines created by users or public templates.
- **Columns**:
  - `id` (uuid, PK, default: `gen_random_uuid()`).
  - `name` (text).
  - `creator_id` (uuid, FK -> `profiles.id`).
  - `created_at` (timestamptz, default: `now()`).
  - `is_public` (boolean, default: `false`).
- **RLS**: Enabled.
  - `routines_select`: Viewable if `is_public` or if user is the creator.
  - `routines_insert/update/delete`: Only by the creator.

#### `public.routine_days`
Specific days within a routine (e.g., "Day 1", "Leg Day").
- **Columns**:
  - `id` (uuid, PK, default: `gen_random_uuid()`).
  - `routine_id` (uuid, FK -> `routines.id`).
  - `day_of_week` (integer, 1-7).
  - `name` (text).
- **RLS**: Enabled.
  - `routine_days_select`: Viewable if the parent routine is public or owned.

#### `public.routine_exercises`
Linking table for exercises within a routine day, including targets.
- **Columns**:
  - `id` (uuid, PK, default: `gen_random_uuid()`).
  - `routine_day_id` (uuid, FK -> `routine_days.id`).
  - `exercise_id` (uuid, FK -> `exercises.id`).
  - `order` (integer, default: 0).
  - `target_sets` (integer, default: 3).
  - `target_reps` (integer, default: 10).
  - `target_weight` (numeric, default: 0).
  - `rest_timer_seconds` (integer, default: 90).
- **RLS**: Enabled.
  - `routine_exercises_select`: Viewable if parent routine is public or owned.

#### `public.workout_sessions`
Recorded instances of a user performing a routine day.
- **Columns**:
  - `id` (uuid, PK, default: `gen_random_uuid()`).
  - `user_id` (uuid, FK -> `profiles.id`).
  - `routine_day_id` (uuid, FK -> `routine_days.id`).
  - `session_date` (date, default: `CURRENT_DATE`).
  - `completed_at` (timestamptz, nullable).
  - `coaching_analysis` (jsonb, nullable).
- **RLS**: Enabled.
  - `sessions_select/insert/update`: Only by the owner (`user_id`).
- **Uniqueness**: `uq_workout_sessions_single_active_per_user` (Only one active session per user).

#### `public.set_logs`
Detailed logs for each set performed during a workout session.
- **Columns**:
  - `id` (uuid, PK, default: `gen_random_uuid()`).
  - `session_id` (uuid, FK -> `workout_sessions.id`).
  - `exercise_id` (uuid, FK -> `exercises.id`).
  - `set_index` (integer).
  - `actual_weight` (numeric, default: 0).
  - `actual_reps` (integer, default: 0).
  - `created_at` (timestamptz, default: `now()`).
- **RLS**: Enabled.
  - `set_logs_select/insert`: Only if the user owns the parent `workout_session`.
- **Uniqueness**: `uq_set_logs_session_exercise_set_index` (Unique set index per exercise in a session).

#### `public.user_routines`
Tracks which routine is currently assigned/active for a user.
- **Columns**:
  - `user_id` (uuid, PK, FK -> `profiles.id`).
  - `routine_id` (uuid, FK -> `routines.id`).
  - `assigned_at` (timestamptz, default: `now()`).
- **RLS**: Enabled.
  - `user_routines_select/insert/update/delete`: Only by the owner.

---

## 2. Views

### `public.routines_view`
Joins routines with profile names and counts exercises.
```sql
SELECT r.*, p.full_name AS creator_name, count(re.id) AS exercise_count ...
```

### `public.view_workout_sessions_summary`
Aggregates target vs. actual sets to determine completion status.
- **Calculated fields**: `total_target_sets`, `total_completed_sets`, `is_strictly_completed`.

---

## 3. SQL Functions & Triggers

### `public.handle_new_user()`
Automatically creates a profile in `public.profiles` when a user signs up via Auth.
- **Trigger**: `on_auth_user_created` (AFTER INSERT on `auth.users`).

### `public.get_last_exercise_performance(p_user_id, p_exercise_id)`
Returns the most recent set log for a specific exercise and user as JSONB.

---

## 4. Edge Functions

Configured in `supabase.json`:
- `finalize_workout_session_v1`: Processes session completion logic.
- `generate_coaching_v1`: AI-driven coaching insights based on session data.
- `get_weekly_insights_v1`: Summarizes weekly progress.

**Auth Note**: Configured as `verify_jwt: false` in `supabase.json`, but function code expects/validates JWT.

---

## 5. Storage

- No specific custom buckets were identified during exploration, but standard defaults exist.

---

## 6. Performance & Security Notes

- **Indices**: All foreign keys and frequently queried columns (like `session_date`, `user_id`) have optimized indices.
- **RLS**: Comprehensive policies ensure data isolation between users.
- **Offline Sync**: Infrastructure exists in the codebase but is currently disabled in DI (`lib/injection_container.dart`).
