import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/core/services/local_user_data_cleaner.dart';
import 'package:gym_flutter/core/services/workout_draft_service.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

import '../../helpers/database_test_helper.dart';
import '../../helpers/mocks.dart';

void main() {
  const tUserId = 'user-1';

  late SharedPreferences prefs;
  late ActiveSessionService activeSession;
  late WorkoutDraftService drafts;
  late MockOutboxRepository outbox;
  late LocalDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'app.theme_mode': 'dark'});
    prefs = await SharedPreferences.getInstance();
    activeSession = ActiveSessionService(prefs);
    drafts = WorkoutDraftService(prefs);
    outbox = MockOutboxRepository();
    db = openInMemoryDb();
    addTearDown(() async => db.close());
  });

  LocalUserDataCleaner buildCleaner() => LocalUserDataCleaner(
    activeSessionService: activeSession,
    draftService: drafts,
    outbox: outbox,
    localDatabase: db,
  );

  Future<void> seed() async {
    await activeSession.save(
      sessionId: 's1',
      routineDayId: 'd1',
      userId: tUserId,
      sessionDate: DateTime(2026, 10, 19),
      routineDayName: 'Pierna',
    );
    await drafts.save(
      tUserId,
      const SetLog(
        sessionId: 's1',
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 20,
        actualReps: 10,
      ),
    );
    await drafts.save(
      'otro-usuario',
      const SetLog(
        sessionId: 's9',
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 20,
        actualReps: 10,
      ),
    );
    await db
        .into(db.cachedExercises)
        .insert(
          CachedExercisesCompanion.insert(
            id: 'e1',
            name: 'Press',
            fetchedAt: 1,
          ),
        );
    await db
        .into(db.cachedWeeklyInsights)
        .insert(
          CachedWeeklyInsightsCompanion.insert(
            userId: tUserId,
            routineId: 'r1',
            weekStart: '2026-10-19',
            payloadJson: '{}',
            fetchedAt: 1,
          ),
        );
  }

  test('purga outbox, caché drift, sesión activa y borradores del usuario; '
      'conserva preferencias y app_meta', () async {
    when(() => outbox.purgeAll()).thenAnswer((_) async {});
    await seed();

    await buildCleaner().purgeUserData(tUserId);

    verify(() => outbox.purgeAll()).called(1);
    expect(activeSession.getContext(), isNull);
    expect(drafts.load(tUserId, 's1'), isEmpty);
    // Borradores de otro usuario no se tocan.
    expect(drafts.load('otro-usuario', 's9'), hasLength(1));
    expect(await db.select(db.cachedExercises).get(), isEmpty);
    expect(await db.select(db.cachedWeeklyInsights).get(), isEmpty);
    // El healthcheck sigue funcionando y el tema se conserva.
    await db.ping();
    expect(prefs.getString('app.theme_mode'), 'dark');
  });

  test('un paso que falla no impide los siguientes', () async {
    when(() => outbox.purgeAll()).thenThrow(StateError('db cerrada'));
    await seed();

    await buildCleaner().purgeUserData(tUserId);

    expect(activeSession.getContext(), isNull);
    expect(drafts.load(tUserId, 's1'), isEmpty);
    expect(await db.select(db.cachedExercises).get(), isEmpty);
  });

  test('sin persistencia local (outbox/db nulos) no falla', () async {
    final cleaner = LocalUserDataCleaner(
      activeSessionService: activeSession,
      draftService: drafts,
    );
    await cleaner.purgeUserData(tUserId);
    expect(activeSession.getContext(), isNull);
  });
}
