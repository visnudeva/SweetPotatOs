(function () {
  var nav = document.querySelector(".topnav");
  var button = nav && nav.querySelector(".nav-toggle");
  var links = nav && nav.querySelector(".topnav-links");
  if (!nav || !button || !links) return;

  function setOpen(open) {
    nav.classList.toggle("is-open", open);
    button.setAttribute("aria-expanded", open ? "true" : "false");
  }

  button.addEventListener("click", function () {
    setOpen(!nav.classList.contains("is-open"));
  });

  links.addEventListener("click", function (event) {
    if (event.target.closest("a")) setOpen(false);
  });

  var lastY = window.scrollY;
  window.addEventListener("scroll", function () {
    if (Math.abs(window.scrollY - lastY) > 6) setOpen(false);
    lastY = window.scrollY;
  }, { passive: true });
})();
