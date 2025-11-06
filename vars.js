/**
 * Configurações do Modem VIVO
 * 
 * IMPORTANTE: As credenciais são ofuscadas usando XOR (0x1f)
 * Para alterar usuário/senha, edite os valores em texto claro
 * e a função messUserPass() em utils.js fará a conversão
 * Padrao:
 * IP = "192.168.15.1";   // IP do modem (ip padrao)
 * user = "admin";         // Usuário (admin)
 * pass = "sua-senha";     // Senha (se encontra etiquetado no aparelho da vivo)
 */


const Utils = require("./utils");

// IP do modem (padrão VIVO Fibra)
const IP = "192.168.15.1";

// Credenciais (ofuscadas)
const user = "admin";
const pass = "rpgrs65e"; // Senha ofuscada com XOR

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