/**
 * utils.js
 * Utilitários para automação do modem VIVO
 * - Ofuscação XOR para credenciais
 * - Configuração automática do WebDriver
 */

const Vars = require("./vars");

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


// ==================== EXPORTS ====================

module.exports = {
    // Ofuscação
    messUserPass,
};