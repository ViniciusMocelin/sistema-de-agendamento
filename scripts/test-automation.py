#!/usr/bin/env python3
"""
Script de Teste para Automação Completa
Sistema de Agendamento - 4Minds

Este script testa todas as funcionalidades de automação implementadas:
1. Conectividade AWS
2. Acesso à EC2
3. Status dos serviços
4. Funcionalidade Git
5. Scripts Python
6. Workflows GitHub Actions

Uso:
    python scripts/test-automation.py
"""

import os
import sys
import subprocess
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

class AutomationTester:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.test_results = []
        self.ec2_instance_id = "i-04d14b81170c26323"
        self.region = "us-east-1"
        
    def log(self, message, color=Colors.WHITE):
        """Log com cores"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"{Colors.BLUE}[{timestamp}]{Colors.NC} {color}{message}{Colors.NC}")
        
    def test_result(self, test_name, success, message=""):
        """Registra resultado do teste"""
        result = {
            "test": test_name,
            "success": success,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }
        self.test_results.append(result)
        
        if success:
            self.log(f"✅ {test_name}: {message}", Colors.GREEN)
        else:
            self.log(f"❌ {test_name}: {message}", Colors.RED)
    
    def run_command(self, command, description=""):
        """Executa comando e retorna resultado"""
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True,
                cwd=self.project_root
            )
            return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
        except Exception as e:
            return False, "", str(e)
    
    def test_aws_cli(self):
        """Testa se AWS CLI está configurado"""
        self.log("🔍 Testando AWS CLI...", Colors.CYAN)
        
        # Verificar se AWS CLI está instalado
        success, stdout, stderr = self.run_command("aws --version")
        if not success:
            self.test_result("AWS CLI Installation", False, "AWS CLI não está instalado")
            return False
        
        # Verificar se está configurado
        success, stdout, stderr = self.run_command("aws sts get-caller-identity")
        if not success:
            self.test_result("AWS CLI Configuration", False, "AWS CLI não está configurado")
            return False
        
        self.test_result("AWS CLI Configuration", True, "AWS CLI configurado corretamente")
        return True
    
    def test_ec2_access(self):
        """Testa acesso à EC2"""
        self.log("🔍 Testando acesso à EC2...", Colors.CYAN)
        
        # Verificar se consegue descrever instâncias
        cmd = f"aws ec2 describe-instances --instance-ids {self.ec2_instance_id} --region {self.region}"
        success, stdout, stderr = self.run_command(cmd)
        
        if not success:
            self.test_result("EC2 Access", False, f"Erro ao acessar EC2: {stderr}")
            return False
        
        # Verificar se consegue obter IP
        cmd = f"aws ec2 describe-instances --instance-ids {self.ec2_instance_id} --region {self.region} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text"
        success, ip, stderr = self.run_command(cmd)
        
        if not success or not ip or ip == "None":
            self.test_result("EC2 IP Retrieval", False, "Não foi possível obter IP da EC2")
            return False
        
        self.test_result("EC2 Access", True, f"IP obtido: {ip}")
        return True
    
    def test_rds_access(self):
        """Testa acesso ao RDS"""
        self.log("🔍 Testando acesso ao RDS...", Colors.CYAN)
        
        cmd = "aws rds describe-db-instances --db-instance-identifier sistema-agendamento-postgres --region us-east-1"
        success, stdout, stderr = self.run_command(cmd)
        
        if not success:
            self.test_result("RDS Access", False, f"Erro ao acessar RDS: {stderr}")
            return False
        
        self.test_result("RDS Access", True, "Acesso ao RDS funcionando")
        return True
    
    def test_git_repository(self):
        """Testa repositório Git"""
        self.log("🔍 Testando repositório Git...", Colors.CYAN)
        
        # Verificar se é um repositório Git
        success, stdout, stderr = self.run_command("git status")
        if not success:
            self.test_result("Git Repository", False, "Não é um repositório Git válido")
            return False
        
        # Verificar se há remote configurado
        success, stdout, stderr = self.run_command("git remote -v")
        if not success or not stdout:
            self.test_result("Git Remote", False, "Nenhum remote configurado")
            return False
        
        self.test_result("Git Repository", True, "Repositório Git configurado")
        return True
    
    def test_python_scripts(self):
        """Testa scripts Python"""
        self.log("🔍 Testando scripts Python...", Colors.CYAN)
        
        # Verificar se script principal existe
        script_path = self.project_root / "scripts" / "auto-ip-update.py"
        if not script_path.exists():
            self.test_result("Python Scripts", False, "Script auto-ip-update.py não encontrado")
            return False
        
        # Verificar se consegue importar módulos necessários
        try:
            import boto3
            import requests
            self.test_result("Python Dependencies", True, "Dependências Python disponíveis")
        except ImportError as e:
            self.test_result("Python Dependencies", False, f"Dependências faltando: {e}")
            return False
        
        self.test_result("Python Scripts", True, "Scripts Python funcionando")
        return True
    
    def test_powershell_scripts(self):
        """Testa scripts PowerShell"""
        self.log("🔍 Testando scripts PowerShell...", Colors.CYAN)
        
        # Verificar se scripts existem
        scripts = [
            "scripts/start-aws-services-auto.ps1",
            "scripts/start-aws-services-fixed.ps1"
        ]
        
        for script in scripts:
            script_path = self.project_root / script
            if not script_path.exists():
                self.test_result("PowerShell Scripts", False, f"Script {script} não encontrado")
                return False
        
        self.test_result("PowerShell Scripts", True, "Scripts PowerShell disponíveis")
        return True
    
    def test_batch_scripts(self):
        """Testa scripts Batch"""
        self.log("🔍 Testando scripts Batch...", Colors.CYAN)
        
        # Verificar se scripts existem
        scripts = [
            "scripts/start-aws-services-auto.bat",
            "deploy-now.bat"
        ]
        
        for script in scripts:
            script_path = self.project_root / script
            if not script_path.exists():
                self.test_result("Batch Scripts", False, f"Script {script} não encontrado")
                return False
        
        self.test_result("Batch Scripts", True, "Scripts Batch disponíveis")
        return True
    
    def test_github_workflows(self):
        """Testa workflows GitHub Actions"""
        self.log("🔍 Testando workflows GitHub Actions...", Colors.CYAN)
        
        # Verificar se diretório .github existe
        github_dir = self.project_root / ".github" / "workflows"
        if not github_dir.exists():
            self.test_result("GitHub Workflows", False, "Diretório .github/workflows não encontrado")
            return False
        
        # Verificar se workflows existem
        workflows = [
            ".github/workflows/deploy.yml",
            ".github/workflows/update-ip.yml"
        ]
        
        for workflow in workflows:
            workflow_path = self.project_root / workflow
            if not workflow_path.exists():
                self.test_result("GitHub Workflows", False, f"Workflow {workflow} não encontrado")
                return False
        
        self.test_result("GitHub Workflows", True, "Workflows GitHub Actions configurados")
        return True
    
    def test_configuration_files(self):
        """Testa arquivos de configuração"""
        self.log("🔍 Testando arquivos de configuração...", Colors.CYAN)
        
        # Verificar se arquivos de exemplo existem
        config_files = [
            "env.example",
            ".env.example",
            "env.production.example",
            ".env.production.example"
        ]
        
        found_files = []
        for config_file in config_files:
            config_path = self.project_root / config_file
            if config_path.exists():
                found_files.append(config_file)
        
        if not found_files:
            self.test_result("Configuration Files", False, "Nenhum arquivo de configuração encontrado")
            return False
        
        self.test_result("Configuration Files", True, f"Arquivos encontrados: {', '.join(found_files)}")
        return True
    
    def test_ssh_key(self):
        """Testa chave SSH"""
        self.log("🔍 Testando chave SSH...", Colors.CYAN)
        
        # Verificar se chave SSH existe
        ssh_key_path = Path.home() / ".ssh" / "id_rsa"
        if not ssh_key_path.exists():
            self.test_result("SSH Key", False, "Chave SSH não encontrada em ~/.ssh/id_rsa")
            return False
        
        self.test_result("SSH Key", True, "Chave SSH encontrada")
        return True
    
    def generate_report(self):
        """Gera relatório de testes"""
        self.log("📊 Gerando relatório de testes...", Colors.CYAN)
        
        total_tests = len(self.test_results)
        passed_tests = len([r for r in self.test_results if r["success"]])
        failed_tests = total_tests - passed_tests
        
        # Criar relatório
        report = {
            "timestamp": datetime.now().isoformat(),
            "summary": {
                "total_tests": total_tests,
                "passed": passed_tests,
                "failed": failed_tests,
                "success_rate": (passed_tests / total_tests * 100) if total_tests > 0 else 0
            },
            "tests": self.test_results
        }
        
        # Salvar relatório
        report_file = self.project_root / "test-automation-report.json"
        report_file.write_text(json.dumps(report, indent=2))
        
        # Mostrar resumo
        print(f"\n{Colors.CYAN}{'='*60}")
        print("📊 RELATÓRIO DE TESTES DE AUTOMAÇÃO")
        print(f"{'='*60}{Colors.NC}")
        print(f"{Colors.BLUE}Total de testes:{Colors.NC} {total_tests}")
        print(f"{Colors.GREEN}Testes aprovados:{Colors.NC} {passed_tests}")
        print(f"{Colors.RED}Testes falharam:{Colors.NC} {failed_tests}")
        print(f"{Colors.PURPLE}Taxa de sucesso:{Colors.NC} {report['summary']['success_rate']:.1f}%")
        
        if failed_tests > 0:
            print(f"\n{Colors.RED}❌ Testes que falharam:{Colors.NC}")
            for result in self.test_results:
                if not result["success"]:
                    print(f"  - {result['test']}: {result['message']}")
        
        print(f"\n{Colors.BLUE}📄 Relatório salvo em: {report_file}{Colors.NC}")
        
        return failed_tests == 0
    
    def run_all_tests(self):
        """Executa todos os testes"""
        self.log("🚀 Iniciando testes de automação...", Colors.PURPLE)
        print(f"{Colors.PURPLE}{'='*60}")
        print("🧪 TESTES DE AUTOMAÇÃO COMPLETA")
        print(f"{'='*60}{Colors.NC}")
        print()
        
        # Executar testes
        tests = [
            self.test_aws_cli,
            self.test_ec2_access,
            self.test_rds_access,
            self.test_git_repository,
            self.test_python_scripts,
            self.test_powershell_scripts,
            self.test_batch_scripts,
            self.test_github_workflows,
            self.test_configuration_files,
            self.test_ssh_key
        ]
        
        for test in tests:
            try:
                test()
            except Exception as e:
                self.log(f"❌ Erro no teste: {e}", Colors.RED)
        
        # Gerar relatório
        success = self.generate_report()
        
        if success:
            print(f"\n{Colors.GREEN}🎉 Todos os testes passaram! Sistema pronto para automação.{Colors.NC}")
            print(f"\n{Colors.BLUE}Próximos passos:{Colors.NC}")
            print("1. Configure os secrets do GitHub (veja GITHUB_SECRETS_SETUP.md)")
            print("2. Execute: .\\scripts\\start-aws-services-auto.ps1")
            print("3. Faça push para o GitHub para testar workflows")
        else:
            print(f"\n{Colors.RED}❌ Alguns testes falharam. Verifique os problemas acima.{Colors.NC}")
            print(f"\n{Colors.BLUE}Para resolver:{Colors.NC}")
            print("1. Configure AWS CLI: aws configure")
            print("2. Configure Git: git config --global user.name 'Seu Nome'")
            print("3. Verifique se a chave SSH existe em ~/.ssh/id_rsa")
            print("4. Execute este teste novamente")
        
        return success

def main():
    """Função principal"""
    tester = AutomationTester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
