#!/usr/bin/env python3
"""
Testes básicos para o sistema de agendamento
"""

import os
import sys
import django
from django.conf import settings

# Adicionar o diretório raiz do projeto ao Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_django_setup():
    """Testar configuração básica do Django"""
    print("Testando configuracao do Django...")
    
    try:
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
        django.setup()
        print("Django configurado com sucesso")
        return True
    except Exception as e:
        print(f"Erro na configuracao do Django: {e}")
        return False

def test_imports():
    """Testar importações básicas"""
    print("Testando importacoes...")
    
    try:
        from django.contrib.auth.models import User
        from django.db import models
        print("Modelos do Django importados")
        
        # Testar importações específicas do projeto
        from core.settings import DEBUG
        print(f"Configuracoes carregadas (DEBUG: {DEBUG})")
        
        return True
    except Exception as e:
        print(f"Erro nas importacoes: {e}")
        return False

def test_database_connection():
    """Testar conexão com banco de dados"""
    print("Testando conexao com banco de dados...")
    
    try:
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            if result[0] == 1:
                print("Conexao com banco de dados OK")
                return True
            else:
                print("Resultado inesperado do banco de dados")
                return False
    except Exception as e:
        print(f"Erro na conexao com banco: {e}")
        return False

def test_urls():
    """Testar configuração de URLs"""
    print("Testando configuracao de URLs...")
    
    try:
        from django.urls import reverse
        from django.test import Client
        
        client = Client()
        
        # Testar URLs básicas
        try:
            response = client.get('/')
            print(f"Pagina principal responde (status: {response.status_code})")
        except Exception as e:
            print(f"Pagina principal com problema: {e}")
        
        return True
    except Exception as e:
        print(f"Erro na configuracao de URLs: {e}")
        return False

def main():
    """Executar todos os testes básicos"""
    print("Executando testes basicos do sistema...")
    print("=" * 50)
    
    tests = [
        test_django_setup,
        test_imports,
        test_database_connection,
        test_urls
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        print()
    
    print(f"Resultado: {passed}/{total} testes passaram")
    
    if passed == total:
        print("Todos os testes basicos passaram!")
        return True
    else:
        print("Alguns testes falharam!")
        return False

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
