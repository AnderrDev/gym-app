import 'package:flutter/material.dart';
import 'package:gym_flutter/core/utils/calendar_dates.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gym_flutter/core/services/shell_tab_notifier.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/injection_container.dart' show sl;
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_state.dart';
import 'package:gym_flutter/features/workout/presentation/progress/pages/progress_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_fixtures.dart';

class _MockProgressBloc extends Mock implements ProgressBloc {}

class _MockAuthBloc extends Mock implements AuthBloc {}

class _MockGoRouter extends Mock implements GoRouter {}

void main() {
  late _MockProgressBloc bloc;
  late _MockAuthBloc authBloc;
  late _MockGoRouter router;

  const routineA = Routine(id: 'r1', name: 'Push Pull Legs', exerciseCount: 6);
  final monday = DateTime(2026, 5, 11);
  final sunday = monday.add(const Duration(days: 6));

  setUpAll(() async {
    registerFallbackValue(const LoadProgress('user-1'));
    registerFallbackValue(const ProgressInitial());
    // `_WeekRangeLabel` usa `DateFormat(..., 'es')` — necesita los symbols
    // cargados (en producción se inicializa en `main.dart`).
    await initializeDateFormatting('es');
  });

  setUp(() {
    bloc = _MockProgressBloc();
    authBloc = _MockAuthBloc();
    router = _MockGoRouter();

    when(() => authBloc.state).thenReturn(
      const Authenticated(
        User(id: 'user-1', email: 't@t.com', fullName: 'Tester'),
      ),
    );
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.add(any())).thenReturn(null);

    when(() => router.push<bool>(any())).thenAnswer((_) async => null);
    when(
      () => router.push<bool>(any(), extra: any(named: 'extra')),
    ).thenAnswer((_) async => null);
    when(() => router.go(any())).thenReturn(null);
  });

  Widget wrap() {
    return MaterialApp(
      home: InheritedGoRouter(
        goRouter: router,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ProgressBloc>.value(value: bloc),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const ProgressPage(),
        ),
      ),
    );
  }

  testWidgets('volver a la pestaña PROGRESO refresca sin Loading', (
    tester,
  ) async {
    final tabs = ShellTabNotifier();
    sl.registerSingleton<ShellTabNotifier>(tabs);
    addTearDown(() => sl.unregister<ShellTabNotifier>());
    when(() => bloc.state).thenReturn(
      ProgressReady(
        weekStart: monday,
        weekEnd: sunday,
        routines: const [routineA],
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();
    clearInteractions(bloc);

    tabs.value = 0; // HOY: no toca nada
    tabs.value = ShellTabNotifier.progressTab;
    await tester.pump();

    verify(
      () => bloc.add(
        any(
          that: isA<RefreshProgress>().having(
            (e) => e.weekStart,
            'weekStart',
            monday,
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('estado Loading muestra AppSpinner', (tester) async {
    when(() => bloc.state).thenReturn(const ProgressLoading());

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(AppSpinner), findsOneWidget);
  });

  testWidgets('Ready con insights + rutinas pinta ambas secciones', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      ProgressReady(
        weekStart: monday,
        weekEnd: sunday,
        routines: const [routineA],
        insights: testWeeklyInsights,
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('CAMBIO'), findsOneWidget);
    expect(find.text('VOLUMEN'), findsOneWidget);
    expect(find.text('ÚLTIMAS 8 SEMANAS'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(routineA.name), 200);
    expect(find.text('HISTORIAL POR RUTINA'), findsOneWidget);
    expect(find.text(routineA.name), findsOneWidget);
  });

  testWidgets('el selector va a la semana anterior y no pasa de la actual', (
    tester,
  ) async {
    final thisWeek = AppCalendar.startOfWeek(DateTime.now());
    when(() => bloc.state).thenReturn(
      ProgressReady(
        weekStart: thisWeek,
        weekEnd: AppCalendar.addDays(thisWeek, 6),
        routines: const [routineA],
        insights: testWeeklyInsights,
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Esta semana'), findsOneWidget);
    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
    );
    expect(next.onPressed, isNull);

    clearInteractions(bloc);
    await tester.tap(find.byTooltip('Semana anterior'));
    await tester.pump();

    expect(find.text('Semana pasada'), findsOneWidget);
    final event =
        verify(() => bloc.add(captureAny())).captured.single as RefreshProgress;
    expect(event.weekStart, AppCalendar.addDays(thisWeek, -7));
  });

  testWidgets('sin volumen la semana anterior no inventa un +100 %', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      ProgressReady(
        weekStart: monday,
        weekEnd: sunday,
        routines: const [routineA],
        insights: WeeklyInsights(
          weekStart: monday,
          weekEnd: sunday,
          plannedDays: 3,
          completedDays: 1,
          completedSessions: 1,
          adherenceRate: 33,
          totalVolume: 12450,
          previousWeekVolume: 0,
          volumeTrendPercent: 100,
          personalRecords: 2,
        ),
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('12.450 kg'), findsOneWidget);
    expect(find.text('de 3 planificados'), findsOneWidget);
    expect(
      find.text('vs semana anterior, que no tuvo volumen'),
      findsOneWidget,
    );
    expect(find.textContaining('100'), findsNothing);
    expect(find.text('2 récords personales esta semana'), findsOneWidget);
  });

  testWidgets('Ready sin rutinas muestra empty state con CTA IR A RUTINAS', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      ProgressReady(weekStart: monday, weekEnd: sunday, routines: const []),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Sin rutinas asignadas'), findsOneWidget);
    expect(find.text('IR A RUTINAS'), findsOneWidget);
  });

  testWidgets('Failure muestra REINTENTAR y dispara LoadProgress al tap', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const ProgressFailure('oh no'));

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('oh no'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pump();

    verify(
      () => bloc.add(
        any(
          that: isA<LoadProgress>().having((e) => e.userId, 'userId', 'user-1'),
        ),
      ),
    ).called(greaterThanOrEqualTo(1));
  });
}
