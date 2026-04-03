import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected async {
    // En Web, los sockets TCP no están permitidos por el browser.
    // hasInternetAccess puede colgarse indefinidamente. Asumimos conectado
    // y dejamos que las llamadas HTTP fallen si realmente no hay red.
    if (kIsWeb) return true;

    try {
      return await connectionChecker.hasInternetAccess
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }
}
