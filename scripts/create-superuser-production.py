#!/usr/bin/env python3
"""
Script para criar superuser em produção
Sistema de Agendamento - 4Minds

Uso:
    python scripts/create-superuser-production.py
"""

import os
import sys
import django
from pathlib import Path

# Adicionar o diretório raiz do projeto ao Python path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
django.setup()

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.db import transaction

User = get_user_model()

def create_superuser():
    """Cria o superuser com as credenciais especificadas"""
    
    username = "@4minds"
    password = "@4mindsPassword"
    email = "admin@4minds.com"
    
    print("🔐 Criando superuser em produção...")
    print(f"👤 Usuário: {username}")
    print(f"📧 Email: {email}")
    
    try:
        # Verificar se o usuário já existe
        if User.objects.filter(username=username).exists():
            print(f"⚠️  Usuário '{username}' já existe!")
            
            # Perguntar se deve atualizar a senha
            update = input("Deseja atualizar a senha? (s/N): ").lower().strip()
            if update in ['s', 'sim', 'y', 'yes']:
                user = User.objects.get(username=username)
                user.set_password(password)
                user.is_superuser = True
                user.is_staff = True
                user.is_active = True
                user.email = email
                user.save()
                print(f"✅ Senha do usuário '{username}' atualizada com sucesso!")
            else:
                print("❌ Operação cancelada.")
            return
        
        # Criar o superuser
        with transaction.atomic():
            user = User.objects.create_superuser(
                username=username,
                email=email,
                password=password
            )
            
        print(f"✅ Superuser '{username}' criado com sucesso!")
        print(f"🔑 Senha: {password}")
        print(f"📧 Email: {email}")
        print("🚀 Você pode fazer login no admin em: /admin/")
        
    except Exception as e:
        print(f"❌ Erro ao criar superuser: {e}")
        sys.exit(1)

def verify_database_connection():
    """Verifica se a conexão com o banco está funcionando"""
    try:
        from django.db import connection
        connection.ensure_connection()
        print("✅ Conexão com banco de dados: OK")
        return True
    except Exception as e:
        print(f"❌ Erro na conexão com banco: {e}")
        return False

def main():
    """Função principal"""
    print("=" * 50)
    print("🚀 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("🔐 CRIAÇÃO DE SUPERUSER EM PRODUÇÃO")
    print("=" * 50)
    print()
    
    # Verificar conexão com banco
    if not verify_database_connection():
        print("❌ Não foi possível conectar ao banco de dados.")
        print("Verifique se:")
        print("  - As variáveis de ambiente estão configuradas")
        print("  - O banco PostgreSQL está rodando")
        print("  - As credenciais estão corretas")
        sys.exit(1)
    
    # Executar migrações se necessário
    print("🗄️  Verificando migrações...")
    try:
        call_command('migrate', verbosity=0)
        print("✅ Migrações atualizadas")
    except Exception as e:
        print(f"⚠️  Erro nas migrações: {e}")
        print("Continuando mesmo assim...")
    
    # Criar superuser
    create_superuser()
    
    print()
    print("=" * 50)
    print("🎉 PROCESSO CONCLUÍDO!")
    print("=" * 50)

if __name__ == "__main__":
    main()
