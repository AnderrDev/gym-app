import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/ui/feedback/barbell_loader.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/profile/presentation/pages/profile_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late _MockAuthBloc mockAuthBloc;

  const tUser = User(
    id: 'user-123',
    email: 'ander@example.com',
    fullName: 'Ander Cifuentes',
  );

  setUpAll(() {
    registerFallbackValue(SignOutRequested());
  });

  setUp(() {
    mockAuthBloc = _MockAuthBloc();
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget pumpProfile() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const ProfilePage(),
      ),
    );
  }

  testWidgets(
    'renderiza datos del usuario, preferencias y CTA de cerrar sesión cuando '
    'Authenticated',
    (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const Authenticated(tUser));

      // Viewport más alto para que el `ListView` materialice todo el
      // contenido (sign-out incluido) sin necesidad de scroll.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(pumpProfile());
      await tester.pump();

      // Tanto el nombre como el email aparecen dos veces: una en el
      // avatar-header y otra como `value` de su `_InfoRow` en CUENTA.
      expect(find.text('Ander Cifuentes'), findsNWidgets(2));
      expect(find.text('ander@example.com'), findsNWidgets(2));

      // Sección CUENTA
      expect(find.text('CUENTA'), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);

      // Sección PREFERENCIAS (con valores)
      expect(find.text('PREFERENCIAS'), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Unidades'), findsOneWidget);
      expect(find.text('Kilogramos (kg)'), findsOneWidget);

      // Sólo las rows de preferencias siguen con el tag "PRÓXIMAMENTE".
      // La row de "Nombre" ahora es editable (tap → sheet) y muestra chevron.
      expect(find.text('PRÓXIMAMENTE'), findsNWidgets(2));
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // CTA sign-out
      expect(find.text('CERRAR SESIÓN'), findsOneWidget);
    },
  );

  testWidgets('muestra BarbellLoader cuando AuthLoading', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(AuthLoading());

    await tester.pumpWidget(pumpProfile());
    await tester.pump();

    expect(find.byType(BarbellLoader), findsOneWidget);
    // Sin contenido del perfil.
    expect(find.text('CUENTA'), findsNothing);
  });

  testWidgets(
    'tap en CERRAR SESIÓN abre dialog de confirmación y al confirmar dispara '
    'SignOutRequested',
    (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const Authenticated(tUser));

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(pumpProfile());
      await tester.pump();

      // El primer "CERRAR SESIÓN" es el botón del body.
      await tester.tap(find.text('CERRAR SESIÓN').first);
      await tester.pumpAndSettle();

      // Dialog visible.
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      expect(
        find.text(
          'Tendrás que volver a iniciar sesión para acceder a tus rutinas.',
        ),
        findsOneWidget,
      );

      // Confirmar — el botón filled del dialog también dice "CERRAR SESIÓN".
      // En este punto hay dos matches (botón del body + botón del dialog);
      // el del dialog es el último renderizado.
      await tester.tap(find.text('CERRAR SESIÓN').last);
      await tester.pumpAndSettle();

      final captured = verify(() => mockAuthBloc.add(captureAny())).captured;
      expect(captured.length, 1);
      expect(captured.single, isA<SignOutRequested>());
    },
  );

  testWidgets('cancelar el dialog no dispara SignOutRequested', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(const Authenticated(tUser));

    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(pumpProfile());
    await tester.pump();

    await tester.tap(find.text('CERRAR SESIÓN').first);
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar sesión?'), findsOneWidget);

    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar sesión?'), findsNothing);
    verifyNever(() => mockAuthBloc.add(any()));
  });
}
