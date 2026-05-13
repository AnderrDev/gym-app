import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';

/// Helpers tipados para snackbars. Sustituye a `ScaffoldMessenger.of
/// (context).showSnackBar(SnackBar(...))` en `lib/features/`.
///
/// Usar la variante semántica que corresponda en lugar de inventar
/// background colors ad-hoc.
class AppSnackBar {
  AppSnackBar._();

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) => _show(
    context,
    message: message,
    background: AppColors.success,
    foreground: AppColors.background,
    duration: duration,
    icon: Icons.check_circle_outline_rounded,
  );

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) => _show(
    context,
    message: message,
    background: AppColors.error,
    foreground: AppColors.textPrimary,
    duration: duration,
    icon: Icons.error_outline_rounded,
  );

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) => _show(
    context,
    message: message,
    background: AppColors.surfaceHighlight,
    foreground: AppColors.textPrimary,
    duration: duration,
    icon: Icons.info_outline_rounded,
  );

  /// Misma duración que info pero icono y color de advertencia — para
  /// guardar contra acciones rechazadas suaves (input vacío, requisito
  /// previo, etc.) sin escalar a `error`.
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) => _show(
    context,
    message: message,
    background: AppColors.warning,
    foreground: AppColors.background,
    duration: duration,
    icon: Icons.warning_amber_rounded,
  );

  static void _show(
    BuildContext context, {
    required String message,
    required Color background,
    required Color foreground,
    required Duration duration,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          duration: duration,
          content: Row(
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
        ),
      );
  }
}
