#!/bin/bash

# Script completo para validação, build e empacotamento da extensão Paste Guard
# Executa todas as verificações de segurança e gera o build final

set -e  # Para em caso de erro

echo "🚀 Iniciando processo completo de build da extensão Paste Guard..."

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Diretório base
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$BASE_DIR/build"
DIST_DIR="$BASE_DIR/dist"

echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}🔧 PASTE GUARD - BUILD AUTOMATIZADO${NC}"
echo -e "${CYAN}===============================================${NC}"

# Função para imprimir seção
print_section() {
    echo -e "\n${CYAN}📋 $1${NC}"
    echo -e "${CYAN}$(printf '%.0s-' {1..40})${NC}"
}

# Função para reportar sucesso
report_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função para reportar erro e sair
report_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Função para reportar aviso
report_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 1. VERIFICAÇÃO DE SEGURANÇA
print_section "VERIFICAÇÃO DE SEGURANÇA"

echo -e "${YELLOW}🔐 Executando verificação de segurança...${NC}"

# Contador de problemas de segurança
SECURITY_ISSUES=0

# Verificar arquivos sensíveis
echo "📁 Verificando arquivos sensíveis..."
SENSITIVE_FILES=(
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    ".env"
    ".env.*"
    "secrets.json"
    "config.json"
    "credentials.json"
    "*.crx"
)

for pattern in "${SENSITIVE_FILES[@]}"; do
    if find . -name "$pattern" -not -path "./build/*" -not -path "./dist/*" | grep -q .; then
        report_error "Arquivo sensível encontrado: $pattern"
    fi
done
report_success "Nenhum arquivo sensível encontrado"

# Verificar padrões suspeitos no código
echo "📄 Verificando padrões suspeitos no código..."
SUSPICIOUS_PATTERNS=(
    "AKIA[0-9A-Z]{16}"
    "ASIA[0-9A-Z]{16}"
    "sk_live_[0-9a-zA-Z]{24}"
    "pk_live_[0-9a-zA-Z]{24}"
    "xox[bpars]-[0-9a-zA-Z-]{10,48}"
    "gh[pousr]_[A-Za-z0-9_]{36,251}"
    "glpat-[a-zA-Z0-9_\-]{20}"
    "AIza[0-9A-Za-z\-_]{35}"
    "-----BEGIN PRIVATE KEY-----"
    "-----BEGIN RSA PRIVATE KEY-----"
)

FILES_TO_CHECK=$(find . -type f \( -name "*.js" -o -name "*.json" -o -name "*.html" \) \
    -not -path "./build/*" \
    -not -path "./dist/*" \
    -not -path "./node_modules/*" \
    -not -path "./.git/*")

for file in $FILES_TO_CHECK; do
    for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
        if grep -q "$pattern" "$file" 2>/dev/null; then
            line=$(grep "$pattern" "$file")
            if [[ $line != *"example"* ]] && [[ $line != *"exemplo"* ]] && [[ $line != *"//"* ]] && [[ $line != *"#"* ]]; then
                report_error "Padrão suspeito em $file: $pattern"
            fi
        fi
    done
done
report_success "Nenhum padrão suspeito encontrado"

# 2. VALIDAÇÃO DE ARQUIVOS JSON
print_section "VALIDAÇÃO DE ARQUIVOS JSON"

echo -e "${YELLOW}📋 Validando arquivos JSON...${NC}"

# Verificar se jq está instalado
if ! command -v jq &> /dev/null; then
    report_warning "jq não instalado, pulando validação JSON detalhada"
else
    JSON_FILES=$(find . -name "*.json" -not -path "./build/*" -not -path "./dist/*" -not -path "./node_modules/*")
    
    for json_file in $JSON_FILES; do
        echo "🔍 Validando $json_file..."
        if jq empty "$json_file" 2>/dev/null; then
            report_success "$(basename "$json_file") é válido"
        else
            report_error "$(basename "$json_file") contém erros de sintaxe"
        fi
    done
fi

# Validação específica do manifest.json
if [[ -f "manifest.json" ]]; then
    echo "🔍 Verificando manifest.json..."
    
    # Verificar campos obrigatórios
    REQUIRED_FIELDS=("manifest_version" "name" "version")
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! grep -q "\"$field\":" manifest.json; then
            report_error "Campo obrigatório '$field' não encontrado no manifest.json"
        fi
    done
    
    # Verificar se a versão é válida
    VERSION=$(grep -o '"version": "[^"]*"' manifest.json | cut -d'"' -f4)
    if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ ! $VERSION =~ ^[0-9]+\.[0-9]+$ ]]; then
        report_warning "Formato de versão '$VERSION' pode não ser padrão"
    fi
    
    report_success "manifest.json válido (versão: $VERSION)"
fi

# 3. VERIFICAÇÃO DE DEPENDÊNCIAS
print_section "VERIFICAÇÃO DE DEPENDÊNCIAS"

echo -e "${YELLOW}📦 Verificando estrutura do projeto...${NC}"

# Verificar arquivos essenciais
ESSENTIAL_FILES=(
    "manifest.json"
    "content.js"
    "_locales/en/messages.json"
    "_locales/pt/messages.json"
)

for file in "${ESSENTIAL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        report_success "$(basename "$file") encontrado"
    else
        report_error "Arquivo essencial não encontrado: $file"
    fi
done

# Verificar ícones
if [[ -d "icons" ]]; then
    ICON_FILES=$(find icons -name "*.png" | wc -l)
    if [[ $ICON_FILES -gt 0 ]]; then
        report_success "$ICON_FILES ícone(s) encontrado(s)"
    else
        report_warning "Nenhum ícone encontrado na pasta icons/"
    fi
else
    report_warning "Pasta icons/ não encontrada"
fi

# 4. LIMPEZA E PREPARAÇÃO
print_section "LIMPEZA E PREPARAÇÃO"

echo -e "${YELLOW}🧹 Limpando builds anteriores...${NC}"
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"
report_success "Diretórios de build limpos"

# 5. BUILD DA EXTENSÃO
print_section "BUILD DA EXTENSÃO"

echo -e "${YELLOW}📦 Copiando arquivos para build...${NC}"

FILES_TO_COPY=(
    "manifest.json"
    "content.js"
    "landing.html"
    "_locales"
    "icons"
)

for file in "${FILES_TO_COPY[@]}"; do
    if [[ -e "$file" ]]; then
        cp -r "$file" "$BUILD_DIR/"
        report_success "Copiado: $file"
    else
        report_error "Arquivo não encontrado: $file"
    fi
done

# 6. VALIDAÇÃO FINAL DO BUILD
print_section "VALIDAÇÃO FINAL DO BUILD"

echo -e "${YELLOW}🔍 Validando build gerado...${NC}"

# Verificar se todos os arquivos foram copiados
for file in "${FILES_TO_COPY[@]}"; do
    if [[ -e "$BUILD_DIR/$file" ]]; then
        report_success "Build contém: $file"
    else
        report_error "Build não contém: $file"
    fi
done

# Validar manifest.json do build
if command -v jq &> /dev/null; then
    if jq empty "$BUILD_DIR/manifest.json" 2>/dev/null; then
        BUILD_VERSION=$(grep -o '"version": "[^"]*"' "$BUILD_DIR/manifest.json" | cut -d'"' -f4)
        report_success "manifest.json do build é válido (v$BUILD_VERSION)"
    else
        report_error "manifest.json do build contém erros"
    fi
fi

# 7. CRIAÇÃO DO ARQUIVO ZIP
print_section "CRIAÇÃO DO ARQUIVO ZIP"

VERSION=$(grep -o '"version": "[^"]*"' "$BUILD_DIR/manifest.json" | cut -d'"' -f4)
ZIP_NAME="paste-guard-v$VERSION.zip"

echo -e "${YELLOW}📦 Criando arquivo ZIP: $ZIP_NAME${NC}"

cd "$BUILD_DIR"
zip -r "$DIST_DIR/$ZIP_NAME" . -x "*.DS_Store" "*/.*" >/dev/null 2>&1
cd "$BASE_DIR"

# Verificar se o ZIP foi criado com sucesso
if [[ -f "$DIST_DIR/$ZIP_NAME" ]]; then
    FILE_SIZE=$(ls -lh "$DIST_DIR/$ZIP_NAME" | awk '{print $5}')
    report_success "ZIP criado: $ZIP_NAME ($FILE_SIZE)"
else
    report_error "Falha ao criar arquivo ZIP"
fi

# 8. RELATÓRIO FINAL
print_section "RELATÓRIO FINAL"

echo -e "${GREEN}🎉 BUILD CONCLUÍDO COM SUCESSO!${NC}\n"

echo -e "${BLUE}📊 RESUMO:${NC}"
echo -e "• Versão: ${YELLOW}$VERSION${NC}"
echo -e "• Arquivo: ${YELLOW}$DIST_DIR/$ZIP_NAME${NC}"
echo -e "• Tamanho: ${YELLOW}$FILE_SIZE${NC}"

echo -e "\n${BLUE}📁 ESTRUTURA DO BUILD:${NC}"
cd "$BUILD_DIR" && find . -type f | sort | sed 's/^/  /'
cd "$BASE_DIR"

echo -e "\n${BLUE}🚀 PRÓXIMOS PASSOS:${NC}"
echo -e "• ${GREEN}Desenvolvimento:${NC} Carregue a pasta ${YELLOW}$BUILD_DIR${NC} no Chrome"
echo -e "• ${GREEN}Publicação:${NC} Faça upload do arquivo ${YELLOW}$ZIP_NAME${NC} na Chrome Web Store"

echo -e "\n${BLUE}🔗 LINKS ÚTEIS:${NC}"
echo -e "• Chrome Extensions: ${CYAN}chrome://extensions/${NC}"
echo -e "• Web Store Console: ${CYAN}https://chrome.google.com/webstore/devconsole/${NC}"

echo -e "\n${CYAN}===============================================${NC}"
echo -e "${GREEN}✅ PROCESSO COMPLETO FINALIZADO COM SUCESSO!${NC}"
echo -e "${CYAN}===============================================${NC}"
