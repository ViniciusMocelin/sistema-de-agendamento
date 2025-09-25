#!/usr/bin/env python3
"""
Teste simples do frontend
"""

import os
import sys
import django
from pathlib import Path

# Adicionar o diretório raiz do projeto ao Python path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model

def test_frontend():
    """Testa o frontend"""
    print("🧪 Testando frontend...")
    
    try:
        User = get_user_model()
        client = Client()
        
        # Criar usuário de teste
        user, created = User.objects.get_or_create(
            username='testuser',
            defaults={'email': 'test@example.com', 'is_staff': True}
        )
        if created:
            user.set_password('testpass123')
            user.save()
        
        # Fazer login
        login_success = client.login(username='testuser', password='testpass123')
        if not login_success:
            print("❌ Falha no login")
            return False
        
        # Testar páginas
        pages = [
            ('/', 'Página principal'),
            ('/dashboard/', 'Dashboard'),
            ('/auth/login/', 'Login'),
        ]
        
        for url, name in pages:
            response = client.get(url)
            if response.status_code == 200:
                print(f"✅ {name} - OK")
            else:
                print(f"❌ {name} - Erro {response.status_code}")
        
        print("✅ Frontend funcionando!")
        return True
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        return False

if __name__ == "__main__":
    test_frontend()
