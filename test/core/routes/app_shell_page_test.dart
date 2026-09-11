import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_flutter/core/routes/app_shell_page.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_state.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/routine_management/routine_management_state.dart';
import 'package:mocktail/mocktail.dart';

class MockActiveSessionWatcherBloc extends Mock
    implements ActiveSessionWatcherBloc {}

class MockRoutineManagementBloc extends Mock implements RoutineManagementBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockActiveSessionWatcherBloc mockWatcherBloc;
  late MockRoutineManagementBloc mockRoutineMgmtBloc;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(const CheckActiveSession('user123'));
    registerFallbackValue(const ClearActiveSession());
    registerFallbackValue(const ActiveSessionWatcherState());
    registerFallbackValue(const LoadAllRoutines());
    registerFallbackValue(const RoutineManagementState());
  });

  setUp(() {
    mockWatcherBloc = MockActiveSessionWatcherBloc();
    mockRoutineMgmtBloc = MockRoutineManagementBloc();
    mockAuthBloc = MockAuthBloc();

    when(
      () => mockWatcherBloc.state,
    ).thenReturn(const ActiveSessionWatcherState());
    when(() => mockWatcherBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockWatcherBloc.close()).thenAnswer((_) async {});

    when(
      () => mockRoutineMgmtBloc.state,
    ).thenReturn(const RoutineManagementState());
    when(
      () => mockRoutineMgmtBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockRoutineMgmtBloc.close()).thenAnswer((_) async {});

    when(() => mockAuthBloc.state).thenReturn(
      const Authenticated(
        User(id: 'user123', email: 'test@test.com', fullName: 'Tester'),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    // El shell hace `sl<ActiveSessionWatcherBloc>()` para crear el bloc en
    // `BlocProvider.create`. Registramos el mock como factory para que cada
    // pump test obtenga el mismo singleton mockeado.
    final sl = GetIt.instance;
    if (sl.isRegistered<ActiveSessionWatcherBloc>()) {
      sl.unregister<ActiveSessionWatcherBloc>();
    }
    sl.registerFactory<ActiveSessionWatcherBloc>(() => mockWatcherBloc);
  });

  tearDown(() {
    final sl = GetIt.instance;
    if (sl.isRegistered<ActiveSessionWatcherBloc>()) {
      sl.unregister<ActiveSessionWatcherBloc>();
    }
  });

  /// Construye un router de prueba con un shell minimal. Cada branch es una
  /// pantalla stub identificable por un texto único — así verificamos el
  /// tab-switch sin depender de las páginas reales (DashboardBloc, etc.).
  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: '/dashboard',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShellPage(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  builder: (context, state) =>
                      const Scaffold(body: Text('STUB_DASHBOARD')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/routines',
                  builder: (context, state) =>
                      BlocProvider<RoutineManagementBloc>.value(
                        value: mockRoutineMgmtBloc,
                        child: const Scaffold(body: Text('STUB_ROUTINES')),
                      ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/progress',
                  builder: (context, state) =>
                      const Scaffold(body: Text('STUB_PROGRESS')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) =>
                      const Scaffold(body: Text('STUB_PROFILE')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget createWidgetUnderTest() {
    return MaterialApp.router(
      routerConfig: buildTestRouter(),
      builder: (context, child) {
        return BlocProvider<AuthBloc>.value(value: mockAuthBloc, child: child!);
      },
    );
  }

  testWidgets('renderiza 4 destinations con sus labels', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('HOY'), findsOneWidget);
    expect(find.text('RUTINAS'), findsOneWidget);
    expect(find.text('PROGRESO'), findsOneWidget);
    expect(find.text('PERFIL'), findsOneWidget);
  });

  testWidgets('arranca en /dashboard (branch 0)', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('STUB_DASHBOARD'), findsOneWidget);
    expect(find.text('STUB_ROUTINES'), findsNothing);
  });

  testWidgets('tap en RUTINAS cambia al branch de rutinas', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('RUTINAS'));
    await tester.pumpAndSettle();

    expect(find.text('STUB_ROUTINES'), findsOneWidget);
    // `IndexedStack` mantiene los branches montados — ambos están en el
    // árbol pero solo el activo es visible. Verificamos el visible:
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
  });

  testWidgets('tap en PERFIL muestra el branch de perfil', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('PERFIL'));
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 3);
  });

  testWidgets(
    'banner de sesión activa aparece cuando el watcher emite hasActiveSession',
    (tester) async {
      final session = ActiveSessionInfo(
        sessionId: 's1',
        userId: 'user123',
        routineDayId: 'd1',
        routineDayName: 'Active Day',
        sessionDate: DateTime.now(),
      );
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
    },
  );

  testWidgets('banner desaparece cuando el watcher no tiene sesión activa', (
    tester,
  ) async {
    when(
      () => mockWatcherBloc.state,
    ).thenReturn(const ActiveSessionWatcherState());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Retomar'), findsNothing);
  });

  testWidgets(
    'initState dispara CheckActiveSession con el userId autenticado',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      verify(
        () => mockWatcherBloc.add(any(that: isA<CheckActiveSession>())),
      ).called(1);
    },
  );
}
