#!/usr/bin/env bash
# Full verification gate: dependencies → format → analyze → tests → content →
# release APK. Stops at the first failure with a non-zero exit code.
#
# Usage: scripts/verify.sh            (from anywhere inside the repo)
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ -f /opt/sdk/env.sh ]]; then
  # Cloud build environment only; locally Flutter is expected on PATH.
  # shellcheck disable=SC1091
  source /opt/sdk/env.sh
fi

step() { printf '\n\033[1m▶ %s\033[0m\n' "$*"; }

step "flutter --version"
flutter --version

step "flutter pub get"
flutter pub get

step "dart format (check only)"
dart format --output=none --set-exit-if-changed lib test integration_test test_screenshots tool

step "flutter analyze"
flutter analyze

step "flutter test (unit + widget)"
flutter test

step "content validation"
dart run tool/validate_content.dart

step "flutter build apk --release"
flutter build apk --release

APK=build/app/outputs/flutter-apk/app-release.apk
if [[ ! -f "$APK" ]]; then
  echo "Release APK not found at $APK" >&2
  exit 1
fi

step "release APK keeps the notification icon"
# The icon is referenced only by name from Dart, so the resource shrinker
# removes it unless res/raw/keep.xml protects it. Without it every reminder
# silently fails (this shipped broken in 1.0.0–1.1.0).
AAPT2="$(ls -d "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/opt/sdk/android-sdk}}"/build-tools/* 2>/dev/null | sort -V | tail -1)/aapt2"
if [[ -x "$AAPT2" ]]; then
  # Dump first: piping into `grep -q` would SIGPIPE aapt2 and, under
  # pipefail, report a present icon as missing.
  RESOURCES="$("$AAPT2" dump resources "$APK")"
  if ! grep -q "drawable/ic_stat_notify" <<<"$RESOURCES"; then
    echo "drawable/ic_stat_notify missing from $APK" >&2
    exit 1
  fi
  echo "drawable/ic_stat_notify present"
else
  echo "aapt2 not found; skipped" >&2
fi

step "release APK"
ls -l "$APK"
sha256sum "$APK"
echo
echo "verify.sh: all checks passed."
