import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/sync/presentation/sync_status_bloc.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_sign_out_button.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockSyncStatusBloc extends Mock implements SyncStatusBloc {}

void main() {
  late _MockAuthBloc auth;

  setUp(() {
    auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(Unauthenticated());
  });

  Future<void> pump(WidgetTester tester, {SyncStatusBloc? sync}) async {
    Widget child = const Scaffold(body: ProfileSignOutButton());
    if (sync != null) {
      child = BlocProvider<SyncStatusBloc>.value(value: sync, child: child);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: BlocProvider<AuthBloc>.value(value: auth, child: child),
      ),
    );
    await tester.tap(find.byType(ProfileSignOutButton));
    await tester.pumpAndSettle();
  }

  testWidgets('avisa de cambios sin sincronizar antes de cerrar sesión', (
    tester,
  ) async {
    final sync = _MockSyncStatusBloc();
    when(() => sync.state).thenReturn(const SyncStatusState(pending: 2));
    when(() => sync.stream).thenAnswer((_) => const Stream.empty());
    await pump(tester, sync: sync);
    expect(find.textContaining('2 cambios sin sincronizar'), findsOneWidget);
  });

  testWidgets('sin pendientes muestra el mensaje habitual', (tester) async {
    await pump(tester);
    expect(find.textContaining('sin sincronizar'), findsNothing);
  });
}
