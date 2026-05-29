import 'package:equatable/equatable.dart';

abstract class ActiveSessionWatcherEvent extends Equatable {
  const ActiveSessionWatcherEvent();

  @override
  List<Object?> get props => const [];
}

/// Verifica si el usuario tiene una sesión activa en backend (al arrancar
/// el dashboard). Si la encuentra, emite estado `detected`.
class CheckActiveSession extends ActiveSessionWatcherEvent {
  const CheckActiveSession(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Limpia el estado watcher (cuando la sesión activa termina o se cancela).
class ClearActiveSession extends ActiveSessionWatcherEvent {
  const ClearActiveSession();
}
