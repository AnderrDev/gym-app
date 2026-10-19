import 'package:flutter/foundation.dart';

/// Índice de la pestaña visible del shell (`AppShellPage`). Las pestañas
/// viven en un `IndexedStack` y no se reconstruyen al volver a ellas: quien
/// necesite datos frescos al hacerse visible (p. ej. PROGRESO tras terminar
/// un entreno) escucha este notifier. Mismo patrón que `RoutineAssignmentBus`.
class ShellTabNotifier extends ValueNotifier<int> {
  ShellTabNotifier() : super(0);

  /// Orden de los `StatefulShellBranch` en `AppRouter`.
  static const progressTab = 2;
}
