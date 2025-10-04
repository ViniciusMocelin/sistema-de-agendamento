# Script para configurar AWS CLI
# Execute este script no PowerShell

Write-Host "🔧 Configurando AWS CLI..." -ForegroundColor Green

# Verificar se AWS CLI está instalado
try {
    $awsVersion = aws --version 2>$null
    if ($awsVersion) {
        Write-Host "✅ AWS CLI já está instalado: $awsVersion" -ForegroundColor Green
    } else {
        throw "AWS CLI não encontrado"
    }
} catch {
    Write-Host "❌ AWS CLI não está instalado. Instalando..." -ForegroundColor Yellow
    
    # Baixar e instalar AWS CLI
    $installerPath = "$env:TEMP\AWSCLIV2.msi"
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $installerPath
    
    Write-Host "📦 Instalando AWS CLI..." -ForegroundColor Yellow
    Start-Process msiexec.exe -Wait -ArgumentList "/i $installerPath /quiet"
    
    # Limpar arquivo temporário
    Remove-Item $installerPath -Force
    
    Write-Host "✅ AWS CLI instalado com sucesso!" -ForegroundColor Green
}

# Configurar AWS CLI
Write-Host "`n🔐 Configure suas credenciais AWS:" -ForegroundColor Cyan
Write-Host "Você precisará de:" -ForegroundColor Yellow
Write-Host "- AWS Access Key ID" -ForegroundColor Yellow
Write-Host "- AWS Secret Access Key" -ForegroundColor Yellow
Write-Host "- Região (padrão: us-east-1)" -ForegroundColor Yellow
Write-Host "- Formato de saída (padrão: json)" -ForegroundColor Yellow

$configure = Read-Host "`nDeseja configurar agora? (s/n)"
if ($configure -eq "s" -or $configure -eq "S") {
    aws configure
    Write-Host "✅ AWS CLI configurado!" -ForegroundColor Green
} else {
    Write-Host "ℹ️ Execute 'aws configure' quando estiver pronto" -ForegroundColor Yellow
}

Write-Host "`n📋 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1. Configure as credenciais AWS: aws configure"
Write-Host "2. Teste a conexão: aws sts get-caller-identity"
Write-Host "3. Configure os secrets no GitHub (veja scripts/setup-github-secrets.md)"
Write-Host "4. Execute o script de geração de chaves SSH: .\scripts\generate-ssh-keys.ps1"
