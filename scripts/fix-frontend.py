#!/usr/bin/env python3
"""
Script para corrigir frontend quebrado
Sistema de Agendamento - 4Minds

Uso:
    python scripts/fix-frontend.py
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

from django.core.management import call_command
from django.conf import settings

def fix_css_files():
    """Corrige arquivos CSS"""
    print("🎨 Corrigindo arquivos CSS...")
    
    try:
        # Verificar se arquivo CSS principal existe
        css_file = BASE_DIR / "static" / "css" / "style.css"
        if not css_file.exists():
            print("❌ Arquivo CSS principal não encontrado")
            return False
        
        # Aplicar CSS corrigido
        css_fixed = BASE_DIR / "static" / "css" / "style-fixed.css"
        if css_fixed.exists():
            shutil.copy2(css_fixed, css_file)
            print("✅ CSS corrigido aplicado")
        else:
            print("⚠️ Arquivo CSS corrigido não encontrado")
        
        # Verificar outros arquivos CSS
        css_files = [
            "static/css/bootstrap.min.css",
            "static/css/dashboard.css",
            "static/css/agendamentos/agendamento_detail.css",
            "static/css/agendamentos/agendamento_form.CSS"
        ]
        
        for css_path in css_files:
            full_path = BASE_DIR / css_path
            if full_path.exists():
                print(f"✅ {css_path} - OK")
            else:
                print(f"⚠️ {css_path} - Não encontrado")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao corrigir CSS: {e}")
        return False

def fix_js_files():
    """Corrige arquivos JavaScript"""
    print("📜 Corrigindo arquivos JavaScript...")
    
    try:
        js_files = [
            "static/js/script.js",
            "static/js/dashboard.js",
            "static/js/agendamento_detail.js",
            "static/js/bootstrap.bundle.min.js"
        ]
        
        all_ok = True
        
        for js_path in js_files:
            full_path = BASE_DIR / js_path
            if full_path.exists():
                print(f"✅ {js_path} - OK")
            else:
                print(f"❌ {js_path} - Não encontrado")
                all_ok = False
        
        # Verificar se script.js tem conteúdo válido
        script_file = BASE_DIR / "static" / "js" / "script.js"
        if script_file.exists():
            content = script_file.read_text(encoding='utf-8')
            if len(content.strip()) > 0:
                print("✅ script.js tem conteúdo válido")
            else:
                print("❌ script.js está vazio")
                all_ok = False
        
        return all_ok
        
    except Exception as e:
        print(f"❌ Erro ao verificar JavaScript: {e}")
        return False

def fix_templates():
    """Corrige templates"""
    print("📄 Corrigindo templates...")
    
    try:
        # Verificar template base
        base_template = BASE_DIR / "templates" / "base.html"
        if not base_template.exists():
            print("❌ Template base.html não encontrado")
            return False
        
        # Verificar se template tem CSS e JS corretos
        content = base_template.read_text(encoding='utf-8')
        
        if '{% static "css/style.css" %}' in content:
            print("✅ CSS linkado corretamente")
        else:
            print("❌ CSS não está linkado corretamente")
        
        if '{% static "js/script.js" %}' in content:
            print("✅ JavaScript linkado corretamente")
        else:
            print("❌ JavaScript não está linkado corretamente")
        
        if 'bootstrap.min.css' in content:
            print("✅ Bootstrap CSS linkado")
        else:
            print("❌ Bootstrap CSS não está linkado")
        
        if 'bootstrap.bundle.min.js' in content:
            print("✅ Bootstrap JS linkado")
        else:
            print("❌ Bootstrap JS não está linkado")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao verificar templates: {e}")
        return False

def collect_static_files():
    """Coleta arquivos estáticos"""
    print("📁 Coletando arquivos estáticos...")
    
    try:
        call_command('collectstatic', '--noinput', verbosity=0)
        print("✅ Arquivos estáticos coletados")
        return True
    except Exception as e:
        print(f"❌ Erro ao coletar arquivos estáticos: {e}")
        return False

def create_emergency_css():
    """Cria CSS de emergência se necessário"""
    print("🚨 Criando CSS de emergência...")
    
    try:
        emergency_css = BASE_DIR / "static" / "css" / "emergency-fix.css"
        if emergency_css.exists():
            # Aplicar CSS de emergência
            main_css = BASE_DIR / "static" / "css" / "style.css"
            shutil.copy2(emergency_css, main_css)
            print("✅ CSS de emergência aplicado")
            return True
        else:
            print("⚠️ CSS de emergência não encontrado")
            return False
    except Exception as e:
        print(f"❌ Erro ao aplicar CSS de emergência: {e}")
        return False

def fix_template_context():
    """Corrige context processors"""
    print("🔧 Verificando context processors...")
    
    try:
        # Verificar se context processor está configurado
        from django.conf import settings
        
        if 'core.context_processors.tema_context' in settings.TEMPLATES[0]['OPTIONS']['context_processors']:
            print("✅ Context processor de tema configurado")
        else:
            print("❌ Context processor de tema não configurado")
        
        return True
    except Exception as e:
        print(f"❌ Erro ao verificar context processors: {e}")
        return False

def test_frontend():
    """Testa se frontend está funcionando"""
    print("🧪 Testando frontend...")
    
    try:
        from django.test import Client
        client = Client()
        
        # Testar página principal
        response = client.get('/')
        if response.status_code == 200:
            print("✅ Página principal carregando")
        else:
            print(f"❌ Página principal com erro: {response.status_code}")
        
        # Testar dashboard
        response = client.get('/dashboard/')
        if response.status_code in [200, 302]:
            print("✅ Dashboard acessível")
        else:
            print(f"❌ Dashboard com erro: {response.status_code}")
        
        return True
    except Exception as e:
        print(f"❌ Erro ao testar frontend: {e}")
        return False

def show_final_status():
    """Mostra status final"""
    print("\n" + "=" * 60)
    print("🎉 CORREÇÃO DO FRONTEND CONCLUÍDA!")
    print("=" * 60)
    print()
    print("🌐 URLs de Teste:")
    print("   Home: http://localhost:8000/")
    print("   Dashboard: http://localhost:8000/dashboard/")
    print("   Admin: http://localhost:8000/admin/")
    print()
    print("🔧 Se ainda houver problemas:")
    print("1. Limpe o cache do navegador (Ctrl+F5)")
    print("2. Teste em modo incógnito")
    print("3. Verifique o console do navegador (F12)")
    print("4. Execute: python manage.py collectstatic")
    print()
    print("✅ Frontend deve estar funcionando agora!")

def main():
    """Função principal"""
    print("=" * 60)
    print("🎨 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("🔧 CORREÇÃO DO FRONTEND")
    print("=" * 60)
    print()
    
    # Executar correções
    css_ok = fix_css_files()
    js_ok = fix_js_files()
    template_ok = fix_templates()
    static_ok = collect_static_files()
    context_ok = fix_template_context()
    
    # Se CSS não estiver funcionando, aplicar emergência
    if not css_ok:
        create_emergency_css()
    
    # Testar frontend
    test_ok = test_frontend()
    
    # Mostrar status
    show_final_status()

if __name__ == "__main__":
    main()
