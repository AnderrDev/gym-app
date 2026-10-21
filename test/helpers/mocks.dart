import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/core/services/local_user_data_cleaner.dart';
import 'package:gym_flutter/core/services/workout_draft_service.dart';
import 'package:gym_flutter/core/sync/connectivity_service.dart';
import 'package:gym_flutter/core/sync/outbox_repository.dart';
import 'package:gym_flutter/core/sync/sync_worker.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:gym_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:gym_flutter/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:gym_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:gym_flutter/features/profile/domain/usecases/delete_account.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_local_data_source.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockSignOut extends Mock implements SignOut {}

class MockLocalUserDataCleaner extends Mock implements LocalUserDataCleaner {}

class MockWorkoutDraftService extends Mock implements WorkoutDraftService {}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockWorkoutRemoteDataSource extends Mock
    implements WorkoutRemoteDataSource {}

class MockWorkoutLocalDataSource extends Mock
    implements WorkoutLocalDataSource {}

class MockActiveSessionService extends Mock implements ActiveSessionService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockLiveActivitiesBridge extends Mock implements LiveActivitiesBridge {}

class MockActiveWorkoutNotifier extends Mock implements ActiveWorkoutNotifier {}

class MockClock extends Mock implements Clock {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockSyncWorker extends Mock implements SyncWorker {}

class MockUuid extends Mock implements Uuid {}

/// Convenience factory: returns a [FakeClock] anchored at the given fixed
/// instant. Use this in tests that exercise time-sensitive behaviour
/// (week_start boundaries, rest timers, session_date).
FakeClock fakeClockAt(DateTime instant) => FakeClock(instant);
