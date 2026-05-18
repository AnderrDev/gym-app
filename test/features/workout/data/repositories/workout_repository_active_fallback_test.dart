import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

import '../../../../helpers/mocks.dart';

/// `getActiveSessionForUser`: cuando el remote tira un error de red y el
/// cache local tiene una sesión abierta, devolver el cache.
void main() {
  late WorkoutRepositoryImpl repo;
  late MockWorkoutRemoteDataSource remote;
  late MockWorkoutLocalDataSource local;
  late MockConnectivityService conn;
  late MockOutboxRepository outbox;
  late MockSyncWorker worker;

  const tUserId = 'u1';
  final tCachedSession = WorkoutSession(
    id: 'cached-1',
    userId: tUserId,
    routineDayId: 'd1',
    sessionDate: DateTime.utc(2026, 5, 18),
  );

  setUp(() {
    remote = MockWorkoutRemoteDataSource();
    local = MockWorkoutLocalDataSource();
    conn = MockConnectivityService();
    outbox = MockOutboxRepository();
    worker = MockSyncWorker();
    when(() => conn.isOnline).thenReturn(true);

    repo = WorkoutRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      connectivity: conn,
      outbox: outbox,
      syncWorker: worker,
      uuid: const Uuid(),
      currentUserIdResolver: () => tUserId,
    );
  });

  test('remote falla con SocketException → fallback cache', () async {
    when(() => remote.getActiveSessionForUser(tUserId))
        .thenThrow(const SocketException('down'));
    when(() => local.getOpenSessionForUser(tUserId))
        .thenAnswer((_) async => tCachedSession);

    final result = await repo.getActiveSessionForUser(tUserId);
    result.fold((l) => fail('expected Right, got $l'), (session) {
      expect(session?.id, 'cached-1');
    });
    verify(() => local.getOpenSessionForUser(tUserId)).called(1);
  });

  test('remote OK con valor → no toca cache', () async {
    when(() => remote.getActiveSessionForUser(tUserId))
        .thenAnswer((_) async => null);

    final result = await repo.getActiveSessionForUser(tUserId);
    result.fold((l) => fail('expected Right'), (s) => expect(s, isNull));
    verifyNever(() => local.getOpenSessionForUser(any()));
  });

  test('remote falla con AuthException (no-network) → no fallback', () async {
    when(() => remote.getActiveSessionForUser(tUserId))
        .thenThrow(Exception('auth boom'));

    final result = await repo.getActiveSessionForUser(tUserId);
    expect(result.isLeft(), isTrue);
    verifyNever(() => local.getOpenSessionForUser(any()));
  });
}
