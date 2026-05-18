import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:gym_flutter/core/error/exceptions.dart' as core_ex;
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/sync/connectivity_service.dart';
import 'package:gym_flutter/core/sync/outbox_repository.dart';
import 'package:gym_flutter/core/sync/sync_worker.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_local_data_source.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

/// Política de drop: motivos que el worker considera no-recuperables.
class _DropReason {
  static const sessionSuperseded = 'session_superseded';
  static const validation = 'validation_failed';
  static const notFound = 'not_found';
}

/// Implementación del SyncWorker.
///
/// Reglas clave:
/// - Single-flight: solo un drain en vuelo. Si `kick`/`drain` se llama
///   mientras `_draining`, se ignora.
/// - Backoff: `min(2^attempts seconds, 5 min) * jitter(0.8..1.2)`. La pausa
///   por auth NO incrementa attempts (es estado externo, no fallo lógico).
/// - Min-interval por kind: `finalizeSession` se rate-limit-ea a 2.5 s
///   entre ejecuciones consecutivas exitosas.
class SyncWorkerImpl implements SyncWorker {
  SyncWorkerImpl({
    required OutboxRepository outbox,
    required WorkoutRemoteDataSource remote,
    required WorkoutLocalDataSource local,
    required ConnectivityService connectivity,
    required AuthRepository authRepository,
    required Clock clock,
    Random? random,
  })  : _outbox = outbox,
        _remote = remote,
        _local = local,
        _connectivity = connectivity,
        _auth = authRepository,
        _clock = clock,
        _random = random ?? Random();

  final OutboxRepository _outbox;
  final WorkoutRemoteDataSource _remote;
  final WorkoutLocalDataSource _local;
  final ConnectivityService _connectivity;
  final AuthRepository _auth;
  final Clock _clock;
  final Random _random;

  final StreamController<SyncWorkerEvent> _eventsCtrl =
      StreamController<SyncWorkerEvent>.broadcast();
  StreamSubscription<bool>? _connSub;
  StreamSubscription<bool>? _authSub;

  bool _draining = false;
  bool _authPaused = false;
  bool _started = false;
  bool _stopped = false;
  final Map<MutationKind, DateTime> _lastSuccessByKind = {};

  /// Configuración de rate-limit por kind (min interval entre éxitos
  /// consecutivos). Mantenerlo aquí (no por payload) evita serializar
  /// metadata extra en la outbox.
  static const Map<MutationKind, Duration> _minInterval = {
    MutationKind.finalizeSession: Duration(milliseconds: 2500),
  };

  @override
  Stream<SyncWorkerEvent> get events$ => _eventsCtrl.stream;

  @override
  void start() {
    if (_started || _stopped) return;
    _started = true;

    _connSub = _connectivity.isOnline$.listen((online) {
      if (!online) return;
      if (_authPaused) return;
      unawaited(kick());
    });

    _authSub = _auth.authStateChanges.listen((authed) {
      if (!authed) return;
      if (!_authPaused) return;
      _authPaused = false;
      AppLogger.instance.info('sync_worker: auth restored → resume drain');
      unawaited(kick());
    });

    // Bootstrap: libera locks de runs anteriores que crashearon y dispara
    // un drain inicial.
    unawaited(() async {
      try {
        await _outbox.releaseStaleLocks(const Duration(seconds: 60));
        if (_connectivity.isOnline) {
          final pending = await _outbox.pendingCount();
          if (pending > 0) {
            unawaited(drain());
          }
        }
      } catch (e) {
        AppLogger.instance.warning('sync_worker.bootstrap_failed: $e');
      }
    }());
  }

  @override
  Future<void> kick() async {
    if (!_started || _stopped) return;
    if (_draining) return;
    if (_authPaused) return;
    if (!_connectivity.isOnline) return;
    await drain();
  }

  @override
  Future<void> drain() async {
    if (_draining || _stopped) return;
    if (_authPaused) return;
    _draining = true;
    _emit(const SyncDrainStarted());
    try {
      while (!_stopped) {
        if (_authPaused) break;
        if (!_connectivity.isOnline) break;
        final batch = await _outbox.peekReady(_clock.now(), limit: 1);
        if (batch.isEmpty) break;
        final m = batch.first;

        // Rate-limit por kind: si todavía no se cumple el min-interval
        // desde el último éxito de este kind, reagenda con backoff corto
        // y termina el drain (próximo tick lo retoma).
        final last = _lastSuccessByKind[m.kind];
        final minInt = _minInterval[m.kind];
        if (last != null && minInt != null) {
          final elapsed = _clock.now().difference(last);
          if (elapsed < minInt) {
            // Espera el resto del intervalo. No incrementa attempts.
            await Future<void>.delayed(minInt - elapsed);
          }
        }

        final lockToken = '${_clock.now().microsecondsSinceEpoch}'
            '-${_random.nextInt(1 << 32)}';
        final got = await _outbox.tryClaim(m.id, lockToken);
        if (!got) {
          // Otro worker se adelantó (no esperado con single-flight). Sale.
          break;
        }

        try {
          await _dispatch(m);
          _lastSuccessByKind[m.kind] = _clock.now();
          await _outbox.markSuccess(m.id);
          _emit(SyncMutationApplied(kind: m.kind, id: m.id));
        } on _DropException catch (drop) {
          await _outbox.markSuccess(m.id);
          _emit(SyncMutationDropped(
            kind: m.kind,
            id: m.id,
            reason: drop.reason,
          ));
        } on _AuthPausedException {
          // No incrementamos attempts; sólo liberamos el lock para que
          // cuando se reanude, el siguiente drain la tome igual.
          await _outbox.markFailure(
            m.id,
            'auth_paused',
            _clock.now(),
          );
          _authPaused = true;
          _emit(const SyncAuthPaused());
          break;
        } catch (e) {
          final next = _nextAttempt(m.attempts);
          await _outbox.markFailure(m.id, e.toString(), _clock.now().add(next));
          _emit(SyncMutationFailed(
            kind: m.kind,
            id: m.id,
            error: e.toString(),
            nextAttempt: next,
          ));
          // Backoff: terminamos el drain para no quemar la CPU; el próximo
          // kick (connectivity / nuevo enqueue) reintentará.
          break;
        }
      }
    } finally {
      _draining = false;
      final remaining = await _safePending();
      _emit(SyncDrainEnded(remaining: remaining));
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    await _connSub?.cancel();
    await _authSub?.cancel();
    _connSub = null;
    _authSub = null;
    if (!_eventsCtrl.isClosed) {
      await _eventsCtrl.close();
    }
  }

  // ─── Dispatcher ────────────────────────────────────────────────────────

  Future<void> _dispatch(PendingMutation m) async {
    try {
      switch (m.kind) {
        case MutationKind.insertSession:
          final userId = m.payload['user_id'] as String;
          final routineDayId = m.payload['routine_day_id'] as String;
          final sessionDate =
              DateTime.parse(m.payload['session_date'] as String);
          await _remote.startWorkoutForDay(userId, routineDayId, sessionDate);
          return;
        case MutationKind.upsertSetLog:
          final log = SetLog(
            id: m.payload['id'] as String?,
            sessionId: m.payload['session_id'] as String,
            exerciseId: m.payload['exercise_id'] as String,
            actualWeight: (m.payload['actual_weight'] as num).toDouble(),
            actualReps: (m.payload['actual_reps'] as num).toInt(),
            setIndex: (m.payload['set_index'] as num).toInt(),
            createdAt: m.payload['created_at'] != null
                ? DateTime.parse(m.payload['created_at'] as String)
                : null,
          );
          await _remote.saveSetLog(SetLogModel.fromEntity(log));
          return;
        case MutationKind.finalizeSession:
          final sessionId = m.payload['session_id'] as String;
          final coachingRaw =
              m.payload['coaching_analysis'] as List<dynamic>?;
          final coaching = coachingRaw
              ?.whereType<Map<String, dynamic>>()
              .map(CoachingAnalysis.fromJson)
              .toList();
          await _remote.finishWorkoutSession(
            sessionId,
            coachingAnalysis: coaching,
          );
          // Si hay coaching, lo aplicamos en local para que la UI reaccione.
          if (coaching != null && coaching.isNotEmpty) {
            await _local.applyCoachingForSession(sessionId, coaching);
          }
          return;
      }
    } on supabase.AuthException {
      throw const _AuthPausedException();
    } on supabase.PostgrestException catch (e) {
      // Drops por errores semánticos no-recuperables. Mantenemos los códigos
      // estándar de PostgREST (PGRST116 = no rows, 23505 = unique violation).
      if (e.code == '23505' && m.kind == MutationKind.insertSession) {
        throw const _DropException(_DropReason.sessionSuperseded);
      }
      if (e.code == 'PGRST116' || e.code == 'PGRST106') {
        throw const _DropException(_DropReason.notFound);
      }
      // Auth via PostgrestException (RLS).
      final code = e.code ?? '';
      if (code.startsWith('PGRST301') ||
          code == '42501' /* insufficient_privilege */) {
        throw const _AuthPausedException();
      }
      rethrow;
    } on core_ex.WorkoutFunctionException catch (e) {
      switch (e.code) {
        case 'UNAUTHORIZED':
          throw const _AuthPausedException();
        case 'NOT_FOUND_OR_ALREADY_COMPLETED':
        case 'NOT_FOUND_OR_COMPLETED':
        case 'SESSION_NOT_FOUND':
          throw const _DropException(_DropReason.notFound);
        case 'VALIDATION_ERROR':
        case 'INVALID_JSON':
        case 'COACHING_TOO_LARGE':
          throw const _DropException(_DropReason.validation);
        default:
          rethrow;
      }
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  Duration _nextAttempt(int attempts) {
    // attempts viene del estado previo (antes de incrementar).
    final pow2 = (1 << attempts.clamp(0, 9)).toDouble(); // hasta 2^9=512
    final base = (pow2 * 1000).clamp(1000, 5 * 60 * 1000);
    final jitter = 0.8 + _random.nextDouble() * 0.4; // 80..120%
    final ms = (base * jitter).round();
    return Duration(milliseconds: ms);
  }

  Future<int> _safePending() async {
    try {
      return await _outbox.pendingCount();
    } catch (_) {
      return -1;
    }
  }

  void _emit(SyncWorkerEvent e) {
    if (_eventsCtrl.isClosed) return;
    _eventsCtrl.add(e);
  }
}

class _DropException implements Exception {
  const _DropException(this.reason);
  final String reason;
}

class _AuthPausedException implements Exception {
  const _AuthPausedException();
}
