#!/usr/bin/env python3
"""
Script para verificar usuário em produção
Sistema de Agendamento - 4Minds

Uso:
    python scripts/check-user-production.py
"""

import os
import sys
import django
from pathlib import Path

# Adicionar o diretório raiz do projeto ao Python path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

# Configurar Django para produção
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

def check_user():
    """Verifica se o usuário @4minds existe e suas propriedades"""
    
    username = "@4minds"
    
    print("🔍 Verificando usuário em produção...")
    print(f"👤 Buscando usuário: {username}")
    
    try:
        # Verificar se o usuário existe
        if User.objects.filter(username=username).exists():
            user = User.objects.get(username=username)
            
            print(f"✅ Usuário '{username}' encontrado!")
            print(f"📧 Email: {user.email}")
            print(f"🔑 É superuser: {user.is_superuser}")
            print(f"👨‍💼 É staff: {user.is_staff}")
            print(f"✅ Está ativo: {user.is_active}")
            print(f"📅 Data de criação: {user.date_joined}")
            print(f"📅 Último login: {user.last_login}")
            
            # Testar senha
            print(f"\n🔐 Testando senha...")
            test_password = "@4mindsPassword"
            if user.check_password(test_password):
                print("✅ Senha está correta!")
            else:
                print("❌ Senha está incorreta!")
                print("💡 Vamos redefinir a senha...")
                
                user.set_password(test_password)
                user.save()
                print("✅ Senha redefinida com sucesso!")
                
        else:
            print(f"❌ Usuário '{username}' não encontrado!")
            print("💡 Vamos criar o usuário...")
            
            # Criar o usuário
            user = User.objects.create_superuser(
                username=username,
                email="admin@4minds.com",
                password="@4mindsPassword"
            )
            
            print(f"✅ Usuário '{username}' criado com sucesso!")
            
    except Exception as e:
        print(f"❌ Erro ao verificar/criar usuário: {e}")
        sys.exit(1)

def list_all_users():
    """Lista todos os usuários do sistema"""
    
    print("\n👥 Listando todos os usuários do sistema:")
    print("-" * 50)
    
    users = User.objects.all()
    
    if users.exists():
        for user in users:
            print(f"👤 {user.username}")
            print(f"   📧 Email: {user.email}")
            print(f"   🔑 Superuser: {user.is_superuser}")
            print(f"   👨‍💼 Staff: {user.is_staff}")
            print(f"   ✅ Ativo: {user.is_active}")
            print(f"   📅 Criado: {user.date_joined}")
            print()
    else:
        print("❌ Nenhum usuário encontrado no sistema!")

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
    print("=" * 60)
    print("🚀 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("🔍 VERIFICAÇÃO DE USUÁRIO EM PRODUÇÃO")
    print("=" * 60)
    print()
    
    # Verificar conexão com banco
    if not verify_database_connection():
        print("❌ Não foi possível conectar ao banco de dados.")
        print("Verifique se:")
        print("  - As variáveis de ambiente estão configuradas")
        print("  - O banco PostgreSQL está rodando")
        print("  - As credenciais estão corretas")
        sys.exit(1)
    
    # Verificar usuário
    check_user()
    
    # Listar todos os usuários
    list_all_users()
    
    print()
    print("=" * 60)
    print("🎉 VERIFICAÇÃO CONCLUÍDA!")
    print("=" * 60)

if __name__ == "__main__":
    main()
