from django.shortcuts import render, redirect, get_object_or_404
from django.urls import reverse_lazy
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.views.generic import (TemplateView, ListView, CreateView, UpdateView, DeleteView, DetailView)
from django.db.models import Q, Count, Sum
from django.utils import timezone
from django.http import JsonResponse
from datetime import datetime, timedelta

import json
from .models import Cliente, TipoServico, Agendamento, StatusAgendamento
from .forms import ClienteForm, TipoServicoForm, AgendamentoForm, AgendamentoStatusForm
from django.db.models.functions import TruncMonth

# ========================================
# VIEWS PRINCIPAIS
# ========================================

class HomeView(TemplateView):
    """View da página inicial (pública)"""
    template_name = 'agendamentos/home.html'


class DashboardView(LoginRequiredMixin, TemplateView):
    """Dashboard principal com gráficos e KPIs"""
    template_name = 'agendamentos/dashboard.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        user = self.request.user
        
        # Data atual
        hoje = timezone.now().date()
        inicio_semana = hoje - timedelta(days=hoje.weekday())
        fim_semana = inicio_semana + timedelta(days=6)
        inicio_mes = hoje.replace(day=1)
        
        # Queryset base
        agendamentos = Agendamento.objects.filter(criado_por=user)
        
        # Estatísticas básicas
        context['agendamentos_hoje'] = agendamentos.filter(data_agendamento=hoje).count()
        context['agendamentos_semana'] = agendamentos.filter(
            data_agendamento__range=[inicio_semana, fim_semana]
        ).count()
        context['total_clientes'] = Cliente.objects.filter(criado_por=user).count()
        context['agendamentos_pendentes'] = agendamentos.filter(status='agendado').count()
        
        # Próximos agendamentos
        context['proximos_agendamentos'] = agendamentos.filter(
            data_agendamento__gte=hoje
        ).order_by('data_agendamento', 'hora_inicio')[:5]
        
        # Estatísticas do mês
        agendamentos_mes = agendamentos.filter(data_agendamento__gte=inicio_mes)
        context['agendamentos_mes_realizados'] = agendamentos_mes.filter(status='concluido').count()
        context['agendamentos_mes_cancelados'] = agendamentos_mes.filter(
            status__in=['cancelado', 'nao_compareceu']
        ).count()
        
        # Taxa de comparecimento
        total_mes = agendamentos_mes.count()
        if total_mes > 0:
            context['taxa_comparecimento'] = round(
                (context['agendamentos_mes_realizados'] / total_mes) * 100, 1
            )
        else:
            context['taxa_comparecimento'] = 0
        
        # Dados para gráfico de agendamentos por dia (últimos 30 dias)
        context['grafico_agendamentos_dados'] = self.get_agendamentos_por_dia(user)
        
        # Dados para outros contextos
        context['today'] = hoje
        
        return context
    
    def get_agendamentos_por_dia(self, user):
        """Gera dados para gráfico de agendamentos por dia"""
        hoje = timezone.now().date()
        inicio_periodo = hoje - timedelta(days=29)  # Últimos 30 dias
        
        # Buscar agendamentos do período
        agendamentos = Agendamento.objects.filter(
            criado_por=user,
            data_agendamento__range=[inicio_periodo, hoje]
        ).values('data_agendamento').annotate(
            total=Count('id')
        ).order_by('data_agendamento')
        
        # Criar lista de todos os dias do período
        dados = {}
        data_atual = inicio_periodo
        while data_atual <= hoje:
            dados[data_atual.strftime('%Y-%m-%d')] = 0
            data_atual += timedelta(days=1)
        
        # Preencher com dados reais
        for item in agendamentos:
            data_str = item['data_agendamento'].strftime('%Y-%m-%d')
            dados[data_str] = item['total']
        
        # Preparar dados para o gráfico
        categorias = []
        valores = []
        
        for data_str, total in dados.items():
            data_obj = datetime.strptime(data_str, '%Y-%m-%d').date()
            categorias.append(data_obj.strftime('%d/%m'))
            valores.append(total)
        
        return {
            'categorias': json.dumps(categorias),
            'valores': json.dumps(valores)
        }


class RelatoriosView(LoginRequiredMixin, TemplateView):
    """View para relatórios avançados com gráficos"""
    template_name = 'agendamentos/relatorios.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        user = self.request.user
        
        # Período padrão (últimos 3 meses)
        hoje = timezone.now().date()
        inicio_periodo = hoje - timedelta(days=90)
        
        # Filtros da URL
        data_inicio = self.request.GET.get('data_inicio')
        data_fim = self.request.GET.get('data_fim')
        
        if data_inicio:
            inicio_periodo = datetime.strptime(data_inicio, '%Y-%m-%d').date()
        if data_fim:
            hoje = datetime.strptime(data_fim, '%Y-%m-%d').date()
        
        context['data_inicio'] = inicio_periodo
        context['data_fim'] = hoje
        
        # Queryset base
        agendamentos = Agendamento.objects.filter(
            criado_por=user,
            data_agendamento__range=[inicio_periodo, hoje],
            status='concluido'  # Apenas agendamentos concluídos para relatórios
        )
        
        # Gráfico de serviços mais realizados
        context['servicos_dados'] = self.get_servicos_mais_realizados(agendamentos)
        
        # Gráfico de clientes mais frequentes
        context['clientes_dados'] = self.get_clientes_mais_frequentes(agendamentos)
        
        # Gráfico de faturamento por dia
        context['faturamento_dados'] = self.get_faturamento_por_dia(agendamentos, inicio_periodo, hoje)
        
        # KPIs financeiros
        context['kpis_financeiros'] = self.get_kpis_financeiros(agendamentos, inicio_periodo, hoje)
        
        return context
    
    def get_servicos_mais_realizados(self, agendamentos):
        """Dados para gráfico de pizza dos serviços mais realizados"""
        servicos = agendamentos.values('servico__nome').annotate(
            total=Count('id')
        ).order_by('-total')[:10]
        
        dados = []
        for item in servicos:
            dados.append({
                'name': item['servico__nome'],
                'data': item['total']
            })
        
        return json.dumps(dados)
    
    def get_clientes_mais_frequentes(self, agendamentos):
        """Dados para gráfico de clientes mais frequentes"""
        clientes = agendamentos.values('cliente__nome').annotate(
            total=Count('id')
        ).order_by('-total')[:10]
        
        categorias = []
        valores = []
        
        for item in clientes:
            categorias.append(item['cliente__nome'])
            valores.append(item['total'])
        
        return {
            'categorias': json.dumps(categorias),
            'valores': json.dumps(valores)
        }
    
    def get_faturamento_por_dia(self, agendamentos, inicio, fim):
        """Dados para gráfico de faturamento por dia"""
        # Agrupar por data e somar valores
        faturamento = agendamentos.values('data_agendamento').annotate(
            total=Sum('valor_cobrado')
        ).order_by('data_agendamento')
        
        # Criar dicionário com todas as datas
        dados = {}
        data_atual = inicio
        while data_atual <= fim:
            dados[data_atual.strftime('%Y-%m-%d')] = 0
            data_atual += timedelta(days=1)
        
        # Preencher com dados reais
        for item in faturamento:
            if item['total']:
                data_str = item['data_agendamento'].strftime('%Y-%m-%d')
                dados[data_str] = float(item['total'])
            else:
                # Se valor_cobrado for None, usar preço do serviço
                agendamento_item = agendamentos.filter(data_agendamento=item['data_agendamento']).first()
                if agendamento_item:
                    data_str = item['data_agendamento'].strftime('%Y-%m-%d')
                    dados[data_str] = float(agendamento_item.servico.preco)
        
        categorias = []
        valores = []
        
        for data_str, valor in dados.items():
            data_obj = datetime.strptime(data_str, '%Y-%m-%d').date()
            categorias.append(data_obj.strftime('%d/%m'))
            valores.append(valor)
        
        return {
            'categorias': json.dumps(categorias),
            'valores': json.dumps(valores)
        }
    
    def get_kpis_financeiros(self, agendamentos, inicio, fim):
        """KPIs financeiros do período - CORRIGIDO para SQLite"""
        # Faturamento total
        total_valor_cobrado = agendamentos.filter(
            valor_cobrado__isnull=False
        ).aggregate(total=Sum('valor_cobrado'))['total'] or 0
        
        # Para agendamentos sem valor_cobrado, usar preço do serviço
        agendamentos_sem_valor = agendamentos.filter(valor_cobrado__isnull=True)
        total_preco_servico = 0
        for agendamento in agendamentos_sem_valor:
            total_preco_servico += float(agendamento.servico.preco)
        
        faturamento_total = float(total_valor_cobrado) + total_preco_servico
        
        # Ticket médio
        total_agendamentos = agendamentos.count()
        ticket_medio = faturamento_total / total_agendamentos if total_agendamentos > 0 else 0
        
        # Faturamento por mês usando TruncMonth (compatível com SQLite)
        meses = agendamentos.annotate(
            mes=TruncMonth('data_agendamento')
        ).values('mes').annotate(
            total_valor=Sum('valor_cobrado'),
            count_agendamentos=Count('id')
        ).order_by('mes')
        
        faturamento_mensal = []
        for item in meses:
            mes_obj = item['mes']
            valor_cobrado = float(item['total_valor'] or 0)
            
            # Calcular valor dos serviços sem valor_cobrado neste mês
            agendamentos_mes_sem_valor = agendamentos.filter(
                data_agendamento__year=mes_obj.year,
                data_agendamento__month=mes_obj.month,
                valor_cobrado__isnull=True
            )
            
            valor_servicos = 0
            for agendamento in agendamentos_mes_sem_valor:
                valor_servicos += float(agendamento.servico.preco)
            
            valor_total_mes = valor_cobrado + valor_servicos
            
            faturamento_mensal.append({
                'mes': mes_obj.strftime('%m/%Y'),
                'valor': valor_total_mes
            })
        
        # Crescimento mensal
        crescimento = 0
        if len(faturamento_mensal) >= 2:
            ultimo = faturamento_mensal[-1]['valor']
            penultimo = faturamento_mensal[-2]['valor']
            if penultimo > 0:
                crescimento = ((ultimo - penultimo) / penultimo) * 100
        
        return {
            'faturamento_total': faturamento_total,
            'ticket_medio': ticket_medio,
            'total_agendamentos': total_agendamentos,
            'faturamento_mensal': faturamento_mensal,
            'crescimento_mensal': round(crescimento, 1),
            'dias_periodo': (fim - inicio).days + 1
        }

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



# ========================================
# APIS DE CONFIGURAÇÃO
# ========================================
