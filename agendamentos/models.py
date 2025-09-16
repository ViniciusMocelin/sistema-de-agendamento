from django.db import models
from django.contrib.auth.models import User
from django.core.validators import RegexValidator
from django.utils import timezone
from datetime import datetime, timedelta
from django.core.exceptions import ValidationError

class Cliente(models.Model):
    """Model para armazenar dados dos clientes"""
    nome = models.CharField(max_length=100, verbose_name="Nome Completo")
    email = models.EmailField(unique=True, verbose_name="Email")
    telefone_regex = RegexValidator(
        regex=r'^\(\d{2}\)\s\d{4,5}-\d{4}$',
        message="Telefone deve estar no formato: (11) 99999-9999"
    )
    telefone = models.CharField(
        validators=[telefone_regex], 
        max_length=15, 
        verbose_name="Telefone"
    )
    cpf_regex = RegexValidator(
        regex=r'^\d{3}\.\d{3}\.\d{3}-\d{2}$',
        message="CPF deve estar no formato: 000.000.000-00"
    )
    cpf = models.CharField(
        validators=[cpf_regex], 
        max_length=14, 
        unique=True, 
        verbose_name="CPF"
    )
    data_nascimento = models.DateField(verbose_name="Data de Nascimento")
    endereco = models.TextField(blank=True, null=True, verbose_name="Endereço")
    observacoes = models.TextField(blank=True, null=True, verbose_name="Observações")
    ativo = models.BooleanField(default=True, verbose_name="Ativo")
    criado_em = models.DateTimeField(auto_now_add=True, verbose_name="Criado em")
    atualizado_em = models.DateTimeField(auto_now=True, verbose_name="Atualizado em")
    criado_por = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="Criado por")

    class Meta:
        verbose_name = "Cliente"
        verbose_name_plural = "Clientes"
        ordering = ['nome']

    def __str__(self):
        return f"{self.nome} - {self.telefone}"

    @property
    def idade(self):
        """Calcula a idade do cliente"""
        hoje = timezone.now().date()
        return hoje.year - self.data_nascimento.year - (
            (hoje.month, hoje.day) < (self.data_nascimento.month, self.data_nascimento.day)
        )


class TipoServico(models.Model):
    """Model para tipos de serviços oferecidos"""
    nome = models.CharField(max_length=100, verbose_name="Nome do Serviço")
    descricao = models.TextField(blank=True, null=True, verbose_name="Descrição")
    duracao = models.DurationField(verbose_name="Duração", help_text="Ex: 01:30:00 para 1h30min")
    preco = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Preço")
    ativo = models.BooleanField(default=True, verbose_name="Ativo")
    criado_em = models.DateTimeField(auto_now_add=True, verbose_name="Criado em")
    criado_por = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="Criado por")

    class Meta:
        verbose_name = "Tipo de Serviço"
        verbose_name_plural = "Tipos de Serviços"
        ordering = ['nome']

    def __str__(self):
        return f"{self.nome} - R\$ {self.preco}"

    @property
    def duracao_formatada(self):
        """Retorna duração em formato legível"""
        total_seconds = int(self.duracao.total_seconds())
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        return f"{hours}h{minutes:02d}min"


class StatusAgendamento(models.TextChoices):
    """Choices para status do agendamento"""
    AGENDADO = 'agendado', 'Agendado'
    CONFIRMADO = 'confirmado', 'Confirmado'
    EM_ANDAMENTO = 'em_andamento', 'Em Andamento'
    CONCLUIDO = 'concluido', 'Concluído'
    CANCELADO = 'cancelado', 'Cancelado'
    NAO_COMPARECEU = 'nao_compareceu', 'Não Compareceu'


class Agendamento(models.Model):
    """Model principal para agendamentos"""
    cliente = models.ForeignKey(Cliente, on_delete=models.CASCADE, verbose_name="Cliente")
    servico = models.ForeignKey(TipoServico, on_delete=models.CASCADE, verbose_name="Serviço")
    data_agendamento = models.DateField(verbose_name="Data do Agendamento")
    hora_inicio = models.TimeField(verbose_name="Hora de Início")
    hora_fim = models.TimeField(verbose_name="Hora de Fim", blank=True, null=True)  # Permitir null
    status = models.CharField(
        max_length=20,
        choices=StatusAgendamento.choices,
        default=StatusAgendamento.AGENDADO,
        verbose_name="Status"
    )
    observacoes = models.TextField(blank=True, null=True, verbose_name="Observações")
    valor_cobrado = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        blank=True, 
        null=True, 
        verbose_name="Valor Cobrado"
    )
    criado_em = models.DateTimeField(auto_now_add=True, verbose_name="Criado em")
    atualizado_em = models.DateTimeField(auto_now=True, verbose_name="Atualizado em")
    criado_por = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="Criado por")

    class Meta:
        verbose_name = "Agendamento"
        verbose_name_plural = "Agendamentos"
        ordering = ['data_agendamento', 'hora_inicio']
        unique_together = ['data_agendamento', 'hora_inicio', 'criado_por']

    def __str__(self):
        return f"{self.cliente.nome} - {self.data_agendamento} {self.hora_inicio}"

    def clean(self):
        """Validações customizadas"""
        errors = {}
        
        # Validar se a data não é no passado
        if self.data_agendamento and self.data_agendamento < timezone.now().date():
            errors['data_agendamento'] = "Não é possível agendar para datas passadas."
        
        # Validar se hora_fim é maior que hora_inicio (apenas se hora_fim estiver definida)
        if self.hora_inicio and self.hora_fim:
            if self.hora_fim <= self.hora_inicio:
                errors['hora_fim'] = "Hora de fim deve ser maior que hora de início."
        
        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        # Auto-calcular hora_fim baseada na duração do serviço (se não estiver definida)
        if not self.hora_fim and self.servico and self.hora_inicio:
            inicio_datetime = datetime.combine(self.data_agendamento, self.hora_inicio)
            fim_datetime = inicio_datetime + self.servico.duracao
            self.hora_fim = fim_datetime.time()
        
        # Auto-definir valor_cobrado se não informado
        if not self.valor_cobrado and self.servico:
            self.valor_cobrado = self.servico.preco
        
        # Executar validações antes de salvar
        self.full_clean()
        
        super().save(*args, **kwargs)

    @property
    def duracao_total(self):
        """Calcula duração total do agendamento"""
        if not self.hora_fim:
            return self.servico.duracao if self.servico else timedelta(hours=1)
        
        inicio = datetime.combine(self.data_agendamento, self.hora_inicio)
        fim = datetime.combine(self.data_agendamento, self.hora_fim)
        return fim - inicio

    @property
    def status_badge_class(self):
        """Retorna classe CSS para badge do status"""
        status_classes = {
            'agendado': 'bg-secondary',
            'confirmado': 'bg-primary',
            'em_andamento': 'bg-warning',
            'concluido': 'bg-success',
            'cancelado': 'bg-danger',
            'nao_compareceu': 'bg-dark'
        }
        return status_classes.get(self.status, 'bg-secondary')

    def pode_editar(self):
        """Verifica se o agendamento pode ser editado"""
        return self.status in ['agendado', 'confirmado']

    def pode_cancelar(self):
        """Verifica se o agendamento pode ser cancelado"""
        return self.status not in ['concluido', 'cancelado']