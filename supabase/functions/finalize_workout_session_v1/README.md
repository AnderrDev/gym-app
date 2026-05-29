# finalize_workout_session_v1

Edge Function para cerrar una sesión de entrenamiento de forma segura.

## Request
POST body JSON:
- `session_id` (string, requerido)
- `coaching_analysis` (array opcional). Si se omite, el servidor invoca
  `generate_coaching_v1` y, si responde, persiste el resultado. Debe ser
  un array; si llega otra cosa se rechaza con `VALIDATION_ERROR`.

## Behavior
- Requiere JWT válido (`verify_jwt = true`); además `requireUser()` revalida
  el token contra `auth.getUser(token)` (defensa en profundidad).
- Solo permite cerrar la sesión cuyo `user_id` coincide con el JWT.
- Solo cierra sesiones abiertas (`completed_at IS NULL`); intentos sobre
  sesiones ya cerradas devuelven `404 NOT_FOUND_OR_COMPLETED`.
- Si `generate_coaching_v1` falla, la sesión se cierra igual (UX
  prioritaria) y la respuesta incluye `data.warning_code =
  "COACHING_GENERATION_FAILED"` para que el cliente pueda reintentar.
- Tras cerrar, intenta adjuntar `data.summary` desde
  `view_workout_sessions_summary`. Si la lectura falla, se omite (no
  bloquea la confirmación de cierre).

## Response
```json
{
  "success": true,
  "code": "SESSION_COMPLETED",
  "data": {
    "session_id": "...",
    "summary": {
      "id": "...",
      "user_id": "...",
      "routine_day_id": "...",
      "session_date": "2026-05-12",
      "completed_at": "2026-05-12T18:34:00Z",
      "total_target_sets": 12,
      "total_completed_sets": 12,
      "is_strictly_completed": true
    },
    "warning_code": "COACHING_GENERATION_FAILED"
  }
}
```

`summary` y `warning_code` son opcionales: pueden no aparecer si la vista
no devolvió fila o si el coaching se generó/se aportó correctamente.

## Error codes
| Code | HTTP | Significado |
|---|---|---|
| `INVALID_JSON` | 400 | Body no es JSON válido |
| `VALIDATION_ERROR` | 400 | `session_id` ausente o `coaching_analysis` no es array |
| `UNAUTHORIZED` | 401 | JWT inválido / usuario no resuelto |
| `NOT_FOUND_OR_COMPLETED` | 404 | Sesión no existe o ya fue cerrada |
| `METHOD_NOT_ALLOWED` | 405 | Solo se acepta POST |
| `COACHING_TOO_LARGE` | 413 | `coaching_analysis` excede 64 KB |
| `RATE_LIMIT_EXCEEDED` | 429 | Más de 30 llamadas/min — `error.reset_at` indica cuándo reintentar |
| `DB_UPDATE_ERROR` | 500 | Error al actualizar `workout_sessions` |
