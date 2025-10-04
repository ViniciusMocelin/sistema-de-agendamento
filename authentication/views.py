from django.shortcuts import render, redirect
from django.urls import reverse_lazy
from django.contrib.auth.views import LoginView, LogoutView
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.contrib.auth.models import User
from django.contrib.auth.forms import UserCreationForm
from django.contrib import messages
from django.views.generic import (
    ListView, CreateView, UpdateView, DeleteView, 
    DetailView, TemplateView
)
from .forms import CustomUserCreationForm, CustomUserChangeForm
from django.contrib.auth import logout
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.views.decorators.http import require_POST
from .models import PreferenciasUsuario
from django.views.decorators.csrf import csrf_protect

# ========================================
# VIEWS DE AUTENTICAÇÃO
# ========================================

class CustomLoginView(LoginView):
    """View personalizada para login"""
    template_name = 'authentication/login.html'
    redirect_authenticated_user = True
    
    def get_success_url(self):
        return reverse_lazy('agendamentos:dashboard')
    
    def form_valid(self, form):
        messages.success(self.request, f'Bem-vindo, {form.get_user().first_name or form.get_user().username}!')
        return super().form_valid(form)


def custom_logout_view(request):
    """View simples para logout"""
    logout(request)
    return redirect('agendamentos:home')  # Redireciona para página inicial


class RegisterView(CreateView):
    """View para registro de novos usuários"""
    model = User
    form_class = CustomUserCreationForm
    template_name = 'authentication/register.html'
    success_url = reverse_lazy('authentication:login')
    
    def form_valid(self, form):
        messages.success(self.request, 'Usuário criado com sucesso! Faça login para continuar.')
        return super().form_valid(form)


# ========================================
# VIEWS DE GERENCIAMENTO DE USUÁRIOS
# ========================================

class UserListView(LoginRequiredMixin, UserPassesTestMixin, ListView):
    """Lista todos os usuários (apenas para admins)"""
    model = User
    template_name = 'authentication/user_list.html'
    context_object_name = 'users'
    paginate_by = 20
    
    def test_func(self):
        return self.request.user.is_staff
    
    def get_queryset(self):
        return User.objects.all().order_by('username')


class UserCreateView(LoginRequiredMixin, UserPassesTestMixin, CreateView):
    """Criar novo usuário (apenas para admins)"""
    model = User
    form_class = CustomUserCreationForm
    template_name = 'authentication/user_form.html'
    success_url = reverse_lazy('authentication:user_list')
    
    def test_func(self):
        return self.request.user.is_staff
    
    def form_valid(self, form):
        messages.success(self.request, 'Usuário criado com sucesso!')
        return super().form_valid(form)


class UserUpdateView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    """Atualizar usuário (apenas para admins)"""
    model = User
    form_class = CustomUserChangeForm
    template_name = 'authentication/user_form.html'
    success_url = reverse_lazy('authentication:user_list')
    
    def test_func(self):
        return self.request.user.is_staff
    
    def form_valid(self, form):
        messages.success(self.request, 'Usuário atualizado com sucesso!')
        return super().form_valid(form)


class UserDeleteView(LoginRequiredMixin, UserPassesTestMixin, DeleteView):
    """Deletar usuário (apenas para admins)"""
    model = User
    template_name = 'authentication/user_confirm_delete.html'
    success_url = reverse_lazy('authentication:user_list')
    
    def test_func(self):
        return self.request.user.is_staff
    
    def delete(self, request, *args, **kwargs):
        messages.success(request, 'Usuário deletado com sucesso!')
        return super().delete(request, *args, **kwargs)


class UserDetailView(LoginRequiredMixin, UserPassesTestMixin, DetailView):
    """Detalhes do usuário (apenas para admins)"""
    model = User
    template_name = 'authentication/user_detail.html'
    context_object_name = 'user_detail'
    
    def test_func(self):
        return self.request.user.is_staff


# ========================================
# VIEWS DE PERFIL
# ========================================

class ProfileView(LoginRequiredMixin, DetailView):
    """Visualizar perfil do usuário logado"""
    model = User
    template_name = 'authentication/profile.html'
    context_object_name = 'user_profile'
    
    def get_object(self):
        return self.request.user


class ProfileUpdateView(LoginRequiredMixin, UpdateView):
    """Atualizar perfil do usuário logado"""
    model = User
    fields = ['first_name', 'last_name', 'email']
    template_name = 'authentication/profile_update.html'
    success_url = reverse_lazy('authentication:profile')
    
    def get_object(self):
        return self.request.user
    
    def form_valid(self, form):
        messages.success(self.request, 'Perfil atualizado com sucesso!')
        return super().form_valid(form)
    

@login_required
@require_POST
def alterar_tema(request):
    """AJAX para alterar tema do usuário"""
    tema = request.POST.get('tema')
    
    if tema not in ['default', 'emerald', 'sunset', 'ocean', 'purple']:
        return JsonResponse({'error': 'Tema inválido'}, status=400)
    
    preferencias = PreferenciasUsuario.get_or_create_for_user(request.user)
    preferencias.tema = tema
    preferencias.save()
    
    return JsonResponse({
        'success': True,
        'tema': tema,
        'message': f'Tema alterado para {preferencias.get_tema_display()}'
    })


@login_required
@require_POST
@csrf_protect
def alterar_modo(request):
    """AJAX para alterar modo claro/escuro"""
    try:
        modo = request.POST.get('modo')
        
        if modo not in ['light', 'dark']:
            return JsonResponse({'success': False, 'error': 'Modo inválido'}, status=400)
        
        preferencias = PreferenciasUsuario.get_or_create_for_user(request.user)
        if not preferencias:
            return JsonResponse({'success': False, 'error': 'Erro ao obter preferências'}, status=500)
        
        # CORRIGIDO: Salvar o modo atual antes de alterar
        modo_anterior = preferencias.modo
        preferencias.modo = modo
        preferencias.save()
        
        # CORRIGIDO: Mostrar mensagem baseada no novo modo
        modo_nome = 'Escuro' if modo == 'dark' else 'Claro'
        
        return JsonResponse({
            'success': True,
            'modo': modo,
            'modo_anterior': modo_anterior,
            'message': f'Modo alterado para {modo_nome} com sucesso!'
        })
        
    except Exception as e:
        return JsonResponse({'success': False, 'error': str(e)}, status=500)