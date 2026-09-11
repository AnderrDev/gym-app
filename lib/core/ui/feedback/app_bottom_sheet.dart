import 'package:flutter/material.dart';

import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';

/// Wrapper legacy — la API canónica es [AdaptiveSheet].
///
/// Hace de bottom-sheet en mobile y de dialog centrado en web vía
/// [AdaptiveSheet] (que es el que conoce las capabilities). Este alias
/// existe solo para no romper los callers viejos; código nuevo debería
/// importar `core/ui/adaptive/adaptive_sheet.dart` directamente.
@Deprecated('Use AdaptiveSheet from core/ui/adaptive/adaptive_sheet.dart')
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool useSafeArea = true,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
  }) => AdaptiveSheet.show<T>(
    context,
    child: child,
    title: title,
    useSafeArea: useSafeArea,
    padding: padding,
    backgroundColor: backgroundColor,
  );

  static Future<T?> showRaw<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool useSafeArea = true,
  }) => AdaptiveSheet.showRaw<T>(
    context,
    builder: builder,
    useSafeArea: useSafeArea,
  );
}
