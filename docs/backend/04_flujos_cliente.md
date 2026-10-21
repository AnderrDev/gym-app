# 04 · Cómo usa el backend el cliente actual

Cada operación del cliente Flutter con la llamada exacta, para replicarla en la
web. Notación supabase-js. Origen: `lib/features/*/data/datasources/`.

## Rutinas y catálogo

| Operación | Llamada |
|---|---|
| Listar rutinas (mías + públicas) | `from('routines_view').select('id, name, exercise_count, is_public, creator_id, creator_name').or('is_public.eq.true,creator_id.eq.<uid>').order('name').range(0, 99)` |
| Una rutina | `from('routines_view').select(<ídem>).eq('id', id).single()` |
| Rutina asignada (activa) | `from('user_routines').select('routine_id, routines(id, name, is_public, creator_id)').eq('user_id', uid)` |
| Asignar rutina | `from('user_routines').upsert({user_id, routine_id}, {onConflict: 'user_id'})` (reemplaza la anterior) |
| Crear rutina | `from('routines').insert({name, is_public, creator_id: uid}).select('id, name, is_public, creator_id').single()` |
| Editar rutina | `from('routines').update({name, is_public}).eq('id', id).select(<ídem>).single()` |
| Borrar rutina | `from('routines').delete().eq('id', id).select('id')` → 0 filas = no es tuya / no existe |
| Copiar rutina | `rpc('fork_routine_v1', {p_source_routine_id, p_new_name?})` |
| Catálogo de ejercicios | `from('exercises').select('id, name, description, muscle_group')[.eq('muscle_group', g)][.ilike('name', '%q%')].order('name').limit(200)` |
| Detalle de ejercicio | `from('exercises').select('id, name, muscle_group, description, image_url, animation_url, video_url, instructions, tips, equipment, difficulty').eq('id', id).single()` |

> El cliente busca en el catálogo sin tildes y en minúsculas **en local**;
> `ilike` del servidor no normaliza tildes.

## Días y ejercicios de una rutina

| Operación | Llamada |
|---|---|
| Días con ejercicios | `from('routine_days').select('id, routine_id, day_of_week, name, routine_exercises(target_sets, target_reps, target_weight, rest_timer_seconds, "order", exercises(id, name, muscle_group))').eq('routine_id', rid).order('day_of_week')` — **ordenar el embebido por `order` en el cliente** (PostgREST no lo garantiza) |
| Ejercicios de un día | `from('routine_exercises').select('id, target_reps, target_weight, target_sets, rest_timer_seconds, exercises(id, name, muscle_group)').eq('routine_day_id', dayId).order('order')` — descartar filas con `exercises` null |
| Crear / editar día | `insert({name, day_of_week, routine_id})` / `update({name, day_of_week}).eq('id', id)` + `.select('id, routine_id, day_of_week, name').single()`. El editor propone el primer `day_of_week` libre (1..7) |
| Borrar día | `from('routine_days').delete().eq('id', id).select('id')` |
| Añadir ejercicio(s) | `order` = `max(order)+1` (o 0) leído antes; `upsert([{routine_day_id, exercise_id, order, target_sets: 3, target_reps: 10, target_weight: 0, rest_timer_seconds: 90}], {onConflict: 'routine_day_id,exercise_id', ignoreDuplicates: true})` |
| Quitar ejercicio | `delete().eq('routine_day_id', d).eq('exercise_id', e).select('exercise_id')` |
| Reordenar | `rpc('reorder_routine_exercises', {p_day_id, p_ordered_ids: [exercise_id…]})` |
| Cambiar objetivos | `update({target_weight, target_reps, target_sets?, rest_timer_seconds?}).match({routine_day_id, exercise_id}).select('exercise_id')` |

Regla: **todo UPDATE/DELETE pide `.select()`** y trata 0 filas como "no
encontrado o sin permiso" (RLS no lanza error).

## Ciclo de vida de un entrenamiento

```
[Previa] ──Iniciar──▶ startWorkout ──▶ get_session_exercises_v1 (congela snapshot)
                                          │
              ┌─────────── upsert set_logs / delete set_logs ◀──┘
              │            adapt_session_exercise_v1 / update_session_exercise_target_v1
              ▼
   Finalizar: Edge finalize_workout_session_v1 ──▶ leer coaching_analysis
   Descartar: rpc discard_workout_session_v1
```

### Iniciar (`startWorkoutForDay`)
1. ¿Hay sesión abierta del usuario? `from('workout_sessions').select('id, user_id, routine_day_id, session_date, completed_at').eq('user_id', uid).is('completed_at', null).order('session_date', {ascending: false}).limit(1).maybeSingle()` → si existe, **se devuelve esa** (aunque sea de otro día).
2. ¿Existe ya sesión para (día, hoy)? `from('view_workout_sessions_summary').select('id, user_id, routine_day_id, session_date, completed_at, total_target_sets, total_completed_sets').eq('user_id', uid).eq('routine_day_id', dayId).eq('session_date', hoy).maybeSingle()` → si existe, se devuelve.
3. Si no: `from('workout_sessions').insert({user_id, routine_day_id, session_date: hoy, id?}).select(<base>).single()`.

Después la UI **rechaza** si la sesión devuelta es de otro día ("Ya hay una
sesión activa en otro día. Termínala antes de iniciar esta.") o de otra fecha
("Hay una sesión anterior pendiente…"). `hoy` = fecha **local** `YYYY-MM-DD`.
El índice único parcial garantiza una sola abierta; un insert concurrente da `23505`.

### Durante la sesión
| Operación | Llamada |
|---|---|
| Ejercicios de la sesión | `rpc('get_session_exercises_v1', {p_session_id})` (ocultar entradas con `target_sets = 0`) |
| Series registradas | `from('set_logs').select('id, session_id, exercise_id, set_index, actual_weight, actual_reps, created_at').eq('session_id', sid).order('created_at')` |
| "Última vez" | `rpc('get_last_exercise_performances', {p_user_id: uid, p_exercise_ids: [≤100]})` — quedarse con la primera fila por ejercicio |
| Registrar / editar serie | `from('set_logs').upsert({session_id, exercise_id, actual_weight, actual_reps, set_index}, {onConflict: 'session_id,exercise_id,set_index'})` (sin `id` ni `created_at`) |
| Desmarcar serie | `from('set_logs').delete().eq('session_id', s).eq('exercise_id', e).eq('set_index', i)` |
| Añadir extra / sustituir | `rpc('adapt_session_exercise_v1', {…})` |
| Cambiar objetivo solo hoy | `rpc('update_session_exercise_target_v1', {…})` |

`set_index` es **1..target_sets**; la siguiente serie es el primer índice libre.
La UI marca la serie al instante y la revierte si el upsert falla.

### Finalizar
`functions.invoke('finalize_workout_session_v1', {body: {session_id}, headers: {Authorization: 'Bearer ' + accessToken}})`
(sin `coaching_analysis`: lo genera el servidor). Si responde 404, releer
`from('workout_sessions').select('completed_at').eq('id', sid).maybeSingle()`:
si `completed_at` no es null, es éxito (reintento). Luego leer el coaching:
`from('workout_sessions').select('coaching_analysis').eq('id', sid).maybeSingle()`.

### Descartar
`rpc('discard_workout_session_v1', {p_session_id})`. `23514` → "ya se finalizó",
`P0002` → no encontrada. El cliente móvil solo lo permite online y con su cola
offline vacía.

## Historial, progreso y estadísticas

| Operación | Llamada |
|---|---|
| Sesiones de una semana | `from('view_workout_sessions_summary').select(<summary>).eq('user_id', uid).gte('session_date', lunes).lte('session_date', lunes+6)` |
| Últimas 3 sesiones del mismo día (coaching en vivo / resumen) | `…summary.eq('user_id').eq('routine_day_id').lt('session_date', hoy).not('completed_at', 'is', null).order('session_date', desc).limit(3)` |
| Series de varias sesiones | `from('set_logs').select(<cols>).in('session_id', ids).order('created_at')` |
| Detalle de sesión pasada | en paralelo: series de la sesión + `get_session_exercises_v1` + `coaching_analysis` |
| Historial de un ejercicio | `from('set_logs').select('id, session_id, exercise_id, actual_weight, actual_reps, set_index, created_at, workout_sessions!inner(session_date, completed_at)').eq('exercise_id', e).eq('workout_sessions.user_id', uid).not('workout_sessions.completed_at', 'is', null).order('created_at', desc).limit(365)` → agrupar por `session_date` |
| Estadísticas de una rutina | `from('workout_sessions').select('id, session_date, routine_day_id, routine_days!inner(name, routine_id), set_logs(actual_weight, actual_reps)').eq('user_id', uid).eq('routine_days.routine_id', rid).not('completed_at', 'is', null).order('session_date')` |
| Insights semanales | Edge `get_weekly_insights_v1` `{routine_id, week_start}`. El cliente lo pide por cada rutina asignada y la pestaña Progreso los suma, aunque la BD solo admite **una** asignación por usuario (el código y el backend de pruebas sí contemplan varias) |

## Mapeo de errores recomendado

| `code` | Significado | Mensaje (es) |
|---|---|---|
| `PGRST116`, `PGRST106` | no encontrado | "No se encontró lo que buscabas. Puede que se haya borrado." |
| `23505` | duplicado | "Eso ya existe." (en sesión: "Ese ejercicio ya está en esta sesión.") |
| `42501` | sin permiso | "No tienes permiso para hacer esto." |
| `PGRST301`, `PGRST303` | JWT caducado | "Tu sesión expiró. Vuelve a iniciar sesión." |
| `23514`, `22P02` | validación | "Hay datos no válidos. Revísalos e inténtalo de nuevo." |
| `23503` | referencia rota | "El elemento relacionado ya no existe." |
| Edge `NOT_FOUND_OR_COMPLETED`, `SESSION_NOT_FOUND` | no encontrado | |
| Edge `VALIDATION_ERROR`, `INVALID_JSON`, `COACHING_TOO_LARGE` | validación | |
| Edge `UNAUTHORIZED` | auth | |
| Edge `RATE_LIMIT_EXCEEDED` | límite | usar `error.reset_at` |
| error de red / timeout | red | "Sin conexión con el servidor…" |

## Offline: qué hace el móvil y qué puede omitir la web

El móvil es *online-first* con respaldo offline:
- Caché SWR en SQLite (drift) de: rutina asignada, días, ejercicios del día,
  "última vez", sesiones de la semana, insights, series y sesión abierta.
- Cola (`pending_mutations`) solo cuando no hay red o falla por red:
  `insertSession` (con UUID del cliente), `upsertSetLog`, `deleteSetLog`,
  `finalizeSession`. Se envía en FIFO estricto, de una en una, con backoff
  exponencial (máx. 5 min); se descartan `23505` en `insertSession`,
  `PGRST116`, códigos de "no encontrado" y de validación; los errores de auth
  pausan la cola hasta re-login.

La web puede **omitir** la caché y la cola. Si se quiere robustez en el
gimnasio (cobertura mala), basta una cola mínima en IndexedDB para
upsert/delete de series y finalizar, en FIFO, y bloquear "Descartar" mientras
tenga elementos. El estado "hay sesión en curso" se reconstruye siempre con
`workout_sessions` donde `completed_at IS NULL`.
