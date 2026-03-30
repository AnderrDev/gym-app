import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'core/database/database_helper.dart';
import 'core/network/network_info.dart';

import 'features/workout/data/datasources/workout_remote_data_source.dart';
import 'features/workout/data/datasources/workout_local_data_source.dart';
import 'features/workout/data/repositories/workout_repository_impl.dart';
import 'features/workout/domain/repositories/workout_repository.dart';
import 'features/workout/domain/usecases/finish_workout_session.dart';
import 'features/workout/domain/usecases/get_assigned_routines.dart';
import 'features/workout/domain/usecases/get_last_exercise_performance.dart';
import 'features/workout/domain/usecases/save_set_log.dart';
import 'features/workout/domain/usecases/start_workout_session.dart';
import 'features/workout/domain/usecases/get_routine_exercises.dart';
import 'features/workout/presentation/bloc/workout_bloc.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/sign_in_with_email.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up_with_email.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      signInWithEmail: sl(),
      signUpWithEmail: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );

  // Features - Workout
  // Bloc
  sl.registerFactory(
    () => WorkoutBloc(
      getAssignedRoutines: sl(),
      getLastExercisePerformance: sl(),
      saveSetLog: sl(),
      finishWorkoutSession: sl(),
      startWorkoutSession: sl(),
      getRoutineExercises: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAssignedRoutines(sl()));
  sl.registerLazySingleton(() => GetLastExercisePerformance(sl()));
  sl.registerLazySingleton(() => SaveSetLog(sl()));
  sl.registerLazySingleton(() => FinishWorkoutSession(sl()));
  sl.registerLazySingleton(() => StartWorkoutSession(sl()));
  sl.registerLazySingleton(() => GetRoutineExercises(sl()));

  // Repository
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<WorkoutRemoteDataSource>(
    () => WorkoutRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<WorkoutLocalDataSource>(
    () => WorkoutLocalDataSourceImpl(dbHelper: sl()),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  // External
  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => InternetConnection());
}
