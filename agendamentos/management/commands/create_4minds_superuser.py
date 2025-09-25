"""
Comando Django personalizado para criar superuser da 4Minds
Sistema de Agendamento

Uso:
    python manage.py create_4minds_superuser
"""

from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from django.db import transaction

User = get_user_model()


class Command(BaseCommand):
    help = 'Cria o superuser da 4Minds com credenciais específicas'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Força a criação mesmo se o usuário já existir (atualiza senha)',
        )
        parser.add_argument(
            '--no-input',
            action='store_true',
            help='Não solicita confirmação do usuário',
        )

    def handle(self, *args, **options):
        username = "@4minds"
        password = "@4mindsPassword"
        email = "admin@4minds.com"
        
        self.stdout.write(
            self.style.SUCCESS('🔐 Criando superuser da 4Minds...')
        )
        
        try:
            # Verificar se o usuário já existe
            if User.objects.filter(username=username).exists():
                if options['force']:
                    self.stdout.write(
                        self.style.WARNING(f'⚠️  Usuário "{username}" já existe. Atualizando...')
                    )
                    user = User.objects.get(username=username)
                    user.set_password(password)
                    user.is_superuser = True
                    user.is_staff = True
                    user.is_active = True
                    user.email = email
                    user.save()
                    
                    self.stdout.write(
                        self.style.SUCCESS(f'✅ Usuário "{username}" atualizado com sucesso!')
                    )
                else:
                    self.stdout.write(
                        self.style.ERROR(f'❌ Usuário "{username}" já existe!')
                    )
                    self.stdout.write(
                        self.style.WARNING('Use --force para atualizar a senha')
                    )
                    
                    if not options['no_input']:
                        update = input("Deseja atualizar a senha? (s/N): ").lower().strip()
                        if update in ['s', 'sim', 'y', 'yes']:
                            user = User.objects.get(username=username)
                            user.set_password(password)
                            user.is_superuser = True
                            user.is_staff = True
                            user.is_active = True
                            user.email = email
                            user.save()
                            
                            self.stdout.write(
                                self.style.SUCCESS(f'✅ Senha do usuário "{username}" atualizada!')
                            )
                        else:
                            self.stdout.write(
                                self.style.WARNING('❌ Operação cancelada.')
                            )
                    return
            
            # Criar o superuser
            with transaction.atomic():
                user = User.objects.create_superuser(
                    username=username,
                    email=email,
                    password=password
                )
                
            self.stdout.write(
                self.style.SUCCESS(f'✅ Superuser "{username}" criado com sucesso!')
            )
            self.stdout.write(f'👤 Usuário: {username}')
            self.stdout.write(f'🔑 Senha: {password}')
            self.stdout.write(f'📧 Email: {email}')
            self.stdout.write('🚀 Acesse o admin em: /admin/')
            
        except Exception as e:
            raise CommandError(f'❌ Erro ao criar superuser: {e}')
