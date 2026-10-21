import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_session_detail.dart';

import '../../../../helpers/mocks.dart';

const testSetLog = SetLog(
  id: 'l1',
  sessionId: 's1',
  exerciseId: 'e1',
  setIndex: 0,
  actualReps: 8,
  actualWeight: 60,
);

const testExercise = Exercise(
  id: 'e1',
  routineDayId: 'd1',
  name: 'Press banca',
  targetMuscle: 'Pecho',
  targetWeight: 60,
  targetReps: 8,
);

void main() {
  late MockWorkoutRepository repository;
  late GetSessionDetail useCase;
  final date = DateTime(2026, 10, 13);

  setUp(() {
    repository = MockWorkoutRepository();
    useCase = GetSessionDetail(repository);
    when(
      () => repository.getSessionSetLogs('s1'),
    ).thenAnswer((_) async => const Right([testSetLog]));
    when(
      () => repository.getSessionExercises('s1'),
    ).thenAnswer((_) async => const Right([testExercise]));
  });

  Future<Either<Failure, SessionDetail>> run() => useCase(
    sessionId: 's1',
    userId: 'u1',
    routineDayId: 'd1',
    sessionDate: date,
  );

  test('junta series, ejercicios y coaching de la sesión', () async {
    when(
      () => repository.getSessionCoaching('s1'),
    ).thenAnswer((_) async => const Right(<CoachingAnalysis>[]));

    final detail = (await run()).getOrElse((_) => throw StateError('left'));

    expect(detail.session.id, 's1');
    expect(detail.session.sessionDate, date);
    expect(detail.session.coachingAnalysis, isEmpty);
    expect(detail.logs, <SetLog>[testSetLog]);
    expect(detail.exercises, <Exercise>[testExercise]);
  });

  test('si falla el coaching sigue mostrando la sesión', () async {
    when(
      () => repository.getSessionCoaching('s1'),
    ).thenAnswer((_) async => const Left(ServerFailure('x')));

    final detail = (await run()).getOrElse((_) => throw StateError('left'));

    expect(detail.session.coachingAnalysis, isNull);
    expect(detail.logs, hasLength(1));
  });

  test('si fallan las series devuelve el fallo', () async {
    when(
      () => repository.getSessionSetLogs('s1'),
    ).thenAnswer((_) async => const Left(NetworkFailure('sin red')));
    when(
      () => repository.getSessionCoaching('s1'),
    ).thenAnswer((_) async => const Right(<CoachingAnalysis>[]));

    expect((await run()).isLeft(), isTrue);
  });
}
