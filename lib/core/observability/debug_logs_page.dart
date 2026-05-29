import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';

/// Pantalla de logs estructurados expuesta solo en builds no-release.
///
/// Reutiliza el [Talker] singleton de [AppLogger], por lo que muestra todo lo
/// emitido por [AppBlocObserver] y [ErrorReporter] sin requerir cableado extra.
class DebugLogsPage extends StatelessWidget {
  const DebugLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('Logs no disponibles en release')),
      );
    }
    return TalkerScreen(talker: AppLogger.instance.talker);
  }
}
