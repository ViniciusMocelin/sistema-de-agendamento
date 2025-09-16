from django import forms
from django.core.exceptions import ValidationError
from django.utils import timezone
from datetime import datetime, time
from .models import Cliente, TipoServico, Agendamento
import re

class ClienteForm(forms.ModelForm):
    """Form para cadastro/edição de clientes"""
    
    class Meta:
        model = Cliente
        fields = [
            'nome', 'email', 'telefone', 'cpf', 'data_nascimento',
            'endereco', 'observacoes', 'ativo'
        ]
        widgets = {
            'nome': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Nome completo do cliente'
            }),
            'email': forms.EmailInput(attrs={
                'class': 'form-control',
                'placeholder': 'email@exemplo.com'
            }),
            'telefone': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': '(11) 99999-9999',
                'data-mask': '(00) 00000-0000'
            }),
            'cpf': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': '000.000.000-00',
                'data-mask': '000.000.000-00'
            }),
            'data_nascimento': forms.DateInput(attrs={
                'class': 'form-control',
                'type': 'date'
            }),
            'endereco': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 3,
                'placeholder': 'Endereço completo (opcional)'
            }),
            'observacoes': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 3,
                'placeholder': 'Observações sobre o cliente (opcional)'
            }),
            'ativo': forms.CheckboxInput(attrs={
                'class': 'form-check-input'
            })
        }

    def clean_cpf(self):
        cpf = self.cleaned_data.get('cpf')
        if cpf:
            # Remove caracteres especiais
            cpf_numbers = re.sub(r'[^0-9]', '', cpf)
            
            # Validação básica de CPF
            if len(cpf_numbers) != 11:
                raise ValidationError("CPF deve ter 11 dígitos.")
            
            # Verifica se todos os dígitos são iguais
            if cpf_numbers == cpf_numbers[0] * 11:
                raise ValidationError("CPF inválido.")
                
        return cpf

    def clean_data_nascimento(self):
        data = self.cleaned_data.get('data_nascimento')
        if data:
            hoje = timezone.now().date()
            if data > hoje:
                raise ValidationError("Data de nascimento não pode ser no futuro.")
            
            # Verificar se a pessoa tem pelo menos 1 ano
            idade = hoje.year - data.year
            if idade < 1:
                raise ValidationError("Cliente deve ter pelo menos 1 ano.")
                
        return data


class TipoServicoForm(forms.ModelForm):
    """Form para cadastro/edição de tipos de serviço"""
    
    duracao_horas = forms.IntegerField(
        min_value=0,
        max_value=23,
        initial=1,
        widget=forms.NumberInput(attrs={
            'class': 'form-control',
            'placeholder': '1'
        }),
        label="Horas"
    )
    
    duracao_minutos = forms.IntegerField(
        min_value=0,
        max_value=59,
        initial=0,
        widget=forms.NumberInput(attrs={
            'class': 'form-control',
            'placeholder': '0'
        }),
        label="Minutos"
    )
    
    class Meta:
        model = TipoServico
        fields = ['nome', 'descricao', 'preco', 'ativo']
        widgets = {
            'nome': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Nome do serviço'
            }),
            'descricao': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 3,
                'placeholder': 'Descrição do serviço (opcional)'
            }),
            'preco': forms.NumberInput(attrs={
                'class': 'form-control',
                'step': '0.01',
                'min': '0',
                'placeholder': '0.00'
            }),
            'ativo': forms.CheckboxInput(attrs={
                'class': 'form-check-input'
            })
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Se editando, preencher campos de duração
        if self.instance and self.instance.pk and self.instance.duracao:
            total_seconds = int(self.instance.duracao.total_seconds())
            hours = total_seconds // 3600
            minutes = (total_seconds % 3600) // 60
            self.fields['duracao_horas'].initial = hours
            self.fields['duracao_minutos'].initial = minutes

    def save(self, commit=True):
        instance = super().save(commit=False)
        
        # Converter horas e minutos para timedelta
        horas = self.cleaned_data.get('duracao_horas', 0)
        minutos = self.cleaned_data.get('duracao_minutos', 0)
        
        from datetime import timedelta
        instance.duracao = timedelta(hours=horas, minutes=minutos)
        
        if commit:
            instance.save()
        return instance


class AgendamentoForm(forms.ModelForm):
    """Form para cadastro/edição de agendamentos"""
    
    class Meta:
        model = Agendamento
        fields = [
            'cliente', 'servico', 'data_agendamento', 'hora_inicio',
            'observacoes', 'valor_cobrado'
        ]
        widgets = {
            'cliente': forms.Select(attrs={
                'class': 'form-select'
            }),
            'servico': forms.Select(attrs={
                'class': 'form-select'
            }),
            'data_agendamento': forms.DateInput(attrs={
                'class': 'form-control',
                'type': 'date'
            }),
            'hora_inicio': forms.TimeInput(attrs={
                'class': 'form-control',
                'type': 'time'
            }),
            'observacoes': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 3,
                'placeholder': 'Observações sobre o agendamento (opcional)'
            }),
            'valor_cobrado': forms.NumberInput(attrs={
                'class': 'form-control',
                'step': '0.01',
                'min': '0',
                'placeholder': 'Valor a ser cobrado'
            })
        }

    def __init__(self, *args, **kwargs):
        self.user = kwargs.pop('user', None)
        super().__init__(*args, **kwargs)
        
        # Filtrar apenas clientes ativos do usuário
        if self.user:
            self.fields['cliente'].queryset = Cliente.objects.filter(
                criado_por=self.user, 
                ativo=True
            ).order_by('nome')
            
            self.fields['servico'].queryset = TipoServico.objects.filter(
                criado_por=self.user, 
                ativo=True
            ).order_by('nome')

        # Adicionar opção vazia
        self.fields['cliente'].empty_label = "Selecione um cliente"
        self.fields['servico'].empty_label = "Selecione um serviço"

    def clean_data_agendamento(self):
        data = self.cleaned_data.get('data_agendamento')
        if data:
            hoje = timezone.now().date()
            if data < hoje:
                raise ValidationError("Não é possível agendar para datas passadas.")
        return data

    def clean(self):
        cleaned_data = super().clean()
        data_agendamento = cleaned_data.get('data_agendamento')
        hora_inicio = cleaned_data.get('hora_inicio')
        servico = cleaned_data.get('servico')
        
        if data_agendamento and hora_inicio and servico and self.user:
            # Calcular hora_fim baseada no serviço
            inicio_datetime = datetime.combine(data_agendamento, hora_inicio)
            fim_datetime = inicio_datetime + servico.duracao
            hora_fim = fim_datetime.time()
            
            # Verificar se o agendamento não passa da meia-noite
            if fim_datetime.date() > data_agendamento:
                raise ValidationError({
                    'hora_inicio': f"O agendamento não pode passar da meia-noite. "
                                 f"Com duração de {servico.duracao_formatada}, "
                                 f"o horário máximo de início é {(datetime.combine(data_agendamento, time(23, 59)) - servico.duracao).time().strftime('%H:%M')}"
                })
            
            # Verificar conflitos de horário
            agendamentos_conflitantes = Agendamento.objects.filter(
                criado_por=self.user,
                data_agendamento=data_agendamento,
                status__in=['agendado', 'confirmado', 'em_andamento']
            )
            
            # Excluir o próprio agendamento se estiver editando
            if self.instance and self.instance.pk:
                agendamentos_conflitantes = agendamentos_conflitantes.exclude(pk=self.instance.pk)
            
            for agendamento in agendamentos_conflitantes:
                # Calcular hora_fim do agendamento existente se não estiver definida
                if agendamento.hora_fim:
                    agend_fim = agendamento.hora_fim
                else:
                    agend_inicio_dt = datetime.combine(data_agendamento, agendamento.hora_inicio)
                    agend_fim_dt = agend_inicio_dt + agendamento.servico.duracao
                    agend_fim = agend_fim_dt.time()
                
                agend_inicio = agendamento.hora_inicio
                
                # Verificar sobreposição
                if (hora_inicio < agend_fim and hora_fim > agend_inicio):
                    raise ValidationError({
                        'hora_inicio': f"Conflito de horário com agendamento existente: "
                                     f"{agendamento.cliente.nome} das {agend_inicio} às {agend_fim}"
                    })
        
        return cleaned_data


class AgendamentoStatusForm(forms.ModelForm):
    """Form para alterar status do agendamento"""
    
    observacoes_status = forms.CharField(
        required=False,
        max_length=500,
        widget=forms.Textarea(attrs={
            'class': 'form-control',
            'rows': 3,
            'placeholder': 'Observações sobre a mudança de status (opcional)'
        }),
        help_text='Adicione observações sobre a mudança de status'
    )
    
    class Meta:
        model = Agendamento
        fields = ['status']
        widgets = {
            'status': forms.RadioSelect(attrs={
                'class': 'form-check-input'
            })
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Personalizar choices se necessário
        self.fields['status'].widget.attrs.update({'class': 'btn-check'})
        
    def save(self, commit=True):
        agendamento = super().save(commit=False)
        
        # Adicionar observações sobre mudança de status
        observacoes_status = self.cleaned_data.get('observacoes_status')
        if observacoes_status:
            if agendamento.observacoes:
                agendamento.observacoes += f"\n\n[{timezone.now().strftime('%d/%m/%Y %H:%M')}] Status alterado para {agendamento.get_status_display()}: {observacoes_status}"
            else:
                agendamento.observacoes = f"[{timezone.now().strftime('%d/%m/%Y %H:%M')}] Status alterado para {agendamento.get_status_display()}: {observacoes_status}"
        
        if commit:
            agendamento.save()
        return agendamento