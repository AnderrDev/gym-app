import 'package:equatable/equatable.dart';

enum ActiveSessionWatcherStatus { idle, checking, detected, none, failure }

/// Snapshot suficiente para que el dashboard muestre el banner de sesión
/// activa y reanude vía deep-link a la rutina-day.
class ActiveSessionInfo extends Equatable {
  const ActiveSessionInfo({
    required this.sessionId,
    required this.userId,
    required this.routineDayId,
    required this.routineDayName,
    required this.sessionDate,
  });

  final String sessionId;
  final String userId;
  final String routineDayId;
  final String routineDayName;
  final DateTime sessionDate;

  @override
  List<Object?> get props => [
    sessionId,
    userId,
    routineDayId,
    routineDayName,
    sessionDate,
  ];
}

class ActiveSessionWatcherState extends Equatable {
  const ActiveSessionWatcherState({
    this.status = ActiveSessionWatcherStatus.idle,
    this.session,
    this.errorMessage,
  });

  final ActiveSessionWatcherStatus status;
  final ActiveSessionInfo? session;
  final String? errorMessage;

  bool get hasActiveSession =>
      status == ActiveSessionWatcherStatus.detected && session != null;

  ActiveSessionWatcherState copyWith({
    ActiveSessionWatcherStatus? status,
    ActiveSessionInfo? session,
    bool clearSession = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ActiveSessionWatcherState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage];
}
