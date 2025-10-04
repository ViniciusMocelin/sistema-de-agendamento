# Script de Deploy Manual para o Servidor
# Execute este script para fazer deploy manual

Write-Host "🚀 Iniciando Deploy Manual..." -ForegroundColor Green

# 1. Parar serviços
Write-Host "⏹️ Parando serviços..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo pkill -f gunicorn"

# 2. Fazer backup do arquivo atual
Write-Host "💾 Fazendo backup..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django cp /home/django/sistema-de-agendamento/core/settings_production.py /home/django/sistema-de-agendamento/core/settings_production.py.backup"

# 3. Atualizar arquivo settings_production.py
Write-Host "📝 Atualizando configurações..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django bash -c 'cd /home/django/sistema-de-agendamento && python3 -c \"
import os
content = open(\\\"core/settings_production.py\\\", \\\"r\\\").read()
# Substituir a linha problemática
new_content = content.replace(\\\"os.environ.get(\\\"ALLOWED_HOSTS\\\", \\\"\\\").split(\\\",\\\")\\\", \\\"\\\"*\\\"\\\")
open(\\\"core/settings_production.py\\\", \\\"w\\\").write(new_content)
print(\\\"Arquivo corrigido!\\\")
\"'"

# 4. Executar migrações
Write-Host "🗄️ Executando migrações..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django bash -c 'cd /home/django/sistema-de-agendamento && source venv/bin/activate && export DJANGO_SETTINGS_MODULE=core.settings_production && export DB_NAME=agendamentos_db && export DB_USER=postgres && export DB_PASSWORD=MinhaSenhaSegura123 && export DB_HOST=sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com && export DB_PORT=5432 && export ALLOWED_HOSTS=* && python manage.py migrate --settings=core.settings_production'"

# 5. Coletar arquivos estáticos
Write-Host "📦 Coletando arquivos estáticos..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django bash -c 'cd /home/django/sistema-de-agendamento && source venv/bin/activate && export DJANGO_SETTINGS_MODULE=core.settings_production && export DB_NAME=agendamentos_db && export DB_USER=postgres && export DB_PASSWORD=MinhaSenhaSegura123 && export DB_HOST=sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com && export DB_PORT=5432 && export ALLOWED_HOSTS=* && python manage.py collectstatic --noinput --settings=core.settings_production'"

# 6. Iniciar Gunicorn
Write-Host "🚀 Iniciando Gunicorn..." -ForegroundColor Yellow
ssh -i $env:USERPROFILE\.ssh\id_rsa_github -o StrictHostKeyChecking=no ubuntu@13.223.47.98 "sudo -u django bash -c 'cd /home/django/sistema-de-agendamento && source venv/bin/activate && export DJANGO_SETTINGS_MODULE=core.settings_production && export DB_NAME=agendamentos_db && export DB_USER=postgres && export DB_PASSWORD=MinhaSenhaSegura123 && export DB_HOST=sistema-agendamento-4minds-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com && export DB_PORT=5432 && export ALLOWED_HOSTS=* && gunicorn --bind 127.0.0.1:8000 core.wsgi:application --daemon'"

# 7. Testar aplicação
Write-Host "🧪 Testando aplicação..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
try {
    $response = Invoke-WebRequest -Uri http://13.223.47.98 -Method Get -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Deploy realizado com sucesso!" -ForegroundColor Green
        Write-Host "🌐 Aplicação disponível em: http://13.223.47.98" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ Aplicação retornou status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erro ao testar aplicação: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🏁 Deploy concluído!" -ForegroundColor Green
