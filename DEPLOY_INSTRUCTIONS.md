# Instruções de Deploy - Sistema de Agendamento

## Visão Geral

Este documento fornece instruções passo a passo para fazer deploy do Sistema de Agendamento na AWS usando a configuração gratuita (Free Tier).

## Objetivo

Hospedar o sistema Django de agendamento na AWS com:
- EC2 t2.micro (Free Tier)
- RDS PostgreSQL db.t3.micro (Free Tier)
- S3 para arquivos estáticos
- Monitoramento e alertas
- Backup automático
- SSL/TLS configurado

## Arquivos Criados

```
sistema-de-agendamento/
├── AWS_DEPLOYMENT_GUIDE.md          # Guia completo de deploy
├── DEPLOY_INSTRUCTIONS.md           # Este arquivo
├── deploy.sh                        # Script de deploy automatizado
├── env.example                      # Exemplo de variáveis de ambiente
├── aws-infrastructure/              # Infraestrutura Terraform
│   ├── main.tf                      # Configuração principal
│   ├── variables.tf                 # Variáveis
│   ├── outputs.tf                   # Outputs
│   ├── user_data.sh                 # Script de inicialização EC2
│   ├── terraform.tfvars.example     # Exemplo de variáveis
│   └── README.md                    # Documentação da infraestrutura
└── scripts/                         # Scripts utilitários
    ├── health_check.py              # Verificação de saúde
    ├── backup.py                    # Backup automático
    └── monitor.py                   # Monitoramento
```

## Deploy Rápido

### 1. Pré-requisitos

```bash
# Instalar dependências
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Python e dependências
sudo apt update
sudo apt install python3 python3-pip git
pip3 install boto3 psutil requests
```

### 2. Configurar AWS

```bash
# Configurar credenciais AWS
aws configure

# Criar chave SSH (se não tiver)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### 3. Deploy Automatizado

```bash
# Tornar script executável
chmod +x deploy.sh

# Executar deploy
./deploy.sh

# Ou com parâmetros específicos
./deploy.sh deploy
```

### 4. Deploy Manual (Passo a Passo)

```bash
# 1. Configurar variáveis de ambiente
cp env.example .env
nano .env  # Editar com suas configurações

# 2. Configurar Terraform
cd aws-infrastructure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Editar com suas configurações

# 3. Aplicar infraestrutura
terraform init
terraform plan
terraform apply

# 4. Obter informações da infraestrutura
terraform output

# 5. Configurar aplicação
cd ..
python3 manage.py migrate --settings=core.settings_production
python3 manage.py collectstatic --noinput --settings=core.settings_production
```

## Configurações Importantes

### Variáveis de Ambiente (.env)

```bash
# Configurações Django
DEBUG=False
SECRET_KEY=sua_secret_key_aqui
ALLOWED_HOSTS=seu-ip-ec2,seu-dominio.com

# Configurações do Banco
DB_NAME=agendamentos_db
DB_USER=postgres
DB_PASSWORD=sua_senha_segura
DB_HOST=seu-endpoint-rds.amazonaws.com
DB_PORT=5432

# Configurações de Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=seu-email@gmail.com
EMAIL_HOST_PASSWORD=sua_senha_app
```

### Variáveis Terraform (terraform.tfvars)

```hcl
# Configurações básicas
aws_region = "us-east-1"
project_name = "sistema-agendamento"
environment = "prod"

# Banco de dados
db_password = "sua_senha_super_segura"

# Domínio (opcional)
domain_name = "meusite.com"

# Notificações
notification_email = "admin@meusite.com"
```

## Monitoramento

### Verificação de Saúde

```bash
# Verificar status da aplicação
python3 scripts/health_check.py

# Verificar com URL específica
python3 scripts/health_check.py --url http://seu-ip-ec2

# Monitoramento contínuo
python3 scripts/monitor.py --continuous --interval 60
```

### Backup

```bash
# Backup manual
python3 scripts/backup.py backup

# Listar backups
python3 scripts/backup.py list

# Restaurar backup
python3 scripts/backup.py restore --file /path/to/backup.sql
```

## Segurança

### Configurar SSL

```bash
# Conectar na instância EC2
ssh -i ~/.ssh/id_rsa ubuntu@seu-ip-ec2

# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d seu-dominio.com

# Configurar renovação automática
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

### Configurar Firewall

```bash
# Verificar status do firewall
sudo ufw status

# Configurar regras (já configurado automaticamente)
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

## Custos

### Free Tier (12 meses)
- **EC2 t2.micro**: 750 horas/mês
- **RDS db.t3.micro**: 750 horas/mês + 20GB
- **S3**: 5GB de armazenamento
- **Total**: $0/mês

### Após Free Tier
- **EC2 t2.micro**: ~$8-10/mês
- **RDS db.t3.micro**: ~$15-20/mês
- **S3 (5GB)**: ~$0.12/mês
- **Total**: ~$25-30/mês

## Troubleshooting

### Problemas Comuns

1. **Erro de conexão com banco**
   ```bash
   # Verificar security groups
   aws ec2 describe-security-groups --group-ids <sg-id>
   
   # Testar conectividade
   telnet <rds-endpoint> 5432
   ```

2. **Aplicação não inicia**
   ```bash
   # Verificar logs
   sudo journalctl -u django -f
   
   # Verificar configuração
   python manage.py check --settings=core.settings_production
   ```

3. **Arquivos estáticos não carregam**
   ```bash
   # Recriar arquivos estáticos
   python manage.py collectstatic --noinput --settings=core.settings_production
   
   # Verificar permissões
   sudo chown -R django:django /home/django/sistema-agendamento/staticfiles/
   ```

### Logs Importantes

```bash
# Logs da aplicação
sudo journalctl -u django -f

# Logs do Nginx
sudo tail -f /var/log/nginx/django_error.log

# Logs do sistema
sudo tail -f /var/log/syslog

# Logs de inicialização
sudo tail -f /var/log/user-data.log
```

## Próximos Passos

1. **Configurar CI/CD** com GitHub Actions
2. **Implementar CDN** com CloudFront
3. **Configurar Load Balancer** para alta disponibilidade
4. **Implementar Auto Scaling** para picos de tráfego
5. **Configurar WAF** para proteção adicional

## Suporte

Para dúvidas ou problemas:
- Email: suporte@sistema-agendamento.com
- WhatsApp: (11) 99999-9999
- Documentação: https://docs.sistema-agendamento.com

## Importante

- **Sempre teste em ambiente de desenvolvimento primeiro**
- **Configure backup automático**
- **Monitore os custos da AWS**
- **Altere senhas padrão**
- **Configure alertas de segurança**

---

**Parabéns!** Seu sistema de agendamento está pronto para produção na AWS!