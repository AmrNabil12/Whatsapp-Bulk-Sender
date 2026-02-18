@echo off
title WhatsApp Automator - API Server
color 0A

echo ============================================================
echo   WhatsApp Automator - Python API Server
echo ============================================================
echo.

:: Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please install Python from https://python.org
    pause
    exit /b 1
)

:: Check if we're in the right directory
if not exist "api_server.py" (
    echo [ERROR] api_server.py not found.
    echo Please run this from the Whatsapp-Automator-main directory.
    pause
    exit /b 1
)

:: Install dependencies if needed
echo [INFO] Checking Python dependencies...
pip install flask flask-cors colorama selenium webdriver-manager packaging setuptools -q

:: Create data and logs directories if they don't exist
if not exist "data" mkdir data
if not exist "logs" mkdir logs

echo.
echo [INFO] Starting API server on http://localhost:5000
echo [INFO] Keep this window open while using the Flutter app.
echo [INFO] Press Ctrl+C to stop the server.
echo.

python api_server.py

pause
