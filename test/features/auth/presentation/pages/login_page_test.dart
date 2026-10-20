import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/auth/presentation/pages/login_page.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late _MockAuthBloc auth;

  setUpAll(() {
    registerFallbackValue(const SignInRequested('user@gym.com', 'password123'));
  });

  setUp(() {
    dotenv.testLoad(fileInput: 'DEV_LOGIN_EMAIL=\nDEV_LOGIN_PASSWORD=\n');
    auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(Unauthenticated());
    when(() => auth.stream).thenAnswer((_) => const Stream.empty());
  });

  Future<void> pumpLogin(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<AuthBloc>.value(
          value: auth,
          child: const LoginPage(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('mientras se comprueba la sesión no se ve el formulario', (
    tester,
  ) async {
    when(() => auth.state).thenReturn(AuthLoading());
    await pumpLogin(tester, const Size(400, 800));
    expect(find.byType(TextField), findsNothing);
    expect(find.bySemanticsLabel('Comprobando tu sesión'), findsOneWidget);
  });

  testWidgets('el formulario conserva un ancho legible en escritorio', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(1440, 900));
    expect(
      tester.getSize(find.byType(TextField).first).width,
      lessThanOrEqualTo(420),
    );
  });

  testWidgets('Enter no vuelve a iniciar sesión mientras ya está enviando', (
    tester,
  ) async {
    when(() => auth.state).thenReturn(AuthSubmitting());
    await pumpLogin(tester, const Size(1200, 900));
    await tester.enterText(find.byType(TextField).first, 'user@gym.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    verifyNever(() => auth.add(any(that: isA<SignInRequested>())));
  });

  testWidgets('el login cabe en móvil y permite enviar con Enter', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField).first, ' user@gym.com ');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    verify(
      () => auth.add(const SignInRequested('user@gym.com', 'password123')),
    ).called(1);
  });

  testWidgets('Tab avanza desde el correo a la contraseña', (tester) async {
    await pumpLogin(tester, const Size(1200, 900));
    final fields = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();
    expect(fields.first.focusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(fields.last.focusNode.hasFocus, isTrue);
  });

  testWidgets('un error de acceso conserva los valores y permite reintentar', (
    tester,
  ) async {
    final states = StreamController<AuthState>.broadcast();
    addTearDown(states.close);
    AuthState current = Unauthenticated();
    when(() => auth.state).thenAnswer((_) => current);
    when(() => auth.stream).thenAnswer((_) => states.stream);
    await pumpLogin(tester, const Size(1200, 900));
    await tester.enterText(find.byType(TextField).first, 'user@gym.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    current = AuthSubmitting();
    states.add(current);
    await tester.pump();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    current = const AuthError('No pudimos iniciar sesión. Inténtalo de nuevo.');
    states.add(current);
    await tester.pump();
    expect(
      find.text('No pudimos iniciar sesión. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.first.controller!.text, 'user@gym.com');
    expect(fields.last.controller!.text, 'password123');
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    verify(
      () => auth.add(const SignInRequested('user@gym.com', 'password123')),
    ).called(2);
  });
}
