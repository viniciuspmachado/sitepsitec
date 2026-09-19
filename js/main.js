(function () {
  "use strict";

  // Mobile nav toggle
  var toggle = document.getElementById("nav-toggle");
  var nav = document.getElementById("main-nav");

  if (toggle && nav) {
    toggle.addEventListener("click", function () {
      var isOpen = nav.classList.toggle("is-open");
      toggle.classList.toggle("is-active", isOpen);
      toggle.setAttribute("aria-expanded", isOpen ? "true" : "false");
    });

    nav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", function () {
        nav.classList.remove("is-open");
        toggle.classList.remove("is-active");
        toggle.setAttribute("aria-expanded", "false");
      });
    });
  }

  // Footer year
  var yearEl = document.getElementById("year");
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  // Contact form -> mailto fallback (no backend on this static site)
  var form = document.getElementById("contact-form");
  var note = document.getElementById("form-note");

  if (form) {
    form.addEventListener("submit", function (e) {
      e.preventDefault();

      var name = form.name.value.trim();
      var email = form.email.value.trim();
      var topic = form.topic.value;
      var message = form.message.value.trim();

      var subject = encodeURIComponent("[Psitec] " + topic + " — contato de " + name);
      var body = encodeURIComponent(
        "Nome: " + name + "\n" +
        "E-mail: " + email + "\n" +
        "Assunto: " + topic + "\n\n" +
        message
      );

      window.location.href = "mailto:contato@psitec.com.br?subject=" + subject + "&body=" + body;

      if (note) {
        note.textContent = "Abrindo seu aplicativo de e-mail para enviar a mensagem...";
      }
    });
  }
})();
