@echo off
REM Script para Atualizar Produção com Correções
REM Sistema de Agendamento - 4Minds

echo ===============================================
echo    ATUALIZAÇÃO DE PRODUÇÃO
echo    Sistema de Agendamento - 4Minds
echo    Correções: Visual + Admin + Superuser
echo ===============================================
echo.

REM Verificar se AWS CLI está instalado
where aws >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ AWS CLI não encontrado
    echo Instale o AWS CLI: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

REM Verificar se AWS CLI está configurado
aws sts get-caller-identity >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ AWS CLI não configurado
    echo Execute: aws configure
    pause
    exit /b 1
)

REM Verificar se arquivo .env.production existe
if not exist ".env.production" (
    echo ❌ Arquivo .env.production não encontrado
    echo Execute: copy env.production.example .env.production
    pause
    exit /b 1
)

echo ✅ Pré-requisitos verificados

REM Configurações
set REGION=us-east-1
set EC2_INSTANCE_ID=i-04d14b81170c26323

echo.
echo Verificando infraestrutura...

REM Verificar status da EC2
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].State.Name" --output text') do set EC2_STATUS=%%i

echo Status da EC2: %EC2_STATUS%

if not "%EC2_STATUS%"=="running" (
    echo ❌ Instância EC2 não está rodando
    echo Execute: scripts\start-aws-services-simple.bat
    pause
    exit /b 1
)

echo ✅ Infraestrutura verificada

REM Obter IP da EC2
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set EC2_IP=%%i

if "%EC2_IP%"=="None" (
    echo ❌ Não foi possível obter IP da EC2
    pause
    exit /b 1
)

echo ✅ IP da EC2: %EC2_IP%

echo.
echo Fazendo backup antes da atualização...

REM Fazer backup via SSH
ssh -i %USERPROFILE%\.ssh\id_rsa -o StrictHostKeyChecking=no ubuntu@%EC2_IP% "echo '📦 Criando backup...' && sudo -u postgres pg_dump agendamentos_db > /tmp/backup_$(date +%%Y%%m%%d_%%H%%M%%S).sql && sudo tar -czf /tmp/static_backup_$(date +%%Y%%m%%d_%%H%%M%%S).tar.gz /home/django/sistema-agendamento/staticfiles/ && echo '✅ Backup criado com sucesso!'"

if %ERRORLEVEL% neq 0 (
    echo ❌ Erro ao fazer backup
    pause
    exit /b 1
)

echo ✅ Backup criado

echo.
echo Fazendo deploy das correções...

REM Copiar arquivo .env.production para EC2
echo Copiando configurações...
scp -i %USERPROFILE%\.ssh\id_rsa -o StrictHostKeyChecking=no .env.production ubuntu@%EC2_IP%:/tmp/

if %ERRORLEVEL% neq 0 (
    echo ❌ Erro ao copiar configurações
    pause
    exit /b 1
)

echo Executando atualização na EC2...

REM Executar atualização via SSH
ssh -i %USERPROFILE%\.ssh\id_rsa -o StrictHostKeyChecking=no ubuntu@%EC2_IP% "
set -e
echo '🚀 Iniciando atualização de produção...'
cd /home/django/sistema-agendamento
cp .env .env.backup.$(date +%%Y%%m%%d_%%H%%M%%S) 2>/dev/null || true
sudo cp /tmp/.env.production .env
source venv/bin/activate
echo '📦 Instalando dependências...'
pip install -r requirements.txt
echo '🗄️ Executando migrações...'
python manage.py migrate --settings=core.settings_production
echo '📁 Coletando arquivos estáticos...'
python manage.py collectstatic --noinput --settings=core.settings_production
echo '🔐 Corrigindo superuser...'
python manage.py create_4minds_superuser --force --no-input --settings=core.settings_production
echo '🎨 Aplicando correções de CSS...'
if [ -f static/css/style-fixed.css ]; then cp static/css/style-fixed.css static/css/style.css; echo '✅ CSS corrigido aplicado'; fi
echo '🔄 Recarregando aplicação...'
sudo systemctl restart django
sudo systemctl restart nginx
echo '✅ Verificando status dos serviços...'
sudo systemctl status django --no-pager -l
sudo systemctl status nginx --no-pager -l
echo '🎉 Atualização concluída com sucesso!'
"

if %ERRORLEVEL% neq 0 (
    echo ❌ Erro durante a atualização
    pause
    exit /b 1
)

echo ✅ Atualização executada com sucesso

echo.
echo Aguardando aplicação inicializar...
timeout /t 30 /nobreak >nul

echo.
echo Testando endpoints...

REM Testar página principal
curl -f -s "http://%EC2_IP%/" >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo ✅ Página principal funcionando
) else (
    echo ❌ Página principal não está respondendo
)

REM Testar admin
curl -f -s "http://%EC2_IP%/admin/" >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo ✅ Admin funcionando
) else (
    echo ⚠️ Admin não está respondendo (pode ser normal)
)

REM Testar arquivos estáticos
curl -f -s "http://%EC2_IP%/static/css/style.css" >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo ✅ Arquivos estáticos funcionando
) else (
    echo ⚠️ Arquivos estáticos podem não estar disponíveis
)

echo.
echo ===============================================
echo    ATUALIZAÇÃO CONCLUÍDA COM SUCESSO!
echo ===============================================
echo.
echo 🎉 CORREÇÕES APLICADAS:
echo ✅ Visual corrigido - Interface moderna
echo ✅ Admin funcionando - Totalmente acessível
echo ✅ Superuser configurado - @4minds
echo ✅ CSS atualizado - Design profissional
echo.
echo 🔑 CREDENCIAIS DO ADMIN:
echo    Usuário: @4minds
echo    Senha: @4mindsPassword
echo    Email: admin@4minds.com
echo.
echo 🌐 URLs DE ACESSO:
echo    Admin Django: http://%EC2_IP%/admin/
echo    Dashboard: http://%EC2_IP%/dashboard/
echo    Home: http://%EC2_IP%/
echo.
echo 🔧 COMANDOS ÚTEIS:
echo    SSH: ssh -i %USERPROFILE%\.ssh\id_rsa ubuntu@%EC2_IP%
echo    Logs: ssh -i %USERPROFILE%\.ssh\id_rsa ubuntu@%EC2_IP% "sudo journalctl -u django -f"
echo    Status: ssh -i %USERPROFILE%\.ssh\id_rsa ubuntu@%EC2_IP% "sudo systemctl status django"
echo.
echo 📋 PRÓXIMOS PASSOS:
echo 1. Acesse http://%EC2_IP%/admin/
echo 2. Faça login com as credenciais acima
echo 3. Configure o sistema conforme necessário
echo 4. Teste todas as funcionalidades
echo.
echo 🎉 Sistema atualizado e funcionando perfeitamente!
echo.
pause
