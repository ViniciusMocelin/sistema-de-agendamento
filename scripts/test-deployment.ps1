# Script para testar o deployment
# Execute este script no PowerShell

Write-Host "🧪 Testando configuração de deployment..." -ForegroundColor Green

# Verificar AWS CLI
Write-Host "`n1. Verificando AWS CLI..." -ForegroundColor Cyan
try {
    $awsIdentity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    if ($awsIdentity) {
        Write-Host "✅ AWS CLI configurado corretamente" -ForegroundColor Green
        Write-Host "   Account: $($awsIdentity.Account)" -ForegroundColor Gray
        Write-Host "   User: $($awsIdentity.Arn)" -ForegroundColor Gray
    } else {
        throw "AWS CLI não configurado"
    }
} catch {
    Write-Host "❌ AWS CLI não configurado ou credenciais inválidas" -ForegroundColor Red
    Write-Host "   Execute: aws configure" -ForegroundColor Yellow
    exit 1
}

# Verificar Terraform
Write-Host "`n2. Verificando Terraform..." -ForegroundColor Cyan
try {
    $terraformVersion = terraform version 2>$null
    if ($terraformVersion) {
        Write-Host "✅ Terraform instalado" -ForegroundColor Green
        Write-Host "   Versão: $($terraformVersion[0])" -ForegroundColor Gray
    } else {
        throw "Terraform não encontrado"
    }
} catch {
    Write-Host "❌ Terraform não instalado" -ForegroundColor Red
    Write-Host "   Baixe em: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
    exit 1
}

# Verificar chaves SSH
Write-Host "`n3. Verificando chaves SSH..." -ForegroundColor Cyan
$sshPrivateKey = "$env:USERPROFILE\.ssh\id_rsa_github"
$sshPublicKey = "$env:USERPROFILE\.ssh\id_rsa_github.pub"

if (Test-Path $sshPrivateKey -and Test-Path $sshPublicKey) {
    Write-Host "✅ Chaves SSH encontradas" -ForegroundColor Green
    Write-Host "   Privada: $sshPrivateKey" -ForegroundColor Gray
    Write-Host "   Pública: $sshPublicKey" -ForegroundColor Gray
} else {
    Write-Host "❌ Chaves SSH não encontradas" -ForegroundColor Red
    Write-Host "   Execute: .\scripts\generate-ssh-keys.ps1" -ForegroundColor Yellow
    exit 1
}

# Verificar arquivos de configuração
Write-Host "`n4. Verificando arquivos de configuração..." -ForegroundColor Cyan
$requiredFiles = @(
    "aws-infrastructure\main.tf",
    "aws-infrastructure\variables.tf",
    "aws-infrastructure\terraform.tfvars.example",
    ".github\workflows\terraform-deploy.yml",
    ".github\workflows\deploy.yml",
    "requirements.txt"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host "❌ Alguns arquivos de configuração estão faltando" -ForegroundColor Red
    exit 1
}

# Verificar Python
Write-Host "`n5. Verificando Python..." -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>$null
    if ($pythonVersion) {
        Write-Host "✅ Python instalado: $pythonVersion" -ForegroundColor Green
    } else {
        throw "Python não encontrado"
    }
} catch {
    Write-Host "❌ Python não instalado" -ForegroundColor Red
    Write-Host "   Baixe em: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

# Verificar dependências Python
Write-Host "`n6. Verificando dependências Python..." -ForegroundColor Cyan
try {
    $pipList = pip list 2>$null
    if ($pipList -match "Django") {
        Write-Host "✅ Dependências Python instaladas" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Dependências Python podem não estar instaladas" -ForegroundColor Yellow
        Write-Host "   Execute: pip install -r requirements.txt" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erro ao verificar dependências Python" -ForegroundColor Red
}

# Verificar Git
Write-Host "`n7. Verificando Git..." -ForegroundColor Cyan
try {
    $gitVersion = git --version 2>$null
    if ($gitVersion) {
        Write-Host "✅ Git instalado: $gitVersion" -ForegroundColor Green
    } else {
        throw "Git não encontrado"
    }
} catch {
    Write-Host "❌ Git não instalado" -ForegroundColor Red
    Write-Host "   Baixe em: https://git-scm.com/downloads" -ForegroundColor Yellow
    exit 1
}

# Verificar repositório Git
Write-Host "`n8. Verificando repositório Git..." -ForegroundColor Cyan
try {
    $gitRemote = git remote get-url origin 2>$null
    if ($gitRemote) {
        Write-Host "✅ Repositório Git configurado" -ForegroundColor Green
        Write-Host "   Remote: $gitRemote" -ForegroundColor Gray
    } else {
        throw "Repositório Git não configurado"
    }
} catch {
    Write-Host "❌ Repositório Git não configurado" -ForegroundColor Red
    Write-Host "   Execute: git remote add origin [URL_DO_REPOSITORIO]" -ForegroundColor Yellow
    exit 1
}

# Resumo
Write-Host "`n🎉 TESTE CONCLUÍDO!" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

if ($allFilesExist) {
    Write-Host "✅ Tudo configurado corretamente!" -ForegroundColor Green
    Write-Host "`n📋 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
    Write-Host "1. Configure os secrets no GitHub (veja scripts/setup-github-secrets.md)" -ForegroundColor White
    Write-Host "2. Faça commit e push das alterações" -ForegroundColor White
    Write-Host "3. A pipeline será executada automaticamente" -ForegroundColor White
    Write-Host "4. Acompanhe o progresso em: Actions" -ForegroundColor White
} else {
    Write-Host "❌ Alguns problemas foram encontrados" -ForegroundColor Red
    Write-Host "   Corrija os problemas acima antes de prosseguir" -ForegroundColor Yellow
}
