@echo off
REM Script de Configuração da Infraestrutura AWS - Windows
REM Sistema de Agendamento

echo.
echo ========================================
echo   CONFIGURACAO DA INFRAESTRUTURA AWS
echo ========================================
echo.

REM Verificar se estamos no diretório correto
if not exist "manage.py" (
    echo ERRO: Execute este script a partir do diretório raiz do projeto Django
    pause
    exit /b 1
)

REM Verificar dependências
echo Verificando dependências...

REM Verificar AWS CLI
aws --version >nul 2>&1
if errorlevel 1 (
    echo ERRO: AWS CLI não está instalado. Instale em: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

REM Verificar Terraform
terraform --version >nul 2>&1
if errorlevel 1 (
    echo ERRO: Terraform não está instalado. Instale em: https://terraform.io/downloads
    pause
    exit /b 1
)

echo [OK] Todas as dependências estão instaladas

REM Configurar AWS CLI
echo.
echo Configurando AWS CLI...
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo AWS CLI não está configurado. Configure com: aws configure
    pause
    exit /b 1
)

echo [OK] AWS CLI configurado

REM Configurar chave SSH
echo.
echo Configurando chave SSH...
if not exist "%USERPROFILE%\.ssh\id_rsa.pub" (
    echo Chave SSH não encontrada. Gerando nova chave...
    ssh-keygen -t rsa -b 4096 -f "%USERPROFILE%\.ssh\id_rsa" -N ""
)

echo [OK] Chave SSH configurada

REM Configurar Terraform
echo.
echo Configurando Terraform...
cd aws-infrastructure

REM Verificar se terraform.tfvars existe
if not exist "terraform.tfvars" (
    echo Arquivo terraform.tfvars não encontrado. Criando a partir do exemplo...
    copy terraform.tfvars.example terraform.tfvars
    
    echo.
    echo Configure as variáveis no arquivo terraform.tfvars:
    echo - db_password: Senha do banco de dados
    echo - domain_name: Domínio (opcional)
    echo - notification_email: Email para notificações
    echo.
    pause
)

REM Inicializar Terraform
echo Inicializando Terraform...
terraform init
if errorlevel 1 (
    echo ERRO: Falha ao inicializar Terraform
    pause
    exit /b 1
)

echo [OK] Terraform inicializado

REM Planejar mudanças
echo.
echo Planejando mudanças...
terraform plan -out=tfplan
if errorlevel 1 (
    echo ERRO: Falha ao planejar mudanças
    pause
    exit /b 1
)

REM Aplicar mudanças
echo.
echo Aplicando mudanças...
terraform apply tfplan
if errorlevel 1 (
    echo ERRO: Falha ao aplicar mudanças
    pause
    exit /b 1
)

REM Obter outputs
echo.
echo Obtendo informações da infraestrutura...
for /f "tokens=*" %%i in ('terraform output -raw ec2_public_ip') do set EC2_IP=%%i
for /f "tokens=*" %%i in ('terraform output -raw rds_endpoint') do set RDS_ENDPOINT=%%i
for /f "tokens=*" %%i in ('terraform output -raw s3_bucket_name') do set S3_BUCKET=%%i

echo.
echo ========================================
echo   INFRAESTRUTURA CONFIGURADA COM SUCESSO!
echo ========================================
echo.
echo INFORMAÇÕES DA INFRAESTRUTURA:
echo   • EC2 IP: %EC2_IP%
echo   • RDS Endpoint: %RDS_ENDPOINT%
echo   • S3 Bucket: %S3_BUCKET%
echo.
echo ACESSO À APLICAÇÃO:
echo   • URL: http://%EC2_IP%
echo   • Admin: http://%EC2_IP%/admin/
echo   • Usuário: admin
echo   • Senha: admin123
echo.
echo CONEXÃO SSH:
echo   ssh -i %%USERPROFILE%%\.ssh\id_rsa ubuntu@%EC2_IP%
echo.
echo PRÓXIMOS PASSOS:
echo   1. Aguarde alguns minutos para a aplicação inicializar
echo   2. Acesse a aplicação e configure seu sistema
echo   3. Altere a senha do admin
echo   4. Configure seu domínio (se aplicável)
echo   5. Configure backup automático
echo   6. Configure monitoramento
echo.
echo IMPORTANTE:
echo   • Altere a senha do banco de dados
echo   • Configure backup automático
echo   • Monitore os custos da AWS
echo   • Configure alertas de segurança
echo.

REM Salvar informações em arquivo
echo Infraestrutura AWS Criada > ..\infrastructure-info.txt
echo ======================== >> ..\infrastructure-info.txt
echo. >> ..\infrastructure-info.txt
echo EC2 IP: %EC2_IP% >> ..\infrastructure-info.txt
echo RDS Endpoint: %RDS_ENDPOINT% >> ..\infrastructure-info.txt
echo S3 Bucket: %S3_BUCKET% >> ..\infrastructure-info.txt
echo. >> ..\infrastructure-info.txt
echo Aplicação: http://%EC2_IP% >> ..\infrastructure-info.txt
echo Admin: http://%EC2_IP%/admin/ >> ..\infrastructure-info.txt
echo SSH: ssh -i %%USERPROFILE%%\.ssh\id_rsa ubuntu@%EC2_IP% >> ..\infrastructure-info.txt
echo. >> ..\infrastructure-info.txt
echo Criado em: %DATE% %TIME% >> ..\infrastructure-info.txt

echo [OK] Informações salvas em infrastructure-info.txt

cd ..

echo.
echo Pressione qualquer tecla para continuar...
pause >nul
