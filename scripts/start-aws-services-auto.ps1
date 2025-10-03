# Script PowerShell para iniciar serviços AWS com atualização automática de IP
# Sistema de Agendamento - 4Minds

param(
    [switch]$Help,
    [switch]$NoDeploy,
    [switch]$NoCommit
)

# Configurações baseadas no terraform.tfstate
$REGION = "us-east-1"
$PROJECT_NAME = "sistema-agendamento"
$EC2_INSTANCE_ID = "i-04d14b81170c26323"
$RDS_INSTANCE_ID = "sistema-agendamento-postgres"

# Função para mostrar ajuda
function Show-Help {
    Write-Host "=== SCRIPT PARA INICIAR SERVIÇOS AWS COM ATUALIZAÇÃO AUTOMÁTICA ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Este script inicia todos os serviços AWS que geram cobrança E:"
    Write-Host "- Atualiza automaticamente o IP nos arquivos de configuração"
    Write-Host "- Faz commit automático no GitHub"
    Write-Host "- Executa deploy automático (opcional)"
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor Yellow
    Write-Host "  .\scripts\start-aws-services-auto.ps1"
    Write-Host "  .\scripts\start-aws-services-auto.ps1 -NoDeploy"
    Write-Host "  .\scripts\start-aws-services-auto.ps1 -NoCommit"
    Write-Host "  .\scripts\start-aws-services-auto.ps1 -Help"
    Write-Host ""
    Write-Host "Parâmetros:" -ForegroundColor Yellow
    Write-Host "  -NoDeploy    Não executar deploy automático"
    Write-Host "  -NoCommit    Não fazer commit automático no GitHub"
    Write-Host "  -Help        Mostrar esta ajuda"
    Write-Host ""
    Write-Host "Pré-requisitos:" -ForegroundColor Yellow
    Write-Host "  - AWS CLI instalado e configurado"
    Write-Host "  - Git configurado com repositório remoto"
    Write-Host "  - Python 3 instalado"
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

Write-ColorOutput "=== INICIANDO SERVIÇOS AWS COM ATUALIZAÇÃO AUTOMÁTICA ===" "Cyan"
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

# Função para verificar Git
function Test-GitRepo {
    try {
        $null = git status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ Repositório Git válido" "Green"
            return $true
        } else {
            Write-ColorOutput "ERRO: Não é um repositório Git válido" "Red"
            return $false
        }
    } catch {
        Write-ColorOutput "ERRO: Git não está instalado ou não está no PATH" "Red"
        return $false
    }
}

# Função para verificar Python
function Test-Python {
    try {
        $null = Get-Command python -ErrorAction Stop
        Write-ColorOutput "✓ Python encontrado" "Green"
        return $true
    } catch {
        try {
            $null = Get-Command python3 -ErrorAction Stop
            Write-ColorOutput "✓ Python3 encontrado" "Green"
            return $true
        } catch {
            Write-ColorOutput "ERRO: Python não está instalado ou não está no PATH" "Red"
            return $false
        }
    }
}

# Função para iniciar instância EC2
function Start-EC2Instance {
    Write-ColorOutput "Iniciando instância EC2..." "Yellow"
    
    try {
        # Verificar status atual
        $currentState = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text
        
        Write-ColorOutput "Status atual da instância EC2: $currentState" "Blue"
        
        if ($currentState -eq "stopped") {
            Write-ColorOutput "Iniciando instância EC2 ($EC2_INSTANCE_ID)..." "Yellow"
            aws ec2 start-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --output table
            
            Write-ColorOutput "Aguardando instância iniciar..." "Yellow"
            aws ec2 wait instance-running --instance-ids $EC2_INSTANCE_ID --region $REGION
            
            # Obter IP público
            $publicIP = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
            
            Write-ColorOutput "✓ Instância EC2 iniciada com sucesso" "Green"
            Write-ColorOutput "✓ IP Público: $publicIP" "Green"
            Write-ColorOutput "✓ URL da aplicação: http://$publicIP" "Green"
        } elseif ($currentState -eq "running") {
            Write-ColorOutput "✓ Instância EC2 já está rodando" "Yellow"
            
            # Obter IP público
            $publicIP = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
            Write-ColorOutput "✓ IP Público: $publicIP" "Green"
            Write-ColorOutput "✓ URL da aplicação: http://$publicIP" "Green"
        } elseif ($currentState -eq "pending") {
            Write-ColorOutput "✓ Instância EC2 já está sendo iniciada" "Yellow"
            aws ec2 wait instance-running --instance-ids $EC2_INSTANCE_ID --region $REGION
            
            # Obter IP público
            $publicIP = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
            
            Write-ColorOutput "✓ Instância EC2 iniciada com sucesso" "Green"
            Write-ColorOutput "✓ IP Público: $publicIP" "Green"
            Write-ColorOutput "✓ URL da aplicação: http://$publicIP" "Green"
        } else {
            Write-ColorOutput "⚠ Instância EC2 está em estado: $currentState" "Yellow"
        }
    } catch {
        Write-ColorOutput "ERRO ao gerenciar instância EC2: $($_.Exception.Message)" "Red"
    }
}

# Função para iniciar instância RDS
function Start-RDSInstance {
    Write-ColorOutput "Iniciando instância RDS..." "Yellow"
    
    try {
        # Verificar status atual
        $currentState = aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --query 'DBInstances[0].DBInstanceStatus' --output text 2>$null
        
        if (-not $currentState) {
            $currentState = "not-found"
        }
        
        Write-ColorOutput "Status atual da instância RDS: $currentState" "Blue"
        
        if ($currentState -eq "stopped") {
            Write-ColorOutput "Iniciando instância RDS ($RDS_INSTANCE_ID)..." "Yellow"
            aws rds start-db-instance --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --output table
            
            Write-ColorOutput "Aguardando instância RDS iniciar..." "Yellow"
            aws rds wait db-instance-available --db-instance-identifier $RDS_INSTANCE_ID --region $REGION
            
            # Obter endpoint
            $rdsEndpoint = aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --query 'DBInstances[0].Endpoint.Address' --output text
            
            Write-ColorOutput "✓ Instância RDS iniciada com sucesso" "Green"
            Write-ColorOutput "✓ Endpoint: $rdsEndpoint" "Green"
        } elseif ($currentState -eq "available") {
            Write-ColorOutput "✓ Instância RDS já está rodando" "Yellow"
            
            # Obter endpoint
            $rdsEndpoint = aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --query 'DBInstances[0].Endpoint.Address' --output text
            Write-ColorOutput "✓ Endpoint: $rdsEndpoint" "Green"
        } elseif ($currentState -eq "starting") {
            Write-ColorOutput "✓ Instância RDS já está sendo iniciada" "Yellow"
            aws rds wait db-instance-available --db-instance-identifier $RDS_INSTANCE_ID --region $REGION
            
            # Obter endpoint
            $rdsEndpoint = aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --query 'DBInstances[0].Endpoint.Address' --output text
            
            Write-ColorOutput "✓ Instância RDS iniciada com sucesso" "Green"
            Write-ColorOutput "✓ Endpoint: $rdsEndpoint" "Green"
        } elseif ($currentState -eq "not-found") {
            Write-ColorOutput "⚠ Instância RDS não encontrada" "Yellow"
        } else {
            Write-ColorOutput "⚠ Instância RDS está em estado: $currentState" "Yellow"
        }
    } catch {
        Write-ColorOutput "ERRO ao gerenciar instância RDS: $($_.Exception.Message)" "Red"
    }
}

# Função para executar atualização automática de IP
function Invoke-AutoIPUpdate {
    Write-ColorOutput "🤖 Executando atualização automática de IP..." "Cyan"
    
    try {
        # Verificar se script Python existe
        $scriptPath = "scripts\auto-ip-update.py"
        if (-not (Test-Path $scriptPath)) {
            Write-ColorOutput "❌ Script auto-ip-update.py não encontrado" "Red"
            return $false
        }
        
        # Construir comando Python
        $pythonCmd = "python"
        if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
            $pythonCmd = "python3"
        }
        
        $cmd = "$pythonCmd `"$scriptPath`""
        if (-not $NoDeploy) {
            $cmd += " --deploy"
        }
        
        Write-ColorOutput "Executando: $cmd" "Blue"
        
        # Executar script Python
        Invoke-Expression $cmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Atualização automática concluída com sucesso!" "Green"
            return $true
        } else {
            Write-ColorOutput "❌ Erro na atualização automática" "Red"
            return $false
        }
    } catch {
        Write-ColorOutput "ERRO ao executar atualização automática: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Função para aguardar serviços ficarem prontos
function Wait-ForServices {
    Write-ColorOutput "Aguardando serviços ficarem prontos..." "Yellow"
    
    try {
        # Aguardar EC2
        $ec2State = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text
        
        if ($ec2State -eq "running") {
            Write-ColorOutput "Aguardando aplicação Django iniciar..." "Yellow"
            Start-Sleep -Seconds 30
            
            # Obter IP público
            $publicIP = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
            
            # Testar se a aplicação está respondendo
            Write-ColorOutput "Testando conectividade da aplicação..." "Yellow"
            try {
                $response = Invoke-WebRequest -Uri "http://$publicIP" -TimeoutSec 10 -ErrorAction Stop
                Write-ColorOutput "✓ Aplicação Django está respondendo" "Green"
            } catch {
                Write-ColorOutput "⚠ Aplicação ainda não está respondendo (pode levar alguns minutos)" "Yellow"
            }
        }
    } catch {
        Write-ColorOutput "Aviso: Não foi possível testar conectividade" "Yellow"
    }
}

# Função para mostrar status final
function Show-FinalStatus {
    Write-Host ""
    Write-ColorOutput "=== STATUS FINAL DOS SERVIÇOS ===" "Cyan"
    
    try {
        # Status EC2
        $ec2State = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text 2>$null
        
        $publicIP = aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>$null
        
        if (-not $publicIP -or $publicIP -eq "None") {
            $publicIP = "N/A"
        }
        
        Write-ColorOutput "EC2 ($EC2_INSTANCE_ID): $ec2State - IP: $publicIP" "Blue"
        
        # Status RDS
        $rdsState = aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --query 'DBInstances[0].DBInstanceStatus' --output text 2>$null
        
        $rdsEndpoint = aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --region $REGION --query 'DBInstances[0].Endpoint.Address' --output text 2>$null
        
        if (-not $rdsEndpoint -or $rdsEndpoint -eq "None") {
            $rdsEndpoint = "N/A"
        }
        
        Write-ColorOutput "RDS ($RDS_INSTANCE_ID): $rdsState - Endpoint: $rdsEndpoint" "Blue"
        
        Write-Host ""
        Write-ColorOutput "=== SERVIÇOS INICIADOS COM SUCESSO ===" "Green"
        
        if ($publicIP -ne "N/A") {
            Write-ColorOutput "URL da aplicação: http://$publicIP" "Green"
            Write-ColorOutput "Comando SSH: ssh -i ~/.ssh/id_rsa ubuntu@$publicIP" "Green"
        }
        
        Write-ColorOutput "Nota: Aguarde alguns minutos para a aplicação ficar completamente pronta" "Yellow"
    } catch {
        Write-ColorOutput "Aviso: Não foi possível obter status final completo" "Yellow"
    }
}

# Função principal
function Main {
    Write-ColorOutput "Iniciando processo de inicialização dos serviços com automação..." "Blue"
    
    # Verificar pré-requisitos
    if (-not (Test-AWSCLI)) {
        Write-ColorOutput "ERRO: AWS CLI não está configurado corretamente" "Red"
        exit 1
    }
    
    if (-not $NoCommit) {
        if (-not (Test-GitRepo)) {
            Write-ColorOutput "ERRO: Repositório Git não configurado" "Red"
            exit 1
        }
        
        if (-not (Test-Python)) {
            Write-ColorOutput "ERRO: Python não está instalado" "Red"
            exit 1
        }
    }
    
    # Iniciar serviços
    Start-RDSInstance
    Start-EC2Instance
    
    # Aguardar serviços ficarem prontos
    Wait-ForServices
    
    # Executar atualização automática (se não desabilitado)
    if (-not $NoCommit) {
        Invoke-AutoIPUpdate
    }
    
    Show-FinalStatus
}

# Executar função principal
Main
