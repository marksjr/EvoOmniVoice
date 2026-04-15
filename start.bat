@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Evo OmniVoice - Iniciar
color 0A

set "BIN_DIR=%~dp0bin"
set "FFMPEG_DIR=%BIN_DIR%\ffmpeg"
set "VENV_DIR=%~dp0venv"
set "INDEX_FILE=%~dp0index.html"
set "SERVER_PORT=8081"

echo.
echo ============================================================
echo           EVO OMNIVOICE - SISTEMA PORTATIL
echo ============================================================
echo.

:: Verificar se está instalado
if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo [ERRO] Sistema nao instalado!
    echo Por favor, execute "install.bat" primeiro.
    echo.
    pause
    exit /b 1
)

:: Adicionar FFmpeg local ao PATH se existir
if exist "%FFMPEG_DIR%\bin" (
    set "PATH=%FFMPEG_DIR%\bin;%PATH%"
)

:: Ativar ambiente virtual
call "%VENV_DIR%\Scripts\activate.bat"

:: Verificação de Hardware
echo [STATUS] Verificando hardware...
python -c "import torch; print('[HW] GPU Detectada: ' + torch.cuda.get_device_name(0)) if torch.cuda.is_available() else print('[HW] AVISO: GPU NAO DETECTADA (Usando CPU)')"
echo.

:: Iniciar servidor FastAPI em janela separada
echo [INFO] Iniciando servidor FastAPI...
start "Evo OmniVoice Server" cmd /c "call venv\Scripts\activate.bat && python server.py"

:: Aguardar servidor estar pronto
echo [INFO] Aguardando servidor carregar modelos na GPU...
echo.

:wait_loop
powershell -Command "$ErrorActionPreference = 'SilentlyContinue'; $tcpc = New-Object System.Net.Sockets.TcpClient; $tcpc.Connect('localhost', %SERVER_PORT%); if ($tcpc.Connected) { $tcpc.Close(); exit 0 } else { exit 1 }"
if !errorlevel! equ 0 (
    echo [SUCESSO] Servidor esta pronto!
    goto :ready
)
timeout /t 2 /nobreak >nul
goto :wait_loop

:ready
:: Abrir arquivo index.html local
echo [INFO] Abrindo interface local...
start "" "%INDEX_FILE%"
echo.
echo ============================================================
echo           EVO OMNIVOICE ESTA EM EXECUCAO
echo ============================================================
echo.
echo Nao feche esta janela! O servidor esta rodando em segundo plano.
echo Para parar o sistema, feche a janela "Evo OmniVoice Server".
echo.
pause
