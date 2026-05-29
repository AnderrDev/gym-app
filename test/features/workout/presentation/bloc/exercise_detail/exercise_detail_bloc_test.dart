import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_detail.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_exercise_detail.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_detail/exercise_detail_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_detail/exercise_detail_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_detail/exercise_detail_state.dart';

class _MockGetExerciseDetail extends Mock implements GetExerciseDetail {}

void main() {
  late _MockGetExerciseDetail getExerciseDetail;

  const tDetail = ExerciseDetail(
    id: 'ex-1',
    name: 'Press de Banca',
    muscleGroup: 'Pecho',
    instructions: 'Acuéstate en banco plano.',
  );

  setUp(() {
    getExerciseDetail = _MockGetExerciseDetail();
  });

  ExerciseDetailBloc buildBloc() =>
      ExerciseDetailBloc(getExerciseDetail: getExerciseDetail);

  group('LoadExerciseDetail', () {
    blocTest<ExerciseDetailBloc, ExerciseDetailState>(
      'éxito → status ready con detail',
      build: () {
        when(() => getExerciseDetail(any()))
            .thenAnswer((_) async => const Right(tDetail));
        return buildBloc();
      },
      act: (b) => b.add(const LoadExerciseDetail('ex-1')),
      expect: () => [
        isA<ExerciseDetailState>().having(
          (s) => s.status,
          'status',
          ExerciseDetailStatus.loading,
        ),
        isA<ExerciseDetailState>()
            .having((s) => s.status, 'status', ExerciseDetailStatus.ready)
            .having((s) => s.detail, 'detail', tDetail),
      ],
    );

    blocTest<ExerciseDetailBloc, ExerciseDetailState>(
      'failure → status failure con errorMessage',
      build: () {
        when(() => getExerciseDetail(any()))
            .thenAnswer((_) async => const Left(NotFoundFailure('no existe')));
        return buildBloc();
      },
      act: (b) => b.add(const LoadExerciseDetail('ex-1')),
      verify: (b) {
        expect(b.state.status, ExerciseDetailStatus.failure);
        expect(b.state.errorMessage, 'no existe');
      },
    );
  });
}
