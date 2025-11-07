@echo off
REM Um meio simples para iniciar.ps1 
REM Evita problemas de encoding UTF-8 com caracteres especiais

cd /d "%~dp0"

echo Iniciando Modem VIVO Modo avançado...
echo.

REM Executa o script PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0iniciar.ps1"

exit /b %errorlevel%