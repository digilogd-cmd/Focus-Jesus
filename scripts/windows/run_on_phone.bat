@echo off
setlocal
rem Run from anywhere: work in the project root (two folders up).
cd /d "%~dp0..\.."

echo === Run on a connected Android phone (USB debugging on) ===
call flutter devices
call flutter run --release
pause
