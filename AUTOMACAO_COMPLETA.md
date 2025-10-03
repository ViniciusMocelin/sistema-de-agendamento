# 🤖 Sistema de Automação Completa - 4Minds

## 📋 Visão Geral

Este documento descreve o sistema completo de automação implementado para o Sistema de Agendamento, incluindo:

- ✅ **Atualização automática do IP da EC2**
- ✅ **Commit automático no GitHub**
- ✅ **Deploy automático na AWS**
- ✅ **Workflows GitHub Actions**
- ✅ **Monitoramento e notificações**

## 🚀 Scripts Disponíveis

### 1. Script Principal com Automação Completa

**PowerShell:**
```powershell
.\scripts\start-aws-services-auto.ps1
```

**Batch (Windows):**
```batch
scripts\start-aws-services-auto.bat
```

**Funcionalidades:**
- Inicia serviços AWS (EC2 + RDS)
- Obtém IP público automaticamente
- Atualiza arquivos de configuração
- Faz commit automático no GitHub
- Executa deploy automático na AWS

### 2. Script de Atualização de IP Standalone

**Python:**
```bash
python scripts/auto-ip-update.py [--deploy]
```

**Funcionalidades:**
- Obtém IP atual da EC2
- Compara com IP armazenado
- Atualiza arquivos de configuração
- Cria arquivo `ip-info.json`
- Faz commit automático
- Executa deploy (opcional)

### 3. Scripts Específicos

**Iniciar apenas serviços AWS:**
```powershell
.\scripts\start-aws-services-fixed.ps1
```

**Deploy manual:**
```batch
deploy-now.bat
```

## 🔄 Workflows GitHub Actions

### 1. Deploy Automático (`.github/workflows/deploy.yml`)

**Triggers:**
- Push para branch `main` ou `master`
- Pull Request para `main` ou `master`
- Execução manual via GitHub UI

**Funcionalidades:**
- Executa testes
- Verifica infraestrutura AWS
- Obtém IP da EC2
- Faz deploy via SSH
- Verifica funcionamento
- Cria arquivo de informações do deploy

### 2. Atualização de IP (`.github/workflows/update-ip.yml`)

**Triggers:**
- Agendamento: A cada 6 horas
- Execução manual via GitHub UI

**Funcionalidades:**
- Verifica se IP da EC2 mudou
- Atualiza arquivos de configuração
- Faz commit automático
- Dispara deploy se necessário

## 📁 Arquivos Criados/Modificados

### Novos Arquivos:

1. **`scripts/auto-ip-update.py`** - Script Python para atualização de IP
2. **`scripts/start-aws-services-auto.ps1`** - Script PowerShell com automação completa
3. **`scripts/start-aws-services-auto.bat`** - Script Batch com automação completa
4. **`.github/workflows/deploy.yml`** - Workflow de deploy automático
5. **`.github/workflows/update-ip.yml`** - Workflow de atualização de IP
6. **`ip-info.json`** - Arquivo com informações do IP atual (gerado automaticamente)

### Arquivos Modificados:

1. **`scripts/start-aws-services-fixed.ps1`** - Adicionadas funções de automação

## 🔧 Configuração Necessária

### 1. Secrets do GitHub

Configure os seguintes secrets no seu repositório GitHub:

```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
EC2_SSH_KEY=your_private_ssh_key
GITHUB_TOKEN=your_github_token
```

### 2. Pré-requisitos

**Local:**
- AWS CLI configurado
- Git configurado
- Python 3.x
- PowerShell (Windows)
- Chave SSH para EC2

**GitHub:**
- Repositório configurado
- Secrets configurados
- Branch `main` ou `master` como padrão

## 📊 Fluxo Completo de Automação

### Cenário 1: Inicialização Manual

1. **Usuário executa:**
   ```powershell
   .\scripts\start-aws-services-auto.ps1
   ```

2. **Script executa automaticamente:**
   - ✅ Inicia serviços AWS
   - ✅ Obtém IP público
   - ✅ Atualiza arquivos de configuração
   - ✅ Faz commit no GitHub
   - ✅ Executa deploy na AWS
   - ✅ Verifica funcionamento

3. **Resultado:**
   - Sistema funcionando
   - GitHub sincronizado
   - Deploy concluído

### Cenário 2: Atualização Automática

1. **GitHub Actions executa a cada 6 horas:**
   - Verifica se IP mudou
   - Atualiza configurações se necessário
   - Faz commit automático
   - Dispara deploy se IP mudou

2. **Push para GitHub:**
   - Dispara workflow de deploy
   - Executa testes
   - Faz deploy automático
   - Verifica funcionamento

### Cenário 3: Deploy Manual

1. **Via GitHub UI:**
   - Acesse Actions
   - Execute workflow "Deploy to AWS"
   - Escolha ambiente (production/staging)

2. **Via Script Local:**
   ```bash
   python scripts/auto-ip-update.py --deploy
   ```

## 📋 Monitoramento

### Arquivos de Log:

1. **`ip-info.json`** - Informações do IP atual
2. **`deployment-info.json`** - Informações do último deploy
3. **GitHub Actions Logs** - Logs detalhados dos workflows

### Verificações Automáticas:

- ✅ Status da EC2
- ✅ Status da RDS
- ✅ Conectividade da aplicação
- ✅ Funcionamento do admin
- ✅ Arquivos estáticos

## 🚨 Troubleshooting

### Problema: AWS CLI não configurado
**Solução:**
```bash
aws configure
```

### Problema: Git não configurado
**Solução:**
```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"
```

### Problema: Chave SSH não encontrada
**Solução:**
- Certifique-se de que `~/.ssh/id_rsa` existe
- Configure a chave no GitHub Secrets como `EC2_SSH_KEY`

### Problema: Workflows não executam
**Solução:**
- Verifique se os secrets estão configurados
- Verifique se o branch é `main` ou `master`
- Verifique as permissões do repositório

## 🎯 Benefícios da Automação

### ✅ Antes (Manual):
1. Iniciar serviços AWS
2. Obter IP manualmente
3. Atualizar arquivos manualmente
4. Fazer commit manual
5. Executar deploy manual
6. Verificar funcionamento manual

### ✅ Agora (Automático):
1. **Um comando:** `.\scripts\start-aws-services-auto.ps1`
2. **Tudo automático:** IP, commit, deploy, verificação
3. **GitHub sincronizado:** Sempre atualizado
4. **Monitoramento contínuo:** A cada 6 horas
5. **Deploy automático:** A cada push

## 🔐 Segurança

### Secrets Protegidos:
- Credenciais AWS
- Chaves SSH
- Tokens GitHub

### Verificações de Segurança:
- Testes antes do deploy
- Backup automático
- Verificação de integridade
- Logs detalhados

## 📞 Suporte

Para problemas ou dúvidas:

1. **Verifique os logs** do GitHub Actions
2. **Execute os scripts** com verbose para debug
3. **Verifique os arquivos** `ip-info.json` e `deployment-info.json`
4. **Consulte este documento** para troubleshooting

---

## 🎉 Conclusão

O sistema agora está **100% automatizado**:

- ✅ **IP atualizado automaticamente**
- ✅ **GitHub sempre sincronizado**
- ✅ **Deploy automático funcionando**
- ✅ **Monitoramento contínuo ativo**
- ✅ **Workflows GitHub Actions configurados**

**Execute um comando e tudo funciona automaticamente!** 🚀
