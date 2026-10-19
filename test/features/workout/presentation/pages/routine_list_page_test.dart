import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/pages/routine_list_page.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/routine_list_skeleton.dart';
import 'package:mocktail/mocktail.dart';

class MockRoutineManagementBloc extends Mock implements RoutineManagementBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockRoutineManagementBloc bloc;
  late MockAuthBloc mockAuthBloc;
  late MockGoRouter mockGoRouter;

  const tRoutines = [
    Routine(id: 'r1', creatorId: 'user123', name: 'Push', exerciseCount: 3),
    Routine(
      id: 'r2',
      creatorId: 'other',
      name: 'Community',
      exerciseCount: 2,
      isPublic: true,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const LoadAllRoutines());
    registerFallbackValue(const RoutineManagementState());
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

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<RoutineManagementBloc>.value(value: bloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const RoutineListPage(),
        ),
      ),
    );
  }

  testWidgets('initState dispara LoadAllRoutines', (tester) async {
    when(() => bloc.state).thenReturn(const RoutineManagementState());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    verify(() => bloc.add(any(that: isA<LoadAllRoutines>()))).called(1);
  });

  testWidgets('cargando sin rutinas → RoutineListSkeleton', (tester) async {
    when(() => bloc.state).thenReturn(
      const RoutineManagementState(status: RoutineManagementStatus.loading),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(RoutineListSkeleton), findsOneWidget);
  });

  testWidgets('estado ready muestra cards de rutinas', (tester) async {
    when(() => bloc.state).thenReturn(
      const RoutineManagementState(
        status: RoutineManagementStatus.ready,
        routines: tRoutines,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('PUSH'), findsOneWidget);
    expect(find.text('COMMUNITY'), findsOneWidget);
  });

  testWidgets('estado failure muestra mensaje', (tester) async {
    when(() => bloc.state).thenReturn(
      const RoutineManagementState(
        status: RoutineManagementStatus.failure,
        errorMessage: 'oops',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('oops'), findsOneWidget);
  });

  testWidgets('tap en ACTIVAR dispara AssignRoutineToUser', (tester) async {
    when(() => bloc.state).thenReturn(
      const RoutineManagementState(
        status: RoutineManagementStatus.ready,
        routines: tRoutines,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('ACTIVAR').first);
    await tester.pump();

    verify(() => bloc.add(any(that: isA<AssignRoutineToUser>()))).called(1);
  });
}
