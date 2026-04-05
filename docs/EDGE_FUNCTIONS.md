# Edge Functions activas (fase actual)

Este documento describe las functions implementadas en la fase actual del proyecto.

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
- Usa logs actuales y última sesión completada del mismo `routine_day_id`.
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

## Estados remotos (verificados)
- `finalize_workout_session_v1`: ACTIVE (version 3)
- `generate_coaching_v1`: ACTIVE (version 2)
- `get_weekly_insights_v1`: ACTIVE (version 1)

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
