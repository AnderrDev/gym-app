#!/usr/bin/env bash
# Levanta un Supabase LOCAL con el esquema completo de producción para probar
# el coach (ver README.md de esta carpeta). No modifica el repo: trabaja sobre
# una copia de supabase/ en $SIM_DIR.
#
#   bash scripts/local_coach_sim/setup_local.sh        # arranca (o reinicia)
#   bash scripts/local_coach_sim/setup_local.sh stop   # para y borra la copia
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
# Dentro de build/ (ignorado por git). No usar carpetas ocultas: Docker
# Desktop no comparte su contenido con los contenedores.
SIM_DIR="${SIM_DIR:-$REPO/build/local-coach-sim}"
# Último schema.sql antes de borrarse (2026-05): las migraciones empiezan con
# ALTER y necesitan estas tablas base.
SCHEMA_COMMIT="78d01e911dc408bf09ee375d605f6d95bc00d1a8"

if [[ "${1:-}" == "stop" ]]; then
  supabase stop --workdir "$SIM_DIR" --no-backup || true
  rm -rf "$SIM_DIR"
  exit 0
fi

rm -rf "$SIM_DIR"
mkdir -p "$SIM_DIR"
# Los ficheros versionados de supabase/, con su contenido actual (incluye
# cambios sin commitear en las Edge Functions; excluye ficheros sin trackear).
(cd "$REPO" && git ls-files -z supabase | tar --null -T - -cf -) | tar -xf - -C "$SIM_DIR"
git -C "$REPO" show "$SCHEMA_COMMIT:supabase/schema.sql" > "$SIM_DIR/supabase/migrations/000_base_schema_local.sql"

# El Supabase local nuevo no concede SELECT/INSERT/UPDATE/DELETE a los roles
# de la API; producción (proyecto antiguo) sí. RLS sigue mandando.
cat > "$SIM_DIR/supabase/migrations/99999999999999_local_api_grants.sql" <<'SQL'
GRANT SELECT, INSERT, UPDATE, DELETE ON
  public.profiles, public.exercises, public.routines, public.user_routines,
  public.routine_days, public.routine_exercises, public.workout_sessions,
  public.set_logs, public.function_rate_limits
TO anon, authenticated, service_role;
GRANT SELECT ON public.view_workout_sessions_summary, public.routines_view TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.coaching_events, public.exercise_session_stats TO service_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO service_role;
SQL

# Puertos propios (5632x) para convivir con otros proyectos locales.
sed -i '' 's/^project_id = .*/project_id = "gym_coach_sim"/' "$SIM_DIR/supabase/config.toml"
cat >> "$SIM_DIR/supabase/config.toml" <<'TOML'

[api]
port = 56321

[db]
port = 56322
shadow_port = 56320
major_version = 17

[db.pooler]
port = 56329

[studio]
port = 56323

[inbucket]
port = 56324

[analytics]
port = 56327
TOML

supabase start --workdir "$SIM_DIR"
echo
echo "Listo. Simula con:"
echo "  eval \"\$(supabase status --workdir $SIM_DIR -o env | grep -E '^(API_URL|ANON_KEY|SERVICE_ROLE_KEY)=')\" && export API_URL ANON_KEY SERVICE_ROLE_KEY"
echo "  deno run --allow-net --allow-env scripts/local_coach_sim/simulate.ts"
