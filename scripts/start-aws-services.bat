@echo off
REM Script Batch para iniciar serviços AWS - Sistema de Agendamento
REM Sistema de Agendamento - 4Minds

echo ===============================================
echo    INICIANDO SERVICOS AWS - SISTEMA DE AGENDAMENTO
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

REM Executar script PowerShell
echo Executando script PowerShell...
powershell -ExecutionPolicy Bypass -File "%~dp0start-aws-services.ps1"

echo.
echo Script concluido!
pause
