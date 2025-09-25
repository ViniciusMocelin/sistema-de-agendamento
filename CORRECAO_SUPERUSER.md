# 🔧 Correção do Superuser em Produção

## 🚨 Problema Identificado
As credenciais do superuser `@4minds` não estão funcionando em produção.

## 🎯 Soluções Disponíveis

### 🚀 **Solução 1: Script Automatizado (Recomendado)**

Execute um dos scripts abaixo para corrigir automaticamente:

#### **Windows:**
```cmd
scripts\fix-superuser-production.bat
```

#### **Linux/macOS:**
```bash
chmod +x scripts/fix-superuser-production.sh
./scripts/fix-superuser-production.sh
```

### 🔧 **Solução 2: Correção Manual via SSH**

#### **Passo 1: Conectar na EC2**
```bash
ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_EC2]
```

#### **Passo 2: Executar Script de Correção**
```bash
cd /home/django/sistema-agendamento
source venv/bin/activate
python scripts/diagnose-and-fix-user.py
```

#### **Passo 3: Ou Correção Rápida**
```bash
chmod +x scripts/quick-fix-user.sh
./scripts/quick-fix-user.sh
```

### 🛠️ **Solução 3: Comando Django Direto**

#### **Via SSH:**
```bash
cd /home/django/sistema-agendamento
source venv/bin/activate
python manage.py create_4minds_superuser --force --no-input
```

#### **Ou Recriar Completamente:**
```bash
python manage.py shell
```

```python
from django.contrib.auth import get_user_model
User = get_user_model()

# Deletar usuário existente (se houver)
User.objects.filter(username='@4minds').delete()

# Criar novo usuário
user = User.objects.create_superuser(
    username='@4minds',
    email='admin@4minds.com',
    password='@4mindsPassword'
)

print("✅ Usuário criado com sucesso!")
exit()
```

---

## 🔍 **Diagnóstico Manual**

Se quiser verificar o que está acontecendo:

### **1. Verificar se usuário existe:**
```bash
python manage.py shell
```

```python
from django.contrib.auth import get_user_model
User = get_user_model()

user = User.objects.filter(username='@4minds').first()
if user:
    print(f"Usuário encontrado: {user.username}")
    print(f"É superuser: {user.is_superuser}")
    print(f"É staff: {user.is_staff}")
    print(f"Está ativo: {user.is_active}")
    print(f"Senha correta: {user.check_password('@4mindsPassword')}")
else:
    print("Usuário não encontrado!")
```

### **2. Listar todos os usuários:**
```python
for user in User.objects.all():
    print(f"{user.username} - Superuser: {user.is_superuser}, Staff: {user.is_staff}, Ativo: {user.is_active}")
```

### **3. Testar autenticação:**
```python
from django.contrib.auth import authenticate
user = authenticate(username='@4minds', password='@4mindsPassword')
print(f"Autenticação: {'Sucesso' if user else 'Falhou'}")
```

---

## 🚨 **Possíveis Causas do Problema**

### **1. Usuário não foi criado**
- **Solução:** Execute qualquer um dos scripts acima

### **2. Senha incorreta**
- **Solução:** Scripts corrigem automaticamente

### **3. Usuário não é superuser/staff**
- **Solução:** Scripts definem permissões corretas

### **4. Usuário está inativo**
- **Solução:** Scripts ativam o usuário

### **5. Problema no banco de dados**
- **Solução:** Recriar usuário completamente

### **6. Cache de sessão**
- **Solução:** Limpar cache do navegador ou usar modo incógnito

---

## 🔄 **Após a Correção**

### **1. Reiniciar Serviços (se necessário):**
```bash
sudo systemctl restart django
sudo systemctl restart nginx
```

### **2. Testar Login:**
- Acesse: `http://[IP_DA_EC2]/admin/`
- Usuário: `@4minds`
- Senha: `@4mindsPassword`

### **3. Verificar Logs:**
```bash
sudo journalctl -u django -f
```

---

## 📋 **Checklist de Verificação**

Após executar a correção, verifique:

- [ ] ✅ Usuário `@4minds` existe no banco
- [ ] ✅ Usuário é superuser (`is_superuser=True`)
- [ ] ✅ Usuário é staff (`is_staff=True`)
- [ ] ✅ Usuário está ativo (`is_active=True`)
- [ ] ✅ Senha `@4mindsPassword` funciona
- [ ] ✅ Login no admin funciona
- [ ] ✅ Acesso total ao Django Admin

---

## 🆘 **Se Nada Funcionar**

### **Última Opção - Reset Completo:**

```bash
cd /home/django/sistema-agendamento
source venv/bin/activate
python manage.py shell
```

```python
from django.contrib.auth import get_user_model
User = get_user_model()

# Deletar TODOS os usuários (CUIDADO!)
User.objects.all().delete()

# Criar novo superuser
user = User.objects.create_superuser(
    username='@4minds',
    email='admin@4minds.com',
    password='@4mindsPassword'
)

print("✅ Sistema resetado - usuário criado!")
exit()
```

---

## 📞 **Suporte**

Se ainda houver problemas:

1. **Verifique os logs:** `sudo journalctl -u django -f`
2. **Teste em modo incógnito**
3. **Limpe cache do navegador**
4. **Verifique se o banco está acessível**
5. **Confirme que o Django está rodando**

---

**🎉 Com essas soluções, o superuser da 4Minds deve funcionar perfeitamente!**

*Documento criado para resolver problema de credenciais - Sistema de Agendamento v1.0*
