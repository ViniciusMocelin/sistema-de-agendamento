@echo off
REM Script Batch para iniciar serviços AWS com atualização automática
REM Sistema de Agendamento - 4Minds

echo ===============================================
echo    INICIANDO SERVICOS AWS COM AUTOMACAO
echo    Sistema de Agendamento - 4Minds
echo ===============================================
echo.

REM Verificar se o AWS CLI está instalado
where aws >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: AWS CLI nao esta instalado ou nao esta no PATH
    echo.
    echo Instale o AWS CLI em: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

REM Verificar se o AWS CLI está configurado
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: AWS CLI nao esta configurado ou credenciais invalidas
    echo.
    echo Configure o AWS CLI com: aws configure
    pause
    exit /b 1
)

echo ✓ AWS CLI configurado corretamente
echo.

REM Verificar se Git está disponível
git status >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: Git nao esta configurado ou nao e um repositorio valido
    echo.
    echo Configure o Git e certifique-se de estar em um repositorio
    pause
    exit /b 1
)

echo ✓ Repositorio Git valido
echo.

REM Verificar se Python está disponível
python --version >nul 2>&1
if %errorlevel% neq 0 (
    python3 --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERRO: Python nao esta instalado
        echo.
        echo Instale o Python em: https://python.org/
        pause
        exit /b 1
    )
)

echo ✓ Python encontrado
echo.

REM Configurações
set REGION=us-east-1
set EC2_INSTANCE_ID=i-04d14b81170c26323
set RDS_INSTANCE_ID=sistema-agendamento-postgres

echo ===============================================
echo    INICIANDO INSTANCIA RDS
echo ===============================================
echo.

REM Verificar status atual da RDS
echo Verificando status da instancia RDS...
for /f "tokens=*" %%i in ('aws rds describe-db-instances --db-instance-identifier %RDS_INSTANCE_ID% --region %REGION% --query "DBInstances[0].DBInstanceStatus" --output text 2^>nul') do set RDS_STATUS=%%i

if "%RDS_STATUS%"=="" set RDS_STATUS=not-found

echo Status atual da RDS: %RDS_STATUS%

if "%RDS_STATUS%"=="stopped" (
    echo Iniciando instancia RDS...
    aws rds start-db-instance --db-instance-identifier %RDS_INSTANCE_ID% --region %REGION%
    
    echo Aguardando instancia RDS iniciar...
    aws rds wait db-instance-available --db-instance-identifier %RDS_INSTANCE_ID% --region %REGION%
    
    echo ✓ Instancia RDS iniciada com sucesso
) else if "%RDS_STATUS%"=="available" (
    echo ✓ Instancia RDS ja esta rodando
) else if "%RDS_STATUS%"=="starting" (
    echo ✓ Instancia RDS ja esta sendo iniciada
    aws rds wait db-instance-available --db-instance-identifier %RDS_INSTANCE_ID% --region %REGION%
    echo ✓ Instancia RDS iniciada com sucesso
) else (
    echo ⚠ Instancia RDS esta em estado: %RDS_STATUS%
)

echo.
echo ===============================================
echo    INICIANDO INSTANCIA EC2
echo ===============================================
echo.

REM Verificar status atual da EC2
echo Verificando status da instancia EC2...
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].State.Name" --output text') do set EC2_STATUS=%%i

echo Status atual da EC2: %EC2_STATUS%

if "%EC2_STATUS%"=="stopped" (
    echo Iniciando instancia EC2...
    aws ec2 start-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION%
    
    echo Aguardando instancia EC2 iniciar...
    aws ec2 wait instance-running --instance-ids %EC2_INSTANCE_ID% --region %REGION%
    
    echo ✓ Instancia EC2 iniciada com sucesso
    
    REM Obter IP público
    for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set PUBLIC_IP=%%i
    echo ✓ IP Publico: %PUBLIC_IP%
    echo ✓ URL da aplicacao: http://%PUBLIC_IP%
    
) else if "%EC2_STATUS%"=="running" (
    echo ✓ Instancia EC2 ja esta rodando
    
    REM Obter IP público
    for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set PUBLIC_IP=%%i
    echo ✓ IP Publico: %PUBLIC_IP%
    echo ✓ URL da aplicacao: http://%PUBLIC_IP%
    
) else if "%EC2_STATUS%"=="pending" (
    echo ✓ Instancia EC2 ja esta sendo iniciada
    aws ec2 wait instance-running --instance-ids %EC2_INSTANCE_ID% --region %REGION%
    
    REM Obter IP público
    for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].PublicIpAddress" --output text') do set PUBLIC_IP=%%i
    echo ✓ Instancia EC2 iniciada com sucesso
    echo ✓ IP Publico: %PUBLIC_IP%
    echo ✓ URL da aplicacao: http://%PUBLIC_IP%
    
) else (
    echo ⚠ Instancia EC2 esta em estado: %EC2_STATUS%
)

echo.
echo ===============================================
echo    EXECUTANDO ATUALIZACAO AUTOMATICA
echo ===============================================
echo.

REM Verificar se script Python existe
if not exist "scripts\auto-ip-update.py" (
    echo ERRO: Script auto-ip-update.py nao encontrado
    echo.
    echo Certifique-se de que o arquivo existe em scripts\auto-ip-update.py
    pause
    exit /b 1
)

echo Executando atualizacao automatica de IP e deploy...

REM Executar script Python
python scripts\auto-ip-update.py --deploy

if %errorlevel% equ 0 (
    echo.
    echo ===============================================
    echo    ATUALIZACAO AUTOMATICA CONCLUIDA!
    echo ===============================================
    echo.
    echo ✓ IP atualizado nos arquivos de configuracao
    echo ✓ Commit realizado no GitHub
    echo ✓ Deploy executado na AWS
    echo.
    echo Sistema sincronizado e funcionando!
) else (
    echo.
    echo ===============================================
    echo    ERRO NA ATUALIZACAO AUTOMATICA
    echo ===============================================
    echo.
    echo Verifique os logs acima para detalhes do erro
    echo.
    echo Voce pode tentar executar manualmente:
    echo   python scripts\auto-ip-update.py
    echo   deploy-now.bat
)

echo.
echo ===============================================
echo    STATUS FINAL DOS SERVICOS
echo ===============================================
echo.

REM Status final
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].State.Name" --output text') do set EC2_FINAL=%%i
for /f "tokens=*" %%i in ('aws rds describe-db-instances --db-instance-identifier %RDS_INSTANCE_ID% --region %REGION% --query "DBInstances[0].DBInstanceStatus" --output text 2^>nul') do set RDS_FINAL=%%i

echo EC2 (%EC2_INSTANCE_ID%): %EC2_FINAL%
echo RDS (%RDS_INSTANCE_ID%): %RDS_FINAL%

echo.
echo ===============================================
echo    SERVICOS INICIADOS COM SUCESSO!
echo ===============================================
echo.

if not "%PUBLIC_IP%"=="" (
    echo URL da aplicacao: http://%PUBLIC_IP%
    echo Comando SSH: ssh -i ~/.ssh/id_rsa ubuntu@%PUBLIC_IP%
    echo.
    echo Credenciais do Admin:
    echo Usuario: @4minds
    echo Senha: @4mindsPassword
    echo.
    echo Admin Django: http://%PUBLIC_IP%/admin/
    echo Dashboard: http://%PUBLIC_IP%/dashboard/
)

echo.
echo Nota: Aguarde alguns minutos para a aplicacao ficar completamente pronta
echo.
pause
