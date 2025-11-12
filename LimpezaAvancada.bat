@echo off
:: ============================================
:: Limpeza Avançada by EdyOne
:: Executa com privilégios de Administrador
:: ============================================

echo.
echo ================================================
echo   Limpeza Avancada do Windows by EdyOne
echo ================================================
echo.

:: Verifica se já está rodando como Admin
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Executando como Administrador...
    goto :ExecutarLimpeza
) else (
    echo [!] Solicitando privilegios de Administrador...
    echo.
    
    :: Solicita elevação e executa o script PowerShell
    powershell.exe -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:ExecutarLimpeza
echo.
echo [1/2] Iniciando script de limpeza...
echo.

:: Executa o script PowerShell local
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0LimpezaAvancada.ps1"

echo.
echo [2/2] Limpeza concluida!
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
exit