# Supabase Optimization Flow (Rendimiento + Costo)

Este documento deja mapeado el flujo de trabajo que seguimos en esta fase para optimizar API/Supabase sin cache en app (offline-first queda para la siguiente fase).

## Objetivo de la fase

- Reducir tiempos de carga en app.
- Reducir costo por request/consulta en Supabase.
- Mantener cambios moderados y compatibles con el flujo actual.

## Alcance aplicado

- Incluido: llamadas API, SQL/RPC, índices, Edge Functions, payloads selectivos, medición en logs MCP.
- Excluido: cache en app, estrategia offline-first, cambios de billing/plan, refactors masivos de UI.

## Cambios implementados

### 1) Optimización de lecturas en app (API calls)

- Se eliminó patrón N+1 para set logs recientes:
  - Antes: 1 request por sesión para `set_logs`.
  - Ahora: request batch con `session_id IN (...)`.
- Se reemplazó escritura `delete + insert` por `upsert` en `set_logs` con `onConflict: session_id,exercise_id,set_index`.
- Se redujeron lecturas `select *` en rutas críticas a columnas explícitas.

Archivos principales:
- `lib/features/workout/data/datasources/workout_remote_data_source.dart`
- `lib/features/workout/presentation/bloc/workout_bloc.dart`
- `lib/features/workout/data/repositories/workout_repository_impl.dart`
- `lib/features/workout/domain/repositories/workout_repository.dart`
- `lib/features/auth/data/datasources/auth_remote_data_source.dart`

### 2) Weekly Insights (Fase 3 iniciada y aplicada)

- Se creó RPC único para cálculo semanal:
  - `compute_weekly_insights_v1(p_user_id, p_routine_id, p_week_start)`
- Se simplificó `get_weekly_insights_v1` para delegar cálculo al RPC.
- Se agregaron índices de soporte.

Migración:
- `supabase/migrations/20260405120000_optimize_weekly_insights_rpc.sql`

Function:
- `supabase/functions/get_weekly_insights_v1/index.ts`

Resultado observado en logs:
- v8: ~1.0s a ~1.8s
- v9: ~0.4s a ~0.8s (mejora clara)

### 3) Last exercise performance batch

- Se creó RPC batch para evitar llamadas por ejercicio:
  - `get_last_exercise_performances(p_user_id, p_exercise_ids)`
- El datasource ahora usa batch por defecto y mantiene fallback seguro.

Migración:
- `supabase/migrations/20260405123000_add_get_last_exercise_performances_rpc.sql`

Validación en logs:
- Con `pg_stat_statements` reseteado, el flujo probado usó batch y 0 llamadas al RPC legacy en la ventana de prueba.

### 4) Coaching inputs batch

- Se creó RPC de inputs para coaching en un solo llamado:
  - `get_coaching_inputs_v1(p_user_id, p_session_id)`
- `generate_coaching_v1` ahora consume ese RPC (en vez de múltiples queries secuenciales).

Migración:
- `supabase/migrations/20260405124500_add_get_coaching_inputs_rpc.sql`

Functions:
- `supabase/functions/generate_coaching_v1/index.ts` (v11)
- `supabase/functions/finalize_workout_session_v1/index.ts` (v15)

Corrección clave:
- Se detectó error `invalid input syntax for type uuid: "unknown"`.
- Se corrigió pasando contexto de usuario en la invocación entre functions:
  - Header `X-User-Token`
  - Fallback `user_id` en payload

Validación final:
- `generate_coaching_v1` respondió `200` (v11) con ~401ms en prueba reciente.

## Estado de Functions y migraciones (esta fase)

### Edge Functions activas relevantes

- `get_weekly_insights_v1` -> versión 9
- `generate_coaching_v1` -> versión 11
- `finalize_workout_session_v1` -> versión 15

Nota:
- En `supabase.json` siguen con `verify_jwt: false` (config actual del proyecto).

### Migraciones nuevas aplicadas

- `20260405120000_optimize_weekly_insights_rpc.sql`
- `20260405123000_add_get_last_exercise_performances_rpc.sql`
- `20260405124500_add_get_coaching_inputs_rpc.sql`

## Flujo operativo recomendado (repetible)

1. Implementar cambio incremental (API/RPC/index).
2. Desplegar migración o function.
3. Ejecutar flujo real en app local (2-3 repeticiones).
4. Medir con MCP:
   - `edge-function` logs (status, versión, `execution_time_ms`)
   - `pg_stat_statements` (calls, mean, total)
5. Comparar antes/después en ventana corta.
6. Mantener, ajustar o revertir según resultado.

## Queries de verificación (MCP SQL)

### A) Ver uso batch vs legacy en last performance

```sql
select calls, round(mean_exec_time::numeric,3) as mean_ms, left(query, 200) as query_sample
from pg_stat_statements
where query ilike '%get_last_exercise_performances%'
   or query ilike '%get_last_exercise_performance%'
order by calls desc;
```

### B) Ver latencia de selects en rutas críticas

```sql
select calls, round(total_exec_time::numeric,2) as total_ms, round(mean_exec_time::numeric,3) as mean_ms, left(query, 260) as query_sample
from pg_stat_statements
where query ilike '%view_workout_sessions_summary%'
   or query ilike '%from "public"."set_logs"%'
order by total_exec_time desc
limit 30;
```

### C) Reset controlado para medir ventana limpia

```sql
select pg_stat_statements_reset();
```

## Pendientes para próxima iteración

- Barrido final de `select=*` residuales en rutas no críticas.
- Reducir logs de debug en `finalize_workout_session_v1` cuando se estabilice producción.
- Definir umbrales KPI de fase:
  - p95 por function
  - llamadas por flujo de pantalla
  - ratio batch/single en queries sensibles

## Decisión de arquitectura vigente

- Mantener estrategia API + Supabase optimizada (REST/RPC + Edge Functions).
- No incorporar cache de app en esta fase.
- Offline-first se trabajará en un plan separado.

## Referencia de sesión exportada

- `session-ses_2a12.md`
