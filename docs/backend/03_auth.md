# 03 · Autenticación y perfil

Supabase Auth (GoTrue) con email + contraseña y flujo **PKCE**. No hay login
social.

## Operaciones

| Acción | Llamada | Detalles |
|---|---|---|
| Registro | `auth.signUp({email, password, options: {data: {full_name}}})` | `full_name` en metadata es **obligatorio en la práctica**: el trigger `handle_new_user` crea `profiles` con ese valor. Después, upsert best-effort de `profiles {id, full_name}` (falla por RLS si la confirmación de email está activa y no hay sesión; no importa, lo crea el trigger) |
| Login | `auth.signInWithPassword({email, password})` | Después: upsert best-effort de `profiles` desde `user_metadata.full_name` y lectura `profiles.select('id, full_name').eq('id', uid).maybeSingle()` |
| Usuario actual | `auth.getUser()` / sesión + lectura de `profiles` | Si falla la lectura del perfil, el usuario se usa sin nombre |
| Cambiar nombre | `profiles.update({full_name}).eq('id', uid).select('full_name').single()` y luego, best-effort, `auth.updateUser({data: {full_name}})` | |
| Cerrar sesión | `auth.signOut()` | Limpia estado local de usuario |
| Pedir reset | `auth.resetPasswordForEmail(email, {redirectTo})` | Anti-enumeración: responde OK aunque la cuenta no exista |
| Fijar contraseña nueva | `auth.updateUser({password})` | Requiere la sesión de recuperación |
| Eliminar cuenta | Edge `delete_account_v1` con `{"confirm":"ELIMINAR"}` | Ver [02_api.md](02_api.md#delete_account_v1) |

## Reset de contraseña (PKCE)

1. El cliente pide el correo con `redirectTo`:
   - web: `<origin>/reset-password` (hoy `https://gym-tracker-anderson.netlify.app/reset-password`)
   - móvil: `com.gymtracker.gymflutter://reset-password`
2. El enlace vuelve con `?code=…`; el SDK lo canjea (el *code verifier* está
   **solo** en el navegador/dispositivo que pidió el correo) y emite el evento
   `PASSWORD_RECOVERY` (`passwordRecovery` en Flutter).
3. La página `/reset-password` llama a `updateUser({password})`.

Requisitos en el dashboard (Auth → URL Configuration → Redirect URLs): **cada
`redirectTo` debe estar en la lista**, si no Supabase cae a la *Site URL* y el
canje PKCE falla.

Para la web nativa con supabase-js:
```ts
createClient(url, anonKey, { auth: { flowType: 'pkce', detectSessionInUrl: true, persistSession: true } })
supabase.auth.onAuthStateChange((event) => { if (event === 'PASSWORD_RECOVERY') router.push('/reset-password') })
```
y añadir `<nuevo-origen>/reset-password` (y `http://localhost:<puerto>/reset-password`
para desarrollo) a las Redirect URLs.

## Configuración que NO está en el repo

`supabase/config.toml` no tiene sección `[auth]`: Site URL, Redirect URLs,
confirmación de email, caducidad del JWT y SMTP viven **solo en el dashboard**.

Estado conocido (2026-10-21):
- Redirect URLs de web (Netlify), localhost y deep link móvil: configuradas.
- **Site URL sigue en `localhost`** → corregir antes de lanzar la web nativa
  (afecta a correos de confirmación y a cualquier `redirectTo` no listado).
- Si la confirmación de email está activa: desconocido desde el repo; comprobar
  en el dashboard (cambia el flujo de registro: `signUp` devuelve usuario sin sesión).

## Estado de auth en el cliente

El cliente Flutter traduce `onAuthStateChange` a "hay sesión / no hay sesión"
con los eventos `INITIAL_SESSION`, `SIGNED_IN`, `PASSWORD_RECOVERY`,
`USER_UPDATED`, `SIGNED_OUT` (ignora `TOKEN_REFRESHED`). Mientras el estado
inicial no se ha resuelto, el router no redirige (evita parpadeo login↔home).
Rutas: sin sesión → `/login`; con sesión, fuera de `/login`/registro;
`/reset-password` exenta en ambos sentidos.

## Mensajes de error de auth (por `AuthError.code`)

Traducción usada hoy (`lib/core/error/user_messages.dart`):
`invalid_credentials`, `user_already_exists`/`email_exists`,
`email_not_confirmed`, `weak_password`, `email_address_invalid`/`validation_failed`,
`over_email_send_rate_limit`/`over_request_rate_limit`, `signup_disabled`,
`same_password`, `session_*`/`refresh_token_*`, `user_not_found`. Reutilizar los
mismos textos en la web para coherencia.
