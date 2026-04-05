import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';

void main() {
  group('Workout Entities', () {
    test('Routine should support equality', () {
      const routine1 = Routine(id: '1', name: 'R1', exerciseCount: 5);
      const routine2 = Routine(id: '1', name: 'R1', exerciseCount: 5);
      expect(routine1, routine2);
    });

    test('RoutineDay should support equality', () {
      const day1 = RoutineDay(
        id: '1',
        routineId: 'r1',
        dayOfWeek: 1,
        name: 'D1',
      );
      const day2 = RoutineDay(
        id: '1',
        routineId: 'r1',
        dayOfWeek: 1,
        name: 'D1',
      );
      expect(day1, day2);
    });

    test('WorkoutSession should support equality', () {
      final date = DateTime(2026, 1, 1);
      final session1 = WorkoutSession(
        id: '1',
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: date,
      );
      final session2 = WorkoutSession(
        id: '1',
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: date,
      );
      expect(session1, session2);
    });

    test('WeeklyInsights should support equality', () {
      final date = DateTime(2026, 1, 1);
      final insights1 = WeeklyInsights(
        weekStart: date,
        weekEnd: date,
        plannedDays: 1,
        completedDays: 1,
        completedSessions: 1,
        adherenceRate: 1.0,
        totalVolume: 100,
        previousWeekVolume: 90,
        volumeTrendPercent: 10,
        personalRecords: 1,
      );
      final insights2 = WeeklyInsights(
        weekStart: date,
        weekEnd: date,
        plannedDays: 1,
        completedDays: 1,
        completedSessions: 1,
        adherenceRate: 1.0,
        totalVolume: 100,
        previousWeekVolume: 90,
        volumeTrendPercent: 10,
        personalRecords: 1,
      );
      expect(insights1, insights2);
    });

    test('SetLog should support equality', () {
      final date = DateTime(2026, 1, 1);
      final log1 = SetLog(
        id: '1',
        sessionId: 's1',
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 10,
        actualReps: 10,
        createdAt: date,
      );
      final log2 = SetLog(
        id: '1',
        sessionId: 's1',
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 10,
        actualReps: 10,
        createdAt: date,
      );
      expect(log1, log2);
    });

    test('Exercise should support equality', () {
      const ex1 = Exercise(
        id: '1',
        name: 'E1',
        routineDayId: 'd1',
        targetMuscle: 'Chest',
        targetWeight: 100,
        targetReps: 10,
      );
      const ex2 = Exercise(
        id: '1',
        name: 'E1',
        routineDayId: 'd1',
        targetMuscle: 'Chest',
        targetWeight: 100,
        targetReps: 10,
      );
      expect(ex1, ex2);
    });
  });
}
