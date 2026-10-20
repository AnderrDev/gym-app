import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_delete_account_section.dart';

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _DialogResult {
  String? value;
  bool closed = false;
}

ElevatedButton _confirmButton(WidgetTester tester) => tester.widget(
  find.descendant(
    of: find.byKey(const Key('delete_account_confirm_button')),
    matching: find.byType(ElevatedButton),
  ),
);

void main() {
  setUpAll(() {
    registerFallbackValue(const AcknowledgeProfileFeedback());
  });

  group('DeleteAccountConfirmDialog', () {
    Future<_DialogResult> openDialog(WidgetTester tester) async {
      final result = _DialogResult();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result.value = await DeleteAccountConfirmDialog.show(context);
                  result.closed = true;
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('explica qué se borra y que las rutinas públicas quedan '
        'anónimas', (tester) async {
      await openDialog(tester);

      expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
      expect(find.textContaining('permanente'), findsOneWidget);
      expect(find.textContaining('de forma anónima'), findsOneWidget);
    });

    testWidgets('el botón sigue deshabilitado hasta escribir ELIMINAR', (
      tester,
    ) async {
      final result = await openDialog(tester);

      expect(_confirmButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'ELIMIN');
      await tester.pump();
      expect(_confirmButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'borrar');
      await tester.pump();
      expect(_confirmButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'eliminar ');
      await tester.pump();
      expect(_confirmButton(tester).onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
      expect(result.closed, isTrue);
      expect(result.value, 'ELIMINAR');
    });

    testWidgets('cancelar devuelve null', (tester) async {
      final result = await openDialog(tester);

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(result.closed, isTrue);
      expect(result.value, isNull);
    });
  });

  group('ProfileDeleteAccountSection', () {
    late _MockProfileBloc bloc;

    setUp(() {
      bloc = _MockProfileBloc();
    });

    Future<void> pumpSection(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: BlocProvider<ProfileBloc>.value(
              value: bloc,
              child: const ProfileDeleteAccountSection(userId: 'u1'),
            ),
          ),
        ),
      );
    }

    testWidgets('al confirmar dispara DeleteAccountRequested', (tester) async {
      when(() => bloc.state).thenReturn(const ProfileState());
      await pumpSection(tester);

      await tester.tap(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ELIMINAR');
      await tester.pump();
      await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(
          const DeleteAccountRequested(userId: 'u1', confirmation: 'ELIMINAR'),
        ),
      ).called(1);
    });

    testWidgets('mientras se elimina el botón queda deshabilitado', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        const ProfileState(deletionStatus: AccountDeletionStatus.deleting),
      );
      await pumpSection(tester);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('fallo → snackbar de error y acknowledge', (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable(const [
          ProfileState(deletionStatus: AccountDeletionStatus.deleting),
          ProfileState(
            deletionStatus: AccountDeletionStatus.failure,
            deletionErrorMessage: 'Sin conexión a internet',
          ),
        ]),
        initialState: const ProfileState(),
      );
      await pumpSection(tester);
      await tester.pump();
      await tester.pump();

      expect(find.text('Sin conexión a internet'), findsOneWidget);
      verify(() => bloc.add(const AcknowledgeProfileFeedback())).called(1);
    });

    testWidgets('éxito → snackbar "Tu cuenta se eliminó"', (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable(const [
          ProfileState(deletionStatus: AccountDeletionStatus.deleting),
          ProfileState(deletionStatus: AccountDeletionStatus.deleted),
        ]),
        initialState: const ProfileState(),
      );
      await pumpSection(tester);
      await tester.pump();
      await tester.pump();

      expect(find.text('Tu cuenta se eliminó'), findsOneWidget);
    });
  });
}
