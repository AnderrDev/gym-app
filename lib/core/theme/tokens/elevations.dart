/// Niveles de elevación expresados como sombra (no Material elevation
/// numérico) — el dark theme usa overlays sutiles, no luz dura.
class Elevations {
  Elevations._();

  /// Sin sombra.
  static const double none = 0;

  /// Cards en reposo.
  static const double card = 1;

  /// Bottom sheets, dialogs.
  static const double overlay = 8;

  /// Floating action buttons.
  static const double fab = 6;
}
