import 'package:equatable/equatable.dart';

/// Eventos del [ProgressBloc].
///
/// Distinguimos `LoadProgress` (emite `Loading` antes del fetch) de
/// `RefreshProgress` (silencioso — para pull-to-refresh sin destruir la
/// UI ya pintada).
sealed class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => const [];
}

/// Carga inicial del hub. Emite `ProgressLoading` y luego `Ready/Failure`.
///
/// Si [weekStart] es `null`, el bloc lo calcula como el lunes de la
/// semana actual.
class LoadProgress extends ProgressEvent {
  const LoadProgress(this.userId, {this.weekStart});

  final String userId;
  final DateTime? weekStart;

  @override
  List<Object?> get props => [userId, weekStart];
}

/// Refresh silencioso (pull-to-refresh). NO emite `ProgressLoading` —
/// va directo a `ProgressReady` o `ProgressFailure`.
class RefreshProgress extends ProgressEvent {
  const RefreshProgress(this.userId, {this.weekStart});

  final String userId;
  final DateTime? weekStart;

  @override
  List<Object?> get props => [userId, weekStart];
}
