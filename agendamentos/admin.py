from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth import get_user_model

User = get_user_model()

# Personalizar admin site
admin.site.site_header = "Sistema de Agendamentos - 4Minds"
admin.site.site_title = "Admin 4Minds"
admin.site.index_title = "Painel Administrativo"

# Personalizar User Admin
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'is_active', 'date_joined')
    list_filter = ('is_staff', 'is_active', 'is_superuser', 'date_joined')
    search_fields = ('username', 'email', 'first_name', 'last_name')
    ordering = ('-date_joined',)

# Re-registrar User model
admin.site.unregister(User)
admin.site.register(User, CustomUserAdmin)
