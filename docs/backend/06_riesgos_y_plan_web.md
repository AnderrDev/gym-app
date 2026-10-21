# 06 · Riesgos detectados y plan para la web nativa

Hallazgos del mapeo (2026-10-21). Marcados como **verificado** los que se
comprobaron leyendo el código; el resto son inferencias de las migraciones a
confirmar contra producción.

## Bugs

| # | Problema | Impacto | Estado |
|---|---|---|---|
| B1 | `discard_workout_session_v1` no anula `exercise_plan` antes de borrar series. Si la sesión abierta tiene un ejercicio **sustituido con series**, el trigger `guard_session_set_log_v1` rechaza el borrado (`23514 retained original logs are immutable`) | No se puede descartar ese entrenamiento; el cliente muestra "ya se finalizó" | ✅ **arreglado** (2026-10-21) en `20261021120000_fix_discard_session_with_replaced_exercise.sql` + test `supabase/tests/discard_workout_session.sql`. **Pendiente de desplegar** |
| B2 | `finalize_workout_session_v1` acepta `coaching_analysis` del cliente y lo guarda sin validar (array ≤ 64 KB) | Coaching falsificable / basura en historial | ✅ **arreglado** (2026-10-21): la función ignora el valor del cliente y genera siempre en servidor. **Pendiente de desplegar**. El hueco por PostgREST (`sessions_update` dejaba escribir `coaching_analysis`/`completed_at` directamente) queda cerrado con el trigger `guard_session_completion_v1` (`20261021130000_guard_session_completion_columns.sql` + test `supabase/tests/session_completion_guard.sql`). **Pendiente de desplegar** |
| B3 | El servidor devuelve `NOT_FOUND_OR_COMPLETED`; el cliente Dart espera `NOT_FOUND_OR_ALREADY_COMPLETED` | El 404 de la función trae `code`, así que el invoker no usaba el mapeo por status: quedaba `FINALIZE_FUNCTION_ERROR_404`, el reintento no se trataba como éxito y el SyncWorker reintentaba en vez de descartar | ✅ **arreglado** (2026-10-21) en el cliente: acepta `NOT_FOUND_OR_COMPLETED` y el código antiguo. Sale con la próxima build |
| B4 | El motor de coaching en vivo guarda `recommendation`/`feedback` cruzados respecto al servidor | `hasActionableAdvice` y el icono del badge evalúan mal según el origen | verificado en código |
| B5 | `compute_weekly_insights_v1` no comprueba que la rutina sea visible o del usuario | Fuga menor: nº de días de una rutina ajena | inferido |
| B6 | Un fallo de red al llamar a una Edge Function se clasifica como error de servidor (`*_RUNTIME_ERROR`), no de red | En móvil, finalizar con la red caída no cae a la cola offline (salvo timeout) | inferido del cliente |

## Discrepancias cliente ↔ servidor

1. **Tres motores de coaching** con algoritmos, historial y escalas distintas: el
   resumen previo puede decir "¡SUPERACIÓN!" y el guardado `MAINTAIN`.
2. **Récords**: el resumen compara con la sesión anterior del mismo día; el
   insight semanal, con todo el histórico de la rutina.
3. **Volumen semanal**: el servidor incluye sesiones abiertas; las gráficas del cliente solo cerradas.
4. **Completado de sesiones legacy** (sin snapshot): usa los objetivos *actuales*
   de la rutina y no topa series extra → editar la rutina cambia estados pasados.
5. **Semana por defecto**: UTC en servidor, local en cliente (hoy no afecta porque el cliente siempre manda `week_start`).
6. **Asignación**: la BD admite una rutina activa por usuario, pero el cliente
   modela una lista y suma insights de "todas".
7. **Topes de validación** distintos en formularios (1000 kg / 999 reps), hoja
   de serie (10000 / 1000), editor (20 series / 50 reps), RPCs (100 / 1000 / 10000)
   y BD (solo ≥ 0; sin CHECKs en `routine_exercises`).

## Riesgos de esquema

- **DDL base fuera del repo** (tablas originales, trigger `on_auth_user_created`,
  algunas políticas). Hacer un dump de producción y crear una migración baseline.
- `workout_sessions.routine_day_id` sin `ON DELETE`: borrar un día o rutina con
  historial falla por FK (por eso las cuentas borradas anonimizan en vez de borrar).
- `set_logs.exercise_id` y `routine_exercises.exercise_id` en CASCADE: borrar un
  ejercicio del catálogo **borra historial**.
- Sin UNIQUE `(user_id, routine_day_id, session_date)`: un segundo cliente puede
  crear duplicados y el `maybeSingle()` de "sesión existente" fallaría.
- ~~`sessions_update` permite reabrir una sesión desde el cliente (`completed_at = NULL`).~~ Cerrado por `guard_session_completion_v1` (20261021130000, desplegada 2026-10-21).
- Rutina asignada que deja de ser visible → el usuario pierde lectura de sus días.
- Configuración de Auth solo en el dashboard; **Site URL aún en localhost**.

## Plan recomendado para la web nativa

### Antes de empezar (backend)
1. Dump del esquema de producción → migración baseline + revisar [01](01_esquema.md#verificación-pendiente).
2. ~~Arreglar **B1** y **B2**; unificar el código de **B3**.~~ Hecho y desplegado (2026-10-21): migraciones `20261021120000` y `20261021130000` y función `finalize_workout_session_v1`.
3. Site URL = dominio definitivo de la web; añadir `<web>/reset-password` y
   `localhost` a Redirect URLs.
4. Generar tipos: `supabase gen types typescript --linked > src/lib/database.types.ts`
   (dará tipado a tablas, vistas y RPCs; los JSONB `exercise_plan` y
   `coaching_analysis` hay que tiparlos a mano con [01](01_esquema.md)).

### Mover lógica al servidor (para no duplicarla en TypeScript)
| Propuesta | Sustituye | Prioridad |
|---|---|---|
| RPC `start_workout_session_v1(p_routine_day_id, p_session_date)` con las reglas de sesión activa / misma fecha y errores con código | lógica de inicio en cliente (§3 de [05](05_logica_cliente.md)) | Alta |
| RPC `get_weekly_plan_v1(p_routine_id, p_week_start)` → estado por día + `recommended_day_id` | `GetWeeklyPlan` y "TE TOCA HOY" | Alta |
| Edge/RPC `preview_coaching_v1(session_id)` (mismo motor que `generate_coaching_v1`, sin guardar) y retirar el motor en vivo | coaching en vivo y del resumen | Media |
| RPC `get_session_summary_v1(session_id)` con volumen, récords y comparación (una sola definición de récord) | resumen al finalizar | Media |
| `compute_weekly_insights_v1` con `p_routine_id NULL` = rutina activa; decidir si el volumen incluye sesiones abiertas | suma de insights en cliente | Baja |
| CHECKs de rango en `routine_exercises` y `set_logs` + tabla de constantes | topes dispersos | Baja |

Hacerlo antes que la web evita escribir la misma lógica tres veces (Dart, TS y SQL).

### Lo que la web sí debe reimplementar (UX, siguiendo [05](05_logica_cliente.md))
Fechas locales con semana en lunes · feedback por serie · orden de precarga y
peso corporal confirmado · descanso (90 s, ±15 s, reglas de arranque) ·
duración estimada · 1RM de Epley · agregaciones de gráficas · formato es-ES ·
búsqueda sin tildes · borradores de series en `localStorage`.

### Lo que la web puede omitir
Caché SQLite/SWR y cola offline del móvil (ver [04](04_flujos_cliente.md#offline-qué-hace-el-móvil-y-qué-puede-omitir-la-web)),
notificaciones locales, Live Activities y alarma nativa de descanso.

### Checklist de compatibilidad (ambos clientes contra el mismo backend)
- [ ] `session_date` en fecha local; `week_start` siempre explícito (lunes local).
- [ ] Ejercicios del entreno desde `get_session_exercises_v1`; ocultar `target_sets = 0`.
- [ ] Upsert de series con `onConflict: 'session_id,exercise_id,set_index'`, `set_index` desde 1.
- [ ] Finalizar solo por Edge Function, con relectura de `completed_at` ante 404.
- [ ] Descartar solo por RPC.
- [ ] `.select()` en todo UPDATE/DELETE; 0 filas = no encontrado.
- [ ] Bearer explícito y sin cabeceras extra en Edge Functions (CORS).
- [ ] Errores por `code`, con los textos de [04](04_flujos_cliente.md#mapeo-de-errores-recomendado).
- [ ] `full_name` en la metadata del `signUp`.
