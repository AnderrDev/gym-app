# AGENT_CONTEXT: Smart Gym Tracker

Este documento es el punto de entrada para cualquier agente IA que vaya a trabajar en este repositorio.

## 1) Resumen del Proyecto
Smart Gym Tracker es una app Flutter orientada a entrenamiento de fuerza/hipertrofia con foco en sobrecarga progresiva.

Objetivo de producto:
- Decirle al usuario exactamente que entrenar cada dia.
- Permitir registro rapido de series (peso/repeticiones) sin friccion.
- Mostrar rendimiento previo para impulsar progresion.
- Ofrecer feedback de coaching al cerrar sesiones.

Plataformas objetivo:
- Android, iOS y Web.

## 2) Objetivos Funcionales (MVP)
Fuente principal: `docs/DOCUMENTACION.md`, `docs/HISTORIAS_DE_USUARIO.md`.

- Gestion de rutinas y dias de entrenamiento.
- Entrenamiento activo con registro libre (sin flujo rigido iniciar/finalizar).
- Temporizador de descanso por ejercicio.
- Historial semanal y comparacion con sesiones previas.
- Coaching de rendimiento al completar sesion.

## 3) Arquitectura Tecnica
Stack principal:
- Flutter
- Supabase (Auth + Postgres)
- BLoC (`flutter_bloc`)
- Inyeccion de dependencias (`get_it`)
- Router (`go_router`)
- Funcional (`fpdart`)
- Persistencia local (`sqflite`, `shared_preferences`)

Estructura:
- `lib/core`: configuracion, rutas, errores, servicios transversales.
- `lib/features/auth`: autenticacion y perfil.
- `lib/features/workout`: rutinas, sesiones, registro de sets, historial.

Bootstrap:
- `lib/main.dart` inicializa locale, Supabase, DI y providers BLoC.

DI actual:
- `lib/injection_container.dart` registra Auth y Workout en remoto.
- Hay componentes offline comentados, por lo que offline-first esta parcial en runtime.

## 4) Como Debe Funcionar (Flujo Ideal End-to-End)
1. Usuario se registra/inicia sesion.
2. App carga rutinas asignadas (`user_routines`).
3. Usuario entra a un dia (`routine_days`) y ve ejercicios (`routine_exercises` + `exercises`).
4. App abre/recupera sesion del dia (`workout_sessions`).
5. Usuario registra series (`set_logs`) set por set.
6. App compara con rendimiento previo por ejercicio (RPC o fallback query).
7. Al terminar, marca `completed_at` y guarda `coaching_analysis`.
8. Dashboard semanal muestra progreso y estado de completitud estricta.

## 5) Backend y Base de Datos (Repo + Remoto)
Fuentes locales: `supabase/schema.sql`, `supabase/migrations/002_workout_integrity_improvements.sql`, `supabase/seed_mock_data.sql`, `supabase/assign_mock.sql`.
Fuentes remotas (MCP Supabase): migraciones aplicadas, tablas/columnas, RLS, vistas y RPC.

Tablas principales:
- `profiles`
- `routines`
- `exercises`
- `user_routines`
- `routine_days`
- `routine_exercises`
- `workout_sessions`
- `set_logs`

RLS:
- Habilitado en tablas principales.
- Lectura de catalogos (ejercicios/rutinas/dias) abierta segun politicas del schema.
- Escritura de sesiones/logs restringida al usuario propietario.

Migraciones relevantes:
- `002_workout_integrity_improvements.sql` agrega `completed_at` y `coaching_analysis` en `workout_sessions`.
- Crea vista `view_workout_sessions_summary` con:
  - `total_target_sets`
  - `total_completed_sets`
  - `is_strictly_completed`

Migraciones remotas detectadas:
- `20260402202056_add_rest_timer_and_indexes`
- `20260402202120_optimize_rls_and_rpc`
- `20260402220058_migration_v2_fix_workout_v3_drop_and_create`
- `20260402220935_fix_last_performance_rpc_v2`

Seeds:
- `seed_mock_data.sql` crea escenario de pruebas consistente con coaching y semanas historicas.
- `assign_mock.sql` crea catalogo/rutina para el primer usuario y datos de ejemplo.

Hallazgos remotos confirmados:
- Existen en `public`: `profiles`, `routines`, `exercises`, `user_routines`, `routine_days`, `routine_exercises`, `workout_sessions`, `set_logs`, `view_workout_sessions_summary`.
- Existe la RPC `get_last_exercise_performance`.
- En remoto, `routine_exercises` incluye `rest_timer_seconds`.
- En remoto, `workout_sessions` incluye `completed_at` y `coaching_analysis`.

## 6) Avances Comprobados
Hecho:
- Autenticacion con Supabase y cache local de usuario (`auth_local_data_source.dart`).
- Navegacion basada en estado auth (`main.dart` + router + bloc).
- Flujo principal de workout remoto (`workout_remote_data_source.dart`).
- Historial semanal basado en `view_workout_sessions_summary`.
- Cierre de sesion con `completed_at` y `coaching_analysis`.

Parcial:
- Offline-first existe a nivel de componentes (`database_helper`, `workout_local_data_source`, `sync_service`) pero no esta totalmente cableado en DI actual.

## 7) Brechas y Riesgos Detectados
1. Drift repo vs remoto:
- Se agregaron al repo las 4 migraciones timestamp detectadas en remoto para reducir drift.
- Riesgo residual: falta validar reproducibilidad completa en un entorno Supabase limpio ejecutando todas las migraciones en orden.

2. Drift de schema local:
- Se alineo `schema.sql` con `rest_timer_seconds` en `routine_exercises`.
- Riesgo residual: revisar periodicamente que `schema.sql` y migraciones sigan sincronizados tras cambios futuros.

3. Drift de seeds:
- Se corrigio `assign_mock.sql` para no insertar columnas inexistentes (`started_at`, `total_volume`).
- Riesgo residual: validar seed en entorno nuevo y unificar con `seed_mock_data.sql` para evitar duplicidad funcional.

4. Modelo de ejercicio parcialmente desacoplado:
- Cliente usa `target_muscle` en `ExerciseModel`; el origen SQL principal es `exercises.muscle_group`.
- Hoy se usa fallback a `Desconocido` y eso puede ocultar errores de mapeo.

5. Seguridad/secretos:
- `lib/core/config/supabase_config.dart` contiene URL y anon key hardcodeados.

6. Offline runtime:
- Wiring comentado en `lib/injection_container.dart` implica que la promesa offline-first no esta cerrada extremo a extremo.

7. RLS de catalogos muy abierta:
- `routines_select`, `routine_days_select`, `routine_exercises_select` y `exercises_select` estan con `USING (true)`.
- Puede ser intencional para catalogo publico, pero conviene explicitar alcance (publico vs privado) para evitar filtraciones futuras.

## 8) Prioridades Recomendadas (Roadmap)
Prioridad 1 (small):
- Mover credenciales Supabase a `--dart-define`/entorno y quitar hardcode.

Prioridad 2 (small-medium):
- Sincronizar repo con remoto:
  - exportar/crear migraciones faltantes en `supabase/migrations/`.
  - actualizar `schema.sql` para que represente estado desplegado.

Prioridad 3 (medium):
- Rehabilitar offline-first en DI y validar sincronizacion `is_synced`.

Prioridad 4 (medium):
- Alinear mapeo de dominio:
  - decidir canon entre `muscle_group` (SQL) y `target_muscle` (cliente).
  - eliminar fallbacks silenciosos donde oculten drift.

Prioridad 5 (medium):
- Crear pruebas de integracion para flujo: iniciar sesion -> registrar sets -> cerrar sesion -> ver resumen semanal.

Prioridad 6 (medium-large):
- UI completa de creador/editor de rutinas aprovechando operaciones ya expuestas en datasource remoto.

Prioridad 7 (small-medium):
- Revisar y endurecer RLS segun producto:
  - Si rutinas son privadas por usuario, cerrar SELECT global.
  - Si hay catalogo publico, separar tablas publicas de datos de usuario.

## 9) Reglas Operativas para Agentes
Antes de codificar:
- Leer este archivo completo.
- Revisar `lib/injection_container.dart` y `workout_remote_data_source.dart` para entender contratos reales.
- Confirmar que cualquier cambio SQL tenga migracion versionada en `supabase/migrations/`.

Al tocar backend/BD:
- No asumir columnas/RPC existentes si no estan en schema+migrations.
- Mantener RLS consistente con ownership por usuario.
- Preferir cambios backwards compatible.

Al tocar app Flutter:
- Mantener estilo Clean Architecture (domain/data/presentation).
- Evitar mezclar logica de negocio en UI.
- Agregar pruebas cuando se altere flujo critico de workout.

## 10) Checklist Minimo Antes de PR
1. `flutter pub get`
2. `flutter analyze`
3. Validar login y carga de rutinas.
4. Validar guardado de set log y cierre de sesion.
5. Validar dashboard semanal y estado de completitud.
6. Si hubo cambios SQL: incluir migracion y seed de prueba coherente.

## 11) Estado de Verificacion del Backend en Este Documento
- Verificacion realizada contra SQL del repositorio + inspeccion remota con MCP Supabase.
- Verificado en remoto:
  - tablas principales y vista `view_workout_sessions_summary`,
  - columnas clave (`rest_timer_seconds`, `completed_at`, `coaching_analysis`),
  - RPC `get_last_exercise_performance`,
  - politicas RLS e indices relevantes.
- Principal gap actual: sincronizacion incompleta de migraciones/DDL entre repo y remoto.

## 12) Alineacion Actual (Resumen Ejecutivo)
Estado general: alineacion funcional parcial.

Alineado:
- Flujo workout principal, vista de resumen y RPC de ultima performance existen en remoto y son consumidos por la app.

No alineado:
- Falta prueba de reproducibilidad end-to-end en entorno Supabase nuevo usando solo migraciones del repo.
- Persisten decisiones abiertas de modelo (`muscle_group` vs `target_muscle`) y estrategia RLS de catalogos.

Siguiente objetivo tecnico recomendado:
- Ejecutar verificacion de reproducibilidad (migraciones + seeds) y luego priorizar endurecimiento de seguridad/consistencia de dominio.

## 13) Plan de Servicios Supabase
Para estrategia de aprovechamiento de servicios Supabase (Auth, Realtime, Storage, Edge Functions, Vault, observabilidad y roadmap por fases), revisar:
- `docs/SUPABASE_SERVICES_PLAN.md`
