# Plan de Implementación del Plan de Supabase

Este documento convierte la estrategia de `docs/SUPABASE_SERVICES_PLAN.md` en ejecución operativa.

Alcance de esta fase:
- Incluido: Database, Auth básico, RLS, Edge Functions, observabilidad.
- Excluido por ahora: Realtime, Storage, Cron (`pg_cron`), Vault, roles/claims avanzados.

## Objetivo de implementación
Completar el flujo de entrenamiento con lógica server-side en Supabase Functions, mejorar integridad de datos y cerrar riesgos de configuración/operación.

## Fase 0: Base técnica (bloqueante)

### 0.1 Seguridad de configuración
- [x] Migrar claves de Supabase fuera del código (`--dart-define`).
- [x] Agregar `.env.example` de referencia.
- [x] Documentar ejecución en README.
- [ ] Verificar que no queden claves en historial/archivos legacy.

Entregables:
- `lib/core/config/supabase_config.dart`
- `.env.example`
- `README.md`

Criterio de salida:
- App arranca con `--dart-define`.
- No hay claves embebidas en código activo.

### 0.2 Integridad de datos
- [x] Unicidad de sesión activa por usuario (índice parcial).
- [x] Unicidad de set por `session_id + exercise_id + set_index` (migración).
- [ ] Ejecutar validación en entorno limpio con todas las migraciones.

Entregables:
- `supabase/migrations/20260404143000_enforce_single_active_session.sql`
- `supabase/migrations/20260404235500_enforce_unique_set_logs_per_set.sql`

Criterio de salida:
- No existen duplicados inválidos.
- Índices aplicados en remoto y reproducibles en local limpio.

## Fase 1: Cierre de sesión 100% server-side

### 1.1 Function de cierre
- [x] Crear y desplegar `finalize_workout_session_v1`.
- [x] Requerir JWT (`verify_jwt=true`).
- [x] Devolver contrato estándar (`success`, `code`, `data`, `error`).

### 1.2 Integración Flutter
- [x] Invocar function desde `finishWorkoutSession(...)`.
- [x] Mapear códigos de negocio críticos.
- [x] Mantener fallback temporal para infraestructura.
- [x] Ajustar UI para mostrar mensajes por `code` (no solo genérico).
- [x] Retirar fallback legacy de update directo cuando hubo estabilidad inicial.

Entregables:
- `supabase/functions/finalize_workout_session_v1/index.ts`
- `lib/features/workout/data/datasources/workout_remote_data_source.dart`

Criterio de salida:
- Cierre funciona en remoto con respuesta consistente.
- Usuario recibe feedback claro ante errores de negocio.

## Fase 2: Coaching automático server-side

### 2.1 Function de coaching
- [x] Crear y desplegar `generate_coaching_v1`.
- [x] Basar análisis en sesión actual + última sesión cerrada comparable.
- [x] Emitir recomendaciones compatibles con UI actual.

### 2.2 Orquestación de cierre + coaching
- [x] `finalize_workout_session_v1` invoca `generate_coaching_v1` si no llega `coaching_analysis` desde cliente.
- [ ] Validar calidad de recomendaciones con datos reales de usuarios de prueba.

Entregables:
- `supabase/functions/generate_coaching_v1/index.ts`
- `supabase/functions/finalize_workout_session_v1/index.ts`

Criterio de salida:
- `coaching_analysis` persistido en cierres y visible en UI.

## Fase 3: Insights semanales server-side

### 3.1 Diseñar función
- [x] Definir contrato de `get_weekly_insights_v1`.
- [x] Implementar cálculo de volumen, adherencia, tendencia y PRs.

### 3.2 Integración
- [x] Conectar dashboard al contrato de insights.
- [x] Añadir fallback visual si la función falla.

Entregables:
- `supabase/functions/get_weekly_insights_v1/index.ts`
- componentes de dashboard en `lib/features/workout/presentation/pages/`

Criterio de salida:
- Dashboard usa datos server-side para métricas principales.

## Fase 4: Calidad y operación

### 4.1 Pruebas
- [~] Tests de contrato para functions (éxito/error).
- [~] Smoke test E2E de flujo workout.

Estado actual:
- Casos de error sin auth validados (`401`) para las 3 functions.
- Casos success con JWT de usuario bloqueados por `Invalid JWT` en gateway/functions con tokens `ES256` del proyecto.
- Smoke backend con datos semilla ejecutado, pendiente cierre E2E completo cuando se resuelva validación JWT en runtime de functions.

### 4.2 Observabilidad
- [x] Estandarizar logs por `code`, `session_id`, `user_id`.
- [ ] Revisar consultas top con `pg_stat_statements`.

### 4.3 Retiro de fallback legacy
- [ ] Definir ventana de estabilidad (ej. 1 sprint).
- [x] Quitar update directo de `workout_sessions` desde cliente.

Criterio de salida:
- Cierre de sesión 100% server-side.
- Diagnóstico operativo claro ante fallos.

## Orden recomendado de ejecución
1. Fase 0 (terminar pendientes)
2. Fase 1 (cerrar UX de errores)
3. Fase 2 (calibrar calidad de coaching)
4. Fase 3 (insights)
5. Fase 4 (hardening + retiro fallback)

## Comandos de validación sugeridos
```bash
flutter pub get
flutter analyze
flutter run --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Definición de hecho (DoD) por fase
- Código en repo con migraciones/functions versionadas.
- Validación manual del flujo principal en app.
- Documento de operación actualizado (`docs/EDGE_FUNCTIONS.md`).
- Sin regresiones de autenticación ni guardado de sets.
