@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Diagnose.ps1" %*
exit /b %errorlevel%
