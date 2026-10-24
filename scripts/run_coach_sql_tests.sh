#!/usr/bin/env bash
# Ejecuta supabase/tests/coach_stats.sql en un PostgreSQL temporal (no toca
# ningún proyecto de Supabase). Requiere initdb/pg_ctl/psql en el PATH.
set -euo pipefail
export LC_ALL=C LANG=C
cd "$(dirname "$0")/.."
DATA="$(mktemp -d)"
PORT="${PORT:-55432}"
trap 'pg_ctl -D "$DATA" -m immediate stop >/dev/null 2>&1 || true; rm -rf "$DATA"' EXIT
initdb -D "$DATA" -U postgres --auth=trust --locale=C --encoding=UTF8 >/dev/null
pg_ctl -D "$DATA" -o "-p $PORT -k $DATA" -l "$DATA/log" start -w >/dev/null
run() { psql -h "$DATA" -p "$PORT" -U postgres -d postgres -v ON_ERROR_STOP=1 -q -t -f "$1"; }
run supabase/tests/session_exercises_fixture.sql
run supabase/migrations/20261015144656_session_exercises.sql
run supabase/tests/coach_stats_fixture.sql
run supabase/migrations/20261022130000_coach_catalog_and_rep_range.sql
run supabase/migrations/20261022140000_coach_stats_and_events.sql
run supabase/migrations/20261022232000_coach_v2_rpcs.sql
run supabase/migrations/20261022233000_coach_inputs_v2_names.sql
run supabase/migrations/20261024163000_coach_layoff_soft.sql
run supabase/tests/coach_stats.sql
run supabase/tests/coach_v2_rpcs.sql
