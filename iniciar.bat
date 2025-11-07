@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ==================== CONFIGURAÇÕES ====================
set VARS_FILE=vars.js
set NODE_MIN_VERSION=20

REM ==================== CORES ====================
set COLOR_SUCCESS=0A
set COLOR_ERROR=0C
set COLOR_WARNING=0E
set COLOR_INFO=0B

REM ==================== BANNER ====================
cls
color %COLOR_INFO%
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║   █▀▄▀█ █▀█ █▀▄ █▀▀ █▀▄▀█   █░█ █ █░█ █▀█                ║
echo ║   █░▀░█ █▄█ █▄▀ ██▄ █░▀░█   ▀▄▀ █ ▀▄▀ █▄█                ║
echo ║                                                            ║
echo ║              Modem VIVO - Unlock Tool                      ║
echo ║          Askey RTF8115VW REV5 - Automação                  ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo [INFO] Iniciando verificações do sistema...
echo.

REM ==================== VERIFICAÇÃO 1: ARQUIVO VARS.JS ====================
echo [1/5] Verificando arquivo de configuração...

if not exist "%VARS_FILE%" (
    color %COLOR_ERROR%
    echo.
    echo [ERRO] Arquivo %VARS_FILE% não encontrado!
    echo.
    echo Verifique se você está na pasta correta do projeto.
    echo Caminho atual: %CD%
    echo.
    pause
    exit /b 1
)

echo [OK] Arquivo vars.js encontrado
echo.

REM ==================== VERIFICAÇÃO 2: NODE.JS ====================
echo [2/5] Verificando Node.js...

where node >nul 2>&1
if errorlevel 1 (
    color %COLOR_ERROR%
    echo.
    echo [ERRO] Node.js não encontrado!
    echo.
    echo Instale o Node.js v%NODE_MIN_VERSION% (LTS) em:
    echo https://nodejs.org/
    echo.
    pause
    exit /b 1
)

for /f "tokens=1 delims=v" %%V in ('node --version') do set NODE_VERSION=%%V
echo [OK] Node.js instalado: v%NODE_VERSION%
echo.

REM ==================== VERIFICAÇÃO 3: CHROME ====================
echo [3/5] Verificando Google Chrome...

set CHROME_FOUND=0
set "CHROME_PATHS[0]=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "CHROME_PATHS[1]=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
set "CHROME_PATHS[2]=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"

for /L %%i in (0,1,2) do (
    if exist "!CHROME_PATHS[%%i]!" (
        set CHROME_FOUND=1
        echo [OK] Chrome encontrado
        goto :chrome_ok
    )
)

if %CHROME_FOUND%==0 (
    color %COLOR_WARNING%
    echo [AVISO] Google Chrome não encontrado!
    echo.
    echo O script pode não funcionar corretamente.
    echo Instale o Chrome em: https://www.google.com/chrome/
    echo.
    pause
)

:chrome_ok
echo.

REM ==================== VERIFICAÇÃO 4: CHROMEDRIVER ====================
echo [4/5] Verificando ChromeDriver...

if not exist "chromedriver.exe" (
    color %COLOR_ERROR%
    echo.
    echo [ERRO] chromedriver.exe não encontrado!
    echo.
    echo Baixe o ChromeDriver compatível com sua versão do Chrome em:
    echo https://googlechromelabs.github.io/chrome-for-testing/
    echo.
    echo Extraia o chromedriver.exe na pasta do projeto.
    echo.
    pause
    exit /b 1
)

echo [OK] ChromeDriver encontrado
echo.

REM ==================== VERIFICAÇÃO 5: CREDENCIAIS ====================
echo [5/5] Validando credenciais...
echo.

REM Extrai configurações do vars.js
for /f "tokens=2 delims==;" %%A in ('findstr /C:"const IP" "%VARS_FILE%"') do (
    set line=%%A
    set line=!line:"=!
    set line=!line: =!
    set IP_VAL=!line!
)

for /f "tokens=2 delims==;" %%A in ('findstr /C:"const user" "%VARS_FILE%"') do (
    set line=%%A
    set line=!line:"=!
    set line=!line: =!
    set USER_VAL=!line!
)

for /f "tokens=2 delims==;" %%A in ('findstr /C:"const pass" "%VARS_FILE%"') do (
    set line=%%A
    set line=!line:"=!
    set line=!line: =!
    set PASS_VAL=!line!
)

REM Remove "Utils.messUserPass(" e ")" se existir (senha ofuscada)
set PASS_VAL=!PASS_VAL:Utils.messUserPass(=!
set PASS_VAL=!PASS_VAL:)=!
set PASS_VAL=!PASS_VAL:"=!
set PASS_VAL=!PASS_VAL: =!

echo ┌─────────────────────────────────────────────────────────┐
echo │ Configurações Atuais                                    │
echo ├─────────────────────────────────────────────────────────┤
echo │ IP do modem: !IP_VAL!
echo │ Usuário:     !USER_VAL!
echo │ Senha:       !PASS_VAL!
echo └─────────────────────────────────────────────────────────┘
echo.

REM Verifica senha padrão
set CHECK_PASS=!PASS_VAL!
set CHECK_PASS=!CHECK_PASS:"=!
set CHECK_PASS=!CHECK_PASS: =!

if /i "!CHECK_PASS!"=="sua-senha" (
    color %COLOR_ERROR%
    echo.
    echo ╔════════════════════════════════════════════════════════════╗
    echo ║  ⚠  ATENÇÃO: SENHA PADRÃO DETECTADA                        ║
    echo ╚════════════════════════════════════════════════════════════╝
    echo.
    echo A senha ainda está configurada como padrão: "sua-senha"
    echo.
    echo Para continuar, você precisa configurar a senha real do modem.
    echo.
    echo ┌─────────────────────────────────────────────────────────┐
    echo │ Como configurar:                                        │
    echo ├─────────────────────────────────────────────────────────┤
    echo │ 1. Abra o arquivo: vars.js                              │
    echo │ 2. Localize a linha:                                    │
    echo │    const pass = "sua-senha";                            │
    echo │ 3. Substitua por:                                       │
    echo │    const pass = "SUA_SENHA_REAL";                       │
    echo │ 4. A senha está na etiqueta na parte de baixo do modem  │
    echo │ 5. Salve o arquivo e execute este script novamente      │
    echo └─────────────────────────────────────────────────────────┘
    echo.
    
    set /p OPEN_FILE="Deseja abrir o vars.js agora para editar? (S/N): "
    if /i "!OPEN_FILE!"=="S" (
        echo.
        echo [INFO] Abrindo vars.js no Notepad...
        start notepad "%VARS_FILE%"
        echo.
        echo Após editar e salvar, execute este script novamente.
    )
    echo.
    pause
    exit /b 2
)

if /i "!CHECK_PASS!"=="SUA_SENHA_AQUI" (
    color %COLOR_ERROR%
    echo.
    echo [ERRO] Senha ainda não configurada: "SUA_SENHA_AQUI"
    echo.
    echo Configure a senha real do modem no arquivo vars.js
    echo A senha está na etiqueta na parte de baixo do aparelho.
    echo.
    pause
    exit /b 2
)

REM Verifica se a senha está vazia
if "!CHECK_PASS!"=="" (
    color %COLOR_ERROR%
    echo.
    echo [ERRO] Senha vazia detectada!
    echo.
    echo Configure a senha no arquivo vars.js
    echo.
    pause
    exit /b 2
)

color %COLOR_SUCCESS%
echo [OK] Credenciais configuradas corretamente!
echo.

REM ==================== TESTE DE CONECTIVIDADE ====================
echo ┌─────────────────────────────────────────────────────────┐
echo │ Testando conectividade com o modem...                  │
echo └─────────────────────────────────────────────────────────┘
echo.

ping -n 1 -w 2000 %IP_VAL% >nul 2>&1
if errorlevel 1 (
    color %COLOR_WARNING%
    echo [AVISO] Não foi possível conectar ao modem em %IP_VAL%
    echo.
    echo Verifique:
    echo - Se você está conectado ao WiFi ou cabo do modem
    echo - Se o IP está correto no vars.js
    echo - Se o modem está ligado
    echo.
    set /p CONTINUE="Deseja continuar mesmo assim? (S/N): "
    if /i "!CONTINUE!" NEQ "S" (
        echo.
        echo Execução cancelada.
        pause
        exit /b 3
    )
) else (
    echo [OK] Modem acessível em %IP_VAL%
)
echo.

REM ==================== VERIFICAÇÃO DE DEPENDÊNCIAS ====================
echo ┌─────────────────────────────────────────────────────────┐
echo │ Verificando dependências do Node.js...                 │
echo └─────────────────────────────────────────────────────────┘
echo.

if not exist "node_modules\" (
    color %COLOR_WARNING%
    echo [AVISO] Dependências não instaladas!
    echo.
    echo [INFO] Instalando dependências...
    call npm install
    
    if errorlevel 1 (
        color %COLOR_ERROR%
        echo.
        echo [ERRO] Falha ao instalar dependências!
        echo.
        pause
        exit /b 1
    )
    echo.
    echo [OK] Dependências instaladas com sucesso!
) else (
    echo [OK] Dependências já instaladas
)
echo.

REM ==================== INICIAR APLICAÇÃO ====================
color %COLOR_SUCCESS%
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║  ✓ TODAS AS VERIFICAÇÕES CONCLUÍDAS COM SUCESSO           ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo Iniciando aplicação...
echo.
echo ┌─────────────────────────────────────────────────────────┐
echo │ O Chrome será aberto automaticamente                    │
echo │ Aguarde a mensagem de sucesso                           │
echo │ Não feche esta janela!                                  │
echo └─────────────────────────────────────────────────────────┘
echo.
timeout /t 3 /nobreak >nul

REM Inicia o aplicativo
echo ════════════════════════════════════════════════════════════
echo.
REM IMPORTANTE: Sempre executar index.js, NUNCA vars.js diretamente!
node index.js

REM ==================== FINALIZAÇÃO ====================
echo.
echo ════════════════════════════════════════════════════════════
echo.
if errorlevel 1 (
    color %COLOR_ERROR%
    echo [ERRO] A aplicação encerrou com erros.
    echo.
    echo Verifique as mensagens acima para mais detalhes.
) else (
    color %COLOR_SUCCESS%
    echo [OK] Aplicação encerrada normalmente.
)
echo.
pause