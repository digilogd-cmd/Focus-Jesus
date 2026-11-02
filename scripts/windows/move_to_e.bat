@echo off
rem Moves FOCUS JESUS from C: to E:\claude (see move_to_e.ps1).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0move_to_e.ps1"
pause
