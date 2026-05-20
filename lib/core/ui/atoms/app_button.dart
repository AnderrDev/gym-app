import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

/// Variantes semánticas del botón. La paleta y radii vienen del tema, así
/// que solo necesitamos discriminar el rol (primary, secondary, ghost,
/// destructive) y el estado (loading).
enum AppButtonVariant { primary, secondary, ghost, destructive }

/// Botón único de la app. Sustituye a `KineticButton`/`ElevatedButton`/
/// `OutlinedButton` directos en `lib/features/`.
///
/// Props:
/// * `label` (siempre uppercase visualmente).
/// * `onPressed` — `null` ⇒ botón disabled.
/// * `isLoading` — muestra spinner y deshabilita el tap.
/// * `icon` — opcional, alineado a la izquierda del label.
/// * `expand` — `true` (default) ocupa todo el ancho disponible.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disabled = isLoading || onPressed == null;
    final child = _buildContent(context);
    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
      case AppButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onPrimary,
          ),
          child: child,
        );
        break;
    }
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      final colors = context.colors;
      // Spinner contrasta con el fondo segun variante: onPrimary sobre
      // primary/destructive (fills saturados), primary sobre secondary/ghost
      // (sin fill). Sin esto el spinner se funde con el fondo en la variante
      // primary (azul sobre azul = invisible).
      final spinnerColor =
          variant == AppButtonVariant.primary ||
              variant == AppButtonVariant.destructive
          ? colors.onPrimary
          : colors.primary;
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: spinnerColor,
        ),
      );
    }
    final text = Text(label.toUpperCase());
    if (icon == null) return text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 8), text],
    );
  }
}
