@echo off
setlocal
rem Run from anywhere: work in the project root (two folders up).
cd /d "%~dp0..\.."

echo === Build the arm64 APK ===
call flutter build apk --release --split-per-abi --target-platform android-arm64 || (pause & exit /b 1)
if not exist release mkdir release
copy /y "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "release\FOCUS-JESUS-local-arm64.apk" >nul
echo Built: %CD%\release\FOCUS-JESUS-local-arm64.apk
pause
