# 02 · API de servidor: RPCs y Edge Functions

Lo que hay más allá del CRUD de tablas. Versión final de cada objeto; cuando la
documentación previa (`docs/EDGE_FUNCTIONS.md`, READMEs) difiere, manda el código
y se marca **[DISCREPANCIA]**.

## Convenciones

**RPC**: `POST /rest/v1/rpc/<nombre>` con cabeceras `apikey`,
`Authorization: Bearer <access_token>` y `Content-Type: application/json`; el body
son los parámetros por nombre (`{"p_session_id":"…"}`). Usar siempre **POST**
(`supabase.rpc()` ya lo hace): varias RPCs escriben o hacen `FOR UPDATE`.

Error de PostgREST: `{"code":"<SQLSTATE>","message":"<texto>","details":null,"hint":null}`.
Status orientativos: `42501`→403, `23503`/`23505`→409, `23514`/`22004`→400,
`P0002`→500(P0), función inexistente→404 `PGRST202`, `.single()` sin filas→406 `PGRST116`.
**Decidir por `code`, no por status.**

Todas las RPCs son `SECURITY DEFINER` con `search_path = public` y validan
`auth.uid()`: un cliente solo puede operar sobre sus datos aunque pase otro
`p_user_id`.

## RPCs

| RPC | Parámetros | Devuelve | La llama |
|---|---|---|---|
| `get_last_exercise_performances` | `p_user_id uuid, p_exercise_ids uuid[]` (≤100) | filas `{id, session_id, exercise_id, set_index, actual_weight, actual_reps, created_at}` | cliente |
| `get_session_exercises_v1` | `p_session_id uuid` | jsonb array (plan) | cliente |
| `adapt_session_exercise_v1` | `p_session_id, p_exercise_id, p_target_sets int, p_target_reps int, p_target_weight numeric, p_replace_exercise_id uuid = null` | jsonb array (plan) | cliente |
| `update_session_exercise_target_v1` | `p_session_id, p_exercise_id, p_target_weight numeric, p_target_reps int` | jsonb array (plan) | cliente |
| `discard_workout_session_v1` | `p_session_id uuid` | boolean | cliente |
| `fork_routine_v1` | `p_source_routine_id uuid, p_new_name text = null` | uuid (string JSON) | cliente |
| `reorder_routine_exercises` | `p_day_id uuid, p_ordered_ids uuid[]` (**exercise_ids**) | void | cliente |
| `get_coaching_inputs_v1` | `p_user_id, p_session_id` | jsonb | Edge `generate_coaching_v1` |
| `compute_weekly_insights_v1` | `p_user_id, p_routine_id, p_week_start date = null` | 1 fila | Edge `get_weekly_insights_v1` |
| `get_last_exercise_performance` | `p_user_id, p_exercise_id` | jsonb | **nadie** (legacy) |
| `enforce_rate_limit` | `p_user_id, p_function, p_window_seconds, p_max_calls` | `{allowed, current_count, reset_at}` | solo `service_role` |
| `delete_account_data_v1` | `p_user_id` | jsonb con conteos | solo `service_role` |

### `get_last_exercise_performances`
Último set_log (por `created_at` DESC, `DISTINCT ON exercise_id`) de cada
ejercicio pedido, en **cualquier** sesión del usuario — **incluida la abierta**.
Es "la última serie que hiciste", no la mejor. Gate: `p_user_id` debe ser
`auth.uid()` → si no `42501 'forbidden: p_user_id mismatch'`.

### `get_session_exercises_v1` — snapshot de la sesión
- Dueño distinto o sesión inexistente → `42501 'forbidden: session ownership'`.
- Si la sesión ya tiene `exercise_plan`, lo devuelve.
- Si no, lo construye desde `routine_exercises` del día (orden `"order"`, `id`)
  y, **si la sesión está abierta, lo persiste** (lectura con efecto lateral,
  bloquea la fila con `FOR UPDATE`). Más de 100 → `23514 'too many exercises'`.
- Desde ese momento, editar la rutina **no** cambia el entrenamiento en curso.
- Entradas con `target_sets = 0` son originales sustituidos sin series pendientes: el cliente las oculta.

### `adapt_session_exercise_v1` — añadir extra o sustituir
Validaciones en orden (todas sobre el snapshot, nunca toca la rutina):

| Error | SQLSTATE |
|---|---|
| ownership | 42501 |
| `session closed` | 23514 |
| `invalid exercise targets` (sets 1..100, reps 1..1000, peso 0..10000, no NaN) | 23514 |
| `exercise not found` | 23503 |
| `exercise already in session` | 23505 |
| `too many exercises` (≥100) | 23514 |
| `replacement source missing` | 23503 |
| `no remaining sets` (el original ya completó sus series) | 23514 |

- Sin `p_replace_exercise_id`: añade entrada `is_extra: true`.
- Con él: el original queda con `target_sets` = series ya hechas y
  `replaced_by_exercise_name`; el nuevo lleva `replaces_exercise_name` y hereda `is_extra`.
- `rest_timer_seconds` de entradas nuevas: siempre 90.

### `update_session_exercise_target_v1`
Cambia `target_weight`/`target_reps` de una entrada activa (`target_sets > 0`)
del snapshot. Errores: 42501, `session closed` 23514, `invalid exercise targets`
23514, `active exercise not found` 23503.

### `discard_workout_session_v1`
1. `auth.uid()` nulo → `42501 not_authorized`.
2. `SELECT … FOR UPDATE`; si no existe → **`false`** (idempotente).
3. Ajena → `P0002 session_not_found`. Cerrada → `23514 session_already_completed`.
4. Pone `exercise_plan = NULL` y borra `set_logs` + la sesión → `true`.

✅ **B1 arreglado** (`20261021120000_fix_discard_session_with_replaced_exercise.sql`,
pendiente de desplegar): antes, si la sesión abierta tenía un original
**sustituido con series**, el trigger `guard_session_set_log_v1` rechazaba el
`DELETE` de esos logs (`23514 retained original logs are immutable`) y el
descarte fallaba. Ahora se quita el plan antes de borrar, como
`delete_account_data_v1`. Test: `supabase/tests/discard_workout_session.sql`.

### `fork_routine_v1`
Copia una rutina **visible** (pública o propia) como privada del usuario:
`routines(name, is_public=false, creator_id=uid)` + días (`day_of_week`, `name`)
+ ejercicios (`order`, objetivos, descanso). Nombre: `p_new_name` (trim) o
`"<nombre> (mi copia)"`. **No la asigna.** Errores: sin sesión →
`28000`; no visible → `42501`.

### `reorder_routine_exercises`
`"order" = posición − 1` (base 0) para cada `exercise_id` del array que
pertenezca al día; ids ajenos se ignoran. Errores: `42501 not_authorized`
(sin sesión, o la rutina no es tuya / anonimizada), `P0002 routine_day_not_found`.

### `get_coaching_inputs_v1`
Devuelve `{session, current_logs[{exercise_id, actual_weight, actual_reps, set_index, name}],
routine_exercises[{exercise_id, target_sets, target_reps, target_weight}],
previous_logs[…]}`. `previous_logs`: por ejercicio, los logs de la última sesión
**cerrada** con `session_date` anterior que contenga ese ejercicio, **de cualquier
día o rutina**. Sesión ajena → `session: null` (sin error).

### `compute_weekly_insights_v1`
Semana = `p_week_start` o, si es null, lunes **UTC** actual; `week_end = +6`.
| Campo | Cálculo |
|---|---|
| planned_days | nº de `routine_days` de la rutina |
| completed_days | días distintos con ≥1 sesión **cerrada** en la semana |
| completed_sessions | nº de sesiones cerradas |
| adherence_rate | `round(completed_days / planned_days × 100, 2)` (**0–100**) |
| total_volume / previous_week_volume | Σ peso×reps de la semana / la anterior, **incluye sesiones abiertas** |
| volume_trend_percent | 100 si la previa es 0 y la actual >0; 0 si ambas 0; si no `round((v−p)/p×100, 2)` |
| personal_records | nº de ejercicios cuyo máximo de la semana supera el máximo histórico previo (>0) |

**[DISCREPANCIA]** Los docs dicen que verifica la propiedad de la rutina: no lo
hace (solo filtra las sesiones del usuario; con un `routine_id` ajeno filtra el
nº de días de esa rutina).

## Edge Functions

### Común a las cuatro (`supabase/functions/_shared/`)

- `verify_jwt = true` (`supabase/config.toml`) + revalidación con
  `admin.auth.getUser(token)`.
- Cabeceras del cliente: `Authorization: Bearer <access_token>`,
  `apikey: <anon/publishable>`, `Content-Type: application/json`.
- **CORS**: `Access-Control-Allow-Origin: *`,
  `Allow-Headers: authorization, x-client-info, apikey, content-type`,
  `Allow-Methods: POST, OPTIONS`. Una web en otro dominio funciona, pero **no
  añadas cabeceras propias** o fallará el preflight.
- Respuesta: `{"success": bool, "code": "…", "data"?: {…}, "error"?: {"message": "…", …}}`.
- Errores comunes:

| Status | code | Cuándo |
|---|---|---|
| 401 | `UNAUTHORIZED` | falta/vacío/expirado el Bearer. (El 401 del gateway puede venir con otra forma: `{"code":401,"message":"Invalid JWT"}`) |
| 405 | `METHOD_NOT_ALLOWED` | método ≠ POST/OPTIONS |
| 400 | `INVALID_JSON` | body no parseable |
| 429 | `RATE_LIMIT_EXCEEDED` | `error: {message, reset_at, limit, window_seconds}` |

- Rate limit (ventana fija de 60 s, se cuenta antes de parsear el body; si la
  RPC de límite falla, deja pasar): finalize 30, generate_coaching 30,
  weekly_insights 60, delete_account 5.

### `finalize_workout_session_v1`
Cierra la sesión y guarda el coaching.

Request: `{"session_id": "uuid"}`
- Siempre llama a `generate_coaching_v1` (consume su rate limit); si falla,
  cierra igualmente y añade `warning_code: "COACHING_GENERATION_FAILED"`.
- ✅ **B2 arreglado** (pendiente de desplegar): un `coaching_analysis` enviado
  por el cliente **se ignora** (antes se guardaba tal cual, sin validar).
  Mandarlo no es un error.
- Hace `UPDATE workout_sessions SET completed_at = now(), coaching_analysis = …
  WHERE id = … AND user_id = <jwt> AND completed_at IS NULL`.

200:
```json
{"success":true,"code":"SESSION_COMPLETED","data":{"session_id":"…",
 "summary":{"id":"…","user_id":"…","routine_day_id":"…","session_date":"2026-10-21",
  "completed_at":"…","total_target_sets":5,"total_completed_sets":5,"is_strictly_completed":true},
 "warning_code":"COACHING_GENERATION_FAILED"}}
```
(`summary` y `warning_code` opcionales.)

| Status | code |
|---|---|
| 400 | `VALIDATION_ERROR` (`session_id is required`) |
| 404 | `NOT_FOUND_OR_COMPLETED` (no existe, ajena o ya cerrada) |
| 500 | `DB_UPDATE_ERROR` |

**Idempotencia**: un segundo intento da 404. El cliente, ante 404, relee
`workout_sessions.completed_at` y si no es null lo trata como éxito.
✅ **B3 arreglado**: el cliente Dart reconoce `NOT_FOUND_OR_COMPLETED` (y sigue
aceptando el antiguo `NOT_FOUND_OR_ALREADY_COMPLETED`). Antes, como el 404 de
la función trae `code` en el body, el invoker no aplicaba el mapeo por status
y el error quedaba como `FINALIZE_FUNCTION_ERROR_404`: el reintento tras
perder la respuesta no se trataba como éxito y el SyncWorker no descartaba la
mutación.

### `generate_coaching_v1`
Request `{"session_id":"uuid"}`. **No persiste nada.** Funciona con sesiones
abiertas o cerradas. Algoritmo por ejercicio (medias de peso y reps, sesión
actual vs previa de `get_coaching_inputs_v1`):

| Condición (en orden) | recommendation | score |
|---|---|---|
| series hechas < objetivo | `MAINTAIN` | 0.65 |
| sin historial y reps ≥ objetivo | `INCREASE_WEIGHT` | 1.0 |
| sin historial y reps < objetivo | `INCREASE_REPS` | 0.85 |
| peso medio sube y reps ≥ previas | `INCREASE_WEIGHT` | 1.05 |
| peso ≥ previo y reps < objetivo | `INCREASE_REPS` | 0.88 |
| peso ≤ objetivo y reps < `max(4, 0.6·target_reps)` | `DECREASE_WEIGHT` | 0.55 |
| resto | `MAINTAIN` | 0.9 |

200: `{"success":true,"code":"COACHING_GENERATED","data":{"session_id":"…","analysis":[…]}}`.
Errores: 400 `VALIDATION_ERROR`, 404 `SESSION_NOT_FOUND`, 500 `COACHING_INPUTS_ERROR`.
El cliente actual **no la llama directamente**.

### `get_weekly_insights_v1`
Request `{"routine_id":"uuid","week_start":"YYYY-MM-DD"}` (`week_start`
opcional pero **mándalo siempre**: el lunes **local**; no se fuerza a lunes).
Solo lectura sobre `compute_weekly_insights_v1`.

200:
```json
{"success":true,"code":"WEEKLY_INSIGHTS_READY","data":{"week_start":"2026-10-19","week_end":"2026-10-25",
 "planned_days":2,"completed_days":1,"completed_sessions":1,"adherence_rate":50,
 "total_volume":1770,"previous_week_volume":0,"volume_trend_percent":100,"personal_records":1}}
```
Errores: 400 `VALIDATION_ERROR` (`routine_id is required` / `week_start must be YYYY-MM-DD`),
500 `INSIGHTS_RPC_ERROR` (p. ej. uuid inválido).

### `delete_account_v1`
Request `{"confirm":"ELIMINAR"}` (literal exacto).
1. `delete_account_data_v1(<uid del JWT>)` (service_role, transaccional, lock por usuario):
   anula `exercise_plan`, borra series, sesiones y asignación; **anonimiza**
   (`creator_id = NULL`) rutinas públicas o usadas por otros; borra el resto de
   rutinas privadas; borra rate limits y perfil.
2. `auth.admin.deleteUser(uid)` (un reintento).

200: `{"success":true,"code":"ACCOUNT_DELETED","data":{"user_id":"…","deleted":{"set_logs":…,"workout_sessions":…,"user_routines":…,"routines_anonymized":…,"routines_deleted":…,"routine_days_deleted":…,"routine_exercises_deleted":…,"rate_limits":…,"profiles":…}}}`

| Status | code | Significado |
|---|---|---|
| 400 | `CONFIRMATION_REQUIRED` | `confirm` ≠ "ELIMINAR" |
| 500 | `DELETE_ACCOUNT_DATA_ERROR` | no se borró nada |
| 500 | `DELETE_AUTH_USER_ERROR` | datos borrados, usuario no; reintentar es seguro |

Tras el éxito el JWT deja de valer: el cliente debe cerrar sesión y limpiar su estado local.

## Smoke de contrato

`bash scripts/contract_smoke_supabase.sh` (requiere `supabase` CLI autenticado,
`psql`, `jq`, `SUPABASE_DB_PASSWORD`): crea un usuario real, siembra datos y
prueba generate/finalize/insights + negativos (sin token, JWT falso, IDOR a la
RPC). **No** cubre `delete_account_v1` ni borra el usuario de prueba.
