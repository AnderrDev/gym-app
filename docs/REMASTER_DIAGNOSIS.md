# Diagnóstico de Remaster — Smart Gym Tracker

> Fecha: 2026-05-03
> Alcance: app Flutter completa (`lib/`), tests (`test/`, `integration_test/`), config (`pubspec.yaml`, `analysis_options.yaml`, `supabase.json`, `firebase.json`, scripts), backend cliente (data sources, edge function contracts vistos desde el cliente).
> Objetivo: catalogar todos los problemas reales (con evidencia `file:line`) que el remaster debe resolver para alcanzar las metas del proyecto: arquitectura SOLID, BLoC saneado, componentización con cero duplicidad, formularios reactivos, rediseño UI/UX, loaders unificados y endurecimiento "cero errores".

---

## 0. TL;DR

La app **funciona** pero está estructuralmente frágil:

- **Capa de presentación sobrecargada**: 3 widgets > 300 LOC, formularios crudos repetidos en 6 sitios, 33 invocaciones ad-hoc de `SnackBar`/`Dialog`/`BottomSheet`, 18 `CircularProgressIndicator` sin sistema, ~21 `context.push/go` esparcidos sin centralizar.
- **`WorkoutBloc` god-bloc** de 608 LOC con un `WorkoutState` sealed de 13+ estados que mezcla 6 subdominios (dashboard, plan semanal, día, sesión activa, historial, gestión, catálogo).
- **Manejo de errores roto en silencio**: `auth_remote_data_source.dart` lanza `Exception` plano y `auth_repository_impl.dart:26` espera `ServerException` → el `on ServerException` **nunca matchea** y todo cae al catch genérico que pierde contexto. Hay `catch (_) { /* ignorar */ }` en upsert de profiles.
- **Memory leaks confirmados**: `exercise_card.dart:321-326` crea dos `TextEditingController` en `showDialog` sin `dispose`.
- **Performance**: `workout_remote_data_source.dart:696-702` ejecuta N queries secuenciales en `reorderExercisesInDay` (N+1).
- **Clean Architecture rota**: `domain/usecases/get_weekly_plan.dart` importa desde `data/models/`.
- **Tema vacío**: `MaterialApp` sólo declara `ColorScheme`; `InputDecorationTheme`, `ButtonTheme`, `SnackBarTheme`, `BottomSheetTheme`, `DialogTheme`, `CardTheme`, `AppBarTheme`, `TextTheme` real → ausentes. Por eso cada widget redibuja sus estilos a mano.
- **Sin red de seguridad**: `main.dart` no awaitea `SupabaseConfig.init()`, no instala `FlutterError.onError` ni `PlatformDispatcher.instance.onError`, no usa `runZonedGuarded`, no hay `BlocObserver`.
- **Lints permisivos**: `analysis_options.yaml` con 0 reglas custom — `flutter analyze` reporta limpio por permisividad, no por ausencia de bugs.
- **Cobertura**: ~32% en ratio archivo-test, integration test es smoke superficial, 0 golden tests.
- **Drifts conocidos**: offline-first cableado pero comentado en DI; credenciales Supabase hardcoded como `defaultValue`; `target_muscle` ↔ `muscle_group` con fallback silencioso a `Desconocido`.

---

## 1. Métricas

| Métrica | Valor |
|---|---|
| Archivos productivos en `lib/` | 86 |
| Archivos de test (`*_test.dart`) | 28 |
| Ratio cobertura archivos | ~32% |
| Cobertura auth | 8/15 ≈ 53% |
| Cobertura workout | 20/71 ≈ 28% |
| Golden tests | 0 |
| Integration tests reales | 0 (los 3 existentes son smoke de UI) |
| LOC del bloc más grande (`workout_bloc.dart`) | 608 |
| LOC del widget más grande (`exercise_card.dart`) | 386 |
| `CircularProgressIndicator` directos | 18 (en 10 archivos) |
| `SnackBar` / `showDialog` / `showModalBottomSheet` ad-hoc | 33 (en 8 archivos) |
| `TextEditingController` directos | 13 |
| `TextField` crudo (sin `TextFormField`/Form) | en todas las pantallas |
| Dependencias clave faltantes | `shimmer`, `formz`/`reactive_forms`, `freezed`, `build_runner`, `golden_toolkit`, logger estructurado |

---

## 2. Hallazgos por severidad

### 2.1 CRÍTICOS (bloquean el objetivo "cero errores")

| # | Archivo:línea | Hallazgo | Impacto |
|---|---|---|---|
| C1 | `lib/main.dart:19` | `SupabaseConfig.instance.init()` se llama con `await` pero no hay `try/catch`. Si el handshake con Supabase falla → app crashea sin pantalla de error | Crash silencioso al arranque sin red |
| C2 | `lib/main.dart:12-24` | Sin `FlutterError.onError`, sin `PlatformDispatcher.instance.onError`, sin `runZonedGuarded`. Cualquier excepción no atrapada cae al log del sistema | Cero observabilidad de crashes en prod |
| C3 | `lib/main.dart:12-24` | No hay `BlocObserver` global. Imposible auditar transiciones de estado, errores en blocs ni race conditions | Bugs de estado invisibles |
| C4 | `lib/features/auth/data/datasources/auth_remote_data_source.dart:27,60` | `throw Exception('Login failed')` y `throw Exception('Registration failed')` — no `ServerException` | Rompe el contrato del repositorio |
| C5 | `lib/features/auth/data/repositories/auth_repository_impl.dart:26,43` | `on ServerException` nunca matchea (ver C4); todo cae al `catch (e)` genérico que devuelve `e.toString()` | Mensajes de error inútiles para el usuario; pérdida total del contexto del error original |
| C6 | `lib/features/auth/data/datasources/auth_remote_data_source.dart:40,72` | `catch (_) { /* Ignorar */ }` en upsert a `profiles`. Si RLS bloquea o hay error real, se silencia | Estado inconsistente entre Auth y `profiles` puede pasar desapercibido |
| C7 | `lib/features/workout/presentation/exercise/widgets/exercise_card.dart:321-326` | `TextEditingController` × 2 creados dentro de `_showRemoteTargetEditor()` (invocado por `build` cuando se abre un dialog) sin `dispose` | Memory leak acumulativo cada vez que el usuario edita objetivo |
| C8 | `lib/features/workout/data/datasources/workout_remote_data_source.dart:696-702` | `reorderExercisesInDay` hace `for { await client.from(...).update(...) }`. Una query por ejercicio | N+1 lento + ventana de inconsistencia si una falla a mitad de proceso |
| C9 | `lib/features/workout/domain/usecases/get_weekly_plan.dart` | El use case importa `import '../../data/models/routine_day_model.dart'` | Viola Clean Architecture; el domain depende de data |
| C10 | `lib/injection_container.dart:29-35` | Toda la wiring offline-first (`DatabaseHelper`, `NetworkInfo`, `SyncService`, `WorkoutLocalDataSource`) está comentada. `WorkoutRepositoryImpl` no recibe `localDataSource` | Promesa offline-first no cumplida; código vivo pero muerto |
| C11 | `lib/core/config/supabase_config.dart:11-13` | URL Supabase y `anon_key` hardcoded como `defaultValue` de `String.fromEnvironment` | Credenciales en repo (no rotables sin commit); contradice `--dart-define` declarado en README |
| C12 | `lib/main.dart:52-62` | `MaterialApp` sólo declara `ColorScheme`. Faltan `InputDecorationTheme`, `ElevatedButtonTheme`, `OutlinedButtonTheme`, `TextButtonTheme`, `SnackBarTheme`, `BottomSheetTheme`, `DialogTheme`, `CardTheme`, `ChipTheme`, `AppBarTheme`, `ProgressIndicatorTheme`, `DividerTheme`, `IconTheme`, `TextTheme` real | Cada widget redibuja a mano sus estilos → fuente raíz de la duplicación visual |
| C13 | `lib/analysis_options.yaml:23-25` | Cero reglas activadas (sólo `package:flutter_lints`). Sin `strict-casts`, `strict-inference`, `strict-raw-types`, `unawaited_futures`, `avoid_dynamic_calls`, `prefer_const_constructors`, `require_trailing_commas` | "0 issues" en `flutter analyze` no significa nada. Bugs como `unawaited` futuros pasan |
| C14 | Sin `.github/workflows/` | Sin CI. `scripts/contract_smoke_supabase.sh` es manual | Cualquier regresión llega a main sin filtro |

### 2.2 ALTOS

| # | Archivo:línea | Hallazgo |
|---|---|---|
| A1 | `lib/features/workout/presentation/bloc/workout_bloc.dart` (608 LOC) | God-bloc que maneja dashboard + plan semanal + día + sesión activa + historial + gestión + catálogo |
| A2 | `lib/features/workout/presentation/bloc/workout_state.dart:14-162` | `WorkoutState` sealed con 13 subclases: `WorkoutInitial`, `WorkoutLoading`, `WorkoutError`, `RoutinesLoaded`, `WeeklyPlanLoaded`, `DayInfoLoaded`, `DayWorkoutStarted`, `SessionHistoryLoaded`, `SavingSetLog`, `SetLogSuccess`, `WorkoutFinishedSuccess`, `ExercisePerformanceLoaded`, `ActiveSessionDetected`, `ManagementSuccess`, `AllRoutinesLoaded`. `buildWhen` es ingobernable |
| A3 | `lib/features/auth/presentation/pages/login_page.dart:157-200` vs `register_page.dart:166-209` | `_buildTextField(...)` privado idéntico en ambas páginas (~40 LOC duplicadas, sin `autofillHints`, sin `textInputAction`, sin toggle ver/ocultar contraseña, sin `onSubmitted` para Enter) |
| A4 | `lib/features/auth/presentation/pages/login_page.dart:32-40` | Validación con `if (email.isEmpty \|\| password.isEmpty) ScaffoldMessenger... showSnackBar(...)`. Sin formato de email, sin longitud de password, sin `Form`/`TextFormField`/`FormState` |
| A5 | `lib/features/workout/data/datasources/workout_remote_data_source.dart:140` y `lib/features/workout/data/datasources/workout_local_data_source.dart:174` | `targetMuscle: exerciseData['muscle_group'] as String? ?? 'Desconocido'` — fallback silencioso oculta drift remoto/local |
| A6 | `lib/features/workout/data/repositories/workout_repository_impl.dart:33-35` (y 30+ métodos similares) | `catch (e) { return Left(ServerFailure(e.toString())); }` para todo. Sin diferenciar timeout, auth, conflict, validación, network |
| A7 | `lib/core/error/failures.dart` y `lib/core/error/exceptions.dart` | Sólo existen `ServerFailure`, `CacheFailure`, `NetworkFailure`. Faltan: `ValidationFailure`, `AuthFailure` (token expirado, credenciales inválidas), `NotFoundFailure`, `ConflictFailure` (sesión activa duplicada, set único) |
| A8 | `lib/features/workout/domain/usecases/assign_routine.dart` y `assign_routine_to_user.dart` | Duplicados 100%, ambos registrados en DI (`injection_container.dart:16,93`) |
| A9 | `lib/features/workout/domain/usecases/get_routine_exercises.dart:7`, `start_workout_session.dart:8` | Marcados `@Deprecated` pero seguidos compilando. Código muerto |
| A10 | `lib/features/workout/domain/repositories/workout_repository.dart:145` y impl `:464` | `syncPendingData()` declarado y devuelve `const Right(null)`. Phantom method del wiring offline desactivado |
| A11 | `lib/features/workout/data/models/*.dart` | 5 modelos con `fromJson`/`toJson` manuales (~260 LOC). Sin `freezed`/`json_serializable`. Cada cambio de schema requiere modificar 5 archivos manualmente |
| A12 | `lib/features/workout/domain/usecases/get_session_history.dart:27` y `weekly_insights.dart:32-33` | `DateTime.now()` invocado dentro de lógica de negocio → tests no deterministas |
| A13 | `lib/features/workout/data/datasources/workout_remote_data_source.dart:95,135,269,434-436,529-531` | Casts `as Map<String, dynamic>` directos sin null-check. Si la query devuelve null o el join falla → crash en runtime |
| A14 | `lib/features/auth/data/datasources/auth_local_data_source.dart:19-23` | `UserModel` (incluye email) cacheado en `SharedPreferences` plano. Si se quisiera persistir un token, tampoco serviría — falta `flutter_secure_storage` |
| A15 | `lib/features/workout/presentation/dashboard/pages/dashboard_page.dart:46-55` | `bloc.add(...)` invocado directamente en `initState` sin `addPostFrameCallback`. Riesgo de `setState during build` cuando se combina con redirección del router |
| A16 | Multiplicidad de bottom sheets sin wrapper común | `exercise_stats_bottom_sheet.dart:48-202`, `workout_summary_bottom_sheet.dart:41-58`, `workout_history_bottom_sheet.dart`, `exercise_catalog_sheet.dart` — cada uno reinventa el handle/header/scroll-padding |
| A17 | Empty/error states únicos por página | `routine_day_error_state.dart`, `dashboard_empty_state.dart`, `routine_stats_page.dart:82-99` — patrones distintos |
| A18 | Hex duplicados | `0xFF4CAF50` (success) hardcoded 11 veces en `dashboard_weekly_cards.dart`, `exercise_card_coaching.dart`, `exercise_set_row.dart` (5×), `exercise_card_header.dart` (4×). `0xFFFF9800` (warning) hardcoded 4 veces. `0xFF00E5FF` (cyan 1RM), `0xFF2A2A2A` (divider) repetidos. **No están en `AppColors`** |
| A19 | `lib/core/routes/router_helpers.dart` | Sólo expone `goToLogin/Register/Dashboard`. Restantes ~21 `context.push/go/pop(AppRoutes.*)` esparcidos por features (ej. `routine_list_page.dart:61,243,329`, `dashboard_page.dart:114,124,140,161,196`) |
| A20 | `lib/features/auth/presentation/bloc/auth_bloc.dart:79-107` | Tras éxito de `signIn`/`signUp` no se emite `Authenticated` directamente; depende de la subscription a `onAuthStateChange`. Ventana de race + estado intermedio confuso |

### 2.3 MEDIOS

| # | Archivo:línea | Hallazgo |
|---|---|---|
| M1 | `lib/features/auth/presentation/pages/login_page.dart:111-117` y `register_page.dart:121-126` | `buildWhen` incluye estados que también están en `listenWhen` → rebuilds redundantes |
| M2 | `lib/features/workout/presentation/exercise/widgets/exercise_stats_bottom_sheet.dart:105` y otros | `BlocBuilder` sin `buildWhen`, reconstruye toda la UI ante cualquier cambio |
| M3 | `lib/features/workout/presentation/dashboard/pages/dashboard_page.dart:26-32` (5 flags), `routine_editor_page.dart:26-31` (6 flags) | Estado local con muchos `setState` (`_currentWeekStart`, `_selectedRoutine`, `_activeSession`, `_autoResumeHandled`, `_cachedWeeklyPlan`; `_isInitialized`, `_isPublic`, `_pendingPop`, `_hasMutations`, `_cachedDays`). Debería estar en blocs por subdominio |
| M4 | `lib/features/workout/presentation/dashboard/pages/dashboard_page.dart:272-285` | "State caching manual": `_lastDashboardState` para esquivar `WorkoutLoading` flicker → síntoma de bloc mal partido |
| M5 | `lib/features/workout/data/datasources/workout_remote_data_source.dart:156-158,178-179,217-218,379-380` y repo `:272-273` | `padLeft(4, '0')` + format de fecha repetido 6 veces. Sin helper |
| M6 | `lib/features/workout/data/datasources/workout_remote_data_source.dart` | Inconsistencia de error handling: algunos métodos con `try/catch` específico (`finishWorkoutSession:410`, `getWeeklyInsights:501`), otros sin `try/catch` (`getAssignedRoutines:88`, `getRoutineDays:107`, `toggleExerciseInDay:658`) |
| M7 | `lib/features/workout/domain/entities/` | `Exercise`, `RoutineDay` tienen `copyWith`; `SetLog`, `Routine`, `WorkoutSession` no. Inconsistente |
| M8 | `lib/features/workout/domain/entities/set_log.dart` | Modelo de set rígido: sólo `weight`, `reps`, `set_index`. Sin RPE, RIR, AMRAP, drop sets, tempo, paused reps. Cualquier extensión futura toca BD + modelo + queries + UI |
| M9 | `lib/features/auth/presentation/bloc/auth_state.dart` | Coexisten `AuthInitial` y `AuthLoading`; no queda claro cuándo emite cuál. Subestados redundantes |
| M10 | `lib/features/workout/presentation/exercise/widgets/exercise_card.dart:146-151,305-316` | Strings de coaching hardcoded ("No alcanzaste el peso objetivo...", "Te faltaron repeticiones...", "¡Excelente!...") |
| M11 | `lib/features/workout/presentation/routine_day/pages/routine_day_page.dart:129-145` | Array `_meses` hardcoded en lugar de `intl.DateFormat.MMMM('es')` |
| M12 | Strings sin i18n | >20 strings españoles hardcoded distribuidos: `day_editor_page.dart:208,257`, `workout_summary_bottom_sheet.dart:73-80`, `exercise_card.dart`, login/register, etc. Sin `AppLocalizations`/`flutter_localizations`/`.arb` |
| M13 | `lib/features/auth/presentation/pages/login_page.dart:183-195`, `register_page.dart:192-204` | Sin `autofillHints: [AutofillHints.email, AutofillHints.password, AutofillHints.newPassword, AutofillHints.name]`; sin `textInputAction.next/done`; sin `onSubmitted` |
| M14 | Sin Semantics en gráficos | `exercise_stats_bottom_sheet.dart:340-514` (3 chart classes con `fl_chart`) sin `Semantics`/`semanticsLabel` |
| M15 | `lib/main.dart` | Sin `SystemChrome.setPreferredOrientations`, sin `SystemUiOverlayStyle` (status bar no alineada con tema oscuro), sin splash screen |
| M16 | `lib/core/services/active_session_service.dart:59` | `DateTime.parse` sin `try/catch` — JSON malformado en SP → excepción no controlada |
| M17 | `pubspec.yaml` | Faltan: `shimmer`, `formz` o `reactive_forms`, `freezed`+`freezed_annotation`+`json_annotation`+`json_serializable`+`build_runner`, `flutter_secure_storage`, logger estructurado (`talker` o `loggy`), `golden_toolkit` (dev), `faker` (dev) |
| M18 | `test/helpers/mocks.dart:1-8` | Sólo 2 mocks (`MockAuthRepository`, `MockWorkoutRepository`). Mocks de use cases creados inline en cada test |
| M19 | `integration_test/app_test.dart` | 3 tests. El primero verifica que el título "GYM TRACKER" sigue visible tras error (no valida SnackBar). Los demás navegan UI sin auth real. Comentario en `:59` reconoce limitación |

### 2.4 BAJOS

| # | Archivo:línea | Hallazgo |
|---|---|---|
| B1 | Imports relativos vs absolutos mezclados | `auth/` predomina relativo (`../../../`), `workout/` mayormente absoluto (`package:gym_flutter/...`). Sin convención uniforme |
| B2 | Magic numbers | `Duration(milliseconds: 1500)` (`exercise_card.dart:72`), `Duration(seconds: 8)` (`:160`), `BorderRadius.circular(14|10|4)` distintos sin sistema, `_totalRestSeconds = 60` (`routine_day_page.dart:48`) y luego `90` (`:119`) |
| B3 | Tap targets | Buttons sin `constraints: BoxConstraints(minWidth: 48, minHeight: 48)` en mayoría |
| B4 | Sin Hero animations entre páginas; `PageTransition` por defecto |
| B5 | Sin `logger` estructurado — `print` directo en algunos sitios (revisar `data_source` paths) |
| B6 | Sin `.flutter-plugins` no en gitignore (presencia variable) |
| B7 | RLS: política `USING (true)` en `routines`, `routine_days`, `routine_exercises`, `exercises` (`AGENT_CONTEXT.md:135`) — intencional pero a explicitar |

---

## 3. Hallazgos por área

### 3.1 Bootstrap y red de seguridad (`main.dart`, `injection_container.dart`)

- **`main.dart`** (68 LOC) hace lo mínimo: locale → Supabase init → DI → `runApp`. **Falta**:
  - `WidgetsFlutterBinding.ensureInitialized()` está, ✓.
  - `try/catch` alrededor de `SupabaseConfig.instance.init()` con pantalla de error fallback ✗.
  - `FlutterError.onError` ✗.
  - `PlatformDispatcher.instance.onError` ✗.
  - `runZonedGuarded(() => runApp(...), reportError)` ✗.
  - `Bloc.observer = AppBlocObserver()` ✗.
  - `SystemChrome.setPreferredOrientations` (si la UI es portrait-first) ✗.
  - `SystemChrome.setSystemUIOverlayStyle` para alinear status bar con tema oscuro ✗.
  - Splash nativo o `flutter_native_splash` configurado ✗.
- **`injection_container.dart`** (110 LOC):
  - Wiring offline comentado en `:29-35`. Si se quiere reactivar `localDataSource` y `sync_service`, hay que rearmar seis dependencias.
  - `Supabase.instance.client` se registra en `:107` como `LazySingleton`, pero `SupabaseConfig.init()` ya lo inicializó antes — orden correcto, pero **frágil**: cualquier futuro singleton que se inyecte y use Supabase antes de `di.init()` rompe.
  - Falta registrar `RoutineStatsBloc` explícitamente; está en `routine_stats_bloc.dart` pero no aparece en DI (es factoryless?). Verificar.
  - Sin `dispose()` de blocs `LazySingleton` cuando los hay.

### 3.2 Tema y design tokens

- `AppColors` y `AppTextStyles` están bien estructurados como tokens, pero **ignorados** por la mitad del código:
  - `success = 0xFF4CAF50` y `warning = 0xFFFF9800` no existen en `AppColors`, pero se usan crudos en >15 sitios.
  - `surface`, `surfaceHighlight` están definidos pero los widgets dibujan `Colors.white.withValues(alpha: 0.05)` y similares de cabeza.
- `MaterialApp.theme` (ver C12) deja todos los componentes Material con su default. Por eso cada `TextField` se envuelve en un `Container` decorado a mano (`login_page.dart:177-196`).
- No hay light mode (no es requisito necesariamente, pero el `ColorScheme.dark` está hardcoded sin abstracción).

### 3.3 Formularios

- **Cero `Form`/`FormState`/`TextFormField`/validators** en todo `lib/`.
- Patrón actual: `TextEditingController` directo + `onChanged`/`onPressed` + `if (x.isEmpty) showSnackBar`. Repetido en:
  - `login_page.dart`, `register_page.dart` (ver A3)
  - `routine_editor_page.dart:26,36` y `day_editor_page.dart:28,35`
  - `exercise_card.dart:321-326` (con leak)
  - `exercise_set_row.dart:45-46,59-64`
- Sin reactividad de validación en tiempo real, sin `formz`/`reactive_forms`.
- Sin `autofillHints`, `textInputAction`, ni manejo de `Enter`.
- **Sin contador de longitud, sin máscara para peso/reps, sin teclado decimal correcto en algunos sitios** (ver `exercise_card.dart:343,349` — `TextInputType.number` no permite decimales en iOS).

### 3.4 BLoC y manejo de estado

- **`WorkoutBloc`** (608 LOC, `WorkoutState` con 13 estados, `WorkoutEvent` extenso) es el problema central. Subdominios identificados que deben separarse:
  1. Dashboard / rutinas asignadas / plan semanal / insights.
  2. Día (info pre-start, recientes, last performances).
  3. Sesión activa (`startWorkoutForDay`, `saveSetLog`, `finishWorkoutSession`).
  4. Historial readonly.
  5. Gestión CRUD rutinas/días/ejercicios.
  6. Catálogo público + `assignRoutineToUser`.
  7. Detección de sesión activa global (cross-cutting al abrir app).
- `AuthBloc` está mejor (~3 estados claros) pero tiene la race condition descrita en A20.
- `ExerciseStatsBloc`, `RoutineStatsBloc` — bien aislados, mantener.
- **Anti-patterns recurrentes**:
  - `BlocBuilder` sin `buildWhen` (M2).
  - `bloc.add` en `initState` sin `addPostFrameCallback` (A15).
  - State caching manual con `_lastState` para esquivar `WorkoutLoading` flicker (M4).

### 3.5 Capa data/domain

- **Boilerplate de modelos** (A11): refactor a `freezed`+`json_serializable` reduce 260 LOC a ~50 y elimina typos en keys.
- **Error handling roto** (C4-C6, A6, A7, M6): hay que rediseñar la jerarquía `Exception → Failure` y el catching consistente.
- **Clean Architecture violada** (C9).
- **Use cases redundantes** (A8, A9, A10): `assign_routine` × 2, `get_routine_exercises` deprecated, `start_workout_session` deprecated, `syncPendingData` phantom.
- **Use cases anémicos**: muchos son wrappers de 1 línea sobre el repo. Decidir entre mantener (consistencia) o consolidar (menos boilerplate). Lista candidatos: `GetAssignedRoutines`, `GetWeeklyPlan`, `GetSessionHistory`, `SaveSetLog`, `AssignRoutine`, `GetAllRoutines`.
- **N+1** en `reorderExercisesInDay` (C8) — convertir a RPC con array de tuplas o `upsert` batch.
- **Date formatting duplicado** (M5).
- **Casts inseguros** (A13).
- **Modelo de `SetLog` no extensible** (M8).

### 3.6 Capa presentation

- **Widgets gigantes**:
  - `exercise_card.dart` (386): timer descanso (45-77), live advice (139-164), set management (97-137), expansión, render, dialog editor — extraer a `RestTimerSection`, `LiveAdvicePanel`, `SetGrid`, `RemoteTargetEditor`.
  - `dashboard_page.dart` (323): caché semanal, selección rutina, sesión activa, auto-resume, routing — adelgazar a orquestador.
  - `routine_day_page.dart` (314): timer global, sync logs, análisis, summary modal — separar.
  - `routine_editor_page.dart` (443): edición rutina + days CRUD + persistence + form.
- **Duplicación**:
  - `_buildTextField` × 2 (auth) + 4 sitios más con TextField crudo.
  - Bottom sheets sin wrapper (A16).
  - Empty/error states únicos por página (A17).
  - Loaders ad-hoc (18 spots).
- **Routing extras frágiles**: `state.extra as Map<String, dynamic>` con casts manuales en `app_router.dart:82-86,91-100,108-115,119-126`. Si una key cambia, falla en runtime sin compilación.
- **Strings sin i18n** (M10-M12): >20 sitios.
- **Magic numbers** (B2).

### 3.7 Tests

- 28 archivos test vs 86 productivos (~32%). Distribución desigual:
  - `test/features/auth/` cubre data/domain pero **presentation tiene 0 widget tests**.
  - `test/features/workout/` tiene tests dispersos en data/domain/presentation pero pocos cubren los blocs nuevos.
  - **`workout_bloc_test.dart` no existe o no cubre los 13 estados** (verificar — el bloc es muy grande para testear como uno solo).
- 0 golden tests.
- `test/helpers/mocks.dart` minimalista (2 mocks).
- `integration_test/app_test.dart` es smoke superficial.
- Sin CI que ejecute tests.

### 3.8 Lints y configuración

- `analysis_options.yaml` sin reglas custom (C13).
- `pubspec.yaml` faltan deps clave para el remaster (M17).
- Sin CI workflows (C14).
- `scripts/contract_smoke_supabase.sh` requiere secrets (PG password) y dependencias externas (`psql`, `jq`, `supabase` CLI) — diseñado para ejecución manual; integrarlo en CI requiere envvar setup.

### 3.9 Seguridad

- Credenciales Supabase como `defaultValue` (C11).
- `UserModel` con email en `SharedPreferences` plano (A14). Si se añade token, debe ir a `flutter_secure_storage`.
- RLS de catálogos abierta (B7) — intencional pero documentar.
- `catch (_)` que silencia upserts a `profiles` (C6).

### 3.10 Accesibilidad

- Sin `Semantics` en gráficos (M14).
- `autofillHints` ausentes (M13).
- Tap targets < 48dp en varios botones (B3).
- Contraste neon-lime sobre negro: el lime `0xFFCCFF00` sobre `0xFF000000` mide ~17:1 (excelente). Pero **lime sobre blanco** (si llega a aparecer en surface clara) cae bajo AA. La paleta general pasa, pero el `textSecondary = 0xFFA0A0A5` sobre fondo negro mide ~7.7:1 (AA OK).
- Sin soporte explícito para `MediaQuery.textScaler` — texto fijo, puede romper layout con sistema en escala 1.5×.

### 3.11 Performance

- N+1 en reorder (C8).
- Rebuilds por falta de `buildWhen`/`const`/`RepaintBoundary` (M2).
- `TextEditingController` leak (C7).
- No hay `precacheImage` ni lazy loading sistemático.
- `fl_chart` sin viewport limit en datasets grandes — verificar `exercise_progress_page.dart`.

---

## 4. Mapa de duplicaciones concretas

| Concepto duplicado | Sitios | Líneas afectadas | Solución de remaster |
|---|---|---|---|
| TextField estilizado con label arriba + container con border + icon | login, register, routine_editor, day_editor, exercise_card editor, exercise_set_row | ~250 LOC | `core/ui/molecules/AppFormField` consumiendo `InputDecorationTheme` |
| Container con glass/blur/border + radius | login, register, varios bottom sheets, cards | ~80 LOC | `core/ui/atoms/AppCard` + `GlassContainer` ya existe pero subutilizado |
| Bottom sheet con handle + header + scroll | exercise_stats, workout_summary, workout_history, exercise_catalog | ~120 LOC | `core/ui/feedback/AppBottomSheet.show(context, child:, title:)` |
| Empty/error state | dashboard, routine_day, routine_stats, routine_list | ~150 LOC | `core/ui/molecules/AppEmptyState` + `AppErrorState` |
| Loading spinner inline | 18 sitios en 10 archivos | ~50 LOC | `core/ui/feedback/AppLoader` + skeletons específicos |
| SnackBar de error | login, register, exercise_card, dashboard, routine_editor | ~30 LOC | `AppSnackBar.error/success/info` leyendo `SnackBarTheme` |
| Hex color literal `0xFF4CAF50` (success) | 11 sitios | — | `AppColors.success` |
| Hex color literal `0xFFFF9800` (warning) | 4 sitios | — | `AppColors.warning` |
| Date format con `padLeft(4,'0')` | 6 sitios en data | — | `core/utils/date_format.dart` |
| `ScaffoldMessenger.of(context).showSnackBar` | 33 sitios en 8 archivos | — | Servicio `FeedbackService` o extension `context.showError(...)` |
| `context.push/go/pop(AppRoutes.X)` directo | ~21 sitios | — | Helpers en `router_helpers.dart` |
| `Coaching analysis` mapping de strings | exercise_card, routine_day_live_coaching | — | `core/utils/coaching_messages.dart` con i18n |

---

## 5. Riesgos para el remaster

1. **`WorkoutBloc` god-bloc**: partirlo es la operación más grande. Riesgo: tests existentes dependen de la API actual de eventos/estados → habrá que reescribir buena parte. Mitigación: hacer la división en commits pequeños por subdominio, mantener el bloc viejo como fachada hasta que todos los consumidores migren.
2. **Modelos con freezed**: introducir `build_runner` cambia el flujo dev (tener que correr `dart run build_runner watch`). Asegurar que CI lo corra.
3. **Activación de offline-first**: el código existe pero está congelado. Reactivarlo implica decidir política de conflictos (last-write-wins vs CRDT) — fuera del alcance del remaster cosmético, debe quedar marcado como **opcional** en el plan o explícitamente diferido.
4. **Cambios de schema** para soportar `SetLog` extensible (RPE/AMRAP) requieren migraciones Supabase y backfill — **diferir a una fase 8** post-remaster.
5. **i18n**: empezar a localizar significa tocar todas las pantallas. Si se hace mal puede congelar el remaster — recomiendo mantener español hardcoded centralizado en `core/i18n/strings_es.dart` durante el remaster y migrar a `.arb` después.
6. **Rediseño UI/UX**: si se hace simultáneo con la refactorización estructural, el riesgo de rotura es mayor. Mejor: estructura primero, rediseño después (Fase 6 del plan original).
7. **Tests durante refactor**: si se rompen los actuales sin reescribir, perdemos la red. Adoptar la regla "ningún PR de remaster reduce el `flutter test` de verde a rojo".

---

## 6. Lista de verificación "cero errores"

Para considerar el remaster completo:

- [ ] `flutter analyze` con 0 issues bajo `strict-casts`/`strict-inference`/`strict-raw-types`.
- [ ] `flutter test` con 0 fallos y cobertura ≥ 60% en `domain/` y ≥ 50% en `presentation/blocs`.
- [ ] Integration test del flujo crítico (login → dashboard → start day → save set → finish → ver insights) verde.
- [ ] Golden tests para los 8 widgets atómicos clave (`AppFormField`, `AppButton`, `AppCard`, `AppEmptyState`, `AppErrorState`, `AppLoader`, `AppSkeleton`, `AppBottomSheet`).
- [ ] `FlutterError.onError` + `PlatformDispatcher.instance.onError` + `runZonedGuarded` reportando a `ErrorReporter`.
- [ ] `AppBlocObserver` activo con logging estructurado de transiciones y errores.
- [ ] 0 `TextField` crudo en `features/`.
- [ ] 0 `if (x.isEmpty) showSnackBar` (validación reactiva con `formz`).
- [ ] 0 `CircularProgressIndicator` directo en `features/` (todos vía `AppLoader`/skeleton).
- [ ] 0 `ScaffoldMessenger.of(...).showSnackBar(...)` directo (todos vía `AppSnackBar`/`FeedbackService`).
- [ ] 0 hex literales fuera de `core/theme/`.
- [ ] 0 `EdgeInsets.all(N)` con N fuera del sistema de spacing.
- [ ] 0 widget > 200 LOC.
- [ ] 0 bloc > 250 LOC.
- [ ] 0 imports relativos en `features/` (solo absolutos `package:gym_flutter/...`).
- [ ] 0 use cases duplicados/deprecated/phantom.
- [ ] Domain sin imports a `data/`.
- [ ] `MaterialApp` con `ThemeData` completo (todos los component themes).
- [ ] Credenciales Supabase fuera del repo (sólo `--dart-define`).
- [ ] Sin secrets en `SharedPreferences`; usar `flutter_secure_storage` para datos sensibles.
- [ ] CI workflow ejecuta `flutter pub get && flutter analyze && flutter test` en cada PR.
- [ ] CI workflow opcional: ejecutar `scripts/contract_smoke_supabase.sh` con secrets.
- [ ] `AGENT_CONTEXT.md` actualizado tras el remaster.

---

## 7. Inventario detallado

### 7.1 Archivos de `lib/` por tamaño (top 15)

| LOC | Archivo |
|---|---|
| 608 | `lib/features/workout/presentation/bloc/workout_bloc.dart` |
| 443 | `lib/features/workout/presentation/routine_management/pages/routine_editor_page.dart` |
| 386 | `lib/features/workout/presentation/exercise/widgets/exercise_card.dart` |
| 323 | `lib/features/workout/presentation/dashboard/pages/dashboard_page.dart` |
| 314 | `lib/features/workout/presentation/routine_day/pages/routine_day_page.dart` |
| 210 | `lib/features/auth/presentation/pages/register_page.dart` |
| 201 | `lib/features/auth/presentation/pages/login_page.dart` |
| 162 | `lib/features/workout/presentation/bloc/workout_state.dart` |
| ~700+ | `lib/features/workout/data/datasources/workout_remote_data_source.dart` |
| ~250+ | `lib/features/workout/data/datasources/workout_local_data_source.dart` |
| ~127 | `lib/core/database/database_helper.dart` |
| 110 | `lib/injection_container.dart` |
| 68 | `lib/main.dart` |

### 7.2 Estado del catálogo de tests

- `test/features/auth/data/` — repos + datasources cubiertos.
- `test/features/auth/domain/` — use cases cubiertos.
- `test/features/auth/presentation/` — **0 widget tests**.
- `test/features/workout/data/` — modelos + repo + datasources parciales.
- `test/features/workout/domain/` — entities + use cases.
- `test/features/workout/presentation/` — algunos blocs (`exercise_stats`, `routine_stats`), algunas páginas (smoke), widgets aislados.
- **No existe** un `test/features/workout/presentation/bloc/workout_bloc_test.dart` exhaustivo.

### 7.3 Dependencias clave actuales y faltantes

| Paquete | Estado | Acción |
|---|---|---|
| `flutter_bloc 9.1.1` | ✓ | mantener |
| `get_it 9.2.1` | ✓ | mantener |
| `go_router 17.1.0` | ✓ | mantener |
| `fpdart 1.1.0` | ✓ | mantener |
| `equatable 2.0.8` | ✓ | mantener (mientras no se migre a freezed) |
| `supabase_flutter 2.12.2` | ✓ | mantener |
| `shared_preferences 2.5.5` | ✓ | mantener (cache no sensible) |
| `sqflite` + `sqflite_common_ffi_web` | ✓ | mantener (si reactivamos offline) |
| `fl_chart 1.2.0` | ✓ | mantener |
| `intl 0.20.2` | ✓ | mantener |
| `google_fonts 8.0.2` | ✓ | mantener |
| `bloc_test 10.0.0` (dev) | ✓ | mantener |
| `mocktail 1.0.4` (dev) | ✓ | mantener |
| `shimmer` | ✗ | **AÑADIR** para skeletons |
| `formz` o `reactive_forms` | ✗ | **AÑADIR** — recomiendo `formz` por integración natural con BLoC |
| `freezed` + `freezed_annotation` | ✗ | **AÑADIR** para modelos/estados |
| `json_serializable` + `json_annotation` | ✗ | **AÑADIR** para parsing de modelos |
| `build_runner` (dev) | ✗ | **AÑADIR** para los anteriores |
| `flutter_secure_storage` | ✗ | **AÑADIR** para tokens/datos sensibles |
| `talker` o `loggy` | ✗ | **AÑADIR** logger estructurado |
| `golden_toolkit` (dev) | ✗ | **AÑADIR** para golden tests |
| `faker` (dev) | ✗ | opcional, generación de datos |
| `flutter_native_splash` | ✗ | opcional, splash polished |
| `flutter_localizations` + `intl_utils` | ✗ | **AÑADIR** para `.arb`/i18n (posiblemente diferido a post-remaster) |

---

## 8. Mapeo a las fases del plan

| Fase | Hallazgos que cierra |
|---|---|
| Fase 0 — Red de seguridad | C1, C2, C3, C13, C14, M15 |
| Fase 1 — Tema y tokens | C12, A18, M11, B2 |
| Fase 2 — Formularios reactivos | A3, A4, M13, M10-M12 (parcial) |
| Fase 3 — Partir `WorkoutBloc` | A1, A2, M1, M2, M3, M4, A15, A20, M9 |
| Fase 4 — Componentes y descomposición | A16, A17, B3, widgets gigantes (`exercise_card`, `dashboard_page`, `routine_day_page`, `routine_editor_page`) |
| Fase 5 — Loaders/feedback unificados | M2 (parte), las 18 instancias de spinners y 33 de modales/snackbars |
| Fase 6 — Rediseño UI/UX | (nuevo, no cierra hallazgos pero apoya M14, B3, B4) |
| Fase 7 — Endurecimiento | C4-C11, A5-A14, M5-M8, M16, A19, M17, M18, M19, B7 |

---

## 9. Recomendaciones inmediatas (antes de Fase 0)

1. Hacer un commit-checkpoint del estado actual (rama `pre-remaster`).
2. Decidir las 4 preguntas pendientes del plan (librería de formularios, alcance de diseño, alcance de "cero errores", granularidad de tests).
3. Crear branch `remaster/fase-0-safety-net` y arrancar.

---

*Este documento es la fotografía del estado pre-remaster. Una vez completada la Fase 7, se debe archivar como `docs/REMASTER_DIAGNOSIS_PRE.md` y generar `docs/REMASTER_RESULT.md` con el delta.*
