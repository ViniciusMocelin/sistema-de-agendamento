# Configurações para deploy da infraestrutura
aws_region = "us-east-1"
project_name = "sistema-agendamento-4minds"
environment = "prod"
db_username = "postgres"
db_password = "senha_segura_postgre"
domain_name = ""
instance_type = "t2.micro"
db_instance_class = "db.t3.micro"
allocated_storage = 20
max_allocated_storage = 100
backup_retention_period = 7
multi_az = false
deletion_protection = false
enable_monitoring = true
cpu_threshold = 80
memory_threshold = 80
disk_threshold = 85
enable_ssl = true
enable_waf = false
enable_cloudfront = false
notification_email = "carlosmedeiroscode@gmail.com"
tags = {
  Environment = "prod"
  Project     = "sistema-agendamento-4minds"
  Owner       = "4Minds"
  CostCenter  = "TI"
}