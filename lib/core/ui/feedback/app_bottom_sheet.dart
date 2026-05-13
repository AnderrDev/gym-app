import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Helper único para abrir bottom sheets. Sustituye los `showModalBottomSheet`
/// directos en `lib/features/`. Los detalles de presentación
/// (transparencia, radius, padding del teclado, scroll controlado) están
/// centralizados aquí.
class AppBottomSheet {
  AppBottomSheet._();

  /// Bottom sheet "padding-aware" (el viewInsets del teclado se respeta) y
  /// scroll-controlled. Si pasás `title` se renderiza un header con drag
  /// handle y close button.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool useSafeArea = true,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: useSafeArea,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AppBottomSheetContainer(
          title: title,
          padding: padding,
          backgroundColor: backgroundColor,
          child: child,
        ),
      ),
    );
  }

  /// Bottom sheet "raw": solo se encarga del scroll controlado y el padding
  /// del teclado. El `child` pinta su propio chrome (handle, header, fondos).
  /// Usar cuando el contenido ya tiene un layout custom rico (ej: summary).
  static Future<T?> showRaw<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: useSafeArea,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: builder(ctx),
      ),
    );
  }
}

class _AppBottomSheetContainer extends StatelessWidget {
  const _AppBottomSheetContainer({
    required this.child,
    this.title,
    this.padding,
    this.backgroundColor,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.xxl),
        ),
      ),
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.md,
            Spacing.xl,
            Spacing.xl,
          ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  Expanded(child: Text(title!, style: textTheme.headlineSmall)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Spacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
