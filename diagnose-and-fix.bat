@echo off
echo ===============================================
echo    DIAGNOSTICO E CORRECAO COMPLETA - 502 BAD GATEWAY
echo ===============================================
echo.

set EC2_IP=54.162.74.83

echo 🔍 Analisando sistema...
echo.

"C:\Windows\System32\OpenSSH\ssh.exe" -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@%EC2_IP% "
set -e

echo '=== DIAGNOSTICO DO SISTEMA ==='
echo ''

# 1. Verificar processos Python/Django
echo '1. Verificando processos Python/Django...'
ps aux | grep python || echo '   Nenhum processo Python encontrado'
echo ''

# 2. Verificar portas em uso
echo '2. Verificando portas em uso...'
netstat -tlnp | grep -E ':(80|8000)' || echo '   Nenhuma porta 80/8000 em uso'
echo ''

# 3. Verificar status do Nginx
echo '3. Verificando status do Nginx...'
sudo systemctl status nginx --no-pager -l || echo '   Erro ao verificar Nginx'
echo ''

# 4. Verificar logs do Nginx
echo '4. Verificando logs de erro do Nginx...'
sudo tail -10 /var/log/nginx/error.log 2>/dev/null || echo '   Nenhum log de erro encontrado'
echo ''

# 5. Verificar configuração do Nginx
echo '5. Verificando configuração do Nginx...'
sudo nginx -t 2>&1 || echo '   Erro na configuração do Nginx'
echo ''

# 6. Verificar se diretório da aplicação existe
echo '6. Verificando diretório da aplicação...'
ls -la /home/django/sistema-de-agendamento/ 2>/dev/null || echo '   Diretório não encontrado'
echo ''

# 7. Verificar se ambiente virtual existe
echo '7. Verificando ambiente virtual...'
ls -la /home/django/sistema-de-agendamento/venv/ 2>/dev/null || echo '   Ambiente virtual não encontrado'
echo ''

# 8. Verificar arquivo .env
echo '8. Verificando arquivo .env...'
ls -la /home/django/sistema-de-agendamento/.env 2>/dev/null || echo '   Arquivo .env não encontrado'
echo ''

echo '=== INICIANDO CORRECAO ==='
echo ''

# Parar processos existentes
echo '🛑 Parando processos existentes...'
sudo pkill -f 'python.*manage.py' || echo '   Nenhum processo Django para parar'
echo ''

# Ir para diretório da aplicação
cd /home/django/sistema-de-agendamento

# Ativar ambiente virtual
echo '📦 Ativando ambiente virtual...'
source venv/bin/activate
echo ''

# Verificar dependências
echo '📦 Verificando dependências...'
pip list | grep -E '(Django|psycopg2)' || echo '   Dependências não encontradas'
echo ''

# Executar migrações
echo '🗄️ Executando migrações...'
python manage.py migrate --settings=core.settings_production || echo '   Erro nas migrações'
echo ''

# Coletar arquivos estáticos
echo '📁 Coletando arquivos estáticos...'
mkdir -p static
python manage.py collectstatic --noinput --settings=core.settings_production || echo '   Erro ao coletar estáticos'
echo ''

# Verificar configuração do Django
echo '🔧 Verificando configuração do Django...'
python manage.py check --settings=core.settings_production || echo '   Erro na configuração do Django'
echo ''

# Iniciar Django em background
echo '🚀 Iniciando Django na porta 8000...'
nohup python manage.py runserver 0.0.0.0:8000 --settings=core.settings_production > /tmp/django.log 2>&1 &
DJANGO_PID=$!
echo \"   PID do Django: $DJANGO_PID\"
echo ''

# Aguardar Django iniciar
echo '⏳ Aguardando Django iniciar...'
sleep 15
echo ''

# Verificar se Django está rodando
echo '✅ Verificando se Django está rodando...'
if pgrep -f 'python.*manage.py.*runserver' > /dev/null; then
    echo '   ✅ Django iniciado com sucesso!'
    ps aux | grep python | grep manage.py
else
    echo '   ❌ Falha ao iniciar Django'
    echo '   Logs do Django:'
    cat /tmp/django.log
fi
echo ''

# Verificar se porta 8000 está em uso
echo '🔌 Verificando porta 8000...'
netstat -tlnp | grep :8000 || echo '   Porta 8000 não está em uso'
echo ''

# Testar conectividade local
echo '🧪 Testando conectividade local...'
curl -I http://localhost:8000 2>/dev/null || echo '   Django não responde localmente'
echo ''

# Verificar configuração do Nginx
echo '🌐 Verificando configuração do Nginx...'
sudo cat /etc/nginx/sites-available/default | grep -A 5 -B 5 proxy_pass || echo '   Configuração de proxy não encontrada'
echo ''

# Reiniciar Nginx
echo '🔄 Reiniciando Nginx...'
sudo systemctl restart nginx
sudo systemctl status nginx --no-pager -l
echo ''

# Teste final
echo '🎯 Teste final de conectividade...'
curl -I http://localhost 2>/dev/null || echo '   Nginx não responde'
echo ''

echo '=== DIAGNOSTICO COMPLETO ==='
echo ''
echo 'Status dos serviços:'
echo '- Django:' \$(pgrep -f 'python.*manage.py.*runserver' && echo 'RODANDO' || echo 'PARADO')
echo '- Nginx:' \$(systemctl is-active nginx)
echo '- Porta 8000:' \$(netstat -tlnp | grep :8000 > /dev/null && echo 'ABERTA' || echo 'FECHADA')
echo '- Porta 80:' \$(netstat -tlnp | grep :80 > /dev/null && echo 'ABERTA' || echo 'FECHADA')
echo ''
"

if %errorlevel% equ 0 (
    echo.
    echo ===============================================
    echo    DIAGNOSTICO CONCLUIDO
    echo ===============================================
    echo.
    echo Aguardando sistema estabilizar...
    timeout /t 10 /nobreak >nul
    
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
    echo    ERRO NO DIAGNOSTICO
    echo ===============================================
    echo.
    echo Verifique os logs acima para identificar o problema
)

echo.
pause
