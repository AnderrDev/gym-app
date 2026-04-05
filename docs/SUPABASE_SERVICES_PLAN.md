# Plan Maestro de Maximización de Supabase para Smart Gym Tracker

Documento estratégico para explotar Supabase al máximo en esta app, con foco principal en Edge Functions.

Plan táctico de ejecución por fases:
- `docs/SUPABASE_IMPLEMENTATION_PLAN.md`

Alcance de esta fase:
- Incluido: Database, Auth básico, RLS, Edge Functions, observabilidad.
- Excluido por ahora: Realtime, Storage, Cron (`pg_cron`), Vault y roles/claims avanzados.

## 1) Estado actual verificado (hoy)
En uso real:
- Postgres + PostgREST
- Auth (email/password)
- RLS en tablas core
- RPC `get_last_exercise_performance`
- Vista `view_workout_sessions_summary`

Verificado en remoto:
- Migraciones alineadas en repo con las migraciones detectadas en remoto.
- Índice único parcial para una sola sesión activa por usuario.
- Edge Functions desplegadas actualmente: ninguna (`list_edge_functions` vacío).

Extensiones instaladas:
- `pgcrypto`, `pg_stat_statements`, `pg_graphql`, `supabase_vault`, `uuid-ossp`

No instaladas:
- `pg_cron`, `pg_net`

## 2) Mapa completo de servicios Supabase y cómo integrarlos

### 2.1 Database (Postgres)
Qué aporta:
- Modelo transaccional del negocio fitness (rutinas, sesiones, set logs).

Cómo explotarlo más:
- Constraints de integridad (unicidad de set por `session_id, exercise_id, set_index`).
- Índices compuestos de consultas calientes (dashboard semanal, histórico por ejercicio).
- Funciones SQL para operaciones atómicas críticas (completar sesión + snapshot de métricas).

### 2.2 Auth
Qué aporta:
- Identidad y sesión segura del atleta.

Cómo explotarlo más:
- Verificación de email y políticas de contraseña.
- Auditoría de eventos auth para soporte y seguridad.

### 2.3 Row Level Security (RLS)
Qué aporta:
- Aislamiento por usuario en datos sensibles.

Cómo explotarlo más:
- Decisión explícita de modelo de catálogo:
	- público (`SELECT true`) o
	- segmentado por usuario/tenant.
- Tests de seguridad SQL para evitar regresiones de políticas.

### 2.6 Edge Functions (prioridad alta)
Qué aporta:
- Lógica de negocio server-side, integraciones externas, webhooks, tareas seguras.

Cómo explotarlo más (en este proyecto):
- Orquestar cierre de sesión, coaching, notificaciones, ingesta externa.
- Evitar lógica sensible dispersa en el cliente.
- Centralizar validaciones e idempotencia.

Buenas prácticas clave:
- `verify_jwt=true` por defecto.
- Service role solo dentro de función cuando sea estrictamente necesario.
- Idempotencia por request-id/session-id.
- Logging estructurado por `user_id`, `session_id`, `correlation_id`.

### 2.7 GraphQL (`pg_graphql`)
Qué aporta:
- Capa alternativa de consulta (útil para clientes ricos en lectura).

Cómo explotarlo más:
- Mantenerlo opcional por ahora.
- Activarlo solo para vistas analíticas complejas si aporta claridad frente a PostgREST.

### 2.8 Observabilidad
Qué aporta:
- Detección de cuellos de botella y costos.

Cómo explotarlo más:
- Revisiones periódicas con `pg_stat_statements`.
- SLO de latencia para endpoints críticos (dashboard, apertura de día, cierre sesión).

## 3) Plan específico de Edge Functions (lo más importante)

### Fase A (base, 1 sprint)
1. `finalize_workout_session_v1`
- Entrada: `session_id`.
- Proceso: valida ownership, calcula completitud estricta, marca `completed_at`, persiste resumen.
- Salida: estado final + métricas de sesión.

2. `generate_coaching_v1`
- Entrada: `session_id`, contexto mínimo.
- Proceso: analiza rendimiento vs histórico reciente.
- Salida: recomendaciones estructuradas para `coaching_analysis`.

3. `get_weekly_insights_v1`
- Entrada: `user_id`, rango semanal.
- Salida: volumen, adherencia, tendencia, PRs.

### Fase B (producto, 1-2 sprints)
4. `ingest_wearable_webhook_v1`
- Endpoint para integrar datos externos (pasos, HR, etc.) bajo firma segura.

5. `backfill_coaching_v1`
- Reprocesa sesiones antiguas cuando se actualiza algoritmo de coaching.

### Contrato técnico recomendado para Functions
- Versionado explícito (`*_v1`, `*_v2`).
- Respuesta estándar:
	- `success: bool`
	- `code: string`
	- `data: object`
	- `error: { message, details? }`
- Idempotencia por `session_id` y `operation_key`.

## 4) Arquitectura objetivo (Supabase-first)
1. Flutter
- UI + estado + validaciones de experiencia.

2. Postgres/RLS
- Fuente de verdad transaccional.

3. Edge Functions
- Casos de negocio complejos e integraciones externas.

4. Cliente Flutter
- Solo consumo de API/Auth/Functions en esta fase (sin Storage).

## 5) Roadmap priorizado (90 días)

### Sprint 1
1. Quitar secretos hardcodeados del cliente (`--dart-define` + entorno).
2. Crear `finalize_workout_session_v1`.
3. Añadir constraint único de set logs por set.
4. Tests de RLS y de flujo de cierre de sesión.

### Sprint 2
1. Crear `generate_coaching_v1`.
2. Integrar lectura/escritura de coaching desde función.
3. Hardening de errores y retries idempotentes en functions.

### Sprint 3
1. Crear `get_weekly_insights_v1`.
2. Integrar dashboard con insights de función.
3. Pruebas end-to-end de functions + hardening de contratos.

### Sprint 4
1. Integración de `ingest_wearable_webhook_v1`.
2. Ejecutar `backfill_coaching_v1` controlado para histórico.
3. Hardening de observabilidad y costos.

## 6) Backlog técnico recomendado
1. Unificar dominio `muscle_group` vs `target_muscle`.
2. Test suite SQL (RLS + funciones + vistas).
3. Script de “drift check” repo vs remoto.
4. Catálogo de errores de negocio estandarizado.
5. Estrategia de retries en funciones idempotentes.

## 7) Criterios de éxito
- Cero drift entre remoto y `supabase/migrations`.
- 100% de cierres de sesión pasan por función server-side.
- Latencia aceptable en flujos críticos (abrir día/cerrar sesión/dashboard).
- Sin secretos hardcodeados en app/repo.
- Recomendaciones de coaching consistentes y auditables.
