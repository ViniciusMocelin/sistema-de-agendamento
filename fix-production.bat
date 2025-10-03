@echo off
echo ===============================================
echo    CORRIGINDO PROBLEMA 502 BAD GATEWAY
echo ===============================================
echo.

REM Configurações
set EC2_IP=54.162.74.83

echo Conectando na EC2 e corrigindo a aplicacao...
echo.

REM Executar comandos de correção na EC2
"C:\Windows\System32\OpenSSH\ssh.exe" -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@%EC2_IP% "
set -e

echo '🔧 Iniciando correção da aplicação...'

# Ir para diretório da aplicação
cd /home/django/sistema-agendamento

# Ativar ambiente virtual
source venv/bin/activate

# Verificar se requirements estão instalados
echo '📦 Verificando dependências...'
pip install -r requirements.txt

# Executar migrações
echo '🗄️ Executando migrações...'
python manage.py migrate --settings=core.settings_production

# Coletar arquivos estáticos
echo '📁 Coletando arquivos estáticos...'
python manage.py collectstatic --noinput --settings=core.settings_production

# Criar superuser se não existir
echo '🔐 Verificando superuser...'
python manage.py create_4minds_superuser --force --no-input --settings=core.settings_production

# Parar processos Django existentes
echo '🛑 Parando processos Django existentes...'
sudo pkill -f 'python.*manage.py.*runserver' || true

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

echo '🎉 Correção concluída!'
"

if %errorlevel% equ 0 (
    echo.
    echo ===============================================
    echo    CORRECAO CONCLUIDA COM SUCESSO!
    echo ===============================================
    echo.
    echo Aguardando aplicacao inicializar...
    timeout /t 15 /nobreak >nul
    
    echo Testando aplicacao...
    powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://%EC2_IP%' -TimeoutSec 10; Write-Host 'Status:' $response.StatusCode; Write-Host 'Aplicacao funcionando!' } catch { Write-Host 'Erro:' $_.Exception.Message }"
    
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
    echo    ERRO NA CORRECAO
    echo ===============================================
    echo.
    echo Verifique os logs e tente novamente
)

echo.
pause
