# AGENTS

Supplementary notes for AI agents working in this repo. The primary source of truth is **`CLAUDE.md`** (root) — read that first. This file only covers pointers and rules that don't fit cleanly there.

## Read first
- `CLAUDE.md` — architecture, commands, conventions, error mapping, DB rules.
- `docs/AGENT_CONTEXT.md` — extended architecture/flow notes and Supabase drift context. Required before any non-trivial change.
- `docs/EDGE_FUNCTIONS.md` and per-function READMEs under `supabase/functions/` for API contracts.

## Run / dev
See `CLAUDE.md#Commands`. Local dev uses `.env` at the repo root (loaded by `flutter_dotenv`); CI/release passes the same values via `--dart-define-from-file=.env`. Don't reintroduce hardcoded credential fallbacks in `SupabaseConfig` — `init()` is supposed to throw `StateError` when both sources are empty.

## Backend / DB
- **Source of truth:** `supabase/migrations/` only. The old `supabase/schema.sql` snapshot was removed in 2026-05; do not re-create it.
- Any schema change → new timestamped migration. Never edit historical migrations.
- Seeds: `supabase/seed_mock_data.sql` and `supabase/assign_mock.sql` (idempotent).

## Edge Functions
- Registered in `supabase.json`: `finalize_workout_session_v1`, `generate_coaching_v1`, `get_weekly_insights_v1` — all with `verify_jwt: true`.
- Auth helper: `supabase/functions/_shared/auth.ts#requireUser(req)` validates the bearer token via `supabaseAdmin.auth.getUser`. Don't decode JWTs by hand. Don't loosen `verify_jwt` without a security review.

## Offline-first wiring
Removed. Runtime is remote-only. See `CLAUDE.md#Known drift` §1. Re-introduction needs a fresh design discussion, not a silent revival of the deleted scaffolding.

## Web hosting (Firebase)
- Hosting output is `build/web` (`firebase.json`).
- Default Firebase project: `gym-flutter-web-224` (`.firebaserc`).
- Deploy: `flutter build web` then `firebase deploy --only hosting`.
