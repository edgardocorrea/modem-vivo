# 🌐 modem-vivo Askey (RTF8115VW)

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://microsoft.com/powershell)
[![GitHub repo size](https://img.shields.io/github/repo-size/edgardocorrea/modem-vivo)](https://github.com/edgardocorrea/modem-vivo)
[![GitHub last commit](https://img.shields.io/github/last-commit/edgardocorrea/modem-vivo)](https://github.com/edgardocorrea/modem-vivo/commits/main)
[![Author](https://img.shields.io/badge/Author-EdyOne-blueviolet.svg)](https://github.com/edgardocorrea)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/edgardocorrea/modem-vivo/blob/main/LICENSE)
[![Made with](https://img.shields.io/badge/Made%20with%20❤️-by%20EdyOne-red.svg)](https://github.com/edgardocorrea)

```Shell
╔════════════════════════════════════════════════════════════╗
║                     Projeto Modem VIVO                     ║
║        Desbloqueio avançado do modem by EdyOne             ║
╚════════════════════════════════════════════════════════════╝
```

> **Firmware de referência:** `BR_SV_g13.12_RTF_TEF001_V8.33_V022`  
> **Navegador compatível:** Google Chrome

---

##  Visão Geral

Este projeto oferece uma solução de automação para desbloquear o **modo avançado** do modem Askey RTF8115VW, fornecido pela Vivo. Inspirado no trabalho de [Izurii](https://github.com/Izurii/modem-vivo-avancado/), este script utiliza Selenium WebDriver para interagir com a interface web do modem, liberando acesso a configurações de rede e parâmetros técnicos que são restritos ao usuário padrão.

A ferramenta foi desenvolvida para usuários que buscam um controle melhor sobre suas conexões de rede, WIFI e demais permitindo otimizações e ajustes finos que vão além das configurações convencionais(pagina avançada).

---

##  Estrutura do Projeto

A arquitetura do projeto foi organizada para facilitar a manutenção e a compreensão do código-fonte.

```Shell
modem-vivo/
├── index.js             # Módulo principal de automação Selenium
├── vars.js              # Arquivo de configuração (IP, credenciais)
├── utils.js             # Biblioteca de funções utilitárias
├── iniciar.bat          # Atalho para execução do script PowerShell (Windows)
├── iniciar.ps1          # Script de inicialização e automação (Windows)
├── package.json         # Manifesto do projeto com dependências (Node.js)
├── chromedriver.exe     # Binário do ChromeDriver para Windows
├── chromedriver         # Binário do ChromeDriver para Linux
├── README.md            # Documentação técnica do projeto
└── LICENSE              # Termos da licença MIT
```

---

##  Guia de Instalação e Uso

O projeto pode ser instalado e executado de duas maneiras: através de um script de instalação automática ou seguindo os passos manuais.

###  Instalação Automática (Recomendado)

1.  Abra uma sessão do **PowerShell com privilégios de Administrador**.
2.  Execute o seguinte comando para iniciar o processo automatizado:

    ```Powershell
    irm https://raw.githubusercontent.com/edgardocorrea/modem-vivo/instalando/instalar.ps1 | iex
    ```

Ao final do processo, um atalho para a aplicação será criado na área de trabalho.

---

###  Instalação Manual

#### 1. Instalação do Node.js (LTS v20+)

-   **Repositório oficial:** [https://nodejs.org/en/download](https://nodejs.org/en/download)
-   **Versão validada:** **20.19.5** ou posterior.
-   **Verificação de instalação:** Execute o comando `node -v` no terminal para confirmar a versão instalada.

#### 2. Configuração do ChromeDriver

**Passo A: Identificação da Versão do Google Chrome**

-   **Via PowerShell:**
    ```Powershell
    (Get-Item "C:\Program Files\Google\Chrome\Application\chrome.exe").VersionInfo
    ```
-   **Via Interface do Navegador:** Acesse `chrome://version` para obter a versão completa.

**Passo B: Download do ChromeDriver Correspondente**

-   **Opção A: Portal Oficial (Recomendado)**
    Acesse [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/), localize a versão exata do seu Chrome e baixe o arquivo `chromedriver-win64.zip`.

-   **Opção B: Link Direto**
    Utilize o modelo de URL abaixo, substituindo `VERSION` pela versão identificada:
    `https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/VERSION/win64/chromedriver-win64.zip`

**Passo C: Implantação do Executável**

1.  Descompacte o arquivo `.zip` baixado.
2.  Copie o executável `chromedriver.exe` para o diretório raiz do projeto.

#### 3. Instalação das Dependências

No terminal, na pasta do projeto, execute o gerenciador de pacotes do Node.js para instalar as dependências listadas no `package.json`:

```Powershell
npm install
```

---

## ️ Configuração de Acesso

Antes da execução, é necessário configurar as credenciais de acesso ao modem no arquivo `vars.js`:

```Javascript
const ip = "192.168.15.1";        // Endereço IP padrão do modem
const usuario = "admin";           // Nome de usuário padrão
const senha = "sua-senha-aqui";   // Substitua pela senha do seu modem
```

> **Nota:** A senha de administrador geralmente está disponível na etiqueta de informações do equipamento.

---

## ️ Execução da Aplicação

A execução é gerenciada pelo script `iniciar.ps1`, que realiza as verificações iniciais e inicia a automação.

-   **Via Atalho:** Utilize o atalho criado na área de trabalho durante a instalação automática.
-   **Via Diretório:** Execute o arquivo `iniciar.bat` localizado na raiz do projeto.

**Advertência:** A janela do console deve permanecer aberta durante toda a operação, pois é responsável por manter a sessão avançada ativa.

---

## ️ Desinstalação

Caso você não deseje mais utilizar a ferramenta, dentro do diretório consta um script de desinstalação completo para remover todos os componentes e arquivos criados durante a instalação, incluindo o atalho na área de trabalho.

### Como Desinstalar

1.  Abra uma sessão do **PowerShell com privilégios de Administrador**.
2.  Navegue até a pasta do projeto (ex: `C:\modem-vivo`).
3.  Execute o script de desinstalação:

    ```Powershell
    .\desinstalar.ps1
    ```

**Alternativamente**, você pode simplesmente executar o arquivo `desinstalar.bat` na pasta do projeto.

**O que o script de desinstalação faz:**
-   Remove o atalho da área de trabalho.
-   Exclui a pasta do projeto e todo o seu conteúdo.
-   Reverte quaisquer alterações feitas no sistema durante a instalação.

---

##  Termos de Responsabilidade

-   A modificação de configurações avançadas do modem pode impactar o desempenho e a estabilidade da rede.
-   É altamente recomendável criar um backup das configurações atuais antes de prosseguir.
-   O equipamento possui uma opção de reset físico para restauração das configurações de fábrica.
-   O autor não se responsabiliza por danos ou perdas de funcionalidade resultantes do uso desta ferramenta.

---

##  Registro de Alterações

### v1.0.10 (2025)
-   Implementação de detecção automática de encerramento da janela do navegador.
-   Revisão e aprimoramento da documentação técnica.
-   Refinamento no tratamento de exceções e logs de erro.
-   Otimização da interface de saída de logs.

### v1.0.0 (2025)
-   Lançamento inicial da ferramenta.
-   Implementação do fluxo de autenticação via API.
-   Desenvolvimento do módulo de desbloqueio de elementos da interface.

---

##  Licença

Este projeto é distribuído sob os termos da [Licença MIT](LICENSE). Você está livre para utilizar, modificar e distribuir o software, em conformidade com os termos estabelecidos.

---

##  Referências e Recursos

-   [Chrome for Testing (Downloads ChromeDriver)](https://googlechromelabs.github.io/chrome-for-testing/)
-   [Node.js](https://nodejs.org/)
-   [Documentação Oficial Selenium WebDriver](https://www.selenium.dev/documentation/webdriver/)
-   [Projeto de Referência - Izurii](https://github.com/Izurii/modem-vivo-avancado/)

---

## 👨‍💻 Autor

**EdyOne**

-   **GitHub:** [edgardocorrea](https://github.com/edgardocorrea)

---

Se este projeto te ajudou de alguma maneira, que tal deixar uma ⭐ no GitHub. Grato =D
```
