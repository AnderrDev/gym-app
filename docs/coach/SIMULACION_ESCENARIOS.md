# Coach v2 — banco de escenarios y prueba de volumen

Fecha: 2026-10-24 · Herramientas: `scripts/local_coach_sim/` (ver su README).

## 1. Qué se probó

**Banco de escenarios** (`scenarios.ts`, `compare.ts`): el motor real
(`engine_v2.ts`) con la misma semántica de historial que el servidor, sin base
de datos.
- 12 perfiles de atleta × 200 atletas × 6 ejercicios tipo, ~113 000 sesiones.
- Mismas semillas para comparar variantes.
- El banco completo tarda ~1,5 s.

| Perfil | Qué modela |
|---|---|
| novato | gana 2–3,5 %/semana, mucho ruido |
| intermedio | 0,5–1,2 %/semana |
| avanzado | 0,1–0,4 %/semana |
| estancado | sin ganancia |
| regresion | −12 % en 4 semanas (enfermedad) |
| pausa | 5 semanas sin entrenar a mitad |
| irregular | 2–20 días entre sesiones |
| amrap | va al fallo (no para en el máximo del rango) |
| no_sigue | sigue al coach la mitad de las veces |
| ego | cuando no sigue al coach, sube un incremento |
| sin_rango | rutina con un solo objetivo de reps |
| mal_calibrado | peso inicial de la rutina +20 % |

**Volumen** (`load.ts`) contra el Supabase local, por el camino real
(PostgREST + Edge Functions):
- 20 usuarios simultáneos (21 sesiones cada uno);
- un "veterano" con un año (150 sesiones).

## 2. Resultados con el motor anterior al banco

| perfil | acierto | fallos | carga/ideal | captura | vaivenes/10 | imposibles | lag regresión |
|---|---|---|---|---|---|---|---|
| novato | 83,7 % | 15,9 % | 0,89 | 1,15 | 1,06 | 1,1 % | — |
| intermedio | 80,3 % | 20,4 % | 0,92 | 0,70 | 1,34 | 1,3 % | — |
| avanzado | 79,3 % | 22,0 % | 0,92 | −0,25 | 1,38 | 1,5 % | — |
| estancado | 77,9 % | 23,5 % | 0,92 | — | 1,39 | 1,4 % | — |
| regresion | 77,5 % | 23,1 % | 0,92 | — | 1,27 | 1,2 % | 2,9 sesiones |
| pausa | 81,9 % | 18,8 % | 0,91 | 0,47 | 1,44 | 1,3 % | — |
| irregular | 94,1 % | 10,7 % | **0,83** | **−0,16** | **2,08** | 0,7 % | — |
| amrap | 78,0 % | 22,9 % | 0,91 | 0,63 | 1,48 | 1,9 % | — |
| no_sigue | 82,4 % | 17,6 % | 0,90 | 0,56 | 0,50 | 0,5 % | — |
| ego | **55,7 %** | **52,6 %** | 1,10 | 2,52 | 2,91 | 5,6 % | — |
| sin_rango | **63,6 %** | **36,4 %** | 0,94 | 0,85 | **3,26** | **5,1 %** | — |
| mal_calibrado | 77,9 % | 24,6 % | 0,91 | −1,13 | 1,31 | 4,7 % | — |

Métricas:
- **acierto:** sugerencias seguidas tras las que se cumplieron series y reps mínimas.
- **fallos:** exposiciones con alguna serie bajo el mínimo.
- **carga/ideal:** carga final frente a la carga con la que la fuerza real da justo el mínimo de reps.
- **captura:** ganancia de carga entre ganancia de fuerza real (1 = la carga sigue a la fuerza).
- **imposibles:** sugerencias por encima de lo que el atleta podía ese día.

Lectura:
- **Seguro:** nunca más de 3–5 bajadas seguidas (8 con "ego"). Detecta una regresión real en ~3 sesiones.
- **Conservador:** la carga queda ~8 % por debajo del máximo para el mínimo de reps.
- **Lento con intermedios y avanzados:** captura 0,70 y −0,25. La doble progresión exige todas las series en el máximo y la fatiga entre series rara vez lo permite.
- **Sin rango funciona mal:** sube en cuanto se cumple el objetivo, falla la vez siguiente y baja. Son 3,3 vaivenes cada 10 sesiones.
- **La pausa se aplicaba de más:** con 14–20 días entre sesiones recortaba un 7,5 % cada vez. El atleta irregular acababa con menos carga que al empezar.
- **"Estancamiento" daba falsas alarmas:** saltaba casi igual en un intermedio (12,6 %) que en uno estancado de verdad (18,4 %).

## 3. Variantes probadas (mismos atletas)

| Variante | Efecto | Decisión |
|---|---|---|
| **Sin rango: confirmar 2 sesiones antes de subir** | sin_rango: acierto 63,6 → **74,0 %**, fallos 36,4 → **26,6 %**, vaivenes 3,26 → **2,05**, imposibles 5,1 → **2,8 %**. Resto, igual | ✅ por defecto |
| **Pausa suave** (<21 d sin cambio; 21–27 −5 %; 28–55 −10 %; ≥56 −20 %) | irregular: vaivenes 2,08 → **0,57**, captura −0,16 → **0,53**, carga/ideal 0,83 → 0,90. Los fallos suben 10,7 → 16,8 %, aún por debajo del 20 % de un atleta regular. Pausa de 5 semanas: igual | ✅ migración `20261024163000` |
| **Estancamiento por carga y reps** (además del e1RM plano, ni carga ni reps suben en 4 sesiones) | falsas alarmas: novato 4,1 → **2,1 %**, intermedio 12,6 → **8,1 %**. En estancado: 18,4 → 13,3 %. No cambia carga ni seguridad | ✅ por defecto |
| Rango completado = 1.ª serie en el máximo y el resto a ≤1 rep | captura +0,13, pero fallos **+8 puntos**, vaivenes +70 % e imposibles ×2 | ❌ descartada |
| Discos de 1,25 kg en banca y sentadilla | +0,8 puntos de acierto, −0,8 de fallos, algo menos de vaivén. La captura no cambia: el motor ya sube ≥2,5 % de la carga | ➖ opcional (dato de catálogo) |

Con las tres adoptadas (`ahora` en `compare.ts`):
- mejoran sin_rango, irregular y las alarmas de estancamiento;
- el resto de perfiles queda idéntico.

## 4. Volumen (Supabase local, por el camino real)

| Medida | Resultado |
|---|---|
| 20 usuarios simultáneos × 21 sesiones | 27 s; `finalize` p50 **100 ms**, p95 **190 ms** |
| Veterano, 150 sesiones (un año) | `finalize` p50 **77 ms**, p95 158 ms; con historial largo, igual (p50 67 ms) |
| `get_next_targets_v1` (veterano) | p50 **3 ms**, p95 11 ms; usa `coaching_events_user_exercise_idx` |
| `get_coaching_inputs_v2` (veterano) | p50 **2 ms** |
| `refresh_exercise_session_stats_v1` (veterano) | **13 ms** |
| Máximo puntual | 3,1 s: arranque en frío de la Edge Function (primer uso del worker) |
| Integridad (591 sesiones, 7 155 series) | 0 sesiones sin métricas; 0 sin evento v1 o v2; 0 recomendaciones sin etiqueta salvo la última de cada ejercicio |

El rendimiento no es un problema a esta escala. `get_next_targets_v1` lee
todos los eventos del usuario y luego se queda con el último por ejercicio. Es
lineal con el historial, pero con un año son ~1 700 filas y 4 ms.

## 5. Propuestas

Aplicadas en este cambio:
1. **Sin rango → confirmar antes de subir.** Opción por defecto del motor.
2. **Pausa suave.** Nueva migración de `get_next_targets_v1`.
3. **Estancamiento por carga y reps.** Opción por defecto del motor.

Pendientes (requieren decisión de producto o de cliente):

4. **Avisar en la app de las rutinas sin rango.** Aunque confirmar ayuda, un rango (8–12) da mejores resultados que un objetivo único: acierto 80 % frente a 74 %. Proponer un rango al crear o editar un ejercicio.
5. **Adherencia visible.** Con "ego" (subir por cuenta propia) los fallos llegan al 53 % y el motor solo puede reaccionar. Mostrar en la tarjeta del coach cuándo el usuario se desvía y medir `followed` en producción.
6. **Ritmo configurable.** El coach es conservador por diseño (carga ~8 % bajo el máximo, captura 0,7 en intermedios). Ser más agresivo cuesta fallos (+8 puntos con la variante descartada). Si se quiere, que sea un ajuste del usuario ("conservador / estándar"), no el valor por defecto.
7. **Aislamientos ligeros.** Con mancuernas pequeñas el salto mínimo es grande: 6 → 8 kg es +33 %. El motor ya pide 2 reps extra antes de subir. Además, convendría ofrecer incrementos de 1 kg en el catálogo cuando el equipo lo permita.
8. **Precalentar las Edge Functions o asumir el arranque en frío** (3 s puntuales). Mostrar "Guardando…" ya lo cubre en la app.
9. **Retirar el v1 en sombra.** Ya no aporta información (ver `PLAN_COACH_V2.md`) y duplica los eventos.
