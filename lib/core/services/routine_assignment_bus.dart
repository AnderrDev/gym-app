import 'package:flutter/foundation.dart';

/// Bus singleton para señalar que las asignaciones de rutinas
/// (`user_routines`) cambiaron y los consumidores deberían recargar.
///
/// Existe porque cada `GoRoute` crea su propia instancia de
/// `RoutineManagementBloc` (scope por ruta) y el `DashboardBloc` vive en
/// otra branch del shell — un `BlocListener` cross-route no resuelve el
/// provider. El productor llama [`bump`] tras un assign exitoso y los
/// consumidores escuchan vía `addListener`.
class RoutineAssignmentBus extends ChangeNotifier {
  void bump() => notifyListeners();
}
