import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/notifications/active_workout_notifier.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/active_session_service.dart';
import 'core/utils/clock.dart';
import 'features/workout/data/datasources/workout_remote_data_source.dart';
import 'features/workout/data/repositories/workout_repository_impl.dart';
import 'features/workout/domain/repositories/workout_repository.dart';
import 'features/workout/domain/usecases/get_assigned_routines.dart';
import 'features/workout/domain/usecases/get_weekly_plan.dart';
import 'features/workout/domain/usecases/save_set_log.dart';
import 'features/workout/presentation/bloc/active_session_watcher/active_session_watcher_bloc.dart';
import 'features/workout/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'features/workout/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'features/workout/presentation/bloc/exercise_stats/exercise_stats_bloc.dart';
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
import 'features/auth/domain/usecases/get_current_user.dart';
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

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
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
    () => WorkoutRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<WorkoutRemoteDataSource>(
    () => WorkoutRemoteDataSourceImpl(client: sl()),
  );

  // ── EXTERNAL ──────────────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => ActiveSessionService(sl()));
  sl.registerLazySingleton<Clock>(() => const SystemClock());

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => FlutterLocalNotificationsPlugin());
  sl.registerLazySingleton(() => NotificationService(sl()));
  sl.registerLazySingleton(
    () => ActiveWorkoutNotifier(notifications: sl(), sessionService: sl()),
  );
}
