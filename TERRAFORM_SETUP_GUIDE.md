# Guia de Configuração da Infraestrutura AWS com Terraform

## Visão Geral

Este guia mostra como configurar a infraestrutura na AWS usando os arquivos Terraform criados para o Sistema de Agendamento.

## Pré-requisitos

### 1. Conta AWS
- [X] Conta AWS ativa
- [X] Free Tier ativado (se aplicável)
- [X] Usuário IAM com permissões adequadas

### 2. Ferramentas Necessárias
- [X] AWS CLI v2
- [X] Terraform v1.0+
- [X] Git
- [X] Chave SSH (para acesso à EC2)
git@github.com:ViniciusMocelin/sistema-de-agendamento.git

## Passo 1: Configurar AWS CLI

### Instalar AWS CLI

**Windows:**
```powershell
# Baixar e instalar AWS CLI
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

**Linux/macOS:**
```bash
# Baixar e instalar
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Configurar Credenciais

```bash
# Configurar credenciais
aws configure

# Digite suas credenciais:
# AWS Access Key ID: [sua-access-key]
# AWS Secret Access Key: [sua-secret-key]
# Default region name: us-east-1
# Default output format: json
```

### Verificar Configuração

```bash
# Testar conexão
aws sts get-caller-identity

# Deve retornar informações da sua conta AWS
```

## Passo 2: Instalar Terraform

### Windows
```powershell
# Baixar Terraform
Invoke-WebRequest -Uri "https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_windows_amd64.zip" -OutFile "terraform.zip"

# Extrair e instalar
Expand-Archive -Path "terraform.zip" -DestinationPath "C:\terraform"
$env:PATH += ";C:\terraform"
```

### Linux/macOS
```bash
# Baixar e instalar
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Verificar Instalação
```bash
terraform version
```

## Passo 3: Configurar Chave SSH

### Gerar Chave SSH (se não tiver)
```bash
# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

Obs: de ser erro, crie a pasta mkdir $env:USERPROFILE\.ssh
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa


# Verificar se a chave foi criada
ls -la ~/.ssh/
```

### Verificar Chave Pública
```bash
# Mostrar chave pública
cat ~/.ssh/id_rsa.pub

# Copie esta chave - será usada no Terraform
```

## Passo 4: Configurar Variáveis do Terraform

### 1. Navegar para o Diretório da Infraestrutura
```bash
cd aws-infrastructure
```

### 2. Copiar Arquivo de Variáveis
```bash
# Copiar arquivo de exemplo
cp terraform.tfvars.example terraform.tfvars
```

### 3. Editar Variáveis
```bash
# Editar arquivo de variáveis
nano terraform.tfvars
# ou
code terraform.tfvars
```

### 4. Configurar Variáveis Obrigatórias
```hcl
# terraform.tfvars
aws_region = "us-east-1"
project_name = "sistema-agendamento"
environment = "prod"

# SENHA OBRIGATÓRIA - Altere para uma senha segura
db_password = "senha_segura_postgre"

# Configurações opcionais
domain_name = "meusite.com"  # Deixe vazio se não tiver domínio
notification_email = "carlosmedeiroscode@gmail.com"
```

## Passo 5: Inicializar Terraform

### 1. Inicializar Terraform
```bash
# Inicializar Terraform (baixa providers)
terraform init
```

**Saída esperada:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.0.0...
Terraform has been successfully initialized!
```

### 2. Verificar Configuração
```bash
# Validar configuração
terraform validate
```

## Passo 6: Planejar Infraestrutura

### 1. Planejar Mudanças
```bash
# Ver o que será criado
terraform plan
```

**Saída esperada:**
```
Plan: 15 to add, 0 to change, 0 to destroy.
```

### 2. Salvar Plano (Opcional)
```bash
# Salvar plano para revisão
terraform plan -out=tfplan
```

## Passo 7: Aplicar Infraestrutura

### 1. Aplicar Mudanças
```bash
# Aplicar infraestrutura
terraform apply
```

**Confirmação:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

### 2. Aplicar Automaticamente (Alternativa)
```bash
# Aplicar sem confirmação
terraform apply -auto-approve
```

## Passo 8: Verificar Infraestrutura Criada

### 1. Ver Outputs
```bash
# Ver informações da infraestrutura criada
terraform output
```

**Saída esperada:**
```
ec2_public_ip = "13.223.47.98"
rds_endpoint = "sistema-agendamento-postgres.abc123.us-east-1.rds.amazonaws.com"
s3_bucket_name = "sistema-agendamento-static-files-xyz12345"
```

### 2. Verificar no Console AWS
- Acesse o [Console AWS](https://console.aws.amazon.com)
- Verifique os recursos criados:
  - EC2 Instances
  - RDS Databases
  - S3 Buckets
  - VPC e Subnets

## Passo 9: Conectar na Instância EC2

### 1. Obter IP da Instância
```bash
# Obter IP público
terraform output ec2_public_ip
```
============================================================
### 2. Conectar via SSH
```bash
# Conectar na instância
ssh -i ~/.ssh/id_rsa ubuntu@13.223.47.98
```
============================================================


### 3. Verificar Status da Aplicação
```bash
# Verificar status do Django
sudo systemctl status django

# Ver logs da aplicação
sudo journalctl -u django -f

# Verificar se a aplicação está rodando
curl http://localhost:8000/health/
```

## Passo 10: Acessar Aplicação

### 1. Obter URL da Aplicação
```bash
# Obter IP público
EC2_IP=$(terraform output -raw ec2_public_ip)
echo "Aplicação disponível em: http://$EC2_IP"
```

### 2. Acessar no Navegador
- Abra o navegador
- Acesse: `http://[IP_DA_INSTANCIA]`
- Admin: `http://[IP_DA_INSTANCIA]/admin/`
- Usuário: `admin`
- Senha: `admin123`

## Comandos Úteis do Terraform

### Gerenciar Infraestrutura
```bash
# Ver estado atual
terraform show

# Listar recursos
terraform state list

# Ver detalhes de um recurso
terraform state show aws_instance.web_server

# Atualizar infraestrutura
terraform plan
terraform apply

# Destruir infraestrutura
terraform destroy
```

### Troubleshooting
```bash
# Ver logs detalhados
TF_LOG=DEBUG terraform apply

# Recriar um recurso específico
terraform taint aws_instance.web_server
terraform apply

# Importar recurso existente
terraform import aws_instance.web_server i-1234567890abcdef0
```

## Configurações Avançadas

### 1. Configurar Domínio Personalizado
```bash
# Editar terraform.tfvars
domain_name = "meusite.com"

# Aplicar mudanças
terraform plan
terraform apply
```

### 2. Configurar SSL
```bash
# Conectar na instância
ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_INSTANCIA]

# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d meusite.com
```

### 3. Configurar Backup
```bash
# O backup já está configurado automaticamente
# Verificar cron jobs
crontab -l

# Executar backup manual
sudo -u django /home/django/backup.sh
```

## Monitoramento

### 1. CloudWatch Logs
- Acesse [CloudWatch Logs](https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups)
- Procure por: `/aws/ec2/sistema-agendamento/`

### 2. Métricas EC2
- Acesse [EC2 Console](https://console.aws.amazon.com/ec2/)
- Selecione sua instância
- Aba "Monitoring"

### 3. Alertas
- Acesse [CloudWatch Alarms](https://console.aws.amazon.com/cloudwatch/home#alarmsV2:)
- Verifique alertas configurados

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

## Limpeza (Destruir Infraestrutura)

### 1. Destruir Infraestrutura
```bash
# Destruir todos os recursos
terraform destroy

# Confirmar destruição
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

### 2. Verificar Limpeza
```bash
# Verificar se todos os recursos foram removidos
terraform show

# Deve retornar: No state.
```

## Troubleshooting

### Problemas Comuns

1. **Erro de permissões AWS**
   ```bash
   # Verificar credenciais
   aws sts get-caller-identity
   
   # Reconfigurar se necessário
   aws configure
   ```

2. **Erro de chave SSH**
   ```bash
   # Verificar se a chave existe
   ls -la ~/.ssh/id_rsa.pub
   
   # Gerar nova chave se necessário
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

3. **Erro de região**
   ```bash
   # Verificar região configurada
   aws configure get region
   
   # Alterar região se necessário
   aws configure set region us-east-1
   ```

4. **Erro de recursos já existem**
   ```bash
   # Verificar estado
   terraform state list
   
   # Importar recurso existente
   terraform import aws_instance.web_server i-1234567890abcdef0
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

---

**Importante:** Sempre teste em ambiente de desenvolvimento antes de aplicar em produção.
