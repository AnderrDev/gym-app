/// Formatea un peso en kg sin decimales espurios: `40` → "40",
/// `37.5` → "37.5". Evita el `toStringAsFixed(0)` que redondeaba 37.5 a
/// "38" y mostraba un objetivo distinto al real.
String formatWeight(double kg) =>
    kg % 1 == 0 ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

/// "60 kg" o "Peso corporal" cuando el peso es 0 (ejercicios sin carga):
/// "0 kg × 10" parecía un error.
String formatLoad(double kg) =>
    kg == 0 ? 'Peso corporal' : '${formatWeight(kg)} kg';
