@echo off
REM Script para criar superuser em produção
REM Sistema de Agendamento - 4Minds

echo ===============================================
echo    CRIAÇÃO DE SUPERUSER EM PRODUÇÃO
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
echo Criando superuser na EC2...

REM Executar comando via SSH
ssh -i %USERPROFILE%\.ssh\id_rsa -o StrictHostKeyChecking=no ubuntu@%EC2_IP% "cd /home/django/sistema-agendamento && source venv/bin/activate && python manage.py create_4minds_superuser --no-input"

if %ERRORLEVEL% neq 0 (
    echo ❌ Erro ao criar superuser
    pause
    exit /b 1
)

echo.
echo ===============================================
echo    SUPERUSER CRIADO COM SUCESSO!
echo ===============================================
echo.
echo 👤 Credenciais do Superuser:
echo    Usuário: @4minds
echo    Senha: @4mindsPassword
echo    Email: admin@4minds.com
echo.
echo 🌐 URLs de Acesso:
echo    Admin Django: http://%EC2_IP%/admin/
echo    Dashboard: http://%EC2_IP%/dashboard/
echo.
echo 📋 Próximos passos:
echo 1. Acesse http://%EC2_IP%/admin/
echo 2. Faça login com as credenciais acima
echo 3. Configure o sistema conforme necessário
echo.
echo 🎉 Superuser pronto para uso!
echo.
pause
