@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title OmniVoice - Instalador Portatil
color 0B

set "BIN_DIR=%~dp0bin"
set "PYTHON_DIR=%BIN_DIR%\python"
set "FFMPEG_DIR=%BIN_DIR%\ffmpeg"
set "VENV_DIR=%~dp0venv"
set "REQUIRED_SPACE_GB=8"

echo.
echo ============================================================
echo           OMNIVOICE - INSTALADOR PORTATIL
echo ============================================================
echo.
echo Este instalador vai configurar automaticamente:
echo   - Python 3.11 (portatil)
echo   - FFmpeg (processamento de audio)
echo   - Dependencias (PyTorch, OmniVoice, etc.)
echo.
echo Espaco necessario: aproximadamente %REQUIRED_SPACE_GB% GB
echo.
pause

echo.
echo [ETAPA 1/5] Verificando espaco em disco...

:: Check disk space using PowerShell
for /f "tokens=*" %%i in ('powershell -Command "(Get-Volume -DriveLetter '%~d0').SizeRemaining / 1GB"') do set FREE_SPACE=%%i

:: Round down to integer
for /f "tokens=1 delims=." %%i in ("!FREE_SPACE!") do set FREE_SPACE_INT=%%i

if !FREE_SPACE_INT! LSS %REQUIRED_SPACE_GB% (
    echo [ERRO] Espaco em disco insuficiente!
    echo.
    echo Espaco necessario: %REQUIRED_SPACE_GB% GB
    echo Espaco disponivel: !FREE_SPACE_INT! GB (aproximadamente)
    echo.
    echo Por favor, libere espaco em disco e tente novamente.
    echo.
    pause
    exit /b 1
)

echo [OK] Espaco em disco suficiente: !FREE_SPACE_INT! GB disponiveis

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: 1. Check/Install Python
echo.
echo [ETAPA 2/5] Verificando Python...

:: Check for system Python
python --version >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PY_VERSION=%%i
    echo [OK] Python do sistema detectado: !PY_VERSION!
    set "PY_CMD=python"
    goto :check_ffmpeg
)

:: Check for portable Python
if exist "%PYTHON_DIR%\python.exe" (
    echo [OK] Python portatil ja instalado.
    set "PY_CMD=%PYTHON_DIR%\python.exe"
    goto :check_ffmpeg
)

:: Download and install portable Python
echo [INFO] Python nao encontrado. Baixando versao portatil (3.11)...
echo.
echo  Baixando Python portatil (25 MB)...

powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip' -OutFile 'python_portable.zip' -UseBasicParsing"

if not exist "python_portable.zip" (
    echo [ERRO] Falha ao baixar Python. Verifique sua conexao com a internet.
    pause
    exit /b 1
)

echo  Extraindo Python...
powershell -Command "Expand-Archive -Path 'python_portable.zip' -DestinationPath '%PYTHON_DIR%' -Force" >nul 2>&1
del python_portable.zip

echo  Configurando pip...
powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile '%PYTHON_DIR%\get-pip.py' -UseBasicParsing" >nul 2>&1

"%PYTHON_DIR%\python.exe" "%PYTHON_DIR%\get-pip.py" --quiet 2>nul
del "%PYTHON_DIR%\get-pip.py"

:: Enable import site in ._pth file
powershell -Command "(Get-Content '%PYTHON_DIR%\python311._pth') -replace '#import site', 'import site' | Set-Content '%PYTHON_DIR%\python311._pth'" >nul 2>&1

set "PY_CMD=%PYTHON_DIR%\python.exe"
echo [OK] Python portatil instalado com sucesso!

:check_ffmpeg
:: 2. Check/Install FFmpeg
echo.
echo [ETAPA 3/5] Verificando FFmpeg...

:: Check for system FFmpeg
ffmpeg -version >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] FFmpeg do sistema detectado.
    goto :setup_env
)

:: Check for local FFmpeg
if exist "%FFMPEG_DIR%\bin\ffmpeg.exe" (
    echo [OK] FFmpeg portatil ja instalado.
    set "PATH=%FFMPEG_DIR%\bin;%PATH%"
    goto :setup_env
)

:: Download and install FFmpeg
echo [INFO] FFmpeg nao encontrado. Baixando...
echo.
echo  Baixando FFmpeg (70 MB)...

powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -OutFile 'ffmpeg.zip' -UseBasicParsing"

if not exist "ffmpeg.zip" (
    echo [ERRO] Falha ao baixar FFmpeg. Verifique sua conexao com a internet.
    echo [INFO] Voce pode instalar o FFmpeg manualmente ou continuar sem ele.
    pause
) else (
    echo  Extraindo FFmpeg...
    if not exist "%BIN_DIR%\ffmpeg_temp" mkdir "%BIN_DIR%\ffmpeg_temp"
    powershell -Command "Expand-Archive -Path 'ffmpeg.zip' -DestinationPath '%BIN_DIR%\ffmpeg_temp' -Force" >nul 2>&1
    
    for /d %%i in ("%BIN_DIR%\ffmpeg_temp\ffmpeg-*") do move "%%i" "%FFMPEG_DIR%" >nul 2>&1
    rmdir /s /q "%BIN_DIR%\ffmpeg_temp"
    del ffmpeg.zip
    set "PATH=%FFMPEG_DIR%\bin;%PATH%"
    echo [OK] FFmpeg portatil instalado com sucesso!
)

:setup_env
:: 3. Setup Virtual Environment
echo.
echo [ETAPA 4/5] Configurando ambiente virtual...

if not exist "%VENV_DIR%" (
    echo  Criando ambiente virtual...
    "%PY_CMD%" -m venv venv
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao criar ambiente virtual!
        pause
        exit /b 1
    )
    echo [OK] Ambiente virtual criado!
) else (
    echo [OK] Ambiente virtual ja existe.
)

call venv\Scripts\activate.bat

:: 4. Install Dependencies
echo.
echo [ETAPA 5/5] Instalando dependencias (isso pode demorar alguns minutos)...
echo.

python -m pip install --upgrade pip --quiet

:: Detect GPU for PyTorch
where nvidia-smi >nul 2>&1
if !errorlevel! equ 0 (
    echo [INFO] GPU NVIDIA detectada! Instalando versao CUDA para maior velocidade...
    echo  Baixando PyTorch CUDA (~2 GB) - aguarde...
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121
) else (
    echo [INFO] GPU nao detectada. Instalando versao CPU...
    echo  Baixando PyTorch CPU (~200 MB) - aguarde...
    pip install torch torchaudio
)

echo.
echo  Instalando OmniVoice e outras dependencias...
pip install fastapi uvicorn omnivoice numpy soundfile python-multipart

if !errorlevel! neq 0 (
    echo.
    echo [ERRO] Falha ao instalar dependencias!
    echo Verifique sua conexao com a internet.
    pause
    exit /b 1
)

:: 5. Post-installation test
echo.
echo ============================================================
echo           TESTE POS-INSTALACAO
echo ============================================================
echo.
echo Verificando instalacao...

call venv\Scripts\activate.bat

python -c "import torch; import omnivoice; import fastapi; import soundfile; print('OK')" 2>nul
if !errorlevel! equ 0 (
    echo [SUCESSO] Todas as dependencias foram instaladas corretamente!
) else (
    echo [ERRO] Falha na verificacao de dependencias!
    echo.
    echo Tente executar install.bat novamente.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo           INSTALACAO CONCLUIDA!
echo ============================================================
echo.
echo Agora execute "start.bat" para iniciar o sistema.
echo.
echo Na primeira vez, o modelo sera baixado automaticamente (~4-5 GB).
echo Isso pode demorar alguns minutos dependendo da sua internet.
echo.
pause
