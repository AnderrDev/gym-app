import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row.dart';

import '../support/fake_backend.dart';
import '../support/test_app.dart';

/// Flujos de punta a punta sobre la app real con el backend en memoria.
/// Se ejecutan desde `integration_test/app_flows_test.dart` (dispositivo) y
/// desde `test/integration/app_flows_test.dart` (`flutter test`, CI).
/// Se llama con el motivo de cada flujo que falla. En el navegador
/// `flutter drive` no muestra el error; el runner del dispositivo lo vuelca
/// en `reportData` para leerlo en `build/integration_response_data.json`.
Future<void> Function(String flow, String error)? onFlowFailure;

void flowTest(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } catch (e, st) {
      await onFlowFailure?.call(description, '$e\n$st');
      rethrow;
    }
  });
}

void appFlows() {
  // Un toque que no llega al widget (tapado por otro) es un fallo, no un
  // aviso: así se detectó el SnackBar que tapaba el botón de serie.
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  group('Flujo de entrenamiento', () {
    flowTest('HOY → previa → registrar series → finalizar y volver a HOY', (
      tester,
    ) async {
      final backend = await pumpTestApp(tester);
      final repo = backend.workout;

      // HOY: tarjeta destacada con el día que toca.
      expect(find.text('TE TOCA HOY'), findsOneWidget);
      expect(find.text('Torso'), findsWidgets);
      await tapText(tester, 'Entrenar hoy');

      // Previa: resumen, duración estimada y "Última vez".
      expect(find.text('2 ejercicios'), findsOneWidget);
      expect(find.text('5 series'), findsOneWidget);
      expect(find.textContaining('min'), findsWidgets);
      expect(find.text('Última vez: 57,5 kg × 10'), findsOneWidget);
      expect(repo.sessions.where((s) => s.completedAt == null), isEmpty);

      await tapText(tester, 'Iniciar entrenamiento');

      // Sesión creada y vista activa con el registro en un toque.
      expect(repo.openSession, isNotNull);
      final sessionId = repo.openSession!.id;
      expect(find.textContaining('Ejercicio 1 de 2'), findsOneWidget);
      expect(
        find.text('Toca una serie para cambiar peso o repeticiones'),
        findsOneWidget,
      );
      // El objetivo va en la cabecera; las filas no lo repiten.
      expect(find.text('Objetivo'), findsNothing);
      expect(find.text('Siguiente'), findsOneWidget);

      // Press banca: 3 series de un toque con el objetivo (60 × 10).
      for (var set = 1; set <= 3; set++) {
        await tapCompleteSet(tester, expectLabel: 'Serie $set hecha');
      }
      final press = repo
          .logsOf(sessionId)
          .where((l) => l.exerciseId == 'ex-press')
          .toList();
      expect(press, hasLength(3));
      expect(press.map((l) => l.actualWeight), everyElement(60));
      expect(press.map((l) => l.actualReps), everyElement(10));

      // Dominadas: la última vez fueron a peso corporal, así que también se
      // registran de un toque (sin historial abriría la hoja).
      await goToExercise(tester, 'Dominadas');
      expect(find.textContaining('Ejercicio 2 de 2'), findsOneWidget);
      for (var set = 1; set <= 2; set++) {
        await tapCompleteSet(
          tester,
          expectLabel: 'Serie $set hecha · Peso corporal × 8',
        );
      }
      expect(repo.logsOf(sessionId), hasLength(5));
      expect(find.text('Peso corporal × 8 reps'), findsNWidgets(2));
      // Tras la última serie no hay descanso que esperar, y el botón fijo
      // pasa a finalizar.
      expect(find.text('DESCANSO'), findsNothing);
      expect(find.text('Finalizar entrenamiento'), findsOneWidget);

      // Finalizar → resumen → guardar.
      await tapText(tester, 'Finalizar');
      expect(find.text('¡Rutina completada!'), findsOneWidget);
      expect(find.text('Peso corporal · 2 series'), findsOneWidget);
      expect(find.text('Media 60 kg · 3 series'), findsOneWidget);
      await tapText(tester, 'FINALIZAR Y GUARDAR');

      expect(repo.finishedSessionIds, [sessionId]);
      expect(repo.openSession, isNull);

      // De vuelta en HOY: "Torso" hecho, ahora toca "Pierna".
      expect(find.text('TE TOCA HOY'), findsOneWidget);
      expect(find.text('Pierna'), findsWidgets);
      expect(find.textContaining('Realizado el'), findsOneWidget);
    });

    flowTest('deshacer una serie y corregir peso desde la fila', (
      tester,
    ) async {
      final backend = await pumpTestApp(tester);
      final repo = backend.workout;
      await tapText(tester, 'Entrenar hoy');
      await tapText(tester, 'Iniciar entrenamiento');
      final sessionId = repo.openSession!.id;

      // Un toque registra; "Deshacer" la borra y el botón vuelve a la 1.
      await tapCompleteSet(tester, expectLabel: 'Serie 1 hecha · 60 kg × 10');
      expect(repo.logsOf(sessionId), hasLength(1));
      await tapText(tester, 'Deshacer');
      expect(repo.logsOf(sessionId), isEmpty);
      expect(find.textContaining('Serie 1 hecha'), findsOneWidget);

      // Tocar la fila abre la hoja para cambiar el peso.
      await tester.tap(find.byType(ExerciseSetRow).first);
      await settle(tester);
      await typeText(
        tester,
        find.byKey(const ValueKey('complete_set_weight')),
        '62.5',
      );
      await confirmSetSheet(tester);
      final log = repo.logsOf(sessionId).single;
      expect(log.actualWeight, 62.5);
      expect(log.actualReps, 10);

      // La siguiente propone lo mismo que la anterior.
      expect(
        find.textContaining('Serie 2 hecha · 62,5 kg × 10'),
        findsOneWidget,
      );

      // El aviso "Deshacer" se va solo: no se arrastra a otro ejercicio ni
      // tapa las series.
      await tapCompleteSet(tester, expectLabel: 'Serie 2 hecha');
      expect(find.text('Deshacer'), findsOneWidget);
      await pumpUntilGone(tester, find.text('Deshacer'));
    });

    flowTest('salir con la sesión abierta y reanudarla desde HOY', (
      tester,
    ) async {
      final backend = await pumpTestApp(tester);
      final repo = backend.workout;
      await tapText(tester, 'Entrenar hoy');
      await tapText(tester, 'Iniciar entrenamiento');
      await tapCompleteSet(tester, expectLabel: 'Serie 1 hecha');

      await tester.tap(find.byTooltip('Salir del entrenamiento'));
      await settle(tester);

      // HOY la muestra en curso y la reanuda sin pasar por la previa.
      expect(find.text('EN CURSO'), findsOneWidget);
      await tapText(tester, 'Continuar sesión');
      expect(find.text('Iniciar entrenamiento'), findsNothing);
      expect(find.textContaining('Serie 2 hecha'), findsOneWidget);
      expect(repo.sessions.where((s) => s.completedAt == null), hasLength(1));
    });

    flowTest('descartar el entrenamiento lo borra y vuelve a HOY', (
      tester,
    ) async {
      final backend = await pumpTestApp(tester);
      final repo = backend.workout;
      await tapText(tester, 'Entrenar hoy');
      await tapText(tester, 'Iniciar entrenamiento');
      final sessionId = repo.openSession!.id;
      await tapCompleteSet(tester, expectLabel: 'Serie 1 hecha');

      await tester.tap(find.byTooltip('Más opciones'));
      await settle(tester);
      await tapText(tester, 'Descartar entrenamiento');
      expect(find.text('¿Descartar este entrenamiento?'), findsOneWidget);
      await tester.tap(find.text('Descartar'));
      // El aviso dura poco: se busca mientras la pantalla se asienta.
      await pumpUntilFound(tester, find.text('Entrenamiento descartado'));
      // Descartar no es terminar: HOY no debe felicitar (ni después, en la
      // cola de avisos).
      await expectNeverAppears(tester, find.text('¡Entrenamiento completado!'));

      expect(repo.discardedSessionIds, [sessionId]);
      expect(repo.openSession, isNull);
      expect(find.text('TE TOCA HOY'), findsOneWidget);
      expect(find.text('Entrenar hoy'), findsOneWidget);
    });

    flowTest('sustituir un ejercicio a mitad de sesión conserva lo hecho', (
      tester,
    ) async {
      final backend = await pumpTestApp(tester);
      final repo = backend.workout;
      await tapText(tester, 'Entrenar hoy');
      await tapText(tester, 'Iniciar entrenamiento');
      final sessionId = repo.openSession!.id;
      await tapCompleteSet(tester, expectLabel: 'Serie 1 hecha');

      // Press banca → Press inclinado para las 2 series que faltan.
      await tester.tap(find.byTooltip('Opciones del ejercicio').first);
      await settle(tester);
      await tapText(tester, 'Sustituir ejercicio');
      expect(find.text('Solo esta sesión'), findsOneWidget);
      await tapText(tester, 'Press inclinado');
      expect(find.text('Seleccionado: Press inclinado'), findsOneWidget);
      await typeText(tester, find.byType(TextField).last, '50');
      await tester.tap(find.text('Sustituir ejercicio').last);
      await settle(tester);

      // El plan de la sesión cambia; la rutina no.
      final plan = repo.sessionPlans[sessionId]!;
      final press = plan.firstWhere((e) => e.id == 'ex-press');
      final inclinado = plan.firstWhere((e) => e.id == 'ex-press-inclinado');
      expect(press.targetSets, 1);
      expect(press.replacedByExerciseName, 'Press inclinado');
      expect(inclinado.targetSets, 2);
      expect(inclinado.targetWeight, 50);
      expect(inclinado.replacesExerciseName, 'Press banca');
      expect(
        repo.days
            .firstWhere((d) => d.id == FakeWorkoutRepository.torsoDayId)
            .exercises
            .map((e) => e.name),
        ['Press banca', 'Dominadas'],
      );
      expect(
        find.text('Sustituye a Press banca · Solo esta sesión'),
        findsOneWidget,
      );

      // La cabecera sigue a la tarjeta del sustituto (se quedaba en el
      // ejercicio anterior).
      expect(find.text('Ejercicio 3 de 3'), findsOneWidget);

      // La serie ya hecha se conserva y el sustituto se registra aparte.
      await tapCompleteSet(tester, expectLabel: 'Serie 1 hecha · 50 kg × 10');
      final logs = repo.logsOf(sessionId);
      expect(logs.where((l) => l.exerciseId == 'ex-press'), hasLength(1));
      final sub = logs.singleWhere((l) => l.exerciseId == 'ex-press-inclinado');
      expect(sub.actualWeight, 50);
      expect(sub.actualReps, 10);
    });
  });

  group('RUTINAS', () {
    flowTest('crear rutina con un día, ejercicios del catálogo y objetivos', (
      tester,
    ) async {
      final backend = await pumpTestApp(tester);
      final repo = backend.workout;
      await tapText(tester, 'RUTINAS');
      expect(find.text('Fuerza'), findsOneWidget);

      // Rutina nueva: al añadir el primer día se guarda sola.
      await tapText(tester, 'NUEVA RUTINA');
      await typeText(tester, find.byType(TextField).first, 'Mi rutina');
      await tapText(tester, 'AÑADIR DÍA');
      final routine = repo.routines.singleWhere((r) => r.name == 'Mi rutina');
      expect(routine.creatorId, FakeWorkoutRepository.userId);
      final dayId = repo.days.singleWhere((d) => d.routineId == routine.id).id;
      expect(find.text('Sin ejercicios · toca para añadir'), findsOneWidget);

      // Editor del día: dos ejercicios del catálogo de una vez.
      await tapText(tester, 'Nuevo Día');
      await tapText(tester, 'AÑADIR EJERCICIOS');
      await tapText(tester, 'Remo con barra');
      await tapText(tester, 'Press inclinado');
      await tapText(tester, 'Añadir 2 ejercicios');
      List<String> names() => [
        for (final e in repo.days.firstWhere((d) => d.id == dayId).exercises)
          e.name,
      ];
      expect(names(), ['Remo con barra', 'Press inclinado']);
      expect(find.text('6 series'), findsOneWidget);

      // Objetivo del remo: 50 kg.
      await tapText(tester, 'Remo con barra');
      expect(find.text('Editar objetivos'), findsOneWidget);
      await typeText(tester, find.byType(TextField).last, '50');
      await tester.tap(find.text('GUARDAR').last);
      await settle(tester);
      final remo = repo.days
          .firstWhere((d) => d.id == dayId)
          .exercises
          .firstWhere((e) => e.name == 'Remo con barra');
      expect(remo.targetWeight, 50);
      expect(find.textContaining('3 × 10 · 50 kg'), findsOneWidget);

      // Nombre del día.
      await typeText(tester, find.byType(TextField).first, 'Espalda');
      await tapText(tester, 'GUARDAR');
      expect(repo.days.firstWhere((d) => d.id == dayId).name, 'Espalda');

      // GUARDAR vuelve a la rutina; de ahí, a la lista.
      expect(find.text('Espalda'), findsOneWidget);
      expect(find.text('Remo con barra · Press inclinado'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar editor'));
      await settle(tester);
      expect(find.text('Mi rutina'), findsOneWidget);
    });
  });

  group('PROGRESO', () {
    flowTest('semanas anteriores, historial de rutina y de ejercicio', (
      tester,
    ) async {
      await pumpTestApp(tester);
      await tapText(tester, 'PROGRESO');

      expect(find.text('Esta semana'), findsOneWidget);
      expect(find.text('ÚLTIMAS 8 SEMANAS'), findsOneWidget);

      // La semana pasada tiene la sesión sembrada: 3 × 57,5 kg × 10.
      await tester.tap(find.byTooltip('Semana anterior'));
      await pumpUntilFound(tester, find.text('1.725 kg'));
      expect(find.text('Semana pasada'), findsOneWidget);

      // Historial de la rutina → detalle de la sesión.
      await tapText(tester, 'Fuerza');
      expect(find.text('1 SESIÓN'), findsOneWidget);
      await tapText(tester, 'Torso');
      await pumpUntilFound(tester, find.textContaining('Press banca'));
      // Cerrar la hoja tocando fuera y volver a PROGRESO.
      await tester.tapAt(const Offset(20, 20));
      await settle(tester);
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      // Progreso de un ejercicio.
      await pumpUntilFound(tester, find.text('PROGRESO POR EJERCICIO'));
      await tapText(tester, 'Press banca');
      await pumpUntilFound(tester, find.text('PESO MÁXIMO'));
      expect(find.text('1 SESIÓN'), findsOneWidget);
    });
  });

  group('HOY', () {
    flowTest('historial: semana anterior y vuelta a hoy', (tester) async {
      await pumpTestApp(tester);

      await tapText(tester, 'Historial');
      expect(
        find.text('No hay entrenamientos registrados esta semana.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Semana anterior'));
      await settle(tester);
      expect(find.text('Torso'), findsWidgets);
      expect(find.text('Ver sesión'), findsOneWidget);

      await tapText(tester, 'Volver a hoy');
      expect(find.text('TE TOCA HOY'), findsOneWidget);
      expect(find.text('Entrenar hoy'), findsOneWidget);
    });

    flowTest('con dos rutinas recuerda la última elegida', (tester) async {
      final backend = await pumpTestApp(tester, secondRoutine: true);

      // Primera vez: hay que elegir.
      expect(find.text('Mis Rutinas'), findsOneWidget);
      await tapText(tester, 'Fuerza');
      expect(find.text('TE TOCA HOY'), findsOneWidget);
      final saved = Map<String, Object>.fromEntries(
        backend.prefs.getKeys().map((k) => MapEntry(k, backend.prefs.get(k)!)),
      );

      // Al volver a abrir la app entra directa al plan de "Fuerza".
      await pumpTestApp(tester, secondRoutine: true, prefs: saved);
      expect(find.text('Mis Rutinas'), findsNothing);
      expect(find.text('TE TOCA HOY'), findsOneWidget);
      expect(find.text('Torso'), findsWidgets);
    });
  });

  group('Login', () {
    flowTest('contraseña incorrecta avisa; la correcta entra a HOY', (
      tester,
    ) async {
      await pumpTestApp(tester, signedIn: false);
      expect(find.text('TE TOCA HOY'), findsNothing);

      final fields = find.byType(TextField);
      await typeText(tester, fields.first, FakeAuthRepository.user.email);
      await typeText(tester, fields.last, FakeAuthRepository.wrongPassword);
      await tapTextIgnoringCase(tester, 'Iniciar sesión');
      expect(find.textContaining('incorrect'), findsWidgets);
      expect(find.text('TE TOCA HOY'), findsNothing);

      await typeText(tester, fields.last, 'buena-clave-123');
      await tapTextIgnoringCase(tester, 'Iniciar sesión');
      expect(find.text('TE TOCA HOY'), findsOneWidget);
    });
  });
}

// ── Helpers ────────────────────────────────────────────────────────────────

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    // Puede estar al final de una lista perezosa (p. ej. la hoja de resumen).
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
  }
  expect(finder, findsWidgets, reason: 'No se encontró "$text"');
  await tester.ensureVisible(finder.first);
  await settle(tester);
  // Si sigue tapado o cortado, se arrastra la lista como haría el usuario.
  final scrollable = find.ancestor(
    of: finder.first,
    matching: find.byType(Scrollable),
  );
  for (
    var i = 0;
    i < 15 &&
        finder.hitTestable().evaluate().isEmpty &&
        scrollable.evaluate().isNotEmpty;
    i++
  ) {
    await tester.drag(scrollable.first, const Offset(0, -200));
    await settle(tester);
  }
  await tester.tap(finder.first);
  await settle(tester);
}

/// Pulsa el botón fijo "Serie N hecha · …" / "Registrar serie N".
Future<void> tapCompleteSet(
  WidgetTester tester, {
  required String expectLabel,
}) async {
  final button = find.byKey(const ValueKey('focus_complete_set_button'));
  expect(button, findsOneWidget);
  expect(
    find.descendant(of: button, matching: find.textContaining(expectLabel)),
    findsOneWidget,
    reason: 'El botón debía decir "$expectLabel"',
  );
  await tester.tap(button);
  await settle(tester);
}

/// Confirma la hoja de la serie con los valores que trae.
Future<void> confirmSetSheet(WidgetTester tester) async {
  final confirm = find.textContaining(
    RegExp('confirmar serie', caseSensitive: false),
  );
  expect(confirm, findsOneWidget, reason: 'La hoja de la serie no se abrió');
  await tester.tap(confirm);
  await settle(tester);
}

/// Pasa a la tarjeta de [name] en el carrusel de ejercicios.
Future<void> goToExercise(WidgetTester tester, String name) async {
  for (var i = 0; i < 5; i++) {
    if (find.textContaining('Ejercicio').evaluate().isNotEmpty &&
        find
            .descendant(of: find.byType(PageView), matching: find.text(name))
            .hitTestable()
            .evaluate()
            .isNotEmpty) {
      return;
    }
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await settle(tester);
  }
  fail('No se llegó a la tarjeta de "$name"');
}

/// Escribe en un campo como lo haría el teclado. `enterText` no llega al
/// campo en el navegador (la entrada de texto va por el DOM).
Future<void> typeText(WidgetTester tester, Finder field, String text) async {
  final editable = find
      .descendant(of: field, matching: find.byType(EditableText))
      .first;
  await tester.showKeyboard(editable);
  tester
      .state<EditableTextState>(editable)
      .userUpdateTextEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
        SelectionChangedCause.keyboard,
      );
  await settle(tester);
}

/// Bombea hasta que aparece [finder] (o falla tras [timeout]).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final live = tester.binding is! AutomatedTestWidgetsFlutterBinding;
  final end = DateTime.now().add(timeout);
  for (var i = 0; i < 100; i++) {
    if (finder.evaluate().isNotEmpty) return;
    if (live && DateTime.now().isAfter(end)) break;
    await tester.pump(const Duration(milliseconds: 50));
    if (live) await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  expect(finder, findsWidgets);
}

/// Bombea [duration] comprobando que [finder] no aparece en ningún momento.
Future<void> expectNeverAppears(
  WidgetTester tester,
  Finder finder, {
  Duration duration = const Duration(seconds: 5),
}) async {
  final live = tester.binding is! AutomatedTestWidgetsFlutterBinding;
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < duration; t += step) {
    expect(finder, findsNothing);
    await tester.pump(step);
    if (live) await Future<void>.delayed(step);
  }
  expect(finder, findsNothing);
}

/// Pulsa el último texto visible que coincide sin distinguir mayúsculas
/// (los `AppButton` ponen la etiqueta en mayúsculas).
Future<void> tapTextIgnoringCase(WidgetTester tester, String text) async {
  final finder = find.byWidgetPredicate(
    (w) => w is Text && w.data?.toLowerCase() == text.toLowerCase(),
  );
  expect(finder, findsWidgets, reason: 'No se encontró "$text"');
  await tester.tap(finder.last);
  await settle(tester);
}

/// Bombea hasta que [finder] desaparece (p. ej. un aviso temporal), con tope
/// de [timeout] de reloj (falso en `flutter test`, real en dispositivo).
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final live = tester.binding is! AutomatedTestWidgetsFlutterBinding;
  const step = Duration(milliseconds: 100);
  final end = DateTime.now().add(timeout);
  for (var i = 0; i * step.inMilliseconds < timeout.inMilliseconds; i++) {
    if (finder.evaluate().isEmpty) return;
    if (live && DateTime.now().isAfter(end)) break;
    await tester.pump(step);
    if (live) await Future<void>.delayed(step);
  }
  expect(finder, findsNothing);
}
