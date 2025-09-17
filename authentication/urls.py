from django.urls import path
from . import views

app_name = 'authentication'

urlpatterns = [
    # Autenticação
    path('login/', views.CustomLoginView.as_view(), name='login'),
    path('logout/', views.custom_logout_view, name='logout'),  # Mudança aqui
    path('register/', views.RegisterView.as_view(), name='register'),
    
    # Gerenciamento de usuários (admin)
    path('users/', views.UserListView.as_view(), name='user_list'),
    path('users/create/', views.UserCreateView.as_view(), name='user_create'),
    path('users/<int:pk>/update/', views.UserUpdateView.as_view(), name='user_update'),
    path('users/<int:pk>/delete/', views.UserDeleteView.as_view(), name='user_delete'),
    path('users/<int:pk>/detail/', views.UserDetailView.as_view(), name='user_detail'),
    
    # Perfil do usuário
    path('profile/', views.ProfileView.as_view(), name='profile'),
    path('profile/update/', views.ProfileUpdateView.as_view(), name='profile_update'),

    # Preferencias do Usuario
    path('ajax/alterar-tema/', views.alterar_tema, name='alterar_tema'),
    path('ajax/alterar-modo/', views.alterar_modo, name='alterar_modo'),
]