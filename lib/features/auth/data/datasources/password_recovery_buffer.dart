import 'dart:async';

import 'package:gym_flutter/core/observability/app_logger.dart';

/// Retiene un evento de recuperación de contraseña hasta que alguien lo
/// escuche.
///
/// Por qué existe: en arranque en frío desde el deep link, `supabase_flutter`
/// canjea el code PKCE y emite `passwordRecovery` mientras `main()` todavía
/// está inicializando DI/notificaciones, antes de que `AppRouter` se
/// suscriba. `onAuthStateChange` es un `BehaviorSubject` y repite el último
/// evento, pero si después llega otro (p. ej. `tokenRefreshed` de
/// `recoverSession()`) el de recovery se pierde y el usuario aterrizaría en
/// el dashboard en vez de en la pantalla de contraseña nueva.
///
/// Semántica:
/// - Si llega un evento y hay oyentes, se les entrega y no queda pendiente.
/// - Si llega sin oyentes, queda pendiente y se entrega al primer oyente que
///   se suscriba a [events] (solo a ese: un enlace = una navegación).
class PasswordRecoveryBuffer {
  PasswordRecoveryBuffer(Stream<void> source) {
    _subscription = source.listen(
      (_) => _onRecovery(),
      // Errores del stream de auth (p. ej. enlace caducado al canjear el
      // code): no son eventos de recovery y no deben tumbar la suscripción.
      onError: (Object e) =>
          AppLogger.instance.warning('passwordRecovery stream error: $e'),
    );
  }

  late final StreamSubscription<void> _subscription;
  final _controller = StreamController<void>.broadcast();
  bool _pending = false;

  /// `true` si hay un evento de recovery que nadie ha recibido todavía.
  bool get hasPending => _pending;

  void _onRecovery() {
    if (_controller.hasListener) {
      _controller.add(null);
    } else {
      _pending = true;
    }
  }

  /// Eventos de recovery. Al suscribirse se recibe primero el pendiente (si
  /// lo hay) y luego los nuevos.
  Stream<void> get events => Stream<void>.multi((listener) {
    final sub = _controller.stream.listen(listener.add, onDone: listener.close);
    listener.onCancel = sub.cancel;
    if (_pending) {
      _pending = false;
      listener.add(null);
    }
  });

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
