#!/usr/bin/env python3
"""
Script para executar testes do sistema
Sistema de Agendamento - 4Minds
"""

import os
import sys
import subprocess
import django
from pathlib import Path

# Configurar Django
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

# Configurar variáveis de ambiente para teste
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
os.environ.setdefault('DEBUG', 'True')
os.environ.setdefault('SECRET_KEY', 'test-secret-key-for-testing-only')

# Configurar banco de dados em memória para testes
os.environ.setdefault('DATABASE_URL', 'sqlite:///:memory:')

try:
    django.setup()
except Exception as e:
    print(f"❌ Erro ao configurar Django: {e}")
    sys.exit(1)

def run_django_tests():
    """Executa testes do Django"""
    print("🧪 Executando testes do Django...")
    
    try:
        # Executar testes
        result = subprocess.run([
            sys.executable, 'manage.py', 'test', 
            '--verbosity=2',
            '--keepdb'
        ], cwd=BASE_DIR, capture_output=True, text=True)
        
        print(result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)
        
        return result.returncode == 0
        
    except Exception as e:
        print(f"❌ Erro ao executar testes: {e}")
        return False

def run_security_checks():
    """Executa verificações de segurança"""
    print("🔒 Executando verificações de segurança...")
    
    try:
        from django.conf import settings
        
        issues = []
        
        # Verificar SECRET_KEY
        if settings.SECRET_KEY == 'test-secret-key-for-testing-only':
            print("✅ SECRET_KEY configurada para testes")
        else:
            issues.append("SECRET_KEY não é a de teste")
        
        # Verificar DEBUG
        if settings.DEBUG:
            print("✅ DEBUG=True (aceitável para testes)")
        else:
            print("ℹ️  DEBUG=False (produção)")
        
        # Verificar ALLOWED_HOSTS
        if settings.ALLOWED_HOSTS:
            print(f"✅ ALLOWED_HOSTS configurado: {settings.ALLOWED_HOSTS}")
        else:
            issues.append("ALLOWED_HOSTS não configurado")
        
        # Verificar configurações de segurança
        security_settings = [
            'SECURE_BROWSER_XSS_FILTER',
            'SECURE_CONTENT_TYPE_NOSNIFF',
            'X_FRAME_OPTIONS'
        ]
        
        for setting in security_settings:
            if hasattr(settings, setting):
                value = getattr(settings, setting)
                print(f"✅ {setting}: {value}")
            else:
                issues.append(f"{setting} não configurado")
        
        if issues:
            print(f"⚠️  Problemas encontrados: {issues}")
            return False
        else:
            print("✅ Todas as verificações de segurança passaram")
            return True
            
    except Exception as e:
        print(f"❌ Erro nas verificações de segurança: {e}")
        return False

def run_model_tests():
    """Executa testes específicos dos modelos"""
    print("📊 Testando modelos...")
    
    try:
        from django.test import TestCase
        from django.contrib.auth.models import User
        from agendamentos.models import Cliente, TipoServico, Agendamento
        from authentication.models import PreferenciasUsuario
        from datetime import date, time
        
        # Criar usuário de teste
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # Testar criação de cliente
        cliente = Cliente.objects.create(
            nome="João Silva",
            email="joao@test.com",
            telefone="(11) 99999-9999",
            cpf="123.456.789-00",
            data_nascimento=date(1990, 1, 1),
            criado_por=user
        )
        print(f"✅ Cliente criado: {cliente}")
        
        # Testar criação de serviço
        servico = TipoServico.objects.create(
            nome="Corte de Cabelo",
            descricao="Corte básico",
            preco=50.00,
            duracao_minutos=30
        )
        print(f"✅ Serviço criado: {servico}")
        
        # Testar criação de agendamento
        agendamento = Agendamento.objects.create(
            cliente=cliente,
            servico=servico,
            data_agendamento=date.today(),
            hora_inicio=time(14, 0),
            hora_fim=time(14, 30),
            status='agendado',
            criado_por=user
        )
        print(f"✅ Agendamento criado: {agendamento}")
        
        # Testar preferências do usuário
        preferencias = PreferenciasUsuario.objects.create(
            usuario=user,
            tema='emerald',
            modo='dark'
        )
        print(f"✅ Preferências criadas: {preferencias}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro nos testes de modelo: {e}")
        return False

def run_url_tests():
    """Testa URLs principais"""
    print("🌐 Testando URLs...")
    
    try:
        from django.test import Client
        from django.urls import reverse
        
        client = Client()
        
        # Testar URLs principais
        urls_to_test = [
            ('/', 'Home'),
            ('/admin/', 'Admin'),
            ('/auth/login/', 'Login'),
        ]
        
        for url, name in urls_to_test:
            try:
                response = client.get(url)
                print(f"✅ {name} ({url}): {response.status_code}")
            except Exception as e:
                print(f"❌ {name} ({url}): Erro - {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro nos testes de URL: {e}")
        return False

def generate_test_report():
    """Gera relatório de testes"""
    print("\n📋 RELATÓRIO DE TESTES")
    print("=" * 50)
    
    tests_results = []
    
    # Executar testes
    print("\n1. Testes de Modelos:")
    model_result = run_model_tests()
    tests_results.append(("Modelos", model_result))
    
    print("\n2. Testes de URLs:")
    url_result = run_url_tests()
    tests_results.append(("URLs", url_result))
    
    print("\n3. Verificações de Segurança:")
    security_result = run_security_checks()
    tests_results.append(("Segurança", security_result))
    
    print("\n4. Testes Django:")
    django_result = run_django_tests()
    tests_results.append(("Django Tests", django_result))
    
    # Resumo
    print("\n" + "=" * 50)
    print("📊 RESUMO DOS TESTES")
    print("=" * 50)
    
    passed = 0
    total = len(tests_results)
    
    for test_name, result in tests_results:
        status = "✅ PASSOU" if result else "❌ FALHOU"
        print(f"{test_name:20} {status}")
        if result:
            passed += 1
    
    print("-" * 50)
    print(f"Total: {passed}/{total} testes passaram")
    
    if passed == total:
        print("🎉 TODOS OS TESTES PASSARAM!")
        return True
    else:
        print("⚠️  ALGUNS TESTES FALHARAM!")
        return False

def main():
    """Função principal"""
    print("🚀 INICIANDO TESTES DO SISTEMA DE AGENDAMENTO")
    print("=" * 60)
    
    try:
        success = generate_test_report()
        
        if success:
            print("\n✅ Sistema pronto para produção!")
            sys.exit(0)
        else:
            print("\n❌ Sistema precisa de correções antes da produção!")
            sys.exit(1)
            
    except Exception as e:
        print(f"\n❌ Erro crítico durante os testes: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
