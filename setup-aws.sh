#!/bin/bash

# Script de Configuração da Infraestrutura AWS
# Sistema de Agendamento

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    # Verificar AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI não está instalado. Instale em: https://aws.amazon.com/cli/"
    fi
    
    # Verificar Terraform
    if ! command -v terraform &> /dev/null; then
        error "Terraform não está instalado. Instale em: https://terraform.io/downloads"
    fi
    
    # Verificar Git
    if ! command -v git &> /dev/null; then
        error "Git não está instalado"
    fi
    
    success "Todas as dependências estão instaladas"
}

# Configurar AWS CLI
setup_aws() {
    log "Configurando AWS CLI..."
    
    # Verificar se AWS CLI está configurado
    if ! aws sts get-caller-identity &> /dev/null; then
        warning "AWS CLI não está configurado. Configure com: aws configure"
        read -p "Digite sua Access Key ID: " AWS_ACCESS_KEY_ID
        read -p "Digite sua Secret Access Key: " AWS_SECRET_ACCESS_KEY
        read -p "Digite sua região (ex: us-east-1): " AWS_DEFAULT_REGION
        
        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
        aws configure set default.region "$AWS_DEFAULT_REGION"
    fi
    
    success "AWS CLI configurado"
}

# Configurar chave SSH
setup_ssh() {
    log "Configurando chave SSH..."
    
    # Verificar se chave SSH existe
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        warning "Chave SSH não encontrada. Gerando nova chave..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    success "Chave SSH configurada"
}

# Configurar Terraform
setup_terraform() {
    log "Configurando Terraform..."
    
    cd aws-infrastructure
    
    # Verificar se terraform.tfvars existe
    if [ ! -f "terraform.tfvars" ]; then
        warning "Arquivo terraform.tfvars não encontrado. Criando a partir do exemplo..."
        cp terraform.tfvars.example terraform.tfvars
        
        # Solicitar configurações
        read -p "Digite a senha do banco de dados: " DB_PASSWORD
        read -p "Digite o domínio (opcional): " DOMAIN_NAME
        read -p "Digite o email para notificações: " NOTIFICATION_EMAIL
        
        # Atualizar terraform.tfvars
        sed -i "s/sua_senha_super_segura_aqui/$DB_PASSWORD/g" terraform.tfvars
        sed -i "s/domain_name = \"\"/domain_name = \"$DOMAIN_NAME\"/g" terraform.tfvars
        sed -i "s/seu-email@example.com/$NOTIFICATION_EMAIL/g" terraform.tfvars
        
        success "terraform.tfvars configurado"
    fi
    
    # Inicializar Terraform
    terraform init
    
    success "Terraform inicializado"
}

# Aplicar infraestrutura
deploy_infrastructure() {
    log "Aplicando infraestrutura com Terraform..."
    
    cd aws-infrastructure
    
    # Planejar mudanças
    log "Planejando mudanças..."
    terraform plan -out=tfplan
    
    # Aplicar mudanças
    log "Aplicando mudanças..."
    terraform apply tfplan
    
    # Obter outputs
    EC2_IP=$(terraform output -raw ec2_public_ip)
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
    S3_BUCKET=$(terraform output -raw s3_bucket_name)
    
    success "Infraestrutura criada com sucesso!"
    log "EC2 IP: $EC2_IP"
    log "RDS Endpoint: $RDS_ENDPOINT"
    log "S3 Bucket: $S3_BUCKET"
    
    # Salvar informações em arquivo
    cat > ../infrastructure-info.txt << EOF
Infraestrutura AWS Criada
========================

EC2 IP: $EC2_IP
RDS Endpoint: $RDS_ENDPOINT
S3 Bucket: $S3_BUCKET

Aplicação: http://$EC2_IP
Admin: http://$EC2_IP/admin/
SSH: ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP

Criado em: $(date)
EOF
    
    success "Informações salvas em infrastructure-info.txt"
}

# Testar conectividade
test_connectivity() {
    log "Testando conectividade..."
    
    # Obter IP da EC2
    EC2_IP=$(cd aws-infrastructure && terraform output -raw ec2_public_ip)
    
    # Aguardar instância estar pronta
    log "Aguardando instância estar pronta..."
    sleep 60
    
    # Testar SSH
    log "Testando SSH..."
    if ssh -i ~/.ssh/id_rsa -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$EC2_IP "echo 'SSH OK'" &> /dev/null; then
        success "SSH funcionando"
    else
        warning "SSH não está funcionando ainda - aguarde alguns minutos"
    fi
    
    # Testar aplicação
    log "Testando aplicação..."
    if curl -f -s "http://$EC2_IP/health/" > /dev/null; then
        success "Aplicação funcionando"
    else
        warning "Aplicação ainda não está pronta - aguarde alguns minutos"
    fi
}

# Mostrar informações finais
show_final_info() {
    log "Configuração concluída!"
    
    # Obter informações da infraestrutura
    cd aws-infrastructure
    EC2_IP=$(terraform output -raw ec2_public_ip)
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
    S3_BUCKET=$(terraform output -raw s3_bucket_name)
    DOMAIN_NAME=$(terraform output -raw domain_name 2>/dev/null || echo "")
    
    echo ""
    echo "🎉 INFRAESTRUTURA CONFIGURADA COM SUCESSO!"
    echo "=========================================="
    echo ""
    echo "📊 INFORMAÇÕES DA INFRAESTRUTURA:"
    echo "  • EC2 IP: $EC2_IP"
    echo "  • RDS Endpoint: $RDS_ENDPOINT"
    echo "  • S3 Bucket: $S3_BUCKET"
    echo ""
    echo "🌐 ACESSO À APLICAÇÃO:"
    if [ -n "$DOMAIN_NAME" ]; then
        echo "  • URL: https://$DOMAIN_NAME"
    else
        echo "  • URL: http://$EC2_IP"
    fi
    echo "  • Admin: http://$EC2_IP/admin/"
    echo "  • Usuário: admin"
    echo "  • Senha: admin123"
    echo ""
    echo "🔑 CONEXÃO SSH:"
    echo "  ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP"
    echo ""
    echo "📝 PRÓXIMOS PASSOS:"
    echo "  1. Aguarde alguns minutos para a aplicação inicializar"
    echo "  2. Acesse a aplicação e configure seu sistema"
    echo "  3. Altere a senha do admin"
    echo "  4. Configure seu domínio (se aplicável)"
    echo "  5. Configure backup automático"
    echo "  6. Configure monitoramento"
    echo ""
    echo "⚠️  IMPORTANTE:"
    echo "  • Altere a senha do banco de dados"
    echo "  • Configure backup automático"
    echo "  • Monitore os custos da AWS"
    echo "  • Configure alertas de segurança"
    echo ""
}

# Função principal
main() {
    echo "🏗️  CONFIGURAÇÃO DA INFRAESTRUTURA AWS"
    echo "======================================"
    echo ""
    
    # Verificar argumentos
    case "${1:-setup}" in
        "setup")
            check_dependencies
            setup_aws
            setup_ssh
            setup_terraform
            deploy_infrastructure
            test_connectivity
            show_final_info
            ;;
        "destroy")
            warning "DESTRUINDO INFRAESTRUTURA..."
            cd aws-infrastructure
            terraform destroy -auto-approve
            success "Infraestrutura destruída"
            ;;
        "status")
            log "Verificando status da infraestrutura..."
            cd aws-infrastructure
            terraform show
            ;;
        "help")
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos:"
            echo "  setup   - Configurar infraestrutura completa (padrão)"
            echo "  destroy - Destruir infraestrutura"
            echo "  status  - Ver status da infraestrutura"
            echo "  help    - Mostrar esta ajuda"
            ;;
        *)
            error "Comando inválido: $1. Use 'help' para ver comandos disponíveis"
            ;;
    esac
}

# Executar função principal
main "$@"
