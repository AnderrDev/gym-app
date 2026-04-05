# AGENTS

## Read First
- `docs/AGENT_CONTEXT.md` for current architecture/flow notes and Supabase drift context.
- `docs/EDGE_FUNCTIONS.md` and per-function READMEs under `supabase/functions/` for API contracts.

## Run / Dev
- App expects Supabase creds via `--dart-define` (from `README.md`):
  - `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## Backend / DB
- SQL sources of truth live in `supabase/schema.sql` and `supabase/migrations/`; add a migration for any schema change.
- Seed data: `supabase/seed_mock_data.sql` and `supabase/assign_mock.sql`.

## Edge Functions
- Functions registered in `supabase.json`: `finalize_workout_session_v1`, `generate_coaching_v1`, `get_weekly_insights_v1`.
- `supabase.json` sets `verify_jwt: false` for all three; function docs say JWT required. Prefer config over docs and verify before changing auth behavior.

## Offline-First Wiring
- Offline/local data sources and sync services exist but are commented out in DI (`lib/injection_container.dart`); current runtime is remote-only.

## Web Hosting (Firebase)
- Hosting output is `build/web` (`firebase.json`); default Firebase project is `gym-flutter-web-224` (`.firebaserc`).
