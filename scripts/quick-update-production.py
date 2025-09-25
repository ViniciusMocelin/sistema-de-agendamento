#!/usr/bin/env python3
"""
Script rápido para atualizar produção
Sistema de Agendamento - 4Minds

Uso:
    python scripts/quick-update-production.py
"""

import os
import sys
import subprocess
import time
from pathlib import Path

def run_command(command, description=""):
    """Executa comando e mostra resultado"""
    print(f"🔧 {description}")
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {description} - OK")
            return True
        else:
            print(f"❌ {description} - ERRO")
            print(f"   {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ {description} - EXCEÇÃO: {e}")
        return False

def check_aws_cli():
    """Verifica se AWS CLI está configurado"""
    print("🔍 Verificando AWS CLI...")
    
    if not run_command("aws sts get-caller-identity", "AWS CLI configurado"):
        print("❌ AWS CLI não configurado. Execute: aws configure")
        return False
    
    return True

def get_ec2_status():
    """Obtém status da EC2"""
    print("🔍 Verificando status da EC2...")
    
    cmd = "aws ec2 describe-instances --instance-ids i-04d14b81170c26323 --region us-east-1 --query 'Reservations[0].Instances[0].State.Name' --output text"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        status = result.stdout.strip()
        print(f"📊 Status da EC2: {status}")
        return status == "running"
    else:
        print("❌ Erro ao verificar EC2")
        return False

def get_ec2_ip():
    """Obtém IP da EC2"""
    print("🔍 Obtendo IP da EC2...")
    
    cmd = "aws ec2 describe-instances --instance-ids i-04d14b81170c26323 --region us-east-1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        ip = result.stdout.strip()
        if ip != "None" and ip:
            print(f"🌐 IP da EC2: {ip}")
            return ip
        else:
            print("❌ IP não disponível")
            return None
    else:
        print("❌ Erro ao obter IP")
        return None

def deploy_to_ec2(ip):
    """Faz deploy na EC2"""
    print(f"🚀 Fazendo deploy na EC2 ({ip})...")
    
    # Comandos SSH para executar na EC2
    ssh_commands = [
        "cd /home/django/sistema-agendamento",
        "cp .env .env.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true",
        "source venv/bin/activate",
        "pip install -r requirements.txt",
        "python manage.py migrate --settings=core.settings_production",
        "python manage.py collectstatic --noinput --settings=core.settings_production",
        "python manage.py create_4minds_superuser --force --no-input --settings=core.settings_production",
        "if [ -f static/css/style-fixed.css ]; then cp static/css/style-fixed.css static/css/style.css; fi",
        "sudo systemctl restart django",
        "sudo systemctl restart nginx",
        "echo '🎉 Deploy concluído!'"
    ]
    
    # Executar comandos via SSH
    ssh_cmd = f"ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@{ip} \"{'; '.join(ssh_commands)}\""
    
    if run_command(ssh_cmd, "Deploy na EC2"):
        return True
    else:
        print("❌ Falha no deploy")
        return False

def test_production(ip):
    """Testa se produção está funcionando"""
    print(f"🧪 Testando produção ({ip})...")
    
    test_urls = [
        ("http://{}/", "Página principal"),
        ("http://{}/admin/", "Admin Django"),
        ("http://{}/static/css/style.css", "CSS")
    ]
    
    all_ok = True
    
    for url_template, description in test_urls:
        url = url_template.format(ip)
        cmd = f"curl -f -s \"{url}\" >nul 2>nul"
        
        if run_command(cmd, f"Teste: {description}"):
            print(f"✅ {description} funcionando")
        else:
            print(f"⚠️ {description} pode ter problemas")
            all_ok = False
    
    return all_ok

def main():
    """Função principal"""
    print("=" * 60)
    print("🚀 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("⚡ ATUALIZAÇÃO RÁPIDA DE PRODUÇÃO")
    print("=" * 60)
    print()
    
    # Verificar pré-requisitos
    if not check_aws_cli():
        return
    
    # Verificar EC2
    if not get_ec2_status():
        print("❌ EC2 não está rodando. Execute: scripts\\start-aws-services-simple.bat")
        return
    
    # Obter IP
    ip = get_ec2_ip()
    if not ip:
        return
    
    # Fazer deploy
    if not deploy_to_ec2(ip):
        return
    
    # Aguardar inicialização
    print("⏳ Aguardando aplicação inicializar...")
    time.sleep(30)
    
    # Testar
    if test_production(ip):
        print("\n" + "=" * 60)
        print("🎉 ATUALIZAÇÃO CONCLUÍDA COM SUCESSO!")
        print("=" * 60)
        print()
        print("🔑 CREDENCIAIS DO ADMIN:")
        print("   Usuário: @4minds")
        print("   Senha: @4mindsPassword")
        print()
        print("🌐 URLs DE ACESSO:")
        print(f"   Admin: http://{ip}/admin/")
        print(f"   Dashboard: http://{ip}/dashboard/")
        print(f"   Home: http://{ip}/")
        print()
        print("✅ Sistema atualizado e funcionando!")
    else:
        print("\n⚠️ Atualização concluída, mas alguns testes falharam.")
        print("Verifique manualmente: http://{}/admin/".format(ip))

if __name__ == "__main__":
    main()
