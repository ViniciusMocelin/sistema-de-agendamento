#!/bin/bash

# Script para corrigir erro 502 Bad Gateway na EC2
# Execute este script na instância EC2

set -e

echo "🔧 Iniciando correção do erro 502 Bad Gateway..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 1. Verificar status dos serviços
log "Verificando status dos serviços..."
echo "=== Status do Nginx ==="
sudo systemctl status nginx --no-pager -l || true
echo ""
echo "=== Status do Django ==="
sudo systemctl status django --no-pager -l || true
echo ""

# 2. Verificar se Django está rodando na porta 8000
log "Verificando se Django está rodando na porta 8000..."
if netstat -tlnp | grep :8000; then
    success "Django está rodando na porta 8000"
else
    error "Django não está rodando na porta 8000"
fi
echo ""

# 3. Verificar logs de erro
log "Verificando logs de erro..."
echo "=== Últimos logs do Nginx ==="
sudo tail -20 /var/log/nginx/django_error.log || echo "Nenhum log de erro do Nginx"
echo ""
echo "=== Últimos logs do Django ==="
sudo journalctl -u django --no-pager -l -n 20 || echo "Nenhum log do Django"
echo ""

# 4. Verificar configuração do Nginx
log "Verificando configuração do Nginx..."
if sudo nginx -t; then
    success "Configuração do Nginx está correta"
else
    error "Configuração do Nginx tem erros"
fi
echo ""

# 5. Verificar usuário django e permissões
log "Verificando usuário django e permissões..."
if id django >/dev/null 2>&1; then
    success "Usuário django existe"
    echo "Permissões do diretório:"
    ls -la /home/django/sistema-agendamento/ || echo "Diretório não existe"
else
    error "Usuário django não existe"
fi
echo ""

# 6. Verificar ambiente virtual
log "Verificando ambiente virtual..."
if [ -d "/home/django/sistema-agendamento/venv" ]; then
    success "Ambiente virtual existe"
    echo "Conteúdo do venv/bin:"
    ls -la /home/django/sistema-agendamento/venv/bin/ || echo "Diretório venv/bin não existe"
else
    error "Ambiente virtual não existe"
fi
echo ""

# 7. Verificar arquivo .env
log "Verificando arquivo .env..."
if [ -f "/home/django/sistema-agendamento/.env" ]; then
    success "Arquivo .env existe"
    echo "Conteúdo do .env:"
    cat /home/django/sistema-agendamento/.env
else
    error "Arquivo .env não existe"
    warning "Criando arquivo .env básico..."
    cat > /home/django/sistema-agendamento/.env << 'EOF'
DEBUG=False
SECRET_KEY=django-insecure-change-me-in-production
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=senha_segura_postgre
DB_HOST=localhost
DB_PORT=5432
ALLOWED_HOSTS=*
HTTPS_REDIRECT=False
EOF
    sudo chown django:django /home/django/sistema-agendamento/.env
    success "Arquivo .env criado"
fi
echo ""

# 8. Verificar configuração do Gunicorn
log "Verificando configuração do Gunicorn..."
if [ -f "/home/django/sistema-agendamento/gunicorn.conf.py" ]; then
    success "Arquivo gunicorn.conf.py existe"
    cat /home/django/sistema-agendamento/gunicorn.conf.py
else
    error "Arquivo gunicorn.conf.py não existe"
    warning "Criando configuração do Gunicorn..."
    cat > /home/django/sistema-agendamento/gunicorn.conf.py << 'EOF'
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
EOF
    sudo chown django:django /home/django/sistema-agendamento/gunicorn.conf.py
    success "Configuração do Gunicorn criada"
fi
echo ""

# 9. Criar diretório de logs se não existir
log "Criando diretório de logs..."
sudo mkdir -p /home/django/sistema-agendamento/logs
sudo chown django:django /home/django/sistema-agendamento/logs
success "Diretório de logs criado"
echo ""

# 10. Verificar banco de dados
log "Verificando banco de dados..."
cd /home/django/sistema-agendamento
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    if python manage.py check --settings=core.settings_production; then
        success "Banco de dados está acessível"
    else
        error "Problema com banco de dados"
    fi
else
    error "Ambiente virtual não encontrado"
fi
echo ""

# 11. Corrigir permissões
log "Corrigindo permissões..."
sudo chown -R django:django /home/django/sistema-agendamento/
sudo chmod +x /home/django/sistema-agendamento/venv/bin/*
success "Permissões corrigidas"
echo ""

# 12. Reiniciar serviços
log "Reiniciando serviços..."
sudo systemctl stop django || true
sudo systemctl stop nginx || true
sleep 2
sudo systemctl start django
sleep 5
sudo systemctl start nginx
success "Serviços reiniciados"
echo ""

# 13. Verificar status após reinicialização
log "Verificando status após reinicialização..."
echo "=== Status do Django ==="
sudo systemctl status django --no-pager -l || true
echo ""
echo "=== Status do Nginx ==="
sudo systemctl status nginx --no-pager -l || true
echo ""

# 14. Testar Django localmente
log "Testando Django localmente..."
if curl -f -s http://localhost:8000/health/ > /dev/null; then
    success "Django está respondendo localmente"
else
    error "Django não está respondendo localmente"
    warning "Tentando iniciar Django manualmente..."
    cd /home/django/sistema-agendamento
    sudo -u django bash -c "source venv/bin/activate && python manage.py runserver 0.0.0.0:8000 --settings=core.settings_production" &
    sleep 10
    if curl -f -s http://localhost:8000/health/ > /dev/null; then
        success "Django iniciado manualmente com sucesso"
    else
        error "Falha ao iniciar Django manualmente"
    fi
fi
echo ""

# 15. Testar Nginx
log "Testando Nginx..."
if curl -f -s http://localhost/ > /dev/null; then
    success "Nginx está respondendo"
else
    error "Nginx não está respondendo"
fi
echo ""

# 16. Verificar se a porta 8000 está aberta
log "Verificando se a porta 8000 está aberta..."
if netstat -tlnp | grep :8000; then
    success "Porta 8000 está aberta"
else
    error "Porta 8000 não está aberta"
fi
echo ""

# 17. Resumo final
log "=== RESUMO FINAL ==="
echo "Status dos serviços:"
sudo systemctl is-active django && echo "✅ Django: Ativo" || echo "❌ Django: Inativo"
sudo systemctl is-active nginx && echo "✅ Nginx: Ativo" || echo "❌ Nginx: Inativo"

echo ""
echo "Teste de conectividade:"
if curl -f -s http://localhost:8000/health/ > /dev/null; then
    success "✅ Django respondendo na porta 8000"
else
    error "❌ Django não respondendo na porta 8000"
fi

if curl -f -s http://localhost/ > /dev/null; then
    success "✅ Nginx respondendo na porta 80"
else
    error "❌ Nginx não respondendo na porta 80"
fi

echo ""
echo "🔧 Se o problema persistir, verifique:"
echo "1. Logs do Django: sudo journalctl -u django -f"
echo "2. Logs do Nginx: sudo tail -f /var/log/nginx/django_error.log"
echo "3. Configuração do Nginx: sudo nginx -t"
echo "4. Banco de dados: verificar .env"
echo "5. Permissões: sudo chown -R django:django /home/django/"

echo ""
success "Script de correção concluído!"
