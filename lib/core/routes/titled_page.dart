import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Wrappea una página con:
///   1. `Title` — en web propaga al `<title>` de la pestaña del browser.
///      En mobile es no-op visual (el OS usa el title del MaterialApp).
///   2. `SelectionArea` — habilita selección de texto en web sobre
///      cualquier `Text` descendiente. Vive acá (no en `MaterialApp.builder`)
///      porque SelectionArea requiere un `Overlay` ancestor; al estar
///      dentro de un route builder está siempre dentro del Navigator
///      de la app.
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
      color: context.colors.primary,
      child: SelectionArea(child: child),
    );
  }
}
