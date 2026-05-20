import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';

/// Wrappea una página con `Title`, que en web propaga al `<title>` de la
/// pestaña del browser. En mobile es no-op visual (el sistema operativo
/// usa el title del `MaterialApp`).
///
/// Convención de naming: `"<sección> — Smart Gym"`. Sección corta, sin
/// emoji, mayúscula inicial.
class TitledPage extends StatelessWidget {
  const TitledPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Title(
      title: '$title — Smart Gym',
      color: AppColors.primary,
      child: child,
    );
  }
}
