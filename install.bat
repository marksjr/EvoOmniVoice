@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title EVO OMNIVOICE - Portable Installer
color 0B

set "BIN_DIR=%~dp0bin"
set "PYTHON_DIR=%BIN_DIR%\python"
set "FFMPEG_DIR=%BIN_DIR%\ffmpeg"
set "VENV_DIR=%~dp0venv"
set "REQUIRED_SPACE_GB=8"

:: Clear PY_CMD to avoid environment conflicts
set "PY_CMD="

echo.
echo ============================================================
echo           EVO OMNIVOICE - PORTABLE INSTALLER
echo ============================================================
echo.
echo This installer will automatically set up:
echo   - Python 3.11 (portable)
echo   - FFmpeg (audio processing)
echo   - Dependencies (PyTorch, OmniVoice, etc.)
echo.
echo Required space: approximately %REQUIRED_SPACE_GB% GB
echo.
pause

echo.
echo [STEP 1/5] Checking disk space...

:: Get drive letter for the current path
set "TARGET_DRIVE=%~d0"
set "DRIVE_LETTER=%TARGET_DRIVE:~0,1%"

:: Default to 999 to avoid blocking if detection fails
set "FREE_SPACE_GB=999"

:: Use a temporary PS1 file to avoid batch quote escaping hell
echo $d = '%DRIVE_LETTER%'; try { $f = (Get-PSDrive $d -ErrorAction SilentlyContinue).Free; if (-not $f) { $f = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($d):'" -ErrorAction SilentlyContinue).FreeSpace }; if ($f) { [math]::Floor($f / 1GB) } else { '999' } } catch { '999' } > check_space.ps1

for /f "delims=" %%i in ('powershell -ExecutionPolicy Bypass -File check_space.ps1 2^>^&1') do (
    set "RESULT=%%i"
    rem Check if the result is a valid number
    echo !RESULT! | findstr /r "^[0-9][0-9]*$" >nul
    if !errorlevel! equ 0 set "FREE_SPACE_GB=!RESULT!"
)
del check_space.ps1

echo [INFO] Detected free space: !FREE_SPACE_GB! GB (Required: %REQUIRED_SPACE_GB% GB)

:: Only block if we are CERTAIN space is low
if !FREE_SPACE_GB! LSS %REQUIRED_SPACE_GB% (
    echo.
    echo [ERROR] Insufficient disk space!
    echo Required: %REQUIRED_SPACE_GB% GB
    echo Available: !FREE_SPACE_GB! GB
    echo.
    echo Please free up space or edit this script to skip the check.
    pause
    exit /b 1
)

echo [OK] Disk space check passed.

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: 1. Check/Install Python
echo.
echo [STEP 2/5] Checking Python...

:: Check for system Python
python --version >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PY_VERSION=%%i
    echo [OK] System Python detected: !PY_VERSION!
    set "PY_CMD=python"
    goto :check_ffmpeg
)

:: Check for portable Python
if exist "%PYTHON_DIR%\python.exe" (
    echo [OK] Portable Python already installed.
    set "PY_CMD=%PYTHON_DIR%\python.exe"
    goto :check_ffmpeg
)

:: Download and install portable Python
echo [INFO] Python not found. Downloading portable version (3.11)...
echo.
echo  Downloading portable Python (25 MB)...

powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip' -OutFile 'python_portable.zip' -UseBasicParsing"

if not exist "python_portable.zip" (
    echo [ERROR] Failed to download Python. Check your internet connection.
    pause
    exit /b 1
)

echo  Extracting Python...
powershell -Command "Expand-Archive -Path 'python_portable.zip' -DestinationPath '%PYTHON_DIR%' -Force" >nul 2>&1

:: Validate Python was extracted successfully
if not exist "%PYTHON_DIR%\python.exe" (
    echo [ERROR] Failed to extract Python. ZIP file may be corrupted.
    del python_portable.zip
    pause
    exit /b 1
)

del python_portable.zip

echo  Configuring pip...
powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile '%PYTHON_DIR%\get-pip.py' -UseBasicParsing" >nul 2>&1

:: Validate get-pip.py was downloaded
if not exist "%PYTHON_DIR%\get-pip.py" (
    echo [ERROR] Failed to download pip installer. Check your internet connection.
    pause
    exit /b 1
)

"%PYTHON_DIR%\python.exe" "%PYTHON_DIR%\get-pip.py" --quiet
if !errorlevel! neq 0 (
    echo [ERROR] Failed to install pip!
    pause
    exit /b 1
)
del "%PYTHON_DIR%\get-pip.py"

:: Enable import site in ._pth file (works with any Python 3.x version)
powershell -Command "$pthFile = Get-ChildItem '%PYTHON_DIR%\python*._pth' | Select-Object -First 1; if ($pthFile) { (Get-Content $pthFile.FullName) -replace '#import site', 'import site' | Set-Content $pthFile.FullName }" >nul 2>&1

set "PY_CMD=%PYTHON_DIR%\python.exe"
echo [OK] Portable Python installed successfully!

:check_ffmpeg
:: 2. Check/Install FFmpeg
echo.
echo [STEP 3/5] Checking FFmpeg...

:: Check for system FFmpeg
ffmpeg -version >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] System FFmpeg detected.
    goto :setup_env
)

:: Check for local FFmpeg
if exist "%FFMPEG_DIR%\bin\ffmpeg.exe" (
    echo [OK] Portable FFmpeg already installed.
    set "PATH=%FFMPEG_DIR%\bin;%PATH%"
    goto :setup_env
)

:: Download and install FFmpeg
echo [INFO] FFmpeg not found. Downloading...
echo.
echo  Downloading FFmpeg (70 MB)...

powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -OutFile 'ffmpeg.zip' -UseBasicParsing"

if not exist "ffmpeg.zip" (
    echo [ERROR] Failed to download FFmpeg. Check your internet connection.
    echo [INFO] You can install FFmpeg manually or continue without it.
    :: Cleanup any partial downloads
    if exist "ffmpeg.zip" del /q "ffmpeg.zip"
    if exist "%BIN_DIR%\ffmpeg_temp" rmdir /s /q "%BIN_DIR%\ffmpeg_temp"
    pause
) else (
    echo  Extracting FFmpeg...
    if not exist "%BIN_DIR%\ffmpeg_temp" mkdir "%BIN_DIR%\ffmpeg_temp"
    powershell -Command "Expand-Archive -Path 'ffmpeg.zip' -DestinationPath '%BIN_DIR%\ffmpeg_temp' -Force" >nul 2>&1

    :: Validate FFmpeg extraction
    if not exist "%BIN_DIR%\ffmpeg_temp\ffmpeg-*" (
        echo [ERROR] Failed to extract FFmpeg. ZIP file may be corrupted.
        del /q "ffmpeg.zip"
        rmdir /s /q "%BIN_DIR%\ffmpeg_temp"
        pause
    ) else (
        for /d %%i in ("%BIN_DIR%\ffmpeg_temp\ffmpeg-*") do move "%%i" "%FFMPEG_DIR%" >nul 2>&1
        rmdir /s /q "%BIN_DIR%\ffmpeg_temp"
        del /q ffmpeg.zip
        set "PATH=%FFMPEG_DIR%\bin;%PATH%"
        echo [OK] Portable FFmpeg installed successfully!
    )
)

:setup_env
:: 3. Setup Virtual Environment
echo.
echo [STEP 4/5] Setting up virtual environment...

if not exist "%VENV_DIR%" (
    echo  Creating virtual environment...
    "%PY_CMD%" -m venv venv
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to create virtual environment!
        pause
        exit /b 1
    )
    echo [OK] Virtual environment created!
) else (
    echo [OK] Virtual environment already exists.
)

call venv\Scripts\activate.bat

:: 4. Install Dependencies
echo.
echo [STEP 5/5] Installing dependencies (this may take a few minutes)...
echo.

python -m pip install --upgrade pip --quiet

:: Detect GPU for PyTorch
where nvidia-smi >nul 2>&1
if not errorlevel 1 (
    echo [INFO] NVIDIA GPU detected. Installing CUDA version for faster performance...
    echo [INFO] Downloading PyTorch CUDA - please wait...
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121
) else (
    echo [INFO] No GPU detected. Installing CPU version...
    echo [INFO] Downloading PyTorch CPU - please wait...
    pip install torch torchaudio
)

echo.
echo [INFO] Installing dependencies and libraries...
pip install fastapi uvicorn omnivoice numpy soundfile python-multipart

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to install dependencies!
    echo Check your internet connection.
    pause
    exit /b 1
)

:: 5. Post-installation test
echo.
echo ============================================================
echo           POST-INSTALLATION TEST
echo ============================================================
echo.
echo Verifying installation...

call venv\Scripts\activate.bat

python -c "import torch; import omnivoice; import fastapi; import soundfile; print('OK')" 2>nul
if !errorlevel! equ 0 (
    echo [SUCCESS] All dependencies installed correctly!
) else (
    echo [ERROR] Dependency verification failed!
    echo.
    echo Try running install.bat again.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo           INSTALLATION COMPLETE!
echo ============================================================
echo.
echo Now run "start.bat" to launch the system.
echo.
echo On first run, the model will be downloaded automatically (~4-5 GB).
echo This may take a few minutes depending on your internet speed.
echo.
pause
