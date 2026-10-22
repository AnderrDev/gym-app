# 05 · Lógica de negocio que hoy vive solo en el cliente

El servidor calcula **cuatro** cosas: el plan congelado de la sesión
(`exercise_plan`), los conteos de series (`view_workout_sessions_summary`), el
coaching final (`generate_coaching_v1`) y los insights semanales
(`compute_weekly_insights_v1`). **Todo lo demás está en Dart** y la web tendrá
que reimplementarlo o, mejor, moverlo al servidor (ver
[06](06_riesgos_y_plan_web.md)). Rutas relativas a `lib/`.

No existe lógica de rachas (*streaks*).

## 1. Fechas

- La semana empieza en **lunes**: `startOfWeek(d) = d − (weekday − 1)` días,
  aritmética de calendario local (sin desfases por cambio de hora)
  — `core/utils/calendar_dates.dart`.
- `session_date` = **hoy en hora local** (`YYYY-MM-DD`); nunca la fecha
  "programada" del día de rutina.
- Semana = `[lunes, lunes+6]` inclusive. No se navega a semanas futuras.
- `day_of_week`: 1 = lunes … 7 = domingo. Etiquetas `Lun..Dom`, `L M X J V S D`.

⚠️ El servidor usa lunes **UTC** si no recibe `week_start`, y cierra con
`completed_at` en UTC. Una web que calcule fechas en UTC asignaría otro día a
entrenamientos cerca de medianoche.

## 2. Plan semanal y "TE TOCA HOY"

`features/workout/domain/usecases/get_weekly_plan.dart`

Entradas: días de la rutina + sesiones de la semana (vista resumen).

Estado de cada día:
- `inProgress`: hay una sesión abierta (gana sobre las cerradas).
- Si no, se mira la sesión cerrada más reciente:
  `completed` si `total_completed_sets ≥ (total_target_sets > 0 ? total_target_sets : Σ target_sets del día)`,
  si no `completedPartial`.
- `pending`: sin sesiones esta semana.

Día recomendado (`dashboard_weekly_view.dart`):
1. El día `inProgress` si existe (etiqueta "EN CURSO").
2. Si no, el primer día (orden `day_of_week`) **sin sesión esta semana** con `day_of_week ≥ hoy`.
3. Si no, el primer día sin sesión cualquiera.
4. Si no queda ninguno → "¡Semana completada!".

Contador "N de M entrenamientos hechos": N = días `completed` o
`completedPartial`; M = nº de días de la rutina.
Con varias rutinas asignadas se recuerda en el dispositivo la última elegida.

## 3. Reglas de la sesión

- Una sola sesión abierta (la BD lo impone; el cliente reutiliza la existente).
- Reutiliza la sesión de (día, hoy) aunque esté cerrada → reabrir el día muestra lo ya hecho.
- Rechazos: sesión abierta de **otro día** u **otra fecha** (ver [04](04_flujos_cliente.md#iniciar-startworkoutforday)).
- Sesión cerrada = solo lectura.
- Se puede finalizar con 0 series (el resumen dice "Faltan N series…").
- No se puede borrar el día ni la rutina que se está entrenando (**solo cliente**).
- Adaptar sesión: validación sets 1..100, reps 1..1000, peso 0..10000; al
  sustituir, series por defecto = restantes; si no, 3×10 a 0 kg.

## 4. Series completadas

`features/workout/domain/workout_completion.dart`:
- objetivo = Σ `target_sets`; hechas = Σ `min(target_sets, logs del ejercicio)`.
- "¡Rutina completada!" si objetivo > 0 y hechas ≥ objetivo; si no "Sesión finalizada · Faltan N series".
- Al registrar la **última** serie objetivo no arranca descanso.

## 5. Coaching

Hay **tres** motores distintos:

| | Dónde | Cuándo | Historial que mira |
|---|---|---|---|
| Final (autoridad) | servidor `generate_coaching_v1` | al finalizar, se guarda | última sesión cerrada con el ejercicio, **cualquier día** |
| En vivo / resumen previo | cliente `presentation/shared/utils/workout_performance_analyzer.dart` | tarjeta del ejercicio y hoja de resumen antes de guardar | 2 de las 3 últimas sesiones **del mismo día de rutina** |
| Por serie | cliente `presentation/shared/utils/set_feedback.dart` | 8 s tras guardar cada serie | solo la serie vs objetivo |

**Motor en vivo**:
- score = `0.45·(pesoMedio/objetivoPeso) + 0.45·(repsMedias/objetivoReps) + 0.1·clamp(series/objetivoSeries, 0, 1)`
  (cada ratio = 1 si su objetivo es 0).
- Misma forma que el servidor: código en `recommendation`, frase en `feedback`.
- Bajar peso (`DECREASE_WEIGHT`, score ≤ 0.7) si: series completas, reps no
  cumplidas, peso ≤ objetivo, no subió respecto a la última, y (empeora reps
  con igual o menos peso, o lleva 2 sesiones sin llegar a las reps).
- Si no: `IN_PROGRESS` (faltan series; no accionable) → `MAINTAIN` (peso bajo
  objetivo) → `MAINTAIN` (subió peso y consolida) → `INCREASE_REPS` ("baja
  2.5kg" si pesa) → `INCREASE_WEIGHT` (score 1.2, "¡SUPERACIÓN!") → `MAINTAIN`
  (objetivo cumplido, 1.0).
- Sólo son pistas durante el entreno: no se envían al finalizar (el servidor
  ignora el coaching del cliente). Tras un finalize desde el outbox, el
  SyncWorker lee el coaching del servidor y lo guarda en local.
- `CoachingAnalysis.fromJson` es tolerante a tipos inesperados y normaliza el
  formato viejo (frase en `recommendation`, código en `feedback`).

**Feedback por serie**: umbral "reps muy bajas" = `reps < max(4, 0.6·target_reps)`
(mismo umbral que `DECREASE_WEIGHT` del servidor, duplicado a mano). Casos:
superó objetivo, más peso consolidando, más peso con pocas reps, peso por
debajo, reps no cumplidas (si muy bajas: "baja 2.5 kg"), objetivo cumplido.
Con objetivo de peso 0 no se evalúa el peso.

Color de la tarjeta de coaching: verde si score ≥ 1.0.

## 6. Resumen al finalizar (antes de guardar)

`routine_day/widgets/workout_summary_bottom_sheet.dart`, `routine_day_page.dart`:
- **Volumen** = Σ peso×reps de todas las series (extras incluidos).
- **Récord** de un ejercicio si `max(peso hoy) > max(peso en la sesión anterior del mismo día de rutina)` y > 0.
  No es un récord absoluto.
- **Vs sesión anterior**: media de peso y nº de series; "=" si |Δ| < 0.05.

## 7. Estadísticas

- **1RM estimado** (Epley): `peso · (1 + reps/30)`; reps ≤ 1 → peso; ignora
  series de 0 reps; si hay alguna serie de ≤ 12 reps descarta las de > 12; máximo
  de la sesión (`domain/entities/exercise_history_session.dart`).
- Historial de ejercicio agrupado **por fecha** (dos sesiones el mismo día se funden).
- Gráficas: actual = último valor, récord = máximo, delta = último − penúltimo.
  Rangos 1/3/6 meses = 30/91/182 días desde la sesión más reciente.
- Progreso: últimas 8 semanas lunes–domingo (0 en vacías), solo sesiones cerradas.
- Insights de varias rutinas: se suman y se recalculan adherencia y tendencia en
  el cliente (`progress_bloc.dart`). La tarjeta de Progreso muestra "—" si la
  semana anterior no tuvo volumen.

## 8. Precarga de peso y reps

`exercise/widgets/exercise_card.dart`, prioridad:
1. lo ya registrado en esa serie;
2. borrador local (serie desmarcada);
3. la serie anterior de esta sesión (si subiste en la 1, la 2 arranca igual);
4. si el objetivo es 0 kg, el ejercicio no es extra ni sustituto, y la "última vez" tuvo peso > 0 → la última vez;
5. el objetivo.

Registro de un toque: solo si hay reps > 0; con 0 kg solo si el peso corporal
está confirmado (la última vez o una serie de hoy fue a 0 kg).
Hoja de serie: ±2.5 kg, atajos −5/−1/+1/+5; válido peso 0..10000, reps 1..1000.

## 9. Descanso y duración estimada

- Descanso por defecto **90 s** (columna, RPCs y cliente coinciden).
- Arranca al registrar una serie **nueva**; no al editar ni al desmarcar; no tras la última serie del entrenamiento.
- Cuenta atrás contra hora de fin; ±15 s.
- Editor de rutina: series 1..20, reps 1..50, descanso 0..600 s en pasos de 15.
- Duración estimada de la previa: Σ por ejercicio `series·40 s + (series−1)·descanso`
  + 60 s por cambio de ejercicio → minutos hacia arriba → múltiplo de 5 superior ("≈ N min").

## 10. Formato

- Peso: máx. 1 decimal, coma decimal ("37,5"); 0 kg = "Peso corporal" (en el
  editor de rutina, "sin carga").
- Volumen: entero con separador de miles es-ES ("1.770 kg"); ejes compactos "1,2k".
- Búsqueda: minúsculas y sin tildes sobre nombre y grupo muscular.
