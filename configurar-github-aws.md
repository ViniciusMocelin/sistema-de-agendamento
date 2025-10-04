# 🔐 Configurar Credenciais AWS no GitHub Actions

## 📋 **PROBLEMA IDENTIFICADO:**
O GitHub Actions não consegue carregar as credenciais AWS, retornando o erro:
```
Error: Credentials could not be loaded, please check your action inputs: Could not load credentials from any providers
```

## 🔧 **SOLUÇÃO: Configurar GitHub Secrets**

### **PASSO 1: Acessar o GitHub Repository**
1. Vá para: https://github.com/ViniciusMocelin/sistema-de-agendamento
2. Clique em **Settings** (Configurações)
3. No menu lateral, clique em **Secrets and variables** → **Actions**

### **PASSO 2: Adicionar os Secrets Necessários**

Clique em **"New repository secret"** e adicione os seguintes secrets:

#### **1. AWS_ACCESS_KEY_ID**
- **Name:** `AWS_ACCESS_KEY_ID`
- **Secret:** `AKIAUJW7WTY3X43JIHYFH` (sua chave de acesso)

#### **2. AWS_SECRET_ACCESS_KEY**
- **Name:** `AWS_SECRET_ACCESS_KEY`
- **Secret:** `[SUA_SECRET_KEY_AQUI]` (sua chave secreta)

#### **3. DB_PASSWORD**
- **Name:** `DB_PASSWORD`
- **Secret:** `MinhaSenhaSegura123`

#### **4. EC2_SSH_PRIVATE_KEY**
- **Name:** `EC2_SSH_PRIVATE_KEY`
- **Secret:** [Conteúdo completo da chave SSH privada]

### **PASSO 3: Obter a Chave SSH Privada**

Execute este comando para obter sua chave SSH privada:

```powershell
Get-Content $env:USERPROFILE\.ssh\id_rsa_github
```

**IMPORTANTE:** Copie TODO o conteúdo da chave (incluindo `-----BEGIN OPENSSH PRIVATE KEY-----` e `-----END OPENSSH PRIVATE KEY-----`)

### **PASSO 4: Obter a AWS Secret Key**

Execute este comando para obter sua secret key:

```powershell
aws configure get aws_secret_access_key
```

### **PASSO 5: Verificar Configuração**

Após adicionar todos os secrets, você deve ter:

```
✅ AWS_ACCESS_KEY_ID
✅ AWS_SECRET_ACCESS_KEY  
✅ DB_PASSWORD
✅ EC2_SSH_PRIVATE_KEY
```

### **PASSO 6: Testar o Deploy**

1. Faça um commit e push:
```bash
git add .
git commit -m "Teste deploy com credenciais AWS"
git push origin main
```

2. Vá para a aba **Actions** no GitHub
3. Verifique se o workflow está executando sem erros

## 🚨 **IMPORTANTE - SEGURANÇA:**

- **NUNCA** commite credenciais no código
- **SEMPRE** use GitHub Secrets para dados sensíveis
- **MANTENHA** as chaves privadas seguras

## 🔍 **VERIFICAÇÃO:**

Se ainda houver problemas, verifique:

1. **Se os secrets estão corretos** (sem espaços extras)
2. **Se a chave SSH está completa** (com headers)
3. **Se o usuário AWS tem permissões** adequadas
4. **Se a região está correta** (us-east-1)

## 📞 **SUPORTE:**

Se precisar de ajuda, verifique:
- Logs do GitHub Actions na aba "Actions"
- Configurações AWS no console
- Permissões IAM do usuário
