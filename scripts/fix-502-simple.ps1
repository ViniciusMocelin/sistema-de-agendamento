# Script simples para corrigir erro 502 Bad Gateway
# Execute este script no PowerShell

Write-Host "🔧 Corrigindo erro 502 Bad Gateway..." -ForegroundColor Green

# Verificar se temos o IP da EC2
$EC2_IP = Read-Host "Digite o IP da instância EC2"

if (-not $EC2_IP) {
    Write-Host "❌ IP da EC2 é obrigatório" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔍 Testando conectividade com $EC2_IP..." -ForegroundColor Cyan

# Testar conectividade básica
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
Write-Host "`n🌐 Testando HTTP..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://$EC2_IP" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ HTTP está respondendo (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ HTTP não está respondendo: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n🔧 Executando correção automática..." -ForegroundColor Yellow
}

Write-Host "`n📋 COMANDOS PARA EXECUTAR NA EC2:" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow
Write-Host "1. Conecte-se à EC2:" -ForegroundColor White
Write-Host "   ssh -i ~/.ssh/id_rsa ubuntu@$EC2_IP" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Execute os comandos de correção:" -ForegroundColor White
Write-Host "   sudo systemctl restart django" -ForegroundColor Gray
Write-Host "   sudo systemctl restart nginx" -ForegroundColor Gray
Write-Host "   sudo chown -R django:django /home/django/sistema-agendamento/" -ForegroundColor Gray
Write-Host "   sudo mkdir -p /home/django/sistema-agendamento/logs" -ForegroundColor Gray
Write-Host "   sudo chown django:django /home/django/sistema-agendamento/logs" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Teste localmente:" -ForegroundColor White
Write-Host "   curl http://localhost:8000/health/" -ForegroundColor Gray
Write-Host "   curl http://localhost/" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Verifique os logs se necessário:" -ForegroundColor White
Write-Host "   sudo journalctl -u django -f" -ForegroundColor Gray
Write-Host "   sudo tail -f /var/log/nginx/django_error.log" -ForegroundColor Gray
Write-Host "=" * 60 -ForegroundColor Yellow

Write-Host "`n🚀 ALTERNATIVA: Use a pipeline de emergência do GitHub:" -ForegroundColor Cyan
Write-Host "1. Acesse: https://github.com/ViniciusMocelin/sistema-de-agendamento/actions" -ForegroundColor White
Write-Host "2. Clique em 'Fix 502 Error - Emergency Deploy'" -ForegroundColor White
Write-Host "3. Clique em 'Run workflow'" -ForegroundColor White
Write-Host "4. Digite o IP: $EC2_IP" -ForegroundColor White
Write-Host "5. Escolha a ação: 'fix'" -ForegroundColor White

Write-Host "`n✅ Script concluído!" -ForegroundColor Green