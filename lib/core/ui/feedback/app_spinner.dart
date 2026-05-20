import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';

/// Spinner único de la app. Wrap fino sobre [SpinKitFadingCircle] —
/// premium, neutro y universalmente reconocible como "cargando". Sin
/// gimmicks de gym (probamos un barbell-rep custom y se sentía raro).
///
/// Para overlay bloqueante con mensaje, usar [AppLoader.show]; este widget
/// es para mostrar inline en un `Center` cuando el contenido aún no llegó.
///
/// Usar siempre uno de los named constructors:
/// - [AppSpinner.small] → 20×20, inline (sheets, badges, dentro de imágenes).
/// - [AppSpinner.medium] → 36×36, default para dialogs y body de sheets.
/// - [AppSpinner.large] → 56×56, pantallas en blanco esperando datos.
class AppSpinner extends StatelessWidget {
  const AppSpinner({
    super.key,
    this.size = 36,
    this.color,
    this.semanticLabel = 'Cargando',
  });

  const AppSpinner.small({super.key, this.color, this.semanticLabel = 'Cargando'})
      : size = 20;

  const AppSpinner.medium({super.key, this.color, this.semanticLabel = 'Cargando'})
      : size = 36;

  const AppSpinner.large({super.key, this.color, this.semanticLabel = 'Cargando'})
      : size = 56;

  final double size;
  final Color? color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: SpinKitFadingCircle(
        size: size,
        color: color ?? AppColors.primary,
      ),
    );
  }
}
