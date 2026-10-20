# delete_account_v1

Elimina la cuenta del usuario autenticado (requisito App Store 5.1.1(v)).

## Request

`POST` con JWT (`verify_jwt = true`); además `requireUser()` revalida el token
contra `auth.getUser(token)`. Rate limit: 5 llamadas/min por usuario.

```json
{ "confirm": "ELIMINAR" }
```

`confirm` es obligatorio y debe ser exactamente `ELIMINAR`. Evita borrados por
un cliente con bug o una petición reenviada a la function equivocada.

## Behavior

1. Llama con service_role a la RPC `delete_account_data_v1(p_user_id)`
   (migración `20261020130000_delete_account.sql`), que en una transacción:
   - borra `set_logs`, `workout_sessions` y `user_routines` del usuario;
   - **anonimiza** (`creator_id = NULL`) sus rutinas públicas, y también las
     privadas que otro usuario tenga asignadas o con sesiones (no se publican:
     conservan `is_public`). Sin dueño, nadie puede editarlas; se pueden
     seguir usando y copiar (`fork_routine_v1`) si son públicas;
   - borra sus rutinas privadas con `routine_days` y `routine_exercises`;
   - borra `function_rate_limits` y el `profiles` del usuario.
2. Borra el usuario con `auth.admin.deleteUser(userId)`. Si falla (p. ej. el
   cliente sincronizó una serie entre medias), repite la RPC una vez y
   reintenta. La RPC es idempotente.

El `userId` sale siempre del JWT validado; la RPC no es ejecutable por
`anon`/`authenticated`.

## Response

```json
{
  "success": true,
  "code": "ACCOUNT_DELETED",
  "data": {
    "user_id": "…",
    "deleted": {
      "set_logs": 120,
      "workout_sessions": 14,
      "user_routines": 1,
      "routines_anonymized": 1,
      "routines_deleted": 2,
      "routine_days_deleted": 8,
      "routine_exercises_deleted": 40,
      "rate_limits": 1,
      "profiles": 1
    }
  }
}
```

Tras el éxito el JWT del cliente deja de servir: la app limpia su estado local
y cierra sesión sólo en local.

## Error codes

| Code | HTTP | Significado |
|---|---|---|
| `INVALID_JSON` | 400 | Body no es JSON válido |
| `CONFIRMATION_REQUIRED` | 400 | `confirm` ausente o distinto de `ELIMINAR` |
| `UNAUTHORIZED` | 401 | JWT inválido / usuario no resuelto |
| `METHOD_NOT_ALLOWED` | 405 | Solo se acepta POST |
| `RATE_LIMIT_EXCEEDED` | 429 | Más de 5 llamadas/min |
| `DELETE_ACCOUNT_DATA_ERROR` | 500 | Falló la RPC; no se borró nada (transacción) |
| `DELETE_AUTH_USER_ERROR` | 500 | Datos borrados pero el usuario de Auth sigue; reintentar es seguro |

## Deploy

```bash
supabase db push   # aplica 20261020130000_delete_account.sql
supabase functions deploy delete_account_v1
```

Contrato SQL reproducible: `supabase/tests/delete_account_fixture.sql` +
`supabase/tests/delete_account.sql` (base desechable, ver cabecera del fixture).
