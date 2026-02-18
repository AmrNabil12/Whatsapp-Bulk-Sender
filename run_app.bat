@echo off
title WhatsApp Automator - Launcher
color 0A

:: ── Self-elevate to Administrator if not already ───────────────────
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    PowerShell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

echo ============================================================
echo   WhatsApp Automator - Windows Desktop Launcher
echo ============================================================
echo.

:: ── Check Python ────────────────────────────────────────────────────
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please install Python from https://python.org
    pause
    exit /b 1
)

:: ── Install Python dependencies ──────────────────────────────────────
echo [INFO] Checking Python dependencies...
pip install flask flask-cors colorama selenium webdriver-manager packaging setuptools -q

:: ── Create required directories ──────────────────────────────────────
if not exist "data" mkdir data
if not exist "logs" mkdir logs

:: ── Enable Developer Mode (required for Flutter Windows symlinks) ────
echo [INFO] Enabling Windows Developer Mode...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1" >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK]  Developer Mode enabled.
) else (
    echo [WARN] Could not enable Developer Mode automatically.
    echo        Please enable it manually:
    echo        Settings ^> Privacy ^& Security ^> Developer Mode ^> ON
)

:: ── Check Flutter ────────────────────────────────────────────────────
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH.
    echo Please install Flutter from https://flutter.dev
    pause
    exit /b 1
)

echo.
echo [INFO] Launching Flutter Windows app...
echo [INFO] The app will automatically start the Python API server.
echo [INFO] WhatsApp Web will open in Chrome. Scan QR code on first run.
echo.

cd /d "%~dp0whatsapp_automator_ui"
flutter run -d windows

pause
