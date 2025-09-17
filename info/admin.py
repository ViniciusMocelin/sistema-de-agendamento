from django.contrib import admin
from .models import CategoriaInfo, Tutorial, FAQ, ProgressoTutorial, Dica

@admin.register(CategoriaInfo)
class CategoriaInfoAdmin(admin.ModelAdmin):
    list_display = ['nome', 'ordem', 'ativo']
    list_editable = ['ordem', 'ativo']
    list_filter = ['ativo']
    search_fields = ['nome', 'descricao']

@admin.register(Tutorial)
class TutorialAdmin(admin.ModelAdmin):
    list_display = ['titulo', 'categoria', 'tipo', 'tempo_estimado', 'ordem', 'ativo']
    list_editable = ['ordem', 'ativo']
    list_filter = ['categoria', 'tipo', 'ativo']
    search_fields = ['titulo', 'descricao']
    readonly_fields = ['criado_em', 'atualizado_em']

@admin.register(FAQ)
class FAQAdmin(admin.ModelAdmin):
    list_display = ['pergunta', 'categoria', 'visualizacoes', 'ordem', 'ativo']
    list_editable = ['ordem', 'ativo']
    list_filter = ['categoria', 'ativo']
    search_fields = ['pergunta', 'resposta']
    readonly_fields = ['visualizacoes', 'criado_em']

@admin.register(ProgressoTutorial)
class ProgressoTutorialAdmin(admin.ModelAdmin):
    list_display = ['usuario', 'tutorial', 'concluido', 'data_inicio', 'data_conclusao']
    list_filter = ['concluido', 'tutorial__categoria']
    search_fields = ['usuario__username', 'tutorial__titulo']
    readonly_fields = ['data_inicio']

@admin.register(Dica)
class DicaAdmin(admin.ModelAdmin):
    list_display = ['titulo', 'cor', 'ordem', 'ativo']
    list_editable = ['ordem', 'ativo']
    list_filter = ['cor', 'ativo']
    search_fields = ['titulo', 'conteudo']