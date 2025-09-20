/*
Este script é responsável por animações e melhorias na experiência do usuário. Ele adiciona:
- Efeitos visuais ao passar o mouse sobre elementos (como subir e aumentar de tamanho).
- Uma caixa de confirmação para ações importantes (como finalizar ou confirmar).
- Animações para a entrada de cards na página, criando um efeito visual agradável.
- Feedback visual para elementos clicáveis.
*/


document.addEventListener('DOMContentLoaded', function() {
    // Animação nos cards de informação
    const infoBoxes = document.querySelectorAll('.info-box');
    infoBoxes.forEach(box => {
        box.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-3px) scale(1.02)';
        });
        
        box.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });
    
    // Confirmar ações importantes
    const actionButtons = document.querySelectorAll('a[href*="status"]');
    actionButtons.forEach(button => {
        if (button.textContent.includes('Finalizar') || button.textContent.includes('Confirmar')) {
            button.addEventListener('click', function(e) {
                const action = this.textContent.trim();
                if (!confirm(`Tem certeza que deseja ${action.toLowerCase()}?`)) {
                    e.preventDefault();
                }
            });
        }
    });
    
    // Animação de entrada escalonada
    const cards = document.querySelectorAll('.detail-card');
    cards.forEach((card, index) => {
        card.style.animationDelay = `${index * 0.1}s`;
    });
    
    // Scroll suave para seções
    const timelineItems = document.querySelectorAll('.timeline-item');
    timelineItems.forEach(item => {
        item.addEventListener('click', function() {
            this.style.transform = 'scale(1.02)';
            setTimeout(() => {
                this.style.transform = 'scale(1)';
            }, 200);
        });
    });
});