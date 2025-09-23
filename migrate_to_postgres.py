#!/usr/bin/env python
"""
Script para migrar dados do SQLite para PostgreSQL
"""
import os
import sys
import django
from django.core.management import execute_from_command_line

def migrate_to_postgres():
    """Migra dados do SQLite para PostgreSQL"""
    print("🔄 Iniciando migração do SQLite para PostgreSQL...")
    
    # Configurar Django
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
    django.setup()
    
    # Fazer migrações
    print("🗄️ Aplicando migrações do PostgreSQL...")
    execute_from_command_line(['manage.py', 'migrate', '--noinput'])
    
    # Carregar dados do SQLite se existir
    if os.path.exists('db.sqlite3'):
        print("📥 Carregando dados do SQLite...")
        try:
            execute_from_command_line(['manage.py', 'loaddata', 'db.sqlite3'])
            print("✅ Dados carregados com sucesso!")
        except Exception as e:
            print(f"⚠️ Erro ao carregar dados: {e}")
            print("💡 Você pode importar os dados manualmente após o deploy")
    
    print("✅ Migração concluída!")

if __name__ == '__main__':
    migrate_to_postgres()
