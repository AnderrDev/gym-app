import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/pages/routine_editor_page.dart';
import 'package:mocktail/mocktail.dart';

class MockRoutineManagementBloc extends Mock implements RoutineManagementBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockRoutineManagementBloc bloc;
  late MockAuthBloc mockAuthBloc;
  late MockGoRouter mockGoRouter;

  setUpAll(() {
    registerFallbackValue(
      const LoadRoutineForEditing(userId: 'u1', routineId: 'r1'),
    );
    registerFallbackValue(const SaveRoutine(userId: 'u1', name: 'Test'));
    registerFallbackValue(
      const SaveDay(
        userId: 'u1',
        routineId: 'r1',
        day: RoutineDay(
          id: '',
          routineId: 'r1',
          name: '',
          dayOfWeek: 1,
          exercises: [],
        ),
      ),
    );
  });

  setUp(() {
    bloc = MockRoutineManagementBloc();
    mockAuthBloc = MockAuthBloc();
    mockGoRouter = MockGoRouter();
    when(() => mockAuthBloc.state).thenReturn(
      const Authenticated(
        User(id: 'user123', email: 'test@test.com', fullName: 'Tester'),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest({String? routineId}) {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<RoutineManagementBloc>.value(value: bloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: RoutineEditorPage(routineId: routineId),
        ),
      ),
    );
  }

  testWidgets('initState con routineId dispara LoadRoutineForEditing', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const RoutineManagementState());

    await tester.pumpWidget(createWidgetUnderTest(routineId: 'r1'));
    await tester.pump();

    verify(() => bloc.add(any(that: isA<LoadRoutineForEditing>()))).called(1);
  });

  testWidgets('estado ready con editingRoutine pre-popula nombre', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      const RoutineManagementState(
        status: RoutineManagementStatus.ready,
        editingRoutine: Routine(id: 'r1', name: 'My Routine', exerciseCount: 3),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest(routineId: 'r1'));
    await tester.pump();

    expect(find.text('MY ROUTINE'), findsWidgets);
  });

  testWidgets('GUARDAR dispara SaveRoutine', (tester) async {
    when(() => bloc.state).thenReturn(
      const RoutineManagementState(status: RoutineManagementStatus.ready),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('GUARDAR'));
    await tester.pump();

    verify(() => bloc.add(any(that: isA<SaveRoutine>()))).called(1);
  });

  testWidgets('AÑADIR DÍA dispara SaveDay con día nuevo', (tester) async {
    when(() => bloc.state).thenReturn(
      const RoutineManagementState(status: RoutineManagementStatus.ready),
    );

    await tester.pumpWidget(createWidgetUnderTest(routineId: 'r1'));
    await tester.pump();

    await tester.tap(find.text('AÑADIR DÍA'));
    await tester.pump();

    verify(() => bloc.add(any(that: isA<SaveDay>()))).called(1);
  });
}
