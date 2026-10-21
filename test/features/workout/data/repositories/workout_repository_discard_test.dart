import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';

import '../../../../helpers/mocks.dart';

/// Descartar una sesión abierta: online-only y con la cola offline vacía,
/// para que el SyncWorker no la "resucite" después del borrado.
void main() {
  late WorkoutRepositoryImpl repo;
  late MockWorkoutRemoteDataSource remote;
  late MockWorkoutLocalDataSource local;
  late MockConnectivityService conn;
  late MockOutboxRepository outbox;

  setUp(() {
    remote = MockWorkoutRemoteDataSource();
    local = MockWorkoutLocalDataSource();
    conn = MockConnectivityService();
    outbox = MockOutboxRepository();
    when(() => conn.isOnline).thenReturn(true);
    when(() => outbox.pendingCount()).thenAnswer((_) async => 0);
    when(() => remote.discardWorkoutSession(any())).thenAnswer((_) async {});
    when(() => local.deleteCachedSession(any())).thenAnswer((_) async {});

    repo = WorkoutRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      connectivity: conn,
      outbox: outbox,
      syncWorker: MockSyncWorker(),
      uuid: const Uuid(),
      currentUserIdResolver: () => 'u1',
    );
  });

  test('online y sin pendientes: borra en remoto y en la caché', () async {
    final result = await repo.discardWorkoutSession('s1');

    expect(result.isRight(), isTrue);
    verify(() => remote.discardWorkoutSession('s1')).called(1);
    verify(() => local.deleteCachedSession('s1')).called(1);
  });

  test('offline: NetworkFailure sin tocar remoto ni caché', () async {
    when(() => conn.isOnline).thenReturn(false);

    final result = await repo.discardWorkoutSession('s1');

    expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    verifyNever(() => remote.discardWorkoutSession(any()));
    verifyNever(() => local.deleteCachedSession(any()));
  });

  test('con cambios offline pendientes: ConflictFailure', () async {
    when(() => outbox.pendingCount()).thenAnswer((_) async => 2);

    final result = await repo.discardWorkoutSession('s1');

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<ConflictFailure>());
    expect(failure!.message, contains('sin sincronizar'));
    verifyNever(() => remote.discardWorkoutSession(any()));
  });

  test('si el remoto rechaza, no borra la caché local', () async {
    when(
      () => remote.discardWorkoutSession(any()),
    ).thenThrow(ValidationException('Este entrenamiento ya se finalizó.'));

    final result = await repo.discardWorkoutSession('s1');

    expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    verifyNever(() => local.deleteCachedSession(any()));
  });

  test('un fallo al limpiar la caché no tumba el descarte', () async {
    when(
      () => local.deleteCachedSession(any()),
    ).thenThrow(Exception('disk full'));

    final result = await repo.discardWorkoutSession('s1');

    expect(result.isRight(), isTrue);
  });
}
