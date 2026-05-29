import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/sync/connectivity_service.dart';
import 'package:gym_flutter/core/sync/outbox_repository.dart';
import 'package:gym_flutter/core/sync/sync_worker.dart';

/// Estado consolidado para el badge de sync (esquina del AppBar / shell).
///
/// Tres dimensiones independientes:
/// - [isOnline]: conectividad efectiva.
/// - [pending]: items en la outbox a sincronizar.
/// - [draining]: el SyncWorker está activamente trabajando un batch.
class SyncStatusState extends Equatable {
  const SyncStatusState({
    this.isOnline = true,
    this.pending = 0,
    this.draining = false,
  });

  final bool isOnline;
  final int pending;
  final bool draining;

  SyncStatusState copyWith({
    bool? isOnline,
    int? pending,
    bool? draining,
  }) {
    return SyncStatusState(
      isOnline: isOnline ?? this.isOnline,
      pending: pending ?? this.pending,
      draining: draining ?? this.draining,
    );
  }

  @override
  List<Object?> get props => [isOnline, pending, draining];
}

/// Eventos internos del bloc. Se exponen `sealed` para que cualquier
/// listener externo pueda matchear exhaustivamente; en la práctica solo el
/// propio bloc los enqueua (vía subscriptions).
sealed class _SyncStatusEvent {
  const _SyncStatusEvent();
}

class _OnlineChanged extends _SyncStatusEvent {
  const _OnlineChanged(this.value);
  final bool value;
}

class _PendingChanged extends _SyncStatusEvent {
  const _PendingChanged(this.value);
  final int value;
}

class _DrainingChanged extends _SyncStatusEvent {
  const _DrainingChanged(this.value);
  final bool value;
}

class SyncStatusBloc extends Bloc<_SyncStatusEvent, SyncStatusState> {
  SyncStatusBloc({
    required ConnectivityService connectivity,
    required OutboxRepository outbox,
    required SyncWorker syncWorker,
  })  : _connectivity = connectivity,
        _outbox = outbox,
        _syncWorker = syncWorker,
        super(SyncStatusState(isOnline: connectivity.isOnline)) {
    on<_OnlineChanged>(
      (e, emit) => emit(state.copyWith(isOnline: e.value)),
    );
    on<_PendingChanged>(
      (e, emit) => emit(state.copyWith(pending: e.value)),
    );
    on<_DrainingChanged>(
      (e, emit) => emit(state.copyWith(draining: e.value)),
    );

    _connSub = _connectivity.isOnline$.listen(
      (v) => add(_OnlineChanged(v)),
    );
    _pendingSub = _outbox.watchPendingCount().listen(
          (v) => add(_PendingChanged(v)),
        );
    _eventsSub = _syncWorker.events$.listen((ev) {
      if (ev is SyncDrainStarted) {
        add(const _DrainingChanged(true));
      } else if (ev is SyncDrainEnded) {
        add(const _DrainingChanged(false));
      }
    });
  }

  final ConnectivityService _connectivity;
  final OutboxRepository _outbox;
  final SyncWorker _syncWorker;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<int>? _pendingSub;
  StreamSubscription<SyncWorkerEvent>? _eventsSub;

  @override
  Future<void> close() async {
    await _connSub?.cancel();
    await _pendingSub?.cancel();
    await _eventsSub?.cancel();
    return super.close();
  }
}
