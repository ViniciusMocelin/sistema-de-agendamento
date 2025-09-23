#!/usr/bin/env python3
"""
Script de backup automtico
Sistema de Agendamento
"""

import os
import sys
import subprocess
import boto3
import tarfile
import shutil
from datetime import datetime, timedelta
import logging
from pathlib import Path

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('backup.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

class BackupManager:
    def __init__(self):
        self.backup_dir = Path("/home/django/backups")
        self.media_dir = Path("/home/django/sistema-agendamento/media")
        self.static_dir = Path("/home/django/sistema-agendamento/staticfiles")
        self.retention_days = int(os.environ.get('BACKUP_RETENTION_DAYS', '7'))
        
        # Configurar S3
        self.s3_bucket = os.environ.get('S3_BUCKET_NAME', '')
        self.s3_client = None
        
        if self.s3_bucket:
            try:
                self.s3_client = boto3.client('s3')
                logger.info(f"S3 configurado: {self.s3_bucket}")
            except Exception as e:
                logger.warning(f"Erro ao configurar S3: {e}")
        
        # Criar diretrio de backup
        self.backup_dir.mkdir(parents=True, exist_ok=True)
    
    def backup_database(self):
        """Faz backup do banco de dados"""
        try:
            # Configurar variveis de ambiente do banco
            db_host = os.environ.get('DB_HOST', 'localhost')
            db_port = os.environ.get('DB_PORT', '5432')
            db_name = os.environ.get('DB_NAME', 'agendamentos_db')
            db_user = os.environ.get('DB_USER', 'postgres')
            db_password = os.environ.get('DB_PASSWORD', '')
            
            # Nome do arquivo de backup
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_file = self.backup_dir / f"db_backup_{timestamp}.sql"
            
            # Configurar varivel de ambiente para senha
            env = os.environ.copy()
            env['PGPASSWORD'] = db_password
            
            # Executar pg_dump
            cmd = [
                'pg_dump',
                '-h', db_host,
                '-p', db_port,
                '-U', db_user,
                '-d', db_name,
                '-f', str(backup_file)
            ]
            
            result = subprocess.run(cmd, env=env, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info(f" Backup do banco criado: {backup_file}")
                return backup_file
            else:
                logger.error(f" Erro no backup do banco: {result.stderr}")
                return None
                
        except Exception as e:
            logger.error(f" Erro no backup do banco: {e}")
            return None
    
    def backup_media_files(self):
        """Faz backup dos arquivos de mdia"""
        try:
            if not self.media_dir.exists():
                logger.warning("Diretrio de mdia no encontrado")
                return None
            
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_file = self.backup_dir / f"media_backup_{timestamp}.tar.gz"
            
            with tarfile.open(backup_file, 'w:gz') as tar:
                tar.add(self.media_dir, arcname='media')
            
            logger.info(f" Backup de mdia criado: {backup_file}")
            return backup_file
            
        except Exception as e:
            logger.error(f" Erro no backup de mdia: {e}")
            return None
    
    def backup_static_files(self):
        """Faz backup dos arquivos estticos"""
        try:
            if not self.static_dir.exists():
                logger.warning("Diretrio de arquivos estticos no encontrado")
                return None
            
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_file = self.backup_dir / f"static_backup_{timestamp}.tar.gz"
            
            with tarfile.open(backup_file, 'w:gz') as tar:
                tar.add(self.static_dir, arcname='static')
            
            logger.info(f" Backup de arquivos estticos criado: {backup_file}")
            return backup_file
            
        except Exception as e:
            logger.error(f" Erro no backup de arquivos estticos: {e}")
            return None
    
    def upload_to_s3(self, file_path):
        """Upload do arquivo para S3"""
        if not self.s3_client or not self.s3_bucket:
            logger.warning("S3 no configurado, pulando upload")
            return False
        
        try:
            key = f"backups/{file_path.name}"
            self.s3_client.upload_file(str(file_path), self.s3_bucket, key)
            logger.info(f" Upload para S3: s3://{self.s3_bucket}/{key}")
            return True
        except Exception as e:
            logger.error(f" Erro no upload para S3: {e}")
            return False
    
    def cleanup_old_backups(self):
        """Remove backups antigos"""
        try:
            cutoff_date = datetime.now() - timedelta(days=self.retention_days)
            
            for file_path in self.backup_dir.glob('*'):
                if file_path.is_file():
                    file_time = datetime.fromtimestamp(file_path.stat().st_mtime)
                    if file_time < cutoff_date:
                        file_path.unlink()
                        logger.info(f"  Backup antigo removido: {file_path.name}")
            
            logger.info(f" Limpeza concluda (reteno: {self.retention_days} dias)")
            
        except Exception as e:
            logger.error(f" Erro na limpeza: {e}")
    
    def run_backup(self):
        """Executa backup completo"""
        logger.info(" Iniciando backup completo...")
        
        # Backup do banco de dados
        db_backup = self.backup_database()
        if db_backup:
            self.upload_to_s3(db_backup)
        
        # Backup de arquivos de mdia
        media_backup = self.backup_media_files()
        if media_backup:
            self.upload_to_s3(media_backup)
        
        # Backup de arquivos estticos
        static_backup = self.backup_static_files()
        if static_backup:
            self.upload_to_s3(static_backup)
        
        # Limpeza de backups antigos
        self.cleanup_old_backups()
        
        logger.info(" Backup concludo com sucesso!")
    
    def restore_database(self, backup_file):
        """Restaura banco de dados a partir de backup"""
        try:
            # Configurar variveis de ambiente do banco
            db_host = os.environ.get('DB_HOST', 'localhost')
            db_port = os.environ.get('DB_PORT', '5432')
            db_name = os.environ.get('DB_NAME', 'agendamentos_db')
            db_user = os.environ.get('DB_USER', 'postgres')
            db_password = os.environ.get('DB_PASSWORD', '')
            
            # Configurar varivel de ambiente para senha
            env = os.environ.copy()
            env['PGPASSWORD'] = db_password
            
            # Executar psql
            cmd = [
                'psql',
                '-h', db_host,
                '-p', db_port,
                '-U', db_user,
                '-d', db_name,
                '-f', str(backup_file)
            ]
            
            result = subprocess.run(cmd, env=env, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info(f" Banco de dados restaurado: {backup_file}")
                return True
            else:
                logger.error(f" Erro na restaurao: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f" Erro na restaurao: {e}")
            return False
    
    def list_backups(self):
        """Lista backups disponveis"""
        logger.info(" Backups disponveis:")
        
        for file_path in sorted(self.backup_dir.glob('*')):
            if file_path.is_file():
                file_time = datetime.fromtimestamp(file_path.stat().st_mtime)
                size = file_path.stat().st_size
                logger.info(f"  {file_path.name} - {file_time.strftime('%Y-%m-%d %H:%M:%S')} - {size:,} bytes")

def main():
    """Funo principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Gerenciador de backup')
    parser.add_argument('action', choices=['backup', 'restore', 'list'],
                       help='Ao a executar')
    parser.add_argument('--file', help='Arquivo de backup para restaurao')
    parser.add_argument('--retention', type=int, default=7,
                       help='Dias de reteno de backup')
    
    args = parser.parse_args()
    
    # Configurar reteno
    os.environ['BACKUP_RETENTION_DAYS'] = str(args.retention)
    
    manager = BackupManager()
    
    if args.action == 'backup':
        manager.run_backup()
    elif args.action == 'restore':
        if not args.file:
            logger.error("Arquivo de backup no especificado")
            sys.exit(1)
        manager.restore_database(Path(args.file))
    elif args.action == 'list':
        manager.list_backups()

if __name__ == "__main__":
    main()
