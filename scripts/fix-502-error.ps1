# Script para diagnosticar e corrigir erro 502 Bad Gateway
# Execute este script no PowerShell

Write-Host "🔧 Diagnosticando erro 502 Bad Gateway..." -ForegroundColor Yellow

# Verificar se temos o IP da EC2
$EC2_IP = Read-Host "Digite o IP da instância EC2"

if (-not $EC2_IP) {
    Write-Host "❌ IP da EC2 é obrigatório" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔍 Diagnosticando instância EC2: $EC2_IP" -ForegroundColor Cyan

# Testar conectividade básica
Write-Host "`n1. Testando conectividade..." -ForegroundColor Cyan
try {
    $ping = Test-Connection -ComputerName $EC2_IP -Count 1 -Quiet
    if ($ping) {
        Write-Host "✅ Instância EC2 está acessível" -ForegroundColor Green
    } else {
        Write-Host "❌ Instância EC2 não está acessível" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Erro ao testar conectividade" -ForegroundColor Red
    exit 1
}

# Testar HTTP
Write-Host "`n2. Testando HTTP..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://$EC2_IP" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ HTTP está respondendo (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ HTTP não está respondendo: $($_.Exception.Message)" -ForegroundColor Red
}

# Testar health endpoint
Write-Host "`n3. Testando health endpoint..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-WebRequest -Uri "http://$EC2_IP/health/" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Health endpoint está respondendo" -ForegroundColor Green
} catch {
    Write-Host "❌ Health endpoint não está respondendo: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🔧 Executando correções na instância EC2..." -ForegroundColor Yellow

# Gerar script de correção para executar na EC2
$fixScript = @'
#!/bin/bash
set -e

echo "🔧 Iniciando correção do erro 502..."

# Verificar status dos serviços
echo "📊 Verificando status dos serviços..."
sudo systemctl status nginx --no-pager -l
sudo systemctl status django --no-pager -l

# Verificar se o Django está rodando na porta 8000
echo "🔍 Verificando se Django está rodando na porta 8000..."
if netstat -tlnp | grep :8000; then
    echo "✅ Django está rodando na porta 8000"
else
    echo "❌ Django não está rodando na porta 8000"
fi

# Verificar logs do Nginx
echo "📋 Verificando logs do Nginx..."
sudo tail -20 /var/log/nginx/django_error.log

# Verificar logs do Django
echo "📋 Verificando logs do Django..."
sudo journalctl -u django --no-pager -l -n 20

# Verificar se o arquivo de configuração do Nginx está correto
echo "🔍 Verificando configuração do Nginx..."
sudo nginx -t

# Verificar se o usuário django existe e tem permissões
echo "👤 Verificando usuário django..."
id django
ls -la /home/django/sistema-agendamento/

# Verificar se o ambiente virtual existe
echo "🐍 Verificando ambiente virtual..."
if [ -d "/home/django/sistema-agendamento/venv" ]; then
    echo "✅ Ambiente virtual existe"
    ls -la /home/django/sistema-agendamento/venv/bin/
else
    echo "❌ Ambiente virtual não existe"
fi

# Verificar se o arquivo .env existe
echo "📄 Verificando arquivo .env..."
if [ -f "/home/django/sistema-agendamento/.env" ]; then
    echo "✅ Arquivo .env existe"
    cat /home/django/sistema-agendamento/.env
else
    echo "❌ Arquivo .env não existe"
fi

# Tentar reiniciar os serviços
echo "🔄 Reiniciando serviços..."
sudo systemctl restart django
sleep 5
sudo systemctl restart nginx

# Verificar status após reinicialização
echo "📊 Status após reinicialização..."
sudo systemctl status django --no-pager -l
sudo systemctl status nginx --no-pager -l

# Verificar se Django está respondendo localmente
echo "🔍 Testando Django localmente..."
if curl -f -s http://localhost:8000/health/ > /dev/null; then
    echo "✅ Django está respondendo localmente"
else
    echo "❌ Django não está respondendo localmente"
fi

# Verificar configuração do Gunicorn
echo "🔍 Verificando configuração do Gunicorn..."
if [ -f "/home/django/sistema-agendamento/gunicorn.conf.py" ]; then
    echo "✅ Arquivo gunicorn.conf.py existe"
    cat /home/django/sistema-agendamento/gunicorn.conf.py
else
    echo "❌ Arquivo gunicorn.conf.py não existe"
fi

# Verificar se o banco de dados está acessível
echo "🗄️ Verificando banco de dados..."
cd /home/django/sistema-agendamento
source venv/bin/activate
python manage.py check --settings=core.settings_production

echo "✅ Diagnóstico concluído!"
'@

# Salvar script temporário
$fixScript | Out-File -FilePath "fix-502-temp.sh" -Encoding UTF8

Write-Host "`n📤 Enviando script de correção para a EC2..." -ForegroundColor Cyan

# Executar script na EC2 (assumindo que você tem SSH configurado)
Write-Host "`n⚠️  Para executar o script de correção, conecte-se à EC2 e execute:" -ForegroundColor Yellow
Write-Host "ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP" -ForegroundColor White
Write-Host "`nDepois execute o script de correção que foi salvo em: fix-502-temp.sh" -ForegroundColor White

Write-Host "`n📋 COMANDOS RÁPIDOS PARA EXECUTAR NA EC2:" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "sudo systemctl status django" -ForegroundColor White
Write-Host "sudo systemctl status nginx" -ForegroundColor White
Write-Host "sudo journalctl -u django -f" -ForegroundColor White
Write-Host "sudo tail -f /var/log/nginx/django_error.log" -ForegroundColor White
Write-Host "sudo systemctl restart django" -ForegroundColor White
Write-Host "sudo systemctl restart nginx" -ForegroundColor White
Write-Host "curl http://localhost:8000/health/" -ForegroundColor White
Write-Host "=" * 50 -ForegroundColor Cyan

Write-Host "`n🔧 SOLUÇÕES MAIS COMUNS:" -ForegroundColor Yellow
Write-Host "1. Django não está rodando: sudo systemctl restart django" -ForegroundColor White
Write-Host "2. Nginx não está configurado: sudo nginx -t" -ForegroundColor White
Write-Host "3. Porta 8000 não está aberta: netstat -tlnp | grep :8000" -ForegroundColor White
Write-Host "4. Permissões incorretas: sudo chown -R django:django /home/django/" -ForegroundColor White
Write-Host "5. Banco de dados inacessível: verificar .env" -ForegroundColor White

# Limpar arquivo temporário
Remove-Item "fix-502-temp.sh" -Force -ErrorAction SilentlyContinue

Write-Host "`n✅ Script de diagnóstico concluído!" -ForegroundColor Green
