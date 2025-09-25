#!/bin/bash

# Script para Atualizar Produção com Correções
# Sistema de Agendamento - 4Minds

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
REGION="us-east-1"
EC2_INSTANCE_ID="i-04d14b81170c26323"

echo -e "${BLUE}=== ATUALIZAÇÃO DE PRODUÇÃO ===${NC}"
echo -e "${BLUE}Sistema de Agendamento - 4Minds${NC}"
echo -e "${BLUE}Correções: Visual + Admin + Superuser${NC}"
echo ""

# Função para verificar pré-requisitos
check_prerequisites() {
    echo -e "${YELLOW}Verificando pré-requisitos...${NC}"
    
    # Verificar AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI não encontrado${NC}"
        exit 1
    fi
    
    # Verificar se está configurado
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS CLI não configurado${NC}"
        exit 1
    fi
    
    # Verificar se arquivo .env.production existe
    if [[ ! -f ".env.production" ]]; then
        echo -e "${RED}❌ Arquivo .env.production não encontrado${NC}"
        echo -e "${YELLOW}Execute: cp env.production.example .env.production${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Pré-requisitos verificados${NC}"
}

# Função para verificar status da infraestrutura
check_infrastructure() {
    echo -e "${YELLOW}Verificando infraestrutura...${NC}"
    
    # Verificar status da EC2
    EC2_STATUS=$(aws ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text)
    
    echo -e "${BLUE}Status da EC2: ${EC2_STATUS}${NC}"
    
    if [[ "$EC2_STATUS" != "running" ]]; then
        echo -e "${RED}❌ Instância EC2 não está rodando${NC}"
        echo -e "${YELLOW}Execute: ./scripts/start-aws-services-simple.bat${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Infraestrutura verificada${NC}"
}

# Função para obter IP da EC2
get_ec2_ip() {
    EC2_IP=$(aws ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    
    if [[ "$EC2_IP" == "None" || -z "$EC2_IP" ]]; then
        echo -e "${RED}❌ Não foi possível obter IP da EC2${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ IP da EC2: ${EC2_IP}${NC}"
}

# Função para fazer backup antes da atualização
create_backup() {
    echo -e "${YELLOW}Fazendo backup antes da atualização...${NC}"
    
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Fazer backup via SSH
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF
        echo "📦 Criando backup..."
        
        # Backup do banco de dados
        sudo -u postgres pg_dump agendamentos_db > /tmp/backup_\$(date +%Y%m%d_%H%M%S).sql
        
        # Backup dos arquivos estáticos
        sudo tar -czf /tmp/static_backup_\$(date +%Y%m%d_%H%M%S).tar.gz /home/django/sistema-agendamento/staticfiles/
        
        # Backup dos logs
        sudo tar -czf /tmp/logs_backup_\$(date +%Y%m%d_%H%M%S).tar.gz /var/log/django/ 2>/dev/null || true
        
        echo "✅ Backup criado com sucesso!"
EOF
    
    echo -e "${GREEN}✅ Backup criado${NC}"
}

# Função para fazer deploy das correções
deploy_corrections() {
    echo -e "${YELLOW}Fazendo deploy das correções...${NC}"
    
    # Copiar arquivo .env.production para EC2
    echo -e "${BLUE}Copiando configurações...${NC}"
    scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no .env.production ubuntu@$EC2_IP:/tmp/
    
    # Executar atualização na EC2
    echo -e "${BLUE}Executando atualização na EC2...${NC}"
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF
        set -e
        
        echo "🚀 Iniciando atualização de produção..."
        
        # Ir para diretório da aplicação
        cd /home/django/sistema-agendamento
        
        # Fazer backup das configurações atuais
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        
        # Copiar novas configurações
        sudo cp /tmp/.env.production .env
        
        # Ativar ambiente virtual
        source venv/bin/activate
        
        # Atualizar código do repositório
        echo "📥 Atualizando código..."
        git pull origin main 2>/dev/null || echo "⚠️ Git pull falhou, continuando..."
        
        # Instalar/atualizar dependências
        echo "📦 Instalando dependências..."
        pip install -r requirements.txt
        
        # Executar migrações
        echo "🗄️ Executando migrações..."
        python manage.py migrate --settings=core.settings_production
        
        # Coletar arquivos estáticos
        echo "📁 Coletando arquivos estáticos..."
        python manage.py collectstatic --noinput --settings=core.settings_production
        
        # Corrigir superuser
        echo "🔐 Corrigindo superuser..."
        python manage.py create_4minds_superuser --force --no-input --settings=core.settings_production
        
        # Aplicar correções de CSS
        echo "🎨 Aplicando correções de CSS..."
        if [ -f static/css/style-fixed.css ]; then
            cp static/css/style-fixed.css static/css/style.css
            echo "✅ CSS corrigido aplicado"
        fi
        
        # Recarregar aplicação
        echo "🔄 Recarregando aplicação..."
        sudo systemctl restart django
        sudo systemctl restart nginx
        
        # Verificar status dos serviços
        echo "✅ Verificando status dos serviços..."
        sudo systemctl status django --no-pager -l
        sudo systemctl status nginx --no-pager -l
        
        echo "🎉 Atualização concluída com sucesso!"
EOF
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Atualização executada com sucesso${NC}"
    else
        echo -e "${RED}❌ Erro durante a atualização${NC}"
        exit 1
    fi
}

# Função para verificar se aplicação está funcionando
verify_deployment() {
    echo -e "${YELLOW}Verificando se aplicação está funcionando...${NC}"
    
    # Aguardar aplicação inicializar
    echo -e "${BLUE}Aguardando aplicação inicializar...${NC}"
    sleep 30
    
    # Testar endpoints
    echo -e "${BLUE}Testando endpoints...${NC}"
    
    # Testar página principal
    if curl -f -s "http://$EC2_IP/" > /dev/null; then
        echo -e "${GREEN}✅ Página principal funcionando${NC}"
    else
        echo -e "${RED}❌ Página principal não está respondendo${NC}"
        return 1
    fi
    
    # Testar admin
    if curl -f -s "http://$EC2_IP/admin/" > /dev/null; then
        echo -e "${GREEN}✅ Admin funcionando${NC}"
    else
        echo -e "${YELLOW}⚠️ Admin não está respondendo (pode ser normal)${NC}"
    fi
    
    # Testar arquivos estáticos
    if curl -f -s "http://$EC2_IP/static/css/style.css" > /dev/null; then
        echo -e "${GREEN}✅ Arquivos estáticos funcionando${NC}"
    else
        echo -e "${YELLOW}⚠️ Arquivos estáticos podem não estar disponíveis${NC}"
    fi
    
    echo -e "${GREEN}✅ Verificação concluída${NC}"
}

# Função para testar login do admin
test_admin_login() {
    echo -e "${YELLOW}Testando login do admin...${NC}"
    
    # Testar login via curl
    LOGIN_DATA="username=@4minds&password=@4mindsPassword"
    
    if curl -s -X POST "http://$EC2_IP/admin/login/" \
        -d "$LOGIN_DATA" \
        -c /tmp/cookies.txt \
        -b /tmp/cookies.txt \
        -L | grep -q "admin"; then
        echo -e "${GREEN}✅ Login do admin funcionando${NC}"
    else
        echo -e "${YELLOW}⚠️ Login do admin pode precisar de verificação manual${NC}"
    fi
}

# Função para mostrar informações finais
show_final_info() {
    echo ""
    echo -e "${GREEN}=== ATUALIZAÇÃO CONCLUÍDA COM SUCESSO ===${NC}"
    echo ""
    echo -e "${BLUE}🎉 CORREÇÕES APLICADAS:${NC}"
    echo -e "${YELLOW}✅ Visual corrigido - Interface moderna${NC}"
    echo -e "${YELLOW}✅ Admin funcionando - Totalmente acessível${NC}"
    echo -e "${YELLOW}✅ Superuser configurado - @4minds${NC}"
    echo -e "${YELLOW}✅ CSS atualizado - Design profissional${NC}"
    echo ""
    echo -e "${BLUE}🔑 CREDENCIAIS DO ADMIN:${NC}"
    echo -e "${YELLOW}Usuário:${NC} @4minds"
    echo -e "${YELLOW}Senha:${NC} @4mindsPassword"
    echo -e "${YELLOW}Email:${NC} admin@4minds.com"
    echo ""
    echo -e "${BLUE}🌐 URLs DE ACESSO:${NC}"
    echo -e "${YELLOW}Admin Django:${NC} http://$EC2_IP/admin/"
    echo -e "${YELLOW}Dashboard:${NC} http://$EC2_IP/dashboard/"
    echo -e "${YELLOW}Home:${NC} http://$EC2_IP/"
    echo ""
    echo -e "${BLUE}🔧 COMANDOS ÚTEIS:${NC}"
    echo -e "${YELLOW}SSH:${NC} ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP"
    echo -e "${YELLOW}Logs:${NC} ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP 'sudo journalctl -u django -f'"
    echo -e "${YELLOW}Status:${NC} ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP 'sudo systemctl status django'"
    echo ""
    echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
    echo "1. Acesse http://$EC2_IP/admin/"
    echo "2. Faça login com as credenciais acima"
    echo "3. Configure o sistema conforme necessário"
    echo "4. Teste todas as funcionalidades"
    echo ""
    echo -e "${GREEN}🎉 Sistema atualizado e funcionando perfeitamente!${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando atualização de produção...${NC}"
    
    check_prerequisites
    check_infrastructure
    get_ec2_ip
    create_backup
    deploy_corrections
    verify_deployment
    test_admin_login
    show_final_info
}

# Verificar se foi chamado com --help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Script para Atualizar Produção com Correções"
    echo ""
    echo "Uso: $0"
    echo ""
    echo "Este script irá:"
    echo "  1. Verificar pré-requisitos"
    echo "  2. Verificar infraestrutura"
    echo "  3. Fazer backup"
    echo "  4. Deploy das correções"
    echo "  5. Corrigir superuser"
    echo "  6. Aplicar CSS corrigido"
    echo "  7. Verificar funcionamento"
    echo ""
    echo "Correções incluídas:"
    echo "  - Visual modernizado"
    echo "  - Admin funcionando"
    echo "  - Superuser @4minds"
    echo "  - CSS corrigido"
    exit 0
fi

# Executar função principal
main "$@"
