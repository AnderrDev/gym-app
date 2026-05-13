# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Smart Gym Tracker — Flutter app (Android, iOS, Web) for strength/hypertrophy training with progressive overload. Backend is Supabase (Auth + Postgres + Edge Functions). Web hosting goes to Firebase (`build/web` → `gym-flutter-web-224`, see `firebase.json`/`.firebaserc`).

The authoritative architecture document is `docs/AGENT_CONTEXT.md` — read it before any non-trivial change. `AGENTS.md` lists supplementary agent rules.

## Commands

The app needs Supabase credentials at startup. Resolution order (first non-empty wins, otherwise `SupabaseConfig.init()` throws `StateError`):

1. `--dart-define=SUPABASE_URL` / `--dart-define=SUPABASE_ANON_KEY` (or `--dart-define-from-file=.env`) — used by CI/release.
2. `.env` at the repo root, loaded at runtime via `flutter_dotenv` (`dotenv.load` in `lib/main.dart`). The file is bundled as an asset (`pubspec.yaml#assets`) and gitignored.

For local dev just keep `.env` populated and run:

```bash
flutter run                      # mobile / desktop
flutter run -d chrome            # web
```

Releases / CI pass the defines explicitly (the `.env` asset is optional — if missing, dotenv silently skips and the dart-defines take over):

```bash
flutter build web --dart-define-from-file=.env
```

- Install deps: `flutter pub get`
- Static analysis: `flutter analyze` (uses `package:flutter_lints/flutter.yaml`)
- All tests: `flutter test`
- Single test file: `flutter test test/features/workout/domain/usecases/save_set_log_test.dart`
- Single test by name: `flutter test --plain-name "<substring of test description>"`
- Integration test: `flutter test integration_test/app_test.dart` (or via `flutter drive`)
- Edge-function contract smoke test: `bash scripts/contract_smoke_supabase.sh` (requires `supabase` CLI auth, `psql`, `jq`, and `SUPABASE_DB_PASSWORD` env var; creates a real test user via admin API and exercises all three Edge Functions end-to-end)
- Firebase web deploy: `flutter build web` then `firebase deploy --only hosting`

## High-level architecture

### Layering — Clean Architecture per feature

```
lib/
  core/                         transversal: config, routes, errors, services
  features/
    auth/{data,domain,presentation}
    workout/{data,domain,presentation}
  injection_container.dart      get_it composition root
  main.dart                     bootstrap (locale → Supabase → DI → router)
```

Within each feature: `domain` (entities + repository interfaces + use cases returning `Either<Failure, T>` via `fpdart`) → `data` (models + remote/local data sources + repository impl) → `presentation` (BLoC + pages/widgets). UI **must not** call data sources or Supabase directly — go through use cases.

### State management — flutter_bloc

Two top-level providers wired in `main.dart`: `AuthBloc` (lifetime-bound to the app) and `WorkoutBloc` (created via DI). Auth state drives navigation: the router subscribes to `authBloc.stream` via `GoRouterRefreshStream` and redirects unauthenticated users to `/login` and authenticated users away from auth pages. **While `AuthInitial`/`AuthLoading`, redirect returns `null` to avoid flicker before auth resolves** — preserve this behavior when modifying `AppRouter`.

### Routing

All paths are constants on `AppRoutes` (`lib/core/routes/app_routes.dart`). `AppRouter` (`lib/core/routes/app_router.dart`) registers them with `go_router` and decodes `state.extra` as either a raw `String?` (routine id) or a `Map<String, dynamic>` for screens that need multiple typed params (e.g. `routineDay`, `routineStats`, `exerciseProgress`). When adding a route, update `AppRoutes`, not string literals.

### Backend split (data path)

- Direct Supabase tables — read/written via PostgREST in `workout_remote_data_source.dart` and `auth_remote_data_source.dart`.
- RPCs (all `SECURITY DEFINER`, gate-checked against `auth.uid()`): `get_last_exercise_performance`, `get_last_exercise_performances`, `get_coaching_inputs_v1`, `compute_weekly_insights_v1`. From the Dart side only `get_last_exercise_performances` is invoked directly (`WorkoutRemoteDataSource.getLastPerformances`); the rest are called inside Edge Functions. Prefer RPC over ad-hoc joins where one exists.
- Edge Functions — invoked from `WorkoutRemoteDataSource`:
  - `finalize_workout_session_v1` (closes session, optionally generates coaching)
  - `generate_coaching_v1` (per-exercise recommendations)
  - `get_weekly_insights_v1` (dashboard metrics)

  Function contracts live in `docs/EDGE_FUNCTIONS.md` and per-function READMEs under `supabase/functions/`. **`supabase.json` sets `verify_jwt: true` for all three (gateway validates the JWT signature)**, and each function additionally calls `supabaseAdmin.auth.getUser(token)` via the shared `_shared/auth.ts#requireUser` helper as defense in depth. The client passes `Authorization: Bearer <session.access_token>` explicitly when invoking. **Do not loosen `verify_jwt` without a security review.**

### Database / migrations

SQL source of truth is `supabase/migrations/`. Numbering is mixed (`002_*.sql` legacy + `2026MMDDHHMMSS_*.sql` timestamped); lex-sorting them yields the correct chronological order, but new migrations must always use the timestamped style. Any schema change requires a new migration file; do **not** edit historical migrations. The old `supabase/schema.sql` snapshot was deleted in 2026-05 — reconstruct the live schema by reading the migrations in order. Seeds: `supabase/seed_mock_data.sql` and `supabase/assign_mock.sql` (both idempotent).

Key tables: `profiles`, `routines`, `exercises`, `user_routines`, `routine_days`, `routine_exercises`, `workout_sessions`, `set_logs`. Key view: `view_workout_sessions_summary` (provides `total_target_sets`, `total_completed_sets`, `is_strictly_completed`). RLS is enabled — writes to sessions/logs are restricted to the owning user; `profiles_select` is restricted to self + creators of routines visible to the requester (`20260508120000_security_hardening_idor.sql`).

### Error mapping convention

Repository implementations should NOT use ad-hoc `catch (e) { return Left(ServerFailure(e.toString())) }`. Use the helper in `lib/core/error/error_mapper.dart`:

- `mapToFailure(error)` returns a typed `Failure` (Auth/Network/NotFound/Conflict/Validation/Server) by inspecting the exception type (`PostgrestException`, `supabase.AuthException`, `SocketException`, `TimeoutException`, project exceptions, …).
- `guard<T>(() async => …)` wraps the body and returns `Either<Failure, T>` directly.

`workout_repository_impl.dart` is the canonical example; new repositories must follow the same pattern.

### Known drift (treat as constraints)

1. **Offline-first removed.** All offline-first scaffolding (`database_helper`, `workout_local_data_source`, `network_info`, `sync_service`, `database_inspector_page`, deps `sqflite*` and `internet_connection_checker_plus`) was deleted because the wiring had been disabled for months. Runtime is remote-only. Re-introduction requires a fresh design discussion.
2. **No `schema.sql` snapshot.** It was deleted because it always drifted from the deployed state. Reconstruct the schema from `supabase/migrations/` if you need a full picture.

## Conventions

- Dart SDK `^3.10.8`, Flutter, Material 3 dark scheme (`AppColors` in `lib/core/constants`).
- Locale: Spanish (`es`) — `intl`/`date_symbol_data_local` initialized in `main.dart`. UI strings and many doc/comment strings are Spanish; preserve language when editing.
- Functional error handling with `fpdart` — use cases return `Either<Failure, T>`; don't throw from domain code. Use `guard`/`mapToFailure` in repositories.
- DI via `get_it` (`sl`). Repositories/data sources are `LazySingleton`; BLoCs are `Factory`. Register new dependencies in `injection_container.dart`.
- `AuthBloc` consumes `AuthRepository.authStateChanges` (a `Stream<bool>`) — it must NOT import `package:supabase_flutter/...`. Adding a new auth-aware bloc? Inject the repository, not the SDK.
- The "is there an in-progress workout?" question is owned by `ActiveSessionService` (`lib/core/services/active_session_service.dart`) — DI singleton, watched by `ActiveSessionWatcherBloc`. Don't query `workout_sessions` directly from UI/blocs for this state.
- Logging goes through `lib/core/observability/app_logger.dart` and `AppBlocObserver`. Use the logger instead of raw `print`/`debugPrint`.
- Tests live under `test/features/<feature>/{data,domain,presentation}` mirroring `lib/`. Shared mocks in `test/helpers/mocks.dart` (`MockAuthRepository`, `MockWorkoutRepository`, `MockWorkoutRemoteDataSource`, `MockActiveSessionService`, `MockClock` + the `FakeClock` factory), fixtures in `test/helpers/test_fixtures.dart`. Test stack: `flutter_test` + `bloc_test` + `mocktail`.
- Prefer absolute imports (`package:gym_flutter/...`) for new files — the codebase is mid-migration (most of `lib/` is absolute, but `features/auth/` still has legacy relative imports). Don't add new relative imports; existing ones can be left alone unless the file is being substantially edited.

## Before finishing a change

- Run `flutter analyze` — must come back clean (no new warnings).
- Run the impacted tests at minimum (e.g. `flutter test test/features/<feature>/...`). For non-trivial changes, run `flutter test`.
- If you touched an Edge Function or its contract, also run `bash scripts/contract_smoke_supabase.sh` when the smoke env is available.
- If you touched routing, auth gating, or DI, manually verify the redirect-on-auth and the bootstrap path didn't regress.
