# 🚀 GUIA COMPLETO: DEPLOY GRATUITO NO RAILWAY

## 📋 PRÉ-REQUISITOS

- ✅ Conta no GitHub
- ✅ Conta no Railway (gratuita)
- ✅ Sistema Django configurado

---

## 🎯 PASSO A PASSO COMPLETO

### **1. PREPARAR REPOSITÓRIO GITHUB**

```bash
# 1. Inicializar Git (se não existir)
git init

# 2. Adicionar todos os arquivos
git add .

# 3. Fazer commit
git commit -m "Preparar para deploy no Railway"

# 4. Criar repositório no GitHub e conectar
git remote add origin https://github.com/SEU_USUARIO/sistema-agendamento.git
git push -u origin main
```

### **2. CRIAR CONTA NO RAILWAY**

1. Acesse: https://railway.app
2. Clique em "Login" → "Login with GitHub"
3. Autorize o Railway a acessar seus repositórios

### **3. CRIAR NOVO PROJETO**

1. No Railway, clique em "New Project"
2. Selecione "Deploy from GitHub repo"
3. Escolha seu repositório `sistema-agendamento`
4. Clique em "Deploy Now"

### **4. CONFIGURAR BANCO POSTGRESQL**

1. No projeto Railway, clique em "New Service"
2. Selecione "Database" → "PostgreSQL"
3. Aguarde a criação do banco
4. Copie as variáveis de ambiente do PostgreSQL

### **5. CONFIGURAR VARIÁVEIS DE AMBIENTE**

No Railway, vá em "Variables" e adicione:

```env
SECRET_KEY=sua-chave-secreta-aqui
DEBUG=False
DJANGO_SETTINGS_MODULE=core.settings_production
RAILWAY_ENVIRONMENT=production
```

**As variáveis do PostgreSQL são adicionadas automaticamente pelo Railway!**

### **6. CONFIGURAR DOMÍNIO (OPCIONAL)**

1. Vá em "Settings" → "Domains"
2. Clique em "Generate Domain"
3. Copie o domínio gerado (ex: `sistema-agendamento-production.up.railway.app`)

### **7. FAZER DEPLOY**

1. O Railway fará deploy automático
2. Aguarde alguns minutos
3. Acesse seu domínio para testar

---

## 🔧 CONFIGURAÇÕES IMPORTANTES

### **Arquivos Criados:**

- ✅ `core/settings_production.py` - Configurações de produção
- ✅ `requirements.txt` - Dependências atualizadas
- ✅ `Procfile` - Comando de inicialização
- ✅ `railway.json` - Configurações do Railway
- ✅ `deploy.py` - Script de configuração
- ✅ `migrate_to_postgres.py` - Migração de dados

### **Dependências Adicionadas:**

- `psycopg2-binary` - Driver PostgreSQL
- `gunicorn` - Servidor WSGI
- `whitenoise` - Servir arquivos estáticos
- `python-decouple` - Gerenciar variáveis de ambiente

---

## 🚨 SOLUÇÃO DE PROBLEMAS

### **Erro: "No module named 'psycopg2'"
```bash
# Adicione ao requirements.txt:
psycopg2-binary==2.9.9
```

### **Erro: "Static files not found"
```bash
# Execute no Railway:
python manage.py collectstatic --noinput
```

### **Erro: "Database connection failed"
- Verifique se as variáveis do PostgreSQL estão corretas
- Confirme se o serviço PostgreSQL está rodando

### **Erro: "SECRET_KEY not set"
- Adicione a variável SECRET_KEY no Railway
- Gere uma nova chave: `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"`

---

## 📊 MONITORAMENTO

### **Logs do Railway:**
1. Vá em "Deployments"
2. Clique no deployment mais recente
3. Veja os logs em tempo real

### **Métricas:**
- CPU: Monitorado automaticamente
- Memória: Limitada a 512MB
- Uso de dados: 1GB/mês

---

## 💰 CUSTOS

### **Plano Gratuito:**
- ✅ **$0/mês**
- ✅ 500 horas de execução
- ✅ 1GB de armazenamento
- ✅ 1GB de transferência
- ✅ PostgreSQL incluído
- ✅ SSL automático

### **Quando Considerar Upgrade:**
- Mais de 500 horas/mês de uso
- Necessidade de mais armazenamento
- Suporte prioritário

---

## 🎉 PRÓXIMOS PASSOS APÓS DEPLOY

### **1. Testar Funcionalidades:**
- [ ] Login/logout
- [ ] Criar agendamento
- [ ] Cadastrar cliente
- [ ] Visualizar dashboard
- [ ] Testar relatórios

### **2. Configurar Domínio Personalizado:**
- [ ] Comprar domínio (.com.br)
- [ ] Configurar DNS no Railway
- [ ] Atualizar ALLOWED_HOSTS

### **3. Configurar Backup:**
- [ ] Backup automático do PostgreSQL
- [ ] Backup dos arquivos estáticos
- [ ] Teste de restauração

### **4. Monitoramento:**
- [ ] Configurar alertas
- [ ] Monitorar performance
- [ ] Acompanhar logs

---

## 🆘 SUPORTE

### **Documentação:**
- Railway Docs: https://docs.railway.app
- Django Deploy: https://docs.djangoproject.com/en/5.2/howto/deployment/

### **Comunidade:**
- Railway Discord: https://discord.gg/railway
- Django Forum: https://forum.djangoproject.com

---

## ✅ CHECKLIST FINAL

- [ ] Repositório no GitHub
- [ ] Conta no Railway
- [ ] Projeto criado
- [ ] PostgreSQL configurado
- [ ] Variáveis de ambiente definidas
- [ ] Deploy realizado
- [ ] Testes funcionando
- [ ] Domínio configurado
- [ ] Backup configurado

---

**🎊 PARABÉNS! Seu sistema está rodando gratuitamente no Railway!**

**URL do seu sistema:** `https://sistema-agendamento-production.up.railway.app`

---

*Guia criado para o Sistema de Agendamento - 4Minds*
