/**
 * Configurações do Modem VIVO
 * 
 * IMPORTANTE:
 * Para alterar usuário/senha, edite os valores em texto claro
 * e a função messUserPass() em utils.js fará a conversão
 * 
 * Padrão:
 * IP = "192.168.15.1";   // IP do modem (ip padrão)
 * user = "admin";         // Usuário (admin padrão)
 * pass = "sua-senha";     // Senha (se encontra etiquetado no aparelho da vivo)
 */

// Proteção contra execução direta
if (require.main === module) {
    console.error("\n[ERRO] vars.js é um módulo, não execute diretamente!");
    console.error("Use: node index.js ou iniciar.bat\n");
    process.exit(1);
}

const Utils = require("./utils");

// Configurações do modem
const IP = "192.168.15.1";
const user = "admin";
const pass = "sua-senha"; // ← Altere para senha do modem

// Configuração do navegador
const browser = "chrome";
const browserPaths = {
    linux: { chrome: "/usr/bin/google-chrome" }
};

// Caminhos do ChromeDriver por plataforma
const chromedriverPaths = {
    win32: "chromedriver.exe",
    linux: "chromedriver"
};

module.exports = {
    IP,
    user: Utils.messUserPass(user),
    pass: Utils.messUserPass(pass),
    browserPaths,
    browser,
    chromedriverPaths
};