from django.shortcuts import render, redirect, get_object_or_404
from django.urls import reverse_lazy
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.views.generic import (
    TemplateView, ListView, CreateView, UpdateView, 
    DeleteView, DetailView
)
from django.db.models import Q, Count
from django.utils import timezone
from django.http import JsonResponse
from datetime import datetime, timedelta

from .models import Cliente, TipoServico, Agendamento, StatusAgendamento
from .forms import ClienteForm, TipoServicoForm, AgendamentoForm, AgendamentoStatusForm

# ========================================
# VIEWS PRINCIPAIS
# ========================================

class HomeView(TemplateView):
    """View da página inicial (pública)"""
    template_name = 'agendamentos/home.html'


class DashboardView(LoginRequiredMixin, TemplateView):
    """View do dashboard (apenas usuários logados)"""
    template_name = 'agendamentos/dashboard.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        user = self.request.user
        hoje = timezone.now().date()

        context['today'] = hoje.strftime('%Y-%m-%d')
        
        # Estatísticas gerais
        context['total_clientes'] = Cliente.objects.filter(criado_por=user, ativo=True).count()
        context['total_servicos'] = TipoServico.objects.filter(criado_por=user, ativo=True).count()
        
        # Agendamentos de hoje
        agendamentos_hoje = Agendamento.objects.filter(
            criado_por=user,
            data_agendamento=hoje
        ).exclude(status='cancelado')
        context['agendamentos_hoje'] = agendamentos_hoje.count()
        
        # Agendamentos desta semana
        inicio_semana = hoje - timedelta(days=hoje.weekday())
        fim_semana = inicio_semana + timedelta(days=6)
        context['agendamentos_semana'] = Agendamento.objects.filter(
            criado_por=user,
            data_agendamento__range=[inicio_semana, fim_semana]
        ).exclude(status='cancelado').count()
        
        # Agendamentos pendentes de confirmação
        context['agendamentos_pendentes'] = Agendamento.objects.filter(
            criado_por=user,
            status='agendado',
            data_agendamento__gte=hoje
        ).count()
        
        # Próximos agendamentos (próximos 7 dias)
        proximos_agendamentos = Agendamento.objects.filter(
            criado_por=user,
            data_agendamento__range=[hoje, hoje + timedelta(days=7)]
        ).exclude(status__in=['cancelado', 'concluido']).order_by('data_agendamento', 'hora_inicio')[:5]
        context['proximos_agendamentos'] = proximos_agendamentos
        
        # Estatísticas do mês
        inicio_mes = hoje.replace(day=1)
        context['agendamentos_mes_realizados'] = Agendamento.objects.filter(
            criado_por=user,
            data_agendamento__gte=inicio_mes,
            status='concluido'
        ).count()
        
        context['agendamentos_mes_cancelados'] = Agendamento.objects.filter(
            criado_por=user,
            data_agendamento__gte=inicio_mes,
            status__in=['cancelado', 'nao_compareceu']
        ).count()
        
        # Taxa de comparecimento
        total_mes = Agendamento.objects.filter(
            criado_por=user,
            data_agendamento__gte=inicio_mes,
            data_agendamento__lt=hoje
        ).count()
        
        if total_mes > 0:
            context['taxa_comparecimento'] = round(
                (context['agendamentos_mes_realizados'] / total_mes) * 100, 1
            )
        else:
            context['taxa_comparecimento'] = 0
        
        return context


# ========================================
# VIEWS DE CLIENTES
# ========================================

class ClienteListView(LoginRequiredMixin, ListView):
    """Lista todos os clientes do usuário"""
    model = Cliente
    template_name = 'agendamentos/cliente_list.html'
    context_object_name = 'clientes'
    paginate_by = 20
    
    def get_queryset(self):
        queryset = Cliente.objects.filter(criado_por=self.request.user)
        
        # Filtro de busca
        search = self.request.GET.get('search')
        if search:
            queryset = queryset.filter(
                Q(nome__icontains=search) |
                Q(email__icontains=search) |
                Q(telefone__icontains=search) |
                Q(cpf__icontains=search)
            )
        
        # Filtro de status
        status = self.request.GET.get('status')
        if status == 'ativo':
            queryset = queryset.filter(ativo=True)
        elif status == 'inativo':
            queryset = queryset.filter(ativo=False)
        
        return queryset.order_by('nome')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['search'] = self.request.GET.get('search', '')
        context['status'] = self.request.GET.get('status', '')
        context['total_clientes'] = self.get_queryset().count()
        return context


class ClienteCreateView(LoginRequiredMixin, CreateView):
    """Criar novo cliente"""
    model = Cliente
    form_class = ClienteForm
    template_name = 'agendamentos/cliente_form.html'
    success_url = reverse_lazy('agendamentos:cliente_list')
    
    def form_valid(self, form):
        form.instance.criado_por = self.request.user
        messages.success(self.request, f'Cliente "{form.instance.nome}" criado com sucesso!')
        return super().form_valid(form)
    
    def form_invalid(self, form):
        messages.error(self.request, 'Erro ao criar cliente. Verifique os dados informados.')
        return super().form_invalid(form)


class ClienteDetailView(LoginRequiredMixin, DetailView):
    """Detalhes do cliente"""
    model = Cliente
    template_name = 'agendamentos/cliente_detail.html'
    context_object_name = 'cliente'
    
    def get_queryset(self):
        return Cliente.objects.filter(criado_por=self.request.user)
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        cliente = self.get_object()
        
        # Histórico de agendamentos
        context['agendamentos'] = Agendamento.objects.filter(
            cliente=cliente
        ).order_by('-data_agendamento', '-hora_inicio')[:10]
        
        # Estatísticas do cliente
        context['total_agendamentos'] = Agendamento.objects.filter(cliente=cliente).count()
        context['agendamentos_concluidos'] = Agendamento.objects.filter(
            cliente=cliente, status='concluido'
        ).count()
        context['agendamentos_cancelados'] = Agendamento.objects.filter(
            cliente=cliente, status__in=['cancelado', 'nao_compareceu']
        ).count()
        
        # Taxa de comparecimento
        if context['total_agendamentos'] > 0:
            context['taxa_comparecimento'] = round(
                (context['agendamentos_concluidos'] / context['total_agendamentos']) * 100, 1
            )
        else:
            context['taxa_comparecimento'] = 0
        
        # Informações financeiras
        agendamentos_concluidos = Agendamento.objects.filter(
            cliente=cliente, status='concluido'
        )
        
        if agendamentos_concluidos.exists():
            valores = []
            for agendamento in agendamentos_concluidos:
                valor = agendamento.valor_cobrado or agendamento.servico.preco
                valores.append(valor)
            
            context['total_faturado'] = sum(valores)
            context['ticket_medio'] = context['total_faturado'] / len(valores)
            
            # Última visita
            context['ultima_visita'] = agendamentos_concluidos.order_by('-data_agendamento').first().data_agendamento
        else:
            context['total_faturado'] = 0
            context['ticket_medio'] = 0
            context['ultima_visita'] = None
        
        return context


class ClienteUpdateView(LoginRequiredMixin, UpdateView):
    """Editar cliente"""
    model = Cliente
    form_class = ClienteForm
    template_name = 'agendamentos/cliente_form.html'
    success_url = reverse_lazy('agendamentos:cliente_list')
    
    def get_queryset(self):
        return Cliente.objects.filter(criado_por=self.request.user)
    
    def form_valid(self, form):
        messages.success(self.request, f'Cliente "{form.instance.nome}" atualizado com sucesso!')
        return super().form_valid(form)
    
    def form_invalid(self, form):
        messages.error(self.request, 'Erro ao atualizar cliente. Verifique os dados informados.')
        return super().form_invalid(form)


class ClienteDeleteView(LoginRequiredMixin, DeleteView):
    """Deletar cliente"""
    model = Cliente
    template_name = 'agendamentos/cliente_confirm_delete.html'
    success_url = reverse_lazy('agendamentos:cliente_list')
    context_object_name = 'cliente'
    
    def get_queryset(self):
        return Cliente.objects.filter(criado_por=self.request.user)
    
    def delete(self, request, *args, **kwargs):
        cliente = self.get_object()
        
        # Verificar se há agendamentos futuros
        agendamentos_futuros = Agendamento.objects.filter(
            cliente=cliente,
            data_agendamento__gte=timezone.now().date(),
            status__in=['agendado', 'confirmado']
        ).count()
        
        if agendamentos_futuros > 0:
            messages.error(
                request, 
                f'Não é possível excluir o cliente "{cliente.nome}" pois há {agendamentos_futuros} agendamento(s) futuro(s).'
            )
            return redirect('agendamentos:cliente_detail', pk=cliente.pk)
        
        messages.success(request, f'Cliente "{cliente.nome}" excluído com sucesso!')
        return super().delete(request, *args, **kwargs)


# ========================================
# VIEWS DE SERVIÇOS
# ========================================

class TipoServicoListView(LoginRequiredMixin, ListView):
    """Lista todos os tipos de serviço do usuário"""
    model = TipoServico
    template_name = 'agendamentos/servico_list.html'
    context_object_name = 'servicos'
    paginate_by = 20
    
    def get_queryset(self):
        queryset = TipoServico.objects.filter(criado_por=self.request.user)
        
        # Filtro de busca
        search = self.request.GET.get('search')
        if search:
            queryset = queryset.filter(
                Q(nome__icontains=search) |
                Q(descricao__icontains=search)
            )
        
        # Filtro de status
        status = self.request.GET.get('status')
        if status == 'ativo':
            queryset = queryset.filter(ativo=True)
        elif status == 'inativo':
            queryset = queryset.filter(ativo=False)
        
        return queryset.order_by('nome')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['search'] = self.request.GET.get('search', '')
        context['status'] = self.request.GET.get('status', '')
        context['total_servicos'] = self.get_queryset().count()
        
        # Estatísticas adicionais
        servicos = TipoServico.objects.filter(criado_por=self.request.user)
        context['servicos_ativos'] = servicos.filter(ativo=True).count()
        
        if servicos.exists():
            # Preço médio
            precos = [s.preco for s in servicos]
            context['preco_medio'] = sum(precos) / len(precos) if precos else 0
            
            # Duração média
            duracoes = [s.duracao.total_seconds() for s in servicos]
            duracao_media_segundos = sum(duracoes) / len(duracoes) if duracoes else 0
            horas = int(duracao_media_segundos // 3600)
            minutos = int((duracao_media_segundos % 3600) // 60)
            context['duracao_media'] = f"{horas}h{minutos:02d}min"
        else:
            context['preco_medio'] = 0
            context['duracao_media'] = "0h00min"
        
        return context


class TipoServicoCreateView(LoginRequiredMixin, CreateView):
    """Criar novo tipo de serviço"""
    model = TipoServico
    form_class = TipoServicoForm
    template_name = 'agendamentos/servico_form.html'
    success_url = reverse_lazy('agendamentos:servico_list')
    
    def form_valid(self, form):
        form.instance.criado_por = self.request.user
        messages.success(self.request, f'Serviço "{form.instance.nome}" criado com sucesso!')
        return super().form_valid(form)
    
    def form_invalid(self, form):
        messages.error(self.request, 'Erro ao criar serviço. Verifique os dados informados.')
        return super().form_invalid(form)


class TipoServicoUpdateView(LoginRequiredMixin, UpdateView):
    """Editar tipo de serviço"""
    model = TipoServico
    form_class = TipoServicoForm
    template_name = 'agendamentos/servico_form.html'
    success_url = reverse_lazy('agendamentos:servico_list')
    
    def get_queryset(self):
        return TipoServico.objects.filter(criado_por=self.request.user)
    
    def form_valid(self, form):
        messages.success(self.request, f'Serviço "{form.instance.nome}" atualizado com sucesso!')
        return super().form_valid(form)
    
    def form_invalid(self, form):
        messages.error(self.request, 'Erro ao atualizar serviço. Verifique os dados informados.')
        return super().form_invalid(form)


class TipoServicoDeleteView(LoginRequiredMixin, DeleteView):
    """Deletar tipo de serviço"""
    model = TipoServico
    template_name = 'agendamentos/servico_confirm_delete.html'
    success_url = reverse_lazy('agendamentos:servico_list')
    context_object_name = 'servico'
    
    def get_queryset(self):
        return TipoServico.objects.filter(criado_por=self.request.user)
    
    def delete(self, request, *args, **kwargs):
        servico = self.get_object()
        
        # Verificar se há agendamentos futuros
        agendamentos_futuros = Agendamento.objects.filter(
            servico=servico,
            data_agendamento__gte=timezone.now().date(),
            status__in=['agendado', 'confirmado']
        ).count()
        
        if agendamentos_futuros > 0:
            messages.error(
                request, 
                f'Não é possível excluir o serviço "{servico.nome}" pois há {agendamentos_futuros} agendamento(s) futuro(s).'
            )
            return redirect('agendamentos:servico_list')
        
        messages.success(request, f'Serviço "{servico.nome}" excluído com sucesso!')
        return super().delete(request, *args, **kwargs)


# ========================================
# VIEWS DE AGENDAMENTOS
# ========================================

class AgendamentoListView(LoginRequiredMixin, ListView):
    """Lista todos os agendamentos do usuário"""
    model = Agendamento
    template_name = 'agendamentos/agendamento_list.html'
    context_object_name = 'agendamentos'
    paginate_by = 20
    
    def get_queryset(self):
        queryset = Agendamento.objects.filter(criado_por=self.request.user)
        
        # Filtro de busca
        search = self.request.GET.get('search')
        if search:
            queryset = queryset.filter(
                Q(cliente__nome__icontains=search) |
                Q(servico__nome__icontains=search) |
                Q(observacoes__icontains=search)
            )
        
        # Filtro de status
        status = self.request.GET.get('status')
        if status:
            queryset = queryset.filter(status=status)
        
        # Filtro de data
        data_inicio = self.request.GET.get('data_inicio')
        data_fim = self.request.GET.get('data_fim')
        
        if data_inicio:
            queryset = queryset.filter(data_agendamento__gte=data_inicio)
        if data_fim:
            queryset = queryset.filter(data_agendamento__lte=data_fim)
        
        return queryset.order_by('-data_agendamento', '-hora_inicio')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['search'] = self.request.GET.get('search', '')
        context['status'] = self.request.GET.get('status', '')
        context['data_inicio'] = self.request.GET.get('data_inicio', '')
        context['data_fim'] = self.request.GET.get('data_fim', '')
        context['status_choices'] = StatusAgendamento.choices
        context['total_agendamentos'] = self.get_queryset().count()
        
        # Datas para filtros rápidos
        hoje = timezone.now().date()
        context['hoje'] = hoje.strftime('%Y-%m-%d')
        
        # Início e fim da semana
        inicio_semana = hoje - timedelta(days=hoje.weekday())
        fim_semana = inicio_semana + timedelta(days=6)
        context['inicio_semana'] = inicio_semana.strftime('%Y-%m-%d')
        context['fim_semana'] = fim_semana.strftime('%Y-%m-%d')
        
        # Início e fim do mês
        inicio_mes = hoje.replace(day=1)
        if hoje.month == 12:
            fim_mes = hoje.replace(year=hoje.year + 1, month=1, day=1) - timedelta(days=1)
        else:
            fim_mes = hoje.replace(month=hoje.month + 1, day=1) - timedelta(days=1)
        context['inicio_mes'] = inicio_mes.strftime('%Y-%m-%d')
        context['fim_mes'] = fim_mes.strftime('%Y-%m-%d')
        
        return context


class AgendamentoCreateView(LoginRequiredMixin, CreateView):
    """Criar novo agendamento"""
    model = Agendamento
    form_class = AgendamentoForm
    template_name = 'agendamentos/agendamento_form.html'
    success_url = reverse_lazy('agendamentos:agendamento_list')
    
    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        kwargs['user'] = self.request.user
        return kwargs
    
    def form_valid(self, form):
        form.instance.criado_por = self.request.user
        messages.success(
            self.request, 
            f'Agendamento para "{form.instance.cliente.nome}" criado com sucesso!'
        )
        return super().form_valid(form)
    
    def form_invalid(self, form):
        messages.error(self.request, 'Erro ao criar agendamento. Verifique os dados informados.')
        return super().form_invalid(form)


class AgendamentoDetailView(LoginRequiredMixin, DetailView):
    """Detalhes do agendamento"""
    model = Agendamento
    template_name = 'agendamentos/agendamento_detail.html'
    context_object_name = 'agendamento'
    
    def get_queryset(self):
        return Agendamento.objects.filter(criado_por=self.request.user)


class AgendamentoUpdateView(LoginRequiredMixin, UpdateView):
    """Editar agendamento"""
    model = Agendamento
    form_class = AgendamentoForm
    template_name = 'agendamentos/agendamento_form.html'
    success_url = reverse_lazy('agendamentos:agendamento_list')
    
    def get_queryset(self):
        return Agendamento.objects.filter(criado_por=self.request.user)
    
    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        kwargs['user'] = self.request.user
        return kwargs
    
    def form_valid(self, form):
        # Verificar se pode editar
        if not form.instance.pode_editar():
            messages.error(
                self.request, 
                'Este agendamento não pode ser editado devido ao seu status atual.'
            )
            return redirect('agendamentos:agendamento_detail', pk=form.instance.pk)
        
        messages.success(
            self.request, 
            f'Agendamento de "{form.instance.cliente.nome}" atualizado com sucesso!'
        )
        return super().form_valid(form)
    
    def form_invalid(self, form):
        messages.error(self.request, 'Erro ao atualizar agendamento. Verifique os dados informados.')
        return super().form_invalid(form)


class AgendamentoDeleteView(LoginRequiredMixin, DeleteView):
    """Deletar agendamento"""
    model = Agendamento
    template_name = 'agendamentos/agendamento_confirm_delete.html'
    success_url = reverse_lazy('agendamentos:agendamento_list')
    context_object_name = 'agendamento'
    
    def get_queryset(self):
        return Agendamento.objects.filter(criado_por=self.request.user)
    
    def delete(self, request, *args, **kwargs):
        agendamento = self.get_object()
        
        # Verificar se pode cancelar
        if not agendamento.pode_cancelar():
            messages.error(
                request, 
                'Este agendamento não pode ser excluído devido ao seu status atual.'
            )
            return redirect('agendamentos:agendamento_detail', pk=agendamento.pk)
        
        messages.success(
            request, 
            f'Agendamento de "{agendamento.cliente.nome}" excluído com sucesso!'
        )
        return super().delete(request, *args, **kwargs)


class AgendamentoStatusUpdateView(LoginRequiredMixin, UpdateView):
    """View para alterar status do agendamento"""
    model = Agendamento
    form_class = AgendamentoStatusForm
    template_name = 'agendamentos/agendamento_status_form.html'
    context_object_name = 'agendamento'

    def get_queryset(self):
        return Agendamento.objects.filter(criado_por=self.request.user)

    def get_success_url(self):
        messages.success(
            self.request, 
            f'Status do agendamento alterado para "{self.object.get_status_display()}" com sucesso!'
        )
        return reverse_lazy('agendamentos:agendamento_detail', kwargs={'pk': self.object.pk})

    def form_valid(self, form):
        # Log da mudança de status
        old_status = self.get_object().status
        new_status = form.cleaned_data['status']
        
        if old_status != new_status:
            # Aqui você pode adicionar lógica adicional
            # como envio de notificações, emails, etc.
            pass
            
        return super().form_valid(form)


# ========================================
# VIEWS DE CONFIGURAÇÃO
# ========================================

class ConfiguracaoView(LoginRequiredMixin, TemplateView):
    """View para configurações do sistema"""
    template_name = 'agendamentos/configuracoes.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # Aqui você pode adicionar configurações específicas
        return context

        