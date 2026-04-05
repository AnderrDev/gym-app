import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

const testUser = User(
  id: 'user-1',
  email: 'test@example.com',
  fullName: 'Test User',
);

const testRoutine = Routine(
  id: 'routine-1',
  name: 'Test Routine',
  exerciseCount: 5,
  isPublic: false,
);

const testRoutineDay = RoutineDay(
  id: 'day-1',
  routineId: 'routine-1',
  dayOfWeek: 1,
  name: 'Monday Workout',
  status: WorkoutDayStatus.pending,
);

final testSessionDate = DateTime(2026, 4, 6);

final testWeeklyInsights = WeeklyInsights(
  weekStart: testSessionDate,
  weekEnd: testSessionDate.add(const Duration(days: 6)),
  plannedDays: 5,
  completedDays: 0,
  completedSessions: 0,
  adherenceRate: 0,
  totalVolume: 0,
  previousWeekVolume: 0,
  volumeTrendPercent: 0,
  personalRecords: 0,
);

final testWorkoutSession = WorkoutSession(
  id: 'session-1',
  userId: 'user-1',
  routineDayId: 'day-1',
  sessionDate: testSessionDate,
);
