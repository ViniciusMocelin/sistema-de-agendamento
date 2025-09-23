# Guia de Deploy na AWS - Sistema de Agendamento

## Visão Geral

Este guia fornece instruções completas para hospedar o Sistema de Agendamento na AWS usando o Free Tier, incluindo configuração de infraestrutura, deploy da aplicação e otimizações.

## Arquitetura da Solução

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CloudFront    │    │   Route 53      │    │   Certificate   │
│   (CDN)         │    │   (DNS)         │    │   Manager       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
┌─────────────────────────────────┼─────────────────────────────────┐
│                                 │                                 │
│  ┌─────────────────────────────┴─────────────────────────────┐   │
│  │                    EC2 t2.micro                          │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │   Nginx     │  │  Gunicorn   │  │   Django    │      │   │
│  │  │  (Proxy)    │  │  (WSGI)     │  │  (App)      │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                 │                                 │
│  ┌─────────────────────────────┴─────────────────────────────┐   │
│  │                RDS PostgreSQL db.t3.micro                │   │
│  │              (Banco de Dados)                             │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Pré-requisitos

### 1. Conta AWS
- [ ] Criar conta AWS (se não tiver)
- [ ] Ativar Free Tier
- [ ] Configurar AWS CLI
- [ ] Criar usuário IAM com permissões necessárias

### 2. Ferramentas Locais
- [ ] Python 3.8+
- [ ] Git
- [ ] AWS CLI v2
- [ ] Terraform (opcional, para IaC)

## Serviços AWS Utilizados

| Serviço | Tipo | Limite Free Tier | Custo Estimado |
|---------|------|------------------|----------------|
| **EC2** | t2.micro | 750h/mês | $8-10/mês |
| **RDS** | db.t3.micro | 750h/mês + 20GB | $15-20/mês |
| **S3** | Standard | 5GB | $0.12/mês |
| **Route 53** | Hosted Zone | 1 zona | $0.50/mês |
| **Certificate Manager** | SSL | 1 certificado | Gratuito |
| **CloudFront** | CDN | 1TB transfer | $0.085/GB |

## Passo a Passo - Configuração

### 1. Configurar AWS CLI

```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciais
aws configure
```

### 2. Criar Usuário IAM

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "rds:*",
                "s3:*",
                "route53:*",
                "acm:*",
                "cloudfront:*",
                "iam:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### 3. Configurar Região AWS

```bash
# Definir região (recomendado: us-east-1 para melhor compatibilidade)
export AWS_DEFAULT_REGION=us-east-1
export AWS_REGION=us-east-1
```

## Infraestrutura como Código (Terraform)

### 1. Estrutura de Arquivos

```
aws-infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── security-groups.tf
├── ec2.tf
├── rds.tf
├── s3.tf
└── terraform.tfvars.example
```

### 2. Configuração Principal (main.tf)

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-lts-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

### 3. Variáveis (variables.tf)

```hcl
variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "sistema-agendamento"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domínio do site"
  type        = string
  default     = ""
}
```

## Security Groups

### 1. Security Group para EC2

```hcl
resource "aws_security_group" "ec2_sg" {
  name_prefix = "${var.project_name}-ec2-"
  description = "Security group para EC2"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Django (Gunicorn)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}
```

### 2. Security Group para RDS

```hcl
resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.project_name}-rds-"
  description = "Security group para RDS"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
```

## Configuração EC2

### 1. Instância EC2 (ec2.tf)

```hcl
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id             = aws_subnet.public.id

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_endpoint = aws_db_instance.postgres.endpoint
    db_name     = aws_db_instance.postgres.db_name
    db_username = aws_db_instance.postgres.username
    db_password = var.db_password
  }))

  tags = {
    Name = "${var.project_name}-web-server"
  }
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
```

### 2. Script de Inicialização (user_data.sh)

```bash
#!/bin/bash

# Script de inicialização para instância EC2
# Configura automaticamente o ambiente Django

set -e

# Variáveis
DB_ENDPOINT="${db_endpoint}"
DB_NAME="${db_name}"
DB_USERNAME="${db_username}"
DB_PASSWORD="${db_password}"
PROJECT_NAME="${project_name}"

# Log de inicialização
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Iniciando configuração da instância EC2 para $PROJECT_NAME..."

# Atualizar sistema
apt-get update
apt-get upgrade -y

# Instalar dependências básicas
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    postgresql-client \
    git \
    curl \
    wget \
    unzip \
    htop \
    tree \
    vim \
    ufw \
    certbot \
    python3-certbot-nginx

# Criar usuário para aplicação
if ! id "django" &>/dev/null; then
    useradd -m -s /bin/bash django
    usermod -aG sudo django
    echo "Usuário django criado"
else
    echo "Usuário django já existe"
fi

# Configurar diretório home do django
mkdir -p /home/django/sistema-agendamento
chown -R django:django /home/django

# Configurar Nginx
cat > /etc/nginx/sites-available/django << EOF
server {
    listen 80;
    server_name _;

    # Logs
    access_log /var/log/nginx/django_access.log;
    error_log /var/log/nginx/django_error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Static files
    location /static/ {
        alias /home/django/sistema-agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Media files
    location /media/ {
        alias /home/django/sistema-agendamento/media/;
        expires 1y;
        add_header Cache-Control "public";
    }

    # Django application
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Health check endpoint
    location /health/ {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Habilitar site Django
ln -sf /etc/nginx/sites-available/django /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração do Nginx
nginx -t

# Reiniciar Nginx
systemctl restart nginx
systemctl enable nginx

echo "Nginx configurado"

# Configurar firewall
ufw --force enable
ufw allow 22
ufw allow 80
ufw allow 443

echo "Firewall configurado"

# Instalar AWS CLI
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
    echo "AWS CLI instalado"
fi

# Instalar CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Configurar CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/home/django/sistema-agendamento/logs/django.log",
                        "log_group_name": "/aws/ec2/$PROJECT_NAME/django",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/django_access.log",
                        "log_group_name": "/aws/ec2/$PROJECT_NAME/nginx-access",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/django_error.log",
                        "log_group_name": "/aws/ec2/$PROJECT_NAME/nginx-error",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Iniciar CloudWatch Agent
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent

echo "CloudWatch Agent configurado"

# Configurar aplicação Django (será feito pelo usuário django)
cat > /home/django/setup_django.sh << 'EOF'
#!/bin/bash

# Mudar para usuário django
cd /home/django

# Clonar repositório (substitua pela URL real)
# git clone https://github.com/seu-usuario/sistema-de-agendamento.git sistema-de-agendamento
# Por enquanto, vamos criar uma estrutura básica
mkdir -p sistema-de-agendamento
cd sistema-de-agendamento

# Criar ambiente virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependências básicas
pip install --upgrade pip
pip install django gunicorn psycopg2-binary python-decouple whitenoise

# Criar estrutura básica do Django
django-admin startproject core .

# Configurar settings.py para produção
cat > core/settings_production.py << 'SETTINGS_EOF'
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
ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    os.environ.get('ALLOWED_HOSTS', '').split(',')
]

# Database - PostgreSQL para produção
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

# Security settings para produção
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

# Cache (usar memória para instância única)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
    }
}

# WhiteNoise para arquivos estáticos
MIDDLEWARE.insert(1, 'whitenoise.middleware.WhiteNoiseMiddleware')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
SETTINGS_EOF

# Criar diretório de logs
mkdir -p logs

# Configurar variáveis de ambiente
cat > .env << ENV_EOF
DEBUG=False
SECRET_KEY=django-insecure-change-me-in-production-$(date +%s)
DB_NAME=$DB_NAME
DB_USER=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_ENDPOINT
DB_PORT=5432
ALLOWED_HOSTS=*
HTTPS_REDIRECT=False
ENV_EOF

# Configurar Gunicorn
cat > gunicorn.conf.py << 'GUNICORN_EOF'
bind = "127.0.0.1:8000"
workers = 2
worker_class = "sync"
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 100
timeout = 30
keepalive = 2
preload_app = True
daemon = False
pidfile = "/home/django/sistema-agendamento/gunicorn.pid"
accesslog = "/home/django/sistema-agendamento/logs/gunicorn_access.log"
errorlog = "/home/django/sistema-agendamento/logs/gunicorn_error.log"
loglevel = "info"
GUNICORN_EOF

# Configurar serviço systemd
sudo tee /etc/systemd/system/django.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Django App
After=network.target

[Service]
Type=notify
User=django
Group=django
WorkingDirectory=/home/django/sistema-agendamento
Environment=PATH=/home/django/sistema-agendamento/venv/bin
ExecStart=/home/django/sistema-agendamento/venv/bin/gunicorn --config gunicorn.conf.py core.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Recarregar systemd e iniciar serviço
sudo systemctl daemon-reload
sudo systemctl enable django

echo "Django configurado (aguardando banco de dados estar disponível)"

# Aguardar banco de dados estar disponível
echo "Aguardando banco de dados estar disponível..."
for i in {1..30}; do
    if pg_isready -h $DB_ENDPOINT -p 5432 -U $DB_USERNAME; then
        echo "Banco de dados disponível"
        break
    fi
    echo "Tentativa $i/30 - Aguardando banco de dados..."
    sleep 10
done

# Executar migrações e coletar arquivos estáticos
source venv/bin/activate
python manage.py migrate --settings=core.settings_production
python manage.py collectstatic --noinput --settings=core.settings_production

# Criar superusuário (opcional)
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'admin123')" | python manage.py shell --settings=core.settings_production

# Iniciar serviço Django
sudo systemctl start django

echo "Django iniciado com sucesso!"
EOF

# Executar configuração do Django como usuário django
chmod +x /home/django/setup_django.sh
sudo -u django /home/django/setup_django.sh

# Configurar backup automático
cat > /home/django/backup.sh << 'BACKUP_EOF'
#!/bin/bash

# Script de backup automático
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/django/backups"
DB_BACKUP="$BACKUP_DIR/db_backup_$DATE.sql"

mkdir -p $BACKUP_DIR

# Backup do banco
pg_dump -h $DB_ENDPOINT -U $DB_USERNAME -d $DB_NAME > $DB_BACKUP

# Backup dos arquivos de mídia
tar -czf "$BACKUP_DIR/media_backup_$DATE.tar.gz" /home/django/sistema-agendamento/media/

# Limpar backups locais antigos (manter apenas 7 dias)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup concluído: $DATE"
BACKUP_EOF

chmod +x /home/django/backup.sh
chown django:django /home/django/backup.sh

# Agendar backup diário
echo "0 2 * * * /home/django/backup.sh" | crontab -u django -

# Configurar monitoramento de saúde
cat > /home/django/health_check.sh << 'HEALTH_EOF'
#!/bin/bash

# Script de verificação de saúde da aplicação
APP_URL="http://localhost:8000"
LOG_FILE="/home/django/logs/health_check.log"

# Verificar se a aplicação está respondendo
if curl -f -s "$APP_URL/health/" > /dev/null; then
    echo "$(date): Aplicação saudável" >> $LOG_FILE
    exit 0
else
    echo "$(date): Aplicação não está respondendo" >> $LOG_FILE
    # Tentar reiniciar o serviço
    sudo systemctl restart django
    exit 1
fi
HEALTH_EOF

chmod +x /home/django/health_check.sh
chown django:django /home/django/health_check.sh

# Agendar verificação de saúde a cada 5 minutos
echo "*/5 * * * * /home/django/health_check.sh" | crontab -u django -

echo "Configuração da instância concluída!"
echo "Aplicação disponível em: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "SSH: ssh -i ~/.ssh/id_rsa ubuntu@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Logs: /var/log/user-data.log"
```

## Configuração RDS

### 1. Banco de Dados (rds.tf)

```hcl
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = "agendamentos_db"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = {
    Name = "${var.project_name}-postgres"
  }
}

# Subnet Group para RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}
```

## Configuração de Rede

### 1. VPC e Subnets

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Subnets Privadas para RDS
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-subnet-2"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

## Configuração S3

### 1. Bucket S3 (s3.tf)

```hcl
resource "aws_s3_bucket" "static_files" {
  bucket = "${var.project_name}-static-files-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-static-files"
  }
}

resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "static_files" {
  bucket = aws_s3_bucket.static_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
```

## Deploy da Aplicação

### 1. Configurar Variáveis de Ambiente

```bash
# Criar arquivo .env
cat > .env << EOF
DEBUG=False
SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=sua_senha_segura_aqui
DB_HOST=seu-endpoint-rds.amazonaws.com
DB_PORT=5432
ALLOWED_HOSTS=seu-dominio.com,seu-ip-ec2
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=seu-email@gmail.com
EMAIL_HOST_PASSWORD=sua_senha_app
DEFAULT_FROM_EMAIL=Sistema de Agendamentos <noreply@seu-dominio.com>
EOF
```

### 2. Script de Deploy

```bash
#!/bin/bash
# deploy.sh

echo "Iniciando deploy do Sistema de Agendamento..."

# 1. Aplicar infraestrutura Terraform
echo "Criando infraestrutura..."
cd aws-infrastructure
terraform init
terraform plan
terraform apply -auto-approve

# 2. Obter informações da infraestrutura
EC2_IP=$(terraform output -raw ec2_public_ip)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

echo "EC2 IP: $EC2_IP"
echo "RDS Endpoint: $RDS_ENDPOINT"

# 3. Configurar DNS (se tiver domínio)
if [ ! -z "$DOMAIN_NAME" ]; then
    echo "Configurando DNS..."
    # Adicionar comandos Route 53 aqui
fi

# 4. Aguardar instância estar pronta
echo "Aguardando instância estar pronta..."
sleep 60

# 5. Testar aplicação
echo "Testando aplicação..."
curl -I http://$EC2_IP

echo "Deploy concluído!"
echo "Acesse: http://$EC2_IP"
```

## Configurações Pós-Deploy

### 1. Configurar SSL com Let's Encrypt

```bash
# Conectar na instância EC2
ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP

# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d seu-dominio.com

# Configurar renovação automática
sudo crontab -e
# Adicionar: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 2. Configurar Backup Automático

```bash
# Script de backup
cat > /home/django/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/django/backups"
DB_BACKUP="$BACKUP_DIR/db_backup_$DATE.sql"

mkdir -p $BACKUP_DIR

# Backup do banco
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > $DB_BACKUP

# Backup dos arquivos de mídia
tar -czf "$BACKUP_DIR/media_backup_$DATE.tar.gz" /home/django/sistema-agendamento/media/

# Upload para S3
aws s3 cp $DB_BACKUP s3://seu-bucket/backups/
aws s3 cp "$BACKUP_DIR/media_backup_$DATE.tar.gz" s3://seu-bucket/backups/

# Limpar backups locais antigos
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /home/django/backup.sh

# Agendar backup diário
echo "0 2 * * * /home/django/backup.sh" | crontab -u django -
```

## Monitoramento e Logs

### 1. CloudWatch Logs

```bash
# Instalar CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Configurar logs
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

### 2. Configurar Alertas

```hcl
# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.web_server.id
  }
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}
```

## Otimização de Custos

### 1. Configurar Budgets

```bash
# Criar budget AWS
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "Sistema-Agendamento-Budget",
    "BudgetLimit": {
      "Amount": "50",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }'
```

### 2. Configurar Alertas de Custo

```bash
# Criar alerta de custo
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "Sistema-Agendamento-Alert",
    "BudgetLimit": {
      "Amount": "30",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostFilters": {
      "Service": ["Amazon Elastic Compute Cloud - Compute", "Amazon Relational Database Service"]
    }
  }'
```

## Segurança

### 1. Configurar WAF

```hcl
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.project_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WebACLMetric"
    sampled_requests_enabled   = true
  }
}
```

### 2. Configurar Secrets Manager

```bash
# Armazenar senhas no Secrets Manager
aws secretsmanager create-secret \
  --name "sistema-agendamento/db-password" \
  --description "Senha do banco de dados" \
  --secret-string "sua_senha_segura"

aws secretsmanager create-secret \
  --name "sistema-agendamento/django-secret" \
  --description "Secret key do Django" \
  --secret-string "sua_secret_key_django"
```

## Testes e Validação

### 1. Script de Testes

```bash
#!/bin/bash
# test_deployment.sh

echo "Testando deploy..."

# Testar conectividade
curl -f http://$EC2_IP/health/ || exit 1

# Testar banco de dados
curl -f http://$EC2_IP/admin/ || exit 1

# Testar API
curl -f http://$EC2_IP/api/agendamentos/ || exit 1

echo "Todos os testes passaram!"
```

### 2. Health Check

```python
# health_check.py
import requests
import sys

def test_endpoints():
    base_url = "http://seu-ip-ec2"
    
    endpoints = [
        "/",
        "/admin/",
        "/api/agendamentos/",
        "/static/css/style.css"
    ]
    
    for endpoint in endpoints:
        try:
            response = requests.get(f"{base_url}{endpoint}", timeout=10)
            if response.status_code == 200:
                print(f"OK {endpoint} - OK")
            else:
                print(f"ERRO {endpoint} - Status: {response.status_code}")
        except Exception as e:
            print(f"ERRO {endpoint} - Erro: {e}")

if __name__ == "__main__":
    test_endpoints()
```

## Próximos Passos

1. **Configurar CI/CD** com GitHub Actions
2. **Implementar CDN** com CloudFront
3. **Configurar Load Balancer** para alta disponibilidade
4. **Implementar Auto Scaling** para picos de tráfego
5. **Configurar Monitoring** avançado com DataDog ou New Relic

## Troubleshooting

### Problemas Comuns

1. **Erro de conexão com banco**
   ```bash
   # Verificar security groups
   aws ec2 describe-security-groups --group-ids sg-xxxxx
   
   # Testar conectividade
   telnet rds-endpoint 5432
   ```

2. **Arquivos estáticos não carregam**
   ```bash
   # Verificar permissões
   sudo chown -R django:django /home/django/sistema-agendamento/staticfiles/
   
   # Recriar arquivos estáticos
   python manage.py collectstatic --noinput
   ```

3. **Aplicação não inicia**
   ```bash
   # Verificar logs
   sudo journalctl -u django -f
   
   # Verificar status do serviço
   sudo systemctl status django
   ```

## Suporte

Para dúvidas ou problemas:
- Email: suporte@sistema-agendamento.com
- WhatsApp: (11) 99999-9999
- Documentação: https://docs.sistema-agendamento.com

---

**Importante:** Este guia é para fins educacionais. Sempre teste em ambiente de desenvolvimento antes de aplicar em produção.