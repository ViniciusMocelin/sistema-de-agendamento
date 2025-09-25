# Script PowerShell para parar todos os serviços AWS que geram cobrança
# Sistema de Agendamento - 4Minds

param(
    [switch]$Help
)

# Configurações baseadas no terraform.tfstate
$REGION = "us-east-1"
$PROJECT_NAME = "sistema-agendamento"
$EC2_INSTANCE_ID = "i-04d14b81170c26323"
$RDS_INSTANCE_ID = "sistema-agendamento-postgres"

# Função para mostrar ajuda
function Show-Help {
    Write-Host "=== SCRIPT PARA PARAR SERVIÇOS AWS ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Este script para todos os serviços AWS que geram cobrança:"
    Write-Host "- EC2 Instance: $EC2_INSTANCE_ID"
    Write-Host "- RDS PostgreSQL: $RDS_INSTANCE_ID"
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor Yellow
    Write-Host "  .\scripts\stop-aws-services.ps1"
    Write-Host "  .\scripts\stop-aws-services.ps1 -Help"
    Write-Host ""
    Write-Host "Pré-requisitos:" -ForegroundColor Yellow
    Write-Host "  - AWS CLI instalado e configurado"
    Write-Host "  - Permissões adequadas para EC2 e RDS"
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
}

# Cores para output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "=== PARANDO SERVIÇOS AWS - SISTEMA DE AGENDAMENTO ===" "Cyan"
Write-ColorOutput "Região: $REGION" "Blue"
Write-ColorOutput "Projeto: $PROJECT_NAME" "Blue"
Write-Host ""

# Função para verificar se o AWS CLI está configurado
function Test-AWSCLI {
    try {
        $null = Get-Command aws -ErrorAction Stop
        Write-ColorOutput "✓ AWS CLI encontrado" "Green"
        
        # Testar credenciais
        $null = aws sts get-caller-identity 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ AWS CLI configurado corretamente" "Green"
            return $true
        } else {
            Write-ColorOutput "ERRO: AWS CLI não está configurado ou credenciais inválidas" "Red"
            return $false
        }
    } catch {
        Write-ColorOutput "ERRO: AWS CLI não está instalado ou não está no PATH" "Red"
        return $false
    }
}

# Função para parar instância EC2
function Stop-EC2Instance {
    Write-ColorOutput "Parando instância EC2..." "Yellow"
    
    try {
        # Verificar status atual
        $currentState = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text
        
        Write-ColorOutput "Status atual da instância EC2: $currentState" "Blue"
        
        if ($currentState -eq "running") {
            Write-ColorOutput "Parando instância EC2 ($EC2_INSTANCE_ID)..." "Yellow"
            aws ec2 stop-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --output table
            
            Write-ColorOutput "Aguardando instância parar..." "Yellow"
            aws ec2 wait instance-stopped --instance-ids $EC2_INSTANCE_ID --region $REGION
            
            Write-ColorOutput "✓ Instância EC2 parada com sucesso" "Green"
        } elseif ($currentState -eq "stopped") {
            Write-ColorOutput "✓ Instância EC2 já está parada" "Yellow"
        } elseif ($currentState -eq "stopping") {
            Write-ColorOutput "✓ Instância EC2 já está sendo parada" "Yellow"
            aws ec2 wait instance-stopped --instance-ids $EC2_INSTANCE_ID --region $REGION
            Write-ColorOutput "✓ Instância EC2 parada com sucesso" "Green"
        } else {
            Write-ColorOutput "⚠ Instância EC2 está em estado: $currentState" "Yellow"
        }
    } catch {
        Write-ColorOutput "ERRO ao gerenciar instância EC2: $($_.Exception.Message)" "Red"
    }
}

# Função para parar instância RDS
function Stop-RDSInstance {
    Write-ColorOutput "Parando instância RDS..." "Yellow"
    
    try {
        # Verificar status atual
        $currentState = aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --query 'DBInstances[0].DBInstanceStatus' --output text 2>$null
        
        if (-not $currentState) {
            $currentState = "not-found"
        }
        
        Write-ColorOutput "Status atual da instância RDS: $currentState" "Blue"
        
        if ($currentState -eq "available") {
            Write-ColorOutput "Parando instância RDS ($RDS_INSTANCE_ID)..." "Yellow"
            aws rds stop-db-instance --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --output table
            
            Write-ColorOutput "Aguardando instância RDS parar..." "Yellow"
            aws rds wait db-instance-stopped --db-instance-identifier $RDS_INSTANCE_ID --region $REGION
            
            Write-ColorOutput "✓ Instância RDS parada com sucesso" "Green"
        } elseif ($currentState -eq "stopped") {
            Write-ColorOutput "✓ Instância RDS já está parada" "Yellow"
        } elseif ($currentState -eq "stopping") {
            Write-ColorOutput "✓ Instância RDS já está sendo parada" "Yellow"
            aws rds wait db-instance-stopped --db-instance-identifier $RDS_INSTANCE_ID --region $REGION
            Write-ColorOutput "✓ Instância RDS parada com sucesso" "Green"
        } elseif ($currentState -eq "not-found") {
            Write-ColorOutput "⚠ Instância RDS não encontrada" "Yellow"
        } else {
            Write-ColorOutput "⚠ Instância RDS está em estado: $currentState" "Yellow"
        }
    } catch {
        Write-ColorOutput "ERRO ao gerenciar instância RDS: $($_.Exception.Message)" "Red"
    }
}

# Função para mostrar status final
function Show-FinalStatus {
    Write-Host ""
    Write-ColorOutput "=== STATUS FINAL DOS SERVIÇOS ===" "Cyan"
    
    try {
        # Status EC2
        $ec2State = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text 2>$null
        if (-not $ec2State) {
            $ec2State = "not-found"
        }
        Write-ColorOutput "EC2 ($EC2_INSTANCE_ID): $ec2State" "Blue"
        
        # Status RDS
        $rdsState = aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --query 'DBInstances[0].DBInstanceStatus' --output text 2>$null
        if (-not $rdsState) {
            $rdsState = "not-found"
        }
        Write-ColorOutput "RDS ($RDS_INSTANCE_ID): $rdsState" "Blue"
        
        Write-Host ""
        Write-ColorOutput "=== SERVIÇOS PARADOS COM SUCESSO ===" "Green"
        Write-ColorOutput "Nota: S3, CloudWatch Logs, SNS e outros serviços continuam ativos" "Yellow"
        Write-ColorOutput "Para parar completamente todos os recursos, execute: terraform destroy" "Yellow"
    } catch {
        Write-ColorOutput "Aviso: Não foi possível obter status final completo" "Yellow"
    }
}

# Função principal
function Main {
    Write-ColorOutput "Iniciando processo de parada dos serviços..." "Blue"
    
    if (-not (Test-AWSCLI)) {
        Write-ColorOutput "ERRO: AWS CLI não está configurado corretamente" "Red"
        exit 1
    }
    
    Stop-EC2Instance
    Stop-RDSInstance
    Show-FinalStatus
}

# Executar função principal
Main
