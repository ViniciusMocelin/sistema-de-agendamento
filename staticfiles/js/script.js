// Toggle Sidebar
document.getElementById("sidebarToggle").addEventListener("click", function () {
  const sidebar = document.getElementById("sidebar");
  const overlay = document.getElementById("sidebarOverlay");

  if (window.innerWidth <= 768) {
    // Mobile
    sidebar.classList.toggle("show");
    overlay.classList.toggle("show");
  } else {
    // Desktop
    sidebar.classList.toggle("collapsed");
  }
});

// Fechar sidebar no mobile ao clicar no overlay
document
  .getElementById("sidebarOverlay")
  .addEventListener("click", function () {
    document.getElementById("sidebar").classList.remove("show");
    this.classList.remove("show");
  });

// Função para alterar tema
function alterarTema(tema, event) {
  if (event) {
    event.preventDefault();
    event.stopPropagation();
  }

  fetch("/auth/ajax/alterar-tema/", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "X-CSRFToken": getCookie("csrftoken"),
    },
    body: `tema=${tema}`,
  })
    .then((response) => response.json())
    .then((data) => {
      if (data.success) {
        location.reload();
      }
    })
    .catch((error) => console.error("Erro:", error));
}

// Função para alterar modo
function alterarModo(isDark) {
  const modo = isDark ? "dark" : "light";

  fetch("/auth/ajax/alterar-modo/", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "X-CSRFToken": getCookie("csrftoken"),
    },
    body: `modo=${modo}`,
  })
    .then((response) => response.json())
    .then((data) => {
      if (data.success) {
        location.reload();
      }
    })
    .catch((error) => console.error("Erro:", error));
}

// Função para pegar CSRF token
function getCookie(name) {
  let cookieValue = null;
  if (document.cookie && document.cookie !== "") {
    const cookies = document.cookie.split(";");
    for (let i = 0; i < cookies.length; i++) {
      const cookie = cookies[i].trim();
      if (cookie.substring(0, name.length + 1) === name + "=") {
        cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
        break;
      }
    }
  }
  return cookieValue;
}

// Responsividade
window.addEventListener("resize", function () {
  const sidebar = document.getElementById("sidebar");
  const overlay = document.getElementById("sidebarOverlay");

  if (window.innerWidth > 768) {
    sidebar.classList.remove("show");
    overlay.classList.remove("show");
  }
});
