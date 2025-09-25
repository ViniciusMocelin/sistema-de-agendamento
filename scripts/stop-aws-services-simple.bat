@echo off
REM Script simples para parar serviços AWS - Sistema de Agendamento
REM Sistema de Agendamento - 4Minds

echo ===============================================
echo    PARANDO SERVICOS AWS - SISTEMA DE AGENDAMENTO
echo ===============================================
echo.

REM Configurações
set REGION=us-east-1
set EC2_INSTANCE_ID=i-04d14b81170c26323
set RDS_INSTANCE_ID=sistema-agendamento-postgres

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
echo Verificando configuracao do AWS CLI...
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

echo ===============================================
echo    PARANDO INSTANCIA EC2
echo ===============================================
echo.

REM Verificar status atual da EC2
echo Verificando status da instancia EC2...
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION% --query "Reservations[0].Instances[0].State.Name" --output text') do set EC2_STATUS=%%i

echo Status atual da EC2: %EC2_STATUS%

if "%EC2_STATUS%"=="running" (
    echo Parando instancia EC2...
    aws ec2 stop-instances --instance-ids %EC2_INSTANCE_ID% --region %REGION%
    
    echo Aguardando instancia EC2 parar...
    aws ec2 wait instance-stopped --instance-ids %EC2_INSTANCE_ID% --region %REGION%
    
    echo ✓ Instancia EC2 parada com sucesso
) else if "%EC2_STATUS%"=="stopped" (
    echo ✓ Instancia EC2 ja esta parada
) else if "%EC2_STATUS%"=="stopping" (
    echo ✓ Instancia EC2 ja esta sendo parada
    aws ec2 wait instance-stopped --instance-ids %EC2_INSTANCE_ID% --region %REGION%
    echo ✓ Instancia EC2 parada com sucesso
) else (
    echo ⚠ Instancia EC2 esta em estado: %EC2_STATUS%
)

echo.
echo ===============================================
echo    PARANDO INSTANCIA RDS
echo ===============================================
echo.

REM Verificar status atual da RDS
echo Verificando status da instancia RDS...
for /f "tokens=*" %%i in ('aws rds describe-db-instances --db-instance-identifier %RDS_INSTANCE_ID% --region %REGION% --query "DBInstances[0].DBInstanceStatus" --output text 2^>nul') do set RDS_STATUS=%%i

if "%RDS_STATUS%"=="" set RDS_STATUS=not-found

echo Status atual da RDS: %RDS_STATUS%

if "%RDS_STATUS%"=="available" (
    echo Parando instancia RDS...
    aws rds stop-db-instance --db-instance-identifier %RDS_INSTANCE_ID% --region %REGION%
    
    echo Aguardando instancia RDS parar...
    aws rds wait db-instance-stopped --db-instance-identifier %RDS_INSTANCE_ID% --region %REGION%
    
    echo ✓ Instancia RDS parada com sucesso
) else if "%RDS_STATUS%"=="stopped" (
    echo ✓ Instancia RDS ja esta parada
) else if "%RDS_STATUS%"=="stopping" (
    echo ✓ Instancia RDS ja esta sendo parada
    aws rds wait db-instance-stopped --db-instance-identifier %RDS_INSTANCE_ID% --region %REGION%
    echo ✓ Instancia RDS parada com sucesso
) else if "%RDS_STATUS%"=="not-found" (
    echo ⚠ Instancia RDS nao encontrada
) else (
    echo ⚠ Instancia RDS esta em estado: %RDS_STATUS%
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
echo    SERVICOS PARADOS COM SUCESSO!
echo ===============================================
echo.
echo Nota: S3, CloudWatch Logs, SNS e outros servicos continuam ativos
echo Para parar completamente todos os recursos, execute: terraform destroy
echo.
pause
