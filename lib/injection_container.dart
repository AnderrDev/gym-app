import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/active_session_service.dart';
import 'features/workout/data/datasources/workout_remote_data_source.dart';
import 'features/workout/data/repositories/workout_repository_impl.dart';
import 'features/workout/domain/repositories/workout_repository.dart';
import 'features/workout/domain/usecases/get_assigned_routines.dart';
import 'features/workout/domain/usecases/get_last_exercise_performance.dart';
import 'features/workout/domain/usecases/get_weekly_plan.dart';
import 'features/workout/domain/usecases/get_session_history.dart';
import 'features/workout/domain/usecases/save_set_log.dart';
import 'features/workout/presentation/bloc/workout_bloc.dart';
import 'features/workout/presentation/bloc/exercise_stats/exercise_stats_bloc.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/sign_in_with_email.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up_with_email.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// ── DESACTIVADO TEMPORALMENTE ───────────────────────────────────────────────
// import 'core/database/database_helper.dart';
// import 'core/network/network_info.dart';
// import 'core/services/sync_service.dart';
// import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
// import 'features/workout/data/datasources/workout_local_data_source.dart';
// ───────────────────────────────────────────────────────────────────────────

final sl = GetIt.instance;

Future<void> init() async {
  // ── AUTH ──────────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => AuthBloc(
      signInWithEmail: sl(),
      signUpWithEmail: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
    ),
  );

  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // ── WORKOUT (100% remoto) ────────────────────────────────────────────────
  sl.registerFactory(
    () => WorkoutBloc(
      getAssignedRoutines: sl(),
      getWeeklyPlan: sl(),
      saveSetLog: sl(),
      repository: sl(),
      activeSessionService: sl(),
    ),
  );

  sl.registerFactory(
    () => ExerciseStatsBloc(
      repository: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetAssignedRoutines(sl()));
  sl.registerLazySingleton(() => GetWeeklyPlan(sl()));
  sl.registerLazySingleton(() => GetSessionHistory(sl()));
  sl.registerLazySingleton(() => GetLastExercisePerformance(sl()));
  sl.registerLazySingleton(() => SaveSetLog(sl()));

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
}
