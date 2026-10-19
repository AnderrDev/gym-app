import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';

/// Overlay de loading bloqueante. Sustituye los `CircularProgressIndicator`
/// directamente colgados en mitad de la pantalla cuando el usuario disparó
/// una acción que necesita feedback inmediato (login, finalize, save).
///
/// Se monta como un `Dialog` modal y se descarta llamando a [hide].
class AppLoader {
  AppLoader._();

  static bool _showing = false;

  /// Abre el overlay. Si ya hay uno visible, no hace nada.
  static void show(BuildContext context, {String? message}) {
    if (_showing) return;
    _showing = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: context.colors.overlay,
      builder: (_) => _LoaderDialog(message: message),
    );
  }

  /// Cierra el overlay si está visible.
  static void hide(BuildContext context) {
    if (!_showing) return;
    _showing = false;
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class _LoaderDialog extends StatelessWidget {
  const _LoaderDialog({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSpinner.medium(),
            if (message != null) ...[
              const SizedBox(height: Spacing.md),
              Text(message!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
