/**
 * utils.js
 * Utilitários para automação do modem VIVO
 * - Suporta apenas Chrome (Windows, Linux, macOS)
 * - Ofuscação XOR para credenciais
 * - Configuração automática do WebDriver
 */

const Vars = require("./vars");
const WebDriver = require("selenium-webdriver");
const chrome = require("selenium-webdriver/chrome");
const fs = require("fs");
const path = require("path");

/**
 * Ofuscação/Desofuscação XOR (0x1f)
 * Usado para credenciais no vars.js
 * @param {string} str - String para ofuscar/desofuscar
 * @returns {string}
 */
function messUserPass(str) {
    if (typeof str !== "string") return str;
    return str
        .split("")
        .map(function (c) {
            return String.fromCharCode(c.charCodeAt(0) ^ 0x1f);
        })
        .join("");
}

/**
 * Retorna a plataforma atual
 * @returns {string} "win32", "linux" ou "darwin"
 */
function getPlatform() {
    return process.platform;
}

/**
 * Detecta o caminho do binário do Chrome por plataforma
 * @param {string} platform - Plataforma (win32, linux, darwin)
 * @returns {string|null} Caminho do Chrome ou null se não encontrado
 */
function detectChromePath(platform) {
    const chromePaths = {
        win32: [
            "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
            "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
            process.env.LOCALAPPDATA ? 
                path.join(process.env.LOCALAPPDATA, "Google", "Chrome", "Application", "chrome.exe") : 
                null
        ].filter(Boolean),
        linux: [
            "/usr/bin/google-chrome",
            "/usr/bin/google-chrome-stable",
            "/usr/bin/chromium-browser",
            "/usr/bin/chromium"
        ],
        darwin: [
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        ]
    };

    const paths = chromePaths[platform] || [];
    
    for (const chromePath of paths) {
        try {
            if (fs.existsSync(chromePath)) {
                console.log(`[INFO] Chrome encontrado em: ${chromePath}`);
                return chromePath;
            }
        } catch (e) {
            // Ignora erros de acesso
        }
    }
    
    console.warn(`[AVISO] Chrome não encontrado automaticamente em ${platform}`);
    return null;
}

/**
 * Detecta o caminho do ChromeDriver por plataforma
 * @param {string} platform - Plataforma (win32, linux, darwin)
 * @returns {string} Caminho do chromedriver
 */
function detectChromeDriverPath(platform) {
    const driverPaths = {
        win32: path.join(__dirname, "chromedriver.exe"),
        linux: path.join(__dirname, "chromedriver"),
        darwin: path.join(__dirname, "chromedriver")
    };

    const driverPath = driverPaths[platform];
    
    if (!fs.existsSync(driverPath)) {
        throw new Error(
            `ChromeDriver não encontrado em: ${driverPath}\n` +
            `Baixe em: https://googlechromelabs.github.io/chrome-for-testing/`
        );
    }

    return driverPath;
}

/**
 * Configura as opções do Chrome para o WebDriver
 * @param {string} chromePath - Caminho do binário do Chrome
 * @returns {chrome.Options}
 */
function configureChromeOptions(chromePath) {
    const options = new chrome.Options();
    
    if (chromePath) {
        options.setChromeBinaryPath(chromePath);
    }
    
    // Argumentos para melhor estabilidade e performance
    options.addArguments(
        '--disable-blink-features=AutomationControlled',
        '--disable-dev-shm-usage',
        '--no-sandbox',
        '--disable-gpu',
        '--window-size=1920,1080',
        '--disable-features=VizDisplayCompositor',
        '--ignore-certificate-errors',
        '--allow-insecure-localhost',
        '--start-maximized'
    );
    
    // Remove indicadores de automação
    options.excludeSwitches('enable-automation', 'enable-logging');
    
    // Preferências adicionais
    options.setUserPreferences({
        'profile.default_content_setting_values.notifications': 2,
        'profile.managed_default_content_settings.images': 1
    });
    
    return options;
}

/**
 * Cria e configura o WebDriver do Chrome
 * Detecta automaticamente Chrome e ChromeDriver
 * @param {string|null} platform - Plataforma (opcional, auto-detecta se null)
 * @returns {Promise<WebDriver>}
 */
async function getWebDriver(platform = null) {
    platform = platform || getPlatform();
    
    console.log(`[INFO] Configurando WebDriver para plataforma: ${platform}`);
    
    // Valida plataforma suportada
    if (!["win32", "linux", "darwin"].includes(platform)) {
        throw new Error(
            `Plataforma não suportada: ${platform}\n` +
            `Suportadas: Windows (win32), Linux (linux), macOS (darwin)`
        );
    }
    
    // Detecta Chrome
    const chromePath = detectChromePath(platform);
    if (!chromePath) {
        throw new Error(
            `Chrome não encontrado no sistema.\n` +
            `Instale o Google Chrome em: https://www.google.com/chrome/`
        );
    }
    
    // Detecta ChromeDriver
    const chromeDriverPath = detectChromeDriverPath(platform);
    console.log(`[INFO] ChromeDriver: ${chromeDriverPath}`);
    
    // Configura opções
    const options = configureChromeOptions(chromePath);
    
    // Configura service
    const service = new chrome.ServiceBuilder(chromeDriverPath);
    
    // Cria o driver
    const driver = await new WebDriver.Builder()
        .forBrowser(WebDriver.Browser.CHROME)
        .setChromeOptions(options)
        .setChromeService(service)
        .build();
    
    // Configura timeouts
    await driver.manage().setTimeouts({
        implicit: 15000,
        pageLoad: 30000,
        script: 15000
    });
    
    console.log("[INFO] WebDriver iniciado com sucesso");
    
    return driver;
}

/**
 * Aguarda página carregar completamente
 * @param {WebDriver} driver - Instância do WebDriver
 * @param {number} timeout - Timeout em ms (padrão: 15000)
 * @returns {Promise<boolean>}
 */
async function waitForPageLoad(driver, timeout = 15000) {
    console.log("[INFO] Aguardando página carregar...");
    
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeout) {
        try {
            const readyState = await driver.executeScript('return document.readyState');
            if (readyState === 'complete' || readyState === 'interactive') {
                console.log(`[INFO] Página carregada (readyState: ${readyState})`);
                return true;
            }
        } catch (error) {
            // Página ainda não acessível
        }
        await driver.sleep(500);
    }
    
    throw new Error(`Timeout: Página não carregou em ${timeout}ms`);
}

/**
 * Sleep utilitário (Promise-based)
 * @param {number} ms - Milissegundos
 * @returns {Promise<void>}
 */
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// ==================== EXPORTS ====================

module.exports = {
    // Ofuscação
    messUserPass,
    
    // Detecção de plataforma
    getPlatform,
    
    // Configuração do WebDriver
    detectChromePath,
    detectChromeDriverPath,
    configureChromeOptions,
    getWebDriver,
    
    // Utilitários
    waitForPageLoad,
    sleep
};