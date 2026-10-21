import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/core/services/local_user_data_cleaner.dart';
import 'package:gym_flutter/core/services/routine_assignment_bus.dart';
import 'package:gym_flutter/core/services/shell_tab_notifier.dart';
import 'package:gym_flutter/core/services/workout_draft_service.dart';
import 'package:gym_flutter/core/settings/presentation/settings_bloc.dart';
import 'package:gym_flutter/core/settings/user_preferences_service.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:gym_flutter/features/auth/domain/usecases/get_current_user.dart';
import 'package:gym_flutter/features/auth/domain/usecases/request_password_reset.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:gym_flutter/features/profile/domain/usecases/delete_account.dart';
import 'package:gym_flutter/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_assigned_routines.dart';
import 'package:gym_flutter/features/workout/domain/usecases/assign_routine.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_all_routines.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_routine_by_id.dart';
import 'package:gym_flutter/features/workout/domain/usecases/save_routine.dart';
import 'package:gym_flutter/features/workout/domain/usecases/delete_routine.dart';
import 'package:gym_flutter/features/workout/domain/usecases/fork_routine.dart';
import 'package:gym_flutter/features/workout/domain/usecases/save_routine_day.dart';
import 'package:gym_flutter/features/workout/domain/usecases/delete_routine_day.dart';
import 'package:gym_flutter/features/workout/domain/usecases/add_exercise_to_day.dart';
import 'package:gym_flutter/features/workout/domain/usecases/add_exercises_to_day.dart';
import 'package:gym_flutter/features/workout/domain/usecases/remove_exercise_from_day.dart';
import 'package:gym_flutter/features/workout/domain/usecases/reorder_exercises.dart';
import 'package:gym_flutter/features/workout/domain/usecases/update_exercise_target.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_exercises_catalog.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_session_detail.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_session_exercises.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_weekly_plan.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_day/routine_day_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/injection_container.dart';
import 'package:gym_flutter/main.dart';

import 'fake_backend.dart';

/// Backend de la prueba en curso.
class TestBackend {
  TestBackend({required this.workout, required this.auth, required this.prefs});

  final FakeWorkoutRepository workout;
  final FakeAuthRepository auth;
  final SharedPreferences prefs;
}

/// Monta la app real (`SmartGymTrackerApp`: router, shell, BLoCs y páginas)
/// con el mismo cableado que `injection_container.init()` en las piezas que
/// recorren los flujos, pero con repositorios en memoria. Sin Supabase,
/// drift ni red: corre igual en un dispositivo que con `flutter test`.
Future<TestBackend> pumpTestApp(
  WidgetTester tester, {
  bool signedIn = true,
  bool secondRoutine = false,
  Map<String, Object> prefs = const {},
}) async {
  await initializeDateFormatting('es', null);
  await sl.reset();
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPreferences = await SharedPreferences.getInstance();

  final backend = TestBackend(
    workout: FakeWorkoutRepository(secondRoutine: secondRoutine),
    auth: FakeAuthRepository(signedIn: signedIn),
    prefs: sharedPreferences,
  );

  sl
    // Externos y servicios
    ..registerLazySingleton(() => sharedPreferences)
    ..registerLazySingleton<Clock>(() => const SystemClock())
    ..registerLazySingleton(() => ActiveSessionService(sl()))
    ..registerLazySingleton(() => WorkoutDraftService(sl()))
    ..registerLazySingleton(() => RoutineAssignmentBus())
    ..registerLazySingleton(() => ShellTabNotifier())
    ..registerLazySingleton<UserPreferencesService>(
      () => UserPreferencesService(sl()),
    )
    ..registerLazySingleton<SettingsBloc>(() => SettingsBloc(preferences: sl()))
    ..registerLazySingleton<NotificationService>(NoopNotificationService.new)
    ..registerLazySingleton<LiveActivitiesBridge>(NoopLiveActivitiesBridge.new)
    ..registerLazySingleton<ActiveWorkoutNotifier>(
      NoopActiveWorkoutNotifier.new,
    )
    // Auth
    ..registerLazySingleton<AuthRepository>(() => backend.auth)
    ..registerLazySingleton(() => SignInWithEmail(sl()))
    ..registerLazySingleton(() => SignUpWithEmail(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => GetCurrentUser(sl()))
    ..registerLazySingleton(() => RequestPasswordReset(sl()))
    ..registerFactory(
      () => AuthBloc.fromRepository(
        authRepository: sl(),
        signInWithEmail: sl(),
        signUpWithEmail: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
        activeSessionService: sl(),
      ),
    )
    // Perfil
    ..registerLazySingleton<ProfileRepository>(FakeProfileRepository.new)
    ..registerLazySingleton(() => DeleteAccount(sl()))
    ..registerLazySingleton(
      () =>
          LocalUserDataCleaner(activeSessionService: sl(), draftService: sl()),
    )
    ..registerFactory(
      () => ProfileBloc(
        repository: sl(),
        deleteAccount: sl(),
        localDataCleaner: sl(),
        signOut: sl(),
      ),
    )
    // Workout
    ..registerLazySingleton<WorkoutRepository>(() => backend.workout)
    ..registerLazySingleton(() => GetAssignedRoutines(sl()))
    ..registerLazySingleton(() => GetWeeklyPlan(sl()))
    ..registerLazySingleton(() => GetSessionExercises(sl()))
    ..registerLazySingleton(() => GetExercisesCatalog(sl()))
    ..registerFactory(
      () => DashboardBloc(
        getAssignedRoutines: sl(),
        getWeeklyPlan: sl(),
        repository: sl(),
        preferences: sl(),
      ),
    )
    ..registerFactory(() => RoutineDayBloc(repository: sl()))
    ..registerFactory(
      () => ActiveWorkoutBloc(
        repository: sl(),
        activeSessionService: sl(),
        draftService: sl(),
        notifier: sl(),
        clock: sl<Clock>(),
      ),
    )
    ..registerLazySingleton(() => GetSessionDetail(sl()))
    ..registerFactory(
      () => ProgressBloc(getAssignedRoutines: sl(), repository: sl()),
    )
    ..registerFactory(() => ExerciseStatsBloc(repository: sl()))
    // RUTINAS
    ..registerLazySingleton(() => AssignRoutine(sl()))
    ..registerLazySingleton(() => GetAllRoutines(sl()))
    ..registerLazySingleton(() => GetRoutineById(sl()))
    ..registerLazySingleton(() => SaveRoutine(sl()))
    ..registerLazySingleton(() => DeleteRoutine(sl()))
    ..registerLazySingleton(() => ForkRoutine(sl()))
    ..registerLazySingleton(() => SaveRoutineDay(sl()))
    ..registerLazySingleton(() => DeleteRoutineDay(sl()))
    ..registerLazySingleton(() => AddExerciseToDay(sl()))
    ..registerLazySingleton(() => AddExercisesToDay(sl()))
    ..registerLazySingleton(() => RemoveExerciseFromDay(sl()))
    ..registerLazySingleton(() => ReorderExercises(sl()))
    ..registerLazySingleton(() => UpdateExerciseTarget(sl()))
    ..registerFactory(
      () => RoutineManagementBloc(
        assignRoutine: sl(),
        getAllRoutines: sl(),
        getAssignedRoutines: sl(),
        getWeeklyPlan: sl(),
        getRoutineById: sl(),
        saveRoutine: sl(),
        deleteRoutine: sl(),
        forkRoutine: sl(),
        saveRoutineDay: sl(),
        deleteRoutineDay: sl(),
        addExerciseToDay: sl(),
        addExercisesToDay: sl(),
        removeExerciseFromDay: sl(),
        reorderExercises: sl(),
        updateExerciseTarget: sl(),
        getExercisesCatalog: sl(),
      ),
    )
    ..registerFactory(
      () => ActiveSessionWatcherBloc(
        repository: sl(),
        activeSessionService: sl(),
      ),
    );

  await tester.pumpWidget(const SmartGymTrackerApp());
  await settle(tester);
  return backend;
}

/// `pumpAndSettle` con tope: el spinner de carga anima en bucle y no
/// dejaría asentarse nunca. En un dispositivo (binding en vivo) el trabajo
/// asíncrono tarda tiempo real, así que se espera un mínimo antes de dar la
/// pantalla por asentada.
Future<void> settle(WidgetTester tester) async {
  final live = tester.binding is! AutomatedTestWidgetsFlutterBinding;
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (live) await Future<void>.delayed(const Duration(milliseconds: 50));
    if (i >= (live ? 8 : 0) && !tester.binding.hasScheduledFrame) return;
  }
}
