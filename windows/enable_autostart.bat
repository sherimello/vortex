@echo off
REM Vortex Agent - Auto Start Registry Setup Script
REM This script sets up the application to run on Windows startup

setlocal enabledelayedexpansion

echo Creating registry entries for auto-start...

REM Get the application path
set "app_path=%~dp0vortex_agent.exe"

REM Create registry entry for startup
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "VortexAgent" /t REG_SZ /d "%app_path%" /f

if %errorlevel% equ 0 (
    echo.
    echo ✓ Auto-start configured successfully!
    echo Vortex Agent will launch on your next system startup.
) else (
    echo.
    echo ✗ Failed to configure auto-start.
    echo Please run this script as administrator.
)

pause
