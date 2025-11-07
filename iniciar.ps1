# iniciar.ps1
# Script de inicialização do Modem VIVO Unlock Tool
# Verifica todas as dependências antes de executar

$ErrorActionPreference = 'Stop'

# ==================== CONFIGURAÇÕES ====================
$VARS_FILE = "vars.js"
$NODE_MIN_VERSION = 20

# ==================== FUNÇÕES ====================

function Write-ColorBox {
    param([string]$Text, [ConsoleColor]$Color = 'Cyan')
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param([string]$Text)
    Write-Host "[INFO] $Text" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-ErrorMsg {
    param([string]$Text)
    Write-Host "[ERRO] $Text" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Text)
    Write-Host "[AVISO] $Text" -ForegroundColor DarkYellow
}

# ==================== BANNER ====================

Clear-Host
Write-Host ""
Write-ColorBox "╔════════════════════════════════════════════════════════════╗"
Write-ColorBox "║                                                            ║"
Write-ColorBox "║   █▀▄▀█ █▀█ █▀▄ █▀▀ █▀▄▀█   █░█ █ █░█ █▀█                ║"
Write-ColorBox "║   █░▀░█ █▄█ █▄▀ ██▄ █░▀░█   ▀▄▀ █ ▀▄▀ █▄█                ║"
Write-ColorBox "║                                                            ║"
Write-ColorBox "║              Modem VIVO - Unlock Tool                      ║"
Write-ColorBox "║          Askey RTF8115VW REV5 - Automação                  ║"
Write-ColorBox "║                                                            ║"
Write-ColorBox "╚════════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Step "Iniciando verificações do sistema..."
Write-Host ""

# ==================== VERIFICAÇÃO 1: ARQUIVO VARS.JS ====================

Write-Host "[1/5] Verificando arquivo de configuração..." -ForegroundColor White

if (-not (Test-Path $VARS_FILE)) {
    Write-Host ""
    Write-ErrorMsg "Arquivo $VARS_FILE não encontrado!"
    Write-Host ""
    Write-Host "Verifique se você está na pasta correta do projeto." -ForegroundColor Yellow
    Write-Host "Caminho atual: $(Get-Location)" -ForegroundColor White
    Write-Host ""
    pause
    exit 1
}

Write-Success "Arquivo vars.js encontrado"
Write-Host ""

# ==================== VERIFICAÇÃO 2: NODE.JS ====================

Write-Host "[2/5] Verificando Node.js..." -ForegroundColor White

$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCommand) {
    Write-Host ""
    Write-ErrorMsg "Node.js não encontrado!"
    Write-Host ""
    Write-Host "Instale o Node.js v$NODE_MIN_VERSION (LTS) em:" -ForegroundColor Yellow
    Write-Host "https://nodejs.org/" -ForegroundColor Cyan
    Write-Host ""
    pause
    exit 1
}

$nodeVersion = node --version
Write-Success "Node.js instalado: $nodeVersion"
Write-Host ""

# ==================== VERIFICAÇÃO 3: CHROME ====================

Write-Host "[3/5] Verificando Google Chrome..." -ForegroundColor White

$chromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

$chromeFound = $false
foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        $chromeFound = $true
        Write-Success "Chrome encontrado"
        break
    }
}

if (-not $chromeFound) {
    Write-Host ""
    Write-Warning "Google Chrome não encontrado!"
    Write-Host ""
    Write-Host "O script pode não funcionar corretamente." -ForegroundColor Yellow
    Write-Host "Instale o Chrome em: https://www.google.com/chrome/" -ForegroundColor Cyan
    Write-Host ""
    pause
}

Write-Host ""

# ==================== VERIFICAÇÃO 4: CHROMEDRIVER ====================

Write-Host "[4/5] Verificando ChromeDriver..." -ForegroundColor White

if (-not (Test-Path "chromedriver.exe")) {
    Write-Host ""
    Write-ErrorMsg "chromedriver.exe não encontrado!"
    Write-Host ""
    Write-Host "Baixe o ChromeDriver compatível com sua versão do Chrome em:" -ForegroundColor Yellow
    Write-Host "https://googlechromelabs.github.io/chrome-for-testing/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Extraia o chromedriver.exe na pasta do projeto." -ForegroundColor White
    Write-Host ""
    pause
    exit 1
}

Write-Success "ChromeDriver encontrado"
Write-Host ""

# ==================== VERIFICAÇÃO 5: CREDENCIAIS ====================

Write-Host "[5/5] Validando credenciais..." -ForegroundColor White
Write-Host ""

# Lê vars.js
$varsContent = Get-Content $VARS_FILE -Raw

# Extrai IP
if ($varsContent -match 'const IP\s*=\s*"([^"]+)"') {
    $ipVal = $Matches[1]
} else {
    $ipVal = "Não encontrado"
}

# Extrai usuário
if ($varsContent -match 'const user\s*=\s*"([^"]+)"') {
    $userVal = $Matches[1]
} else {
    $userVal = "Não encontrado"
}

# Extrai senha
if ($varsContent -match 'const pass\s*=\s*"([^"]+)"') {
    $passVal = $Matches[1]
} elseif ($varsContent -match 'const pass\s*=\s*Utils\.messUserPass\("([^"]+)"\)') {
    $passVal = $Matches[1] + " (ofuscada)"
} else {
    $passVal = "Não encontrada"
}

Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ Configurações Atuais                                    │" -ForegroundColor Cyan
Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
Write-Host "│ IP do modem: $ipVal" -ForegroundColor Cyan
Write-Host "│ Usuário:     $userVal" -ForegroundColor Cyan
Write-Host "│ Senha:       $passVal" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

# Verifica senhas padrão
if ($passVal -match "sua-senha" -or $passVal -match "SUA_SENHA_AQUI") {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║  ⚠  ATENÇÃO: SENHA PADRÃO DETECTADA                        ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "A senha ainda está configurada como padrão!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para continuar, você precisa configurar a senha real do modem." -ForegroundColor White
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│ Como configurar:                                        │" -ForegroundColor Yellow
    Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Yellow
    Write-Host "│ 1. Abra o arquivo: vars.js                              │" -ForegroundColor Yellow
    Write-Host "│ 2. Localize a linha: const pass = `"sua-senha`";          │" -ForegroundColor Yellow
    Write-Host "│ 3. Substitua por: const pass = `"SUA_SENHA_REAL`";       │" -ForegroundColor Yellow
    Write-Host "│ 4. A senha está na etiqueta na parte de baixo do modem  │" -ForegroundColor Yellow
    Write-Host "│ 5. Salve o arquivo e execute este script novamente      │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""
    
    $openFile = Read-Host "Deseja abrir o vars.js agora para editar? (S/N)"
    if ($openFile -eq 'S' -or $openFile -eq 's') {
        Write-Host ""
        Write-Step "Abrindo vars.js no Notepad..."
        Start-Process notepad $VARS_FILE
        Write-Host ""
        Write-Host "Após editar e salvar, execute este script novamente." -ForegroundColor Yellow
    }
    Write-Host ""
    pause
    exit 2
}

Write-Success "Credenciais configuradas corretamente!"
Write-Host ""

# ==================== TESTE DE CONECTIVIDADE ====================

Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ Testando conectividade com o modem...                  │" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

$pingResult = Test-Connection -ComputerName $ipVal -Count 1 -Quiet -ErrorAction SilentlyContinue

if (-not $pingResult) {
    Write-Warning "Não foi possível conectar ao modem em $ipVal"
    Write-Host ""
    Write-Host "Verifique:" -ForegroundColor Yellow
    Write-Host "- Se você está conectado ao WiFi ou cabo do modem" -ForegroundColor White
    Write-Host "- Se o IP está correto no vars.js" -ForegroundColor White
    Write-Host "- Se o modem está ligado" -ForegroundColor White
    Write-Host ""
    
    $continue = Read-Host "Deseja continuar mesmo assim? (S/N)"
    if ($continue -ne 'S' -and $continue -ne 's') {
        Write-Host ""
        Write-Host "Execução cancelada." -ForegroundColor Yellow
        pause
        exit 3
    }
} else {
    Write-Success "Modem acessível em $ipVal"
}

Write-Host ""

# ==================== VERIFICAÇÃO DE DEPENDÊNCIAS ====================

Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ Verificando dependências do Node.js...                 │" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "node_modules")) {
    Write-Warning "Dependências não instaladas!"
    Write-Host ""
    Write-Step "Instalando dependências..."
    
    npm install
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-ErrorMsg "Falha ao instalar dependências!"
        Write-Host ""
        pause
        exit 1
    }
    
    Write-Host ""
    Write-Success "Dependências instaladas com sucesso!"
} else {
    Write-Success "Dependências já instaladas"
}

Write-Host ""

# ==================== INICIAR APLICAÇÃO ====================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✓ TODAS AS VERIFICAÇÕES CONCLUÍDAS COM SUCESSO           ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Iniciando aplicação..." -ForegroundColor Yellow
Write-Host ""
Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ O Chrome será aberto automaticamente                    │" -ForegroundColor Cyan
Write-Host "│ Aguarde a mensagem de sucesso                           │" -ForegroundColor Cyan
Write-Host "│ Não feche esta janela!                                  │" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

Start-Sleep -Seconds 3

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

# Executa index.js
node index.js

$exitCode = $LASTEXITCODE

# ==================== FINALIZAÇÃO ====================

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

if ($exitCode -ne 0) {
    Write-ErrorMsg "A aplicação encerrou com erros."
    Write-Host ""
    Write-Host "Verifique as mensagens acima para mais detalhes." -ForegroundColor Yellow
} else {
    Write-Success "Aplicação encerrada normalmente."
}

Write-Host ""
pause
