# Simulación local del coach

Un Supabase **local** con el esquema de producción, un usuario de prueba con
~9 semanas de entrenos y la app de iOS conectada a él. Sirve para probar el
coach de punta a punta sin tocar producción.

## Qué simula `simulate.ts`

- Cuenta de prueba **`coach.sim@gym.test`** (contraseña `CoachSim-Local-2026`).
  Solo existe en el Supabase local; el script se niega a correr contra otra URL.
- Rutina *Coach sim · Torso / Pierna*, 8 ejercicios con rangos (6–8, 8–12, …),
  incrementos por equipo, uno de peso corporal (Fondos) y uno estancado
  (Curl martillo, sin ganancia de fuerza).
- 21 sesiones en 62 días con un atleta modelado: fuerza que sube cada semana,
  fatiga entre series, algo de ruido, **una pausa de 18 días** (con pérdida
  del 5 %) y **un mal día** (−10 % solo esa sesión).
- Cada sesión sigue el camino real del cliente: inserta la sesión, pide el
  plan (`get_session_exercises_v1`), usa la sugerencia del coach, registra las
  series y cierra con la Edge Function `finalize_workout_session_v1`, que
  genera el coaching (v2 + v1 en sombra), escribe `coaching_events` y
  recalcula `exercise_session_stats`.
- Al final imprime lo que la app precargará hoy (`get_next_targets_v1` como
  el usuario).

El generador es determinista: dos ejecuciones dan el mismo resultado.

## Pasos

```bash
bash scripts/local_coach_sim/setup_local.sh
eval "$(supabase status --workdir build/local-coach-sim -o env | grep -E '^(API_URL|ANON_KEY|SERVICE_ROLE_KEY)=')" && export API_URL ANON_KEY SERVICE_ROLE_KEY
deno run --allow-net --allow-env scripts/local_coach_sim/simulate.ts
```

`setup_local.sh` no modifica el repo:

- Copia `supabase/` a `build/local-coach-sim`.
- Añade, solo en esa copia, el `schema.sql` histórico como migración `000_`. Las migraciones del repo empiezan con `ALTER` y lo necesitan.
- Añade también los permisos que el proyecto de producción da a los roles de la API.
- Arranca en los puertos 5632x, para convivir con otros proyectos locales.

Si cambias una Edge Function o una migración, vuelve a ejecutar
`setup_local.sh`: trabaja sobre una copia y la recrea desde cero.

Para pararlo y borrar la copia: `bash scripts/local_coach_sim/setup_local.sh stop`.

## Banco de escenarios y volumen

- `scenarios.ts`: 12 perfiles de atleta (novato, estancado, regresión real, pausa larga, asistencia irregular, va al fallo, no sigue al coach, rutina sin rango…) × N atletas sobre el motor real, sin base de datos. Unas 113 000 sesiones en ~1,5 s.
  `deno run --allow-read scripts/local_coach_sim/scenarios.ts 200`
- `compare.ts`: las mismas semillas con variantes del motor (`EngineOptions`) y de la tabla de pausa, para medir antes y después.
  `deno run --allow-read scripts/local_coach_sim/compare.ts 200`
- `load.ts`: volumen contra el Supabase local por el camino real (20 usuarios a la vez y un veterano con un año), con latencias.
  `deno run --allow-net --allow-env scripts/local_coach_sim/load.ts 20 52` (tarda ~6 min por el rate limit de 30 cierres/min por usuario).

Resultados y propuestas: `docs/coach/SIMULACION_ESCENARIOS.md`.

## App de iOS contra el Supabase local

Sin tocar `Config/Secrets.xcconfig`, compila pasando la URL y la clave como
ajustes de compilación (pisan los del xcconfig):

```bash
xcodebuild build -project GymTracker.xcodeproj -scheme GymTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/local-sim \
  'SUPABASE_URL=http:/$()/127.0.0.1:56321' "SUPABASE_ANON_KEY=$ANON_KEY"
xcrun simctl install booted build/local-sim/Build/Products/Debug-iphonesimulator/GymTracker.app
```

Inicia sesión con `coach.sim@gym.test`. "Entrenar hoy" precarga el peso del
coach y "La última vez" muestra "Coach · <motivo>".

## Qué encontró (2026-10-24)

La primera ejecución destapó cuatro fallos del motor v2, ya corregidos y con
test en `engine_v2_test.ts`:

1. Un ejercicio en el que el atleta llegaba al máximo del rango con menos peso
   se leía como regresión: el curl bajaba 2 kg por sesión hasta 0 kg.
2. Un solo mal día disparaba "regresión" y bajaba la carga de toda la sesión.
3. "Estancamiento" falso cuando el atleta paraba en el máximo del rango: el
   e1RM queda topado y parece plano.
4. El reset tras dos fallos bajaba un 10 % fijo aunque la fuerza diera para
   bajar menos.

También mostró que comparar el acierto del v2 con el del v1 no mide nada:
ver *Métricas de producto* en `docs/coach/PLAN_COACH_V2.md`.
