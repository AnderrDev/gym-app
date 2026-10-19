import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Logger estructurado de la app. Capa fina sobre [Talker] para tener un punto
/// único de configuración, tests deterministas y un sink consistente para
/// [ErrorReporter] y [AppBlocObserver].
class AppLogger {
  AppLogger._(this._talker);

  static final AppLogger instance = AppLogger._(_buildTalker());

  final Talker _talker;

  Talker get talker => _talker;

  void info(String message) => _talker.info(message);

  void warning(String message) => _talker.warning(message);

  void debug(String message) => _talker.debug(message);

  void error(String message, [Object? error, StackTrace? stack]) =>
      _talker.error(message, error, stack);

  /// Reporta un error tipado, anotado con el origen (`flutter`, `platform`,
  /// `zone`, `bloc`, etc.).
  void handle(Object error, StackTrace? stack, String origin) {
    _talker.handle(error, stack, '[$origin] error no manejado');
  }

  static Talker _buildTalker() {
    return TalkerFlutter.init(
      settings: TalkerSettings(
        enabled: true,
        useConsoleLogs: kDebugMode,
        maxHistoryItems: 500,
      ),
    );
  }
}
