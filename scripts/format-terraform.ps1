# Script para formatar arquivos Terraform
# Execute este script no PowerShell

Write-Host "🔧 Formatando arquivos Terraform..." -ForegroundColor Green

# Verificar se Terraform está instalado
if (-not (Test-Path "C:\terraform\terraform.exe")) {
    Write-Host "❌ Terraform não encontrado em C:\terraform\" -ForegroundColor Red
    Write-Host "Instale o Terraform primeiro" -ForegroundColor Yellow
    exit 1
}

# Navegar para o diretório da infraestrutura
Set-Location aws-infrastructure

Write-Host "📁 Diretório atual: $(Get-Location)" -ForegroundColor Cyan

# Aplicar formatação
Write-Host "`n🔧 Aplicando formatação do Terraform..." -ForegroundColor Yellow
& C:\terraform\terraform.exe fmt -recursive .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Formatação aplicada com sucesso!" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao aplicar formatação" -ForegroundColor Red
    exit 1
}

# Verificar formatação
Write-Host "`n🔍 Verificando formatação..." -ForegroundColor Yellow
& C:\terraform\terraform.exe fmt -check -recursive .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Formatação está correta!" -ForegroundColor Green
} else {
    Write-Host "❌ Ainda há problemas de formatação" -ForegroundColor Red
    exit 1
}

# Validar arquivos
Write-Host "`n🔍 Validando arquivos Terraform..." -ForegroundColor Yellow
& C:\terraform\terraform.exe init
& C:\terraform\terraform.exe validate

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Arquivos Terraform válidos!" -ForegroundColor Green
} else {
    Write-Host "❌ Erro na validação do Terraform" -ForegroundColor Red
    exit 1
}

# Voltar ao diretório raiz
Set-Location ..

Write-Host "`n✅ Formatação do Terraform concluída!" -ForegroundColor Green
Write-Host "Agora você pode fazer commit das alterações:" -ForegroundColor Cyan
Write-Host "git add aws-infrastructure/" -ForegroundColor Gray
Write-Host "git commit -m 'Corrigir formatação do Terraform'" -ForegroundColor Gray
Write-Host "git push origin main" -ForegroundColor Gray
