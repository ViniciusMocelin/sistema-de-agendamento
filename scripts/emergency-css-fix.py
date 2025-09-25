#!/usr/bin/env python3
"""
Script de emergência para corrigir CSS em produção
Sistema de Agendamento - 4Minds

Uso:
    python scripts/emergency-css-fix.py
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
            if result.stderr.strip():
                print(f"   Erro: {result.stderr.strip()}")
            return False
    except Exception as e:
        print(f"❌ {description} - EXCEÇÃO: {e}")
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

def apply_emergency_fix(ip):
    """Aplica correção de emergência"""
    print(f"🚨 Aplicando correção de emergência na EC2 ({ip})...")
    
    # Comandos para aplicar correção de emergência
    emergency_commands = [
        "cd /home/django/sistema-agendamento",
        "source venv/bin/activate",
        "echo '🚨 Aplicando correção de emergência de CSS...'",
        # Backup do template atual
        "cp templates/base.html templates/base.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true",
        # Aplicar template de emergência
        "cp templates/emergency_base.html templates/base.html",
        "echo '✅ Template de emergência aplicado'",
        # Corrigir permissões
        "sudo chown -R django:django /home/django/sistema-agendamento/",
        "sudo chmod -R 755 /home/django/sistema-agendamento/",
        # Reiniciar serviços
        "sudo systemctl restart django",
        "sudo systemctl restart nginx",
        "echo '✅ Serviços reiniciados'",
        "echo '🎉 Correção de emergência aplicada!'"
    ]
    
    ssh_cmd = f"ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@{ip} \"{'; '.join(emergency_commands)}\""
    
    return run_command(ssh_cmd, "Aplicação de correção de emergência")

def test_emergency_fix(ip):
    """Testa se a correção funcionou"""
    print(f"🧪 Testando correção de emergência ({ip})...")
    
    # Testar página principal
    cmd = f"curl -f -s \"http://{ip}/\" >nul 2>nul"
    if run_command(cmd, "Teste: Página principal"):
        print("✅ Página principal funcionando")
        return True
    else:
        print("⚠️ Página principal pode ter problemas")
        return False

def main():
    """Função principal"""
    print("=" * 60)
    print("🚨 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("🔧 CORREÇÃO DE EMERGÊNCIA - CSS")
    print("=" * 60)
    print()
    
    # Obter IP
    ip = get_ec2_ip()
    if not ip:
        print("❌ Não foi possível obter IP da EC2")
        return
    
    # Aplicar correção de emergência
    print("\n🚨 APLICANDO CORREÇÃO DE EMERGÊNCIA...")
    
    if apply_emergency_fix(ip):
        print("✅ Correção de emergência aplicada")
    else:
        print("❌ Falha na aplicação da correção")
        return
    
    # Aguardar
    print("⏳ Aguardando aplicação inicializar...")
    time.sleep(15)
    
    # Testar
    if test_emergency_fix(ip):
        print("\n" + "=" * 60)
        print("🎉 CORREÇÃO DE EMERGÊNCIA APLICADA!")
        print("=" * 60)
        print()
        print("🌐 URLs de Teste:")
        print(f"   Site: http://{ip}/")
        print(f"   Admin: http://{ip}/admin/")
        print()
        print("✅ Design deve estar funcionando agora!")
        print("🎨 CSS inline aplicado diretamente no template")
        print()
        print("📋 Próximos passos:")
        print("1. Teste o site no navegador")
        print("2. Limpe o cache do navegador (Ctrl+F5)")
        print("3. Se funcionar, podemos fazer a correção permanente")
    else:
        print("\n⚠️ Correção aplicada, mas pode precisar de verificação manual.")
        print("Verifique: http://{}/".format(ip))

if __name__ == "__main__":
    main()
