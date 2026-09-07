@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Performance Test.ps1"
exit /b %errorlevel%
