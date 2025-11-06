# Projeto: modem-vivo Askey (RTF8115VW)

![GitHub repo size](https://img.shields.io/github/repo-size/edgardocorrea/modem-vivo)
![GitHub last commit](https://img.shields.io/github/last-commit/edgardocorrea/modem-vivo)
![GitHub license](https://img.shields.io/github/license/edgardocorrea/modem-vivo)

```Shell
╔════════════════════════════════════════════════════════════╗
║                     Projeto Modem VIVO                     ║
║        Desbloqueio avançado do modem by EdyOne             ║
╚════════════════════════════════════════════════════════════╝
```

## Sobre o projeto

Este projeto foi inspirado no trabalho do [Izurii](https://github.com/Izurii/modem-vivo-avancado/), com o objetivo de desbloquear o modo avançado do modem da Vivo modelo **Askey RTF8115VW**, permitindo ajustes em configurações de rede que normalmente são inacessíveis ao usuário comum.

Firmware utilizado:
```Shell
BR_SV_g13.12_RTF_TEF001_V8.33_V022
```

O navegador utilizado foi o **Chrome**, por apresentar melhor compatibilidade com o processo de automação.

## Estrutura do Repositório

```Shell
modem-vivo/
├── index.js             # Script principal com automação Selenium
├── vars.js              # Configurações (IP, senha)
├── utils.js             # Funções auxiliares
├── iniciar.bat          # Inicialização automática no Windows
├── chromedriver.exe     # Executável para Windows (baixar separadamente)
├── chromedriver         # Executável para Linux (baixar separadamente)
├── README.md            # Documentação do projeto
└── LICENSE              # Licença MIT
```

## Como usar

### Instalação automática

1. Abra o PowerShell como administrador (Windows + X → PowerShell (Admin))
2. Execute o comando abaixo:

```Powershell
irm https://raw.githubusercontent.com/edgardocorrea/modem-vivo/instalando/instalar.ps1 | iex
```

### Instalação manual

#### 1. Instalar Node.js LTS (v20)

- Site oficial: https://nodejs.org/en/download
- Versão recomendada: **20.19.5**
- Após instalar, verifique com:

```Powershell
node -v
```

#### 2. Baixar o ChromeDriver compatível

Você descobrira a versão do chrome que esta usando exemplo:

```Powershell
(Get-Item "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe").VersionInfo
```
Resultado (exemplo):

ProductVersion   FileVersion      FileName
--------------   -----------      --------
142.0.7444.60    142.0.7444.60    C:\Program Files\Google\Chrome\Application\chrome.exe


Outro método: Pelo próprio Chrome

Abra o Google Chrome
Digite na barra de endereço: chrome://version
Pressione Enter
Veja a primeira linha: Google Chrome → Versão completa

Depois verificar o ChromeDriver correspondente:

> Opção A: Site oficial (Recomendado)

Acesse: https://googlechromelabs.github.io/chrome-for-testing/

1. Procure pela sua versão exata do Chrome (ex: 142.0.7444.60)
2. Clique em chromedriver → win64
3. Baixe o arquivo .zip

> Opção B: Link direto (se souber a versão)

Substitua VERSION pela sua versão do Chrome:

https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/
VERSION/win64/chromedriver-win64.zip

--> Exemplo para Chrome 142.0.7444.60:

https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for- testing/142.0.7444.60/win64/chromedriver-win64.zip

--> Exemplo para Chrome 140.0.7339.80:
https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-
testing/140.0.7339.80/win64/chrome driver-win64.zip

Extrair o ChromeDriver

1. Extraia o arquivo .zip baixado
2. Dentro da pasta chromedriver-win64, encontre o arquivo chromedriver.exe
3. Copie o chromedriver.exe para a pasta raiz do projeto (onde estão os arquivos)

Estrutura correta:

```Shell
modem-vivo/
├── chromedriver.exe    ← Deve estar aqui
├── index.js
├── vars.js
├── utils.js
└── package.json
```

#### 3. Instalar Dependências

Abra o terminal ( CMD ) na pasta do projeto e digite:

npm install

Isso instalará:

1 selenium-webdriver - Automação do navegador
2 chromedriver - Driver do Chrome

Aguarde a instalação concluir. Deve aparecer algo como:

added 15 packages, and audited 16 packages in 3s


## Configuração de acesso (vars.js)

No arquivo `vars.js`, configure os dados de acesso ao modem:

```Javascript
const ip = "192.168.15.1";
const usuario = "admin";
const senha = "sua-senha"; // substitua pela senha do seu modem
```

A senha geralmente está na etiqueta na parte inferior do aparelho.

## Verificação com iniciar.bat

O script `iniciar.bat` realiza:

- Verificação da senha no `vars.js`
- Inicialização da automação

Execute-o na pasta do projeto (`C:\modem-vivo`).

## Requisitos técnicos

- Windows 10 ou superior
- Acesso ao IP do modem (ex: `192.168.15.1`)
- Navegador Chrome
- PowerShell 5.0+

## Avisos Legais

- Alterações podem afetar o desempenho do modem
- Faça backup antes de modificar configurações
- Existe opção de reset físico do modem
- O autor não se responsabiliza por danos

## Changelog

### v1.0.10 (2025)

- Detecção automática de fechamento da janela
- Documentação aprimorada
- Tratamento de erros melhorado
- Interface de logs otimizada

### v1.0.0 (2025)

- Versão inicial
- Login automático via API
- Desbloqueio de elementos

## 📄 Licença

Este projeto está licenciado sob os termos da [MIT License](LICENSE).  
Você pode usar, modificar e distribuir livremente, desde que mantenha os créditos ao autor original sobre este projeto: **Edgardo Correa**.

## Links úteis

- https://googlechromelabs.github.io/chrome-for-testing
- https://nodejs.org/
- https://www.selenium.dev/documentation/webdriver/
- [Projeto Izurii](https://github.com/Izurii/modem-vivo-avancado/)

## Autor

**EdyOne**

- GitHub: [https://github.com/edgardocorrea](https://github.com/edgardocorrea)

---

⭐ Se este projeto foi útil, considere dar uma estrela no GitHub!

