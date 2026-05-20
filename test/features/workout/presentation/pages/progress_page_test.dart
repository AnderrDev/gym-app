import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
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

    expect(find.text('ESTA SEMANA'), findsOneWidget);
    expect(find.text('TUS RUTINAS'), findsOneWidget);
    expect(find.text(routineA.name), findsOneWidget);
    // Una métrica de muestra para confirmar que se rindió la grid.
    expect(find.text('VOLUMEN'), findsOneWidget);
  });

  testWidgets('Ready sin rutinas muestra empty state con CTA IR A RUTINAS', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      ProgressReady(
        weekStart: monday,
        weekEnd: sunday,
        routines: const [],
      ),
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
