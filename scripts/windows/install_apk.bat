@echo off
setlocal
rem Run from anywhere: work in the project root (two folders up).
cd /d "%~dp0..\.."

echo === Install the built APK on the connected phone (keeps reading history and notes) ===
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=adb"
if not exist "release\FOCUS-JESUS-local-arm64.apk" (echo [!] Run build_apk.bat first. & pause & exit /b 1)
rem -r replaces the installed app in place, so its data stays.
"%ADB%" install -r "release\FOCUS-JESUS-local-arm64.apk"
pause
