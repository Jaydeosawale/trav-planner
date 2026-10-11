#!/usr/bin/env bash
set -euo pipefail
: "${API_BASE_URL:?Set API_BASE_URL to the Render backend URL including /api/v1}"
FLUTTER_VERSION=3.47.2
SDK_DIR="${TMPDIR:-/tmp}/trav-flutter-${FLUTTER_VERSION}"
if [ ! -x "$SDK_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK_DIR"
fi
export PATH="$SDK_DIR/bin:$PATH"
flutter config --no-analytics
flutter pub get
flutter build web --release --no-wasm-dry-run --dart-define=APP_ENV=production --dart-define="API_BASE_URL=$API_BASE_URL"
