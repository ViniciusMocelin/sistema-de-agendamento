#!/usr/bin/env python3
"""
Script para Atualização Automática de IP da EC2 e Commit no GitHub
Sistema de Agendamento - 4Minds

Este script:
1. Obtém o IP público da EC2
2. Atualiza arquivos de configuração
3. Faz commit automático no GitHub
4. Executa deploy automático (opcional)

Uso:
    python scripts/auto-ip-update.py [--deploy]
"""

import os
import sys
import subprocess
import re
import json
from datetime import datetime
from pathlib import Path

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'  # No Color

class AutoIPUpdater:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.ec2_instance_id = "i-04d14b81170c26323"
        self.region = "us-east-1"
        self.old_ip = None
        self.new_ip = None
        
    def log(self, message, color=Colors.WHITE):
        """Log com cores"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"{Colors.BLUE}[{timestamp}]{Colors.NC} {color}{message}{Colors.NC}")
        
    def run_command(self, command, description="", capture_output=True):
        """Executa comando e retorna resultado"""
        self.log(f"🔧 {description}", Colors.YELLOW)
        
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=capture_output, 
                text=True,
                cwd=self.project_root
            )
            
            if result.returncode == 0:
                self.log(f"✅ {description} - OK", Colors.GREEN)
                return True, result.stdout.strip() if capture_output else ""
            else:
                self.log(f"❌ {description} - ERRO", Colors.RED)
                if capture_output and result.stderr:
                    self.log(f"   Erro: {result.stderr}", Colors.RED)
                return False, result.stderr if capture_output else ""
                
        except Exception as e:
            self.log(f"❌ {description} - EXCEÇÃO: {e}", Colors.RED)
            return False, str(e)
    
    def check_aws_cli(self):
        """Verifica se AWS CLI está configurado"""
        self.log("🔍 Verificando AWS CLI...", Colors.CYAN)
        
        success, _ = self.run_command("aws sts get-caller-identity", "AWS CLI configurado")
        if not success:
            self.log("❌ AWS CLI não configurado. Execute: aws configure", Colors.RED)
            return False
            
        return True
    
    def check_git_status(self):
        """Verifica se estamos em um repositório Git"""
        self.log("🔍 Verificando repositório Git...", Colors.CYAN)
        
        success, _ = self.run_command("git status", "Repositório Git")
        if not success:
            self.log("❌ Não é um repositório Git válido", Colors.RED)
            return False
            
        return True
    
    def get_current_ip(self):
        """Obtém o IP público atual da EC2"""
        self.log("🔍 Obtendo IP atual da EC2...", Colors.CYAN)
        
        cmd = f"aws ec2 describe-instances --instance-ids {self.ec2_instance_id} --region {self.region} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text"
        
        success, output = self.run_command(cmd, "Consulta IP da EC2")
        if success and output and output != "None":
            self.new_ip = output
            self.log(f"🌐 IP atual da EC2: {self.new_ip}", Colors.GREEN)
            return True
        else:
            self.log("❌ Não foi possível obter IP da EC2", Colors.RED)
            return False
    
    def get_stored_ip(self):
        """Obtém o IP armazenado nos arquivos de configuração"""
        self.log("🔍 Verificando IP armazenado...", Colors.CYAN)
        
        # Procurar por IPs em arquivos de configuração
        config_files = [
            ".env.example",
            "env.example", 
            ".env.production.example",
            "env.production.example"
        ]
        
        for config_file in config_files:
            file_path = self.project_root / config_file
            if file_path.exists():
                content = file_path.read_text()
                # Procurar por padrão de IP
                ip_match = re.search(r'ALLOWED_HOSTS=.*?(\d+\.\d+\.\d+\.\d+)', content)
                if ip_match:
                    self.old_ip = ip_match.group(1)
                    self.log(f"📝 IP armazenado encontrado: {self.old_ip}", Colors.BLUE)
                    return True
        
        self.log("⚠️ Nenhum IP armazenado encontrado", Colors.YELLOW)
        return False
    
    def update_config_files(self):
        """Atualiza arquivos de configuração com o novo IP"""
        self.log("📝 Atualizando arquivos de configuração...", Colors.CYAN)
        
        if not self.new_ip:
            self.log("❌ Novo IP não disponível", Colors.RED)
            return False
        
        # Lista de arquivos para atualizar
        files_to_update = [
            ".env.example",
            "env.example",
            ".env.production.example", 
            "env.production.example",
            "aws-infrastructure/terraform.tfvars.example"
        ]
        
        updated_files = []
        
        for filename in files_to_update:
            file_path = self.project_root / filename
            if file_path.exists():
                content = file_path.read_text()
                
                # Padrões para substituir IP
                patterns = [
                    (r'ALLOWED_HOSTS=.*?(\d+\.\d+\.\d+\.\d+)', f'ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,{self.new_ip}'),
                    (r'ALLOWED_HOSTS=.*', f'ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,{self.new_ip}'),
                    (r'# IP da EC2:.*', f'# IP da EC2: {self.new_ip}'),
                    (r'# Application URL:.*', f'# Application URL: http://{self.new_ip}')
                ]
                
                original_content = content
                
                for pattern, replacement in patterns:
                    content = re.sub(pattern, replacement, content)
                
                # Se houve mudança, salvar arquivo
                if content != original_content:
                    file_path.write_text(content)
                    updated_files.append(filename)
                    self.log(f"✅ Atualizado: {filename}", Colors.GREEN)
        
        if updated_files:
            self.log(f"📝 {len(updated_files)} arquivos atualizados", Colors.GREEN)
            return True
        else:
            self.log("⚠️ Nenhum arquivo precisou ser atualizado", Colors.YELLOW)
            return True
    
    def create_ip_info_file(self):
        """Cria arquivo com informações do IP atual"""
        self.log("📄 Criando arquivo de informações do IP...", Colors.CYAN)
        
        ip_info = {
            "ec2_instance_id": self.ec2_instance_id,
            "region": self.region,
            "public_ip": self.new_ip,
            "old_ip": self.old_ip,
            "last_updated": datetime.now().isoformat(),
            "application_url": f"http://{self.new_ip}",
            "admin_url": f"http://{self.new_ip}/admin/",
            "ssh_command": f"ssh -i ~/.ssh/id_rsa ubuntu@{self.new_ip}"
        }
        
        ip_info_file = self.project_root / "ip-info.json"
        ip_info_file.write_text(json.dumps(ip_info, indent=2))
        
        self.log(f"✅ Arquivo ip-info.json criado", Colors.GREEN)
        return True
    
    def git_commit_and_push(self):
        """Faz commit e push das mudanças"""
        self.log("📤 Fazendo commit e push no GitHub...", Colors.CYAN)
        
        # Verificar se há mudanças
        success, status = self.run_command("git status --porcelain", "Verificar mudanças")
        if not success:
            return False
            
        if not status.strip():
            self.log("⚠️ Nenhuma mudança para commitar", Colors.YELLOW)
            return True
        
        # Adicionar todos os arquivos modificados
        success, _ = self.run_command("git add .", "Adicionar arquivos ao Git")
        if not success:
            return False
        
        # Criar mensagem de commit
        commit_message = f"Update: EC2 IP changed to {self.new_ip}"
        if self.old_ip:
            commit_message += f" (from {self.old_ip})"
        commit_message += f" - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        
        # Fazer commit
        success, _ = self.run_command(f'git commit -m "{commit_message}"', "Fazer commit")
        if not success:
            return False
        
        # Fazer push
        success, _ = self.run_command("git push origin main", "Push para GitHub")
        if not success:
            return False
        
        self.log("✅ Commit e push realizados com sucesso!", Colors.GREEN)
        return True
    
    def execute_deploy(self):
        """Executa deploy automático"""
        self.log("🚀 Executando deploy automático...", Colors.CYAN)
        
        # Verificar se script de deploy existe
        deploy_script = self.project_root / "deploy-now.bat"
        if not deploy_script.exists():
            self.log("❌ Script de deploy não encontrado", Colors.RED)
            return False
        
        # Executar deploy
        success, _ = self.run_command("deploy-now.bat", "Deploy automático", capture_output=False)
        if success:
            self.log("✅ Deploy executado com sucesso!", Colors.GREEN)
            return True
        else:
            self.log("❌ Erro no deploy", Colors.RED)
            return False
    
    def show_final_info(self):
        """Mostra informações finais"""
        self.log("🎉 Atualização automática concluída!", Colors.GREEN)
        print()
        print(f"{Colors.CYAN}=== INFORMAÇÕES DO SISTEMA ==={Colors.NC}")
        print(f"{Colors.BLUE}🌐 IP da EC2:{Colors.NC} {self.new_ip}")
        print(f"{Colors.BLUE}🔗 URL da aplicação:{Colors.NC} http://{self.new_ip}")
        print(f"{Colors.BLUE}🔑 Admin Django:{Colors.NC} http://{self.new_ip}/admin/")
        print(f"{Colors.BLUE}📊 Dashboard:{Colors.NC} http://{self.new_ip}/dashboard/")
        print()
        print(f"{Colors.BLUE}🔧 Comandos úteis:{Colors.NC}")
        print(f"{Colors.YELLOW}SSH:{Colors.NC} ssh -i ~/.ssh/id_rsa ubuntu@{self.new_ip}")
        print(f"{Colors.YELLOW}Logs:{Colors.NC} ssh -i ~/.ssh/id_rsa ubuntu@{self.new_ip} 'sudo journalctl -u django -f'")
        print()
        print(f"{Colors.BLUE}🔑 Credenciais do Admin:{Colors.NC}")
        print(f"{Colors.YELLOW}Usuário:{Colors.NC} @4minds")
        print(f"{Colors.YELLOW}Senha:{Colors.NC} @4mindsPassword")
        print()
        print(f"{Colors.GREEN}✅ Sistema atualizado e sincronizado com GitHub!{Colors.NC}")
    
    def run(self, auto_deploy=False):
        """Executa o processo completo"""
        self.log("🚀 Iniciando atualização automática de IP...", Colors.PURPLE)
        print()
        
        # Verificar pré-requisitos
        if not self.check_aws_cli():
            return False
            
        if not self.check_git_status():
            return False
        
        # Obter IPs
        if not self.get_current_ip():
            return False
            
        self.get_stored_ip()
        
        # Verificar se IP mudou
        if self.old_ip == self.new_ip:
            self.log("ℹ️ IP não mudou, nada para atualizar", Colors.BLUE)
            return True
        
        # Atualizar arquivos
        if not self.update_config_files():
            return False
            
        if not self.create_ip_info_file():
            return False
        
        # Commit e push
        if not self.git_commit_and_push():
            return False
        
        # Deploy automático (se solicitado)
        if auto_deploy:
            if not self.execute_deploy():
                return False
        
        # Mostrar informações finais
        self.show_final_info()
        
        return True

def main():
    """Função principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Atualização automática de IP da EC2")
    parser.add_argument("--deploy", action="store_true", help="Executar deploy automático após atualização")
    
    args = parser.parse_args()
    
    print(f"{Colors.PURPLE}{'='*60}")
    print("🤖 SISTEMA DE AGENDAMENTO - 4MINDS")
    print("⚡ ATUALIZAÇÃO AUTOMÁTICA DE IP")
    print(f"{'='*60}{Colors.NC}")
    print()
    
    updater = AutoIPUpdater()
    success = updater.run(auto_deploy=args.deploy)
    
    if success:
        print(f"\n{Colors.GREEN}🎉 Processo concluído com sucesso!{Colors.NC}")
        sys.exit(0)
    else:
        print(f"\n{Colors.RED}❌ Processo falhou!{Colors.NC}")
        sys.exit(1)

if __name__ == "__main__":
    main()
