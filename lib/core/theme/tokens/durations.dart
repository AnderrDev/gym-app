/// Duraciones de animación de la app. Usar `AppDurations.*` en
/// `AnimatedSwitcher`/`AnimatedContainer`/`Tween` para mantener consistencia.
class AppDurations {
  AppDurations._();

  /// 150ms — micro-feedback (haptic, ripple, hover).
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms — defecto para transiciones de estado de UI.
  static const Duration medium = Duration(milliseconds: 250);

  /// 400ms — transiciones de página, hero, modales.
  static const Duration slow = Duration(milliseconds: 400);
}
