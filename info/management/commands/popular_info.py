from django.core.management.base import BaseCommand
from info.models import CategoriaInfo, Tutorial, FAQ, Dica

class Command(BaseCommand):
    help = 'Popula o sistema com dados iniciais de tutoriais e FAQs'

    def handle(self, *args, **options):
        self.stdout.write('Criando dados iniciais do sistema Info...')
        
        # Criar categorias
        categorias = [
            {
                'nome': 'Primeiros Passos',
                'descricao': 'Tutoriais básicos para começar a usar o sistema',
                'icone': 'fas fa-play-circle',
                'ordem': 1
            },
            {
                'nome': 'Agendamentos',
                'descricao': 'Como criar e gerenciar agendamentos',
                'icone': 'fas fa-calendar-alt',
                'ordem': 2
            },
            {
                'nome': 'Clientes',
                'descricao': 'Gestão completa de clientes',
                'icone': 'fas fa-users',
                'ordem': 3
            },
            {
                'nome': 'Relatórios',
                'descricao': 'Como usar relatórios e análises',
                'icone': 'fas fa-chart-bar',
                'ordem': 4
            },
            {
                'nome': 'Dicas Avançadas',
                'descricao': 'Funcionalidades avançadas e otimizações',
                'icone': 'fas fa-lightbulb',
                'ordem': 5
            }
        ]
        
        for cat_data in categorias:
            categoria, created = CategoriaInfo.objects.get_or_create(
                nome=cat_data['nome'],
                defaults=cat_data
            )
            if created:
                self.stdout.write(f'✓ Categoria criada: {categoria.nome}')

        # Criar tutoriais
        self.criar_tutoriais()
        
        # Criar FAQs
        self.criar_faqs()
        
        # Criar dicas
        self.criar_dicas()
        
        self.stdout.write(
            self.style.SUCCESS('✅ Dados iniciais criados com sucesso!')
        )

    def criar_tutoriais(self):
        # Buscar categorias
        primeiros_passos = CategoriaInfo.objects.get(nome='Primeiros Passos')
        agendamentos = CategoriaInfo.objects.get(nome='Agendamentos')
        clientes = CategoriaInfo.objects.get(nome='Clientes')
        relatorios = CategoriaInfo.objects.get(nome='Relatórios')
        
        tutoriais = [
            # Primeiros Passos
            {
                'titulo': 'Bem-vindo ao Sistema',
                'descricao': 'Conheça a interface e navegação básica do sistema',
                'categoria': primeiros_passos,
                'tipo': 'basico',
                'tempo_estimado': 5,
                'ordem': 1,
                'conteudo': '''
                <h2>Bem-vindo ao Sistema de Agendamentos!</h2>
                
                <p>Este tutorial vai te ajudar a dar os primeiros passos no sistema.</p>
                
                <h3>Navegação Principal</h3>
                <p>O menu principal está localizado no topo da página e contém:</p>
                <ul>
                    <li><strong>Dashboard:</strong> Visão geral do seu negócio</li>
                    <li><strong>Agendamentos:</strong> Criar e gerenciar agendamentos</li>
                    <li><strong>Clientes:</strong> Cadastro de clientes</li>
                    <li><strong>Serviços:</strong> Catálogo de serviços</li>
                    <li><strong>Relatórios:</strong> Análises e gráficos</li>
                </ul>
                
                <h3>Dashboard</h3>
                <p>O Dashboard é sua tela inicial e mostra:</p>
                <ul>
                    <li>Agendamentos do dia</li>
                    <li>Estatísticas da semana</li>
                    <li>Próximos agendamentos</li>
                    <li>Ações rápidas</li>
                </ul>
                
                <div class="alert alert-info">
                    <strong>Dica:</strong> Use o Dashboard como ponto de partida para suas atividades diárias.
                </div>
                '''
            },
            {
                'titulo': 'Criando seu Primeiro Agendamento',
                'descricao': 'Passo a passo para criar seu primeiro agendamento',
                'categoria': agendamentos,
                'tipo': 'basico',
                'tempo_estimado': 8,
                'ordem': 1,
                'conteudo': '''
                <h2>Criando seu Primeiro Agendamento</h2>
                
                <p>Vamos criar seu primeiro agendamento passo a passo:</p>
                
                <h3>Passo 1: Acessar a Criação</h3>
                <p>Você pode criar um agendamento de duas formas:</p>
                <ul>
                    <li>Clicando em "Novo Agendamento" no Dashboard</li>
                    <li>Menu "Agendamentos" → "Criar Agendamento"</li>
                </ul>
                
                <h3>Passo 2: Selecionar Cliente</h3>
                <p>Escolha um cliente existente ou cadastre um novo:</p>
                <ul>
                    <li>Digite o nome para buscar</li>
                    <li>Clique em "Novo Cliente" se necessário</li>
                </ul>
                
                <h3>Passo 3: Escolher Serviço</h3>
                <p>Selecione o serviço que será realizado:</p>
                <ul>
                    <li>O preço será preenchido automaticamente</li>
                    <li>A duração também será calculada</li>
                </ul>
                
                <h3>Passo 4: Data e Hora</h3>
                <p>Defina quando será o agendamento:</p>
                <ul>
                    <li>Escolha a data no calendário</li>
                    <li>Selecione o horário disponível</li>
                    <li>O sistema verifica conflitos automaticamente</li>
                </ul>
                
                <h3>Passo 5: Observações</h3>
                <p>Adicione informações importantes (opcional):</p>
                <ul>
                    <li>Preferências do cliente</li>
                    <li>Instruções especiais</li>
                    <li>Lembretes</li>
                </ul>
                
                <div class="alert alert-success">
                    <strong>Pronto!</strong> Clique em "Salvar" e seu agendamento estará criado.
                </div>
                '''
            }
        ]
        
        for tutorial_data in tutoriais:
            tutorial, created = Tutorial.objects.get_or_create(
                titulo=tutorial_data['titulo'],
                categoria=tutorial_data['categoria'],
                defaults=tutorial_data
            )
            if created:
                self.stdout.write(f'✓ Tutorial criado: {tutorial.titulo}')

    def criar_faqs(self):
        categorias = {
            'primeiros_passos': CategoriaInfo.objects.get(nome='Primeiros Passos'),
            'agendamentos': CategoriaInfo.objects.get(nome='Agendamentos'),
            'clientes': CategoriaInfo.objects.get(nome='Clientes'),
        }
        
        faqs = [
            {
                'pergunta': 'Como faço login no sistema?',
                'resposta': 'Acesse a página de login, digite seu usuário e senha, e clique em "Entrar". Se não tiver uma conta, clique em "Cadastrar-se".',
                'categoria': categorias['primeiros_passos'],
                'ordem': 1
            },
            {
                'pergunta': 'Posso criar agendamentos para o mesmo horário?',
                'resposta': 'Não, o sistema não permite agendamentos sobrepostos. Quando você tentar criar um agendamento em horário já ocupado, receberá um aviso.',
                'categoria': categorias['agendamentos'],
                'ordem': 1
            },
            {
                'pergunta': 'Como edito as informações de um cliente?',
                'resposta': 'Vá em "Clientes", encontre o cliente desejado, clique em "Editar" (ícone de lápis), faça as alterações e clique em "Salvar".',
                'categoria': categorias['clientes'],
                'ordem': 1
            },
            {
                'pergunta': 'Posso cancelar um agendamento?',
                'resposta': 'Sim! Acesse o agendamento e altere o status para "Cancelado". O horário ficará disponível novamente.',
                'categoria': categorias['agendamentos'],
                'ordem': 2
            },
            {
                'pergunta': 'Como vejo o histórico de um cliente?',
                'resposta': 'Na lista de clientes, clique no nome do cliente ou no botão "Ver Detalhes". Você verá todos os agendamentos passados e futuros.',
                'categoria': categorias['clientes'],
                'ordem': 2
            }
        ]
        
        for faq_data in faqs:
            faq, created = FAQ.objects.get_or_create(
                pergunta=faq_data['pergunta'],
                defaults=faq_data
            )
            if created:
                self.stdout.write(f'✓ FAQ criado: {faq.pergunta[:50]}...')

    def criar_dicas(self):
        dicas = [
            {
                'titulo': 'Use Filtros para Buscar',
                'conteudo': 'Use os filtros nas listas para encontrar rapidamente o que procura. Você pode filtrar por data, status, cliente, etc.',
                'icone': 'fas fa-search',
                'cor': 'primary',
                'ordem': 1
            },
            {
                'titulo': 'Confirme Agendamentos',
                'conteudo': 'Sempre confirme agendamentos com seus clientes por telefone ou WhatsApp para reduzir faltas.',
                'icone': 'fas fa-phone',
                'cor': 'success',
                'ordem': 2
            },
            {
                'titulo': 'Monitore seus KPIs',
                'conteudo': 'Acompanhe regularmente os relatórios para identificar tendências e oportunidades de crescimento.',
                'icone': 'fas fa-chart-line',
                'cor': 'info',
                'ordem': 3
            },
            {
                'titulo': 'Mantenha Dados Atualizados',
                'conteudo': 'Mantenha as informações de clientes e serviços sempre atualizadas para melhor organização.',
                'icone': 'fas fa-sync',
                'cor': 'warning',
                'ordem': 4
            }
        ]
        
        for dica_data in dicas:
            dica, created = Dica.objects.get_or_create(
                titulo=dica_data['titulo'],
                defaults=dica_data
            )
            if created:
                self.stdout.write(f'✓ Dica criada: {dica.titulo}')