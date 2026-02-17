@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0manage_services.ps1"
pause
