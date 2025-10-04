#!/bin/bash

# Script de inicialização para instância EC2
# Configura automaticamente o ambiente Django

set -e

# Variáveis
DB_ENDPOINT="${db_address}"
DB_PORT="${db_port}"
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
    echo "[OK] Usuário django criado"
else
    echo "[INFO] Usuário django já existe"
fi

# Configurar diretório home do django
mkdir -p /home/django/sistema-de-agendamento
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
        alias /home/django/sistema-de-agendamento/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Media files
    location /media/ {
        alias /home/django/sistema-de-agendamento/media/;
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

echo "[OK] Nginx configurado"

# Configurar firewall
ufw --force enable
ufw allow 22
ufw allow 80
ufw allow 443

echo "[OK] Firewall configurado"

# Instalar AWS CLI
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
    echo "[OK] AWS CLI instalado"
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

echo "[OK] CloudWatch Agent configurado"

# Configurar aplicação Django (será feito pelo usuário django)
cat > /home/django/setup_django.sh << 'EOF'
#!/bin/bash

# Mudar para usuário django
cd /home/django

# Clonar repositório (substitua pela URL real)
# git clone https://github.com/seu-usuario/sistema-de-agendamento.git sistema-de-agendamento
# Clonar repositório do GitHub
git clone https://github.com/ViniciusMocelin/sistema-de-agendamento.git sistema-de-agendamento
cd sistema-de-agendamento

# Criar ambiente virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependências básicas
pip install --upgrade pip
pip install -r requirements.txt

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
    '13.223.47.98',
]

# Adicionar hosts da variável de ambiente
env_hosts = os.environ.get('ALLOWED_HOSTS', '')
if env_hosts:
    ALLOWED_HOSTS.extend([host.strip() for host in env_hosts.split(',') if host.strip()])

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
DB_PORT=${DB_PORT}
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

echo "[OK] Django configurado (aguardando banco de dados estar disponível)"

# Aguardar banco de dados estar disponível
echo "Aguardando banco de dados estar disponível..."
for i in {1..30}; do
    if pg_isready -h $DB_ENDPOINT -p 5432 -U $DB_USERNAME; then
        echo "[OK] Banco de dados disponível"
        break
    fi
    echo "Tentativa $i/30 - Aguardando banco de dados..."
    sleep 10
done

# Executar migrações e coletar arquivos estáticos
source venv/bin/activate
python manage.py migrate --settings=core.settings_production

# Coletar arquivos estáticos com logs detalhados
echo "Coletando arquivos estáticos..."
python manage.py collectstatic --noinput --settings=core.settings_production --verbosity=2

# Verificar se os arquivos foram coletados
echo "Verificando arquivos estáticos coletados..."
ls -la staticfiles/
ls -la staticfiles/admin/css/ || echo "Diretório admin/css não encontrado"

# Corrigir permissões dos arquivos estáticos
echo "Corrigindo permissões dos arquivos estáticos..."
chown -R www-data:www-data staticfiles/
chmod -R 755 staticfiles/

# Criar superusuário (opcional)
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'admin123')" | python manage.py shell --settings=core.settings_production

# Iniciar serviço Django
sudo systemctl start django

echo "[OK] Django iniciado com sucesso!"
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
