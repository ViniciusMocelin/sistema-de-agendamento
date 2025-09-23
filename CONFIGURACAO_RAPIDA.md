# Configuração Rápida da Infraestrutura AWS

## Método 1: Script Automatizado (Recomendado)

### Linux/macOS
```bash
# Tornar executável e executar
chmod +x setup-aws.sh
./setup-aws.sh
```

### Windows
```cmd
# Executar script
setup-aws.bat
```

## Método 2: Manual (Passo a Passo)

### 1. Pré-requisitos
- [ ] AWS CLI instalado e configurado
- [ ] Terraform instalado
- [ ] Chave SSH gerada

### 2. Configurar Variáveis
```bash
cd aws-infrastructure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Editar com suas configurações
```

### 3. Aplicar Infraestrutura
```bash
terraform init
terraform plan
terraform apply
```

### 4. Obter Informações
```bash
terraform output
```

## Configurações Obrigatórias

### terraform.tfvars
```hcl
# Configurações básicas
aws_region = "us-east-1"
project_name = "sistema-agendamento"
environment = "prod"

# SENHA OBRIGATÓRIA
db_password = "MinhaSenh@SuperSegura123!"

# Configurações opcionais
domain_name = "meusite.com"  # Deixe vazio se não tiver
notification_email = "admin@meusite.com"
```

## Recursos Criados

- **EC2 t2.micro** - Servidor web (Free Tier)
- **RDS PostgreSQL db.t3.micro** - Banco de dados (Free Tier)
- **S3 Bucket** - Arquivos estáticos (Free Tier)
- **VPC** - Rede privada
- **Security Groups** - Firewall
- **CloudWatch** - Monitoramento

## Acesso à Aplicação

Após a configuração, você terá:
- **URL**: `http://[IP_DA_EC2]`
- **Admin**: `http://[IP_DA_EC2]/admin/`
- **Usuário**: `admin`
- **Senha**: `admin123`
- **SSH**: `ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_EC2]`

## Comandos Úteis

```bash
# Ver status da infraestrutura
cd aws-infrastructure
terraform show

# Destruir infraestrutura
terraform destroy

# Ver logs da aplicação
ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_EC2]
sudo journalctl -u django -f
```

## Troubleshooting

### Problema: AWS CLI não configurado
```bash
aws configure
# Digite suas credenciais AWS
```

### Problema: Chave SSH não encontrada
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### Problema: Terraform não instalado
- **Windows**: Baixe de https://terraform.io/downloads
- **Linux**: `wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip`

## Custos

### Free Tier (12 meses)
- **Total**: $0/mês

### Após Free Tier
- **Total**: ~$25-30/mês

## Próximos Passos

1. Aguarde 5-10 minutos para a aplicação inicializar
2. Acesse a aplicação e configure seu sistema
3. Altere a senha do admin
4. Configure seu domínio (se aplicável)
5. Configure backup automático
6. Configure monitoramento

## Suporte

- **Documentação completa**: `TERRAFORM_SETUP_GUIDE.md`
- **Guia de deploy**: `AWS_DEPLOYMENT_GUIDE.md`
- **Instruções**: `DEPLOY_INSTRUCTIONS.md`
