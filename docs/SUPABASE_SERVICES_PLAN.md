# Plan de Aprovechamiento de Supabase para Smart Gym Tracker

Este documento traduce los servicios de Supabase a oportunidades concretas para la app.

## 1) Estado Actual Verificado
Servicios/stack ya en uso:
- Postgres + API auto-generada (PostgREST)
- Auth (email/password)
- RLS en tablas principales
- RPC (`get_last_exercise_performance`)
- Vista analitica (`view_workout_sessions_summary`)

Extensiones instaladas en remoto:
- `pgcrypto`
- `pg_stat_statements`
- `pg_graphql`
- `supabase_vault`
- `uuid-ossp`

No instaladas (segun snapshot actual de `pg_extension`):
- `pg_cron`
- `pg_net`

## 2) Servicios Supabase y Como Explotarlos

### A. Auth
Uso actual:
- Login/registro email-password.

Mejoras propuestas:
1. Endurecer sesiones y seguridad:
- activar reglas de password y email verification segun producto.
- agregar auditoria basica de auth events.

2. Rolado de permisos por claims:
- usar custom claims para separar usuario normal vs coach/admin.

Impacto:
- mejor control de acceso a funciones admin (ej. creador global de rutinas).

### B. Postgres + RLS
Uso actual:
- modelo central del producto y ownership por usuario.

Mejoras propuestas:
1. Cerrar drift repo-remoto (prioridad inmediata).
2. Revisar politicas `SELECT USING (true)` para catalogos y decidir:
- catalogo realmente publico, o
- acceso segmentado por tenant/rol.
3. Añadir constraints de integridad de negocio:
- unicidad de set por (`session_id`,`exercise_id`,`set_index`) para evitar deduplicacion manual.

Impacto:
- menos bugs de datos y menor deuda tecnica.

### C. Realtime
Uso actual:
- no hay evidencia de suscripciones activas en cliente para workout.

Mejoras propuestas:
1. Realtime para sincronizacion multi-dispositivo de sesion activa.
2. Canal de presencia para escenarios coach-atleta (futuro premium).
3. Empezar por `postgres_changes` en tablas criticas y evolucionar a `broadcast` en flujos de colaboracion/estado efimero.

Impacto:
- experiencia mas viva y consistente cuando el usuario cambia de dispositivo.

### D. Edge Functions
Uso actual:
- no integradas en flujo principal.

Mejoras propuestas:
1. Mover coaching avanzado a Edge Function:
- entrada: resumen de sesion + historico reciente.
- salida: recomendaciones estructuradas guardadas en `coaching_analysis`.
2. Webhooks de integracion externa (Wearables / WhatsApp / Email).
3. Jobs de saneamiento de datos y backfills controlados.

Impacto:
- logica compleja fuera del cliente, mas mantenible y segura.

### E. Storage
Uso actual:
- no evidenciado en flujo workout.

Mejoras propuestas:
1. Bucket para multimedia de ejercicios (gif/video/imagen).
2. Bucket para avatares de usuario.
3. Politicas por bucket con acceso publico solo donde aplique.

Impacto:
- mejor UX en planner y entrenamiento (ejecucion correcta del ejercicio).

### F. Cron + Jobs Programados (pg_cron)
Uso actual:
- no disponible en extensiones instaladas.

Mejoras propuestas:
1. Instalar `pg_cron` (y `pg_net` si se invocaran endpoints).
2. Programar tareas:
- consolidacion semanal de metricas.
- recordatorios de inactividad.
- recálculo nocturno de insights.

Impacto:
- automatizacion operativa sin depender de cliente abierto.

### G. Vault
Uso actual:
- extension instalada (`supabase_vault`).

Mejoras propuestas:
1. Guardar secretos usados por jobs/funciones.
2. Evitar claves hardcodeadas en app y SQL.

Impacto:
- mejor postura de seguridad.

### H. Observabilidad y Performance
Uso actual:
- `pg_stat_statements` instalado.

Mejoras propuestas:
1. Auditar top queries lentas de dashboard/historial.
2. Ajustar indices compuestos segun consultas reales.
3. Definir SLO basico de latencia para consultas clave.

Impacto:
- app mas fluida y menor costo de BD.

## 3) Roadmap Recomendado por Fases

Fase 0 (inmediata, 1 sprint):
1. Alinear migraciones locales con remoto (hecho en repo).
2. Corregir seed desalineado (`assign_mock.sql`).
3. Quitar secretos hardcodeados del cliente.

Fase 1 (corto plazo):
1. Revisar/ajustar RLS de catalogos.
2. Integrar Storage para assets de ejercicios.
3. Instrumentar monitoreo con `pg_stat_statements`.

Fase 2 (medio plazo):
1. Realtime en sesion activa (sincronizacion entre dispositivos).
2. Edge Function para coaching avanzado.
3. Pruebas de integracion DB + reglas RLS.

Fase 3 (premium/escala):
1. Presencia coach-atleta y colaboracion en vivo.
2. Jobs programados con cron para insights y retention.
3. Exponer endpoints especializados para analitica avanzada.

## 4) Backlog Tecnico Priorizado
1. Definir y aplicar modelo canon de musculo (`muscle_group` vs `target_muscle`).
2. Constraint unico para set logs por set.
3. Endurecer politicas write/update donde falten.
4. Crear scripts de verificacion automatica de drift schema.
5. Diseñar contrato de datos para coaching (input/output versionado).

## 5) Criterios de Exito
- Cero drift entre remoto y `supabase/migrations`.
- Deploy reproducible en un proyecto nuevo.
- Tiempo de carga de dashboard y sesion estable bajo carga normal.
- Sin secretos hardcodeados en repo.
- Recomendaciones de coaching consistentes y auditables.
