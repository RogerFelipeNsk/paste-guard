# Paste Guard - Chrome Extension

Extensão para prevenir vazamento acidental de dados sensíveis através do clipboard.

## 🚀 Desenvolvimento

### Comandos Disponíveis

```bash
# Build da extensão
npm run build
# ou
./build.sh

# Modo desenvolvimento (rebuild automático)
npm run watch
# ou
./watch.sh

# Limpeza de arquivos temporários
npm run clean

# Validação de arquivos JSON
npm run validate

# Atualização de versão automática
npm run version:patch   # 1.0.0 -> 1.0.1
npm run version:minor   # 1.0.0 -> 1.1.0
npm run version:major   # 1.0.0 -> 2.0.0
```

### 🔧 Instalação para Desenvolvimento

1. Clone o repositório
2. Execute `chmod +x build.sh watch.sh` para dar permissão aos scripts
3. Execute `npm run build` para criar o build
4. Abra `chrome://extensions/`
5. Ative "Modo do desenvolvedor"
6. Clique em "Carregar extensão sem compactação"
7. Selecione a pasta `build/`

### 📦 Deploy para Chrome Web Store

1. Execute `npm run build`
2. O arquivo ZIP será criado em `dist/paste-guard-v[versão].zip`
3. Acesse [Chrome Web Store Developer Console](https://chrome.google.com/webstore/devconsole/)
4. Faça upload do arquivo ZIP

### 🔄 Desenvolvimento Contínuo

Para desenvolvimento ativo, use:
```bash
npm run watch
```

Isso monitora mudanças nos arquivos e reconstrói automaticamente a extensão.

## 📁 Estrutura do Projeto

```
paste-guard/
├── manifest.json       # Manifest da extensão
├── content.js         # Script principal de detecção
├── landing.html       # Página de configurações
├── _locales/          # Arquivos de internacionalização
│   ├── en/messages.json
│   └── pt/messages.json
├── icons/             # Ícones da extensão
├── build.sh          # Script de build
├── watch.sh          # Script de desenvolvimento
├── package.json      # Configurações NPM
└── README.md         # Este arquivo
```

## 🛡️ Funcionalidades

- Detecção de API keys, tokens e secrets
- Suporte para AWS, Google Cloud, Azure
- Detecção de credenciais de banco de dados
- Tokens de GitHub, GitLab, Discord, Slack
- Chaves SSH e certificados
- URLs com credenciais embutidas
- E muito mais...

## 🌍 Idiomas Suportados

- Inglês (en)
- Português (pt)

Para adicionar novos idiomas, crie uma pasta em `_locales/[código-idioma]/` com o arquivo `messages.json`.
