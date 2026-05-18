import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Estado de conectividad observable que el resto de la app puede consumir
/// sin depender directamente de `connectivity_plus`.
abstract class ConnectivityService {
  /// Stream broadcast deduplicado. Emite cada vez que el estado de
  /// conectividad cambia (true = online, false = offline).
  Stream<bool> get isOnline$;

  /// Último valor cacheado. Útil para decisiones síncronas (p.ej. decidir si
  /// intentar una llamada de red o ir directo al cache local).
  bool get isOnline;

  /// Fuerza una lectura puntual del estado actual (sin esperar al próximo
  /// evento). Actualiza el valor cacheado y, si cambió, lo publica al stream.
  Future<bool> checkNow();

  /// Cierra suscripciones internas. Llamar desde DI cuando se descarta el
  /// singleton (raro en producción, pero útil en tests).
  Future<void> dispose();
}

/// Implementación basada en `connectivity_plus` v6+.
///
/// Reglas:
/// - Estado inicial: `true` (asumimos online hasta que un evento lo dispute,
///   evitando falsos positivos de "modo offline" durante el bootstrap).
/// - Online si la lista de resultados contiene cualquiera de `wifi`,
///   `mobile`, `ethernet`, `vpn` u `other`. Offline si la lista está vacía o
///   sólo trae `none`/`bluetooth` (bluetooth solo no implica internet).
/// - Dedupe: el `StreamController.broadcast()` interno sólo publica cuando el
///   valor difiere del último emitido.
class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl(this._connectivity) {
    // Fire-and-forget: arranca el bootstrap (suscripción + checkNow inicial)
    // sin bloquear al caller. Cualquier error se silencia para no romper DI;
    // el caller siempre puede invocar `checkNow()` después.
    unawaited(_init());
  }

  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _disposed = false;

  @override
  Stream<bool> get isOnline$ => _controller.stream;

  @override
  bool get isOnline => _isOnline;

  Future<void> _init() async {
    _sub = _connectivity.onConnectivityChanged.listen(_handleResults);
    await checkNow();
  }

  @override
  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    return _handleResults(results);
  }

  /// Procesa una lista de [`ConnectivityResult`] y actualiza el estado
  /// cacheado. Devuelve el valor resultante (true = online).
  bool _handleResults(List<ConnectivityResult> results) {
    final next = _resolveOnline(results);
    if (next != _isOnline) {
      _isOnline = next;
      if (!_controller.isClosed) {
        _controller.add(next);
      }
    }
    return next;
  }

  static bool _resolveOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    for (final r in results) {
      switch (r) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.mobile:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.vpn:
        case ConnectivityResult.other:
        // `satellite` apareció en versiones recientes de `connectivity_plus`;
        // aparece junto a `mobile` en redes restringidas pero indica que sí
        // hay conectividad de datos, así que lo contamos como online.
        case ConnectivityResult.satellite:
          return true;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.none:
          continue;
      }
    }
    return false;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _sub?.cancel();
    _sub = null;
    await _controller.close();
  }
}
