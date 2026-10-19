#!/usr/bin/env bash
set -euo pipefail

PROJECT_REF="benadgxgowycjxypyunc"
BASE_URL="https://${PROJECT_REF}.supabase.co"
FUNCTIONS_URL="https://${PROJECT_REF}.functions.supabase.co"

ANON_KEY=$(supabase projects api-keys --project-ref "$PROJECT_REF" --output json | jq -r '.[] | select(.name=="anon") | .api_key')
SERVICE_ROLE_KEY=$(supabase projects api-keys --project-ref "$PROJECT_REF" --output json | jq -r '.[] | select(.name=="service_role") | .api_key')

TEST_EMAIL="contract.$(date +%s)@gym.local"
TEST_PASSWORD='Str0ng!Pass#2026'

create_user_resp=$(curl -sS -X POST "$BASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"email_confirm\":true}")

user_id=$(echo "$create_user_resp" | jq -r '.id')
if [[ -z "$user_id" || "$user_id" == "null" ]]; then
  echo "FAILED_CREATE_USER"
  echo "$create_user_resp"
  exit 1
fi

signin_resp=$(curl -sS -X POST "$BASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

access_token=$(echo "$signin_resp" | jq -r '.access_token')
if [[ -z "$access_token" || "$access_token" == "null" ]]; then
  echo "FAILED_SIGNIN"
  echo "$signin_resp"
  exit 1
fi

if [[ -z "${SUPABASE_DB_PASSWORD:-}" ]]; then
  echo "Missing SUPABASE_DB_PASSWORD env var"
  exit 1
fi

export PGPASSWORD="$SUPABASE_DB_PASSWORD"
psql "host=aws-0-us-west-2.pooler.supabase.com port=6543 dbname=postgres user=postgres.${PROJECT_REF} sslmode=require" -v ON_ERROR_STOP=1 <<SQL
insert into public.profiles (id, full_name)
values ('$user_id', 'Contract Test User')
on conflict (id) do nothing;

insert into public.routines (id, creator_id, name)
values ('10000000-0000-0000-0000-000000000001', '$user_id', 'Contract Routine')
on conflict (id) do update set creator_id=excluded.creator_id, name=excluded.name;

insert into public.user_routines (user_id, routine_id)
values ('$user_id', '10000000-0000-0000-0000-000000000001')
on conflict (user_id, routine_id) do nothing;

insert into public.routine_days (id, routine_id, day_of_week, name)
values ('10000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 1, 'Lunes Contract')
on conflict (id) do update set routine_id=excluded.routine_id, day_of_week=excluded.day_of_week, name=excluded.name;

insert into public.routine_exercises (id, routine_day_id, exercise_id, "order", target_sets, target_reps, target_weight, rest_timer_seconds)
values ('10000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000003', 'eeeeeeee-0000-0000-0000-000000000001', 0, 3, 8, 40, 90)
on conflict (id) do update set target_sets=excluded.target_sets, target_reps=excluded.target_reps, target_weight=excluded.target_weight, rest_timer_seconds=excluded.rest_timer_seconds;

insert into public.workout_sessions (id, user_id, routine_day_id, session_date, completed_at, coaching_analysis)
values ('10000000-0000-0000-0000-000000000005', '$user_id', '10000000-0000-0000-0000-000000000003', current_date, null, null)
on conflict (id) do update set user_id=excluded.user_id, routine_day_id=excluded.routine_day_id, session_date=excluded.session_date, completed_at=null, coaching_analysis=null;

insert into public.set_logs (id, session_id, exercise_id, set_index, actual_weight, actual_reps, created_at)
values
  ('10000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000005', 'eeeeeeee-0000-0000-0000-000000000001', 1, 40, 8, now()),
  ('10000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000005', 'eeeeeeee-0000-0000-0000-000000000001', 2, 40, 8, now()),
  ('10000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000005', 'eeeeeeee-0000-0000-0000-000000000001', 3, 40, 8, now())
on conflict (id) do update set actual_weight=excluded.actual_weight, actual_reps=excluded.actual_reps, created_at=excluded.created_at;
SQL

gen_http=$(curl -sS -o /tmp/gen_success.json -w "%{http_code}" -X POST "$FUNCTIONS_URL/generate_coaching_v1" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/json" \
  -d '{"session_id":"10000000-0000-0000-0000-000000000005"}')

gen_success=$(jq -r '.success' /tmp/gen_success.json)
gen_code=$(jq -r '.code' /tmp/gen_success.json)

fin_http=$(curl -sS -o /tmp/finalize_success.json -w "%{http_code}" -X POST "$FUNCTIONS_URL/finalize_workout_session_v1" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/json" \
  -d '{"session_id":"10000000-0000-0000-0000-000000000005"}')

fin_success=$(jq -r '.success' /tmp/finalize_success.json)
fin_code=$(jq -r '.code' /tmp/finalize_success.json)

week_start=$(date -u +%Y-%m-%d)
ins_payload=$(printf '{"routine_id":"10000000-0000-0000-0000-000000000001","week_start":"%s"}' "$week_start")
ins_http=$(curl -sS -o /tmp/insights_success.json -w "%{http_code}" -X POST "$FUNCTIONS_URL/get_weekly_insights_v1" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/json" \
  -d "$ins_payload")

ins_success=$(jq -r '.success' /tmp/insights_success.json)
ins_code=$(jq -r '.code' /tmp/insights_success.json)

echo "CONTRACT_OK|generate|http=${gen_http}|success=${gen_success}|code=${gen_code}"
echo "CONTRACT_OK|finalize|http=${fin_http}|success=${fin_success}|code=${fin_code}"
echo "CONTRACT_OK|insights|http=${ins_http}|success=${ins_success}|code=${ins_code}"

psql "host=aws-0-us-west-2.pooler.supabase.com port=6543 dbname=postgres user=postgres.${PROJECT_REF} sslmode=require" -P pager=off -Atc "select 'session_completed|'||(completed_at is not null)::text||'|coaching_not_null|'||(coaching_analysis is not null)::text from public.workout_sessions where id='10000000-0000-0000-0000-000000000005';"

# ── Negative auth tests ────────────────────────────────────
# Each must FAIL with 401. Anything else is a regression.

# 1. No Authorization header → gateway must reject with 401.
no_auth_http=$(curl -sS -o /tmp/no_auth.json -w "%{http_code}" -X POST "$FUNCTIONS_URL/get_weekly_insights_v1" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"routine_id":"10000000-0000-0000-0000-000000000001"}' || true)

# 2. Forged JWT (random base64) → gateway must reject signature.
forged_jwt='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEifQ.invalid_signature_here'
forged_http=$(curl -sS -o /tmp/forged.json -w "%{http_code}" -X POST "$FUNCTIONS_URL/get_weekly_insights_v1" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $forged_jwt" \
  -H "Content-Type: application/json" \
  -d '{"routine_id":"10000000-0000-0000-0000-000000000001"}' || true)

# 3. IDOR direct on RPC: another user's UUID with our token.
# Esto pega contra postgrest, no contra edge function. La RPC debe
# rechazarlo por el guard auth.uid() == p_user_id.
victim_uuid='00000000-0000-0000-0000-0000000000aa'
idor_payload=$(printf '{"p_user_id":"%s","p_routine_id":"10000000-0000-0000-0000-000000000001","p_week_start":"%s"}' "$victim_uuid" "$week_start")
idor_http=$(curl -sS -o /tmp/idor.json -w "%{http_code}" -X POST "$BASE_URL/rest/v1/rpc/compute_weekly_insights_v1" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/json" \
  -d "$idor_payload" || true)

echo "AUTH_NEG|no_auth|http=${no_auth_http}|expect=401"
echo "AUTH_NEG|forged_jwt|http=${forged_http}|expect=401"
echo "AUTH_NEG|idor_rpc|http=${idor_http}|expect=403_or_500"

if [[ "$no_auth_http" != "401" ]]; then echo "FAIL: no_auth must return 401, got $no_auth_http"; exit 1; fi
if [[ "$forged_http" != "401" ]]; then echo "FAIL: forged_jwt must return 401, got $forged_http"; exit 1; fi
# IDOR returns either 403 (if RAISE EXCEPTION mapped) or 500. Anything 2xx is a critical bug.
if [[ "$idor_http" =~ ^2 ]]; then echo "FAIL: idor_rpc must NOT succeed, got $idor_http"; exit 1; fi
