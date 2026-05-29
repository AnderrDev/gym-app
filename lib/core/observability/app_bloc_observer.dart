import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';

/// Observa transiciones, cambios y errores de todos los `Bloc`/`Cubit`.
///
/// Registrado en `main.dart` vía `Bloc.observer = AppBlocObserver()` antes de
/// `runApp`. Vuelca los eventos en [AppLogger], lo que permite verlos en la
/// pantalla de logs de debug sin acoplar la presentación al observador.
class AppBlocObserver extends BlocObserver {
  AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    AppLogger.instance.debug(
      '[bloc] ${bloc.runtimeType} ${change.currentState.runtimeType} -> '
      '${change.nextState.runtimeType}',
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    AppLogger.instance.debug(
      '[bloc] ${bloc.runtimeType} ${transition.event.runtimeType}: '
      '${transition.currentState.runtimeType} -> '
      '${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.instance.handle(error, stackTrace, 'bloc:${bloc.runtimeType}');
    super.onError(bloc, error, stackTrace);
  }
}
