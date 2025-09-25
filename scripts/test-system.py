#!/usr/bin/env python3
"""
Script para testar o sistema completo
Sistema de Agendamento - 4Minds

Uso:
    python scripts/test-system.py
"""

import os
import sys
import django
import requests
from pathlib import Path

# Adicionar o diretório raiz do projeto ao Python path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.contrib.auth import authenticate
from django.test import Client
from django.urls import reverse

User = get_user_model()

def test_user_authentication():
    """Testa autenticação do usuário"""
    
    print("🔐 Testando autenticação...")
    
    username = "@4minds"
    password = "@4mindsPassword"
    
    # Testar autenticação
    user = authenticate(username=username, password=password)
    
    if user:
        print(f"✅ Autenticação OK - Usuário: {user.username}")
        print(f"   É superuser: {user.is_superuser}")
        print(f"   É staff: {user.is_staff}")
        print(f"   Está ativo: {user.is_active}")
        return True
    else:
        print("❌ Falha na autenticação")
        return False

def test_admin_access():
    """Testa acesso ao admin"""
    
    print("🔧 Testando acesso ao admin...")
    
    try:
        # Criar cliente de teste
        client = Client()
        
        # Testar login no admin
        login_data = {
            'username': '@4minds',
            'password': '@4mindsPassword'
        }
        
        response = client.post('/admin/login/', login_data, follow=True)
        
        if response.status_code == 200:
            print("✅ Acesso ao admin OK")
            return True
        else:
            print(f"❌ Falha no acesso ao admin - Status: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao testar admin: {e}")
        return False

def test_urls():
    """Testa URLs principais"""
    
    print("🌐 Testando URLs principais...")
    
    try:
        client = Client()
        
        urls_to_test = [
            ('/', 'Home'),
            ('/admin/', 'Admin'),
            ('/dashboard/', 'Dashboard'),
        ]
        
        all_ok = True
        
        for url, name in urls_to_test:
            try:
                response = client.get(url)
                if response.status_code in [200, 302]:  # 302 é redirecionamento
                    print(f"✅ {name}: OK")
                else:
                    print(f"❌ {name}: Status {response.status_code}")
                    all_ok = False
            except Exception as e:
                print(f"❌ {name}: Erro - {e}")
                all_ok = False
        
        return all_ok
        
    except Exception as e:
        print(f"❌ Erro ao testar URLs: {e}")
        return False

def test_database():
    """Testa conexão com banco"""
    
    print("🗄️ Testando banco de dados...")
    
    try:
        from django.db import connection
        connection.ensure_connection()
        
        # Contar usuários
        user_count = User.objects.count()
        print(f"✅ Conexão com banco OK - {user_count} usuários")
        
        # Verificar se usuário @4minds existe
        if User.objects.filter(username='@4minds').exists():
            print("✅ Usuário @4minds encontrado")
            return True
        else:
            print("❌ Usuário @4minds não encontrado")
            return False
            
    except Exception as e:
        print(f"❌ Erro no banco: {e}")
        return False

def test_static_files():
    """Testa arquivos estáticos"""
    
    print("📁 Testando arquivos estáticos...")
    
    try:
        static_files = [
            'static/css/style.css',
            'static/css/bootstrap.min.css',
            'static/js/script.js',
        ]
        
        all_ok = True
        
        for file_path in static_files:
            full_path = BASE_DIR / file_path
            if full_path.exists():
                print(f"✅ {file_path}: OK")
            else:
                print(f"❌ {file_path}: Não encontrado")
                all_ok = False
        
        return all_ok
        
    except Exception as e:
        print(f"❌ Erro ao testar arquivos estáticos: {e}")
        return False

def show_results(results):
    """Mostra resultados dos testes"""
    
    print("\n" + "="*60)
    print("📊 RESULTADOS DOS TESTES")
    print("="*60)
    
    total_tests = len(results)
    passed_tests = sum(results.values())
    
    print(f"✅ Testes passou: {passed_tests}/{total_tests}")
    print()
    
    for test_name, result in results.items():
        status = "✅ PASSOU" if result else "❌ FALHOU"
        print(f"{status} {test_name}")
    
    print()
    
    if passed_tests == total_tests:
        print("🎉 TODOS OS TESTES PASSARAM!")
        print("🚀 Sistema está funcionando corretamente!")
    else:
        print("⚠️ ALGUNS TESTES FALHARAM!")
        print("🔧 Verifique os problemas acima")
    
    print("\n" + "="*60)
    print("🔑 CREDENCIAIS PARA ACESSO:")
    print("   Usuário: @4minds")
    print("   Senha: @4mindsPassword")
    print("   Admin: http://localhost:8000/admin/")
    print("   Dashboard: http://localhost:8000/dashboard/")
    print("="*60)

def main():
    """Função principal"""
    print("="*60)
    print("🚀 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("🧪 TESTE COMPLETO DO SISTEMA")
    print("="*60)
    print()
    
    # Executar testes
    results = {
        "Autenticação": test_user_authentication(),
        "Acesso ao Admin": test_admin_access(),
        "URLs Principais": test_urls(),
        "Banco de Dados": test_database(),
        "Arquivos Estáticos": test_static_files(),
    }
    
    # Mostrar resultados
    show_results(results)

if __name__ == "__main__":
    main()
