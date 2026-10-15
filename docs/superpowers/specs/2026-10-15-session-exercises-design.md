# Ejercicios adaptables por sesión

Diseño aprobado en conversación: sustituir un ejercicio, añadir ejercicios extra,
confirmar series/repeticiones/peso, conservar las series realizadas y aplicar los
cambios solo a la sesión actual. La rutina habitual permanece independiente.

## Comportamiento

- Cada sesión abierta conserva una copia de sus ejercicios y objetivos.
- Sustituir conserva los logs del ejercicio original y reduce su objetivo a las
  series ya realizadas; crea el sustituto para las series pendientes confirmadas.
- Añadir crea un objetivo adicional. Series extra de un ejercicio no compensan
  series faltantes de otro: los conteos de cumplimiento se limitan por ejercicio.
- Un ejercicio del catálogo aparece como máximo una vez por sesión. No se permite
  sustituir un ejercicio sin series pendientes ni modificar sesiones cerradas.
- Peso/repeticiones no se transfieren automáticamente entre ejercicios distintos.
- El historial muestra los nombres reales, la relación de sustitución y los logs
  originales. Las sesiones antiguas sin copia mantienen su lectura compatible.
- Cambiar objetivos durante la sesión actualiza esa copia, no la rutina base.

## Arquitectura y contratos

`workout_sessions.exercise_plan jsonb` contiene una lista de objetos compatibles
con ExerciseModel: id, routine_day_id, name, muscle_group, target_sets, target_reps,
target_weight, rest_timer_seconds; además is_extra, replaces_exercise_name y
replaced_by_exercise_name. Los objetivos cero identifican originales sustituidos
antes de registrar series y no se muestran como ejercicios pendientes.

RPCs con ownership, sesión bloqueada en escritura y transacción atómica:

1. get_session_exercises_v1(p_session_id uuid) -> jsonb (array). Inicializa la copia
   solo para sesiones abiertas; leer una cerrada no la modifica.
2. adapt_session_exercise_v1(p_session_id uuid, p_exercise_id uuid,
   p_target_sets integer, p_target_reps integer, p_target_weight numeric,
   p_replace_exercise_id uuid default null) -> jsonb (plan resultante).
3. update_session_exercise_target_v1(p_session_id uuid, p_exercise_id uuid,
   p_target_weight numeric, p_target_reps integer) -> jsonb (plan resultante).

Validación: conjuntos 1..100, repeticiones 1..1000, peso finito 0..10000;
selección del catálogo existente; duplicados rechazados; máximo 100 ejercicios.
Campos descriptivos proceden del servidor. La vista resumen usa el plan cuando
existe, con fallback legacy. Coaching usa los objetivos de la sesión y compara
solo logs del mismo exercise_id. No se cambian contratos HTTP de Edge Functions.

## UI

Acción «Sustituir ejercicio» para el ejercicio con series pendientes, «Añadir
ejercicio extra» durante una sesión abierta. Modal con búsqueda del catálogo,
configuración de objetivos, explicación «Solo esta sesión», validación y errores
recuperables. Se conserva Manrope, los colores del tema y controles Material.

## Verificación

Pruebas SQL de ownership, sesiones cerradas, inicialización idempotente,
sustitución parcial y completa, extras, duplicados, persistencia y conteos.
Pruebas Flutter de repositorio/modelo/bloc y modal. flutter analyze y flutter test
completos; build web; contrato Edge cuando haya acceso a la base. No publicar
un frontend que dependa de RPCs sin desplegar primero la migración.
