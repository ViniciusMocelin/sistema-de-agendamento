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


class CustomLogoutView(LogoutView):
    """View personalizada para logout"""
    next_page = reverse_lazy('authentication:login')
    
    def dispatch(self, request, *args, **kwargs):
        if request.user.is_authenticated:
            messages.info(request, 'Logout realizado com sucesso!')
        return super().dispatch(request, *args, **kwargs)


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