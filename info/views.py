from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import TemplateView, ListView, DetailView
from django.http import JsonResponse
from django.contrib import messages
from django.utils import timezone
from .models import CategoriaInfo, Tutorial, FAQ, ProgressoTutorial, Dica

class InfoHomeView(TemplateView):
    """Página inicial do sistema de info"""
    template_name = 'info/home.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['categorias'] = CategoriaInfo.objects.filter(ativo=True)
        context['tutoriais_populares'] = Tutorial.objects.filter(ativo=True)[:6]
        context['dicas'] = Dica.objects.filter(ativo=True)[:4]
        
        if self.request.user.is_authenticated:
            # Progresso do usuário
            total_tutoriais = Tutorial.objects.filter(ativo=True).count()
            concluidos = ProgressoTutorial.objects.filter(
                usuario=self.request.user, 
                concluido=True
            ).count()
            context['progresso_geral'] = round((concluidos / total_tutoriais * 100), 1) if total_tutoriais > 0 else 0
            context['tutoriais_concluidos'] = concluidos
            context['total_tutoriais'] = total_tutoriais
        
        return context

class TutoriaisView(ListView):
    """Lista de tutoriais por categoria"""
    model = Tutorial
    template_name = 'info/tutoriais.html'
    context_object_name = 'tutoriais'
    paginate_by = 12
    
    def get_queryset(self):
        queryset = Tutorial.objects.filter(ativo=True)
        categoria_id = self.request.GET.get('categoria')
        tipo = self.request.GET.get('tipo')
        
        if categoria_id:
            queryset = queryset.filter(categoria_id=categoria_id)
        if tipo:
            queryset = queryset.filter(tipo=tipo)
            
        return queryset.order_by('categoria', 'ordem')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['categorias'] = CategoriaInfo.objects.filter(ativo=True)
        context['categoria_selecionada'] = self.request.GET.get('categoria')
        context['tipo_selecionado'] = self.request.GET.get('tipo')
        
        if self.request.user.is_authenticated:
            # Tutoriais concluídos pelo usuário
            concluidos_ids = ProgressoTutorial.objects.filter(
                usuario=self.request.user,
                concluido=True
            ).values_list('tutorial_id', flat=True)
            context['tutoriais_concluidos'] = list(concluidos_ids)
        
        return context

class TutorialDetailView(DetailView):
    """Detalhes de um tutorial específico"""
    model = Tutorial
    template_name = 'info/tutorial_detail.html'
    context_object_name = 'tutorial'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        if self.request.user.is_authenticated:
            # Verificar se usuário já concluiu
            progresso, created = ProgressoTutorial.objects.get_or_create(
                usuario=self.request.user,
                tutorial=self.object
            )
            context['progresso'] = progresso
            
            # Próximo tutorial
            proximo = Tutorial.objects.filter(
                categoria=self.object.categoria,
                ordem__gt=self.object.ordem,
                ativo=True
            ).first()
            context['proximo_tutorial'] = proximo
            
            # Tutorial anterior
            anterior = Tutorial.objects.filter(
                categoria=self.object.categoria,
                ordem__lt=self.object.ordem,
                ativo=True
            ).last()
            context['tutorial_anterior'] = anterior
        
        return context

class FAQView(ListView):
    """Lista de perguntas frequentes"""
    model = FAQ
    template_name = 'info/faq.html'
    context_object_name = 'faqs'
    
    def get_queryset(self):
        queryset = FAQ.objects.filter(ativo=True)
        categoria_id = self.request.GET.get('categoria')
        busca = self.request.GET.get('q')
        
        if categoria_id:
            queryset = queryset.filter(categoria_id=categoria_id)
        if busca:
            queryset = queryset.filter(
                pergunta__icontains=busca
            ) | queryset.filter(
                resposta__icontains=busca
            )
            
        return queryset.order_by('categoria', 'ordem')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['categorias'] = CategoriaInfo.objects.filter(ativo=True)
        context['categoria_selecionada'] = self.request.GET.get('categoria')
        context['busca'] = self.request.GET.get('q', '')
        return context

class GuiaCompletoView(TemplateView):
    """Guia completo do sistema"""
    template_name = 'info/guia_completo.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        # Estrutura do sistema atual
        context['estrutura_sistema'] = {
            'autenticacao': {
                'titulo': 'Sistema de Autenticação',
                'descricao': 'Controle de acesso e perfis de usuário',
                'funcionalidades': [
                    'Login/Logout seguro',
                    'Registro de novos usuários',
                    'Gerenciamento de perfis',
                    'Controle de permissões'
                ]
            },
            'agendamentos': {
                'titulo': 'Gestão de Agendamentos',
                'descricao': 'Core do sistema para controle de agendamentos',
                'funcionalidades': [
                    'Criar novos agendamentos',
                    'Editar agendamentos existentes',
                    'Controle de status (Agendado, Confirmado, Em Andamento, Concluído, Cancelado)',
                    'Visualização em lista e detalhes',
                    'Filtros avançados por data, cliente, serviço',
                    'Validação de conflitos de horário'
                ]
            },
            'clientes': {
                'titulo': 'Gestão de Clientes',
                'descricao': 'Cadastro e controle de clientes',
                'funcionalidades': [
                    'Cadastro completo de clientes',
                    'Histórico de agendamentos',
                    'Informações de contato',
                    'Busca e filtros',
                    'Estatísticas por cliente'
                ]
            },
            'servicos': {
                'titulo': 'Gestão de Serviços',
                'descricao': 'Catálogo de serviços oferecidos',
                'funcionalidades': [
                    'Cadastro de serviços',
                    'Definição de preços e duração',
                    'Categorização de serviços',
                    'Controle de disponibilidade'
                ]
            },
            'relatorios': {
                'titulo': 'Relatórios e BI',
                'descricao': 'Business Intelligence e análises',
                'funcionalidades': [
                    'Dashboard com KPIs',
                    'Gráficos interativos',
                    'Análise de faturamento',
                    'Relatórios de clientes frequentes',
                    'Análise de serviços mais procurados',
                    'Métricas de crescimento'
                ]
            }
        }
        
        return context

class DemonstracaoView(TemplateView):
    """Demonstração interativa do sistema"""
    template_name = 'info/demonstracao.html'

def marcar_tutorial_concluido(request, tutorial_id):
    """AJAX para marcar tutorial como concluído"""
    if not request.user.is_authenticated:
        return JsonResponse({'error': 'Usuário não autenticado'}, status=401)
    
    tutorial = get_object_or_404(Tutorial, id=tutorial_id)
    progresso, created = ProgressoTutorial.objects.get_or_create(
        usuario=request.user,
        tutorial=tutorial
    )
    
    progresso.concluido = True
    progresso.data_conclusao = timezone.now()
    progresso.save()
    
    return JsonResponse({
        'success': True,
        'message': 'Tutorial marcado como concluído!'
    })

def incrementar_visualizacao_faq(request, faq_id):
    """AJAX para incrementar visualizações do FAQ"""
    faq = get_object_or_404(FAQ, id=faq_id)
    faq.visualizacoes += 1
    faq.save()
    
    return JsonResponse({'success': True})