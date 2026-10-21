# Backend de Smart Gym Tracker — referencia para nuevos clientes

Mapa completo del backend (Supabase: Postgres + PostgREST + Auth + Edge
Functions + Storage) tal como está a **2026-10-21**, pensado para construir la
**web nativa** contra el mismo backend sin depender del código Flutter.

| Documento | Qué cubre |
|---|---|
| [01_esquema.md](01_esquema.md) | Tablas, columnas, restricciones, índices, vistas, RLS, triggers, Storage |
| [02_api.md](02_api.md) | RPCs (Postgres) y Edge Functions: firmas, contratos JSON, errores, CORS, rate limits |
| [03_auth.md](03_auth.md) | Registro, login, perfil, reset de contraseña (PKCE), configuración del dashboard |
| [04_flujos_cliente.md](04_flujos_cliente.md) | Cada operación que hace el cliente actual, con la llamada exacta, invariantes de escritura y mapeo de errores |
| [05_logica_cliente.md](05_logica_cliente.md) | Lógica de negocio que hoy vive solo en Dart (plan semanal, coaching en vivo, récords, 1RM, precarga…) |
| [06_riesgos_y_plan_web.md](06_riesgos_y_plan_web.md) | Bugs y discrepancias detectados + qué mover al servidor antes/durante la web |

## Datos del proyecto

- Proyecto Supabase: ref `benadgxgowycjxypyunc`.
  - REST: `https://benadgxgowycjxypyunc.supabase.co/rest/v1/…`
  - RPC: `POST https://benadgxgowycjxypyunc.supabase.co/rest/v1/rpc/<nombre>`
  - Edge Functions: `POST https://benadgxgowycjxypyunc.supabase.co/functions/v1/<nombre>`
- Clave pública: anon key o publishable key (`sb_publishable_…`). La app la lee
  de `SUPABASE_ANON_KEY`. **Nunca** usar `service_role` en un cliente.
- Web Flutter actual: https://gym-tracker-anderson.netlify.app (Netlify).

## Arquitectura en una imagen

```
Cliente (Flutter hoy / web nativa mañana)
 ├─ supabase-js / supabase_flutter
 │   ├─ Auth (GoTrue, PKCE)            → auth.users  ─trigger→ profiles
 │   ├─ PostgREST (tablas + vistas)    → RLS por auth.uid()
 │   ├─ PostgREST /rpc (SECURITY DEFINER, gate por auth.uid())
 │   └─ Storage (bucket público exercise-media, solo lectura)
 └─ Edge Functions (Deno, verify_jwt = true, CORS *)
     ├─ finalize_workout_session_v1 ─→ generate_coaching_v1 ─→ rpc get_coaching_inputs_v1
     ├─ get_weekly_insights_v1      ─→ rpc compute_weekly_insights_v1
     └─ delete_account_v1           ─→ rpc delete_account_data_v1 + auth.admin.deleteUser
```

## Reglas de oro para un cliente nuevo

1. **Fuente de verdad del esquema = `supabase/migrations/`**, pero el DDL base
   (tablas originales, algunas políticas, el trigger `on_auth_user_created`) se
   creó desde el dashboard y **no está en el repo**. Ver
   [01_esquema.md § Verificación pendiente](01_esquema.md#verificación-pendiente).
2. Durante un entrenamiento, los ejercicios se leen del **snapshot de la
   sesión** (`rpc get_session_exercises_v1`), nunca de `routine_exercises`.
3. Una sesión se **cierra solo** vía la Edge Function
   `finalize_workout_session_v1` y se **descarta solo** vía
   `rpc discard_workout_session_v1`.
4. Las series se guardan con **upsert** sobre `(session_id, exercise_id, set_index)`;
   `set_index` empieza en **1**.
5. `session_date` es la **fecha local** del usuario (`YYYY-MM-DD`), la semana
   empieza en **lunes** y el cliente siempre manda `week_start` explícito.
6. RLS no da error al bloquear un UPDATE/DELETE: devuelve 0 filas. Pide siempre
   `select` de vuelta y trata 0 filas como "no encontrado / sin permiso".
7. Distingue errores por **`code`** (SQLSTATE o código de la Edge Function), no
   por el status HTTP.

## Cómo se generó y cómo mantenerlo

Reconstruido leyendo las 31 migraciones en orden, las 4 Edge Functions, los
tests SQL (`supabase/tests/`), el smoke (`scripts/contract_smoke_supabase.sh`)
y la capa de datos Dart (`lib/features/*/data`). Cuando la documentación previa
(`docs/EDGE_FUNCTIONS.md`, READMEs) contradice al código, aquí manda el código.

Al añadir una migración, RPC o Edge Function, actualiza el documento
correspondiente en esta carpeta.
