#!/usr/bin/env python3
"""
Script para corrigir problemas de acesso ao admin e visual
Sistema de Agendamento - 4Minds

Uso:
    python scripts/fix-admin-and-visual.py
"""

import os
import sys
import django
import shutil
from pathlib import Path

# Adicionar o diretório raiz do projeto ao Python path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.conf import settings

User = get_user_model()

def fix_admin_user():
    """Corrige o usuário admin"""
    
    username = "@4minds"
    password = "@4mindsPassword"
    email = "admin@4minds.com"
    
    print("🔧 Corrigindo usuário admin...")
    
    try:
        # Verificar se usuário existe
        if User.objects.filter(username=username).exists():
            user = User.objects.get(username=username)
            print(f"✅ Usuário '{username}' encontrado")
            
            # Corrigir propriedades
            user.is_superuser = True
            user.is_staff = True
            user.is_active = True
            user.email = email
            user.set_password(password)
            user.save()
            
            print("✅ Propriedades do usuário corrigidas")
        else:
            # Criar usuário
            user = User.objects.create_superuser(
                username=username,
                email=email,
                password=password
            )
            print(f"✅ Usuário '{username}' criado")
            
    except Exception as e:
        print(f"❌ Erro ao corrigir usuário: {e}")

def fix_static_files():
    """Corrige arquivos estáticos"""
    
    print("🔧 Corrigindo arquivos estáticos...")
    
    try:
        # Executar collectstatic
        call_command('collectstatic', '--noinput', verbosity=0)
        print("✅ Arquivos estáticos coletados")
        
        # Copiar CSS corrigido
        css_fixed = BASE_DIR / "static" / "css" / "style-fixed.css"
        css_original = BASE_DIR / "static" / "css" / "style.css"
        
        if css_fixed.exists():
            shutil.copy2(css_fixed, css_original)
            print("✅ CSS corrigido aplicado")
        
    except Exception as e:
        print(f"❌ Erro ao corrigir arquivos estáticos: {e}")

def fix_urls():
    """Verifica e corrige URLs"""
    
    print("🔧 Verificando URLs...")
    
    # Verificar se admin está configurado
    from django.urls import reverse
    try:
        admin_url = reverse('admin:index')
        print(f"✅ Admin URL configurada: {admin_url}")
    except Exception as e:
        print(f"❌ Erro na URL do admin: {e}")

def create_admin_customization():
    """Cria personalização do admin"""
    
    print("🔧 Criando personalização do admin...")
    
    admin_custom = BASE_DIR / "agendamentos" / "admin.py"
    
    admin_content = '''from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth import get_user_model

User = get_user_model()

# Personalizar admin site
admin.site.site_header = "Sistema de Agendamentos - 4Minds"
admin.site.site_title = "Admin 4Minds"
admin.site.index_title = "Painel Administrativo"

# Personalizar User Admin
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'is_active', 'date_joined')
    list_filter = ('is_staff', 'is_active', 'is_superuser', 'date_joined')
    search_fields = ('username', 'email', 'first_name', 'last_name')
    ordering = ('-date_joined',)

# Re-registrar User model
admin.site.unregister(User)
admin.site.register(User, CustomUserAdmin)
'''
    
    try:
        with open(admin_custom, 'w', encoding='utf-8') as f:
            f.write(admin_content)
        print("✅ Personalização do admin criada")
    except Exception as e:
        print(f"❌ Erro ao criar personalização: {e}")

def test_admin_access():
    """Testa acesso ao admin"""
    
    print("🔧 Testando acesso ao admin...")
    
    try:
        from django.contrib.auth import authenticate
        user = authenticate(username='@4minds', password='@4mindsPassword')
        
        if user:
            print("✅ Autenticação funcionando")
            print(f"   Usuário: {user.username}")
            print(f"   É superuser: {user.is_superuser}")
            print(f"   É staff: {user.is_staff}")
            print(f"   Está ativo: {user.is_active}")
        else:
            print("❌ Autenticação falhou")
            
    except Exception as e:
        print(f"❌ Erro ao testar autenticação: {e}")

def show_access_info():
    """Mostra informações de acesso"""
    
    print("\n" + "="*60)
    print("🎉 CORREÇÕES CONCLUÍDAS!")
    print("="*60)
    print()
    print("🔑 CREDENCIAIS DO ADMIN:")
    print("   Usuário: @4minds")
    print("   Senha: @4mindsPassword")
    print("   Email: admin@4minds.com")
    print()
    print("🌐 URLS DE ACESSO:")
    print("   Admin Django: http://localhost:8000/admin/")
    print("   Dashboard: http://localhost:8000/dashboard/")
    print("   Home: http://localhost:8000/")
    print()
    print("🔧 COMANDOS ÚTEIS:")
    print("   Iniciar servidor: python manage.py runserver")
    print("   Criar superuser: python manage.py create_4minds_superuser")
    print("   Coletar estáticos: python manage.py collectstatic")
    print()
    print("📋 PRÓXIMOS PASSOS:")
    print("1. Execute: python manage.py runserver")
    print("2. Acesse: http://localhost:8000/admin/")
    print("3. Faça login com as credenciais acima")
    print("4. Configure o sistema conforme necessário")
    print()

def main():
    """Função principal"""
    print("="*60)
    print("🚀 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("🔧 CORREÇÃO DE ADMIN E VISUAL")
    print("="*60)
    print()
    
    # Executar correções
    fix_admin_user()
    fix_static_files()
    fix_urls()
    create_admin_customization()
    test_admin_access()
    show_access_info()

if __name__ == "__main__":
    main()
