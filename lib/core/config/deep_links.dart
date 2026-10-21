/// Deep links propios de la app móvil (Android/iOS).
///
/// El esquema se declara también en `android/app/src/main/AndroidManifest.xml`
/// (`intent-filter` de `MainActivity`) e `ios/Runner/Info.plist`
/// (`CFBundleURLTypes`): si lo cambias aquí, cámbialo allí y en Supabase →
/// Auth → URL Configuration → Redirect URLs.
///
/// Quien consume el enlace es `supabase_flutter` (vía `app_links`): detecta
/// el `?code=` de PKCE, lo canjea por una sesión y emite el evento de auth
/// correspondiente. El deep linking de Flutter está desactivado en ambas
/// plataformas para que la URI no llegue también al `GoRouter`.
abstract final class DeepLinks {
  /// Esquema de URL propio (minúsculas, sin guion bajo: `_` no es válido en
  /// un esquema según RFC 3986).
  static const scheme = 'com.gymtracker.gymflutter';

  /// Host del enlace de recuperación de contraseña.
  static const resetPasswordHost = 'reset-password';

  /// `redirectTo` del email de recuperación en móvil.
  static const resetPassword = '$scheme://$resetPasswordHost';
}
