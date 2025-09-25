#!/bin/bash

# Script rápido para corrigir usuário em produção
# Execute via SSH na EC2

echo "🔧 CORREÇÃO RÁPIDA DO USUÁRIO @4minds"
echo "======================================"

# Ir para diretório da aplicação
cd /home/django/sistema-agendamento

# Ativar ambiente virtual
source venv/bin/activate

# Executar comando Python inline
python << 'EOF'
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()
username = "@4minds"
password = "@4mindsPassword"
email = "admin@4minds.com"

print("🔍 Verificando usuário...")

# Verificar se usuário existe
if User.objects.filter(username=username).exists():
    user = User.objects.get(username=username)
    print(f"✅ Usuário '{username}' encontrado")
    
    # Verificar propriedades
    print(f"📧 Email: {user.email}")
    print(f"🔑 É superuser: {user.is_superuser}")
    print(f"👨‍💼 É staff: {user.is_staff}")
    print(f"✅ Está ativo: {user.is_active}")
    
    # Testar senha
    if user.check_password(password):
        print("✅ Senha está correta")
    else:
        print("❌ Senha incorreta - corrigindo...")
        user.set_password(password)
        user.save()
        print("✅ Senha corrigida")
    
    # Garantir permissões
    if not user.is_superuser or not user.is_staff or not user.is_active:
        print("🔧 Corrigindo permissões...")
        user.is_superuser = True
        user.is_staff = True
        user.is_active = True
        user.save()
        print("✅ Permissões corrigidas")
        
else:
    print(f"❌ Usuário '{username}' não encontrado - criando...")
    user = User.objects.create_superuser(
        username=username,
        email=email,
        password=password
    )
    print(f"✅ Usuário '{username}' criado com sucesso")

print("\n🎉 Usuário configurado corretamente!")
print(f"👤 Usuário: {username}")
print(f"🔑 Senha: {password}")
print(f"📧 Email: {email}")
print("🌐 Acesse: /admin/")
EOF

echo ""
echo "✅ Correção concluída!"
echo "🔧 Reinicie o serviço Django se necessário:"
echo "   sudo systemctl restart django"
