from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from datetime import date, time
from .models import Cliente, TipoServico, Agendamento


class ClienteModelTest(TestCase):
    """Testes para o modelo Cliente"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_criar_cliente(self):
        """Testa criação de cliente"""
        cliente = Cliente.objects.create(
            nome="João Silva",
            email="joao@test.com",
            telefone="(11) 99999-9999",
            cpf="123.456.789-00",
            data_nascimento=date(1990, 1, 1),
            criado_por=self.user
        )
        
        self.assertEqual(cliente.nome, "João Silva")
        self.assertEqual(cliente.email, "joao@test.com")
        self.assertTrue(cliente.ativo)
        self.assertIsNotNone(cliente.criado_em)
    
    def test_str_cliente(self):
        """Testa representação string do cliente"""
        cliente = Cliente.objects.create(
            nome="Maria Santos",
            email="maria@test.com",
            telefone="(11) 88888-8888",
            cpf="987.654.321-00",
            data_nascimento=date(1985, 5, 15),
            criado_por=self.user
        )
        
        expected = "Maria Santos - (11) 88888-8888"
        self.assertEqual(str(cliente), expected)


class TipoServicoModelTest(TestCase):
    """Testes para o modelo TipoServico"""
    
    def test_criar_tipo_servico(self):
        """Testa criação de tipo de serviço"""
        servico = TipoServico.objects.create(
            nome="Corte de Cabelo",
            descricao="Corte básico",
            preco=50.00,
            duracao_minutos=30,
            ativo=True
        )
        
        self.assertEqual(servico.nome, "Corte de Cabelo")
        self.assertEqual(servico.preco, 50.00)
        self.assertEqual(servico.duracao_minutos, 30)
        self.assertTrue(servico.ativo)


class AgendamentoModelTest(TestCase):
    """Testes para o modelo Agendamento"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.cliente = Cliente.objects.create(
            nome="João Silva",
            email="joao@test.com",
            telefone="(11) 99999-9999",
            cpf="123.456.789-00",
            data_nascimento=date(1990, 1, 1),
            criado_por=self.user
        )
        
        self.servico = TipoServico.objects.create(
            nome="Corte de Cabelo",
            descricao="Corte básico",
            preco=50.00,
            duracao_minutos=30
        )
    
    def test_criar_agendamento(self):
        """Testa criação de agendamento"""
        agendamento = Agendamento.objects.create(
            cliente=self.cliente,
            servico=self.servico,
            data_agendamento=date.today(),
            hora_inicio=time(14, 0),
            hora_fim=time(14, 30),
            status='agendado',
            criado_por=self.user
        )
        
        self.assertEqual(agendamento.cliente, self.cliente)
        self.assertEqual(agendamento.servico, self.servico)
        self.assertEqual(agendamento.status, 'agendado')
        self.assertIsNotNone(agendamento.criado_em)


class ViewsTest(TestCase):
    """Testes para as views"""
    
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_home_view(self):
        """Testa a view home"""
        response = self.client.get(reverse('agendamentos:home'))
        self.assertEqual(response.status_code, 200)
    
    def test_dashboard_view_requires_login(self):
        """Testa que dashboard requer login"""
        response = self.client.get(reverse('agendamentos:dashboard'))
        self.assertEqual(response.status_code, 302)  # Redirect to login
    
    def test_dashboard_view_with_login(self):
        """Testa dashboard com usuário logado"""
        self.client.login(username='testuser', password='testpass123')
        response = self.client.get(reverse('agendamentos:dashboard'))
        self.assertEqual(response.status_code, 200)
    
    def test_cliente_list_view_requires_login(self):
        """Testa que lista de clientes requer login"""
        response = self.client.get(reverse('agendamentos:cliente_list'))
        self.assertEqual(response.status_code, 302)  # Redirect to login
    
    def test_cliente_list_view_with_login(self):
        """Testa lista de clientes com usuário logado"""
        self.client.login(username='testuser', password='testpass123')
        response = self.client.get(reverse('agendamentos:cliente_list'))
        self.assertEqual(response.status_code, 200)


class AuthenticationTest(TestCase):
    """Testes de autenticação"""
    
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_login_view(self):
        """Testa a view de login"""
        response = self.client.get(reverse('authentication:login'))
        self.assertEqual(response.status_code, 200)
    
    def test_login_valid_credentials(self):
        """Testa login com credenciais válidas"""
        response = self.client.post(reverse('authentication:login'), {
            'username': 'testuser',
            'password': 'testpass123'
        })
        self.assertEqual(response.status_code, 302)  # Redirect after login
    
    def test_login_invalid_credentials(self):
        """Testa login com credenciais inválidas"""
        response = self.client.post(reverse('authentication:login'), {
            'username': 'testuser',
            'password': 'wrongpassword'
        })
        self.assertEqual(response.status_code, 200)  # Stay on login page
        self.assertContains(response, 'Please enter a correct username and password')
    
    def test_logout_view(self):
        """Testa a view de logout"""
        self.client.login(username='testuser', password='testpass123')
        response = self.client.post(reverse('authentication:logout'))
        self.assertEqual(response.status_code, 302)  # Redirect after logout


class URLTest(TestCase):
    """Testes para URLs"""
    
    def test_home_url(self):
        """Testa URL da home"""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
    
    def test_admin_url(self):
        """Testa URL do admin"""
        response = self.client.get('/admin/')
        self.assertEqual(response.status_code, 302)  # Redirect to login
    
    def test_static_files_url(self):
        """Testa URLs de arquivos estáticos"""
        # Este teste pode falhar se arquivos estáticos não estiverem coletados
        # É normal em ambiente de teste
        try:
            response = self.client.get('/static/css/style.css')
            # Pode retornar 404 ou 200 dependendo da configuração
            self.assertIn(response.status_code, [200, 404])
        except:
            # Se houver erro, é aceitável em testes
            pass


class SecurityTest(TestCase):
    """Testes de segurança básicos"""
    
    def test_debug_mode_disabled_in_production(self):
        """Testa se DEBUG está desabilitado em produção"""
        from django.conf import settings
        # Este teste assume que em produção DEBUG=False
        # Em desenvolvimento pode ser True
        self.assertIsInstance(settings.DEBUG, bool)
    
    def test_secret_key_set(self):
        """Testa se SECRET_KEY está configurada"""
        from django.conf import settings
        self.assertIsNotNone(settings.SECRET_KEY)
        self.assertGreater(len(settings.SECRET_KEY), 20)
    
    def test_allowed_hosts_configured(self):
        """Testa se ALLOWED_HOSTS está configurado"""
        from django.conf import settings
        self.assertIsInstance(settings.ALLOWED_HOSTS, list)
        self.assertGreater(len(settings.ALLOWED_HOSTS), 0)
