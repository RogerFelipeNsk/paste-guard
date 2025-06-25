#!/bin/bash

# Script para automatizar o build e empacotamento da extensão Paste Guard
# Autor: Script gerado para automatizar deploy

set -e  # Para em caso de erro

echo "🚀 Iniciando build da extensão Paste Guard..."

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Diretório base
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$BASE_DIR/build"
DIST_DIR="$BASE_DIR/dist"

echo -e "${BLUE}📁 Diretório base: $BASE_DIR${NC}"

# Limpar diretórios anteriores
echo -e "${YELLOW}🧹 Limpando builds anteriores...${NC}"
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

# Listar arquivos que serão incluídos
echo -e "${BLUE}📋 Arquivos a serem incluídos:${NC}"
FILES_TO_COPY=(
    "manifest.json"
    "content.js"
    "landing.html"
    "_locales"
    "icons"
)

# Copiar arquivos necessários
echo -e "${YELLOW}📦 Copiando arquivos...${NC}"
for file in "${FILES_TO_COPY[@]}"; do
    if [ -e "$BASE_DIR/$file" ]; then
        cp -r "$BASE_DIR/$file" "$BUILD_DIR/"
        echo -e "${GREEN}✅ Copiado: $file${NC}"
    else
        echo -e "${RED}❌ Arquivo não encontrado: $file${NC}"
        exit 1
    fi
done

# Validar manifest.json
echo -e "${YELLOW}🔍 Validando manifest.json...${NC}"
if command -v jq &> /dev/null; then
    if jq empty "$BUILD_DIR/manifest.json" 2>/dev/null; then
        echo -e "${GREEN}✅ manifest.json é um JSON válido${NC}"
    else
        echo -e "${RED}❌ manifest.json contém erros de sintaxe${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  jq não instalado, pulando validação JSON${NC}"
fi

# Obter versão do manifest
VERSION=$(grep -o '"version": "[^"]*"' "$BUILD_DIR/manifest.json" | cut -d'"' -f4)
echo -e "${BLUE}📝 Versão detectada: $VERSION${NC}"

# Criar arquivo ZIP
ZIP_NAME="paste-guard-v$VERSION.zip"
echo -e "${YELLOW}📦 Criando arquivo ZIP: $ZIP_NAME${NC}"

cd "$BUILD_DIR"
zip -r "$DIST_DIR/$ZIP_NAME" . -x "*.DS_Store" "*/.*"
cd "$BASE_DIR"

# Verificar tamanho do arquivo
FILE_SIZE=$(ls -lh "$DIST_DIR/$ZIP_NAME" | awk '{print $5}')
echo -e "${GREEN}✅ Build concluído!${NC}"
echo -e "${GREEN}📁 Arquivo criado: $DIST_DIR/$ZIP_NAME ($FILE_SIZE)${NC}"

# Mostrar estrutura do build
echo -e "${BLUE}📋 Estrutura do build:${NC}"
cd "$BUILD_DIR" && find . -type f | sort

# Instruções finais
echo -e "\n${GREEN}🎉 Build finalizado com sucesso!${NC}"
echo -e "${YELLOW}📤 Para fazer upload:${NC}"
echo -e "1. Acesse: https://chrome.google.com/webstore/devconsole/"
echo -e "2. Selecione sua extensão"
echo -e "3. Faça upload do arquivo: ${BLUE}$DIST_DIR/$ZIP_NAME${NC}"
echo -e "\n${YELLOW}🔧 Para desenvolvimento local:${NC}"
echo -e "1. Abra chrome://extensions/"
echo -e "2. Ative 'Modo do desenvolvedor'"
echo -e "3. Clique em 'Carregar extensão sem compactação'"
echo -e "4. Selecione a pasta: ${BLUE}$BUILD_DIR${NC}"
