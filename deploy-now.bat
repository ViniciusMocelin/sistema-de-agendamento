@echo off
echo ===============================================
echo    DEPLOY SISTEMA DE AGENDAMENTO - 4MINDS
echo ===============================================
echo.

REM Configurar AWS CLI path
set AWS_PATH="C:\Program Files\Amazon\AWSCLIV2\aws.exe"

REM Configurações
set REGION=us-east-1
set EC2_INSTANCE_ID=i-04d14b81170c26323

echo Verificando status da EC2...
%AWS_PATH% ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].State.Name" --output text

echo.
echo Obtendo IP da EC2...
for /f "tokens=*" %%i in ('%AWS_PATH% ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set PUBLIC_IP=%%i

echo IP Publico: %PUBLIC_IP%
echo.

if "%PUBLIC_IP%"=="None" (
    echo ERRO: Nao foi possivel obter IP da EC2
    echo Verifique se a instancia esta rodando
    pause
    exit /b 1
)

echo ===============================================
echo    FAZENDO DEPLOY NA EC2
echo ===============================================
echo.

echo Executando deploy via SSH...
ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@%PUBLIC_IP% "cd /home/django/sistema-agendamento && source venv/bin/activate && git pull origin main && pip install -r requirements.txt && python manage.py migrate --settings=core.settings_production && python manage.py collectstatic --noinput --settings=core.settings_production && python manage.py create_4minds_superuser --force --no-input --settings=core.settings_production && sudo systemctl restart django && sudo systemctl restart nginx"

if %errorlevel% equ 0 (
    echo.
    echo ===============================================
    echo    DEPLOY CONCLUIDO COM SUCESSO!
    echo ===============================================
    echo.
    echo URL da aplicacao: http://%PUBLIC_IP%
    echo Admin Django: http://%PUBLIC_IP%/admin/
    echo.
    echo Credenciais do Admin:
    echo Usuario: @4minds
    echo Senha: @4mindsPassword
    echo.
    echo Aguarde alguns minutos para a aplicacao ficar pronta...
) else (
    echo.
    echo ===============================================
    echo    ERRO NO DEPLOY
    echo ===============================================
    echo.
    echo Verifique os logs e tente novamente
)

echo.
pause

