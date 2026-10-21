#!/usr/bin/env bash
# Build de Flutter Web en Netlify (la imagen no trae Flutter).
# Variables de entorno del sitio en Netlify: SUPABASE_URL y SUPABASE_ANON_KEY.
set -euo pipefail

: "${SUPABASE_URL:?Falta SUPABASE_URL en las variables de entorno de Netlify}"
: "${SUPABASE_ANON_KEY:?Falta SUPABASE_ANON_KEY en las variables de entorno de Netlify}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.38.9}"
FLUTTER_DIR="${HOME}/flutter-${FLUTTER_VERSION}"

if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  git clone --depth 1 --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi
export PATH="${FLUTTER_DIR}/bin:${PATH}"
flutter config --no-analytics >/dev/null
flutter --version

# `.env` es un asset de pubspec pero está gitignored: vacío basta, las
# credenciales llegan por --dart-define.
touch .env
flutter pub get
# `--wasm`: dart2wasm + skwasm donde hay WasmGC, main.dart.js como fallback.
flutter build web --release --wasm \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
