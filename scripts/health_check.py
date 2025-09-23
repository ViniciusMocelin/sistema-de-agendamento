#!/usr/bin/env python3
"""
Script de verificao de sade da aplicao
Sistema de Agendamento
"""

import requests
import sys
import time
import logging
from datetime import datetime

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('health_check.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

class HealthChecker:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        self.endpoints = [
            "/",
            "/admin/",
            "/health/",
            "/static/css/style.css"
        ]
        
    def check_endpoint(self, endpoint):
        """Verifica se um endpoint est respondendo"""
        try:
            url = f"{self.base_url}{endpoint}"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                logger.info(f" {endpoint} - OK ({response.status_code})")
                return True
            else:
                logger.warning(f"  {endpoint} - Status: {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            logger.error(f" {endpoint} - Erro: {e}")
            return False
    
    def check_database(self):
        """Verifica conectividade com o banco de dados"""
        try:
            # Importar Django settings
            import os
            import django
            from django.conf import settings
            
            os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
            django.setup()
            
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                
            if result:
                logger.info(" Banco de dados - OK")
                return True
            else:
                logger.error(" Banco de dados - Falha na consulta")
                return False
                
        except Exception as e:
            logger.error(f" Banco de dados - Erro: {e}")
            return False
    
    def check_disk_space(self):
        """Verifica espao em disco"""
        try:
            import shutil
            
            total, used, free = shutil.disk_usage("/")
            free_percent = (free / total) * 100
            
            if free_percent > 20:
                logger.info(f" Espao em disco - OK ({free_percent:.1f}% livre)")
                return True
            else:
                logger.warning(f"  Espao em disco - Baixo ({free_percent:.1f}% livre)")
                return False
                
        except Exception as e:
            logger.error(f" Espao em disco - Erro: {e}")
            return False
    
    def check_memory(self):
        """Verifica uso de memria"""
        try:
            with open('/proc/meminfo', 'r') as f:
                meminfo = f.read()
            
            for line in meminfo.split('\n'):
                if 'MemAvailable:' in line:
                    available = int(line.split()[1])
                elif 'MemTotal:' in line:
                    total = int(line.split()[1])
            
            used_percent = ((total - available) / total) * 100
            
            if used_percent < 90:
                logger.info(f" Memria - OK ({used_percent:.1f}% usada)")
                return True
            else:
                logger.warning(f"  Memria - Alta utilizao ({used_percent:.1f}% usada)")
                return False
                
        except Exception as e:
            logger.error(f" Memria - Erro: {e}")
            return False
    
    def run_health_check(self):
        """Executa verificao completa de sade"""
        logger.info(" Iniciando verificao de sade da aplicao...")
        
        results = {
            'endpoints': [],
            'database': False,
            'disk': False,
            'memory': False
        }
        
        # Verificar endpoints
        for endpoint in self.endpoints:
            result = self.check_endpoint(endpoint)
            results['endpoints'].append(result)
        
        # Verificar banco de dados
        results['database'] = self.check_database()
        
        # Verificar recursos do sistema
        results['disk'] = self.check_disk_space()
        results['memory'] = self.check_memory()
        
        # Calcular status geral
        endpoint_ok = sum(results['endpoints']) / len(results['endpoints']) > 0.5
        overall_ok = endpoint_ok and results['database'] and results['disk'] and results['memory']
        
        if overall_ok:
            logger.info(" Aplicao saudvel!")
            return 0
        else:
            logger.error(" Aplicao com problemas!")
            return 1

def main():
    """Funo principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Verificao de sade da aplicao')
    parser.add_argument('--url', default='http://localhost:8000', 
                       help='URL base da aplicao')
    parser.add_argument('--timeout', type=int, default=10,
                       help='Timeout para requisies (segundos)')
    parser.add_argument('--retry', type=int, default=3,
                       help='Nmero de tentativas')
    
    args = parser.parse_args()
    
    checker = HealthChecker(args.url)
    
    # Tentar mltiplas vezes se necessrio
    for attempt in range(args.retry):
        logger.info(f"Tentativa {attempt + 1}/{args.retry}")
        
        result = checker.run_health_check()
        
        if result == 0:
            sys.exit(0)
        elif attempt < args.retry - 1:
            logger.info(f"Aguardando 10 segundos antes da prxima tentativa...")
            time.sleep(10)
    
    logger.error("Falha em todas as tentativas")
    sys.exit(1)

if __name__ == "__main__":
    main()
