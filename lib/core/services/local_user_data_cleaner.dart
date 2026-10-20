import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';
import 'package:gym_flutter/core/services/workout_draft_service.dart';
import 'package:gym_flutter/core/sync/outbox_repository.dart';

/// Borra del dispositivo todo lo que pertenece a un usuario: outbox de
/// mutaciones pendientes, caché drift, sesión activa y borradores de series.
///
/// Se usa tras eliminar la cuenta en el servidor. Las preferencias de la app
/// (tema) no son datos personales y se conservan.
///
/// Best-effort: la cuenta ya no existe en el servidor, así que un fallo
/// local no debe bloquear el cierre de sesión. Cada paso se intenta por
/// separado y los errores sólo se loguean.
class LocalUserDataCleaner {
  LocalUserDataCleaner({
    required this.activeSessionService,
    required this.draftService,
    this.outbox,
    this.localDatabase,
  });

  final ActiveSessionService activeSessionService;
  final WorkoutDraftService draftService;

  /// `null` donde no hay persistencia local (ver `Capabilities`).
  final OutboxRepository? outbox;
  final LocalDatabase? localDatabase;

  Future<void> purgeUserData(String userId) async {
    // Primero el outbox: evita que el SyncWorker intente subir mutaciones de
    // una cuenta que ya no existe.
    await _step('outbox.purgeAll', () async => outbox?.purgeAll());
    await _step(
      'local_db.wipeCachedUserData',
      () async => localDatabase?.wipeCachedUserData(),
    );
    await _step('active_session.clear', activeSessionService.clear);
    await _step(
      'workout_drafts.clearAllForUser',
      () => draftService.clearAllForUser(userId),
    );
  }

  Future<void> _step(String name, Future<void> Function() body) async {
    try {
      await body();
    } catch (e, st) {
      AppLogger.instance.error('local_user_data_cleaner.$name failed', e, st);
    }
  }
}
