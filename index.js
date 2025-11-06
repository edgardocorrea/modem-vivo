/**
 * Askey RTF8115VW REV5 - Modem VIVO Unlock Tool
 * 
 * Automação para desbloqueio de configurações avançadas do modem VIVO
 * - Modelo: Askey RTF8115VW REV5
 * - Node.js: v20.x.x LTS
 * - Chrome: 142.0.7444.60+
 * - ChromeDriver: compatível com versão do Chrome
 * 
 * @author GitHub: seu-usuario
 * @version 2.0.0
 * @license MIT
 */

const Vars = require("./vars");
const Utils = require("./utils");
const { Builder, By, until } = require("selenium-webdriver");
const chrome = require("selenium-webdriver/chrome");
const path = require("path");
const fs = require("fs");
const os = require("os");

// ==================== AUTENTICAÇÃO ====================

/**
 * Obtém Session ID do modem via HTTP
 * @returns {Promise<string>} Session ID
 */
async function getFreshSessionId() {
    console.log("[INFO] Obtendo sessão...");
    const response = await fetch(`http://${Vars.IP}/login.asp`);
    const cookies = response.headers.getSetCookie();

    const cookiesObj = {};
    cookies.forEach((cookie) => {
        const [key, value] = cookie.split("=");
        cookiesObj[key.trim()] = value;
    });

    const sessionId = cookiesObj["_httpdSessionId_"].split(";")[0];
    console.log("[INFO] Sessão obtida:", sessionId);
    return sessionId;
}

/**
 * Realiza login no modem via API
 * @returns {Promise<string>} Session ID autenticado
 */
async function doLogin() {
    console.log("[INFO] Fazendo login...");
    const sessionId = await getFreshSessionId();

    const headers = new Headers();
    headers.append("Cookie", `SessionID=${sessionId}; LoginRole=system; _httpdSessionId_=${sessionId}`);

    const urlencoded = new URLSearchParams();
    urlencoded.append("loginUsername", Vars.user);
    urlencoded.append("loginPassword", Vars.pass);

    await fetch(`http://${Vars.IP}/cgi-bin/te_acceso_router.cgi`, {
        method: "POST",
        body: urlencoded,
        headers,
    });

    console.log("[INFO] Login concluído.");
    return sessionId;
}

// ==================== PROTEÇÃO DE ELEMENTOS ====================

/**
 * Injeta proteção JavaScript para prevenir desabilitação de elementos
 * Intercepta setAttribute e defineProperty
 */
async function injectElementProtection(driver) {
    return await driver.executeScript(`
        try {
            // Sobrescreve Object.defineProperty para bloquear disabled/readonly
            const originalDefineProperty = Object.defineProperty;
            Object.defineProperty = function(obj, prop, descriptor) {
                if ((prop === 'disabled' || prop === 'readOnly') && 
                    (obj === HTMLInputElement.prototype || 
                     obj === HTMLSelectElement.prototype || 
                     obj === HTMLTextAreaElement.prototype || 
                     obj === HTMLButtonElement.prototype)) {
                    descriptor.set = function() { return false; };
                    descriptor.get = function() { return false; };
                }
                return originalDefineProperty.call(this, obj, prop, descriptor);
            };
            
            // Sobrescreve setAttribute para bloquear disabled/readonly
            const originalSetAttribute = Element.prototype.setAttribute;
            Element.prototype.setAttribute = function(name, value) {
                if (name === 'disabled' || name === 'readonly') {
                    return;
                }
                return originalSetAttribute.call(this, name, value);
            };
            
            // Intercepta propriedades disabled e readOnly
            ['disabled', 'readOnly'].forEach(prop => {
                [HTMLInputElement, HTMLSelectElement, HTMLTextAreaElement, HTMLButtonElement].forEach(elementType => {
                    if (elementType.prototype) {
                        originalDefineProperty(elementType.prototype, prop, {
                            get: function() { return false; },
                            set: function(value) { 
                                this.removeAttribute(prop.toLowerCase());
                                return false; 
                            },
                            configurable: true
                        });
                    }
                });
            });
            
            return { success: true };
        } catch(error) {
            return { success: false, error: error.message };
        }
    `);
}

/**
 * Remove atributos disabled/readonly e configura MutationObserver
 * para monitorar mudanças contínuas no DOM
 */
async function forceEnableElements(driver) {
    return await driver.executeScript(`
        try {
            // Função para habilitar elemento
            function enableElement(el) {
                if (el.nodeType !== 1) return;
                
                el.removeAttribute('disabled');
                el.removeAttribute('readonly');
                
                try {
                    Object.defineProperty(el, 'disabled', {
                        get: () => false,
                        set: () => false,
                        configurable: true
                    });
                    Object.defineProperty(el, 'readOnly', {
                        get: () => false,
                        set: () => false,
                        configurable: true
                    });
                } catch(e) {}
            }
            
            const selector = 'input, select, textarea, button';
            document.querySelectorAll(selector).forEach(enableElement);
            
            // MutationObserver para mudanças em tempo real
            const observer = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                    if (mutation.type === 'attributes') {
                        const target = mutation.target;
                        if (mutation.attributeName === 'disabled' || 
                            mutation.attributeName === 'readonly') {
                            enableElement(target);
                        }
                    }
                    
                    if (mutation.type === 'childList') {
                        mutation.addedNodes.forEach((node) => {
                            if (node.nodeType === 1) {
                                if (node.matches && node.matches(selector)) {
                                    enableElement(node);
                                }
                                if (node.querySelectorAll) {
                                    node.querySelectorAll(selector).forEach(enableElement);
                                }
                            }
                        });
                    }
                });
            });
            
            observer.observe(document.documentElement, {
                attributes: true,
                attributeFilter: ['disabled', 'readonly'],
                childList: true,
                subtree: true
            });
            
            // Backup: reaplica habilitação a cada 500ms
            setInterval(() => {
                document.querySelectorAll(selector).forEach(enableElement);
            }, 500);
            
            const count = document.querySelectorAll(selector).length;
            return { success: true, count };
        } catch(error) {
            return { success: false, error: error.message };
        }
    `);
}

// ==================== PROCESSAMENTO DE FRAMES ====================

/**
 * Processa frame genérico com proteção
 * @param {WebDriver} driver - Instância do Selenium WebDriver
 * @param {string} frameName - Nome do frame
 * @param {boolean} enableElements - Se deve habilitar elementos (padrão: true)
 */
async function processFrame(driver, frameName, enableElements = true) {
    try {
        console.log(`[INFO] Processando frame: ${frameName}`);
        
        await driver.wait(until.elementLocated(By.name(frameName)), 5000);
        const frame = await driver.findElement(By.name(frameName));
        await driver.switchTo().frame(frame);
        
        await driver.sleep(1000);
        
        await injectElementProtection(driver);
        
        if (enableElements) {
            const result = await forceEnableElements(driver);
            console.log(`[INFO] Frame ${frameName}:`, result);
        }
        
        await driver.switchTo().defaultContent();
        
        return true;
    } catch (error) {
        console.warn(`[AVISO] Erro no frame ${frameName}:`, error.message);
        try {
            await driver.switchTo().defaultContent();
        } catch(e) {}
        return false;
    }
}

/**
 * Processa frame principal onde ficam as configurações
 */
async function processMainFrame(driver) {
    try {
        console.log("[INFO] Processando frame mainFrm...");
        
        try {
            await driver.wait(until.elementLocated(By.name("mainFrm")), 5000);
            const mainFrame = await driver.findElement(By.name("mainFrm"));
            await driver.switchTo().frame(mainFrame);
        } catch(e) {
            // Fallback: localiza por estrutura
            const frames = await driver.findElements(By.css("frame"));
            if (frames.length >= 3) {
                await driver.switchTo().frame(frames[2]);
            } else {
                throw new Error("Frame mainFrm não encontrado");
            }
        }
        
        await driver.sleep(2000);
        
        await injectElementProtection(driver);
        const result = await forceEnableElements(driver);
        console.log("[INFO] Frame mainFrm:", result);
        
        await driver.switchTo().defaultContent();
        
        return true;
    } catch (error) {
        console.warn("[AVISO] Erro no frame mainFrm:", error.message);
        try {
            await driver.switchTo().defaultContent();
        } catch(e) {}
        return false;
    }
}

// ==================== UTILITÁRIOS ====================

/**
 * Aguarda página carregar completamente
 */
async function waitForPageLoad(driver, timeout = 15000) {
    console.log("[INFO] Aguardando página carregar...");
    
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeout) {
        try {
            const readyState = await driver.executeScript('return document.readyState');
            if (readyState === 'complete' || readyState === 'interactive') {
                console.log("[INFO] Página carregada (readyState:", readyState + ")");
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
 * Monitora fechamento da janela do navegador
 */
async function monitorWindowClosure(driver) {
    const checkInterval = setInterval(async () => {
        try {
            await driver.getTitle();
        } catch (error) {
            // Janela foi fechada
            clearInterval(checkInterval);
            console.log("\n[INFO] ========================================");
            console.log("[INFO] Janela do navegador foi fechada");
            console.log("[INFO] Encerrando aplicação...");
            console.log("[INFO] ========================================");
            process.exit(0);
        }
    }, 1000);
}

// ==================== MAIN ====================

(async function main() {
    let driver;
    
    try {
        console.log("\n╔═════════════════════════════════════════════╗");
        console.log("║  Modem VIVO - Desbloqueio Automático        ║");
        console.log("║  Modem:Askey, Modelo:RTF8115VW, Versao:REV5 ║");
        console.log("╚═════════════════════════════════════════════╝\n");
        
        // Valida plataforma
        const platform = os.platform();
        console.log("[INFO] Plataforma detectada:", platform);
        
        if (!["win32", "linux"].includes(platform)) {
            throw new Error("Plataforma não suportada. Use Windows ou Linux com Chrome instalado.");
        }
        
        // Login via API
        const sessionId = await doLogin();
        
        // Configura Chrome
        console.log("[INFO] Configurando ChromeDriver...");
        const options = new chrome.Options();
        options.addArguments(
            '--disable-blink-features=AutomationControlled',
            '--disable-dev-shm-usage',
            '--no-sandbox',
            '--disable-gpu',
            '--window-size=1920,1080',
            '--disable-features=VizDisplayCompositor',
            '--ignore-certificate-errors',
            '--allow-insecure-localhost'
        );
        options.excludeSwitches('enable-logging');
        
        // Detecta caminho do Chrome (Windows)
        if (platform === "win32") {
            const chromePaths = [
                "C:/Program Files/Google/Chrome/Application/chrome.exe",
                "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
                process.env.LOCALAPPDATA + "/Google/Chrome/Application/chrome.exe"
            ];
            
            for (const chromePath of chromePaths) {
                if (fs.existsSync(chromePath)) {
                    options.setChromeBinaryPath(chromePath);
                    console.log("[INFO] Chrome encontrado em:", chromePath);
                    break;
                }
            }
        }
        
        // Configura service
        const service = new chrome.ServiceBuilder(
            platform === "win32" 
                ? path.join(__dirname, "chromedriver.exe")
                : path.join(__dirname, "chromedriver")
        );
        
        // Inicia navegador
        console.log("[INFO] Iniciando navegador...");
        driver = await new Builder()
            .forBrowser("chrome")
            .setChromeOptions(options)
            .setChromeService(service)
            .build();
        
        await driver.manage().setTimeouts({ 
            implicit: 15000, 
            pageLoad: 30000, 
            script: 15000 
        });
        
        await driver.manage().window().maximize();
        
        // Navega para login
        console.log("[INFO] Navegando para login.asp...");
        try {
            await driver.get(`http://${Vars.IP}/login.asp`);
            await waitForPageLoad(driver, 15000);
        } catch (error) {
            console.warn("[AVISO] Erro ao carregar login.asp:", error.message);
        }
        
        await driver.sleep(1000);
        
        // Configura cookies de sessão
        console.log("[INFO] Configurando cookies...");
        try {
            await driver.manage().addCookie({ 
                name: "SessionID", 
                value: sessionId,
                domain: Vars.IP
            });
            await driver.manage().addCookie({ 
                name: "LoginRole", 
                value: "system",
                domain: Vars.IP
            });
            await driver.manage().addCookie({ 
                name: "_httpdSessionId_", 
                value: sessionId,
                domain: Vars.IP
            });
        } catch (error) {
            console.warn("[AVISO] Erro ao adicionar cookies:", error.message);
        }
        
        // Acessa página avançada
        console.log("[INFO] Redirecionando para avanzada.asp...");
        await driver.get(`http://${Vars.IP}/avanzada.asp`);
        await waitForPageLoad(driver, 20000);
        
        console.log("[INFO] Aguardando frames carregarem...");
        await driver.sleep(3000);
        
        // Injeta proteção no documento principal
        console.log("[INFO] Injetando proteção no documento principal...");
        await injectElementProtection(driver);
        
        // Processa frames
        await processMainFrame(driver);
        await processFrame(driver, "menuFrm", false);
        
        console.log("\n╔════════════════════════════════════════════╗");
        console.log("║  (OK) Script executado com sucesso!        ║");
        console.log("╠════════════════════════════════════════════╣");
        console.log("║  • Elementos habilitados em todos frames   ║");
        console.log("║  • Proteção ativa contra desabilitação     ║");
        console.log("║  • Monitorando mudanças                    ║");
        console.log("╠════════════════════════════════════════════╣");
        console.log("║  Navegador permanecerá aberto para uso     ║");
        console.log("║  Feche a janela ou pressione Ctrl+C        ║");
        console.log("╚════════════════════════════════════════════╝\n");
        
        // Monitora fechamento da janela
        monitorWindowClosure(driver);
        
        // Reaplica proteção periodicamente no frame main
        setInterval(async () => {
            try {
                const mainFrame = await driver.findElement(By.name("mainFrm"));
                await driver.switchTo().frame(mainFrame);
                await injectElementProtection(driver);
                await forceEnableElements(driver);
                await driver.switchTo().defaultContent();
            } catch(e) {
                // Ignora erros silenciosamente
            }
        }, 5000);
        
    } catch (error) {
        console.error("\n╔════════════════════════════════════════════╗");
        console.error("║  ✗ ERRO CRÍTICO                            ║");
        console.error("╚════════════════════════════════════════════╝");
        console.error("[ERRO]", error.message);
        console.error("[STACK]", error.stack);
        
        if (driver) {
            try {
                const screenshot = await driver.takeScreenshot();
                const screenshotPath = path.join(__dirname, 'error-screenshot.png');
                fs.writeFileSync(screenshotPath, screenshot, 'base64');
                console.log("[INFO] Screenshot salvo em:", screenshotPath);
                
                const currentUrl = await driver.getCurrentUrl();
                console.log("[INFO] URL atual:", currentUrl);
            } catch (debugError) {
                console.error("[ERRO DEBUG]", debugError.message);
            }
            
            await driver.quit();
        }
        process.exit(1);
    }
})();