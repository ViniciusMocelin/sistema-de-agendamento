#!/bin/bash

# Script para corrigir superuser em produção
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

echo -e "${BLUE}=== CORREÇÃO DE SUPERUSER EM PRODUÇÃO ===${NC}"
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

# Função para verificar usuário via SSH
check_user_via_ssh() {
    echo -e "${YELLOW}Verificando usuário na EC2...${NC}"
    
    # Executar comando na EC2
    ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF
        set -e
        
        echo "🔍 Verificando usuário @4minds..."
        
        # Ir para diretório da aplicação
        cd /home/django/sistema-agendamento
        
        # Ativar ambiente virtual
        source venv/bin/activate
        
        # Verificar se usuário existe
        echo "📝 Verificando usuário no banco..."
        python manage.py shell << 'PYTHON_EOF'
from django.contrib.auth import get_user_model
User = get_user_model()

username = "@4minds"
if User.objects.filter(username=username).exists():
    user = User.objects.get(username=username)
    print(f"✅ Usuário '{username}' encontrado!")
    print(f"📧 Email: {user.email}")
    print(f"🔑 É superuser: {user.is_superuser}")
    print(f"👨‍💼 É staff: {user.is_staff}")
    print(f"✅ Está ativo: {user.is_active}")
    print(f"📅 Data de criação: {user.date_joined}")
    print(f"📅 Último login: {user.last_login}")
    
    # Testar senha
    test_password = "@4mindsPassword"
    if user.check_password(test_password):
        print("✅ Senha está correta!")
    else:
        print("❌ Senha está incorreta!")
        print("💡 Redefinindo senha...")
        user.set_password(test_password)
        user.save()
        print("✅ Senha redefinida com sucesso!")
else:
    print(f"❌ Usuário '{username}' não encontrado!")
    print("💡 Criando usuário...")
    user = User.objects.create_superuser(
        username=username,
        email="admin@4minds.com",
        password="@4mindsPassword"
    )
    print(f"✅ Usuário '{username}' criado com sucesso!")

# Listar todos os usuários
print("\n👥 Todos os usuários do sistema:")
users = User.objects.all()
for user in users:
    print(f"👤 {user.username} (superuser: {user.is_superuser}, staff: {user.is_staff}, ativo: {user.is_active})")
PYTHON_EOF
        
        echo "✅ Verificação concluída!"
EOF
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Verificação executada com sucesso na EC2${NC}"
    else
        echo -e "${RED}❌ Erro durante verificação${NC}"
        exit 1
    fi
}

# Função para testar login via curl
test_login() {
    echo -e "${YELLOW}Testando login via HTTP...${NC}"
    
    # Fazer uma requisição para a página de admin
    if curl -f -s "http://$EC2_IP/admin/" > /dev/null; then
        echo -e "${GREEN}✅ Admin está acessível${NC}"
    else
        echo -e "${YELLOW}⚠️ Admin pode não estar acessível${NC}"
    fi
}

# Função para mostrar informações finais
show_final_info() {
    echo ""
    echo -e "${GREEN}=== VERIFICAÇÃO CONCLUÍDA ===${NC}"
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
    echo "3. Se ainda não funcionar, verifique os logs"
    echo ""
    echo -e "${BLUE}🔧 Comandos úteis:${NC}"
    echo -e "${YELLOW}SSH:${NC} ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP"
    echo -e "${YELLOW}Logs:${NC} ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP 'sudo journalctl -u django -f'"
    echo ""
    echo -e "${GREEN}🎉 Verificação concluída!${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando verificação e correção...${NC}"
    
    check_prerequisites
    check_infrastructure
    get_ec2_ip
    check_user_via_ssh
    test_login
    show_final_info
}

# Verificar se foi chamado com --help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Script para Verificar e Corrigir Superuser em Produção"
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
    echo "  4. Verificar usuário no banco"
    echo "  5. Corrigir senha se necessário"
    echo "  6. Criar usuário se não existir"
    echo ""
    exit 0
fi

# Executar função principal
main "$@"
