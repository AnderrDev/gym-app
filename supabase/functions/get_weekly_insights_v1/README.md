# get_weekly_insights_v1

Calcula insights semanales server-side para una rutina:

- adherencia (`completed_days / planned_days`)
- sesiones completadas
- volumen total semanal
- tendencia vs semana anterior
- cantidad de PRs por ejercicio

## Request

`POST` con JWT (verify_jwt=true)

```json
{
  "routine_id": "uuid",
  "week_start": "2026-04-06"
}
```

`week_start` es opcional. Si no se envía, usa el lunes de la semana actual en UTC.

## Response

```json
{
  "success": true,
  "code": "WEEKLY_INSIGHTS_READY",
  "data": {
    "week_start": "2026-04-06",
    "week_end": "2026-04-12",
    "planned_days": 5,
    "completed_days": 4,
    "completed_sessions": 4,
    "adherence_rate": 80,
    "total_volume": 35240,
    "previous_week_volume": 33010,
    "volume_trend_percent": 6.76,
    "personal_records": 3
  }
}
```
