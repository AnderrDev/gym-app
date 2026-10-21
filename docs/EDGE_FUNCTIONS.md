# Edge Functions activas (fase actual)

Este documento describe las functions implementadas en la fase actual del proyecto.

## Rate limiting (todas las functions)

Todas las functions invocan `enforceRateLimit` (`supabase/functions/_shared/rate_limit.ts`) inmediatamente después de `requireUser`. La ventana es de 60 s por usuario y por function:

| Function | Llamadas / min |
|---|---|
| `finalize_workout_session_v1` | 30 |
| `generate_coaching_v1` | 30 |
| `get_weekly_insights_v1` | 60 |
| `delete_account_v1` | 5 |

Cuando el usuario supera el límite la function devuelve `429 RATE_LIMIT_EXCEEDED` con `error.reset_at` indicando cuándo termina la ventana. Si la RPC `enforce_rate_limit` falla por motivos de plataforma, se hace *fail open* (la llamada procede) y el error queda logueado como `RATE_LIMIT_RPC_ERROR`.

## 1) finalize_workout_session_v1

Objetivo:
- Cerrar una sesión de entrenamiento en backend de forma segura.

Request (POST):
- `session_id` (string, requerido)
- `coaching_analysis` (array, opcional)

Comportamiento:
- Requiere JWT válido (`verify_jwt=true`).
- Solo permite cerrar sesiones del usuario autenticado.
- Solo cierra sesiones activas (`completed_at IS NULL`).
- Si no llega `coaching_analysis`, intenta generarlo invocando `generate_coaching_v1`.

Response:
- `success`
- `code`
- `data.session_id`
- `data.summary` (si disponible)

## 2) generate_coaching_v1

Objetivo:
- Generar recomendaciones de coaching por ejercicio para una sesión.

Request (POST):
- `session_id` (string, requerido)

Comportamiento:
- Requiere JWT válido.
- Verifica ownership de la sesión.
- Usa logs actuales, objetivos de la copia de sesión y última sesión completada con el mismo ejercicio (incluso en otro día de rutina).
- Retorna recomendaciones:
  - `INCREASE_WEIGHT`
  - `INCREASE_REPS`
  - `MAINTAIN`
  - `DECREASE_WEIGHT`

Response:
- `success`
- `code`
- `data.session_id`
- `data.analysis[]`

## 3) get_weekly_insights_v1

Objetivo:
- Proveer métricas semanales server-side para dashboard.

Request (POST):
- `routine_id` (string, requerido)
- `week_start` (string `YYYY-MM-DD`, opcional)

Comportamiento:
- Requiere JWT válido.
- Verifica ownership por usuario autenticado + días de la rutina.
- Calcula:
  - adherencia semanal
  - sesiones completadas
  - volumen total semanal
  - volumen semana anterior
  - tendencia porcentual
  - PRs (máximo peso por ejercicio vs histórico previo)

Response:
- `success`
- `code`
- `data.week_start`
- `data.week_end`
- `data.planned_days`
- `data.completed_days`
- `data.completed_sessions`
- `data.adherence_rate`
- `data.total_volume`
- `data.previous_week_volume`
- `data.volume_trend_percent`
- `data.personal_records`

## 4) delete_account_v1

Objetivo:
- Eliminar la cuenta del usuario autenticado (App Store 5.1.1(v)).

Request (POST):
- `confirm` (string, requerido): exactamente `"ELIMINAR"`.

Comportamiento:
- Requiere JWT válido (`verify_jwt=true`) + `requireUser`.
- Sin `confirm` correcto → `400 CONFIRMATION_REQUIRED` (no borra nada).
- Llama con service_role a la RPC `delete_account_data_v1(p_user_id)` (sólo
  ejecutable por service_role), que en una transacción borra series, sesiones,
  asignación, rutinas privadas (días + ejercicios), rate limits y perfil, y
  **anonimiza** (`creator_id = NULL`) las rutinas públicas del usuario y las
  privadas que use otro usuario. Una rutina sin dueño no la puede editar nadie;
  la app la muestra como "Comunidad".
- Después borra el usuario con `auth.admin.deleteUser`. Si falla, repite la
  RPC (idempotente) y reintenta una vez.

Response:
- `success`
- `code` (`ACCOUNT_DELETED`)
- `data.user_id`
- `data.deleted` (conteos por tabla)

Errores: `INVALID_JSON` 400, `CONFIRMATION_REQUIRED` 400, `UNAUTHORIZED` 401,
`METHOD_NOT_ALLOWED` 405, `RATE_LIMIT_EXCEEDED` 429,
`DELETE_ACCOUNT_DATA_ERROR` 500, `DELETE_AUTH_USER_ERROR` 500. Detalle en
`supabase/functions/delete_account_v1/README.md`.

Cliente: `ProfileRemoteDataSource.deleteAccount` (feature `profile`). Tras el
éxito la app purga el outbox, la caché drift, la sesión activa y los borradores
locales y cierra sesión en local.

## Estados remotos (verificados)
- `finalize_workout_session_v1`: ACTIVE (version 3)
- `generate_coaching_v1`: ACTIVE (version 2)
- `get_weekly_insights_v1`: ACTIVE (version 1)
- `delete_account_v1`: pendiente de desplegar (requiere antes la migración `20261020130000_delete_account.sql`)

## Integración Flutter actual
- `lib/features/workout/data/datasources/workout_remote_data_source.dart`
- Método `finishWorkoutSession(...)` invoca `finalize_workout_session_v1`.
- Método `getWeeklyInsights(...)` invoca `get_weekly_insights_v1`.
- `dashboard_page.dart` renderiza insights y fallback visual cuando la function no responde.
- Ya no se usa fallback legacy de update directo para cerrar sesión.

## Próximo paso recomendado
1. Añadir tests de contrato para las 3 functions (success/error/códigos).
2. Ejecutar smoke test E2E de cierre + coaching + insights en datos reales.
3. Revisar performance SQL en remoto con `pg_stat_statements`.

### Ejercicios y objetivos de una sesión

La migración `20261015144656_session_exercises.sql` añade
`workout_sessions.exercise_plan`, una copia JSONB inicializada al leer una sesión
abierta. Las sesiones cerradas anteriores conservan la lectura de rutina compatible
sin escribir una copia retroactiva. No cambia ningún contrato HTTP de las Edge
Functions.

RPCs para usuarios autenticados (siempre validan ownership):

- `get_session_exercises_v1(p_session_id uuid) → jsonb[]` devuelve el plan completo.
- `adapt_session_exercise_v1(p_session_id uuid, p_exercise_id uuid,
  p_target_sets integer, p_target_reps integer, p_target_weight numeric,
  p_replace_exercise_id uuid default null) → jsonb[]` añade o sustituye.
- `update_session_exercise_target_v1(p_session_id uuid, p_exercise_id uuid,
  p_target_weight numeric, p_target_reps integer) → jsonb[]` cambia objetivos.

El retorno SQL es `jsonb` con un array JSON, compatible con `ExerciseModel`.
Incluye `is_extra`, `replaces_exercise_name`, `replaced_by_exercise_name` y también
los originales sustituidos con `target_sets = 0`; el cliente oculta estos últimos
en la lista de pendientes. Las escrituras directas del cliente al plan se rechazan.
Las mutaciones bloquean la fila de sesión y rechazan sesiones cerradas, duplicados,
ejercicios inexistentes y valores fuera de límites (1–100 series, 1–1000 reps,
peso finito 0–10000 y hasta 100 entradas, incluidos originales conservados).

La sustitución conserva todos los logs y reduce el objetivo original a sus series
registradas. La vista resumen limita el cumplimiento al objetivo de cada ejercicio;
las series extra no compensan ejercicios pendientes. `get_coaching_inputs_v1`
conserva las claves HTTP existentes, usa los objetivos del plan y busca la última
sesión cerrada anterior con logs del mismo ejercicio, incluso en otro día de rutina.

Contrato SQL reproducible: `supabase/tests/session_exercises.sql` ejecuta fixtures
con rollback. `session_exercises_fixture.sql` es exclusivamente un esquema mínimo
para una base PostgreSQL desechable; no debe ejecutarse en una base existente.
Verificación local realizada con PostgreSQL embebido PGlite; no sustituye el smoke
de las Edge Functions contra el proyecto Supabase correcto antes de publicar.

Los writes de `set_logs` adquieren el mismo bloqueo de sesión que las RPCs. Para
sesiones con plan, se rechazan logs de ejercicios ajenos, cambios de identidad
(session/exercise/set_index), cualquier cambio de logs en sesiones cerradas y
cualquier insert/update/delete de un original ya sustituido. Así, un cliente con
estado antiguo no puede alterar las series conservadas después de sustituir.
El trigger es invoker y conserva las políticas RLS existentes; los logs de sesiones
legacy sin plan conservan su comportamiento anterior.

### Smoke HTTP de ejercicios por sesión

Ejecutar `node scripts/session_exercises_smoke.mjs` con la CLI Supabase autenticada
en la cuenta con acceso al proyecto `benadgxgowycjxypyunc`. No requiere contraseña
Postgres: obtiene claves en memoria mediante la CLI, crea un usuario QA aislado con
email inválido confirmado sin enviar correo y usa su JWT para las peticiones REST,
RPC y Edge. `finally` elimina únicamente las sesiones de ese usuario, su rutina
privada y el usuario Auth creado. No imprime claves, contraseñas ni tokens, ni
escribe credenciales en `.env`. No ejecuta el script antiguo de smoke.

Verificado el 2026-10-15 contra el proyecto correcto: autenticación QA; snapshot,
sustitución parcial y extra; preservación de logs; límite de cumplimiento por
ejercicio; coaching sin reducción errónea para 40 kg frente al objetivo 38 kg;
cierre con coaching automático; resumen estricto 4/4; rechazo de objetivos después
del cierre; weekly insights. Todas las comprobaciones y la limpieza finalizaron
con PASS (exit 0).
