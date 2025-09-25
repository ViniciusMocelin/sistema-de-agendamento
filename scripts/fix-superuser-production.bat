@echo off
REM Script para corrigir superuser em produção
REM Sistema de Agendamento - 4Minds

echo ===============================================
echo    CORREÇÃO DE SUPERUSER EM PRODUÇÃO
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
echo Verificando usuário na EC2...

REM Executar comando via SSH
ssh -i %USERPROFILE%\.ssh\id_rsa -o StrictHostKeyChecking=no ubuntu@%EC2_IP% "cd /home/django/sistema-agendamento && source venv/bin/activate && python -c \"
from django.contrib.auth import get_user_model
User = get_user_model()

username = '@4minds'
if User.objects.filter(username=username).exists():
    user = User.objects.get(username=username)
    print(f'✅ Usuário {username} encontrado!')
    print(f'📧 Email: {user.email}')
    print(f'🔑 É superuser: {user.is_superuser}')
    print(f'👨‍💼 É staff: {user.is_staff}')
    print(f'✅ Está ativo: {user.is_active}')
    print(f'📅 Data de criação: {user.date_joined}')
    print(f'📅 Último login: {user.last_login}')
    
    test_password = '@4mindsPassword'
    if user.check_password(test_password):
        print('✅ Senha está correta!')
    else:
        print('❌ Senha está incorreta!')
        print('💡 Redefinindo senha...')
        user.set_password(test_password)
        user.save()
        print('✅ Senha redefinida com sucesso!')
else:
    print(f'❌ Usuário {username} não encontrado!')
    print('💡 Criando usuário...')
    user = User.objects.create_superuser(
        username=username,
        email='admin@4minds.com',
        password='@4mindsPassword'
    )
    print(f'✅ Usuário {username} criado com sucesso!')

print('\n👥 Todos os usuários do sistema:')
users = User.objects.all()
for user in users:
    print(f'👤 {user.username} (superuser: {user.is_superuser}, staff: {user.is_staff}, ativo: {user.is_active})')
\""

if %ERRORLEVEL% neq 0 (
    echo ❌ Erro durante verificação
    pause
    exit /b 1
)

echo.
echo ===============================================
echo    VERIFICAÇÃO CONCLUÍDA!
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
echo 3. Se ainda não funcionar, verifique os logs
echo.
echo 🔧 Comandos úteis:
echo    SSH: ssh -i %USERPROFILE%\.ssh\id_rsa ubuntu@%EC2_IP%
echo    Logs: ssh -i %USERPROFILE%\.ssh\id_rsa ubuntu@%EC2_IP% "sudo journalctl -u django -f"
echo.
echo 🎉 Verificação concluída!
echo.
pause
