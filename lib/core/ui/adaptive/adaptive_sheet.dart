import 'package:flutter/material.dart';

import 'package:gym_flutter/core/platform/capabilities.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';

/// Modal adaptativo — `BottomSheet` en mobile, `Dialog` centrado en web.
///
/// Mobile: `showModalBottomSheet`, scroll-controlado, respeta `viewInsets`
/// (teclado), drag handle visible.
/// Web/desktop: `showDialog`, centrado vertical, constrained a un ancho
/// cómodo de lectura para evitar que el contenido se estire ocupando
/// toda la ventana.
///
/// Reemplaza a `AppBottomSheet` como API canónica. El comportamiento se
/// decide internamente vía [Capabilities.prefersBottomSheetForModals]; el
/// call site no se entera.
class AdaptiveSheet {
  AdaptiveSheet._();

  /// Modal con chrome estándar: drag-handle (mobile) / título (web),
  /// padding interno y scroll. Si el contenido es complejo y necesita
  /// su propio chrome, usar [showRaw].
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool useSafeArea = true,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
  }) {
    if (Capabilities.prefersBottomSheetForModals) {
      return _showBottomSheet<T>(
        context,
        builder: (ctx) => _ChromedContainer(
          title: title,
          padding: padding,
          backgroundColor: backgroundColor,
          isDialog: false,
          child: child,
        ),
      );
    }
    return _showCenteredDialog<T>(
      context,
      backgroundColor: backgroundColor,
      builder: (ctx) => _ChromedContainer(
        title: title,
        padding: padding,
        backgroundColor: backgroundColor,
        isDialog: true,
        child: child,
      ),
    );
  }

  /// Modal sin chrome — el `child` controla su propio layout (header,
  /// fondo, handle si lo quiere). Se sigue ocupando del padding del
  /// teclado en mobile y de las constraints de ancho en web.
  static Future<T?> showRaw<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool useSafeArea = true,
  }) {
    if (Capabilities.prefersBottomSheetForModals) {
      return _showBottomSheet<T>(
        context,
        builder: builder,
        useSafeArea: useSafeArea,
      );
    }
    return _showCenteredDialog<T>(context, builder: builder);
  }

  // ── Internals ─────────────────────────────────────────────────────────

  static Future<T?> _showBottomSheet<T>(
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

  static Future<T?> _showCenteredDialog<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color? backgroundColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: context.colors.overlay,
      builder: (ctx) => Dialog(
        backgroundColor: backgroundColor ?? Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        clipBehavior: Clip.antiAlias,
        // Ancho confortable de lectura en desktop sin estirar a la ventana
        // entera. En móvil-web (viewport angosto) el `min()` cae al
        // viewport menos el inset.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: builder(ctx),
          ),
        ),
      ),
    );
  }
}

/// Contenedor de chrome compartido (header + padding). Su layout varía
/// ligeramente entre dialog y bottom-sheet: el bottom-sheet muestra
/// drag-handle arriba, el dialog muestra solo el title row.
class _ChromedContainer extends StatelessWidget {
  const _ChromedContainer({
    required this.child,
    required this.isDialog,
    this.title,
    this.padding,
    this.backgroundColor,
  });

  final Widget child;
  final bool isDialog;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final radius = isDialog
        ? const BorderRadius.all(Radius.circular(Radii.xxl))
        : const BorderRadius.vertical(top: Radius.circular(Radii.xxl));
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: radius,
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
            if (!isDialog) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
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
