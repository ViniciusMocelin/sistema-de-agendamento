from django.urls import path
from . import views

app_name = 'info'

urlpatterns = [
    # Páginas principais
    path('', views.InfoHomeView.as_view(), name='home'),
    path('tutoriais/', views.TutoriaisView.as_view(), name='tutoriais'),
    path('tutorial/<int:pk>/', views.TutorialDetailView.as_view(), name='tutorial_detail'),
    path('faq/', views.FAQView.as_view(), name='faq'),
    path('guia-completo/', views.GuiaCompletoView.as_view(), name='guia_completo'),
    path('demonstracao/', views.DemonstracaoView.as_view(), name='demonstracao'),
    
    # AJAX
    path('ajax/tutorial/<int:tutorial_id>/concluir/', views.marcar_tutorial_concluido, name='concluir_tutorial'),
    path('ajax/faq/<int:faq_id>/visualizar/', views.incrementar_visualizacao_faq, name='visualizar_faq'),
]