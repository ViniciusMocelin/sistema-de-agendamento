#!/usr/bin/env python3
"""
Script para gerar uma nova SECRET_KEY segura para Django
Sistema de Agendamento - 4Minds
"""

import secrets
import string
import sys
import os

def generate_secret_key():
    """Gera uma nova SECRET_KEY segura"""
    # Caracteres permitidos para SECRET_KEY
    chars = string.ascii_letters + string.digits + "!@#$%^&*(-_=+)"
    
    # Gerar chave de 50 caracteres
    secret_key = ''.join(secrets.choice(chars) for _ in range(50))
    
    return secret_key

def update_env_file(secret_key, env_file='env.production.example'):
    """Atualiza arquivo de ambiente com nova SECRET_KEY"""
    try:
        if os.path.exists(env_file):
            # Ler arquivo
            with open(env_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Substituir SECRET_KEY
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('SECRET_KEY='):
                    lines[i] = f'SECRET_KEY={secret_key}'
                    break
            
            # Escrever arquivo atualizado
            with open(env_file, 'w', encoding='utf-8') as f:
                f.write('\n'.join(lines))
            
            print(f"✅ SECRET_KEY atualizada em {env_file}")
        else:
            print(f"⚠️  Arquivo {env_file} não encontrado")
            
    except Exception as e:
        print(f"❌ Erro ao atualizar arquivo: {e}")

def main():
    """Função principal"""
    print("🔐 Gerando nova SECRET_KEY segura...")
    
    # Gerar nova chave
    secret_key = generate_secret_key()
    
    print(f"\n📋 Nova SECRET_KEY gerada:")
    print(f"SECRET_KEY={secret_key}")
    
    # Perguntar se quer atualizar arquivo
    try:
        response = input("\n❓ Deseja atualizar o arquivo env.production.example? (s/n): ").lower()
        if response in ['s', 'sim', 'y', 'yes']:
            update_env_file(secret_key)
        else:
            print("ℹ️  Arquivo não foi atualizado. Copie a chave manualmente.")
    except KeyboardInterrupt:
        print("\n\n❌ Operação cancelada pelo usuário")
        sys.exit(1)
    
    print("\n🔒 Instruções de segurança:")
    print("1. Copie a SECRET_KEY acima")
    print("2. Configure como variável de ambiente:")
    print(f"   export SECRET_KEY='{secret_key}'")
    print("3. Ou adicione ao arquivo .env.production")
    print("4. NUNCA commite a SECRET_KEY no Git")
    
    print("\n✅ Processo concluído!")

if __name__ == "__main__":
    main()
