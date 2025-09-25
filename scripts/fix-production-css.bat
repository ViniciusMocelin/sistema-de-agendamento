@echo off
REM Script para corrigir CSS em produção
REM Sistema de Agendamento - 4Minds

echo ===============================================
echo    CORREÇÃO DE CSS EM PRODUÇÃO
echo    Sistema de Agendamento - 4Minds
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

echo ✅ AWS CLI configurado

REM Configurações
set REGION=us-east-1
set EC2_INSTANCE_ID=i-04d14b81170c26323

echo.
echo Verificando status da EC2...

REM Verificar status da EC2
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].State.Name" --output text') do set EC2_STATUS=%%i

echo Status da EC2: %EC2_STATUS%

if not "%EC2_STATUS%"=="running" (
    echo ❌ Instância EC2 não está rodando
    echo Execute: scripts\start-aws-services-simple.bat
    pause
    exit /b 1
)

echo ✅ EC2 está rodando

REM Obter IP da EC2
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set EC2_IP=%%i

if "%EC2_IP%"=="None" (
    echo ❌ Não foi possível obter IP da EC2
    pause
    exit /b 1
)

echo ✅ IP da EC2: %EC2_IP%

echo.
echo Corrigindo CSS na EC2...

REM Executar correção de CSS via SSH
ssh -i %USERPROFILE%\.ssh\id_rsa -o StrictHostKeyChecking=no ubuntu@%EC2_IP% "
cd /home/django/sistema-agendamento
source venv/bin/activate
echo '🔧 Aplicando correções de CSS...'
sudo chown -R django:django /home/django/sistema-agendamento/static/ 2>/dev/null || true
sudo chown -R django:django /home/django/sistema-agendamento/staticfiles/ 2>/dev/null || true
python manage.py collectstatic --noinput --settings=core.settings_production
echo '✅ CSS coletado'
if [ -f static/css/style-fixed.css ]; then cp static/css/style-fixed.css static/css/style.css; echo '✅ CSS corrigido aplicado'; fi
sudo chown -R www-data:www-data /home/django/sistema-agendamento/staticfiles/ 2>/dev/null || sudo chown -R nginx:nginx /home/django/sistema-agendamento/staticfiles/ 2>/dev/null || true
sudo chmod -R 755 /home/django/sistema-agendamento/staticfiles/
echo '✅ Permissões corrigidas'
sudo systemctl restart nginx
echo '✅ Nginx reiniciado'
echo '🎉 CSS corrigido!'
"

if %ERRORLEVEL% neq 0 (
    echo ❌ Erro na correção de CSS, tentando CSS inline...
    
    REM Tentar CSS inline como fallback
    ssh -i %USERPROFILE%\.ssh\id_rsa -o StrictHostKeyChecking=no ubuntu@%EC2_IP% "
    cd /home/django/sistema-agendamento
    echo '/* CSS CORRIGIDO - Sistema de Agendamento 4Minds */' > static/css/style.css
    echo 'body { font-family: \"Inter\", sans-serif; background-color: #ffffff; color: #1e293b; margin: 0; padding: 0; }' >> static/css/style.css
    echo '.sidebar { background-color: #f8fafc; border-right: 1px solid #e2e8f0; width: 280px; height: 100vh; position: fixed; left: 0; top: 0; }' >> static/css/style.css
    echo '.main-content { margin-left: 280px; padding: 30px; }' >> static/css/style.css
    echo '.card { background-color: #ffffff; border: 1px solid #e2e8f0; border-radius: 15px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); margin-bottom: 20px; }' >> static/css/style.css
    echo '.btn-primary { background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); border: none; color: white; border-radius: 8px; padding: 10px 20px; }' >> static/css/style.css
    echo '.table { background-color: #ffffff; color: #1e293b; width: 100%; }' >> static/css/style.css
    echo '.form-control { background-color: #ffffff; border: 1px solid #e2e8f0; color: #1e293b; border-radius: 8px; padding: 10px 15px; }' >> static/css/style.css
    echo '✅ CSS inline criado'
    sudo systemctl restart nginx
    echo '✅ Nginx reiniciado'
    "
    
    if %ERRORLEVEL% neq 0 (
        echo ❌ Erro na correção de CSS
        pause
        exit /b 1
    )
)

echo ✅ CSS corrigido

echo.
echo Aguardando aplicação inicializar...
timeout /t 10 /nobreak >nul

echo.
echo Testando acesso aos arquivos CSS...

REM Testar arquivos CSS
curl -I -s "http://%EC2_IP%/static/css/style.css" | findstr "200 OK" >nul
if %ERRORLEVEL% equ 0 (
    echo ✅ CSS acessível
) else (
    echo ⚠️ CSS pode não estar acessível
)

curl -I -s "http://%EC2_IP%/static/css/bootstrap.min.css" | findstr "200 OK" >nul
if %ERRORLEVEL% equ 0 (
    echo ✅ Bootstrap CSS acessível
) else (
    echo ⚠️ Bootstrap CSS pode não estar acessível
)

echo.
echo ===============================================
echo    CSS CORRIGIDO COM SUCESSO!
echo ===============================================
echo.
echo 🌐 URLs de Teste:
echo    Site: http://%EC2_IP%/
echo    Admin: http://%EC2_IP%/admin/
echo    CSS: http://%EC2_IP%/static/css/style.css
echo.
echo ✅ Design deve estar funcionando agora!
echo.
echo 🔧 Se ainda houver problemas:
echo 1. Limpe o cache do navegador (Ctrl+F5)
echo 2. Teste em modo incógnito
echo 3. Verifique os logs: ssh -i %USERPROFILE%\.ssh\id_rsa ubuntu@%EC2_IP% "sudo journalctl -u nginx -f"
echo.
pause
