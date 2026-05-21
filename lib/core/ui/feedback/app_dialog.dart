import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';

/// Helpers para diálogos. Hoy ofrece `confirm()` para preguntas binarias.
/// Más variantes (alert, choice) se añaden si las features las piden.
class AppDialog {
  AppDialog._();

  /// Muestra un diálogo de confirmación. Devuelve `true` si el usuario
  /// confirma, `false`/`null` si cancela. Hace haptic medium al abrir.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    AppButtonVariant confirmVariant = AppButtonVariant.primary,
  }) {
    HapticFeedback.mediumImpact();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        title: Text(title),
        content: Text(message),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          AppButton(
            label: cancelLabel,
            onPressed: () => Navigator.pop(ctx, false),
            variant: AppButtonVariant.ghost,
            expand: false,
          ),
          AppButton(
            label: confirmLabel,
            onPressed: () => Navigator.pop(ctx, true),
            variant: confirmVariant,
            expand: false,
          ),
        ],
      ),
    );
  }
}
