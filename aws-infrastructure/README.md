#  Infraestrutura AWS - Sistema de Agendamento

Este diretrio contm todos os arquivos necessrios para criar e gerenciar a infraestrutura AWS do Sistema de Agendamento usando Terraform.

##  Estrutura de Arquivos

```
aws-infrastructure/
 main.tf                 # Configurao principal do Terraform
 variables.tf            # Variveis do Terraform
 outputs.tf              # Outputs do Terraform
 user_data.sh            # Script de inicializao da EC2
 terraform.tfvars.example # Exemplo de variveis
 README.md               # Este arquivo
```

##  Como Usar

### 1. Pr-requisitos

- [ ] AWS CLI configurado
- [ ] Terraform instalado
- [ ] Chave SSH criada (`~/.ssh/id_rsa.pub`)
- [ ] Conta AWS com permisses adequadas

### 2. Configurao Inicial

```bash
# 1. Copiar arquivo de variveis
cp terraform.tfvars.example terraform.tfvars

# 2. Editar variveis
nano terraform.tfvars

# 3. Inicializar Terraform
terraform init

# 4. Planejar mudanas
terraform plan

# 5. Aplicar mudanas
terraform apply
```

### 3. Configuraes Importantes

#### Variveis Obrigatrias

```hcl
# terraform.tfvars
db_password = "sua_senha_super_segura_aqui"
```

#### Variveis Opcionais

```hcl
# terraform.tfvars
domain_name = "meusite.com"
notification_email = "admin@meusite.com"
instance_type = "t2.micro"
db_instance_class = "db.t3.micro"
```

### 4. Comandos teis

```bash
# Ver status da infraestrutura
terraform show

# Ver outputs
terraform output

# Destruir infraestrutura
terraform destroy

# Aplicar mudanas especficas
terraform apply -target=aws_instance.web_server
```

##  Recursos Criados

### EC2
- **Tipo**: t2.micro (Free Tier)
- **Sistema**: Ubuntu 22.04 LTS
- **Aplicaes**: Nginx + Gunicorn + Django
- **Portas**: 22 (SSH), 80 (HTTP), 443 (HTTPS)

### RDS
- **Tipo**: db.t3.micro (Free Tier)
- **Engine**: PostgreSQL 15.4
- **Armazenamento**: 20GB (mximo 100GB)
- **Backup**: 7 dias de reteno

### S3
- **Bucket**: Para arquivos estticos
- **Armazenamento**: 5GB (Free Tier)
- **Versionamento**: Habilitado

### VPC
- **CIDR**: 10.0.0.0/16
- **Subnets**: 1 pblica, 2 privadas
- **Security Groups**: Configurados para EC2 e RDS

### CloudWatch
- **Logs**: Aplicao Django e Nginx
- **Mtricas**: CPU, Memria, Disco
- **Alertas**: Configurados para alta utilizao

##  Configuraes Ps-Deploy

### 1. Conectar na Instncia

```bash
# Obter IP da instncia
terraform output ec2_public_ip

# Conectar via SSH
ssh -i ~/.ssh/id_rsa ubuntu@<IP_DA_INSTANCIA>
```

### 2. Verificar Status da Aplicao

```bash
# Status do servio Django
sudo systemctl status django

# Logs da aplicao
sudo journalctl -u django -f

# Logs do Nginx
sudo tail -f /var/log/nginx/django_error.log
```

### 3. Configurar SSL (Opcional)

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d seu-dominio.com

# Configurar renovao automtica
sudo crontab -e
# Adicionar: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 4. Configurar Backup

```bash
# O backup j est configurado automaticamente
# Verificar cron jobs
crontab -l

# Executar backup manual
sudo -u django /home/django/backup.sh
```

##  Monitoramento

### CloudWatch Logs
- **Django**: `/aws/ec2/sistema-agendamento/django`
- **Nginx Access**: `/aws/ec2/sistema-agendamento/nginx-access`
- **Nginx Error**: `/aws/ec2/sistema-agendamento/nginx-error`

### Mtricas
- **CPU**: Utilizao da instncia EC2
- **Memria**: Utilizao de memria
- **Disco**: Utilizao de espao em disco
- **RDS**: Conexes e performance

### Alertas
- **CPU > 80%**: Notificao via SNS
- **Memria > 80%**: Notificao via SNS
- **Disco > 85%**: Notificao via SNS

##  Custos Estimados

### Free Tier (12 meses)
- **EC2 t2.micro**: 750 horas/ms
- **RDS db.t3.micro**: 750 horas/ms + 20GB
- **S3**: 5GB de armazenamento
- **Total**: $0/ms

### Aps Free Tier
- **EC2 t2.micro**: ~$8-10/ms
- **RDS db.t3.micro**: ~$15-20/ms
- **S3 (5GB)**: ~$0.12/ms
- **Total**: ~$25-30/ms

##  Segurana

### Security Groups
- **EC2**: SSH (22), HTTP (80), HTTPS (443)
- **RDS**: PostgreSQL (5432) apenas da EC2

### Configuraes de Segurana
- **HTTPS**: Configurado com Let's Encrypt
- **Firewall**: UFW configurado
- **Logs**: Centralizados no CloudWatch
- **Backup**: Automtico dirio

##  Troubleshooting

### Problemas Comuns

1. **Erro de conexo com banco**
   ```bash
   # Verificar security groups
   aws ec2 describe-security-groups --group-ids <sg-id>
   
   # Testar conectividade
   telnet <rds-endpoint> 5432
   ```

2. **Aplicao no inicia**
   ```bash
   # Verificar logs
   sudo journalctl -u django -f
   
   # Verificar configurao
   sudo -u django python manage.py check --settings=core.settings_production
   ```

3. **Arquivos estticos no carregam**
   ```bash
   # Recriar arquivos estticos
   sudo -u django python manage.py collectstatic --noinput --settings=core.settings_production
   
   # Verificar permisses
   sudo chown -R django:django /home/django/sistema-agendamento/staticfiles/
   ```

### Logs Importantes

```bash
# Logs da aplicao
sudo journalctl -u django -f

# Logs do Nginx
sudo tail -f /var/log/nginx/django_error.log

# Logs do sistema
sudo tail -f /var/log/syslog

# Logs de inicializao
sudo tail -f /var/log/user-data.log
```

##  Prximos Passos

1. **Configurar CI/CD** com GitHub Actions
2. **Implementar CDN** com CloudFront
3. **Configurar Load Balancer** para alta disponibilidade
4. **Implementar Auto Scaling** para picos de trfego
5. **Configurar WAF** para proteo adicional

##  Suporte

Para dvidas ou problemas:
-  Email: suporte@sistema-agendamento.com
-  WhatsApp: (11) 99999-9999
-  Documentao: https://docs.sistema-agendamento.com

---

** Importante:** Este guia  para fins educacionais. Sempre teste em ambiente de desenvolvimento antes de aplicar em produo.
