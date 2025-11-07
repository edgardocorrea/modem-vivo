@echo off
REM Wrapper simples para iniciar.ps1
REM Evita problemas de encoding UTF-8 com caracteres especiais

cd /d "%~dp0"

echo Iniciando Modem VIVO Unlock Tool...
echo.

REM Executa o script PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0iniciar.ps1"

exit /b %errorlevel%