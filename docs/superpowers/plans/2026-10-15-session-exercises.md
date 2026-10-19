# Session Exercises Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans to implement task by task.

**Goal:** Registrar sustituciones y ejercicios extra únicamente en la sesión actual.
**Architecture:** Copia JSONB de los ejercicios dentro de workout_sessions, RPCs atómicas,
repositorio remoto y BLoC serializado. La UI solo consume el dominio.
**Tech Stack:** Flutter, Dart, Postgres, Supabase.
**Spec:** docs/superpowers/specs/2026-10-15-session-exercises-design.md

## Global Constraints

- Mantener español, Manrope y controles Material adaptativos.
- No modificar migraciones históricas, credenciales ni la rutina base.
- No reintroducir persistencia offline. Conservar cambios existentes del workspace.
- Probar antes de publicar. Migración antes del frontend.

## Task 1: Persistencia y resúmenes de sesión

Files: nueva migración timestamped bajo supabase/migrations/, contrato SQL bajo
supabase/tests/session_exercises.sql, documentación docs/EDGE_FUNCTIONS.md.
Interfaces: las tres RPCs JSONB y campos descritos en el spec.

- [x] Crear prueba SQL con BEGIN/ROLLBACK y fixtures aislados. Assert:
  `if actual_count <> expected_count then raise exception 'contract'; end if;`
- [x] Ejecutar contra fixture local antes de la migración y comprobar fallo.
- [x] Crear migración con `supabase migration new session_exercises`.
- [x] Implementar snapshot, RPCs, vista resumen y objetivos de coaching.
- [x] Ejecutar contrato SQL y verificar RLS/ownership y conservación de logs.
- [x] Revisar migración sin aplicar en producción hasta recuperar acceso correcto.

## Task 2: Dominio, remoto y estado

Files: Exercise y ExerciseModel; contratos del repositorio/data source; nuevo
colaborador session_exercise_remote_data_source.dart; active_workout_bloc.dart y
loader; usecases get_session_exercises.dart y adapt_session_exercise.dart.

Interfaces Dart:
```dart
Future<Either<Failure,List<Exercise>>> getSessionExercises(String sessionId);
Future<Either<Failure,List<Exercise>>> adaptSessionExercise(String sessionId,
  String exerciseId, {required int targetSets, required int targetReps,
  required double targetWeight, String? replaceExerciseId});
Future<Either<Failure,List<Exercise>>> updateSessionExerciseTarget(String sessionId,
  String exerciseId, double targetWeight, int targetReps);
```

- [x] Prueba roja: reanudar usa la lista guardada y no la rutina actual.
- [x] Prueba roja: adaptar conserva setLogs, propaga errores sin salir del workout.
- [x] Implementar métodos guard/mapToFailure y parsing de los campos nuevos.
- [x] Cargar plan al iniciar/reanudar; leer snapshot para detalles históricos.
- [x] Evento AdaptActiveWorkoutExercise serializado; bool isAdapting para bloquear
  controles mientras se guarda. Cambiar objetivos se limita a la sesión.
- [x] Verificar pruebas de bloc, modelos y repositorio.

## Task 3: Controles y selector

Files: nuevo session_exercise_sheet.dart; routine_day_page.dart, scaffold y
routine_day_active_focus_view.dart. Nuevas pruebas de widgets.

- [x] Prueba roja: buscar catálogo y confirmar objetivos válidos produce una
  selección tipada; cancelar no cambia datos y un duplicado no se puede elegir.
- [x] Añadir modal adaptativo con búsqueda, campos numéricos y texto Solo esta sesión.
- [x] Añadir acciones de sustituir pendientes y añadir extras; progreso y etiquetas
  de sustitución. Bloquear edición en sesiones cerradas y durante guardado.
- [x] Verificar nombres largos, móvil, errores de carga y reintento.

## Task 4: Verificación e integración

- [x] Revisión de código y corrección de hallazgos.
- [x] `flutter analyze`; `flutter test`; contrato SQL; `git diff --check`.
- [x] Recuperar acceso Supabase al proyecto benadgxgowycjxypyunc y aplicar migración.
- [x] Verificar resúmenes, coaching y contratos con transacciones de prueba.
- [x] `flutter build web --dart-define-from-file=.env --pwa-strategy=none` y publicar
  Firebase únicamente cuando las RPCs estén disponibles; verificación en navegador.

## Evidencia de verificación (2026-10-15)

- Flutter: 535 pruebas correctas y `flutter analyze` sin incidencias.
- Bootstrap web: 6 pruebas Node correctas; coaching: 3 pruebas Deno correctas.
- Contrato SQL local con Postgres/PGlite: PASS. Smoke SQL remoto con RLS y
  rollback: PASS. Migración registrada en el proyecto correcto.
- Asesores de seguridad: RPCs SECURITY DEFINER expuestas intencionalmente a
  authenticated con validación de ownership; aviso existente de protección de
  contraseñas filtradas desactivada. No se cambiaron ajustes de Auth.
- Build web y publicación Firebase correctos; arranque y panel autenticado
  comprobados en navegador después de publicar, sin crear sesiones del usuario.
- La copia de sesión conserva las series previas, las sustituciones y extras;
  las cargas de 0 kg se conservan en el modal y los borradores.
- Smoke HTTP remoto completo: PASS con autenticación, sustitución parcial,
  extra a 0 kg, conservación de logs, coaching, cierre automático, resumen 4/4,
  protección de sesiones cerradas y métricas semanales. Limpieza QA: PASS.
