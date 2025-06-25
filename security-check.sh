#!/bin/bash

# Script de verificação de segurança para o repositório Paste Guard
# Verifica se há dados sensíveis antes do commit/push

echo "🔐 Verificando dados sensíveis no repositório..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Contador de problemas
ISSUES=0

# Função para reportar problema
report_issue() {
    echo -e "${RED}❌ $1${NC}"
    ((ISSUES++))
}

# Função para reportar OK
report_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função para reportar aviso
report_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Verificar arquivos que não devem estar no repositório
check_sensitive_files() {
    echo -e "\n📁 Verificando arquivos sensíveis..."
    
    # Arquivos que nunca devem estar no repo
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
            report_issue "Arquivo sensível encontrado: $pattern"
        fi
    done
    
    if [[ $ISSUES == 0 ]]; then
        report_ok "Nenhum arquivo sensível encontrado"
    fi
}

# Verificar conteúdo dos arquivos por padrões suspeitos
check_file_contents() {
    echo -e "\n📄 Verificando conteúdo dos arquivos..."
    
    # Padrões que indicam dados reais (não exemplos)
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
    
    # Arquivos para verificar (excluindo builds)
    FILES_TO_CHECK=$(find . -type f \( -name "*.js" -o -name "*.json" -o -name "*.html" -o -name "*.md" -o -name "*.sh" \) \
        -not -path "./build/*" \
        -not -path "./dist/*" \
        -not -path "./node_modules/*" \
        -not -path "./.git/*")
    
    for file in $FILES_TO_CHECK; do
        for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
            if grep -q "$pattern" "$file" 2>/dev/null; then
                # Verificar se é um exemplo/comentário
                line=$(grep "$pattern" "$file")
                if [[ $line == *"example"* ]] || [[ $line == *"exemplo"* ]] || [[ $line == *"//"* ]] || [[ $line == *"#"* ]]; then
                    report_warning "Possível exemplo em $file: $pattern"
                else
                    report_issue "Padrão suspeito em $file: $pattern"
                fi
            fi
        done
    done
    
    if [[ $ISSUES == 0 ]]; then
        report_ok "Conteúdo dos arquivos verificado"
    fi
}

# Verificar se .gitignore está configurado corretamente
check_gitignore() {
    echo -e "\n📝 Verificando .gitignore..."
    
    REQUIRED_PATTERNS=(
        "build/"
        "dist/"
        "node_modules/"
        ".env"
        "*.pem"
        "*.crx"
    )
    
    if [[ ! -f .gitignore ]]; then
        report_issue ".gitignore não encontrado"
        return
    fi
    
    for pattern in "${REQUIRED_PATTERNS[@]}"; do
        if ! grep -q "$pattern" .gitignore; then
            report_warning ".gitignore não contém: $pattern"
        fi
    done
    
    report_ok ".gitignore verificado"
}

# Verificar se há TODOs ou FIXMEs com informações sensíveis
check_todos() {
    echo -e "\n📋 Verificando TODOs e FIXMEs..."
    
    TODO_FILES=$(find . -type f \( -name "*.js" -o -name "*.json" -o -name "*.html" -o -name "*.md" \) \
        -not -path "./build/*" \
        -not -path "./dist/*" \
        -not -path "./node_modules/*" \
        -exec grep -l -i "TODO\|FIXME\|XXX\|HACK" {} \;)
    
    if [[ -n "$TODO_FILES" ]]; then
        for file in $TODO_FILES; do
            report_warning "TODOs/FIXMEs encontrados em: $file"
        done
    else
        report_ok "Nenhum TODO/FIXME encontrado"
    fi
}

# Verificar extensão ID placeholder
check_extension_placeholder() {
    echo -e "\n🆔 Verificando placeholders..."
    
    if grep -r "EXTENSION_ID" . --exclude-dir=build --exclude-dir=dist --exclude-dir=node_modules 2>/dev/null; then
        report_warning "Placeholder EXTENSION_ID encontrado (será atualizado após publicação)"
    else
        report_ok "Placeholders verificados"
    fi
}

# Executar todas as verificações
check_sensitive_files
check_file_contents
check_gitignore
check_todos
check_extension_placeholder

# Resultado final
echo -e "\n" + "="*50
if [[ $ISSUES == 0 ]]; then
    echo -e "${GREEN}🎉 Repositório seguro para commit/push!${NC}"
    echo -e "${GREEN}✅ Nenhum dado sensível encontrado${NC}"
    exit 0
else
    echo -e "${RED}🚨 $ISSUES problema(s) encontrado(s)!${NC}"
    echo -e "${RED}❌ Corrija os problemas antes de fazer commit/push${NC}"
    exit 1
fi
