#!/bin/bash

# Script para criar superuser em produção
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

echo -e "${BLUE}=== CRIAÇÃO DE SUPERUSER EM PRODUÇÃO ===${NC}"
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

# Função para criar superuser via SSH
create_superuser_via_ssh() {
    echo -e "${YELLOW}Criando superuser na EC2...${NC}"
    
    # Executar comando na EC2
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF
        set -e
        
        echo "🔐 Criando superuser da 4Minds..."
        
        # Ir para diretório da aplicação
        cd /home/django/sistema-agendamento
        
        # Ativar ambiente virtual
        source venv/bin/activate
        
        # Executar comando para criar superuser
        echo "📝 Executando comando Django..."
        python manage.py create_4minds_superuser --no-input
        
        echo "✅ Superuser criado com sucesso!"
EOF
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Superuser criado com sucesso na EC2${NC}"
    else
        echo -e "${RED}❌ Erro ao criar superuser${NC}"
        exit 1
    fi
}

# Função para verificar se o superuser foi criado
verify_superuser() {
    echo -e "${YELLOW}Verificando se superuser foi criado...${NC}"
    
    # Testar login via curl (se possível)
    echo -e "${BLUE}Testando acesso ao admin...${NC}"
    
    # Fazer uma requisição para a página de admin
    if curl -f -s "http://$EC2_IP/admin/" > /dev/null; then
        echo -e "${GREEN}✅ Admin está acessível${NC}"
    else
        echo -e "${YELLOW}⚠️ Admin pode não estar acessível (normal se precisar de login)${NC}"
    fi
}

# Função para mostrar informações finais
show_final_info() {
    echo ""
    echo -e "${GREEN}=== SUPERUSER CRIADO COM SUCESSO ===${NC}"
    echo ""
    echo -e "${BLUE}👤 Credenciais do Superuser:${NC}"
    echo -e "${YELLOW}Usuário:${NC} @4minds"
    echo -e "${YELLOW}Senha:${NC} @4mindsPassword"
    echo -e "${YELLOW}Email:${NC} admin@4minds.com"
    echo ""
    echo -e "${BLUE}🌐 URLs de Acesso:${NC}"
    echo -e "${YELLOW}Admin Django:${NC} http://$EC2_IP/admin/"
    echo -e "${YELLOW}Dashboard:${NC} http://$EC2_IP/dashboard/"
    echo ""
    echo -e "${BLUE}📋 Próximos passos:${NC}"
    echo "1. Acesse http://$EC2_IP/admin/"
    echo "2. Faça login com as credenciais acima"
    echo "3. Configure o sistema conforme necessário"
    echo ""
    echo -e "${GREEN}🎉 Superuser pronto para uso!${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando criação de superuser...${NC}"
    
    check_prerequisites
    check_infrastructure
    get_ec2_ip
    create_superuser_via_ssh
    verify_superuser
    show_final_info
}

# Verificar se foi chamado com --help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Script para Criar Superuser em Produção"
    echo ""
    echo "Uso: $0"
    echo ""
    echo "Pré-requisitos:"
    echo "  - AWS CLI configurado"
    echo "  - Infraestrutura rodando"
    echo "  - Chave SSH configurada"
    echo ""
    echo "O script irá:"
    echo "  1. Verificar pré-requisitos"
    echo "  2. Verificar infraestrutura"
    echo "  3. Conectar na EC2"
    echo "  4. Criar superuser"
    echo "  5. Verificar criação"
    echo ""
    echo "Credenciais que serão criadas:"
    echo "  Usuário: @4minds"
    echo "  Senha: @4mindsPassword"
    echo "  Email: admin@4minds.com"
    exit 0
fi

# Executar função principal
main "$@"
