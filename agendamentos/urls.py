from django.urls import path
from . import views

app_name = 'agendamentos'

urlpatterns = [
    # Páginas principais
    path('', views.HomeView.as_view(), name='home'),
    path('dashboard/', views.DashboardView.as_view(), name='dashboard'),
    
    # Clientes
    path('clientes/', views.ClienteListView.as_view(), name='cliente_list'),
    path('clientes/criar/', views.ClienteCreateView.as_view(), name='cliente_create'),
    path('clientes/<int:pk>/', views.ClienteDetailView.as_view(), name='cliente_detail'),
    path('clientes/<int:pk>/editar/', views.ClienteUpdateView.as_view(), name='cliente_update'),
    path('clientes/<int:pk>/deletar/', views.ClienteDeleteView.as_view(), name='cliente_delete'),
    
    # Serviços
    path('servicos/', views.TipoServicoListView.as_view(), name='servico_list'),
    path('servicos/criar/', views.TipoServicoCreateView.as_view(), name='servico_create'),
    path('servicos/<int:pk>/editar/', views.TipoServicoUpdateView.as_view(), name='servico_update'),
    path('servicos/<int:pk>/deletar/', views.TipoServicoDeleteView.as_view(), name='servico_delete'),
    
    # Agendamentos
    path('agendamentos/', views.AgendamentoListView.as_view(), name='agendamento_list'),
    path('agendamentos/criar/', views.AgendamentoCreateView.as_view(), name='agendamento_create'),
    path('agendamentos/<int:pk>/', views.AgendamentoDetailView.as_view(), name='agendamento_detail'),
    path('agendamentos/<int:pk>/editar/', views.AgendamentoUpdateView.as_view(), name='agendamento_update'),
    path('agendamentos/<int:pk>/deletar/', views.AgendamentoDeleteView.as_view(), name='agendamento_delete'),
    path('agendamentos/<int:pk>/status/', views.AgendamentoStatusUpdateView.as_view(), name='agendamento_status'),

    # Relatorios
    path('relatorios/', views.RelatoriosView.as_view(), name='relatorios'),
    
    
    # Configurações
    path('configuracoes/', views.ConfiguracaoView.as_view(), name='configuracoes'),
]