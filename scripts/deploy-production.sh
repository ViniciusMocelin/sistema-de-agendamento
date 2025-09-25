#!/bin/bash

# Script de Deploy Seguro para Produção
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
PROJECT_NAME="sistema-agendamento"
EC2_INSTANCE_ID="i-04d14b81170c26323"

echo -e "${BLUE}=== DEPLOY SEGURO PARA PRODUÇÃO ===${NC}"
echo -e "${BLUE}Sistema de Agendamento - 4Minds${NC}"
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
        echo -e "${YELLOW}E configure as variáveis de ambiente${NC}"
        exit 1
    fi
    
    # Verificar se SECRET_KEY foi alterada
    if grep -q "change-me-in-production" .env.production; then
        echo -e "${RED}❌ SECRET_KEY não foi alterada no .env.production${NC}"
        echo -e "${YELLOW}Execute: python scripts/generate-secret-key.py${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Pré-requisitos verificados${NC}"
}

# Função para executar testes
run_tests() {
    echo -e "${YELLOW}Executando testes...${NC}"
    
    if python scripts/run-tests.py; then
        echo -e "${GREEN}✅ Todos os testes passaram${NC}"
    else
        echo -e "${RED}❌ Testes falharam - Deploy cancelado${NC}"
        exit 1
    fi
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
    
    # Verificar status da RDS
    RDS_STATUS=$(aws rds describe-db-instances \
        --db-instance-identifier ${PROJECT_NAME}-postgres \
        --region $REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text 2>/dev/null || echo "not-found")
    
    echo -e "${BLUE}Status da RDS: ${RDS_STATUS}${NC}"
    
    if [[ "$RDS_STATUS" != "available" ]]; then
        echo -e "${RED}❌ Instância RDS não está disponível${NC}"
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

# Função para fazer backup antes do deploy
create_backup() {
    echo -e "${YELLOW}Criando backup...${NC}"
    
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup do banco de dados
    echo -e "${BLUE}Fazendo backup do banco de dados...${NC}"
    
    # Conectar via SSH e fazer backup
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF
        # Fazer backup do banco
        sudo -u postgres pg_dump agendamentos_db > /tmp/backup_\$(date +%Y%m%d_%H%M%S).sql
        
        # Backup dos arquivos estáticos
        sudo tar -czf /tmp/static_files_backup_\$(date +%Y%m%d_%H%M%S).tar.gz /home/django/sistema-agendamento/staticfiles/
        
        # Backup dos logs
        sudo tar -czf /tmp/logs_backup_\$(date +%Y%m%d_%H%M%S).tar.gz /var/log/django/
EOF
    
    echo -e "${GREEN}✅ Backup criado${NC}"
}

# Função para fazer deploy via SSH
deploy_via_ssh() {
    echo -e "${YELLOW}Iniciando deploy...${NC}"
    
    # Copiar arquivo .env.production para EC2
    echo -e "${BLUE}Copiando configurações...${NC}"
    scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no .env.production ubuntu@$EC2_IP:/tmp/
    
    # Executar deploy na EC2
    echo -e "${BLUE}Executando deploy na EC2...${NC}"
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF
        set -e
        
        echo "🔄 Iniciando processo de deploy..."
        
        # Ir para diretório da aplicação
        cd /home/django/sistema-agendamento
        
        # Fazer backup das configurações atuais
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        
        # Copiar novas configurações
        sudo cp /tmp/.env.production .env
        
        # Ativar ambiente virtual
        source venv/bin/activate
        
        # Instalar/atualizar dependências
        echo "📦 Instalando dependências..."
        pip install -r requirements.txt
        
        # Executar migrações
        echo "🗄️ Executando migrações..."
        python manage.py migrate --settings=core.settings_production
        
        # Coletar arquivos estáticos
        echo "📁 Coletando arquivos estáticos..."
        python manage.py collectstatic --noinput --settings=core.settings_production
        
        # Recarregar aplicação
        echo "🔄 Recarregando aplicação..."
        sudo systemctl restart django
        sudo systemctl restart nginx
        
        # Verificar status dos serviços
        echo "✅ Verificando status dos serviços..."
        sudo systemctl status django --no-pager -l
        sudo systemctl status nginx --no-pager -l
        
        echo "🎉 Deploy concluído com sucesso!"
EOF
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Deploy executado com sucesso${NC}"
    else
        echo -e "${RED}❌ Erro durante o deploy${NC}"
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

# Função para mostrar informações finais
show_final_info() {
    echo ""
    echo -e "${GREEN}=== DEPLOY CONCLUÍDO COM SUCESSO ===${NC}"
    echo ""
    echo -e "${BLUE}🌐 URL da aplicação:${NC} http://$EC2_IP"
    echo -e "${BLUE}🔑 Admin Django:${NC} http://$EC2_IP/admin/"
    echo -e "${BLUE}📊 Dashboard:${NC} http://$EC2_IP/dashboard/"
    echo ""
    echo -e "${BLUE}🔧 Comandos úteis:${NC}"
    echo -e "${YELLOW}SSH:${NC} ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP"
    echo -e "${YELLOW}Logs:${NC} ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP 'sudo journalctl -u django -f'"
    echo -e "${YELLOW}Status:${NC} ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP 'sudo systemctl status django'"
    echo ""
    echo -e "${BLUE}📋 Próximos passos:${NC}"
    echo "1. Teste a aplicação no navegador"
    echo "2. Configure SSL/HTTPS (opcional)"
    echo "3. Configure monitoramento"
    echo "4. Configure backup automatizado"
    echo ""
    echo -e "${GREEN}🎉 Sistema pronto para produção!${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando processo de deploy seguro...${NC}"
    
    check_prerequisites
    run_tests
    check_infrastructure
    get_ec2_ip
    create_backup
    deploy_via_ssh
    verify_deployment
    show_final_info
}

# Verificar se foi chamado com --help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Script de Deploy Seguro para Produção"
    echo ""
    echo "Uso: $0"
    echo ""
    echo "Pré-requisitos:"
    echo "  - AWS CLI configurado"
    echo "  - Arquivo .env.production configurado"
    echo "  - SECRET_KEY alterada"
    echo "  - Infraestrutura rodando"
    echo ""
    echo "O script irá:"
    echo "  1. Verificar pré-requisitos"
    echo "  2. Executar testes"
    echo "  3. Verificar infraestrutura"
    echo "  4. Criar backup"
    echo "  5. Fazer deploy"
    echo "  6. Verificar funcionamento"
    exit 0
fi

# Executar função principal
main "$@"
