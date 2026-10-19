import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gym_flutter/features/profile/presentation/widgets/profile_edit_name_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockProfileRepository repository;

  const tUserId = 'user-123';

  setUp(() {
    repository = MockProfileRepository();
  });

  /// Monta el sheet como modal real para que `Navigator.pop` desde su listener
  /// pope la route del bottom sheet (no la root) y el snackbar tenga
  /// `ScaffoldMessenger` válido al renderizarse.
  Future<void> openSheet(
    WidgetTester tester, {
    String? initialValue,
    required void Function(String) onSaved,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BlocProvider<ProfileBloc>(
                    create: (_) => ProfileBloc(repository: repository),
                    child: ProfileEditNameSheet(
                      userId: tUserId,
                      initialValue: initialValue,
                      onSaved: onSaved,
                    ),
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza el initialValue en el form field', (tester) async {
    await openSheet(tester, initialValue: 'Ander', onSaved: (_) {});
    expect(find.text('Editar nombre'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ander'), findsOneWidget);
  });

  testWidgets('submit con nombre vacío muestra warning y NO llama al repo', (
    tester,
  ) async {
    await openSheet(tester, initialValue: '', onSaved: (_) {});
    await tester.tap(find.text('GUARDAR'));
    await tester.pump();
    expect(find.text('El nombre no puede estar vacío'), findsOneWidget);
    verifyNever(
      () => repository.updateFullName(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
      ),
    );
  });

  testWidgets('submit exitoso invoca onSaved y cierra el sheet', (
    tester,
  ) async {
    when(
      () => repository.updateFullName(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
      ),
    ).thenAnswer((_) async => const Right('Ander Cifuentes'));

    String? saved;
    await openSheet(
      tester,
      initialValue: 'Ander Cifuentes',
      onSaved: (name) => saved = name,
    );

    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(saved, 'Ander Cifuentes');
    expect(find.text('Nombre actualizado'), findsOneWidget);
    expect(find.byType(ProfileEditNameSheet), findsNothing);
  });

  testWidgets('submit fallido muestra snackbar de error y NO invoca onSaved', (
    tester,
  ) async {
    when(
      () => repository.updateFullName(
        userId: any(named: 'userId'),
        fullName: any(named: 'fullName'),
      ),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    var calledOnSaved = false;
    await openSheet(
      tester,
      initialValue: 'Ander',
      onSaved: (_) => calledOnSaved = true,
    );

    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(calledOnSaved, isFalse);
    expect(find.text('boom'), findsOneWidget);
    expect(find.byType(ProfileEditNameSheet), findsOneWidget);
  });
}
