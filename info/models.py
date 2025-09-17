from django.db import models
from django.contrib.auth.models import User

class CategoriaInfo(models.Model):
    """Categorias dos tutoriais"""
    nome = models.CharField(max_length=100)
    descricao = models.TextField()
    icone = models.CharField(max_length=50, default='fas fa-info-circle')
    ordem = models.PositiveIntegerField(default=0)
    ativo = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Categoria de Info'
        verbose_name_plural = 'Categorias de Info'
        ordering = ['ordem', 'nome']
    
    def __str__(self):
        return self.nome

class Tutorial(models.Model):
    """Tutoriais do sistema"""
    TIPO_CHOICES = [
        ('basico', 'Básico'),
        ('intermediario', 'Intermediário'),
        ('avancado', 'Avançado'),
    ]
    
    titulo = models.CharField(max_length=200)
    descricao = models.TextField()
    categoria = models.ForeignKey(CategoriaInfo, on_delete=models.CASCADE)
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES, default='basico')
    conteudo = models.TextField(help_text="Conteúdo HTML do tutorial")
    tempo_estimado = models.PositiveIntegerField(help_text="Tempo em minutos")
    ordem = models.PositiveIntegerField(default=0)
    ativo = models.BooleanField(default=True)
    criado_em = models.DateTimeField(auto_now_add=True)
    atualizado_em = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Tutorial'
        verbose_name_plural = 'Tutoriais'
        ordering = ['categoria', 'ordem', 'titulo']
    
    def __str__(self):
        return f"{self.categoria.nome} - {self.titulo}"

class FAQ(models.Model):
    """Perguntas Frequentes"""
    pergunta = models.CharField(max_length=300)
    resposta = models.TextField()
    categoria = models.ForeignKey(CategoriaInfo, on_delete=models.CASCADE)
    ordem = models.PositiveIntegerField(default=0)
    ativo = models.BooleanField(default=True)
    visualizacoes = models.PositiveIntegerField(default=0)
    criado_em = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'FAQ'
        verbose_name_plural = 'FAQs'
        ordering = ['categoria', 'ordem', 'pergunta']
    
    def __str__(self):
        return self.pergunta

class ProgressoTutorial(models.Model):
    """Progresso do usuário nos tutoriais"""
    usuario = models.ForeignKey(User, on_delete=models.CASCADE)
    tutorial = models.ForeignKey(Tutorial, on_delete=models.CASCADE)
    concluido = models.BooleanField(default=False)
    data_inicio = models.DateTimeField(auto_now_add=True)
    data_conclusao = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ['usuario', 'tutorial']
        verbose_name = 'Progresso do Tutorial'
        verbose_name_plural = 'Progressos dos Tutoriais'
    
    def __str__(self):
        status = "Concluído" if self.concluido else "Em andamento"
        return f"{self.usuario.username} - {self.tutorial.titulo} ({status})"

class Dica(models.Model):
    """Dicas rápidas do sistema"""
    titulo = models.CharField(max_length=150)
    conteudo = models.TextField()
    icone = models.CharField(max_length=50, default='fas fa-lightbulb')
    cor = models.CharField(max_length=20, default='primary')
    ativo = models.BooleanField(default=True)
    ordem = models.PositiveIntegerField(default=0)
    
    class Meta:
        verbose_name = 'Dica'
        verbose_name_plural = 'Dicas'
        ordering = ['ordem', 'titulo']
    
    def __str__(self):
        return self.titulo