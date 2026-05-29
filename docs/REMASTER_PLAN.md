# Plan de Trabajo — Remaster Smart Gym Tracker

> Fecha: 2026-05-03
> Documento companion: [`REMASTER_DIAGNOSIS.md`](./REMASTER_DIAGNOSIS.md) (estado pre-remaster con evidencia `file:línea`).
> Objetivo del remaster: arquitectura clara, controlada y escalable bajo principios SOLID, BLoC saneado, componentización con cero duplicidad, formularios reactivos, rediseño UI/UX, loaders unificados, y endurecimiento "cero errores".
> Granularidad: 8 fases, cada una mergeable y con la app funcional al cierre. Cada fase cierra hallazgos específicos del diagnóstico.

---

## 0. Cómo leer este documento

- Cada fase tiene **Objetivo**, **Alcance** (qué SÍ / qué NO), **Tareas** mapeadas a archivos, **Hallazgos que cierra** (refs `Cn`/`An`/`Mn`/`Bn` del diagnóstico), **DoD** verificable, y **Riesgos**.
- Las referencias `Cn/An/Mn/Bn` corresponden a la sección 2 del diagnóstico (CRÍTICO/ALTO/MEDIO/BAJO).
- Cada fase corresponde a una rama `remaster/fase-N-<slug>` y se mergea con un PR autocontenido.

---

## 1. Decisiones técnicas

Tomadas por defecto. Marcadas para que puedas corregirme antes de arrancar.

| # | Decisión | Por qué | Alternativa | Reversible |
|---|---|---|---|---|
| D1 | **`formz`** para formularios reactivos | Integra natural con BLoC ya en uso; sin estado paralelo; tests fáciles | `reactive_forms` (más feature-rich pero introduce `FormGroup` paralelo a BLoC) | Sí, capa fina |
| D2 | **`freezed` + `json_serializable`** para modelos/estados | Elimina ~260 LOC de boilerplate y typos en JSON; sealed classes para estados de bloc | `equatable` manual (status quo) | Sí pero costoso |
| D3 | **Mantener paleta neon-lime/obsidiana** | El diagnóstico muestra que la paleta es coherente; el problema es que no está aplicada (tema vacío), no la elección visual | Rediseño cromático completo | Sí |
| D4 | **`--dart-define` puro**, sin `defaultValue` hardcoded | Cierra C11 sin reactivar offline | Mantener fallback | Sí |
| D5 | **Offline-first se difiere a Fase 8 opcional** | Reactivarlo es un proyecto en sí (políticas de conflicto, sync, tests). El remaster cosmético-estructural no debe arrastrarlo | Reactivar en Fase 7 | Sí |
| D6 | **i18n se difiere a Fase 8 opcional** | Centralizar strings en `core/i18n/strings_es.dart` durante el remaster, migrar a `.arb`/`flutter_localizations` después | Hacerlo durante Fase 4-5 | Sí |
| D7 | **`flutter_secure_storage`** para datos sensibles, `SharedPreferences` solo para preferencias UI | Cierra A14 | Status quo | Sí |
| D8 | **Logger estructurado: `talker`** | Mejor DX que `loggy`, dashboard de logs incluido, integra con `BlocObserver` | `loggy`, `logger` | Sí |
| D9 | **Tests**: bloc_test + integration test del flujo crítico + golden tests **solo** para widgets atómicos del design system | Suficiente para "cero errores" sin sobre-invertir | Cobertura completa | Sí |
| D10 | **CI: GitHub Actions** ejecutando `pub get && analyze && test` por PR. Smoke test de Edge Functions queda como workflow manual con secrets | Cierra C14 | CI más complejo (Codecov, fastlane) | Sí |

---

## 2. Principios rectores (no negociables)

1. **Cada PR deja la app funcional**: ningún merge rompe el flujo crítico (login → dashboard → start day → save set → finish).
2. **Ningún PR baja `flutter test` a rojo**: si una refactorización requiere reescribir tests, se reescriben en el mismo PR.
3. **Domain no importa data**: ni un solo `import '../../data/...'` en `lib/features/*/domain/`.
4. **Cero duplicación visual**: si un patrón aparece dos veces, la tercera vez debe ser un widget compartido.
5. **Tema es la única fuente de estilo**: `Color(...)`, `EdgeInsets.all(N)`, `BorderRadius.circular(N)` literales fuera de `core/theme/` están prohibidos en `features/`.
6. **Componer, no heredar**: widgets pequeños y componibles; cero `StatefulWidget` > 200 LOC.
7. **BLoC por subdominio**: ningún bloc > 250 LOC. Estado modelado como `Status enum + data` (no 13 sealed classes).
8. **Errores tipados**: nunca `catch (e) { rethrow message.toString(); }`. Mapear a `Failure` específico.
9. **Validación reactiva**: nunca `if (x.isEmpty) showSnackBar`. Validación viva con `formz`.
10. **Observabilidad por defecto**: todo error no manejado llega a `ErrorReporter`. `BlocObserver` registra transiciones.

---

## 3. Roadmap

```
Fase 0 ── Fase 1 ── Fase 2 ── Fase 3 ── Fase 4 ── Fase 5 ── Fase 7
  │         │         │         │         │         │
  │         │         │         │         └── Fase 6 (rediseño, paralelizable desde aquí)
  │
  └── (CI workflow se inicia en paralelo con Fase 0)

Fase 8 (opcional) ── offline-first / i18n / SetLog extensible
```

| Fase | Sesiones | Dependencias | Riesgo |
|---|---|---|---|
| 0 — Red de seguridad | 1 | — | Bajo |
| 1 — Tema y tokens | 1 | Fase 0 | Bajo |
| 2 — Formularios reactivos | 2 | Fase 1 | Medio |
| 3 — Partir `WorkoutBloc` | 2-3 | Fase 0 | **Alto** |
| 4 — Componentes y descomposición | 2 | Fase 1, Fase 3 | Medio |
| 5 — Loaders/feedback unificados | 1 | Fase 1, Fase 4 | Bajo |
| 6 — Rediseño UI/UX | 3-4 | Fase 4 (mockups pueden empezar antes) | Medio |
| 7 — Endurecimiento "cero errores" | 1 | Todas | Bajo |
| 8 — Opcional (offline/i18n/SetLog) | 3+ | Fase 7 | Alto |

**Total remaster (Fases 0-7): 12-15 sesiones.**

---

## 4. Fases

### Fase 0 — Red de seguridad

**Rama**: `remaster/fase-0-safety-net`
**Objetivo**: instalar la infraestructura de observabilidad y lints estrictos antes de tocar cualquier feature, para que toda fase posterior tenga validación automática.
**Alcance SÍ**: error reporter, lints estrictos, BlocObserver, CI workflow básico, splash/orientación, secrets fuera del repo.
**Alcance NO**: refactor de features; cambios visuales.

**Tareas**:

1. **Error reporter y zonas guardadas** — `lib/main.dart`, nuevo `lib/core/error/error_reporter.dart`:
   ```dart
   void main() {
     runZonedGuarded(() async {
       WidgetsFlutterBinding.ensureInitialized();
       FlutterError.onError = ErrorReporter.onFlutterError;
       PlatformDispatcher.instance.onError = ErrorReporter.onPlatformError;
       try { await SupabaseConfig.instance.init(); }
       catch (e, st) { ErrorReporter.report(e, st); /* mostrar pantalla fallback */ }
       Bloc.observer = AppBlocObserver();
       await di.init();
       runApp(const SmartGymTrackerApp());
     }, ErrorReporter.report);
   }
   ```
2. **`AppBlocObserver`** en `lib/core/observability/app_bloc_observer.dart` — log `onChange`, `onError`, `onTransition` con `talker`.
3. **`talker` package** añadido a `pubspec.yaml` + screen de logs en debug only.
4. **`SystemChrome.setPreferredOrientations([portraitUp])`** y `SystemUiOverlayStyle` alineado al tema.
5. **Splash básico** vía `flutter_native_splash` (config en `pubspec.yaml`).
6. **`lib/core/config/supabase_config.dart`**: eliminar `defaultValue` de `String.fromEnvironment`. Si falta el define → `throw StateError` con mensaje accionable.
7. **`analysis_options.yaml`** estricto:
   ```yaml
   analyzer:
     language:
       strict-casts: true
       strict-inference: true
       strict-raw-types: true
     errors:
       missing_required_param: error
       missing_return: error
       todo: ignore
   linter:
     rules:
       - prefer_const_constructors
       - prefer_const_literals_to_create_immutables
       - avoid_dynamic_calls
       - unawaited_futures
       - require_trailing_commas
       - cancel_subscriptions
       - close_sinks
       - avoid_returning_null_for_future
       - avoid_slow_async_io
       - prefer_single_quotes
   ```
8. **CI workflow** `.github/workflows/ci.yml`: `flutter pub get && flutter analyze && flutter test` con cache, en push y PR.
9. **CI workflow opcional** `.github/workflows/contract-smoke.yml`: dispara `scripts/contract_smoke_supabase.sh` con secrets, manual trigger (`workflow_dispatch`).

**Hallazgos cerrados**: C1, C2, C3, C11, C13, C14, M15.

**DoD**:
- [ ] `flutter analyze` con 0 issues bajo lints estrictos.
- [ ] `flutter test` verde.
- [ ] Forzar un crash de prueba (en branch separado) → llega a `ErrorReporter`.
- [ ] `Bloc.observer` muestra transiciones en consola.
- [ ] Sin `SUPABASE_URL` en `--dart-define` → `StateError` claro al arrancar.
- [ ] CI ejecutado en PR, verde.

**Riesgos**: lints estrictos pueden generar 100+ warnings legacy. Mitigación: arreglar los críticos en este PR; los cosméticos quedan en backlog visible (`// TODO(remaster): ...`) sin bloquear el merge.

---

### Fase 1 — Tema, tokens y design system base

**Rama**: `remaster/fase-1-theme`
**Objetivo**: que `MaterialApp` declare un `ThemeData` completo y que todos los tokens visuales (color, spacing, radii, durations, typography) vivan en `core/theme/`.
**Alcance SÍ**: tokens, `ThemeData` completo, refactor de literales en widgets existentes.
**Alcance NO**: nuevos componentes (vienen en Fase 4); rediseño visual (Fase 6).

**Tareas**:

1. Crear `lib/core/theme/`:
   - `tokens/spacing.dart` (`Spacing.xs/sm/md/lg/xl/xxl` = 4/8/12/16/24/32).
   - `tokens/radii.dart` (`Radii.sm/md/lg/pill` = 8/12/20/999).
   - `tokens/durations.dart` (`Durations.fast/medium/slow` = 150/250/400 ms).
   - `tokens/elevations.dart`.
   - `app_colors.dart` ← mover `lib/core/constants/app_colors.dart` y **añadir** `success`, `warning`, `info`, `divider`, `overlay`, `glassFill`, `glassBorder`.
   - `app_text_theme.dart` — `TextTheme` Material 3 real basado en `AppTextStyles` actuales.
   - `app_theme.dart` — `ThemeData` con todos los component themes:
     - `colorScheme`, `textTheme`, `scaffoldBackgroundColor`
     - `inputDecorationTheme` (con borders, fill, error styles)
     - `elevatedButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `filledButtonTheme`, `iconButtonTheme`
     - `snackBarTheme`, `bottomSheetTheme`, `dialogTheme`, `cardTheme`, `chipTheme`
     - `progressIndicatorTheme`, `appBarTheme`, `tabBarTheme`, `dividerTheme`, `iconTheme`
     - `pageTransitionsTheme` (cupertino-style en iOS, fade-up en Android)
2. Actualizar `lib/main.dart` para usar `AppTheme.dark`.
3. **Sweep de literales** en `lib/features/`: reemplazar `0xFF4CAF50` → `AppColors.success` (×11), `0xFFFF9800` → `AppColors.warning` (×4), `0xFF00E5FF`, `0xFF2A2A2A`, etc. Reemplazar `EdgeInsets.all(N)` con `Spacing` y `BorderRadius.circular(N)` con `Radii`.
4. Mover `lib/core/constants/` (deprecated) → `lib/core/theme/`. Mantener re-exports temporales si alguno está fuera.
5. Lint custom (regla local) o test que verifique cero hex literales en `lib/features/`:
   ```dart
   // test/lints/no_hex_literals_test.dart
   ```

**Hallazgos cerrados**: C12, A18, M11 (parcial), B2.

**DoD**:
- [ ] `MaterialApp` declara `ThemeData` con ≥15 component themes.
- [ ] `grep -r "0xFF" lib/features/` devuelve 0 matches.
- [ ] `grep -rE "EdgeInsets\.(all|symmetric|fromLTRB)\(\d" lib/features/` devuelve 0 matches con números literales (todos vía `Spacing.*`).
- [ ] App visualmente igual o ligeramente mejor (no hay regresiones).
- [ ] `flutter test` verde.

**Riesgos**: el sweep de literales es tedioso; algunos colores únicos pueden requerir nuevos tokens. Mitigación: añadir tokens conforme aparezcan; no inventar abstracciones por adelantado.

---

### Fase 2 — Formularios reactivos

**Rama**: `remaster/fase-2-forms`
**Objetivo**: cero `TextField` crudo en `features/`. Toda validación es reactiva, vive en blocs específicos, y la UI consume un `AppFormField` único.
**Alcance SÍ**: `formz` inputs, `FormBloc` base, `AppFormField`, refactor de auth/routine_editor/day_editor/exercise_card editor/exercise_set_row.
**Alcance NO**: rediseño visual; nuevos campos (RPE, etc.).

**Tareas**:

1. Añadir `formz` y `flutter_secure_storage` a `pubspec.yaml`.
2. Crear `lib/core/forms/`:
   - `inputs/email.dart` — `Email extends FormzInput<String, EmailError>` con validación regex.
   - `inputs/password.dart` — longitud mínima 8, opcional fortaleza (mayúscula/número/símbolo).
   - `inputs/required_text.dart` — para nombre completo, nombre rutina, nombre día.
   - `inputs/weight_input.dart` — `double` parseado, ≥ 0, ≤ 1000.
   - `inputs/reps_input.dart` — `int` parseado, ≥ 0, ≤ 999.
   - `form_bloc_base.dart` — base con `submissionStatus`, `isValid`, `submit()` hook.
3. Crear `lib/core/ui/molecules/app_form_field.dart`:
   - props: `label`, `value`, `errorText`, `onChanged`, `obscureText`, `keyboardType`, `autofillHints`, `textInputAction`, `onSubmitted`, `prefixIcon`, `suffixIcon` (con toggle ver/ocultar para password).
   - usa `InputDecorationTheme` del tema.
4. Refactorizar features:
   - **Auth**:
     - `lib/features/auth/presentation/bloc/login_form_bloc.dart` (nuevo) con `Email`/`Password`.
     - `lib/features/auth/presentation/bloc/register_form_bloc.dart` (nuevo) con `RequiredText`/`Email`/`Password`.
     - `login_page.dart` y `register_page.dart`: eliminar `_buildTextField` privados, consumir `AppFormField`, escuchar `LoginFormBloc.submissionStatus` para botón.
     - `AuthBloc` solo recibe credenciales validadas.
   - **Routine/day editor**:
     - `routine_form_bloc.dart`, `day_form_bloc.dart`.
     - Reemplazar `TextEditingController` por inputs `formz`.
   - **Exercise set row**:
     - `set_log_form_bloc.dart` con `WeightInput`, `RepsInput`.
     - `exercise_set_row.dart` consume el bloc; submit en `done` del teclado.
   - **Exercise card "remote target editor"** (`exercise_card.dart:320`):
     - Convertir el dialog en `RemoteTargetSheet` con bloc propio. **Cierra el leak C7** porque los controllers ahora viven en el bloc, no en `build`.
5. **`flutter_secure_storage`**:
   - `auth_local_data_source.dart` — separar UserModel UI cache (sigue en SP) de cualquier token futuro (irá a secure storage). Documentar el split en el archivo.
6. **Tests**:
   - Unit tests para cada `FormzInput` (válido, inválido, edge cases).
   - Bloc tests para cada `FormBloc` (transiciones de estado).
   - Widget test para `AppFormField` (muestra error, submit en Enter, autofill hint correcto).

**Hallazgos cerrados**: A3, A4, M13, A14, C7 (consecuencia de la refactorización de exercise_card editor).

**DoD**:
- [ ] `grep -rn "TextField(" lib/features/` devuelve 0 matches (solo `AppFormField`).
- [ ] `grep -rn "if.*isEmpty.*showSnackBar" lib/features/` devuelve 0 matches.
- [ ] Login y register validan en tiempo real (botón disabled hasta `isValid`).
- [ ] Submit con Enter funciona en todos los formularios.
- [ ] `autofillHints` correcto en email/password/name.
- [ ] `flutter test` con tests nuevos verde.

**Riesgos**: `formz` impone ceremonia para inputs simples. Mitigación: el `FormBlocBase` reduce el boilerplate; aceptar que cada formulario es ~30 LOC de bloc nuevo.

---

### Fase 3 — Partir `WorkoutBloc`

**Rama**: `remaster/fase-3-bloc-split`
**Objetivo**: ningún bloc > 250 LOC. Estados modelados como `Status enum + data`. Cada subdominio aislado y testeable.
**Alcance SÍ**: split del bloc en 6, migración de presentación, tests.
**Alcance NO**: cambios de UI (las páginas siguen consumiendo lo nuevo); cambios de schema.

**Tareas**:

1. Crear blocs nuevos en `lib/features/workout/presentation/bloc/`:
   - **`dashboard/`** — `DashboardBloc`, `DashboardState`, `DashboardEvent`. Estado: `status`, `routines`, `selectedRoutine`, `weeklyPlan`, `insights`, `activeSession`, `error`.
   - **`routine_day/`** — `RoutineDayBloc`. Estado: `status`, `exercises`, `existingSession`, `recentSessions`, `lastPerformances`, `hasAnotherActiveSession`.
   - **`active_workout/`** — `ActiveWorkoutBloc`. Estado: `status`, `session`, `exercises`, `setLogs`, `lastPerformances`, `restTimer`. Eventos: `StartSession`, `SaveSet`, `UpdateRestTimer`, `FinishSession`.
   - **`routine_management/`** — `RoutineManagementBloc`. Estado: `status`, `routines`, `editing` (rutina en edición). Eventos: `LoadAllRoutines`, `CreateRoutine`, `SaveRoutine`, `DeleteRoutine`, `AssignToUser`, `UpdateDay`, `ToggleExercise`, `ReorderExercises`, `UpdateExerciseTarget`.
   - **`session_history/`** — `SessionHistoryBloc` (readonly).
   - **`active_session_watcher/`** — `ActiveSessionWatcherBloc` (cross-cutting, escucha al iniciar app y emite redirección si hay sesión sin completar).
2. **Estado modelo**: usar `freezed` con `@Default(Status.initial) Status status`. Status enum: `initial | loading | success | failure`.
3. **Use cases consolidados**:
   - Eliminar `assign_routine_to_user.dart` (duplicado de `assign_routine.dart`).
   - Eliminar `get_routine_exercises.dart` (deprecated).
   - Eliminar `start_workout_session.dart` (deprecated).
   - Eliminar declaración y impl de `syncPendingData()` (phantom).
4. **DI** (`injection_container.dart`): registrar los 6 blocs nuevos. Mantener `WorkoutBloc` viejo solo si se necesita como facade temporal (pero el plan es eliminarlo en este PR).
5. **Migración de páginas**:
   - `dashboard_page.dart` → consume `DashboardBloc`. Eliminar `_lastDashboardState` (ya no necesario, `Status enum` maneja flicker).
   - `routine_day_page.dart` → consume `RoutineDayBloc` + `ActiveWorkoutBloc`.
   - `active_workout_page.dart` → consume `ActiveWorkoutBloc`.
   - `routine_list_page.dart`, `routine_editor_page.dart`, `day_editor_page.dart` → `RoutineManagementBloc`.
   - `routine_stats_page.dart`, `exercise_progress_page.dart` → siguen con `RoutineStatsBloc`/`ExerciseStatsBloc` (ya bien aislados).
6. **`bloc.add` desde `initState`** → todos con `WidgetsBinding.instance.addPostFrameCallback` o (mejor) en `BlocProvider.create` con evento inicial encadenado. Cierra A15.
7. **`AuthBloc`**: emitir `Authenticated` directamente tras éxito de signIn/signUp en lugar de depender solo de `onAuthStateChange` (cierra A20). Eliminar `AuthInitial` o convertirlo en `AuthLoading.initial()` (cierra M9).
8. **Tests**: `bloc_test` exhaustivo por cada bloc nuevo, transiciones felices y de error.

**Hallazgos cerrados**: A1, A2, A8, A9, A10, A15, A20, M1, M2, M3, M4, M9.

**DoD**:
- [ ] Ningún archivo bloc > 250 LOC.
- [ ] `WorkoutBloc` legacy eliminado.
- [ ] `WorkoutState` legacy eliminado.
- [ ] Use cases duplicados/deprecated eliminados.
- [ ] Cada bloc tiene `_test.dart` con cobertura ≥ 70%.
- [ ] `flutter test` verde.
- [ ] Flujo crítico verificado manualmente: login → dashboard → start day → save set → finish.

**Riesgos**: **Esta es la fase más invasiva**. Mitigación: split en 6 sub-PRs si hace falta; cada bloc nuevo se introduce mientras el viejo sigue vivo, se migran consumidores uno a uno, se elimina el viejo al final.

---

### Fase 4 — Componentes y descomposición de widgets gigantes

**Rama**: `remaster/fase-4-components`
**Objetivo**: ningún widget > 200 LOC. Atoms/molecules en `core/ui/` consumidos por todas las features.
**Alcance SÍ**: design system de widgets reutilizables, descomposición de páginas grandes.
**Alcance NO**: rediseño visual (Fase 6); cambios de estado (ya cerrados en Fase 3).

**Tareas**:

1. Crear `lib/core/ui/`:
   - **atoms/**: `app_button.dart` (variants: primary/secondary/ghost/destructive), `app_icon_button.dart`, `app_chip.dart`, `app_badge.dart`, `app_divider.dart`, `app_text.dart` (helper que consume `TextTheme`).
   - **molecules/**: `app_card.dart`, `app_section_header.dart`, `app_empty_state.dart` (icon + title + subtitle + CTA opcional), `app_error_state.dart` (icon + message + retry).
   - **layout/**: `app_scaffold.dart` (con padding y safe area por defecto), `app_page_header.dart`.
2. **`AppCard`** unifica los containers glass/border/shadow repetidos. `GlassContainer` actual queda como **caso de uso interno** de `AppCard.glass`.
3. **Descomposición**:
   - `exercise_card.dart` (386 LOC) →
     - `exercise_card.dart` (≤150 LOC) — orquestador.
     - `widgets/exercise_card_rest_section.dart` (timer descanso).
     - `widgets/exercise_card_advice_section.dart` (live advice).
     - `widgets/exercise_card_set_grid.dart` (sets).
     - `widgets/remote_target_sheet.dart` (ya creado en Fase 2 como bloc).
   - `dashboard_page.dart` (323 LOC) →
     - `dashboard_page.dart` (≤120 LOC) — solo orquestación de `DashboardBloc`.
     - Widgets de dashboard ya existen (`dashboard_*`); revisar y simplificar.
   - `routine_day_page.dart` (314 LOC) →
     - `routine_day_page.dart` (≤120 LOC).
     - Widgets ya existen (`routine_day_*`); reorganizar y eliminar duplicaciones internas.
   - `routine_editor_page.dart` (443 LOC) →
     - `routine_editor_page.dart` (≤150 LOC).
     - `widgets/routine_form_section.dart`, `widgets/routine_days_section.dart`.
4. **Bottom sheets** unificados:
   - `lib/core/ui/feedback/app_bottom_sheet.dart` con `AppBottomSheet.show<T>(context, title:, child:)` que renderiza handle + header + scroll padding según tema.
   - Migrar: `exercise_stats_bottom_sheet`, `workout_summary_bottom_sheet`, `workout_history_bottom_sheet`, `exercise_catalog_sheet`.
5. **Routing typed extras**:
   - Reemplazar `state.extra as Map<String, dynamic>` por classes typed:
     - `class RoutineDayArgs { final RoutineDay day; final String userId; final DateTime date; }`
     - igual para `RoutineStatsArgs`, `ExerciseProgressArgs`, `DayEditorArgs`.
   - `app_router.dart`: builders castan a la clase typed → fail-fast con error de compilación si cambia la shape.
6. **Centralizar navegación**:
   - `router_helpers.dart`: añadir `goToRoutineList`, `pushRoutineEditor(id?)`, `pushDayEditor(args)`, `pushRoutineDay(args)`, `pushRoutineStats(args)`, `pushExerciseProgress(args)`.
   - Sweep de `context.push/go/pop(AppRoutes.*)` directos → llamadas a helpers.
7. **Coaching messages** centralizados:
   - `lib/core/i18n/coaching_messages.dart` con maps de strings (sigue siendo español por D6, pero centralizado).
   - `exercise_card.dart:146-151,305-316` → consume del map.

**Hallazgos cerrados**: A16, A17, A19, M10, M12 (parcial), B3, widgets gigantes, routing extras frágiles.

**DoD**:
- [ ] `wc -l` de todo `lib/features/**/*.dart`: ningún archivo > 200 LOC.
- [ ] `grep -rn "showModalBottomSheet" lib/features/` solo devuelve usos vía `AppBottomSheet.show`.
- [ ] `grep -rn "state.extra as Map" lib/` devuelve 0 matches.
- [ ] `grep -rn "context\.\(push\|go\|pop\)(AppRoutes" lib/features/` devuelve 0 matches (todos vía helpers).
- [ ] Coaching strings centralizados.
- [ ] `flutter test` verde.

**Riesgos**: descomponer `routine_editor_page.dart` puede romper la lógica de `_hasMutations`/`_pendingPop` si no se migra con cuidado. Mitigación: tests de widget para confirm-dialog antes y después.

---

### Fase 5 — Loaders y feedback unificados

**Rama**: `remaster/fase-5-feedback`
**Objetivo**: cero `CircularProgressIndicator` directo en `features/`. Toda acción asíncrona muestra skeleton (espera de datos) o overlay loader (acción bloqueante). Toda comunicación es vía `AppSnackBar`/`AppDialog`.
**Alcance SÍ**: `AppLoader`, `AppSkeleton` + skeletons específicos, `AppSnackBar`, `AppDialog`, `BlocStatusBuilder` mixin.
**Alcance NO**: rediseño visual (Fase 6).

**Tareas**:

1. Añadir `shimmer` a `pubspec.yaml`.
2. Crear `lib/core/ui/feedback/`:
   - `app_loader.dart` — overlay full-screen con `showAppLoader(context)` / `hideAppLoader(context)` para login, finalize, etc.
   - `app_skeleton.dart` — primitive shimmer tile.
   - `app_snack_bar.dart` — `AppSnackBar.error(context, msg)`, `.success(...)`, `.info(...)`. Lee `SnackBarTheme`.
   - `app_dialog.dart` — `AppDialog.confirm(context, title, message, confirmLabel)` con haptics.
3. Skeletons específicos en `lib/features/workout/presentation/<sub>/widgets/`:
   - `dashboard_skeleton.dart` (rutina + 7 días + insights).
   - `routine_day_skeleton.dart` (lista de ejercicios).
   - `weekly_insights_skeleton.dart`.
   - `routine_list_skeleton.dart`.
   - `exercise_progress_skeleton.dart`.
4. Crear `lib/core/presentation/mixins/bloc_status_builder.dart`:
   ```dart
   class BlocStatusBuilder<B extends BlocBase<S>, S> extends StatelessWidget {
     final Widget Function() loading;
     final Widget Function(String message) error;
     final Widget Function() empty;
     final Widget Function(BuildContext, S) success;
     final bool Function(S)? isEmpty;
     // ...
   }
   ```
5. **Sweep**:
   - Reemplazar las 18 `CircularProgressIndicator` por `AppLoader` (acciones bloqueantes) o skeleton específico (carga de datos).
   - Reemplazar las 33 `ScaffoldMessenger.showSnackBar` por `AppSnackBar.*`.
   - Reemplazar `showDialog` directos por `AppDialog.*` (mantener `showDialog` solo en interno de `AppDialog`).
6. **Empty states** existentes → migrar a `AppEmptyState` (creado en Fase 4).
7. **Error states** existentes → migrar a `AppErrorState` con botón retry.

**Hallazgos cerrados**: M2 (parcial), las 18 spinners, las 33 snackbar/dialog/sheet ad-hoc.

**DoD**:
- [ ] `grep -rn "CircularProgressIndicator" lib/features/` devuelve 0 matches.
- [ ] `grep -rn "ScaffoldMessenger.of" lib/features/` devuelve 0 matches.
- [ ] `grep -rn "showDialog" lib/features/` devuelve 0 matches (solo dentro de `AppDialog`).
- [ ] Páginas con datos asíncronos muestran skeleton, no spinner.
- [ ] `flutter test` verde.

**Riesgos**: bajos.

---

### Fase 6 — Rediseño UI/UX

**Rama**: `remaster/fase-6-redesign` (con sub-ramas por pantalla).
**Objetivo**: aplicar la skill `frontend-design` para elevar la UI a calidad producción, manteniendo la estructura de componentes ya consolidada.
**Alcance SÍ**: nuevas variantes visuales sobre el design system, micro-interacciones, animaciones, hero transitions.
**Alcance NO**: cambios de arquitectura/estado (todo eso ya cerrado en Fase 3).

**Sub-fases por pantalla** (orden de impacto):

1. **Dashboard** — hero card de "hoy", strip semanal con estado de completitud, tarjetas de insights con micro-gráficos `fl_chart` densos pero legibles, animación de entrada.
2. **Routine Day (pre-start)** — preview ejercicios, último rendimiento por ejercicio, CTA primario con haptics, microcopy claro.
3. **Active Workout (focus mode)** — un ejercicio prominente, navegación lateral entre sets, timer integrado, indicador "vs último" inline.
4. **Login/Register** — pulir glass actual, hero entrada, transición al dashboard con shared element.
5. **Routine Management** — listas con drag-and-drop fluido, editor con bottom sheet expandible.
6. **Routine/Exercise Stats** — gráficos densos, scrubber temporal, comparativas.

**Para cada pantalla**:
1. Generar mockups con la skill `frontend-design` (3 alternativas).
2. Validación rápida (5 min) y elección.
3. Implementación sobre el design system existente.
4. Screenshot/golden test del resultado.
5. PR autocontenido.

**Tareas transversales**:
- Hero animations entre páginas relacionadas (rutina → día → ejercicio).
- `PageTransition` custom alineado al `pageTransitionsTheme`.
- Haptic feedback (`HapticFeedback.lightImpact`) en saves, finish, milestones.
- Animaciones implícitas (`AnimatedSwitcher`, `AnimatedContainer`) en lugar de `setState` plano.
- Accesibilidad: `Semantics` en charts (cierra M14), tap targets mínimos 48dp (cierra B3).

**Hallazgos cerrados**: M14, B3, B4 (Hero animations).

**DoD por pantalla**:
- [ ] Mockup aprobado.
- [ ] Implementado sin literales fuera del tema.
- [ ] Golden test del estado principal.
- [ ] Accesibilidad verificada (Semantics + tap targets).
- [ ] Animaciones a 60fps en device físico (verificar con `flutter run --profile`).

**Riesgos**: scope creep. Mitigación: timebox por pantalla (1 sesión); si una pantalla excede, hacer "fase 6.bis" en backlog.

---

### Fase 7 — Endurecimiento "cero errores"

**Rama**: `remaster/fase-7-hardening`
**Objetivo**: cerrar todos los hallazgos restantes del diagnóstico y dejar la app con red de seguridad robusta.
**Alcance SÍ**: error mapping correcto, freezed para modelos, migración de hallazgos sueltos, tests faltantes.
**Alcance NO**: nuevas features.

**Tareas**:

1. **Error mapping correcto** (cierra C4, C5, C6, A6, A7):
   - `lib/core/error/exceptions.dart`: añadir `ValidationException`, `AuthException`, `NotFoundException`, `ConflictException`.
   - `lib/core/error/failures.dart`: añadir `ValidationFailure`, `AuthFailure`, `NotFoundFailure`, `ConflictFailure`.
   - `auth_remote_data_source.dart:27,60`: lanzar `AuthException`/`ServerException` específicos.
   - Eliminar `catch (_) { /* Ignorar */ }` en upserts; reemplazar por logging de warning vía `talker`.
   - Repos: mapear `Exception` → `Failure` específico (timeout/auth/conflict/validation/server).
2. **Freezed modelos** (cierra A11):
   - Añadir `freezed`, `freezed_annotation`, `json_annotation`, `json_serializable`, `build_runner` a `pubspec.yaml`.
   - Migrar `Routine`, `RoutineDay`, `Exercise`, `WorkoutSession`, `SetLog` a `freezed`.
   - Modelos de data → freezed con `@JsonSerializable`.
   - Verificar que entities de domain no importan modelos de data (cierra C9).
3. **`muscle_group` ↔ `target_muscle`** (cierra A5):
   - Decidir: mantener `muscle_group` (canon SQL) o renombrar a `target_muscle` con migración.
   - Eliminar fallback `?? 'Desconocido'`. Si el campo es null → `Failure` específico.
4. **N+1 reorder** (cierra C8):
   - Crear migración Supabase con RPC `reorder_routine_exercises(day_id uuid, ordered_ids uuid[])`.
   - Datasource: una sola call.
5. **Casts inseguros** (cierra A13):
   - Helper `Map<String, dynamic> _safeMap(dynamic raw, String context)` que valida antes de castear y lanza `ServerException` con contexto si falla.
   - Sweep en `workout_remote_data_source.dart`.
6. **Date format helper** (cierra M5):
   - `lib/core/utils/date_format.dart` con helpers para `YYYY-MM-DD`, `YYYY-MM-DDTHH:MM:SS`, etc.
7. **`DateTime.now()` en lógica de negocio** (cierra A12):
   - Inyectar `Clock` en use cases que lo necesitan; en producción `SystemClock`, en tests `FakeClock`.
8. **`ActiveSessionService`** (cierra M16):
   - `try/catch` alrededor de `DateTime.parse`; si falla, limpiar el estado corrupto.
9. **`copyWith` consistente** (cierra M7): tras migrar a freezed, todas las entities lo tendrán.
10. **Tests faltantes**:
    - **Integration test real**: `integration_test/critical_flow_test.dart` — login con cuenta de prueba → dashboard → start day → save 3 sets → finish → ver insights. Requiere setup de cuenta de prueba; documentar en README.
    - **Golden tests** para los 8 widgets atómicos clave: `AppFormField`, `AppButton`, `AppCard`, `AppEmptyState`, `AppErrorState`, `AppLoader`, `AppSkeleton`, `AppSnackBar`.
    - **Widget tests faltantes**: presentation de auth, blocs nuevos.
11. **`AGENT_CONTEXT.md`** actualizado: refleja los cambios estructurales, drifts cerrados, nueva organización.
12. **`CLAUDE.md`** actualizado: reglas nuevas, comandos nuevos.

**Hallazgos cerrados**: C4, C5, C6, C8, A5, A6, A7, A11, A12, A13, M5, M7, M16, M18, M19, todo lo restante.

**DoD final del remaster**:
- [ ] Toda la checklist "cero errores" del diagnóstico (sección 6) verde.
- [ ] `flutter analyze` 0 issues bajo lints estrictos.
- [ ] `flutter test` con cobertura ≥ 60% domain, ≥ 50% presentation/blocs.
- [ ] Integration test crítico verde en CI.
- [ ] Smoke test de Edge Functions verde manual.
- [ ] Documentación actualizada.

**Riesgos**: la migración a freezed requiere `build_runner` corriendo en watch. Mitigación: documentar en README y CLAUDE.md; CI corre `build_runner build --delete-conflicting-outputs` antes de tests.

---

### Fase 8 — Opcional (post-remaster)

**Rama**: `remaster/fase-8-extensions`
**Objetivo**: cerrar los items diferidos durante el remaster.
**Alcance**: opcional, requiere visto bueno separado.

**Sub-fases independientes**:

- **8.1 Offline-first reactivado**: re-cablear `WorkoutLocalDataSource`, `SyncService`, `NetworkInfo` en DI; definir política de conflictos; tests de sincronización; queue de pending writes. Cierra C10. ~3 sesiones.
- **8.2 i18n completo**: migrar de `core/i18n/strings_es.dart` a `flutter_localizations` + `.arb`; añadir inglés (opcional). ~2 sesiones.
- **8.3 SetLog extensible**: migración Supabase para soportar RPE/RIR/AMRAP/drop sets/tempo. UI para ingresar. ~3 sesiones.
- **8.4 Endurecimiento RLS**: revisar políticas `USING (true)` y separar catálogo público de datos privados. ~1 sesión.

---

## 5. Convenciones de trabajo

### Branching
- Rama base: `main`.
- Rama de remaster: `remaster/fase-N-<slug>`.
- Sub-ramas si una fase se split: `remaster/fase-N-<slug>/<subtask>`.

### Commits
- Convención existente del repo (revisar `git log`): `tipo: descripción`. Ej: `refactor: split workout bloc into 6 sub-blocs`, `feat: add formz inputs for auth forms`, `fix: dispose controllers in remote target editor`.
- Cada commit debe pasar `flutter analyze` y `flutter test`.

### PRs
- Título: `[Remaster F-N] <descripción>`.
- Body con: hallazgos cerrados (refs `Cn/An/Mn/Bn`), DoD checklist, screenshots/screencasts si toca UI, comando manual de verificación.
- 1 reviewer mínimo.
- CI verde obligatorio antes de merge.

### Verificación pre-PR (script)
Crear `scripts/check.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # post-Fase 7
flutter analyze
flutter test
```

---

## 6. Estimación

- **12-15 sesiones** de trabajo (Fases 0-7).
- Asumiendo 1 sesión = 3-4 horas efectivas, ~50 horas de trabajo.
- Fase 6 (rediseño) es la más variable: depende de iteraciones de mockup.
- Fase 8 opcional: +6-9 sesiones si se ejecuta completa.

---

## 7. Anexos

### 7.1 Estructura objetivo `lib/`

```
lib/
  main.dart                                    bootstrap con red de seguridad
  injection_container.dart                     DI organizada por capas
  core/
    config/
      supabase_config.dart                     sin defaults hardcoded
    error/
      error_reporter.dart                      Flutter/Platform/Zone hooks
      exceptions.dart                          Server/Cache/Network/Validation/Auth/NotFound/Conflict
      failures.dart                            equivalentes
    forms/
      inputs/                                  Email, Password, RequiredText, Weight, Reps
      form_bloc_base.dart
    i18n/
      coaching_messages.dart
      strings_es.dart                          (post-Fase 8 → .arb)
    observability/
      app_bloc_observer.dart
    presentation/
      mixins/
        bloc_status_builder.dart
    routes/
      app_router.dart
      app_routes.dart
      router_helpers.dart                      todas las navegaciones
      args/                                    typed extras por ruta
    services/
      active_session_service.dart
    theme/
      tokens/{spacing,radii,durations,elevations}.dart
      app_colors.dart
      app_text_theme.dart
      app_theme.dart
    ui/
      atoms/                                   AppButton, AppChip, AppBadge, AppText, AppDivider
      molecules/                               AppCard, AppFormField, AppEmptyState, AppErrorState, AppSectionHeader
      layout/                                  AppScaffold, AppPageHeader
      feedback/                                AppLoader, AppSkeleton, AppSnackBar, AppDialog, AppBottomSheet
    utils/
      date_format.dart
      clock.dart                               inyectable para tests
  features/
    auth/
      data/{datasources,models,repositories}/
      domain/{entities,repositories,usecases}/
      presentation/
        bloc/
          auth_bloc.dart
          login_form_bloc.dart
          register_form_bloc.dart
        pages/
        widgets/
    workout/
      data/{datasources,models,repositories}/
      domain/{entities,repositories,usecases}/
      presentation/
        bloc/
          dashboard/
          routine_day/
          active_workout/
          routine_management/
          session_history/
          active_session_watcher/
          exercise_stats/
          routine_stats/
        dashboard/
        routine_day/
        active_workout/
        routine_management/
        routine_stats/
        exercise_stats/
        debug/
        shared/
```

### 7.2 Mapa hallazgo → fase (resumen)

| Hallazgo | Fase | Hallazgo | Fase |
|---|---|---|---|
| C1, C2, C3 | 0 | A6, A7 | 7 |
| C4, C5, C6 | 7 | A8, A9, A10 | 3 |
| C7 | 2 | A11 | 7 |
| C8 | 7 | A12, A13 | 7 |
| C9 | 7 | A14 | 2 |
| C10 | 8 (opcional) | A15 | 3 |
| C11 | 0 | A16, A17 | 4 |
| C12 | 1 | A18 | 1 |
| C13 | 0 | A19 | 4 |
| C14 | 0 | A20 | 3 |
| A1, A2 | 3 | M1-M4 | 3 |
| A3, A4 | 2 | M5, M7, M8 | 7 |
| A5 | 7 | M6 | 7 |
| M9 | 3 | M10-M12 | 4 (centralizar), 8 (i18n) |
| M13 | 2 | M14 | 6 |
| M15 | 0 | M16 | 7 |
| M17 | distribuido | M18, M19 | 7 |
| B1-B7 | distribuido | | |

### 7.3 Comandos clave durante el remaster

```bash
# Setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Dev loop
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
dart run build_runner watch --delete-conflicting-outputs   # post-Fase 7

# Pre-commit
bash scripts/check.sh

# Tests específicos
flutter test test/features/workout/presentation/bloc/dashboard/dashboard_bloc_test.dart
flutter test --plain-name "valida email vacío"
flutter test --update-goldens                              # actualizar goldens

# Smoke E2E backend
SUPABASE_DB_PASSWORD=... bash scripts/contract_smoke_supabase.sh
```

---

## 8. Pre-arranque

Antes de mergear este documento y abrir el branch de Fase 0, confirmame:

1. **D1 (`formz`)** ¿OK o prefieres `reactive_forms`?
2. **D3 (paleta neon-lime)** ¿OK pulir la actual o exploramos dirección visual nueva con `frontend-design`?
3. **D5 (offline-first diferido a Fase 8)** ¿OK o lo metemos en Fase 7?
4. **D6 (i18n diferido)** ¿OK o queremos `.arb`/`flutter_localizations` durante Fase 4?
5. **D9 (alcance de tests)** ¿OK con bloc tests + integration crítico + goldens del design system, o quieres goldens de toda la UI?

Con esos 5 OK arranco con **Fase 0 — Red de seguridad**.
