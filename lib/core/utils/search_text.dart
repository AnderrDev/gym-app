/// Normaliza texto para búsquedas tolerantes: minúsculas y sin tildes, para
/// que "press banca" encuentre "Press Banca" y "biceps" encuentre "Bíceps".
String normalizeForSearch(String text) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñç';
  const to = 'aaaaeeeeiiiioooouuuunc';
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final i = from.indexOf(char);
    buffer.write(i >= 0 ? to[i] : char);
  }
  return buffer.toString().trim();
}
