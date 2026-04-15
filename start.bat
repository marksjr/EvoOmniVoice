@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title EVO OMNIVOICE - Start
color 0B

set "BIN_DIR=%~dp0bin"
set "FFMPEG_DIR=%BIN_DIR%\ffmpeg"
set "VENV_DIR=%~dp0venv"
set "INDEX_FILE=%~dp0index.html"
set "SERVER_PORT=8081"

echo.
echo ============================================================
echo           EVO OMNIVOICE - PORTABLE SYSTEM
echo ============================================================
echo.

:: Check if installed
if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo [ERROR] System not installed!
    echo Please run "install.bat" first.
    echo.
    pause
    exit /b 1
)

:: Add local FFmpeg to PATH if it exists
if exist "%FFMPEG_DIR%\bin" (
    set "PATH=%FFMPEG_DIR%\bin;%PATH%"
)

:: Activate virtual environment
call "%VENV_DIR%\Scripts\activate.bat"

:: Hardware check
echo [STATUS] Checking hardware...
python -c "import torch; print('[HW] GPU Detected: ' + torch.cuda.get_device_name(0)) if torch.cuda.is_available() else print('[HW] WARNING: NO GPU DETECTED (Using CPU)')"
echo.

:: Start FastAPI server in separate window
echo [INFO] Starting FastAPI server...
start "EVO OMNIVOICE Server" cmd /c "cd /d "%~dp0" && call venv\Scripts\activate.bat && python server.py"

:: Wait for server to be ready
echo [INFO] Waiting for server to load models on GPU...
echo.

:wait_loop
powershell -Command "$ErrorActionPreference = 'SilentlyContinue'; $tcpc = New-Object System.Net.Sockets.TcpClient; $tcpc.Connect('localhost', %SERVER_PORT%); if ($tcpc.Connected) { $tcpc.Close(); exit 0 } else { exit 1 }"
if !errorlevel! equ 0 (
    echo [SUCCESS] Server is ready!
    goto :ready
)
timeout /t 2 /nobreak >nul
goto :wait_loop

:ready
:: Open local index.html
echo [INFO] Opening local interface...
start "" "%INDEX_FILE%"
echo.
echo ============================================================
echo           EVO OMNIVOICE IS RUNNING
echo ============================================================
echo.
echo Do not close this window! The server is running in the background.
echo To stop the system, close the "EVO OMNIVOICE Server" window.
echo.
pause
