# 01 · Esquema de base de datos

Estado final reconstruido de `supabase/migrations/` (orden lexicográfico =
cronológico). Entre paréntesis, la migración que fija la versión final. "base"
= DDL original creado desde el dashboard, recuperado del `schema.sql` borrado
(`git show 8649e0b^:supabase/schema.sql`); **ver Verificación pendiente**.

No hay tipos `enum`: todo es `text`/`int` (+ un CHECK en `exercises.difficulty`).
No hay soft deletes ni columnas `updated_at` en ninguna tabla.

## Diagrama de relaciones

```
auth.users 1─1 profiles ──< routines (creator_id, NULL = catálogo/anonimizada)
                 │              └──< routine_days (day_of_week 1..7)
                 │                       └──< routine_exercises >── exercises (catálogo global)
                 ├─1 user_routines >── routines          (rutina activa, 1 por usuario)
                 └──< workout_sessions >── routine_days  (exercise_plan = snapshot JSONB)
                            └──< set_logs >── exercises
```

## Tablas

### `profiles`
| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | FK `auth.users(id)` ON DELETE CASCADE (20261020130000) |
| full_name | text NULL | |

- Lo crea el trigger `on_auth_user_created` → `handle_new_user()` con
  `raw_user_meta_data->>'full_name'` (ON CONFLICT DO NOTHING). El cliente
  además hace `upsert({id, full_name})` best-effort al registrarse/entrar.
- No hay avatar, preferencias ni timestamps.

### `exercises` — catálogo global, solo lectura para usuarios
| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | default `gen_random_uuid()` |
| name | text NOT NULL | sin UNIQUE (los seeds deduplican por `lower(name)`) |
| description, muscle_group | text NULL | `muscle_group` es texto libre: Pecho, Espalda, Hombros, Bíceps, Tríceps, Piernas, Pantorrillas, Glúteos, Abdomen (los seeds de mock usan además "Triceps", "Pierna") |
| image_url, animation_url, video_url | text NULL | imagen/GIF-MP4 en bucket `exercise-media`; vídeo = URL externa (20260520120000) |
| instructions, tips | text NULL | "Markdown-lite": párrafos con línea en blanco, viñetas `- ` |
| equipment | text NULL | p. ej. "Barra olímpica". **Poco poblado**: no fiable para lógica |
| difficulty | text NULL | CHECK `principiante` \| `intermedio` \| `avanzado` |

### `routines`
| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| name | text NOT NULL | |
| creator_id | uuid **NULL** | FK `profiles(id)` ON DELETE SET NULL (20261020130000). NULL = rutina de catálogo (seed) o anonimizada tras borrar cuenta: **nadie puede editarla** |
| is_public | boolean NULL default false | `true` = visible para todos ("Comunidad") |
| created_at | timestamptz default now() | no se expone en `routines_view` ni la usa el cliente |

Índice `idx_routines_creator_id`.

### `user_routines` — rutina activa
| Columna | Tipo | Notas |
|---|---|---|
| user_id | uuid **PK** | FK `profiles(id)` ON DELETE CASCADE → **una sola rutina asignada por usuario** |
| routine_id | uuid | FK `routines(id)` ON DELETE CASCADE |
| assigned_at | timestamptz default now() | |

Asignar = `upsert(..., onConflict: 'user_id')`.

### `routine_days`
| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| routine_id | uuid NOT NULL | FK `routines` ON DELETE CASCADE |
| day_of_week | int NOT NULL | CHECK 1..7, **1 = lunes … 7 = domingo** |
| name | text NOT NULL | "Torso", "Pierna"… |

- Sin UNIQUE `(routine_id, day_of_week)` (la BD admite dos días el mismo día de la semana; la UI no lo genera).
- El orden de días es `day_of_week`.

### `routine_exercises` — objetivos de la rutina
| Columna | Tipo | Default |
|---|---|---|
| id | uuid PK | |
| routine_day_id | uuid NOT NULL | FK `routine_days` CASCADE |
| exercise_id | uuid NOT NULL | FK `exercises` CASCADE |
| "order" | int NOT NULL | 0 (palabra reservada: va entre comillas) |
| target_sets | int NOT NULL | 3 |
| target_reps | int NOT NULL | 10 (un solo valor, no rango) |
| target_weight | numeric **NULL** | 0 (0 = sin carga / peso corporal) |
| rest_timer_seconds | int NOT NULL | 90 |

- UNIQUE `(routine_day_id, exercise_id)`: un ejercicio una vez por día (20260514210018).
- `"order"` sin UNIQUE; la RPC de reordenar usa base 0, los seeds base 1; al borrar quedan huecos.
- **Sin CHECKs de rango** en los objetivos.

### `workout_sessions`
| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | el cliente puede enviar su propio UUID (offline) |
| user_id | uuid NOT NULL | FK `profiles` ON DELETE CASCADE |
| routine_day_id | uuid NOT NULL* | FK `routine_days` **sin ON DELETE** (NO ACTION). *NOT NULL condicional en 20260514205817 |
| session_date | date NOT NULL default CURRENT_DATE | **fecha local** del usuario, la manda el cliente |
| completed_at | timestamptz NULL | NULL = sesión abierta. Lo pone el servidor (UTC) al finalizar |
| coaching_analysis | jsonb NULL | CHECK array o NULL. Lo escribe `finalize_workout_session_v1` |
| exercise_plan | jsonb NULL | CHECK array ≤ 100. **Snapshot** de ejercicios; solo lo escriben RPCs (trigger) |

Índices:
- `uq_workout_sessions_single_active_per_user`: UNIQUE `(user_id)` WHERE `completed_at IS NULL` → **una sola sesión abierta por usuario** (20260404143000).
- `idx_workout_sessions_user_id`, `_routine_day_id`, `_user_day_date (user_id, routine_day_id, session_date)`, `idx_sessions_user_date` (base).
- **No** hay UNIQUE `(user_id, routine_day_id, session_date)`.

Elemento de `exercise_plan`:
```json
{"id":"<exercise_id>","routine_day_id":"…","name":"Press banca","muscle_group":"Pecho",
 "target_sets":3,"target_reps":10,"target_weight":60,"rest_timer_seconds":90,
 "is_extra":false,"replaces_exercise_name":null,"replaced_by_exercise_name":null}
```

Elemento de `coaching_analysis` (formato del servidor):
```json
{"exercise_id":"…","exercise_name":"Press banca","completed_sets":3,"target_sets":3,
 "weight_met":true,"reps_met":true,"recommendation":"INCREASE_WEIGHT",
 "feedback":"Superaste tu sesión anterior, sube el peso ligeramente.","performance_score":1.05}
```
`recommendation` ∈ `MAINTAIN | INCREASE_WEIGHT | INCREASE_REPS | DECREASE_WEIGHT`
(datos antiguos pueden traer `MANTAIN_WEIGHT`). El lector Dart acepta claves en
snake_case **o** camelCase.

### `set_logs`
| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | no se envía en el upsert |
| session_id | uuid NOT NULL | FK `workout_sessions` CASCADE |
| exercise_id | uuid NOT NULL | FK `exercises` CASCADE (apunta al ejercicio, no a `routine_exercises`) |
| set_index | int NOT NULL | **base 1** por convención; CHECK ≥ 0 |
| actual_weight | numeric NOT NULL default 0 | CHECK ≥ 0; 0 = peso corporal |
| actual_reps | int NOT NULL default 0 | CHECK ≥ 0 |
| created_at | timestamptz default now() | lo pone el servidor; ordena "última vez" |

- UNIQUE `uq_set_logs_session_exercise_set_index (session_id, exercise_id, set_index)`.
- Índices por `session_id`, `exercise_id`, `(session_id, created_at)`, `(exercise_id, created_at DESC)`.
- Sin RPE/RIR, notas ni `updated_at`.

### `function_rate_limits` (interna)
`(user_id, function_name, window_start)` PK, `count`. RLS activo **sin
políticas** → solo `service_role`. La usan las Edge Functions vía
`enforce_rate_limit`.

## Vistas

### `routines_view` (security_invoker)
`id, name, is_public, creator_id, creator_name (profiles.full_name), exercise_count`
(nº de `routine_exercises` en todos los días). GRANT SELECT a `authenticated` y
`anon`. Aplica la RLS de `routines`: el usuario ve públicas + propias.

### `view_workout_sessions_summary` (security_invoker)
`id, user_id, routine_day_id, session_date, completed_at, coaching_analysis,
total_target_sets, total_completed_sets, is_strictly_completed`
(**no** expone `exercise_plan`).

| | Sesión con snapshot (`exercise_plan` no nulo) | Sesión legacy (sin snapshot) |
|---|---|---|
| total_target_sets | Σ `target_sets` del plan | Σ `target_sets` **actuales** de `routine_exercises` del día |
| total_completed_sets | Σ por ejercicio `LEAST(target_sets, nº logs)` | nº total de logs (sin tope) |
| is_strictly_completed | `completed_at` no nulo y done ≥ target | igual |

## RLS (final)

RLS activo en todas las tablas de `public`.

| Tabla | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| profiles | propio, o creador de una rutina visible para mí | `uid = id` | `uid = id` | — |
| exercises | todos (`true`) | — | — | — |
| routines | `is_public` o `uid = creator_id` | `uid = creator_id` | `uid = creator_id` | `uid = creator_id` |
| user_routines | `uid = user_id` | ídem | ídem | ídem |
| routine_days | rutina padre visible | rutina padre mía | rutina padre mía | rutina padre mía |
| routine_exercises | rutina (vía día) visible | rutina mía | rutina mía | rutina mía |
| workout_sessions | `uid = user_id` | `uid = user_id` | `uid = user_id` | **ninguna** (a propósito: descartar = RPC) |
| set_logs | sesión mía | sesión mía | sesión mía | sesión mía (20260911090000) |
| function_rate_limits | — | — | — | — |

Notas:
- Un UPDATE/DELETE bloqueado por RLS **no da error**: afecta 0 filas.
- `sessions_update` permite al cliente tocar `completed_at`/`coaching_analysis`
  directamente (incluso reabrir). El cliente actual no lo hace: cierra por la
  Edge Function.
- Si una rutina asignada deja de ser visible (el dueño la hace privada, o queda
  anonimizada y privada), el usuario asignado pierde la lectura de días y ejercicios.

## Triggers

| Trigger | Tabla | Qué hace |
|---|---|---|
| `on_auth_user_created` → `handle_new_user()` | `auth.users` AFTER INSERT | crea `profiles(id, full_name)`. **Creado en el dashboard, no está en migraciones** |
| `guard_session_exercise_plan_v1` | `workout_sessions` BEFORE INSERT/UPDATE | si el rol es `authenticated`/`anon` y se intenta escribir `exercise_plan` → `42501 'exercise_plan is managed by session RPCs'` |
| `guard_session_set_log_v1` | `set_logs` BEFORE INSERT/UPDATE/DELETE | si la sesión tiene snapshot: rechaza sesión cerrada (`'session closed'`), ejercicio fuera del plan, tocar logs de un original sustituido (`'retained original logs are immutable'`) y cambiar la identidad del log. Todo con `23514`. Sesiones legacy: sin restricción |

## Storage

Bucket `exercise-media` (20260520120100): **público**, 10 MB, png/jpeg/webp/gif/mp4/webm.
Lectura para todos (`exercise_media_read_all`); escritura solo `service_role`.
URL pública: `https://<ref>.supabase.co/storage/v1/object/public/exercise-media/<path>`.

## Verificación pendiente

Las migraciones empiezan con `ALTER` sobre tablas ya existentes: el DDL base
(tablas, FKs originales, `profiles_insert`, `sessions_*`, `set_logs_select/insert`,
`exercises_select`, el trigger `on_auth_user_created`, `idx_sessions_user_date`)
solo consta en el `schema.sql` borrado y en el dashboard. Antes de dar por
cerrado este documento, contrastar con producción:

```bash
supabase db dump --linked --schema public -f /tmp/schema_prod.sql   # por defecto solo esquema
```

y revisar especialmente: NOT NULL de `workout_sessions.routine_day_id`, la
existencia del trigger `on_auth_user_created` y las políticas `sessions_*`.
Idealmente, convertir ese dump en una migración "baseline" para que el repo
pueda recrear la base desde cero.
