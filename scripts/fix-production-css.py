#!/usr/bin/env python3
"""
Script para corrigir CSS em produção
Sistema de Agendamento - 4Minds

Uso:
    python scripts/fix-production-css.py
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
            if result.stdout.strip():
                print(f"   Output: {result.stdout.strip()}")
            return True
        else:
            print(f"❌ {description} - ERRO")
            if result.stderr.strip():
                print(f"   Erro: {result.stderr.strip()}")
            return False
    except Exception as e:
        print(f"❌ {description} - EXCEÇÃO: {e}")
        return False

def check_aws_cli():
    """Verifica se AWS CLI está configurado"""
    print("🔍 Verificando AWS CLI...")
    return run_command("aws sts get-caller-identity", "AWS CLI configurado")

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

def check_ec2_status():
    """Verifica status da EC2"""
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

def fix_css_on_ec2(ip):
    """Corrige CSS na EC2"""
    print(f"🎨 Corrigindo CSS na EC2 ({ip})...")
    
    # Comandos para corrigir CSS
    css_fix_commands = [
        "cd /home/django/sistema-agendamento",
        "source venv/bin/activate",
        "echo '🔧 Aplicando correções de CSS...'",
        "sudo chown -R django:django /home/django/sistema-agendamento/static/",
        "sudo chown -R django:django /home/django/sistema-agendamento/staticfiles/",
        "python manage.py collectstatic --noinput --settings=core.settings_production",
        "echo '✅ CSS coletado'",
        "if [ -f static/css/style-fixed.css ]; then cp static/css/style-fixed.css static/css/style.css; echo '✅ CSS corrigido aplicado'; fi",
        "sudo chown -R www-data:www-data /home/django/sistema-agendamento/staticfiles/ 2>/dev/null || sudo chown -R nginx:nginx /home/django/sistema-agendamento/staticfiles/ 2>/dev/null || true",
        "sudo chmod -R 755 /home/django/sistema-agendamento/staticfiles/",
        "echo '✅ Permissões corrigidas'",
        "sudo systemctl restart nginx",
        "echo '✅ Nginx reiniciado'",
        "echo '🎉 CSS corrigido!'"
    ]
    
    ssh_cmd = f"ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@{ip} \"{'; '.join(css_fix_commands)}\""
    
    if run_command(ssh_cmd, "Correção de CSS na EC2"):
        return True
    else:
        print("❌ Falha na correção de CSS")
        return False

def test_css_access(ip):
    """Testa acesso aos arquivos CSS"""
    print(f"🧪 Testando acesso aos arquivos CSS ({ip})...")
    
    css_files = [
        f"http://{ip}/static/css/style.css",
        f"http://{ip}/static/css/bootstrap.min.css",
        f"http://{ip}/static/js/script.js"
    ]
    
    all_ok = True
    
    for css_url in css_files:
        cmd = f"curl -I -s \"{css_url}\" | head -1"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        if "200 OK" in result.stdout:
            print(f"✅ {css_url} - OK")
        else:
            print(f"❌ {css_url} - ERRO")
            all_ok = False
    
    return all_ok

def create_inline_css_fix(ip):
    """Cria correção inline de CSS"""
    print(f"🔧 Criando correção inline de CSS ({ip})...")
    
    # CSS inline para correção rápida
    inline_css = """
    /* CSS INLINE PARA CORREÇÃO RÁPIDA */
    body { font-family: 'Inter', sans-serif; background-color: #ffffff; color: #1e293b; }
    .sidebar { background-color: #f8fafc; border-right: 1px solid #e2e8f0; }
    .card { background-color: #ffffff; border: 1px solid #e2e8f0; border-radius: 15px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
    .btn-primary { background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); border: none; color: white; border-radius: 8px; }
    .table { background-color: #ffffff; color: #1e293b; }
    .form-control { background-color: #ffffff; border: 1px solid #e2e8f0; color: #1e293b; }
    """
    
    # Comando para aplicar CSS inline
    css_commands = [
        "cd /home/django/sistema-agendamento",
        "echo '/* CSS CORRIGIDO - Sistema de Agendamento 4Minds */' > static/css/style.css",
        "echo 'body { font-family: \"Inter\", sans-serif; background-color: #ffffff; color: #1e293b; margin: 0; padding: 0; }' >> static/css/style.css",
        "echo '.sidebar { background-color: #f8fafc; border-right: 1px solid #e2e8f0; width: 280px; height: 100vh; position: fixed; left: 0; top: 0; }' >> static/css/style.css",
        "echo '.main-content { margin-left: 280px; padding: 30px; }' >> static/css/style.css",
        "echo '.card { background-color: #ffffff; border: 1px solid #e2e8f0; border-radius: 15px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); margin-bottom: 20px; }' >> static/css/style.css",
        "echo '.btn-primary { background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); border: none; color: white; border-radius: 8px; padding: 10px 20px; }' >> static/css/style.css",
        "echo '.table { background-color: #ffffff; color: #1e293b; width: 100%; }' >> static/css/style.css",
        "echo '.form-control { background-color: #ffffff; border: 1px solid #e2e8f0; color: #1e293b; border-radius: 8px; padding: 10px 15px; }' >> static/css/style.css",
        "echo '✅ CSS inline criado'",
        "sudo systemctl restart nginx",
        "echo '✅ Nginx reiniciado'"
    ]
    
    ssh_cmd = f"ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@{ip} \"{'; '.join(css_commands)}\""
    
    return run_command(ssh_cmd, "Criação de CSS inline")

def main():
    """Função principal"""
    print("=" * 60)
    print("🎨 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("🔧 CORREÇÃO DE CSS EM PRODUÇÃO")
    print("=" * 60)
    print()
    
    # Verificar pré-requisitos
    if not check_aws_cli():
        print("❌ AWS CLI não configurado. Execute: aws configure")
        return
    
    # Verificar EC2
    if not check_ec2_status():
        print("❌ EC2 não está rodando. Execute: scripts\\start-aws-services-simple.bat")
        return
    
    # Obter IP
    ip = get_ec2_ip()
    if not ip:
        print("❌ Não foi possível obter IP da EC2")
        return
    
    # Corrigir CSS
    print("\n🎨 CORRIGINDO CSS EM PRODUÇÃO...")
    
    if fix_css_on_ec2(ip):
        print("✅ Correção de CSS executada")
    else:
        print("⚠️ Correção padrão falhou, tentando CSS inline...")
        if create_inline_css_fix(ip):
            print("✅ CSS inline aplicado")
        else:
            print("❌ Falha na correção de CSS")
            return
    
    # Aguardar
    print("⏳ Aguardando aplicação inicializar...")
    time.sleep(10)
    
    # Testar
    if test_css_access(ip):
        print("\n" + "=" * 60)
        print("🎉 CSS CORRIGIDO COM SUCESSO!")
        print("=" * 60)
        print()
        print("🌐 URLs de Teste:")
        print(f"   Site: http://{ip}/")
        print(f"   Admin: http://{ip}/admin/")
        print(f"   CSS: http://{ip}/static/css/style.css")
        print()
        print("✅ Design deve estar funcionando agora!")
    else:
        print("\n⚠️ CSS corrigido, mas alguns arquivos podem não estar acessíveis.")
        print("Verifique manualmente: http://{}/".format(ip))

if __name__ == "__main__":
    main()
