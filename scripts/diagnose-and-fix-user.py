#!/usr/bin/env python3
"""
Script para diagnosticar e corrigir usuário em produção
Execute este script diretamente na EC2

Uso na EC2:
    cd /home/django/sistema-agendamento
    source venv/bin/activate
    python scripts/diagnose-and-fix-user.py
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
from django.contrib.auth import authenticate

User = get_user_model()

def diagnose_and_fix():
    """Diagnostica e corrige o problema do usuário"""
    
    username = "@4minds"
    password = "@4mindsPassword"
    email = "admin@4minds.com"
    
    print("🔍 DIAGNÓSTICO DO USUÁRIO @4minds")
    print("=" * 50)
    
    # 1. Verificar se usuário existe
    print("1️⃣ Verificando se usuário existe...")
    user_exists = User.objects.filter(username=username).exists()
    print(f"   Usuário existe: {user_exists}")
    
    if not user_exists:
        print("❌ Usuário não encontrado! Criando...")
        try:
            user = User.objects.create_superuser(
                username=username,
                email=email,
                password=password
            )
            print(f"✅ Usuário '{username}' criado com sucesso!")
            return
        except Exception as e:
            print(f"❌ Erro ao criar usuário: {e}")
            return
    
    # 2. Obter usuário
    user = User.objects.get(username=username)
    print(f"   Usuário encontrado: {user.username}")
    
    # 3. Verificar propriedades
    print("\n2️⃣ Verificando propriedades do usuário...")
    print(f"   📧 Email: {user.email}")
    print(f"   🔑 É superuser: {user.is_superuser}")
    print(f"   👨‍💼 É staff: {user.is_staff}")
    print(f"   ✅ Está ativo: {user.is_active}")
    print(f"   📅 Data de criação: {user.date_joined}")
    print(f"   📅 Último login: {user.last_login}")
    
    # 4. Verificar senha
    print("\n3️⃣ Testando senha...")
    password_correct = user.check_password(password)
    print(f"   Senha está correta: {password_correct}")
    
    if not password_correct:
        print("   🔧 Corrigindo senha...")
        user.set_password(password)
        user.save()
        print("   ✅ Senha corrigida!")
        password_correct = True
    
    # 5. Garantir que é superuser e staff
    print("\n4️⃣ Verificando permissões...")
    needs_update = False
    
    if not user.is_superuser:
        print("   🔧 Definindo como superuser...")
        user.is_superuser = True
        needs_update = True
    
    if not user.is_staff:
        print("   🔧 Definindo como staff...")
        user.is_staff = True
        needs_update = True
    
    if not user.is_active:
        print("   🔧 Ativando usuário...")
        user.is_active = True
        needs_update = True
    
    if needs_update:
        user.save()
        print("   ✅ Permissões atualizadas!")
    
    # 6. Testar autenticação
    print("\n5️⃣ Testando autenticação...")
    authenticated_user = authenticate(username=username, password=password)
    
    if authenticated_user:
        print("   ✅ Autenticação funcionando!")
    else:
        print("   ❌ Autenticação falhou!")
        print("   🔧 Recriando usuário...")
        
        # Deletar usuário existente
        user.delete()
        
        # Criar novo usuário
        new_user = User.objects.create_superuser(
            username=username,
            email=email,
            password=password
        )
        print(f"   ✅ Usuário '{username}' recriado!")
    
    # 7. Listar todos os usuários
    print("\n6️⃣ Listando todos os usuários do sistema:")
    print("   " + "-" * 40)
    users = User.objects.all()
    for u in users:
        status = "✅" if u.is_active else "❌"
        superuser = "🔑" if u.is_superuser else "👤"
        staff = "👨‍💼" if u.is_staff else "👥"
        print(f"   {status} {superuser} {staff} {u.username} ({u.email})")
    
    print("\n" + "=" * 50)
    print("🎉 DIAGNÓSTICO CONCLUÍDO!")
    print("=" * 50)
    print(f"👤 Usuário: {username}")
    print(f"🔑 Senha: {password}")
    print(f"📧 Email: {email}")
    print("🌐 Acesse: /admin/")

if __name__ == "__main__":
    try:
        diagnose_and_fix()
    except Exception as e:
        print(f"❌ Erro durante diagnóstico: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
