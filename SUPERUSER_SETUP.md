# 🔐 Configuração de Superuser - Sistema de Agendamento 4Minds

Este documento explica como criar o superuser da 4Minds em diferentes ambientes.

## 👤 Credenciais do Superuser

- **Usuário:** `@4minds`
- **Senha:** `@4mindsPassword`
- **Email:** `admin@4minds.com`

---

## 🚀 Métodos Disponíveis

### 1. Comando Django Personalizado (Recomendado)

```bash
# Em qualquer ambiente (desenvolvimento ou produção)
python manage.py create_4minds_superuser

# Sem interação (para automação)
python manage.py create_4minds_superuser --no-input

# Forçar atualização se usuário já existir
python manage.py create_4minds_superuser --force
```

**Vantagens:**
- ✅ Funciona em qualquer ambiente
- ✅ Integrado ao Django
- ✅ Verifica se usuário já existe
- ✅ Opções de força e não-interativo

### 2. Script Python Local (Desenvolvimento)

```bash
# Para ambiente de desenvolvimento local
python scripts/create-superuser-local.py
```

**Vantagens:**
- ✅ Interface amigável
- ✅ Verificações de conexão
- ✅ Executa migrações automaticamente

### 3. Script Python Produção

```bash
# Para ambiente de produção (PostgreSQL)
python scripts/create-superuser-production.py
```

**Vantagens:**
- ✅ Configurado para produção
- ✅ Verificações de segurança
- ✅ Logs detalhados

### 4. Scripts Automatizados para Produção

#### Windows (.bat)
```cmd
scripts\create-superuser-production.bat
```

#### Linux/macOS (.sh)
```bash
chmod +x scripts/create-superuser-production.sh
./scripts/create-superuser-production.sh
```

**Vantagens:**
- ✅ Verificação de infraestrutura AWS
- ✅ Conexão automática via SSH
- ✅ Deploy completo automatizado

---

## 📋 Instruções por Ambiente

### 🖥️ Desenvolvimento Local

1. **Método Simples:**
   ```bash
   python manage.py create_4minds_superuser
   ```

2. **Método com Interface:**
   ```bash
   python scripts/create-superuser-local.py
   ```

### 🌐 Produção (AWS)

#### Opção 1: Via SSH Manual
```bash
# Conectar na EC2
ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_EC2]

# Na EC2, executar:
cd /home/django/sistema-agendamento
source venv/bin/activate
python manage.py create_4minds_superuser --no-input
```

#### Opção 2: Script Automatizado
```bash
# Windows
scripts\create-superuser-production.bat

# Linux/macOS
./scripts/create-superuser-production.sh
```

#### Opção 3: Via Deploy Script
```bash
# O deploy já inclui criação do superuser
./scripts/deploy-production.sh
```

---

## 🔧 Comandos Úteis

### Verificar se Superuser Existe
```bash
python manage.py shell
>>> from django.contrib.auth import get_user_model
>>> User = get_user_model()
>>> User.objects.filter(username='@4minds').exists()
```

### Listar Todos os Superusers
```bash
python manage.py shell
>>> from django.contrib.auth import get_user_model
>>> User = get_user_model()
>>> User.objects.filter(is_superuser=True).values('username', 'email')
```

### Alterar Senha do Superuser
```bash
python manage.py shell
>>> from django.contrib.auth import get_user_model
>>> User = get_user_model()
>>> user = User.objects.get(username='@4minds')
>>> user.set_password('nova_senha')
>>> user.save()
```

---

## 🚨 Troubleshooting

### Erro: "Usuário já existe"
```bash
# Use --force para atualizar
python manage.py create_4minds_superuser --force
```

### Erro: "Não foi possível conectar ao banco"
```bash
# Verificar se banco está rodando
python manage.py dbshell

# Verificar configurações
python manage.py shell
>>> from django.conf import settings
>>> print(settings.DATABASES)
```

### Erro: "Comando não encontrado"
```bash
# Verificar se está no diretório correto
pwd
ls -la manage.py

# Verificar se Django está instalado
python -c "import django; print(django.VERSION)"
```

### Erro em Produção: "SSH Connection Failed"
```bash
# Verificar chave SSH
ls -la ~/.ssh/id_rsa

# Verificar status da EC2
aws ec2 describe-instances --instance-ids i-04d14b81170c26323

# Testar conexão SSH
ssh -i ~/.ssh/id_rsa ubuntu@[IP_DA_EC2] 'echo "SSH OK"'
```

---

## 📊 Verificação de Sucesso

Após criar o superuser, verifique:

1. **Login no Admin:**
   - Acesse: `http://[URL]/admin/`
   - Usuário: `@4minds`
   - Senha: `@4mindsPassword`

2. **Permissões:**
   - Deve ter acesso total ao Django Admin
   - Deve conseguir criar/editar/remover usuários
   - Deve conseguir acessar todos os modelos

3. **Logs:**
   ```bash
   # Verificar logs do Django
   tail -f /var/log/django/django.log
   
   # Ou via journalctl (systemd)
   sudo journalctl -u django -f
   ```

---

## 🔒 Segurança

### ⚠️ Importante:
- **NUNCA** commite senhas no código
- **SEMPRE** use variáveis de ambiente em produção
- **CONFIGURE** HTTPS em produção
- **MONITORE** logs de acesso

### Variáveis de Ambiente Recomendadas:
```bash
# .env.production
SECRET_KEY=sua_secret_key_segura
DB_PASSWORD=senha_super_segura
EMAIL_HOST_PASSWORD=senha_app_gmail
```

---

## 📞 Suporte

Em caso de problemas:

1. Verifique os logs de erro
2. Teste em ambiente de desenvolvimento primeiro
3. Consulte a documentação Django
4. Verifique a configuração do banco de dados
5. Confirme que todas as dependências estão instaladas

---

**🎉 Superuser da 4Minds configurado com sucesso!**

*Documento gerado automaticamente - Sistema de Agendamento v1.0*
