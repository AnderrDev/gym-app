/// Literales UI repetidos a lo largo de la app. Centralizados aquí para evitar
/// strings dispersos y para preparar la migración a `.arb` / `AppLocalizations`
/// más adelante. Solo se incluyen los términos que aparecen 2+ veces.
class AppStrings {
  AppStrings._();

  // Unidades
  static const String kg = 'kg';
  static const String kgReps = 'kg·reps';

  // Visibilidad de rutinas
  static const String private = 'PRIVADA';
  static const String public = 'PÚBLICA';

  // Acciones primarias (CTAs)
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String delete = 'Eliminar';
  static const String finish = 'Finalizar';
  static const String continueLabel = 'Continuar';
  static const String discard = 'Descartar';
  static const String discardChanges = 'Descartar cambios';

  // Versiones uppercase para botones tipo "label"
  static const String saveUpper = 'GUARDAR';
  static const String cancelUpper = 'CANCELAR';
  static const String deleteUpper = 'ELIMINAR';
  static const String continueUpper = 'CONTINUAR';
  static const String finishAndSaveUpper = 'FINALIZAR Y GUARDAR';
}
