import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_flutter/core/database/dao/workout_cache_dao.dart';
import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/sync/connectivity_service.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_local_data_source.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_local_data_source_impl.dart';

import 'core/notifications/active_workout_notifier.dart';
import 'core/notifications/live_activities_bridge.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/active_session_service.dart';
import 'core/utils/clock.dart';
import 'features/workout/data/datasources/exercise_catalog_remote_data_source.dart';
import 'features/workout/data/datasources/routine_management_remote_data_source.dart';
import 'features/workout/data/datasources/workout_remote_data_source.dart';
import 'features/workout/data/datasources/workout_session_remote_data_source.dart';
import 'features/workout/data/repositories/workout_repository_impl.dart';
import 'features/workout/domain/repositories/workout_repository.dart';
import 'features/workout/domain/usecases/get_assigned_routines.dart';
import 'features/workout/domain/usecases/get_weekly_plan.dart';
import 'features/workout/domain/usecases/save_set_log.dart';
import 'features/workout/presentation/bloc/active_session_watcher/active_session_watcher_bloc.dart';
import 'features/workout/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'features/workout/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'features/workout/presentation/bloc/exercise_stats/exercise_stats_bloc.dart';
import 'features/workout/presentation/bloc/progress/progress_bloc.dart';
import 'features/workout/presentation/bloc/routine_day/routine_day_bloc.dart';
import 'features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'features/workout/domain/usecases/add_exercise_to_day.dart';
import 'features/workout/domain/usecases/add_exercises_to_day.dart';
import 'features/workout/domain/usecases/assign_routine.dart';
import 'features/workout/domain/usecases/delete_routine.dart';
import 'features/workout/domain/usecases/delete_routine_day.dart';
import 'features/workout/domain/usecases/get_all_routines.dart';
import 'features/workout/domain/usecases/get_exercises_catalog.dart';
import 'features/workout/domain/usecases/get_routine_by_id.dart';
import 'features/workout/domain/usecases/remove_exercise_from_day.dart';
import 'features/workout/domain/usecases/reorder_exercises.dart';
import 'features/workout/domain/usecases/save_routine.dart';
import 'features/workout/domain/usecases/save_routine_day.dart';
import 'features/workout/domain/usecases/update_exercise_target.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/request_password_reset.dart';
import 'features/auth/domain/usecases/sign_in_with_email.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up_with_email.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── AUTH ──────────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => AuthBloc.fromRepository(
      authRepository: sl(),
      signInWithEmail: sl(),
      signUpWithEmail: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
      activeSessionService: sl(),
    ),
  );

  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => RequestPasswordReset(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // ── PROFILE ───────────────────────────────────────────────────────────────
  sl.registerFactory(() => ProfileBloc(repository: sl()));
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remote: sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(client: sl()),
  );

  // ── WORKOUT (100% remoto) ────────────────────────────────────────────────
  sl.registerFactory(() => ExerciseStatsBloc(repository: sl()));

  sl.registerFactory(
    () => DashboardBloc(
      getAssignedRoutines: sl(),
      getWeeklyPlan: sl(),
      repository: sl(),
    ),
  );

  sl.registerFactory(() => RoutineDayBloc(repository: sl()));

  sl.registerFactory(
    () => ActiveWorkoutBloc(
      repository: sl(),
      activeSessionService: sl(),
      notifier: sl(),
    ),
  );

  sl.registerFactory(
    () => RoutineManagementBloc(
      assignRoutine: sl(),
      getAllRoutines: sl(),
      getAssignedRoutines: sl(),
      getWeeklyPlan: sl(),
      getRoutineById: sl(),
      saveRoutine: sl(),
      deleteRoutine: sl(),
      saveRoutineDay: sl(),
      deleteRoutineDay: sl(),
      addExerciseToDay: sl(),
      addExercisesToDay: sl(),
      removeExerciseFromDay: sl(),
      reorderExercises: sl(),
      updateExerciseTarget: sl(),
      getExercisesCatalog: sl(),
    ),
  );

  sl.registerFactory(
    () =>
        ActiveSessionWatcherBloc(repository: sl(), activeSessionService: sl()),
  );

  sl.registerFactory(
    () => ProgressBloc(getAssignedRoutines: sl(), repository: sl()),
  );

  sl.registerLazySingleton(() => GetAssignedRoutines(sl()));
  sl.registerLazySingleton(() => GetWeeklyPlan(sl()));
  sl.registerLazySingleton(() => SaveSetLog(sl()));
  sl.registerLazySingleton(() => AssignRoutine(sl()));
  sl.registerLazySingleton(() => GetAllRoutines(sl()));
  sl.registerLazySingleton(() => GetRoutineById(sl()));
  sl.registerLazySingleton(() => SaveRoutine(sl()));
  sl.registerLazySingleton(() => DeleteRoutine(sl()));
  sl.registerLazySingleton(() => SaveRoutineDay(sl()));
  sl.registerLazySingleton(() => DeleteRoutineDay(sl()));
  sl.registerLazySingleton(() => AddExerciseToDay(sl()));
  sl.registerLazySingleton(() => AddExercisesToDay(sl()));
  sl.registerLazySingleton(() => RemoveExerciseFromDay(sl()));
  sl.registerLazySingleton(() => ReorderExercises(sl()));
  sl.registerLazySingleton(() => UpdateExerciseTarget(sl()));
  sl.registerLazySingleton(() => GetExercisesCatalog(sl()));

  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl.isRegistered<WorkoutLocalDataSource>()
          ? sl<WorkoutLocalDataSource>()
          : null,
      connectivity: sl<ConnectivityService>(),
    ),
  );

  // Colaboradores internos del fachada `WorkoutRemoteDataSource`. Se registran
  // separados para poder reutilizarlos en tests o futuras refactorizaciones.
  sl.registerLazySingleton<WorkoutSessionRemoteDataSource>(
    () => WorkoutSessionRemoteDataSource(client: sl()),
  );
  sl.registerLazySingleton<RoutineManagementRemoteDataSource>(
    () => RoutineManagementRemoteDataSource(client: sl()),
  );
  sl.registerLazySingleton<ExerciseCatalogRemoteDataSource>(
    () => ExerciseCatalogRemoteDataSource(client: sl()),
  );

  sl.registerLazySingleton<WorkoutRemoteDataSource>(
    () => WorkoutRemoteDataSourceImpl.fromParts(
      sessions: sl(),
      routines: sl(),
      catalog: sl(),
    ),
  );

  // ── EXTERNAL ──────────────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Local database (drift): se abre eagerly y se valida con `ping()` para
  // detectar corrupción/migrations rotas en bootstrap. En web la persistencia
  // local llegará en Phase W; mientras tanto no se registra el singleton.
  if (!kIsWeb) {
    final localDb = LocalDatabase.open();
    await localDb.ping();
    sl.registerLazySingleton<LocalDatabase>(() => localDb);

    sl.registerLazySingleton<WorkoutCacheDao>(
      () => WorkoutCacheDao(sl<LocalDatabase>()),
    );
    sl.registerLazySingleton<WorkoutLocalDataSource>(
      () => WorkoutLocalDataSourceImpl(sl<WorkoutCacheDao>()),
    );
    AppLogger.instance.info('local_db ready (schema v2)');
  } else {
    // Phase W enables web persistence. For now, do not register.
  }

  // Connectivity: única fuente de verdad para online/offline. La consumirán
  // los servicios de sync en Phase 1+.
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(Connectivity()),
  );

  // UUID generator. Reusado por Phase 1+ (sync queue, optimistic ids, etc.).
  sl.registerLazySingleton<Uuid>(() => const Uuid());

  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => ActiveSessionService(sl()));
  sl.registerLazySingleton<Clock>(() => const SystemClock());

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => FlutterLocalNotificationsPlugin());
  sl.registerLazySingleton(() => NotificationService(sl()));
  sl.registerLazySingleton(() => LiveActivitiesBridge());
  sl.registerLazySingleton(
    () => ActiveWorkoutNotifier(
      notifications: sl(),
      liveActivities: sl(),
      sessionService: sl(),
    ),
  );
}
