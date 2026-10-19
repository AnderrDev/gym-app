import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Textos para el usuario a partir de errores de Supabase. Los `message` de
/// Supabase vienen en inglés y con detalle técnico ("Invalid login
/// credentials", "ClientException…"): se traducen por código y el original
/// queda sólo en logs.

const genericErrorMessage =
    'No se pudo completar la operación. Inténtalo de nuevo.';
const networkErrorMessage =
    'Sin conexión con el servidor. Revisa tu conexión e inténtalo de nuevo.';

String authErrorMessage(supabase.AuthException e) {
  if (e is supabase.AuthRetryableFetchException) return networkErrorMessage;
  switch (e.code) {
    case 'invalid_credentials':
      return 'Email o contraseña incorrectos.';
    case 'user_already_exists':
    case 'email_exists':
      return 'Ya existe una cuenta con ese email.';
    case 'email_not_confirmed':
      return 'Confirma tu email antes de iniciar sesión. Revisa tu correo.';
    case 'weak_password':
      return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
    case 'email_address_invalid':
    case 'validation_failed':
      return 'Revisa el email: no parece válido.';
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return 'Demasiados intentos. Espera unos minutos y vuelve a probar.';
    case 'signup_disabled':
      return 'El registro de nuevas cuentas está desactivado.';
    case 'same_password':
      return 'La nueva contraseña debe ser distinta de la actual.';
    case 'session_not_found':
    case 'session_expired':
    case 'refresh_token_not_found':
    case 'refresh_token_already_used':
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    case 'user_not_found':
      return 'No existe ninguna cuenta con ese email.';
  }
  // Versiones de GoTrue sin `code`: el mensaje más común.
  if (e.message.toLowerCase().contains('invalid login credentials')) {
    return 'Email o contraseña incorrectos.';
  }
  return genericErrorMessage;
}

String postgrestErrorMessage(supabase.PostgrestException e) {
  switch (e.code) {
    case 'PGRST116':
    case 'PGRST106':
      return 'No se encontró lo que buscabas. Puede que se haya borrado.';
    case '23505':
      return 'Eso ya existe.';
    case '23503':
      return 'El elemento relacionado ya no existe.';
    case '23514':
    case '22P02':
      return 'Hay datos no válidos. Revísalos e inténtalo de nuevo.';
    case '42501':
      return 'No tienes permiso para hacer esto.';
    case 'PGRST301':
    case 'PGRST303':
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
  }
  return genericErrorMessage;
}
