# 🔐 Configuração dos Secrets do GitHub

## Credenciais AWS Necessárias

⚠️ **IMPORTANTE:** Você precisa obter suas credenciais AWS reais

### Como obter suas credenciais AWS:

1. **Acesse o Console AWS IAM:**
   - Vá para: https://console.aws.amazon.com/iam/
   - Faça login na sua conta AWS

2. **Crie um usuário IAM (se não tiver):**
   - Clique em "Users" → "Create user"
   - Nome: `github-actions-deploy`
   - Anexe as políticas: `AmazonEC2FullAccess`, `AmazonRDSFullAccess`, `AmazonS3FullAccess`, `AmazonVPCFullAccess`, `CloudWatchFullAccess`

3. **Gere as chaves de acesso:**
   - Clique no usuário criado
   - Aba "Security credentials"
   - "Create access key"
   - Tipo: "Application running outside AWS"
   - Copie o Access Key ID e Secret Access Key

## Passo a Passo para Configurar no GitHub

### 1. Acesse as Configurações do Repositório
1. Vá para: https://github.com/ViniciusMocelin/sistema-de-agendamento
2. Clique em **Settings** (Configurações)
3. No menu lateral, clique em **Secrets and variables** → **Actions**

### 2. Adicione os Secrets Necessários

Clique em **"New repository secret"** para cada um dos secrets abaixo:

#### 🔑 **AWS_ACCESS_KEY_ID**
- **Name:** `AWS_ACCESS_KEY_ID`
- **Secret:** `[SUA_ACCESS_KEY_AQUI]`

#### 🔑 **AWS_SECRET_ACCESS_KEY**
- **Name:** `AWS_SECRET_ACCESS_KEY`
- **Secret:** `[SUA_SECRET_KEY_AQUI]`

#### 🔑 **DB_PASSWORD**
- **Name:** `DB_PASSWORD`
- **Secret:** `MinhaSenh@Segura123!` (ou sua senha preferida)

#### 🔑 **EC2_SSH_PRIVATE_KEY**
- **Name:** `EC2_SSH_PRIVATE_KEY`
- **Secret:** (veja instruções abaixo para gerar)

### 3. Gerar Chave SSH

Execute no PowerShell:
```powershell
# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa_github

# Mostrar chave privada (copie para EC2_SSH_PRIVATE_KEY)
Get-Content $env:USERPROFILE\.ssh\id_rsa_github

# Mostrar chave pública (adicione à EC2 depois)
Get-Content $env:USERPROFILE\.ssh\id_rsa_github.pub
```

### 4. Secrets Opcionais

#### 🔑 **DOMAIN_NAME** (opcional)
- **Name:** `DOMAIN_NAME`
- **Secret:** (deixe vazio se não tiver domínio)

#### 🔑 **NOTIFICATION_EMAIL** (opcional)
- **Name:** `NOTIFICATION_EMAIL`
- **Secret:** `seu@email.com`

### 5. Verificar Configuração

Após adicionar todos os secrets, você deve ter:

- ✅ `AWS_ACCESS_KEY_ID`
- ✅ `AWS_SECRET_ACCESS_KEY`
- ✅ `DB_PASSWORD`
- ✅ `EC2_SSH_PRIVATE_KEY`
- ✅ `DOMAIN_NAME` (opcional)
- ✅ `NOTIFICATION_EMAIL` (opcional)

### 6. Testar a Pipeline

1. Vá para: https://github.com/ViniciusMocelin/sistema-de-agendamento/actions
2. Clique em **"Terraform Deploy to AWS"**
3. Clique em **"Run workflow"**
4. Escolha a ação: **"apply"**
5. Clique em **"Run workflow"**

### 7. Adicionar Chave SSH à EC2

Após o primeiro deploy, você precisará adicionar a chave pública SSH à instância EC2:

1. **Obtenha o IP da EC2** (será mostrado na pipeline)
2. **Conecte-se à EC2:**
   ```bash
   ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_EC2]
   ```
3. **Adicione a chave pública:**
   ```bash
   echo "sua_chave_publica_aqui" >> ~/.ssh/authorized_keys
   ```

## 🚨 Troubleshooting

### Erro: "Credentials could not be loaded"
- Verifique se os secrets estão configurados corretamente
- Confirme se os nomes dos secrets estão exatamente como mostrado
- Verifique se não há espaços extras nos valores

### Erro: "Access Denied"
- Verifique se o usuário AWS tem as permissões necessárias
- Confirme se a região está correta (us-east-1)

### Erro: "SSH connection failed"
- Verifique se a chave SSH privada está correta
- Confirme se a chave pública foi adicionada à EC2

## ✅ Próximos Passos

1. Configure todos os secrets no GitHub
2. Execute a pipeline "Terraform Deploy to AWS"
3. Aguarde a criação da infraestrutura
4. Acesse a aplicação no IP fornecido
5. Adicione a chave SSH pública à EC2

## 📞 Suporte

Se tiver problemas:
- Verifique os logs na aba "Actions"
- Confirme se todos os secrets estão configurados
- Teste as credenciais AWS localmente: `aws sts get-caller-identity`
