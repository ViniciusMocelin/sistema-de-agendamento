# Script para gerar chaves SSH para deploy no GitHub Actions
# Execute este script no PowerShell

Write-Host "🔑 Gerando chaves SSH para deploy..." -ForegroundColor Green

# Criar diretório .ssh se não existir
$sshDir = "$env:USERPROFILE\.ssh"
if (!(Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force
    Write-Host "✅ Diretório .ssh criado" -ForegroundColor Green
}

# Gerar chave SSH
$keyPath = "$sshDir\id_rsa_github"
Write-Host "🔐 Gerando chave SSH em: $keyPath" -ForegroundColor Yellow

# Usar ssh-keygen do Windows
& ssh-keygen -t rsa -b 4096 -f $keyPath -N '""' -C "github-actions-deploy"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Chave SSH gerada com sucesso!" -ForegroundColor Green
    
    # Mostrar chave pública
    Write-Host "`n📋 CHAVE PÚBLICA (adicione à EC2):" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Get-Content "$keyPath.pub"
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    # Mostrar chave privada
    Write-Host "`n🔒 CHAVE PRIVADA (adicione ao GitHub Secret 'EC2_SSH_PRIVATE_KEY'):" -ForegroundColor Red
    Write-Host "=" * 50 -ForegroundColor Red
    Get-Content $keyPath
    Write-Host "=" * 50 -ForegroundColor Red
    
    Write-Host "`n📝 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
    Write-Host "1. Copie a CHAVE PRIVADA acima e adicione como secret 'EC2_SSH_PRIVATE_KEY' no GitHub"
    Write-Host "2. Após o primeiro deploy, adicione a CHAVE PÚBLICA à instância EC2:"
    Write-Host "   ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_EC2]"
    Write-Host "   echo 'chave_publica_aqui' >> ~/.ssh/authorized_keys"
    Write-Host "3. Faça commit e push para triggerar o deploy"
    
} else {
    Write-Host "❌ Erro ao gerar chave SSH" -ForegroundColor Red
    Write-Host "Tente executar manualmente:" -ForegroundColor Yellow
    Write-Host "ssh-keygen -t rsa -b 4096 -f $keyPath -N ''" -ForegroundColor Yellow
}
