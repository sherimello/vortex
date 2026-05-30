@echo off
REM Vortex Agent - Build Script for Windows
REM This script automates the build process

setlocal enabledelayedexpansion

echo.
echo ========================================
echo Vortex Agent - Build Script
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ✗ Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

REM Show Flutter version
echo Checking Flutter installation...
flutter --version
echo.

REM Navigate to project directory
cd /d "%~dp0"

echo Cleaning previous build...
call flutter clean
if %errorlevel% neq 0 (
    echo ✗ Flutter clean failed
    pause
    exit /b 1
)

echo.
echo Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ✗ Flutter pub get failed
    pause
    exit /b 1
)

echo.
echo Building Windows Release...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo ✗ Build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✓ Build completed successfully!
echo ========================================
echo.
echo Output: build\windows\x64\runner\Release\vortex_agent.exe
echo.
echo Next steps:
echo 1. Run the executable to test
echo 2. Or copy it to Program Files for regular use
echo 3. Create a shortcut if desired
echo.

pause
