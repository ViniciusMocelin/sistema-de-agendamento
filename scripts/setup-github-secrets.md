# Configuração dos Secrets do GitHub para Deploy

## Secrets Necessários

Para que a pipeline de deploy funcione corretamente, você precisa configurar os seguintes secrets no GitHub:

### 1. Acesse as Configurações do Repositório
1. Vá para o seu repositório no GitHub
2. Clique em **Settings** (Configurações)
3. No menu lateral, clique em **Secrets and variables** → **Actions**

### 2. Adicione os Seguintes Secrets

#### AWS Credentials
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

**Como obter:**
1. Acesse o [Console AWS IAM](https://console.aws.amazon.com/iam/)
2. Crie um usuário IAM com as seguintes políticas:
   - `AmazonEC2FullAccess`
   - `AmazonRDSFullAccess`
   - `AmazonS3FullAccess`
   - `AmazonVPCFullAccess`
   - `CloudWatchFullAccess`
   - `IAMFullAccess`
3. Gere as chaves de acesso (Access Key ID e Secret Access Key)

#### Database
```
DB_PASSWORD
```
**Valor:** Senha segura para o banco de dados PostgreSQL (ex: `MinhaSenh@Segura123!`)

#### SSH Key
```
EC2_SSH_PRIVATE_KEY
```
**Como obter:**
1. Gere uma chave SSH:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_github -N ""
   ```
2. Copie o conteúdo do arquivo `~/.ssh/id_rsa_github` (arquivo privado)
3. Cole no secret `EC2_SSH_PRIVATE_KEY`

#### Opcionais
```
DOMAIN_NAME
NOTIFICATION_EMAIL
```

**DOMAIN_NAME:** Seu domínio personalizado (ex: `meusite.com`)
**NOTIFICATION_EMAIL:** Email para notificações (ex: `seu@email.com`)

### 3. Configurar a Chave SSH na EC2

Após o primeiro deploy, você precisa adicionar a chave pública SSH à instância EC2:

1. Copie o conteúdo do arquivo `~/.ssh/id_rsa_github.pub`
2. Conecte-se à instância EC2:
   ```bash
   ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_EC2]
   ```
3. Adicione a chave pública:
   ```bash
   echo "conteudo_da_chave_publica" >> ~/.ssh/authorized_keys
   ```

### 4. Testar a Pipeline

1. Faça um commit e push para a branch `main`
2. A pipeline será executada automaticamente
3. Acesse **Actions** no GitHub para acompanhar o progresso

### 5. URLs de Acesso

Após o deploy bem-sucedido, você terá acesso a:

- **Aplicação Principal:** `http://[IP_DA_EC2]`
- **Painel Admin:** `http://[IP_DA_EC2]/admin/`
- **Dashboard:** `http://[IP_DA_EC2]/dashboard/`

**Credenciais do Admin:**
- Usuário: `@4minds`
- Senha: `@4mindsPassword`

## Troubleshooting

### Erro de Permissões AWS
- Verifique se as credenciais AWS estão corretas
- Confirme se o usuário IAM tem as permissões necessárias

### Erro de SSH
- Verifique se a chave SSH privada está correta
- Confirme se a chave pública foi adicionada à EC2

### Erro de Banco de Dados
- Verifique se a senha do banco está correta
- Confirme se o RDS está acessível

### Pipeline Falhando
- Verifique os logs na aba **Actions**
- Confirme se todos os secrets estão configurados
- Verifique se a instância EC2 está rodando
