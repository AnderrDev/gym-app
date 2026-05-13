import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/domain/usecases/add_exercise_to_day.dart';
import 'package:gym_flutter/features/workout/domain/usecases/add_exercises_to_day.dart';
import 'package:gym_flutter/features/workout/domain/usecases/assign_routine.dart';
import 'package:gym_flutter/features/workout/domain/usecases/delete_routine.dart'
    as uc_del_routine;
import 'package:gym_flutter/features/workout/domain/usecases/delete_routine_day.dart'
    as uc_del_day;
import 'package:gym_flutter/features/workout/domain/usecases/get_all_routines.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_exercises_catalog.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_routine_by_id.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_weekly_plan.dart';
import 'package:gym_flutter/features/workout/domain/usecases/remove_exercise_from_day.dart'
    as uc_remove_ex;
import 'package:gym_flutter/features/workout/domain/usecases/reorder_exercises.dart'
    as uc_reorder;
import 'package:gym_flutter/features/workout/domain/usecases/save_routine.dart'
    as uc_save_routine;
import 'package:gym_flutter/features/workout/domain/usecases/save_routine_day.dart'
    as uc_save_day;
import 'package:gym_flutter/features/workout/domain/usecases/update_exercise_target.dart'
    as uc_update_target;
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';

class _MockAssignRoutine extends Mock implements AssignRoutine {}

class _MockGetAllRoutines extends Mock implements GetAllRoutines {}

class _MockGetWeeklyPlan extends Mock implements GetWeeklyPlan {}

class _MockGetRoutineById extends Mock implements GetRoutineById {}

class _MockSaveRoutine extends Mock implements uc_save_routine.SaveRoutine {}

class _MockDeleteRoutine extends Mock implements uc_del_routine.DeleteRoutine {}

class _MockSaveRoutineDay extends Mock implements uc_save_day.SaveRoutineDay {}

class _MockDeleteRoutineDay extends Mock
    implements uc_del_day.DeleteRoutineDay {}

class _MockAddExerciseToDay extends Mock implements AddExerciseToDay {}

class _MockAddExercisesToDay extends Mock implements AddExercisesToDay {}

class _MockRemoveExerciseFromDay extends Mock
    implements uc_remove_ex.RemoveExerciseFromDay {}

class _MockReorderExercises extends Mock
    implements uc_reorder.ReorderExercises {}

class _MockUpdateExerciseTarget extends Mock
    implements uc_update_target.UpdateExerciseTarget {}

class _MockGetExercisesCatalog extends Mock implements GetExercisesCatalog {}

void main() {
  late _MockAssignRoutine assignRoutine;
  late _MockGetAllRoutines getAllRoutines;
  late _MockGetWeeklyPlan getWeeklyPlan;
  late _MockGetRoutineById getRoutineById;
  late _MockSaveRoutine saveRoutine;
  late _MockDeleteRoutine deleteRoutine;
  late _MockSaveRoutineDay saveRoutineDay;
  late _MockDeleteRoutineDay deleteRoutineDay;
  late _MockAddExerciseToDay addExerciseToDay;
  late _MockAddExercisesToDay addExercisesToDay;
  late _MockRemoveExerciseFromDay removeExerciseFromDay;
  late _MockReorderExercises reorderExercises;
  late _MockUpdateExerciseTarget updateExerciseTarget;
  late _MockGetExercisesCatalog getExercisesCatalog;

  const tRoutine = Routine(id: 'r1', name: 'Push/Pull', exerciseCount: 6);

  setUpAll(() {
    registerFallbackValue(tRoutine);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      const RoutineDay(
        id: 'd1',
        routineId: 'r1',
        dayOfWeek: 1,
        name: 'Día 1',
        exercises: [],
      ),
    );
    registerFallbackValue(<AddExerciseToDayPayload>[]);
  });

  setUp(() {
    assignRoutine = _MockAssignRoutine();
    getAllRoutines = _MockGetAllRoutines();
    getWeeklyPlan = _MockGetWeeklyPlan();
    getRoutineById = _MockGetRoutineById();
    saveRoutine = _MockSaveRoutine();
    deleteRoutine = _MockDeleteRoutine();
    saveRoutineDay = _MockSaveRoutineDay();
    deleteRoutineDay = _MockDeleteRoutineDay();
    addExerciseToDay = _MockAddExerciseToDay();
    addExercisesToDay = _MockAddExercisesToDay();
    removeExerciseFromDay = _MockRemoveExerciseFromDay();
    reorderExercises = _MockReorderExercises();
    updateExerciseTarget = _MockUpdateExerciseTarget();
    getExercisesCatalog = _MockGetExercisesCatalog();
  });

  RoutineManagementBloc buildBloc() => RoutineManagementBloc(
    assignRoutine: assignRoutine,
    getAllRoutines: getAllRoutines,
    getWeeklyPlan: getWeeklyPlan,
    getRoutineById: getRoutineById,
    saveRoutine: saveRoutine,
    deleteRoutine: deleteRoutine,
    saveRoutineDay: saveRoutineDay,
    deleteRoutineDay: deleteRoutineDay,
    addExerciseToDay: addExerciseToDay,
    addExercisesToDay: addExercisesToDay,
    removeExerciseFromDay: removeExerciseFromDay,
    reorderExercises: reorderExercises,
    updateExerciseTarget: updateExerciseTarget,
    getExercisesCatalog: getExercisesCatalog,
  );

  group('LoadAllRoutines', () {
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'éxito → status ready con la lista',
      build: () {
        when(
          () => getAllRoutines(),
        ).thenAnswer((_) async => const Right([tRoutine]));
        return buildBloc();
      },
      act: (b) => b.add(const LoadAllRoutines()),
      expect: () => [
        isA<RoutineManagementState>().having(
          (s) => s.status,
          'status',
          RoutineManagementStatus.loading,
        ),
        isA<RoutineManagementState>()
            .having((s) => s.status, 'status', RoutineManagementStatus.ready)
            .having((s) => s.routines, 'routines', [tRoutine]),
      ],
    );

    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'failure → status failure con errorMessage',
      build: () {
        when(
          () => getAllRoutines(),
        ).thenAnswer((_) async => const Left(ServerFailure('boom')));
        return buildBloc();
      },
      act: (b) => b.add(const LoadAllRoutines()),
      expect: () => [
        isA<RoutineManagementState>().having(
          (s) => s.status,
          'status',
          RoutineManagementStatus.loading,
        ),
        isA<RoutineManagementState>()
            .having((s) => s.status, 'status', RoutineManagementStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'boom'),
      ],
    );
  });

  group('AssignRoutineToUser', () {
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'éxito → submissionStatus.success con feedbackMessage',
      build: () {
        when(
          () => assignRoutine(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (b) =>
          b.add(const AssignRoutineToUser(userId: 'u1', routineId: 'r1')),
      expect: () => [
        isA<RoutineManagementState>().having(
          (s) => s.submissionStatus,
          'submissionStatus',
          RoutineManagementSubmissionStatus.submitting,
        ),
        isA<RoutineManagementState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              RoutineManagementSubmissionStatus.success,
            )
            .having(
              (s) => s.feedbackMessage,
              'feedbackMessage',
              'Rutina activada correctamente',
            ),
      ],
    );
  });

  group('SaveRoutine', () {
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'éxito → editingRoutine guardada con id real',
      build: () {
        when(
          () => saveRoutine(any()),
        ).thenAnswer((_) async => const Right(tRoutine));
        return buildBloc();
      },
      act: (b) => b.add(const SaveRoutine(userId: 'u1', name: 'Push/Pull')),
      verify: (b) {
        expect(
          b.state.submissionStatus,
          RoutineManagementSubmissionStatus.success,
        );
        expect(b.state.editingRoutine, tRoutine);
      },
    );
  });

  group('SaveDay', () {
    const tDay = RoutineDay(
      id: 'd1',
      routineId: 'r1',
      dayOfWeek: 1,
      name: 'Día 1',
    );
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'éxito → editingDays incluye el día guardado',
      build: () {
        when(
          () => saveRoutineDay(any()),
        ).thenAnswer((_) async => const Right(tDay));
        return buildBloc();
      },
      act: (b) => b.add(
        const SaveDay(
          userId: 'u1',
          routineId: 'r1',
          day: RoutineDay(
            id: '',
            routineId: 'r1',
            dayOfWeek: 1,
            name: 'Día 1',
          ),
        ),
      ),
      verify: (b) {
        expect(
          b.state.submissionStatus,
          RoutineManagementSubmissionStatus.success,
        );
        expect(b.state.editingDays.any((d) => d.id == 'd1'), isTrue);
      },
    );
  });

  group('LoadExerciseCatalog', () {
    const tItems = [
      ExerciseCatalogItem(id: 'e1', name: 'Press', muscleGroup: 'Pecho'),
    ];
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'éxito → catalogStatus.ready con el listado',
      build: () {
        when(
          () => getExercisesCatalog(
            muscleGroup: any(named: 'muscleGroup'),
            search: any(named: 'search'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(tItems));
        return buildBloc();
      },
      act: (b) => b.add(const LoadExerciseCatalog()),
      verify: (b) {
        expect(b.state.catalogStatus, ExerciseCatalogStatus.ready);
        expect(b.state.exerciseCatalog, tItems);
      },
    );
  });

  group('AddExerciseToDayEvent', () {
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'éxito → recarga días e indica isDirty',
      build: () {
        when(
          () => addExerciseToDay(
            any(),
            any(),
            targetSets: any(named: 'targetSets'),
            targetReps: any(named: 'targetReps'),
            targetWeight: any(named: 'targetWeight'),
            restSeconds: any(named: 'restSeconds'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => getWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right(<RoutineDay>[]));
        return buildBloc();
      },
      act: (b) => b.add(
        const AddExerciseToDayEvent(
          userId: 'u1',
          routineId: 'r1',
          dayId: 'd1',
          exerciseId: 'e1',
        ),
      ),
      verify: (b) {
        expect(
          b.state.submissionStatus,
          RoutineManagementSubmissionStatus.success,
        );
        expect(b.state.isDirty, isTrue);
      },
    );
  });

  group('AddExercisesToDayEvent', () {
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'éxito → emite isDirty y feedback',
      build: () {
        when(
          () => addExercisesToDay(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => getWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right(<RoutineDay>[]));
        return buildBloc();
      },
      act: (b) => b.add(
        const AddExercisesToDayEvent(
          userId: 'u1',
          routineId: 'r1',
          dayId: 'd1',
          items: [AddExerciseToDayPayload(exerciseId: 'e1')],
        ),
      ),
      verify: (b) {
        expect(
          b.state.submissionStatus,
          RoutineManagementSubmissionStatus.success,
        );
        expect(b.state.isDirty, isTrue);
      },
    );
  });

  group('RemoveExerciseFromDayEvent', () {
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'éxito → success y isDirty',
      build: () {
        when(
          () => removeExerciseFromDay(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => getWeeklyPlan(
            userId: any(named: 'userId'),
            routineId: any(named: 'routineId'),
            weekStart: any(named: 'weekStart'),
          ),
        ).thenAnswer((_) async => const Right(<RoutineDay>[]));
        return buildBloc();
      },
      act: (b) => b.add(
        const RemoveExerciseFromDayEvent(
          userId: 'u1',
          routineId: 'r1',
          dayId: 'd1',
          exerciseId: 'e1',
        ),
      ),
      verify: (b) {
        expect(
          b.state.submissionStatus,
          RoutineManagementSubmissionStatus.success,
        );
        expect(b.state.isDirty, isTrue);
      },
    );
  });

  group('MarkRoutineDirty / ClearEditingContext', () {
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'MarkRoutineDirty activa isDirty',
      build: buildBloc,
      act: (b) => b.add(const MarkRoutineDirty()),
      verify: (b) => expect(b.state.isDirty, isTrue),
    );

    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'ClearEditingContext limpia editingRoutine, editingDays e isDirty',
      build: () => buildBloc()
        ..emit(
          const RoutineManagementState(
            editingRoutine: tRoutine,
            editingDays: [
              RoutineDay(
                id: 'd1',
                routineId: 'r1',
                dayOfWeek: 1,
                name: 'Día 1',
              ),
            ],
            isDirty: true,
          ),
        ),
      act: (b) => b.add(const ClearEditingContext()),
      verify: (b) {
        expect(b.state.editingRoutine, isNull);
        expect(b.state.editingDays, isEmpty);
        expect(b.state.isDirty, isFalse);
      },
    );
  });

  group('AcknowledgeFeedback', () {
    blocTest<RoutineManagementBloc, RoutineManagementState>(
      'limpia feedback y vuelve a idle',
      build: () => buildBloc()
        ..emit(
          const RoutineManagementState(
            submissionStatus: RoutineManagementSubmissionStatus.success,
            feedbackMessage: 'OK',
          ),
        ),
      act: (b) => b.add(const AcknowledgeFeedback()),
      verify: (b) {
        expect(
          b.state.submissionStatus,
          RoutineManagementSubmissionStatus.idle,
        );
        expect(b.state.feedbackMessage, isNull);
      },
    );
  });
}
