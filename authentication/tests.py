from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from django.contrib.auth import get_user_model
from .models import PreferenciasUsuario


class UserModelTest(TestCase):
    """Testes para o modelo User"""
    
    def test_create_user(self):
        """Testa criação de usuário"""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        
        self.assertEqual(user.username, 'testuser')
        self.assertEqual(user.email, 'test@example.com')
        self.assertEqual(user.first_name, 'Test')
        self.assertEqual(user.last_name, 'User')
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)
    
    def test_create_superuser(self):
        """Testa criação de superusuário"""
        user = User.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='adminpass123'
        )
        
        self.assertEqual(user.username, 'admin')
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)


class PreferenciasUsuarioModelTest(TestCase):
    """Testes para o modelo PreferenciasUsuario"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_preferencias(self):
        """Testa criação de preferências"""
        preferencias = PreferenciasUsuario.objects.create(
            usuario=self.user,
            tema='emerald',
            modo='dark'
        )
        
        self.assertEqual(preferencias.usuario, self.user)
        self.assertEqual(preferencias.tema, 'emerald')
        self.assertEqual(preferencias.modo, 'dark')
        self.assertIsNotNone(preferencias.criado_em)
    
    def test_get_or_create_for_user(self):
        """Testa método get_or_create_for_user"""
        # Primeira chamada cria
        preferencias = PreferenciasUsuario.get_or_create_for_user(self.user)
        self.assertIsNotNone(preferencias)
        self.assertEqual(preferencias.usuario, self.user)
        
        # Segunda chamada retorna existente
        preferencias2 = PreferenciasUsuario.get_or_create_for_user(self.user)
        self.assertEqual(preferencias.id, preferencias2.id)
    
    def test_str_preferencias(self):
        """Testa representação string das preferências"""
        preferencias = PreferenciasUsuario.objects.create(
            usuario=self.user,
            tema='sunset',
            modo='light'
        )
        
        expected = f"{self.user.username} - Verde Esmeralda (Claro)"
        self.assertEqual(str(preferencias), expected)


class AuthenticationViewsTest(TestCase):
    """Testes para as views de autenticação"""
    
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_login_view_get(self):
        """Testa GET na view de login"""
        response = self.client.get(reverse('authentication:login'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'login')
    
    def test_login_view_post_valid(self):
        """Testa POST na view de login com credenciais válidas"""
        response = self.client.post(reverse('authentication:login'), {
            'username': 'testuser',
            'password': 'testpass123'
        })
        self.assertEqual(response.status_code, 302)  # Redirect after login
    
    def test_login_view_post_invalid(self):
        """Testa POST na view de login com credenciais inválidas"""
        response = self.client.post(reverse('authentication:login'), {
            'username': 'testuser',
            'password': 'wrongpassword'
        })
        self.assertEqual(response.status_code, 200)  # Stay on login page
    
    def test_logout_view(self):
        """Testa view de logout"""
        # Login primeiro
        self.client.login(username='testuser', password='testpass123')
        
        # Logout
        response = self.client.post(reverse('authentication:logout'))
        self.assertEqual(response.status_code, 302)  # Redirect after logout
    
    def test_register_view_get(self):
        """Testa GET na view de registro"""
        response = self.client.get(reverse('authentication:register'))
        self.assertEqual(response.status_code, 200)
    
    def test_register_view_post(self):
        """Testa POST na view de registro"""
        response = self.client.post(reverse('authentication:register'), {
            'username': 'newuser',
            'first_name': 'New',
            'last_name': 'User',
            'email': 'newuser@example.com',
            'password1': 'newpass123',
            'password2': 'newpass123'
        })
        
        # Verifica se usuário foi criado
        self.assertTrue(User.objects.filter(username='newuser').exists())
        
        # Verifica se foi redirecionado após registro
        self.assertEqual(response.status_code, 302)
    
    def test_profile_view_requires_login(self):
        """Testa que perfil requer login"""
        response = self.client.get(reverse('authentication:profile'))
        self.assertEqual(response.status_code, 302)  # Redirect to login
    
    def test_profile_view_with_login(self):
        """Testa perfil com usuário logado"""
        self.client.login(username='testuser', password='testpass123')
        response = self.client.get(reverse('authentication:profile'))
        self.assertEqual(response.status_code, 200)


class AuthenticationFormsTest(TestCase):
    """Testes para os formulários de autenticação"""
    
    def test_custom_user_creation_form(self):
        """Testa formulário de criação de usuário"""
        from .forms import CustomUserCreationForm
        
        form_data = {
            'username': 'newuser',
            'first_name': 'New',
            'last_name': 'User',
            'email': 'newuser@example.com',
            'password1': 'newpass123',
            'password2': 'newpass123'
        }
        
        form = CustomUserCreationForm(data=form_data)
        self.assertTrue(form.is_valid())
        
        user = form.save()
        self.assertEqual(user.username, 'newuser')
        self.assertEqual(user.email, 'newuser@example.com')
    
    def test_custom_user_creation_form_invalid(self):
        """Testa formulário de criação com dados inválidos"""
        from .forms import CustomUserCreationForm
        
        form_data = {
            'username': 'newuser',
            'email': 'invalid-email',
            'password1': 'pass123',
            'password2': 'different123'
        }
        
        form = CustomUserCreationForm(data=form_data)
        self.assertFalse(form.is_valid())


class AuthenticationSecurityTest(TestCase):
    """Testes de segurança para autenticação"""
    
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_password_validation(self):
        """Testa validação de senha"""
        from django.contrib.auth.password_validation import validate_password
        from django.core.exceptions import ValidationError
        
        # Senha muito curta
        with self.assertRaises(ValidationError):
            validate_password('123')
        
        # Senha comum
        with self.assertRaises(ValidationError):
            validate_password('password')
    
    def test_csrf_protection(self):
        """Testa proteção CSRF"""
        # Testa que formulários têm token CSRF
        response = self.client.get(reverse('authentication:login'))
        self.assertContains(response, 'csrfmiddlewaretoken')
    
    def test_session_security(self):
        """Testa segurança de sessão"""
        self.client.login(username='testuser', password='testpass123')
        
        # Verifica se sessão foi criada
        self.assertTrue('_auth_user_id' in self.client.session)
        
        # Logout e verifica se sessão foi limpa
        self.client.post(reverse('authentication:logout'))
        self.assertFalse('_auth_user_id' in self.client.session)


class AuthenticationIntegrationTest(TestCase):
    """Testes de integração para autenticação"""
    
    def setUp(self):
        self.client = Client()
    
    def test_complete_auth_flow(self):
        """Testa fluxo completo de autenticação"""
        # 1. Acessar página que requer login
        response = self.client.get(reverse('agendamentos:dashboard'))
        self.assertEqual(response.status_code, 302)  # Redirect to login
        
        # 2. Fazer login
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        response = self.client.post(reverse('authentication:login'), {
            'username': 'testuser',
            'password': 'testpass123'
        })
        self.assertEqual(response.status_code, 302)  # Redirect after login
        
        # 3. Acessar página protegida
        response = self.client.get(reverse('agendamentos:dashboard'))
        self.assertEqual(response.status_code, 200)  # Success
        
        # 4. Fazer logout
        response = self.client.post(reverse('authentication:logout'))
        self.assertEqual(response.status_code, 302)  # Redirect after logout
        
        # 5. Tentar acessar página protegida novamente
        response = self.client.get(reverse('agendamentos:dashboard'))
        self.assertEqual(response.status_code, 302)  # Redirect to login again
