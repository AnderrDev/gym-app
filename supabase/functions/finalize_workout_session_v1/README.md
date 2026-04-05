# finalize_workout_session_v1

Edge Function para cerrar una sesión de entrenamiento de forma segura.

## Request
POST body JSON:
- `session_id` (string, requerido)
- `coaching_analysis` (array opcional)

## Behavior
- Requiere JWT válido (`verify_jwt=true`).
- Solo permite cerrar sesión del usuario autenticado (`user_id` del JWT).
- Solo cierra sesiones abiertas (`completed_at IS NULL`).
- Devuelve resumen desde `view_workout_sessions_summary` cuando está disponible.

## Response
```json
{
  "success": true,
  "code": "SESSION_COMPLETED",
  "data": {
    "session_id": "...",
    "summary": { "...": "..." }
  }
}
```
