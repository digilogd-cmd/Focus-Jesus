#!/usr/bin/env bash
# Installs the release APK on a connected Android device/emulator, launches it,
# and checks that the process stays alive without a fatal crash.
#
# Exit codes: 0 = passed, 1 = failed, 2 = could not verify (no device).
#
# Usage: scripts/device_smoke.sh [device-serial]
# SMOKE_WAIT=<seconds> overrides the launch wait (default 8; slow emulators need more).
set -uo pipefail

cd "$(dirname "$0")/.."
if [[ -f /opt/sdk/env.sh ]]; then
  # shellcheck disable=SC1091
  source /opt/sdk/env.sh
fi

PACKAGE=com.focusjesus.story
APK=build/app/outputs/flutter-apk/app-release.apk

if ! command -v adb >/dev/null; then
  echo "UNVERIFIED: adb not found (install Android platform-tools)." >&2
  exit 2
fi
if [[ ! -f "$APK" ]]; then
  echo "FAILED: $APK missing — run scripts/verify.sh first." >&2
  exit 1
fi

SERIAL="${1:-$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')}"
if [[ -z "$SERIAL" ]]; then
  echo "UNVERIFIED: no Android device or emulator connected (adb devices is empty)." >&2
  adb devices >&2
  exit 2
fi
ADB=(adb -s "$SERIAL")
echo "Device: $SERIAL ($("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'), Android $("${ADB[@]}" shell getprop ro.build.version.release | tr -d '\r'), API $("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r'))"

echo "Installing $APK"
"${ADB[@]}" install -r "$APK" || { echo "FAILED: install" >&2; exit 1; }

"${ADB[@]}" logcat -c
echo "Launching $PACKAGE"
"${ADB[@]}" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null || {
  echo "FAILED: launch" >&2
  exit 1
}

WAIT="${SMOKE_WAIT:-8}"
sleep "$WAIT"
PID="$("${ADB[@]}" shell pidof "$PACKAGE" | tr -d '\r')"
mkdir -p build
LOG=build/device_smoke_logcat.txt
"${ADB[@]}" logcat -d > "$LOG"
"${ADB[@]}" exec-out screencap -p > build/device_smoke_launch.png 2>/dev/null || true

if [[ -z "$PID" ]]; then
  echo "FAILED: app process is not running ${WAIT}s after launch. See $LOG" >&2
  exit 1
fi
if grep -E "FATAL EXCEPTION|AndroidRuntime: .*$PACKAGE|Unhandled Exception" "$LOG" >/dev/null; then
  echo "FAILED: crash found in logcat. See $LOG" >&2
  grep -nE "FATAL EXCEPTION|Unhandled Exception" "$LOG" | head -20 >&2
  exit 1
fi

echo "PASSED: installed, launched (pid $PID), no fatal errors in logcat."
echo "Screenshot: build/device_smoke_launch.png, log: $LOG"
echo "Next: flutter test integration_test/app_test.dart -d $SERIAL"
