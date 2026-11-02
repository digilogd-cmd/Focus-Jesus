@echo off
setlocal
rem Run from anywhere: work in the project root (two folders up).
cd /d "%~dp0..\.."

echo === Analyze, test and validate content ===
call flutter analyze || (pause & exit /b 1)
call flutter test || (pause & exit /b 1)
call dart run tool/validate_content.dart || (pause & exit /b 1)
echo All checks passed.
pause
