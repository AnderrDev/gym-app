import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:gym_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockWorkoutRemoteDataSource extends Mock
    implements WorkoutRemoteDataSource {}

class MockActiveSessionService extends Mock implements ActiveSessionService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockLiveActivitiesBridge extends Mock implements LiveActivitiesBridge {}

class MockActiveWorkoutNotifier extends Mock implements ActiveWorkoutNotifier {}

class MockClock extends Mock implements Clock {}

/// Convenience factory: returns a [FakeClock] anchored at the given fixed
/// instant. Use this in tests that exercise time-sensitive behaviour
/// (week_start boundaries, rest timers, session_date).
FakeClock fakeClockAt(DateTime instant) => FakeClock(instant);
