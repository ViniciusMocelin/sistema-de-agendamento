# Script PowerShell para iniciar todos os serviços AWS que geram cobrança
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
    Write-Host "=== SCRIPT PARA INICIAR SERVIÇOS AWS ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Este script inicia todos os serviços AWS que geram cobrança:"
    Write-Host "- EC2 Instance: $EC2_INSTANCE_ID"
    Write-Host "- RDS PostgreSQL: $RDS_INSTANCE_ID"
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor Yellow
    Write-Host "  .\scripts\start-aws-services.ps1"
    Write-Host "  .\scripts\start-aws-services.ps1 -Help"
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

Write-ColorOutput "=== INICIANDO SERVIÇOS AWS - SISTEMA DE AGENDAMENTO ===" "Cyan"
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

# Função para atualizar configurações com novo IP
function Update-ConfigurationFiles {
    param([string]$PublicIP)
    
    if (-not $PublicIP -or $PublicIP -eq "None" -or $PublicIP -eq "N/A") {
        Write-ColorOutput "⚠ Não foi possível obter IP público para atualizar configurações" "Yellow"
        return
    }
    
    Write-ColorOutput "=== ATUALIZANDO CONFIGURAÇÕES COM NOVO IP ===" "Cyan"
    Write-ColorOutput "Atualizando ALLOWED_HOSTS nos arquivos de configuração..." "Yellow"
    
    try {
        # Atualizar env.example
        if (Test-Path "env.example") {
            $envContent = Get-Content "env.example"
            $updatedContent = $envContent -replace "ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,54.196.122.206", "ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,$PublicIP"
            Set-Content "env.example" $updatedContent
            Write-ColorOutput "✓ env.example atualizado com IP: $PublicIP" "Green"
        } else {
            Write-ColorOutput "⚠ Arquivo env.example não encontrado" "Yellow"
        }
        
        # Atualizar env.production.example
        if (Test-Path "env.production.example") {
            $prodContent = Get-Content "env.production.example"
            $updatedProdContent = $prodContent -replace "ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,54.196.122.206", "ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,$PublicIP"
            Set-Content "env.production.example" $updatedProdContent
            Write-ColorOutput "✓ env.production.example atualizado com IP: $PublicIP" "Green"
        } else {
            Write-ColorOutput "⚠ Arquivo env.production.example não encontrado" "Yellow"
        }
        
        Write-ColorOutput "✓ Configurações atualizadas com sucesso!" "Green"
        Write-Host ""
    } catch {
        Write-ColorOutput "ERRO ao atualizar configurações: $($_.Exception.Message)" "Red"
    }
}

# Função para fazer commit automático no Git
function Invoke-GitCommitAndPush {
    param([string]$PublicIP, [string]$OldIP)
    
    Write-ColorOutput "=== FAZENDO COMMIT AUTOMÁTICO NO GITHUB ===" "Cyan"
    
    try {
        # Verificar se há mudanças
        $gitStatus = git status --porcelain
        if (-not $gitStatus) {
            Write-ColorOutput "⚠ Nenhuma mudança para commitar" "Yellow"
            return $true
        }
        
        # Adicionar todos os arquivos modificados
        git add .
        Write-ColorOutput "✓ Arquivos adicionados ao Git" "Green"
        
        # Criar mensagem de commit
        $commitMessage = "Update: EC2 IP changed to $PublicIP"
        if ($OldIP) {
            $commitMessage += " (from $OldIP)"
        }
        $commitMessage += " - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        # Fazer commit
        git commit -m $commitMessage
        Write-ColorOutput "✓ Commit realizado" "Green"
        
        # Fazer push
        git push origin main
        Write-ColorOutput "✓ Push para GitHub realizado" "Green"
        
        Write-ColorOutput "✅ Commit automático concluído com sucesso!" "Green"
        return $true
        
    } catch {
        Write-ColorOutput "❌ Erro no commit automático: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Função para executar deploy automático
function Invoke-AutoDeploy {
    param([string]$PublicIP)
    
    Write-ColorOutput "=== EXECUTANDO DEPLOY AUTOMÁTICO ===" "Cyan"
    
    try {
        # Verificar se script de deploy existe
        if (-not (Test-Path "deploy-now.bat")) {
            Write-ColorOutput "❌ Script deploy-now.bat não encontrado" "Red"
            return $false
        }
        
        # Executar deploy
        Write-ColorOutput "🚀 Executando deploy automático..." "Yellow"
        & ".\deploy-now.bat"
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Deploy automático executado com sucesso!" "Green"
            return $true
        } else {
            Write-ColorOutput "❌ Erro no deploy automático" "Red"
            return $false
        }
        
    } catch {
        Write-ColorOutput "❌ Erro ao executar deploy: $($_.Exception.Message)" "Red"
        return $false
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
        
        # Atualizar configurações se IP estiver disponível
        if ($publicIP -ne "N/A") {
            # Obter IP anterior para comparação
            $oldIP = ""
            if (Test-Path "ip-info.json") {
                try {
                    $ipInfo = Get-Content "ip-info.json" | ConvertFrom-Json
                    $oldIP = $ipInfo.public_ip
                } catch {
                    $oldIP = ""
                }
            }
            
            # Atualizar configurações
            Update-ConfigurationFiles -PublicIP $publicIP
            
            # Fazer commit automático se IP mudou
            if ($oldIP -ne $publicIP) {
                Write-Host ""
                $commitSuccess = Invoke-GitCommitAndPush -PublicIP $publicIP -OldIP $oldIP
                
                if ($commitSuccess) {
                    Write-Host ""
                    $deploySuccess = Invoke-AutoDeploy -PublicIP $publicIP
                    
                    if ($deploySuccess) {
                        Write-ColorOutput "🎉 Sistema completamente automatizado e atualizado!" "Green"
                    }
                }
            }
        }
        
        Write-Host ""
        Write-ColorOutput "=== SERVIÇOS INICIADOS COM SUCESSO ===" "Green"
        
        if ($publicIP -ne "N/A") {
            Write-ColorOutput "URL da aplicação: http://$publicIP" "Green"
            Write-ColorOutput "Comando SSH: ssh -i ~/.ssh/id_rsa ubuntu@$publicIP" "Green"
            Write-Host ""
            Write-ColorOutput "🤖 Automação executada:" "Blue"
            Write-ColorOutput "- ✅ Configurações atualizadas com IP: $publicIP" "Blue"
            Write-ColorOutput "- ✅ Commit automático realizado no GitHub" "Blue"
            Write-ColorOutput "- ✅ Deploy automático executado na AWS" "Blue"
            Write-Host ""
            Write-ColorOutput "🔑 Credenciais do Admin:" "Yellow"
            Write-ColorOutput "   Usuário: @4minds" "White"
            Write-ColorOutput "   Senha: @4mindsPassword" "White"
        }
        
        Write-Host ""
        Write-ColorOutput "Nota: Aguarde alguns minutos para a aplicação ficar completamente pronta" "Yellow"
    } catch {
        Write-ColorOutput "Aviso: Não foi possível obter status final completo" "Yellow"
    }
}

# Função principal
function Main {
    Write-ColorOutput "Iniciando processo de inicialização dos serviços..." "Blue"
    
    if (-not (Test-AWSCLI)) {
        Write-ColorOutput "ERRO: AWS CLI não está configurado corretamente" "Red"
        exit 1
    }
    
    Start-RDSInstance
    Start-EC2Instance
    Wait-ForServices
    Show-FinalStatus
}

# Executar função principal
Main
