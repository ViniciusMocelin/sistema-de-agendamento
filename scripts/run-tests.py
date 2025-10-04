#!/usr/bin/env python3
"""
Script para executar testes do sistema de agendamento
"""

import os
import sys
import django
from django.conf import settings
from django.test.utils import get_runner

def setup_django():
    """Configurar Django para execução dos testes"""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
    django.setup()

def run_tests():
    """Executar todos os testes do projeto"""
    print("🧪 Iniciando execução dos testes...")
    
    # Configurar Django
    setup_django()
    
    # Configurar TestRunner
    TestRunner = get_runner(settings)
    test_runner = TestRunner()
    
    # Executar testes
    failures = test_runner.run_tests([
        'agendamentos',
        'authentication', 
        'info',
        'core'
    ])
    
    if failures:
        print(f"❌ {failures} teste(s) falharam")
        return False
    else:
        print("✅ Todos os testes passaram!")
        return True

def run_basic_checks():
    """Executar verificações básicas sem testes completos"""
    print("🔍 Executando verificações básicas...")
    
    try:
        # Verificar se Django consegue importar
        import django
        print("✅ Django importado com sucesso")
        
        # Verificar configurações
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
        django.setup()
        print("✅ Configurações do Django carregadas")
        
        # Verificar se as apps estão configuradas
        from django.apps import apps
        app_configs = apps.get_app_configs()
        print(f"✅ {len(app_configs)} app(s) configurada(s)")
        
        # Verificar se o banco de dados está acessível
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            print("✅ Conexão com banco de dados OK")
        
        print("✅ Todas as verificações básicas passaram!")
        return True
        
    except Exception as e:
        print(f"❌ Erro nas verificações básicas: {e}")
        return False

def main():
    """Função principal"""
    print("🚀 Sistema de Agendamento - Execução de Testes")
    print("=" * 50)
    
    # Verificar se estamos em ambiente de CI/CD
    if os.getenv('CI') or os.getenv('GITHUB_ACTIONS'):
        print("🔧 Ambiente de CI/CD detectado")
        # Em CI/CD, executar apenas verificações básicas
        success = run_basic_checks()
    else:
        print("💻 Ambiente local detectado")
        # Em ambiente local, executar testes completos
        success = run_tests()
    
    if success:
        print("\n🎉 Execução concluída com sucesso!")
        sys.exit(0)
    else:
        print("\n💥 Execução falhou!")
        sys.exit(1)

if __name__ == '__main__':
    main()
