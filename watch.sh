#!/bin/bash

# Script para watch/desenvolvimento da extensão Paste Guard
# Monitora mudanças e reconstrói automaticamente

set -e

echo "👀 Iniciando modo watch para desenvolvimento..."

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}📁 Monitorando diretório: $BASE_DIR${NC}"
echo -e "${YELLOW}💡 Dica: Mantenha chrome://extensions/ aberto e recarregue a extensão após mudanças${NC}"

# Função para fazer build
build_extension() {
    echo -e "\n${YELLOW}🔄 Detectada mudança, fazendo rebuild...${NC}"
    ./build.sh
    echo -e "${GREEN}✅ Rebuild concluído! Recarregue a extensão no Chrome${NC}"
    echo -e "${BLUE}⏰ $(date '+%H:%M:%S') - Aguardando próximas mudanças...${NC}"
}

# Verificar se fswatch está instalado
if ! command -v fswatch &> /dev/null; then
    echo -e "${YELLOW}⚠️  fswatch não encontrado. Instalando...${NC}"
    if command -v brew &> /dev/null; then
        brew install fswatch
    else
        echo -e "${RED}❌ Por favor instale fswatch manualmente:${NC}"
        echo -e "macOS: brew install fswatch"
        echo -e "Linux: apt-get install fswatch ou yum install fswatch"
        exit 1
    fi
fi

# Build inicial
build_extension

# Monitorar mudanças
echo -e "${GREEN}🎯 Monitorando arquivos... (Ctrl+C para parar)${NC}"

fswatch -o \
    --exclude="build/" \
    --exclude="dist/" \
    --exclude="node_modules/" \
    --exclude=".git/" \
    --exclude="*.log" \
    --exclude="*.tmp" \
    . | while read f; do
    build_extension
done
