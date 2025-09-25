# Gerenciamento de Serviços AWS - Sistema de Agendamento

Este diretório contém scripts para gerenciar os serviços AWS que geram cobrança no Sistema de Agendamento.

## 📋 Recursos Identificados

Com base na análise dos arquivos Terraform, os seguintes recursos geram cobrança quando estão ativos:

### 💰 Recursos Principais (Cobrados)
- **EC2 Instance**: `i-04d14b81170c26323` (t2.micro)
- **RDS PostgreSQL**: `sistema-agendamento-postgres` (db.t3.micro)

### 🔧 Recursos de Infraestrutura (Gratuitos ou Baixo Custo)
- **S3 Bucket**: `sistema-agendamento-static-files-dknda48q`
- **CloudWatch Logs**: `/aws/ec2/sistema-agendamento/django`
- **SNS Topic**: `sistema-agendamento-alerts`
- **VPC, Subnets, Security Groups, etc.**

## 🚀 Scripts Disponíveis

### 🐧 Linux/macOS/Git Bash

#### 1. `aws-service-manager.sh` - Gerenciador Principal
Script interativo com menu para gerenciar todos os serviços.

```bash
# Executar menu interativo
./scripts/aws-service-manager.sh

# Executar comandos diretos
./scripts/aws-service-manager.sh stop    # Parar todos os serviços
./scripts/aws-service-manager.sh start   # Iniciar todos os serviços
./scripts/aws-service-manager.sh status  # Verificar status
```

#### 2. `stop-aws-services.sh` - Parar Serviços
Para todas as instâncias que geram cobrança.

```bash
./scripts/stop-aws-services.sh
```

#### 3. `start-aws-services.sh` - Iniciar Serviços
Inicia todas as instâncias necessárias.

```bash
./scripts/start-aws-services.sh
```

### 🪟 Windows

#### Opção 1: Scripts Batch (Mais Fácil)
Duplo-clique nos arquivos `.bat` ou execute no prompt:

```cmd
# Iniciar serviços
scripts\start-aws-services.bat

# Parar serviços
scripts\stop-aws-services.bat
```

#### Opção 2: Scripts PowerShell
```powershell
# Iniciar serviços
.\scripts\start-aws-services.ps1

# Parar serviços
.\scripts\stop-aws-services.ps1

# Ver ajuda
.\scripts\start-aws-services.ps1 -Help
```

#### Opção 3: Git Bash (Se instalado)
```bash
# No Git Bash
./scripts/start-aws-services.sh
./scripts/stop-aws-services.sh
```

## 📊 Comandos AWS CLI Diretos

### Parar Serviços

```bash
# Parar instância EC2
aws ec2 stop-instances --instance-ids i-04d14b81170c26323 --region us-east-1

# Parar instância RDS
aws rds stop-db-instance --db-instance-identifier sistema-agendamento-postgres --region us-east-1
```

### Iniciar Serviços

```bash
# Iniciar instância EC2
aws ec2 start-instances --instance-ids i-04d14b81170c26323 --region us-east-1

# Iniciar instância RDS
aws rds start-db-instance --db-instance-identifier sistema-agendamento-postgres --region us-east-1
```

### Verificar Status

```bash
# Status da EC2
aws ec2 describe-instances --instance-ids i-04d14b81170c26323 --region us-east-1 --query 'Reservations[0].Instances[0].State.Name' --output text

# Status da RDS
aws rds describe-db-instances --db-instance-identifier sistema-agendamento-postgres --region us-east-1 --query 'DBInstances[0].DBInstanceStatus' --output text

# IP público da EC2
aws ec2 describe-instances --instance-ids i-04d14b81170c26323 --region us-east-1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

## 💡 Dicas de Economia

### Para Desenvolvimento/Testes
- **Pare os serviços** quando não estiver usando: `./scripts/stop-aws-services.sh`
- **Inicie apenas quando necessário**: `./scripts/start-aws-services.sh`
- **Monitore custos** no AWS Cost Explorer

### Para Produção
- **Mantenha os serviços rodando** para alta disponibilidade
- **Configure alertas** de custo no AWS Billing
- **Use Reserved Instances** para economizar em longo prazo

## ⚠️ Importante

1. **S3 e CloudWatch continuam ativos** mesmo quando EC2/RDS estão parados
2. **Dados são preservados** quando você para as instâncias
3. **IP público pode mudar** ao reiniciar a EC2 (exceto com Elastic IP)
4. **Aguarde alguns minutos** para a aplicação ficar pronta após iniciar

## 🔧 Configuração Necessária

Certifique-se de ter:

1. **AWS CLI instalado e configurado**:
   ```bash
   aws configure
   ```

2. **Permissões adequadas** para:
   - `ec2:StartInstances`
   - `ec2:StopInstances`
   - `ec2:DescribeInstances`
   - `rds:StartDBInstance`
   - `rds:StopDBInstance`
   - `rds:DescribeDBInstances`

## 📱 URLs e Acesso

- **Aplicação Web**: http://[IP_PUBLICO_EC2]
- **SSH**: `ssh -i ~/.ssh/id_rsa ubuntu@[IP_PUBLICO_EC2]`
- **Banco de Dados**: `sistema-agendamento-postgres.cgr24gyuwi3d.us-east-1.rds.amazonaws.com:5432`

## 🆘 Troubleshooting

### Problemas Comuns

1. **AWS CLI não configurado**:
   ```bash
   aws configure list
   aws sts get-caller-identity
   ```

2. **Instância não para/inicia**:
   - Verifique permissões IAM
   - Aguarde o estado atual se estiver em transição

3. **Aplicação não responde**:
   - Aguarde alguns minutos após iniciar
   - Verifique logs: `ssh ubuntu@[IP] sudo journalctl -u gunicorn`

### Logs e Monitoramento

```bash
# Logs da aplicação
ssh ubuntu@[IP_PUBLICO] sudo journalctl -u gunicorn -f

# Status dos serviços
ssh ubuntu@[IP_PUBLICO] sudo systemctl status gunicorn
ssh ubuntu@[IP_PUBLICO] sudo systemctl status nginx
```

---

**Nota**: Estes scripts foram criados especificamente para a infraestrutura do Sistema de Agendamento. Ajuste os IDs dos recursos conforme necessário.
