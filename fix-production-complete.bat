@echo off
echo ===============================================
echo    CORRECAO COMPLETA DO SISTEMA DE AGENDAMENTO
echo ===============================================
echo.

set EC2_IP=54.162.74.83

echo Conectando na EC2 e fazendo configuracao completa...
echo.

"C:\Windows\System32\OpenSSH\ssh.exe" -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@%EC2_IP% "
set -e

echo '🔧 Iniciando configuração completa do sistema...'

# Parar processos existentes
echo '🛑 Parando processos existentes...'
sudo pkill -f 'python.*manage.py' || true
sudo systemctl stop nginx || true

# Ir para diretório da aplicação
cd /home/django/sistema-de-agendamento

# Ativar ambiente virtual
source venv/bin/activate

# Verificar e instalar dependências
echo '📦 Verificando dependências...'
pip install -r requirements.txt

# Executar migrações
echo '🗄️ Executando migrações...'
python manage.py migrate --settings=core.settings_production

# Coletar arquivos estáticos
echo '📁 Coletando arquivos estáticos...'
mkdir -p static
python manage.py collectstatic --noinput --settings=core.settings_production

# Criar superuser
echo '🔐 Criando superuser...'
python manage.py create_4minds_superuser --force --no-input --settings=core.settings_production

# Configurar Nginx
echo '🌐 Configurando Nginx...'
sudo tee /etc/nginx/sites-available/django > /dev/null << 'EOF'
server {
    listen 80;
    server_name %EC2_IP%;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /static/ {
        alias /home/django/sistema-de-agendamento/static/;
    }
    
    location /media/ {
        alias /home/django/sistema-de-agendamento/media/;
    }
}
EOF

# Ativar configuração do Nginx
sudo ln -sf /etc/nginx/sites-available/django /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração do Nginx
sudo nginx -t

# Iniciar Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Iniciar Django em background
echo '🚀 Iniciando Django...'
nohup python manage.py runserver 0.0.0.0:8000 --settings=core.settings_production > /tmp/django.log 2>&1 &

# Aguardar Django iniciar
sleep 10

# Verificar se Django está rodando
echo '✅ Verificando se Django está rodando...'
if pgrep -f 'python.*manage.py.*runserver' > /dev/null; then
    echo '✅ Django iniciado com sucesso!'
else
    echo '❌ Falha ao iniciar Django'
    cat /tmp/django.log
fi

# Verificar se Nginx está rodando
if systemctl is-active --quiet nginx; then
    echo '✅ Nginx rodando com sucesso!'
else
    echo '❌ Nginx não está rodando'
fi

echo '🎉 Configuração completa finalizada!'
"

if %errorlevel% equ 0 (
    echo.
    echo ===============================================
    echo    CONFIGURACAO COMPLETA FINALIZADA!
    echo ===============================================
    echo.
    echo Aguardando sistema inicializar...
    timeout /t 20 /nobreak >nul
    
    echo Testando aplicacao...
    powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://%EC2_IP%' -TimeoutSec 15; Write-Host 'Status:' $response.StatusCode; Write-Host 'Aplicacao funcionando!' } catch { Write-Host 'Erro:' $_.Exception.Message }"
    
    echo.
    echo URLs de acesso:
    echo - Home: http://%EC2_IP%/
    echo - Admin: http://%EC2_IP%/admin/
    echo.
    echo Credenciais:
    echo - Usuario: @4minds
    echo - Senha: @4mindsPassword
) else (
    echo.
    echo ===============================================
    echo    ERRO NA CONFIGURACAO
    echo ===============================================
    echo.
    echo Verifique os logs e tente novamente
)

echo.
pause
