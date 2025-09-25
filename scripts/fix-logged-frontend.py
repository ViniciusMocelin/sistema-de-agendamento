#!/usr/bin/env python3
"""
Script para corrigir frontend após login
Sistema de Agendamento - 4Minds

Uso:
    python scripts/fix-logged-frontend.py
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

def fix_auth_css():
    """Corrige CSS de autenticação"""
    print("🔐 Corrigindo CSS de autenticação...")
    
    try:
        # Verificar se auth.css existe
        auth_css = BASE_DIR / "static" / "css" / "auth.css"
        if not auth_css.exists():
            print("❌ Arquivo auth.css não encontrado")
            return False
        
        print("✅ auth.css encontrado e funcionando")
        return True
        
    except Exception as e:
        print(f"❌ Erro ao verificar auth.css: {e}")
        return False

def fix_dashboard_css():
    """Corrige CSS do dashboard"""
    print("📊 Corrigindo CSS do dashboard...")
    
    try:
        # Verificar se dashboard.css existe
        dashboard_css = BASE_DIR / "static" / "css" / "dashboard.css"
        if not dashboard_css.exists():
            print("⚠️ dashboard.css não encontrado, criando...")
            create_dashboard_css()
        
        print("✅ dashboard.css funcionando")
        return True
        
    except Exception as e:
        print(f"❌ Erro ao verificar dashboard.css: {e}")
        return False

def create_dashboard_css():
    """Cria CSS do dashboard se não existir"""
    dashboard_css = BASE_DIR / "static" / "css" / "dashboard.css"
    
    css_content = """
/* DASHBOARD CSS - Sistema de Agendamento 4Minds */

/* Dashboard Header */
.dashboard-header {
    background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
    color: white;
    padding: 2rem;
    border-radius: 15px;
    margin-bottom: 2rem;
    box-shadow: 0 10px 30px rgba(59, 130, 246, 0.3);
    position: relative;
    overflow: hidden;
}

.dashboard-header::before {
    content: '';
    position: absolute;
    top: -50%;
    right: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
    animation: float 6s ease-in-out infinite;
}

.dashboard-title {
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: 0.5rem;
    position: relative;
    z-index: 1;
}

.dashboard-subtitle {
    font-size: 1.1rem;
    opacity: 0.9;
    margin: 0;
    position: relative;
    z-index: 1;
}

.header-actions {
    margin-top: 1.5rem;
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
    position: relative;
    z-index: 1;
}

/* Cards do Dashboard */
.dashboard-card {
    background: white;
    border-radius: 15px;
    padding: 1.5rem;
    box-shadow: 0 5px 20px rgba(0,0,0,0.1);
    border: 1px solid #e2e8f0;
    transition: all 0.3s ease;
    margin-bottom: 1.5rem;
}

.dashboard-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 30px rgba(0,0,0,0.15);
}

.card-icon {
    width: 60px;
    height: 60px;
    border-radius: 15px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.5rem;
    margin-bottom: 1rem;
}

.card-icon.primary {
    background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
    color: white;
}

.card-icon.success {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: white;
}

.card-icon.warning {
    background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
    color: white;
}

.card-icon.danger {
    background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
    color: white;
}

.card-title {
    font-size: 1.1rem;
    font-weight: 600;
    color: #1e293b;
    margin-bottom: 0.5rem;
}

.card-value {
    font-size: 2rem;
    font-weight: 700;
    color: #1e293b;
    margin-bottom: 0.5rem;
}

.card-description {
    color: #64748b;
    font-size: 0.9rem;
    margin: 0;
}

/* Botões customizados */
.btn-custom {
    background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 10px;
    font-weight: 600;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    transition: all 0.3s ease;
}

.btn-custom:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(59, 130, 246, 0.3);
    color: white;
    text-decoration: none;
}

/* Tabelas do Dashboard */
.dashboard-table {
    background: white;
    border-radius: 15px;
    overflow: hidden;
    box-shadow: 0 5px 20px rgba(0,0,0,0.1);
    border: 1px solid #e2e8f0;
}

.dashboard-table .table {
    margin: 0;
    color: #1e293b;
}

.dashboard-table .table th {
    background: #f8fafc;
    color: #1e293b;
    font-weight: 600;
    border: none;
    padding: 1rem;
}

.dashboard-table .table td {
    border: none;
    padding: 1rem;
    border-bottom: 1px solid #e2e8f0;
}

.dashboard-table .table tbody tr:hover {
    background: #f8fafc;
}

/* Status badges */
.status-badge {
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.status-badge.agendado {
    background: rgba(59, 130, 246, 0.1);
    color: #3b82f6;
}

.status-badge.confirmado {
    background: rgba(16, 185, 129, 0.1);
    color: #10b981;
}

.status-badge.cancelado {
    background: rgba(239, 68, 68, 0.1);
    color: #ef4444;
}

.status-badge.concluido {
    background: rgba(107, 114, 128, 0.1);
    color: #6b7280;
}

/* Animações */
@keyframes float {
    0%, 100% {
        transform: translateY(0px) rotate(0deg);
    }
    50% {
        transform: translateY(-20px) rotate(180deg);
    }
}

@keyframes fadeInUp {
    from {
        opacity: 0;
        transform: translateY(30px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.dashboard-card {
    animation: fadeInUp 0.6s ease-out;
}

/* Responsividade */
@media (max-width: 768px) {
    .dashboard-header {
        padding: 1.5rem;
        text-align: center;
    }
    
    .dashboard-title {
        font-size: 2rem;
    }
    
    .header-actions {
        justify-content: center;
    }
    
    .dashboard-card {
        padding: 1rem;
    }
    
    .card-value {
        font-size: 1.5rem;
    }
}

/* Garantir que elementos sejam visíveis */
.dashboard-header, .dashboard-header * {
    color: white !important;
}

.dashboard-card, .dashboard-card * {
    color: #1e293b !important;
}

.dashboard-table, .dashboard-table * {
    color: #1e293b !important;
}

.btn-custom, .btn-custom * {
    color: white !important;
}
"""
    
    dashboard_css.write_text(css_content, encoding='utf-8')
    print("✅ dashboard.css criado")

def fix_template_issues():
    """Corrige problemas de template"""
    print("📄 Corrigindo problemas de template...")
    
    try:
        # Verificar se base.html está correto
        base_template = BASE_DIR / "templates" / "base.html"
        if not base_template.exists():
            print("❌ Template base.html não encontrado")
            return False
        
        content = base_template.read_text(encoding='utf-8')
        
        # Verificar se CSS está linkado
        if '{% static "css/style.css" %}' in content:
            print("✅ CSS principal linkado")
        else:
            print("❌ CSS principal não está linkado")
        
        # Verificar se JS está linkado
        if '{% static "js/script.js" %}' in content:
            print("✅ JavaScript linkado")
        else:
            print("❌ JavaScript não está linkado")
        
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

def test_logged_frontend():
    """Testa frontend após login"""
    print("🧪 Testando frontend após login...")
    
    try:
        from django.test import Client
        from django.contrib.auth import get_user_model
        
        User = get_user_model()
        client = Client()
        
        # Criar usuário de teste se não existir
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
            print("❌ Falha no login de teste")
            return False
        
        # Testar dashboard
        response = client.get('/dashboard/')
        if response.status_code == 200:
            print("✅ Dashboard carregando após login")
        else:
            print(f"❌ Dashboard com erro: {response.status_code}")
        
        # Testar página principal
        response = client.get('/')
        if response.status_code == 200:
            print("✅ Página principal carregando após login")
        else:
            print(f"❌ Página principal com erro: {response.status_code}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao testar frontend: {e}")
        return False

def show_final_status():
    """Mostra status final"""
    print("\n" + "=" * 60)
    print("🎉 FRONTEND APÓS LOGIN CORRIGIDO!")
    print("=" * 60)
    print()
    print("🌐 URLs de Teste:")
    print("   Login: http://localhost:8000/auth/login/")
    print("   Dashboard: http://localhost:8000/dashboard/")
    print("   Home: http://localhost:8000/")
    print()
    print("🔧 Se ainda houver problemas:")
    print("1. Limpe o cache do navegador (Ctrl+F5)")
    print("2. Teste em modo incógnito")
    print("3. Verifique o console do navegador (F12)")
    print("4. Execute: python manage.py collectstatic")
    print()
    print("✅ Frontend após login deve estar funcionando agora!")

def main():
    """Função principal"""
    print("=" * 60)
    print("🎨 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("🔧 CORREÇÃO DO FRONTEND APÓS LOGIN")
    print("=" * 60)
    print()
    
    # Executar correções
    auth_ok = fix_auth_css()
    dashboard_ok = fix_dashboard_css()
    template_ok = fix_template_issues()
    static_ok = collect_static_files()
    
    # Testar frontend
    test_ok = test_logged_frontend()
    
    # Mostrar status
    show_final_status()

if __name__ == "__main__":
    main()
