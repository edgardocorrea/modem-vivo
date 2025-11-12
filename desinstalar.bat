@echo off
REM Este arquivo apenas inicia o script de desinstalação com privilégios de administrador.
REM A lógica de copiar e executar de outro lugar está dentro do script .ps1

powershell.exe -ExecutionPolicy Bypass -File "desinstalar.ps1"

REM Se o script pedir para reiniciar, o .bat fecha e o novo processo tomará conta.
REM Se falhar, a janela ficará aberta para o usuário ver o erro.
pause