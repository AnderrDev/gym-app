import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_flutter/core/services/workout_draft_service.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

void main() {
  late SharedPreferences prefs;
  late WorkoutDraftService service;
  const log = SetLog(
    sessionId: 's1',
    exerciseId: 'e1',
    setIndex: 1,
    actualWeight: 40,
    actualReps: 8,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = WorkoutDraftService(prefs);
  });

  test('recupera el peso editado después de recrear el servicio', () async {
    await service.save('u1', log);
    await prefs.reload();
    final reopened = WorkoutDraftService(prefs);
    expect(reopened.load('u1', 's1'), [log]);
    expect(reopened.load('u2', 's1'), isEmpty);
    expect(reopened.load('u1', 's2'), isEmpty);
  });

  test('preserva un borrador de peso corporal al recargar', () async {
    final bodyweight = log.copyWith(actualWeight: 0, actualReps: 10);
    await service.save('u1', bodyweight);
    await prefs.reload();
    expect(WorkoutDraftService(prefs).load('u1', 's1'), [bodyweight]);
  });

  test('actualiza una serie sin perder las demás', () async {
    await service.save('u1', log);
    await service.save('u1', log.copyWith(setIndex: 2, actualWeight: 42));
    await service.save('u1', log.copyWith(actualWeight: 41));
    final drafts = service.load('u1', 's1');
    expect(drafts, hasLength(2));
    expect(drafts.singleWhere((l) => l.setIndex == 1).actualWeight, 41);
    expect(drafts.singleWhere((l) => l.setIndex == 2).actualWeight, 42);
  });

  test('finalizar limpia solo los borradores de esa sesión', () async {
    await service.save('u1', log);
    await service.save('u1', log.copyWith(sessionId: 's2'));
    await service.clear('u1', 's1');
    expect(service.load('u1', 's1'), isEmpty);
    expect(service.load('u1', 's2'), hasLength(1));
  });
}
