# Plan: Coach v2 — ingeniería de datos + modelos de progresión

Fecha: 2026-10-22 · Alcance: backend Supabase (este repo), gym_ios (`~/Desktop/gym_ios`) y app Flutter.

## 0. Resumen ejecutivo

- **Hoy no hay datos para entrenar ML.** Producción tiene 7 usuarios, 4 con sesiones, 23 sesiones, 225 series, 59 ejercicios (medido 2026-10-22). Un modelo entrenado con eso solo memorizaría ruido.
- **Lo que sí da el mejor resultado ahora:** un motor determinista basado en evidencia (doble progresión + detección de estancamiento sobre e1RM suavizado + señales de esfuerzo deducidas de las series), con **peso sugerido concreto** y guardarraíles de seguridad. Es lo que hacen en la práctica Fitbod, Juggernaut AI o RP, y la literatura no muestra ventaja de modelos complejos frente a reglas bien hechas.
- **La ingeniería de datos es la inversión clave:** registrar cada recomendación y su resultado (etiquetas), y una tabla de métricas por ejercicio y sesión. Así, cuando haya volumen (~1.000 resultados etiquetados), el paso a un modelo estadístico personalizado (bayes empírico + regresión logística) es un cambio de parámetros, no de arquitectura.
- **Antes de mejorar hay que unificar:** hoy existen **tres motores de coaching que se contradicen** (servidor, analizador en vivo de Flutter, reglas por serie en iOS), y Flutter guarda `recommendation`/`feedback` invertidos (riesgo B4).

## 1. Diagnóstico (estado actual)

### Datos
| Qué | Estado | Consecuencia |
|---|---|---|
| `set_logs` | solo peso, reps, `set_index`, `created_at` | sin esfuerzo declarado; se deduce de las series (ver fase 1c). No se pedirá RIR al usuario (decisión 2026-10-22) |
| `routine_exercises.target_reps` | un único valor | no hay rango → no se puede aplicar doble progresión. El seed ULPPL traía `reps_max` y se descarta al importar |
| `exercises` | `muscle_group` texto libre con variantes ("Pierna"/"Piernas", "Triceps"/"Tríceps"), `equipment` casi vacío | no se sabe si es compuesto o aislamiento ni el incremento de carga posible |
| `profiles` | solo `full_name` | sin unidades (kg implícito), sin experiencia |
| `workout_sessions.coaching_analysis` | jsonb sobrescrito, sin versión | no hay historial ni forma de evaluar si el coach acierta |
| Eventos / analítica | no existen | cero etiquetas para evaluar o entrenar |

### Motor (`generate_coaching_v1`)
- Árbol de `if/else` con medias de peso/reps contra **una** sesión anterior (cualquier rutina; los empates del mismo día se rompen por UUID).
- `performance_score` es una constante por rama (0.55…1.05), no una medida.
- Nunca dice **cuánto** subir o bajar.
- Sin tests del handler (solo 3 de `shouldReduceWeight`); el smoke test no valida el contenido.

### Clientes
- iOS decodifica de forma tolerante (campos extra se ignoran; códigos desconocidos → `.other(code)`). Muestra solo nombre, icono y `feedback`.
- Flutter tolera campos extra pero usa casts duros (`as int?`, `as bool?`); no mapea `MAINTAIN_WEIGHT`; usa `performance_score` para colorear el historial.
- **Ninguna app usa el coaching para precargar el peso de la siguiente sesión**: ambas precargan desde la última serie o el objetivo de la rutina. El coach es solo texto.
- Finalize offline: iOS muestra `coaching = []` y nunca lo vuelve a pedir; Flutter tampoco lo refresca tras el replay.

## 2. Principios de diseño

1. **Un solo motor, en el servidor.** Mismo consejo en iOS, Flutter y web. Los clientes solo presentan.
2. **Contrato aditivo.** Se mantienen los 4 códigos de `recommendation`; todo lo nuevo va en campos opcionales. Ningún cliente actual se rompe.
3. **Determinista, explicable y versionado.** Cada salida lleva `engine_version` y `reason_code`; las reglas son funciones puras con tests.
4. **Seguridad antes que optimización.** Límites duros de salto de carga, nunca subir peso y reps a la vez, conservador en arranque en frío.
5. **Instrumentar desde el día uno.** Cada recomendación se guarda con sus features y luego su resultado; así se mide y, más adelante, se entrena.

## 3. Fases

### Fase 0 — Saneamiento (prerrequisito)

1. Desplegar `20261021130000_guard_session_completion_columns.sql` (pendiente según `docs/backend/06_riesgos_y_plan_web.md`).
2. Extraer la lógica de `generate_coaching_v1/index.ts` a un módulo puro (`engine.ts`) y cubrir las ramas actuales con tests Deno. Es la red de seguridad para el cambio de motor.
3. Flutter:
   - Corregir el swap `recommendation`/`feedback` del analizador local (B4).
   - Mapear `MAINTAIN_WEIGHT` y `DECREASE_SETS` en `CoachingMessages`.
   - Cambiar los casts duros de `CoachingAnalysis.fromJson` por lecturas tolerantes.
   - Degradar `WorkoutPerformanceAnalyzer` a "pistas en vivo" durante el entreno; el veredicto final es siempre el del servidor.
4. Ambos clientes: tras el replay de un finalize offline, volver a leer `coaching_analysis`.

**Hecho cuando:** un único motor decide; los tests de la fase pasan; la app no muestra consejos contradictorios.

### Fase 1 — Fundación de datos

Migraciones nuevas (timestamped, aditivas):

**a) Catálogo de ejercicios**
- `exercises.movement_type` (`compound` | `isolation`), `exercises.body_region` (`upper` | `lower` | `core`), `exercises.load_increment_kg numeric` (por defecto: compuesto inferior 2.5–5, compuesto superior 2.5, aislamiento/máquina 1–2.5).
- Normalizar `muscle_group` (unificar variantes) y backfill de los 59 ejercicios.

**b) Prescripción con rango**
- `routine_exercises.target_reps_max int NULL` (si es NULL, rango = `target_reps`..`target_reps`).
- Propagarlo al snapshot `exercise_plan` (`get_session_exercises_v1`, `adapt_session_exercise_v1`).
- Reimportar `reps_max` del seed ULPPL.

**c) Esfuerzo deducido, sin preguntar al usuario**

Decisión 2026-10-22: **no se captura RIR**. La mayoría de usuarios no sabe estimar cuántas repeticiones le quedaban y la pregunta añade fricción. El esfuerzo se infiere de lo que ya se registra:
- **Caída de reps entre series** al mismo peso (p. ej. 10-9-7): una caída fuerte indica series cerca del fallo; reps estables indican margen.
- **Posición en el rango:** todas las series en el máximo del rango dos sesiones seguidas indica que la carga se quedó corta.
- **Consistencia entre sesiones:** mismas reps al mismo peso varias veces = carga dominada; reps que bajan = fatiga o carga excesiva.
- **Series incompletas o por debajo del mínimo** = carga demasiado alta.

El e1RM se calcula asumiendo que la serie terminó cerca del fallo (estimación conservadora). Sin RIR la confianza es algo menor, por eso el motor exige 2 sesiones confirmando antes de subir carga cuando la caída de reps entre series es fuerte (señal de que las series fueron al límite).

**d) Tabla de métricas `exercise_session_stats`** (una fila por usuario × ejercicio × sesión cerrada)
- `best_e1rm`: Epley `w·(1 + reps/30)` sobre la mejor serie con ≤12 reps; las series de más de 12 marcan `low_confidence`.
- `top_weight`, `total_reps`, `volume_load` (Σ peso×reps), `sets_done`, `sets_target`.
- `rep_shortfall` (reps objetivo − reps medias), `rep_dropoff` (caída de reps de la primera a la última serie), `at_range_top` (todas las series en el máximo del rango).
- `days_since_prev` (días desde la exposición anterior del mismo ejercicio), `exposure_n` (número de exposición).
- `is_bodyweight` (peso 0 → progresión solo por reps).
- Escrita por una RPC idempotente `refresh_exercise_session_stats_v1(session_id)` que llama `finalize_workout_session_v1` antes de generar el coaching, más una función de backfill para el histórico (225 series: trivial).
- Se usa tabla en vez de vista materializada porque no hay `pg_cron` y el refresco incremental por sesión es barato.
- RLS: `select` del propio usuario; escritura solo desde funciones `SECURITY DEFINER` / `service_role`.

**e) Registro de recomendaciones `coaching_events`** (append-only)
- Al recomendar: `session_id`, `user_id`, `exercise_id`, `engine_version`, `recommendation`, `reason_code`, `suggested_weight`, `suggested_reps`, `features jsonb` (snapshot de entradas), `created_at`.
- Al cerrar la **siguiente** sesión con ese ejercicio, el mismo refresh rellena el resultado: `outcome_session_id`, `followed` (usó el peso sugerido ±1 incremento), `hit_target` (alcanzó las reps objetivo con esa carga), `e1rm_delta`.
- Estas son las etiquetas para medir y, en la fase 4, entrenar.

**Hecho cuando:** el backfill cuadra con el histórico, los tests SQL cubren el refresh y el etiquetado, y `docs/backend` está actualizado.

### Fase 2 — Motor v2 basado en evidencia (`engine_version = "2.0"`)

Entradas: últimas ≤6 exposiciones del ejercicio desde `exercise_session_stats` (cualquier rutina, ordenadas por `completed_at`, no por UUID), la prescripción del snapshot y las señales de esfuerzo deducidas (fase 1c).

Orden de evaluación (la primera regla que aplica decide):

1. **Datos insuficientes.** Si faltan series objetivo → `MAINTAIN` (`INCOMPLETE_SETS`).
2. **Vuelta tras pausa** (`days_since_prev`):

   | Pausa | Peso sugerido |
   |---|---|
   | < 14 días | normal |
   | 14–28 días | −5–10 % (`LAYOFF_SHORT`) |
   | 28–56 días | −10–20 % (`LAYOFF_MEDIUM`) |
   | > 56 días | −20–30 % y re-rampa en 2–3 sesiones (`LAYOFF_LONG`) |

3. **Arranque en frío** (menos de 2 exposiciones): solo `MAINTAIN` o `INCREASE_REPS`.
4. **Doble progresión con rango `[min, max]`:**
   - Todas las series en `max` (si la caída de reps entre series fue fuerte, se exige que se repita en la sesión siguiente) → `INCREASE_WEIGHT`, nuevo peso = actual + `max(load_increment_kg, 2.5 % del peso)`, redondeado al incremento y **con tope +10 %**; reps sugeridas = `min`.
   - Dentro del rango → `INCREASE_REPS` (+1 rep en la serie más baja). Plotkin 2022: subir reps es tan eficaz como subir carga para hipertrofia, así que no es una recomendación de segunda.
   - Por debajo de `min` → regla de fallos.
5. **Fallos consecutivos** a la misma carga: el 1.º → `MAINTAIN` (repetir); el 2.º → `DECREASE_WEIGHT` −5–10 % (`RESET`).
6. **Estancamiento:** si el EWMA del e1RM no mejora más de ~1 % en 3 exposiciones → `MAINTAIN` con `reason_code = PLATEAU` y sugerencia de variar el rango de reps.
7. **Regresión:** e1RM ≥5 % por debajo del pico reciente → `DECREASE_WEIGHT` (`REGRESSION`).
8. **Fatiga sistémica (a nivel sesión):** si ≥50 % de los ejercicios de la sesión regresan → `session_flags: ["DELOAD_SUGGESTED"]` (descarga: −30–50 % de series, misma carga o −10 %).

Guardarraíles siempre activos: nunca subir peso y reps a la vez; como máximo un incremento por sesión; tope +10 %; con peso 0 (peso corporal) solo progresión por reps.

**Contrato de salida (aditivo):**
```jsonc
{
  "exercise_id": "…", "exercise_name": "…",
  "completed_sets": 3, "target_sets": 3, "weight_met": true, "reps_met": true,
  "recommendation": "INCREASE_WEIGHT",        // mismos 4 códigos
  "feedback": "Completaste 3×12 con margen: sube a 42,5 kg y vuelve a 8 reps.",
  "performance_score": 1.03,                  // ahora = e1RM de hoy / e1RM esperado (EWMA)
  // nuevos, opcionales:
  "suggested_weight": 42.5, "suggested_reps": 8,
  "reason_code": "DOUBLE_PROGRESSION_TOP",
  "confidence": "high",                       // low | medium | high según exposiciones y consistencia
  "engine_version": "2.0"
}
```
Más `session_flags` a nivel de respuesta, y se guarda en `workout_sessions.coaching_analysis` sin cambiar su forma de array.

El texto de `feedback` sale de plantillas en español por `reason_code`, con los números interpolados. Así es consistente y traducible.

**Validación:**
- Suite de escenarios en tests Deno: progresión limpia, estancamiento, regresión, pausa, peso corporal, ejercicio sustituido o extra, arranque en frío, caída de reps fuerte vs. estable.
- Assertions de contenido en `scripts/contract_smoke_supabase.sh`.
- Despliegue con flag: v1 y v2 en paralelo durante 2 semanas guardando ambos en `coaching_events`; revisión manual de discrepancias (con 4 usuarios activos es una revisión cualitativa, no estadística). Después se activa v2.

### Fase 3 — Que el coach mande en el siguiente entreno (clientes)

- Nueva RPC `get_next_targets_v1(p_exercise_ids uuid[])`: devuelve la última sugerencia vigente por ejercicio (`suggested_weight`, `suggested_reps`, `reason_code`, antigüedad) desde `coaching_events`.
- Precarga de peso en ambas apps: **sugerencia del coach > última serie > objetivo de la rutina**. Se muestra como "Coach: 42,5 kg × 8" con el motivo en una línea; el usuario la ajusta con −/+ como siempre.
- Pantallas de cierre e historial: mostrar el peso sugerido y el motivo; el color sigue a `performance_score` (que ahora significa algo).
- Mostrar el aviso de descarga cuando llegue `DELOAD_SUGGESTED`.

**Métricas de producto** (consultas sobre `coaching_events`):
- **Acierto:** % de sugerencias seguidas en las que se alcanzan las reps objetivo. Meta: 70–85 %. Menos indica que el coach es agresivo; más, que es conservador.
- **Seguimiento:** % de veces que el usuario usa el peso sugerido. Si es bajo, el coach no se percibe como útil.
- **Progreso:** Δ e1RM a 4 y 8 semanas por ejercicio.

### Fase 4 — Personalización estadística (cuando haya datos)

**Puerta de entrada:** ≥1.000 recomendaciones con resultado etiquetado en `coaching_events` y ≥30 usuarios con ≥8 exposiciones. Hasta entonces esta fase no aporta.

1. **Bayes empírico de la tasa de progresión.**
   - Prior poblacional de la pendiente de e1RM por categoría (`movement_type` × `body_region`).
   - La pendiente de cada usuario se encoge hacia ese prior según cuántos datos tiene.
   - Ajusta el tamaño del incremento y el umbral de estancamiento por persona. Cabe en SQL.
2. **Regresión logística P(alcanzar reps objetivo).**
   - Variables: carga relativa al e1RM, reps objetivo, días desde la última vez, fallos recientes, caída de reps entre series y categoría.
   - Elige la carga con P ≈ 0.75.
   - Se entrena fuera de línea en Python (notebook en `tools/coach_model/`); los coeficientes van a una tabla `coach_model_params` que lee la Edge Function, con `engine_version = "3.0"`.
   - Validación temporal (entrenar con el pasado, evaluar con el futuro), calibración y comparación de acierto contra v2 en shadow antes de activarlo.
3. Los guardarraíles de la fase 2 siguen envolviendo cualquier salida del modelo.

### Fase 5 (opcional) — Narrativa con LLM

- Resumen semanal en lenguaje natural generado a partir de los datos de `exercise_session_stats`.
- El LLM **no decide cargas**: solo redacta.
- Va en la Edge Function, con límite de uso.

## 4. Lo que se descarta y por qué

| Opción | Motivo |
|---|---|
| Core ML / Create ML en el dispositivo | El consejo divergiría entre iOS, Flutter y web; `coaching_analysis` solo lo escribe el servidor |
| Redes neuronales / deep learning | Con cientos o miles de sesiones sobreajustan; no son explicables |
| Bandits / RL para elegir carga | La señal es lenta y ruidosa, y explorar con carga tiene riesgo de lesión; no hay trabajos revisados por pares que lo respalden |
| Readiness diario (sueño, agujetas) | Añade fricción en cada sesión; no se pide (mismo motivo que el RIR) |
| Pedir RIR / RPE por serie | Los usuarios no saben estimarlo con fiabilidad y añade fricción; el esfuerzo se deduce de las series (decisión 2026-10-22) |

## 5. Riesgos

- **Sin esfuerzo declarado:** el motor no distingue del todo "8 fáciles" de "8 al límite" en una sola sesión. Se mitiga con la caída de reps entre series y exigiendo confirmación en 2 sesiones; el acierto se vigila con `coaching_events`.
- **Calidad del catálogo:** `load_increment_kg` y `movement_type` mal puestos dan saltos incorrectos. El backfill necesita revisión manual de los 59 ejercicios.
- **Unidades:** todo es kg implícito. Si algún día hay libras, los incrementos dependen de la unidad. Fuera de alcance, pero se anota.
- **`session_date` local:** dos sesiones el mismo día. Ordenar por `completed_at`.
- **Ejercicios sustituidos en sesión:** las estadísticas se guardan por `exercise_id` real; la sustitución no hereda el historial del original.
- **Rate limit:** finalize invoca coaching dentro del límite compartido de 30/min. El refresh de estadísticas va en la misma llamada para no sumar invocaciones.

## 6. Orden de trabajo y repos

| # | Trabajo | Repo | Depende de |
|---|---|---|---|
| 0a | Desplegar guard + motor extraído con tests | gym_flutter (supabase) | — |
| 0b | Saneamiento de coaching en Flutter | gym_flutter (lib) | — |
| 0c | Refetch tras finalize offline | gym_ios + gym_flutter | — |
| 1 | Migraciones: catálogo, rango, stats, coaching_events + backfill | gym_flutter (supabase) | 0a |
| 2 | Motor v2 + shadow + smoke con assertions | gym_flutter (supabase) | 1 |
| 3a | `get_next_targets_v1` + precarga + UI de motivo | supabase + ambos clientes | 2 |
| 4 | Modelo personalizado | tools/ + supabase | puerta de datos |

0b y 0c pueden ir en paralelo con el backend. El cliente objetivo de las fases 1–3 es gym_ios. Cada migración o RPC nueva actualiza `docs/backend/`.

## 7. Decisiones abiertas para el producto

1. ~~¿Capturar RIR?~~ **Decidido 2026-10-22: no.** El esfuerzo se deduce de las series.
2. ¿Exponer el rango de reps (`min`–`max`) en el editor de rutinas o solo vía seed y backend al principio?
3. ¿El coach precarga el peso automáticamente o solo lo muestra como sugerencia que el usuario acepta con un toque?

## Fuentes principales

- ACSM 2009, progresión 2–10 % al superar el objetivo en 1–2 reps: https://sfu.ca/~ryand/kin343/ACSMresistance.pdf
- Plotkin 2022, subir carga vs subir reps: https://peerj.com/articles/14142
- Meta-análisis de autorregulación vs porcentajes (2021): https://pmc.ncbi.nlm.nih.gov/articles/PMC8762534/
- Helms 2018, RPE vs %1RM: https://pmc.ncbi.nlm.nih.gov/articles/PMC5877330/
- Precisión del RIR (Halperin 2021): https://sportrxiv.org/index.php/server/preprint/view/67
- Descargas en la práctica (Bell 2022): https://shura.shu.ac.uk/31253/
- Fórmulas de e1RM y su error por rango de reps: https://arxiv.org/abs/2603.17495
- Desentrenamiento y retención de masa muscular (Grgic 2022): https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9657634/
