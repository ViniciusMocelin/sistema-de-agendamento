# 🔐 Configuração dos Secrets do GitHub

## 📋 Secrets Necessários

Para que os workflows GitHub Actions funcionem corretamente, você precisa configurar os seguintes secrets no seu repositório GitHub:

### 1. AWS_ACCESS_KEY_ID
```
Chave de acesso AWS
Exemplo: AKIAIOSFODNN7EXAMPLE
```

### 2. AWS_SECRET_ACCESS_KEY
```
Chave secreta AWS
Exemplo: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### 3. EC2_SSH_KEY
```
Chave privada SSH para acesso à EC2
Exemplo: -----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA7... (conteúdo completo da chave privada)
-----END RSA PRIVATE KEY-----
```

### 4. GITHUB_TOKEN
```
Token do GitHub (gerado automaticamente)
Não precisa configurar manualmente
```

## 🔧 Como Configurar

### Passo 1: Acessar Configurações do Repositório

1. Vá para o seu repositório no GitHub
2. Clique em **Settings** (Configurações)
3. No menu lateral, clique em **Secrets and variables**
4. Clique em **Actions**

### Passo 2: Adicionar Secrets

Para cada secret:

1. Clique em **New repository secret**
2. Digite o **Name** (nome do secret)
3. Digite o **Value** (valor do secret)
4. Clique em **Add secret**

### Passo 3: Verificar Secrets Configurados

Você deve ver os seguintes secrets listados:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EC2_SSH_KEY`
- `GITHUB_TOKEN` (gerado automaticamente)

## 🔑 Como Obter as Credenciais

### AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY

1. **Acesse o Console AWS:**
   - Vá para https://console.aws.amazon.com
   - Faça login na sua conta

2. **Navegue para IAM:**
   - Procure por "IAM" no serviço de busca
   - Clique em "IAM"

3. **Crie um usuário (se não existir):**
   - Clique em "Users" (Usuários)
   - Clique em "Add user" (Adicionar usuário)
   - Digite um nome para o usuário (ex: "github-actions")
   - Selecione "Programmatic access" (Acesso programático)

4. **Configure permissões:**
   - Selecione "Attach existing policies directly" (Anexar políticas existentes diretamente)
   - Adicione as seguintes políticas:
     - `AmazonEC2FullAccess`
     - `AmazonRDSFullAccess`
     - `AmazonS3FullAccess`
     - `CloudWatchFullAccess`
     - `SNSFullAccess`

5. **Crie o usuário:**
   - Clique em "Create user"
   - **IMPORTANTE:** Copie e salve a Access Key ID e Secret Access Key
   - Você só poderá ver a Secret Access Key uma vez!

### EC2_SSH_KEY

1. **Localize sua chave privada SSH:**
   - Normalmente em `~/.ssh/id_rsa` (Linux/Mac) ou `C:\Users\SeuUsuario\.ssh\id_rsa` (Windows)

2. **Copie o conteúdo completo:**
   ```bash
   # Linux/Mac
   cat ~/.ssh/id_rsa
   
   # Windows
   type C:\Users\SeuUsuario\.ssh\id_rsa
   ```

3. **Formato esperado:**
   ```
   -----BEGIN RSA PRIVATE KEY-----
   MIIEpAIBAAKCAQEA7...
   (várias linhas)
   -----END RSA PRIVATE KEY-----
   ```

## ✅ Verificação

### Teste Local

1. **Configure AWS CLI localmente:**
   ```bash
   aws configure
   ```
   - Use as mesmas credenciais que você configurou no GitHub

2. **Teste conectividade:**
   ```bash
   aws sts get-caller-identity
   ```

3. **Teste acesso à EC2:**
   ```bash
   aws ec2 describe-instances --instance-ids i-04d14b81170c26323 --region us-east-1
   ```

### Teste GitHub Actions

1. **Vá para Actions no GitHub:**
   - Clique na aba "Actions" do seu repositório

2. **Execute um workflow manualmente:**
   - Clique em "Deploy to AWS"
   - Clique em "Run workflow"
   - Selecione a branch "main"
   - Clique em "Run workflow"

3. **Verifique os logs:**
   - Clique no workflow em execução
   - Verifique se não há erros de autenticação

## 🚨 Troubleshooting

### Erro: "Invalid credentials"
- Verifique se as credenciais AWS estão corretas
- Certifique-se de que o usuário tem as permissões necessárias

### Erro: "SSH connection failed"
- Verifique se a chave SSH está correta
- Certifique-se de que a chave corresponde à EC2

### Erro: "Access denied"
- Verifique as permissões do usuário AWS
- Certifique-se de que as políticas estão anexadas corretamente

### Erro: "Secret not found"
- Verifique se os secrets estão configurados no repositório correto
- Certifique-se de que os nomes dos secrets estão exatos

## 🔒 Segurança

### Boas Práticas:

1. **Use usuário específico para GitHub Actions:**
   - Não use credenciais da sua conta principal AWS
   - Crie um usuário dedicado com permissões mínimas necessárias

2. **Rotacione credenciais regularmente:**
   - Mude as credenciais AWS periodicamente
   - Atualize os secrets no GitHub

3. **Monitore uso:**
   - Verifique logs de uso das credenciais
   - Monitore custos AWS

4. **Limite permissões:**
   - Use políticas específicas ao invés de permissões amplas
   - Revise permissões regularmente

## 📞 Suporte

Se você encontrar problemas:

1. **Verifique os logs** do GitHub Actions
2. **Teste as credenciais** localmente
3. **Verifique as permissões** do usuário AWS
4. **Consulte a documentação** do AWS IAM

---

## 🎉 Conclusão

Após configurar todos os secrets:

- ✅ **Workflows GitHub Actions funcionarão automaticamente**
- ✅ **Deploy automático será executado a cada push**
- ✅ **Atualização de IP será monitorada continuamente**
- ✅ **Sistema estará completamente automatizado**

**Configure os secrets e aproveite a automação completa!** 🚀
