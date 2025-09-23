#!/usr/bin/env python
"""
Script para preparar o sistema para deploy no Railway
"""
import os
import sys
import django
from django.core.management import execute_from_command_line

def setup_production():
    """Configura o sistema para produção"""
    print("🚀 Configurando sistema para produção...")
    
    # Configurar variáveis de ambiente
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
    
    # Configurar Django
    django.setup()
    
    # Coletar arquivos estáticos
    print("📦 Coletando arquivos estáticos...")
    execute_from_command_line(['manage.py', 'collectstatic', '--noinput'])
    
    # Fazer migrações
    print("🗄️ Aplicando migrações...")
    execute_from_command_line(['manage.py', 'migrate', '--noinput'])
    
    # Criar superusuário se não existir
    print("👤 Verificando superusuário...")
    from django.contrib.auth.models import User
    if not User.objects.filter(is_superuser=True).exists():
        print("⚠️ Nenhum superusuário encontrado. Crie um após o deploy.")
    
    print("✅ Sistema configurado para produção!")

if __name__ == '__main__':
    setup_production()
