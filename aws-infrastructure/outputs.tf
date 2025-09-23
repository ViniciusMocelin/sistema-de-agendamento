output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.web_server.public_ip
}

output "ec2_private_ip" {
  description = "IP privado da instância EC2"
  value       = aws_instance.web_server.private_ip
}

output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.web_server.id
}

output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "Porta do RDS"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Usuário do banco de dados"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "s3_bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.static_files.bucket
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.static_files.arn
}

output "sns_topic_arn" {
  description = "ARN do tópico SNS"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_log_group" {
  description = "Nome do grupo de logs CloudWatch"
  value       = aws_cloudwatch_log_group.django_app.name
}

output "security_group_ec2_id" {
  description = "ID do security group da EC2"
  value       = aws_security_group.ec2_sg.id
}

output "security_group_rds_id" {
  description = "ID do security group do RDS"
  value       = aws_security_group.rds_sg.id
}

output "application_url" {
  description = "URL da aplicação"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_instance.web_server.public_ip}"
}

output "ssh_command" {
  description = "Comando SSH para conectar na instância"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.web_server.public_ip}"
}

output "database_connection_string" {
  description = "String de conexão com o banco de dados"
  value       = "postgresql://${aws_db_instance.postgres.username}:${var.db_password}@${aws_db_instance.postgres.endpoint}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
  sensitive   = true
}

output "deployment_info" {
  description = "Informações do deploy"
  value = {
    project_name    = var.project_name
    environment     = var.environment
    region          = var.aws_region
    instance_type   = var.instance_type
    db_instance     = var.db_instance_class
    application_url = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_instance.web_server.public_ip}"
    created_at      = timestamp()
  }
}
