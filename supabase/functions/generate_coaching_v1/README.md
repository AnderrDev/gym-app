# generate_coaching_v1

Genera análisis de coaching para una sesión usando datos históricos del usuario.

## Request
POST JSON:
- `session_id` (string, requerido)

## Seguridad
- JWT requerido (`verify_jwt=true`).
- Solo genera coaching para sesiones del usuario autenticado.
- Rate limit: 30 llamadas/min por usuario. Excedido → `429 RATE_LIMIT_EXCEEDED`.

## Output
`data.analysis` (array) con campos:
- `exercise_id`
- `exercise_name`
- `completed_sets`
- `target_sets`
- `weight_met`
- `reps_met`
- `recommendation` (`INCREASE_WEIGHT`, `INCREASE_REPS`, `MAINTAIN`, `DECREASE_WEIGHT`)
- `feedback`
- `performance_score`
