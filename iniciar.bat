@echo off
REM ===========================================================
REM Inicia o script PowerShell principal (iniciar.ps1)
REM Compatível com UTF-8 e evita problemas de caminho/encoding
REM ===========================================================

cd /d "%~dp0"

echo.
echo Iniciando Modem VIVO - Modo Avançado ...
echo.

REM Executa o PowerShell com parâmetros seguros
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0iniciar.ps1"

REM Retorna o código de saída do PowerShell
exit /b %ERRORLEVEL%
