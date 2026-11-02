@echo off
setlocal
rem Run from anywhere: work in the project root (two folders up).
cd /d "%~dp0..\.."

echo === FOCUS JESUS: first-time setup ===
where git >nul 2>nul || (echo [!] Git is not installed. See docs\LOCAL_SETUP.md step 1. & goto :fail)
where flutter >nul 2>nul || (echo [!] Flutter is not on PATH. See docs\LOCAL_SETUP.md step 2. & goto :fail)
call flutter --version || goto :fail
call flutter pub get || goto :fail
if exist "android\key.properties" (
  echo [ok] android\key.properties found: builds install as updates of the app on your phone.
) else (
  echo [!] android\key.properties is missing. Builds will work, but cannot update the app
  echo     already installed from the shared APKs. See docs\LOCAL_SETUP.md step 4.
)
call flutter doctor
echo.
echo Setup finished. Next: scripts\windows\run_on_phone.bat or build_apk.bat
pause
exit /b 0
:fail
echo Setup stopped.
pause
exit /b 1
