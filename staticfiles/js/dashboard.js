// dashboard-utils.js

// Função para alterar tema
function alterarTema(tema, event) {
    if (event) {
        event.preventDefault();
        event.stopPropagation();
    }
    
    const clickedItem = event ? event.currentTarget : null;
    if (clickedItem) {
        clickedItem.classList.add('tema-loading');
    }
    
    showToast('Alterando tema...', 'info');
    
    fetch('/auth/ajax/alterar-tema/', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-CSRFToken': getCookie('csrftoken')
        },
        body: `tema=${tema}`
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showToast(data.message, 'success');
            setTimeout(() => location.reload(), 800);
        } else {
            showToast('Erro ao alterar tema', 'error');
            if (clickedItem) {
                clickedItem.classList.remove('tema-loading');
            }
        }
    })
    .catch(error => {
        console.error('Erro:', error);
        showToast('Erro ao alterar tema', 'error');
        if (clickedItem) {
            clickedItem.classList.remove('tema-loading');
        }
    });
}

// Função para mostrar toast notifications
function showToast(message, type = 'info') {
    // Remover toasts existentes
    const existingToasts = document.querySelectorAll('.custom-toast');
    existingToasts.forEach(toast => toast.remove());
    
    // Criar novo toast
    const toast = document.createElement('div');
    toast.className = `custom-toast alert alert-${type === 'error' ? 'danger' : type} alert-dismissible fade show`;
    toast.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        z-index: 9999;
        min-width: 300px;
        border-radius: 10px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    `;
    
    toast.innerHTML = `
        <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'} me-2"></i>
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(toast);
    
    // Auto remover após 3 segundos
    setTimeout(() => {
        if (toast.parentNode) {
            toast.remove();
        }
    }, 3000);
}

// Função para pegar CSRF token
function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}