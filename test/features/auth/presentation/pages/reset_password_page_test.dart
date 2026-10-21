import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/routes/app_routes.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/features/auth/domain/usecases/update_password.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/auth/presentation/pages/reset_password_page.dart';

import '../../../../helpers/test_fixtures.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

class _MockUpdatePassword extends Mock implements UpdatePassword {}

void main() {
  late _MockAuthBloc auth;
  late _MockUpdatePassword updatePassword;

  setUp(() {
    auth = _MockAuthBloc();
    updatePassword = _MockUpdatePassword();
    when(() => auth.state).thenReturn(const Authenticated(testUser));
    when(() => auth.stream).thenAnswer((_) => const Stream.empty());
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.resetPassword,
      routes: [
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (_, _) => ResetPasswordPage(updatePassword: updatePassword),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (_, _) => const Text('HOY'),
        ),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const Text('LOGIN')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // AppFormField pinta la etiqueta fuera del TextField: se ubican por orden.
  Finder field(String label) => switch (label) {
    'Contraseña nueva' => find.byType(TextField).at(0),
    _ => find.byType(TextField).at(1),
  };

  testWidgets('no envía si las contraseñas no coinciden', (tester) async {
    await pumpPage(tester);
    await tester.enterText(field('Contraseña nueva'), 'NuevaClave123');
    await tester.enterText(field('Repite la contraseña'), 'OtraClave123');
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    verifyNever(() => updatePassword(any()));
  });

  testWidgets('guarda la contraseña y lleva a HOY', (tester) async {
    when(
      () => updatePassword('NuevaClave123'),
    ).thenAnswer((_) async => const Right(null));
    await pumpPage(tester);
    await tester.enterText(field('Contraseña nueva'), 'NuevaClave123');
    await tester.enterText(field('Repite la contraseña'), 'NuevaClave123');
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    verify(() => updatePassword('NuevaClave123')).called(1);
    expect(find.text('HOY'), findsOneWidget);
  });

  testWidgets('muestra el error del servidor y se queda en la pantalla', (
    tester,
  ) async {
    when(() => updatePassword(any())).thenAnswer(
      (_) async => const Left(
        AuthFailure('La nueva contraseña debe ser distinta de la actual.'),
      ),
    );
    await pumpPage(tester);
    await tester.enterText(field('Contraseña nueva'), 'NuevaClave123');
    await tester.enterText(field('Repite la contraseña'), 'NuevaClave123');
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('La nueva contraseña debe ser distinta de la actual.'),
      findsOneWidget,
    );
    expect(find.text('HOY'), findsNothing);
  });

  testWidgets('sin sesión explica que el enlace no sirve', (tester) async {
    when(() => auth.state).thenReturn(Unauthenticated());
    await pumpPage(tester);

    expect(find.textContaining('no es válido o ya caducó'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(
      find.textContaining(RegExp('iniciar sesión', caseSensitive: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
