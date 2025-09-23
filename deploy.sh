#!/bin/bash

# Script de Deploy Automatizado para AWS
# Sistema de Agendamento

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# FunÃ§Ã£o para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN} $1${NC}"
}

warning() {
    echo -e "${YELLOW}  $1${NC}"
}

error() {
    echo -e "${RED} $1${NC}"
    exit 1
}

# Verificar se estamos no diretório correto
if [ ! -f "manage.py" ]; then
    error "Execute este script a partir do diretório raiz do projeto Django"
fi

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
    
    # Verificar Python
    if ! command -v python3 &> /dev/null; then
        error "Python 3 não está instalado"
    fi
    
    success "Todas as dependências esto instaladas"
}

# Configurar AWS CLI
setup_aws() {
    log "Configurando AWS CLI..."
    
    # Verificar se AWS CLI est configurado
    if ! aws sts get-caller-identity &> /dev/null; then
        warning "AWS CLI não está configurado. Configure com: aws configure"
        read -p "Digite sua Access Key ID: " AWS_ACCESS_KEY_ID
        read -p "Digite sua Secret Access Key: " AWS_SECRET_ACCESS_KEY
        read -p "Digite sua regio (ex: us-east-1): " AWS_DEFAULT_REGION
        
        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
        aws configure set default.region "$AWS_DEFAULT_REGION"
    fi
    
    success "AWS CLI configurado"
}

# Configurar variveis de ambiente
setup_environment() {
    log "Configurando variveis de ambiente..."
    
    # Verificar se arquivo .env existe
    if [ ! -f ".env" ]; then
        warning "Arquivo .env no encontrado. Criando template..."
        cat > .env << EOF
DEBUG=False
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=
DB_HOST=
DB_PORT=5432
ALLOWED_HOSTS=*
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
DEFAULT_FROM_EMAIL=Sistema de Agendamentos <noreply@example.com>
EOF
        warning "Configure o arquivo .env com suas credenciais antes de continuar"
        exit 1
    fi
    
    # Carregar variveis do .env
    export $(cat .env | grep -v '^#' | xargs)
    
    success "Variveis de ambiente carregadas"
}

# Configurar Terraform
setup_terraform() {
    log "Configurando Terraform..."
    
    cd aws-infrastructure
    
    # Verificar se terraform.tfvars existe
    if [ ! -f "terraform.tfvars" ]; then
        warning "Arquivo terraform.tfvars no encontrado. Criando a partir do exemplo..."
        cp terraform.tfvars.example terraform.tfvars
        
        # Solicitar configuraï¿½ï¿½es
        read -p "Digite a senha do banco de dados: " DB_PASSWORD
        read -p "Digite o domínio (opcional): " DOMAIN_NAME
        read -p "Digite o email para notificaes: " NOTIFICATION_EMAIL
        
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
    
    # Planejar mudanas
    log "Planejando mudanas..."
    terraform plan -out=tfplan
    
    # Aplicar mudanas
    log "Aplicando mudanas..."
    terraform apply tfplan
    
    # Obter outputs
    EC2_IP=$(terraform output -raw ec2_public_ip)
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
    S3_BUCKET=$(terraform output -raw s3_bucket_name)
    
    success "infraestrutura criada com sucesso!"
    log "EC2 IP: $EC2_IP"
    log "RDS Endpoint: $RDS_ENDPOINT"
    log "S3 Bucket: $S3_BUCKET"
    
    # Atualizar .env com INFORMAÇÕES da infraestrutura
    cd ..
    sed -i "s/DB_HOST=.*/DB_HOST=$RDS_ENDPOINT/g" .env
    sed -i "s/ALLOWED_HOSTS=.*/ALLOWED_HOSTS=$EC2_IP/g" .env
    
    success "Arquivo .env atualizado com INFORMAÇÕES da infraestrutura"
}

# Deploy da aplicaï¿½ï¿½o
deploy_application() {
    log "Fazendo deploy da aplicaï¿½ï¿½o..."
    
    # Criar arquivo de configuraï¿½ï¿½o para produo
    cat > core/settings_production.py << EOF
import os
from pathlib import Path
from .settings import *

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-change-me-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'

# Hosts permitidos
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# Database - PostgreSQL para produo
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'agendamentos_db'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_DIRS = [os.path.join(BASE_DIR, 'static')]

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Security settings para produo
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# HTTPS settings
SECURE_SSL_REDIRECT = os.environ.get('HTTPS_REDIRECT', 'False').lower() == 'true'
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Session settings
SESSION_COOKIE_SECURE = os.environ.get('HTTPS_REDIRECT', 'False').lower() == 'true'
CSRF_COOKIE_SECURE = os.environ.get('HTTPS_REDIRECT', 'False').lower() == 'true'

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': os.path.join(BASE_DIR, 'logs', 'django.log'),
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['file', 'console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

# Cache (usar memria para instncia nica)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
    }
}

# WhiteNoise para arquivos estticos
MIDDLEWARE.insert(1, 'whitenoise.middleware.WhiteNoiseMiddleware')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
EOF

    # Criar diretório de logs
    mkdir -p logs
    
    # Instalar dependências
    log "Instalando dependências..."
    pip install -r requirements.txt
    
    # Executar migraes
    log "Executando migraes..."
    python manage.py migrate --settings=core.settings_production
    
    # Coletar arquivos estticos
    log "Coletando arquivos estticos..."
    python manage.py collectstatic --noinput --settings=core.settings_production
    
    # Criar superusurio
    log "Criando superusurio..."
    echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'admin123')" | python manage.py shell --settings=core.settings_production
    
    success "aplicaï¿½ï¿½o configurada para produo"
}

# Testar aplicaï¿½ï¿½o
test_application() {
    log "Testando aplicaï¿½ï¿½o..."
    
    # Obter IP da EC2
    EC2_IP=$(cd aws-infrastructure && terraform output -raw ec2_public_ip)
    
    # Aguardar aplicaï¿½ï¿½o estar pronta
    log "Aguardando aplicaï¿½ï¿½o estar pronta..."
    sleep 30
    
    # Testar endpoints
    log "Testando endpoints..."
    
    # Health check
    if curl -f -s "http://$EC2_IP/health/" > /dev/null; then
        success "Health check passou"
    else
        warning "Health check falhou - aplicaï¿½ï¿½o pode ainda estar inicializando"
    fi
    
    # Testar pgina principal
    if curl -f -s "http://$EC2_IP/" > /dev/null; then
        success "Pgina principal carregou"
    else
        warning "Pgina principal no carregou - verifique logs"
    fi
    
    # Testar admin
    if curl -f -s "http://$EC2_IP/admin/" > /dev/null; then
        success "Admin Django carregou"
    else
        warning "Admin Django no carregou"
    fi
    
    success "Testes concludos"
}

# Configurar SSL (opcional)
setup_ssl() {
    log "Configurando SSL..."
    
    # Obter IP da EC2
    EC2_IP=$(cd aws-infrastructure && terraform output -raw ec2_public_ip)
    
    # Verificar se domínio foi configurado
    DOMAIN_NAME=$(cd aws-infrastructure && terraform output -raw domain_name 2>/dev/null || echo "")
    
    if [ -n "$DOMAIN_NAME" ]; then
        log "Configurando SSL para domínio: $DOMAIN_NAME"
        
        # Conectar na instncia e configurar SSL
        ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@$EC2_IP << EOF
            sudo certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME
            sudo systemctl restart nginx
EOF
        
        success "SSL configurado para $DOMAIN_NAME"
    else
        warning "domínio no configurado - SSL no ser configurado"
    fi
}

# Mostrar INFORMAÇÕES finais
show_final_info() {
    log "Deploy concludo com sucesso!"
    
    # Obter INFORMAÇÕES da infraestrutura
    cd aws-infrastructure
    EC2_IP=$(terraform output -raw ec2_public_ip)
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
    S3_BUCKET=$(terraform output -raw s3_bucket_name)
    DOMAIN_NAME=$(terraform output -raw domain_name 2>/dev/null || echo "")
    
    echo ""
    echo " DEPLOY CONCLUDO COM SUCESSO!"
    echo "=================================="
    echo ""
    echo " INFORMAÇÕES DA infraestrutura:"
    echo "   EC2 IP: $EC2_IP"
    echo "   RDS Endpoint: $RDS_ENDPOINT"
    echo "   S3 Bucket: $S3_BUCKET"
    echo ""
    echo " ACESSO  aplicaï¿½ï¿½o:"
    if [ -n "$DOMAIN_NAME" ]; then
        echo "   URL: https://$DOMAIN_NAME"
    else
        echo "   URL: http://$EC2_IP"
    fi
    echo "   Admin: http://$EC2_IP/admin/"
    echo "   Usurio: admin"
    echo "   Senha: admin123"
    echo ""
    echo " CONEXO SSH:"
    echo "  ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP"
    echo ""
    echo " PRÓXIMOS PASSOS:"
    echo "  1. Acesse a aplicaï¿½ï¿½o e configure seu sistema"
    echo "  2. Altere a senha do admin"
    echo "  3. Configure seu domínio (se aplicável)"
    echo "  4. Configure backup automtico"
    echo "  5. Configure monitoramento"
    echo ""
    echo "  IMPORTANTE:"
    echo "   Altere a senha do banco de dados"
    echo "   Configure backup automtico"
    echo "   Monitore os custos da AWS"
    echo "   Configure alertas de segurana"
    echo ""
}

# Funï¿½ï¿½o principal
main() {
    echo " SISTEMA DE AGENDAMENTO - DEPLOY AWS"
    echo "======================================"
    echo ""
    
    # Verificar argumentos
    case "${1:-deploy}" in
        "deploy")
            check_dependencies
            setup_aws
            setup_environment
            setup_terraform
            deploy_infrastructure
            deploy_application
            test_application
            setup_ssl
            show_final_info
            ;;
        "destroy")
            warning "DESTRUINDO infraestrutura..."
            cd aws-infrastructure
            terraform destroy -auto-approve
            success "infraestrutura destruída"
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
            echo "  deploy  - Fazer deploy completo (padro)"
            echo "  destroy - Destruir infraestrutura"
            echo "  status  - Ver status da infraestrutura"
            echo "  help    - Mostrar esta ajuda"
            ;;
        *)
            error "Comando invlido: $1. Use 'help' para ver comandos disponveis"
            ;;
    esac
}

# Executar Funï¿½ï¿½o principal
main "$@"
