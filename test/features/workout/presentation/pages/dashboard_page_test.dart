import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_state.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/pages/dashboard_page.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_weekly_view.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardBloc extends Mock implements DashboardBloc {}

class MockActiveSessionWatcherBloc extends Mock
    implements ActiveSessionWatcherBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockDashboardBloc mockDashboardBloc;
  late MockActiveSessionWatcherBloc mockWatcherBloc;
  late MockAuthBloc mockAuthBloc;
  late MockGoRouter mockGoRouter;

  setUpAll(() {
    registerFallbackValue(const LoadAssignedRoutines('user123'));
    registerFallbackValue(const CheckActiveSession('user123'));
    registerFallbackValue(const DashboardState());
    registerFallbackValue(const ActiveSessionWatcherState());
  });

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockWatcherBloc = MockActiveSessionWatcherBloc();
    mockAuthBloc = MockAuthBloc();
    mockGoRouter = MockGoRouter();

    when(() => mockAuthBloc.state).thenReturn(
      const Authenticated(
        User(id: 'user123', email: 'test@test.com', fullName: 'Tester'),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(
      () => mockWatcherBloc.state,
    ).thenReturn(const ActiveSessionWatcherState());
    when(() => mockWatcherBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockGoRouter.push<bool>(any())).thenAnswer((_) async => null);
    when(
      () => mockGoRouter.push<bool>(any(), extra: any(named: 'extra')),
    ).thenAnswer((_) async => null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
            BlocProvider<ActiveSessionWatcherBloc>.value(
              value: mockWatcherBloc,
            ),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const DashboardPage(),
        ),
      ),
    );
  }

  testWidgets('estado vacío muestra DashboardEmptyState', (tester) async {
    when(
      () => mockDashboardBloc.state,
    ).thenReturn(const DashboardState(status: DashboardStatus.ready));
    when(
      () => mockDashboardBloc.stream,
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Sin Rutina Activa'), findsOneWidget);
  });

  testWidgets('plan semanal listo renderiza DashboardWeeklyView', (
    tester,
  ) async {
    final monday = DateTime(2026, 5, 4);
    const routine = Routine(id: 'r1', name: 'MY ROUTINE', exerciseCount: 3);
    final days = [
      const RoutineDay(
        id: 'd1',
        routineId: 'r1',
        name: 'PUSH DAY',
        dayOfWeek: 1,
        exercises: [],
      ),
    ];
    when(() => mockDashboardBloc.state).thenReturn(
      DashboardState(
        status: DashboardStatus.ready,
        routines: const [routine],
        selectedRoutine: routine,
        weeklyDays: days,
        weekStart: monday,
      ),
    );
    when(
      () => mockDashboardBloc.stream,
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump();

    expect(find.byType(DashboardWeeklyView), findsOneWidget);
  });

  testWidgets('toca el icono de lista → push a /routine-list', (tester) async {
    when(
      () => mockDashboardBloc.state,
    ).thenReturn(const DashboardState(status: DashboardStatus.ready));
    when(
      () => mockDashboardBloc.stream,
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.list_alt));
    verify(() => mockGoRouter.push<bool>('/routine-list')).called(1);
  });

  testWidgets('banner de sesión activa aparece cuando watcher emite detected', (
    tester,
  ) async {
    final session = ActiveSessionInfo(
      sessionId: 's1',
      userId: 'user123',
      routineDayId: 'd1',
      routineDayName: 'Active Day',
      sessionDate: DateTime.now(),
    );

    when(
      () => mockDashboardBloc.state,
    ).thenReturn(const DashboardState(status: DashboardStatus.ready));
    when(
      () => mockDashboardBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockWatcherBloc.state).thenReturn(
      ActiveSessionWatcherState(
        status: ActiveSessionWatcherStatus.detected,
        session: session,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.textContaining('Active Day'), findsOneWidget);
    expect(find.text('Retomar'), findsOneWidget);
  });
}
