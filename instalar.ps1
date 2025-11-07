# Modem VIVO - Instalador Automático Inteligente
# Repositório: https://github.com/edgardocorrea/modem-vivo
# Uso: irm https://raw.githubusercontent.com/edgardocorrea/modem-vivo/instalando/instalar.ps1 | iex

if (-not $args) {
    Write-Host ''
    Write-Host 'Instalador Automático - Modem VIVO função avançada' -ForegroundColor Cyan
    Write-Host 'Repositório: ' -NoNewline
    Write-Host 'https://github.com/edgardocorrea/modem-vivo' -ForegroundColor Green
    Write-Host ''
}

& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    # ==================== CONFIGURAÇÕES ====================
    $REPO_OWNER = "edgardocorrea"
    $REPO_NAME = "modem-vivo"
    $INSTALL_DIR = "$env:SystemDrive\modem-vivo"
    $NODE_VERSION = "20.18.0"
    $CHROME_FOR_TESTING_API = "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json"
    
    # ==================== FUNÇÕES AUXILIARES ====================
    
    function Write-ColorText {
        param([string]$Text, [ConsoleColor]$Color = 'White')
        Write-Host $Text -ForegroundColor $Color
    }
    
    function Write-Header {
        param([string]$Text)
        Write-Host "`n══════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "   $Text" -ForegroundColor Cyan
        Write-Host "══════════════════════════════════════════════`n" -ForegroundColor Cyan
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
    
    function Test-AdminRights {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    
    function Download-File {
        param([string]$Url, [string]$OutputPath)
        
        try {
            Write-Step "Baixando: $(Split-Path $OutputPath -Leaf)"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $OutputPath)
            
            if (Test-Path $OutputPath) {
                Write-Success "Download concluído"
                return $true
            }
            return $false
        }
        catch {
            Write-ErrorMsg "Falha no download: $($_.Exception.Message)"
            return $false
        }
    }
    
    function Extract-ZipFile {
        param([string]$ZipPath, [string]$DestinationPath)
        
        try {
            Write-Step "Extraindo arquivo..."
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $DestinationPath)
            Write-Success "Extração concluída"
            return $true
        }
        catch {
            Write-ErrorMsg "Falha na extração: $($_.Exception.Message)"
            return $false
        }
    }
    
    # ==================== DETECÇÃO DE NAVEGADORES ====================
    
    function Get-ChromiumBrowser {
        Write-Step "Procurando navegadores Chromium instalados..."
        
        $browsers = @(
            @{Name="Google Chrome"; Path="$env:ProgramFiles\Google\Chrome\Application\chrome.exe"; Type="chrome"},
            @{Name="Google Chrome"; Path="${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"; Type="chrome"},
            @{Name="Google Chrome"; Path="$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"; Type="chrome"},
            @{Name="Microsoft Edge"; Path="$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"; Type="edge"},
            @{Name="Microsoft Edge"; Path="${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"; Type="edge"},
            @{Name="Brave Browser"; Path="$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"; Type="brave"},
            @{Name="Chromium"; Path="$env:LOCALAPPDATA\Chromium\Application\chrome.exe"; Type="chromium"}
        )
        
        foreach ($browser in $browsers) {
            if (Test-Path $browser.Path) {
                try {
                    $version = (Get-Item $browser.Path).VersionInfo.ProductVersion
                    Write-Success "Encontrado: $($browser.Name) v$version"
                    return @{
                        Name = $browser.Name
                        Path = $browser.Path
                        Version = $version
                        Type = $browser.Type
                    }
                }
                catch {
                    continue
                }
            }
        }
        
        return $null
    }
    
    # ==================== API CHROME FOR TESTING ====================
    
    function Get-ChromeDriverUrl {
        param([string]$ChromeVersion)
        
        Write-Step "Consultando API do Chrome for Testing..."
        
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $json = Invoke-RestMethod -Uri $CHROME_FOR_TESTING_API -TimeoutSec 30
            
            # Busca versão exata primeiro
            Write-Step "Procurando ChromeDriver versão $ChromeVersion (exata)..."
            $exactMatch = $json.versions | Where-Object { $_.version -eq $ChromeVersion }
            
            if ($exactMatch) {
                $url = $exactMatch.downloads.chromedriver | Where-Object { $_.platform -eq "win64" } | Select-Object -ExpandProperty url -First 1
                if ($url) {
                    Write-Success "Versão exata encontrada: $ChromeVersion"
                    return @{Version=$ChromeVersion; Url=$url}
                }
            }
            
            # Se não encontrar exata, busca versão MAJOR mais recente
            $majorVersion = $ChromeVersion.Split('.')[0]
            Write-Step "Procurando ChromeDriver versão $majorVersion.x.x.x (major)..."
            
            $majorMatches = $json.versions | Where-Object { $_.version -like "$majorVersion.*" } | Sort-Object {
                [version]($_.version)
            } -Descending
            
            if ($majorMatches) {
                $bestMatch = $majorMatches | Select-Object -First 1
                $url = $bestMatch.downloads.chromedriver | Where-Object { $_.platform -eq "win64" } | Select-Object -ExpandProperty url -First 1
                
                if ($url) {
                    Write-Success "Versão compatível encontrada: $($bestMatch.version)"
                    return @{Version=$bestMatch.version; Url=$url}
                }
            }
            
            Write-Warning "Nenhuma versão compatível encontrada na API"
            return $null
        }
        catch {
            Write-ErrorMsg "Erro ao consultar API: $($_.Exception.Message)"
            return $null
        }
    }
    
    # ==================== INSTALAÇÃO CHROME ====================
    
    function Install-GoogleChrome {
        Write-Header "Instalação do Google Chrome"
        
        Write-Host "Google Chrome não foi encontrado no sistema." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Opções disponíveis:" -ForegroundColor Cyan
        Write-Host "  [1] Baixar e instalar Chrome automaticamente (Recomendado)" -ForegroundColor White
        Write-Host "  [2] Abrir página de download do Chrome no navegador" -ForegroundColor White
        Write-Host "  [3] Cancelar instalação" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Escolha uma opção (1-3)"
        
        switch ($choice) {
            "1" {
                Write-Step "Baixando Google Chrome..."
                $chromeInstaller = "$env:TEMP\ChromeSetup.exe"
                $chromeUrl = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
                
                if (Download-File -Url $chromeUrl -OutputPath $chromeInstaller) {
                    Write-Step "Instalando Google Chrome (aguarde)..."
                    Start-Process -FilePath $chromeInstaller -ArgumentList "/silent /install" -Wait -NoNewWindow
                    Remove-Item $chromeInstaller -Force -ErrorAction SilentlyContinue
                    
                    Start-Sleep -Seconds 3
                    
                    # Verifica se instalou
                    $chrome = Get-ChromiumBrowser
                    if ($chrome -and $chrome.Type -eq "chrome") {
                        Write-Success "Google Chrome instalado com sucesso!"
                        return $chrome
                    }
                    else {
                        Write-ErrorMsg "Instalação falhou ou Chrome não foi detectado"
                        return $null
                    }
                }
                else {
                    Write-ErrorMsg "Falha ao baixar o instalador do Chrome"
                    return $null
                }
            }
            "2" {
                Write-Step "Abrindo página de download..."
                Start-Process "https://www.google.com/chrome/"
                Write-Host ""
                Write-Host "Após instalar o Chrome, execute este script novamente." -ForegroundColor Yellow
                pause
                return $null
            }
            "3" {
                Write-Host "Instalação cancelada pelo usuário." -ForegroundColor Yellow
                return $null
            }
            default {
                Write-ErrorMsg "Opção inválida"
                return $null
            }
        }
    }
    
    # ==================== INÍCIO ====================
    
    # cls
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                            ║" -ForegroundColor Cyan
    Write-Host "║   █▀▄▀█ █▀█ █▀▄ █▀▀ █▀▄▀█   █░█ █ █░█ █▀█                  ║" -ForegroundColor Cyan
    Write-Host "║   █░▀░█ █▄█ █▄▀ ██▄ █░▀░█   ▀▄▀ █ ▀▄▀ █▄█                  ║" -ForegroundColor Cyan
    Write-Host "║                                                            ║" -ForegroundColor Cyan
    Write-Host "║          Instalador Automático Inteligente                 ║" -ForegroundColor Cyan
    Write-Host "║              Askey RTF8115VW REV5                          ║" -ForegroundColor Cyan
    Write-Host "║                  by EdyOne                                 ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Verifica privilégios de admin
try {
    $isAdmin = Test-AdminRights
} catch {
    Write-Host "[DEBUG] Erro ao testar privilégios de administrador:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    return
}

if (-not $isAdmin) {
    Write-ErrorMsg "Este script precisa ser executado como Administrador!"

        Write-Host ""
        Write-Host "Como executar como Administrador:" -ForegroundColor Yellow
        Write-Host "1. Clique [ botão Windows + X ] " -ForegroundColor White
        Write-Host "2. Selecione: Windows PowerShell (Admin)" -ForegroundColor White
        Write-Host ""
        pause
        return
    }
    
    Write-Success "Executando com privilégios de administrador"
    
    # ==================== PASSO 1: DETECTAR NAVEGADOR ====================
    
    Write-Header "PASSO 1/5: Detectando Navegador Chromium"
    
    $browser = Get-ChromiumBrowser
    
    if (-not $browser) {
        Write-Warning "Nenhum navegador Chromium detectado"
        $browser = Install-GoogleChrome
        
        if (-not $browser) {
            Write-ErrorMsg "Não foi possível instalar ou detectar um navegador compatível"
            Write-Host "Instale o Google Chrome manualmente e execute este script novamente." -ForegroundColor Yellow
            pause
            return
        }
    }
    
    Write-Host ""
    Write-Host "┌───────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
    Write-Host "│ Navegador Detectado                                          │" -ForegroundColor Green
    Write-Host "├───────────────────────────────────────────────────────────────────┤" -ForegroundColor Green
    Write-Host "│ Nome:    $($browser.Name.PadRight(45))           │" -ForegroundColor Green
    Write-Host "│ Versão:  $($browser.Version.PadRight(45))           │" -ForegroundColor Green
    Write-Host "│ Caminho: $($browser.Path.PadRight(45))            │" -ForegroundColor Green
    Write-Host "└───────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    
    # ==================== PASSO 2: INSTALAR NODE.JS ====================
    
    Write-Header "PASSO 2/5: Instalando Node.js"
    
    $nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
    
    if ($nodeInstalled) {
        $currentNodeVersion = node --version
        Write-Success "Node.js já instalado: $currentNodeVersion"
        
        $response = Read-Host "Deseja reinstalar Node.js v$NODE_VERSION? (S/N)"
        if ($response -ne 'S' -and $response -ne 's') {
            Write-Step "Mantendo Node.js atual"
        }
        else {
            $nodeInstalled = $null
        }
    }
    
    if (-not $nodeInstalled) {
        Write-Step "Baixando Node.js v$NODE_VERSION..."
        
        $nodeUrl = "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-x64.msi"
        $nodeInstaller = "$env:TEMP\node-installer.msi"
        
        if (Download-File -Url $nodeUrl -OutputPath $nodeInstaller) {
            Write-Step "Instalando Node.js (isso pode levar alguns minutos)..."
            Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait -NoNewWindow
            
            Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            
            # Atualiza PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Success "Node.js instalado com sucesso!"
        }
        else {
            Write-ErrorMsg "Falha ao instalar Node.js"
            pause
            return
        }
    }
    
    # ==================== PASSO 3: BAIXAR REPOSITÓRIO ====================
    
    Write-Header "PASSO 3/5: Baixando Arquivos do GitHub"
    
    if (Test-Path $INSTALL_DIR) {
        Write-Step "Removendo instalação anterior..."
        Remove-Item $INSTALL_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
    
    Write-Step "Baixando repositório..."
    
    $repoZipUrl = "https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/main.zip"
    $repoZipPath = "$env:TEMP\modem-vivo.zip"
    
    if (Download-File -Url $repoZipUrl -OutputPath $repoZipPath) {
        $tempExtract = "$env:TEMP\modem-vivo-extract"
        
        if (Test-Path $tempExtract) {
            Remove-Item $tempExtract -Recurse -Force
        }
        
        if (Extract-ZipFile -ZipPath $repoZipPath -DestinationPath $tempExtract) {
            $subFolder = Get-ChildItem $tempExtract | Select-Object -First 1
            
            # Copia TODOS os arquivos e subpastas
            Get-ChildItem $subFolder.FullName -Recurse | ForEach-Object {
                $targetPath = $_.FullName.Replace($subFolder.FullName, $INSTALL_DIR)
                if ($_.PSIsContainer) {
                    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                } else {
                    Copy-Item $_.FullName -Destination $targetPath -Force
                }
            }
            
            Remove-Item $tempExtract -Recurse -Force
            Remove-Item $repoZipPath -Force
            
            # VALIDAÇÃO: Verifica arquivos críticos
            $requiredFiles = @("index.js", "vars.js", "utils.js", "package.json", "iniciar.bat")
            $missingFiles = @()
            
            foreach ($file in $requiredFiles) {
                if (-not (Test-Path "$INSTALL_DIR\$file")) {
                    $missingFiles += $file
                }
            }
            
            if ($missingFiles.Count -gt 0) {
                Write-ErrorMsg "Arquivos ausentes após download: $($missingFiles -join ', ')"
                Write-Host ""
                Write-Host "Possíveis causas:" -ForegroundColor Yellow
                Write-Host "- Repositório GitHub incompleto" -ForegroundColor White
                Write-Host "- Antivírus bloqueou arquivos" -ForegroundColor White
                Write-Host "- Conexão instável durante download" -ForegroundColor White
                Write-Host ""
                Write-Host "Verifique o repositório em:" -ForegroundColor Cyan
                Write-Host "https://github.com/$REPO_OWNER/$REPO_NAME" -ForegroundColor White
                pause
                return
            }
            
            Write-Success "Arquivos instalados em: $INSTALL_DIR"
            Write-Step "Arquivos verificados: $($requiredFiles -join ', ')"
        }
    }
    else {
        Write-ErrorMsg "Falha ao baixar repositório"
        pause
        return
    }
    
    # ==================== PASSO 4: INSTALAR CHROMEDRIVER INTELIGENTE ====================
    
    Write-Header "PASSO 4/5: Instalando ChromeDriver Compatível"
    
    $chromeDriverInfo = Get-ChromeDriverUrl -ChromeVersion $browser.Version
    
    if ($chromeDriverInfo) {
        Write-Step "ChromeDriver versão $($chromeDriverInfo.Version) será instalado"
        
        $chromeDriverZip = "$env:TEMP\chromedriver.zip"
        
        if (Download-File -Url $chromeDriverInfo.Url -OutputPath $chromeDriverZip) {
            $chromeDriverTemp = "$env:TEMP\chromedriver-extract"
            
            if (Test-Path $chromeDriverTemp) {
                Remove-Item $chromeDriverTemp -Recurse -Force
            }
            
            if (Extract-ZipFile -ZipPath $chromeDriverZip -DestinationPath $chromeDriverTemp) {
                $chromeDriverExe = Get-ChildItem $chromeDriverTemp -Recurse -Filter "chromedriver.exe" | Select-Object -First 1
                
                if ($chromeDriverExe) {
                    Copy-Item $chromeDriverExe.FullName "$INSTALL_DIR\chromedriver.exe" -Force
                    Write-Success "ChromeDriver v$($chromeDriverInfo.Version) instalado"
                }
                
                Remove-Item $chromeDriverTemp -Recurse -Force
                Remove-Item $chromeDriverZip -Force
            }
        }
    }
    else {
        Write-ErrorMsg "Não foi possível obter ChromeDriver compatível"
        Write-Host ""
        Write-Host "Baixe manualmente em:" -ForegroundColor Yellow
        Write-Host "https://googlechromelabs.github.io/chrome-for-testing/" -ForegroundColor Cyan
        Write-Host "Procure pela versão: $($browser.Version)" -ForegroundColor White
        Write-Host ""
        pause
    }
    
    # ==================== PASSO 5: INSTALAR DEPENDÊNCIAS NPM ====================
    
    Write-Header "PASSO 5/5: Instalando Dependências do Node.js"
    
    Push-Location $INSTALL_DIR
    
    Write-Step "Executando npm install (aguarde)..."
    npm install --silent 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Dependências instaladas com sucesso!"
    }
    else {
        Write-ErrorMsg "Falha ao instalar dependências NPM"
        Pop-Location
        pause
        return
    }
    
    Pop-Location
    
    # ==================== CRIAR ATALHOS ====================
    
    Write-Header "Criando Atalhos"
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktopPath\Modem VIVO Unlock.lnk"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
	$Shortcut.TargetPath = "powershell.exe"
	$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$INSTALL_DIR\iniciar.ps1`""
    $Shortcut.WorkingDirectory = $INSTALL_DIR
    $Shortcut.IconLocation = "shell32.dll,104"
    $Shortcut.Description = "Modem VIVO - Desbloqueio Automático"
    $Shortcut.Save()
    
    Write-Success "Atalho criado na Área de Trabalho"
    
    # ==================== CONFIGURAR CREDENCIAIS ====================
    
    Write-Header "Configuração de Credenciais"
    
    Write-Host "Para usar o programa, configure sua senha do modem:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Abra: $INSTALL_DIR\vars.js" -ForegroundColor Cyan
    Write-Host "  2. Localize: const pass = `"sua-senha`";" -ForegroundColor White
    Write-Host "  3. Substitua pela senha da etiqueta do modem" -ForegroundColor White
    Write-Host ""
    
    $openVars = Read-Host "Deseja abrir o vars.js agora para editar? (S/N)"
    if ($openVars -eq 'S' -or $openVars -eq 's') {
        Start-Process notepad "$INSTALL_DIR\vars.js"
        Write-Host ""
        Write-Host "[INFO] Edite e salve o arquivo vars.js" -ForegroundColor Yellow
        Write-Host "[INFO] Pressione qualquer tecla após salvar..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    # ==================== EXECUTAR INICIAR.BAT ====================
    
    Write-Header "Teste de Configuração"
    
    $runNow = Read-Host "Deseja executar o programa agora para testar? (S/N)"
    if ($runNow -eq 'S' -or $runNow -eq 's') {
        Write-Step "Iniciando verificação com iniciar.bat..."
        Write-Host ""
        Start-Sleep -Seconds 2
        
        Push-Location $INSTALL_DIR
        & "$INSTALL_DIR\iniciar.bat"
        Pop-Location
    }
    
    # ==================== FINALIZAÇÃO ====================
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                                                            ║" -ForegroundColor Green
    Write-Host "║          (OK) INSTALAÇÃO CONCLUÍDA COM SUCESSO!            ║" -ForegroundColor Green
    Write-Host "║                                                            ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ Instalação                                              │" -ForegroundColor Cyan
    Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ Pasta: $INSTALL_DIR" -ForegroundColor Cyan
    Write-Host "│ Atalho: Área de Trabalho                                │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│ Como Usar                                               │" -ForegroundColor Yellow
    Write-Host "├─────────────────────────────────────────────────────────┤" -ForegroundColor Yellow
    Write-Host "│ 1. Configure a senha no vars.js                         │" -ForegroundColor Yellow
    Write-Host "│ 2. Clique no atalho 'Modem VIVO Unlock'                 │" -ForegroundColor Yellow
    Write-Host "│ 3. O arquivo 'iniciar' verificará tudo automaticamente  │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor White
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} @args