#!/usr/bin/env python3
"""
Script de monitoramento da aplicao
Sistema de Agendamento
"""

import os
import sys
import time
import psutil
import requests
import logging
from datetime import datetime
import json

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('monitor.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

class SystemMonitor:
    def __init__(self, app_url="http://localhost:8000"):
        self.app_url = app_url
        self.thresholds = {
            'cpu': 80.0,
            'memory': 80.0,
            'disk': 85.0,
            'response_time': 5.0
        }
    
    def check_cpu(self):
        """Verifica uso de CPU"""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            status = "OK" if cpu_percent < self.thresholds['cpu'] else "ALERT"
            
            logger.info(f"CPU: {cpu_percent:.1f}% - {status}")
            return {
                'metric': 'cpu',
                'value': cpu_percent,
                'status': status,
                'threshold': self.thresholds['cpu']
            }
        except Exception as e:
            logger.error(f"Erro ao verificar CPU: {e}")
            return None
    
    def check_memory(self):
        """Verifica uso de memria"""
        try:
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            status = "OK" if memory_percent < self.thresholds['memory'] else "ALERT"
            
            logger.info(f"Memria: {memory_percent:.1f}% - {status}")
            return {
                'metric': 'memory',
                'value': memory_percent,
                'status': status,
                'threshold': self.thresholds['memory']
            }
        except Exception as e:
            logger.error(f"Erro ao verificar memria: {e}")
            return None
    
    def check_disk(self):
        """Verifica uso de disco"""
        try:
            disk = psutil.disk_usage('/')
            disk_percent = (disk.used / disk.total) * 100
            status = "OK" if disk_percent < self.thresholds['disk'] else "ALERT"
            
            logger.info(f"Disco: {disk_percent:.1f}% - {status}")
            return {
                'metric': 'disk',
                'value': disk_percent,
                'status': status,
                'threshold': self.thresholds['disk']
            }
        except Exception as e:
            logger.error(f"Erro ao verificar disco: {e}")
            return None
    
    def check_response_time(self):
        """Verifica tempo de resposta da aplicao"""
        try:
            start_time = time.time()
            response = requests.get(f"{self.app_url}/health/", timeout=10)
            end_time = time.time()
            
            response_time = end_time - start_time
            status = "OK" if response_time < self.thresholds['response_time'] else "ALERT"
            
            logger.info(f"Tempo de resposta: {response_time:.2f}s - {status}")
            return {
                'metric': 'response_time',
                'value': response_time,
                'status': status,
                'threshold': self.thresholds['response_time']
            }
        except Exception as e:
            logger.error(f"Erro ao verificar tempo de resposta: {e}")
            return None
    
    def check_app_health(self):
        """Verifica sade da aplicao"""
        try:
            response = requests.get(f"{self.app_url}/health/", timeout=10)
            
            if response.status_code == 200:
                logger.info("Aplicao: OK")
                return {
                    'metric': 'app_health',
                    'value': 1,
                    'status': 'OK',
                    'threshold': 1
                }
            else:
                logger.warning(f"Aplicao: Status {response.status_code}")
                return {
                    'metric': 'app_health',
                    'value': 0,
                    'status': 'ALERT',
                    'threshold': 1
                }
        except Exception as e:
            logger.error(f"Erro ao verificar sade da aplicao: {e}")
            return {
                'metric': 'app_health',
                'value': 0,
                'status': 'ALERT',
                'threshold': 1
            }
    
    def check_database_connections(self):
        """Verifica conexes com banco de dados"""
        try:
            # Importar Django settings
            import django
            from django.conf import settings
            
            os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings_production')
            django.setup()
            
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
            
            if result:
                logger.info("Banco de dados: OK")
                return {
                    'metric': 'database',
                    'value': 1,
                    'status': 'OK',
                    'threshold': 1
                }
            else:
                logger.warning("Banco de dados: Falha na consulta")
                return {
                    'metric': 'database',
                    'value': 0,
                    'status': 'ALERT',
                    'threshold': 1
                }
        except Exception as e:
            logger.error(f"Erro ao verificar banco de dados: {e}")
            return {
                'metric': 'database',
                'value': 0,
                'status': 'ALERT',
                'threshold': 1
            }
    
    def run_monitoring(self):
        """Executa monitoramento completo"""
        logger.info(" Iniciando monitoramento do sistema...")
        
        metrics = []
        
        # Verificar mtricas do sistema
        cpu_metric = self.check_cpu()
        if cpu_metric:
            metrics.append(cpu_metric)
        
        memory_metric = self.check_memory()
        if memory_metric:
            metrics.append(memory_metric)
        
        disk_metric = self.check_disk()
        if disk_metric:
            metrics.append(disk_metric)
        
        # Verificar mtricas da aplicao
        response_metric = self.check_response_time()
        if response_metric:
            metrics.append(response_metric)
        
        app_health_metric = self.check_app_health()
        if app_health_metric:
            metrics.append(app_health_metric)
        
        db_metric = self.check_database_connections()
        if db_metric:
            metrics.append(db_metric)
        
        # Calcular status geral
        alerts = [m for m in metrics if m['status'] == 'ALERT']
        
        if alerts:
            logger.warning(f"  {len(alerts)} alertas detectados:")
            for alert in alerts:
                logger.warning(f"  - {alert['metric']}: {alert['value']} (limite: {alert['threshold']})")
        else:
            logger.info(" Sistema saudvel")
        
        # Salvar mtricas em arquivo
        self.save_metrics(metrics)
        
        return len(alerts) == 0
    
    def save_metrics(self, metrics):
        """Salva mtricas em arquivo JSON"""
        try:
            timestamp = datetime.now().isoformat()
            data = {
                'timestamp': timestamp,
                'metrics': metrics
            }
            
            with open('metrics.json', 'w') as f:
                json.dump(data, f, indent=2)
            
            logger.info("Mtricas salvas em metrics.json")
        except Exception as e:
            logger.error(f"Erro ao salvar mtricas: {e}")
    
    def send_alert(self, message):
        """Envia alerta (implementar conforme necessrio)"""
        logger.warning(f"ALERTA: {message}")
        # Aqui voc pode implementar envio de email, Slack, etc.
    
    def run_continuous_monitoring(self, interval=60):
        """Executa monitoramento contnuo"""
        logger.info(f" Iniciando monitoramento contnuo (intervalo: {interval}s)")
        
        try:
            while True:
                self.run_monitoring()
                time.sleep(interval)
        except KeyboardInterrupt:
            logger.info("Monitoramento interrompido pelo usurio")
        except Exception as e:
            logger.error(f"Erro no monitoramento contnuo: {e}")

def main():
    """Funo principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Monitor do sistema')
    parser.add_argument('--url', default='http://localhost:8000',
                       help='URL da aplicao')
    parser.add_argument('--interval', type=int, default=60,
                       help='Intervalo de monitoramento em segundos')
    parser.add_argument('--continuous', action='store_true',
                       help='Executar monitoramento contnuo')
    parser.add_argument('--cpu-threshold', type=float, default=80.0,
                       help='Limite de CPU (%)')
    parser.add_argument('--memory-threshold', type=float, default=80.0,
                       help='Limite de memria (%)')
    parser.add_argument('--disk-threshold', type=float, default=85.0,
                       help='Limite de disco (%)')
    parser.add_argument('--response-threshold', type=float, default=5.0,
                       help='Limite de tempo de resposta (s)')
    
    args = parser.parse_args()
    
    monitor = SystemMonitor(args.url)
    
    # Configurar limites
    monitor.thresholds = {
        'cpu': args.cpu_threshold,
        'memory': args.memory_threshold,
        'disk': args.disk_threshold,
        'response_time': args.response_threshold
    }
    
    if args.continuous:
        monitor.run_continuous_monitoring(args.interval)
    else:
        success = monitor.run_monitoring()
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
