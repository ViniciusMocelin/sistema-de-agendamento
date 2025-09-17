from django.db import models
from django.contrib.auth.models import User

class PreferenciasUsuario(models.Model):
    """Preferências de tema e personalização do usuário"""
    
    TEMAS_CHOICES = [
        ('default', 'Azul Clássico'),
        ('emerald', 'Verde Esmeralda'),
        ('sunset', 'Pôr do Sol'),
        ('ocean', 'Oceano Profundo'),
        ('purple', 'Roxo Elegante'),
    ]
    
    # NOVO: Opção de modo escuro
    MODO_CHOICES = [
        ('light', 'Claro'),
        ('dark', 'Escuro'),
    ]
    
    usuario = models.OneToOneField(User, on_delete=models.CASCADE, related_name='preferencias')
    tema = models.CharField(max_length=20, choices=TEMAS_CHOICES, default='default')
    modo = models.CharField(max_length=10, choices=MODO_CHOICES, default='light')  # NOVO
    criado_em = models.DateTimeField(auto_now_add=True)
    atualizado_em = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Preferência do Usuário'
        verbose_name_plural = 'Preferências dos Usuários'
    
    def __str__(self):
        return f"{self.usuario.username} - {self.get_tema_display()} ({self.get_modo_display()})"
    
    @classmethod
    def get_or_create_for_user(cls, user):
        """Retorna ou cria preferências para o usuário"""
        if user.is_authenticated:
            preferencias, created = cls.objects.get_or_create(usuario=user)
            return preferencias
        return None