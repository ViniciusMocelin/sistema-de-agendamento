# 🚀 Quick Start - Automação Completa

## ⚡ Início Rápido (5 minutos)

### 1. Teste o Sistema (30 segundos)
```bash
python scripts/test-automation.py
```

### 2. Configure Secrets do GitHub (2 minutos)
Veja: [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)

### 3. Execute Automação Completa (2 minutos)
```powershell
# PowerShell (Recomendado)
.\scripts\start-aws-services-auto.ps1

# OU Batch (Windows)
scripts\start-aws-services-auto.bat
```

### 4. Pronto! 🎉
- ✅ Serviços AWS iniciados
- ✅ IP atualizado automaticamente
- ✅ Commit realizado no GitHub
- ✅ Deploy executado na AWS
- ✅ Sistema funcionando

## 🔄 Fluxo Automático

### Uma vez configurado, tudo é automático:

1. **Push para GitHub** → Deploy automático
2. **A cada 6 horas** → Verificação de IP
3. **Mudança de IP** → Atualização automática + Deploy

## 📋 Comandos Úteis

### Testar Sistema:
```bash
python scripts/test-automation.py
```

### Atualizar IP Manualmente:
```bash
python scripts/auto-ip-update.py --deploy
```

### Apenas Iniciar Serviços:
```powershell
.\scripts\start-aws-services-fixed.ps1
```

### Deploy Manual:
```batch
deploy-now.bat
```

## 🎯 URLs de Acesso

Após executar a automação:
- **Aplicação:** http://[IP_DA_EC2]
- **Admin:** http://[IP_DA_EC2]/admin/
- **Dashboard:** http://[IP_DA_EC2]/dashboard/

**Credenciais:**
- Usuário: `@4minds`
- Senha: `@4mindsPassword`

## 📞 Problemas?

1. **Execute o teste:** `python scripts/test-automation.py`
2. **Verifique logs:** GitHub Actions → Workflows
3. **Consulte:** [AUTOMACAO_COMPLETA.md](AUTOMACAO_COMPLETA.md)

---

**🎉 Sistema 100% automatizado e funcionando!**
