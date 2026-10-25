(function () {
  var nav = document.querySelector(".topnav");
  var button = nav && nav.querySelector(".nav-toggle");
  var links = nav && nav.querySelector(".topnav-links");
  if (nav && button && links) {
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
  }
})();

/** Shared lightbox for showroom stills and project shots. */
(function () {
  var view = document.querySelector("[data-lightbox]");
  if (!view) return;

  var viewImg = view.querySelector("img");
  var viewCaption = view.querySelector(".wall-view-caption");
  var viewSave = view.querySelector(".wall-view-save");
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var viewTimer = null;
  var fromBox = null;

  function setBox(box) {
    viewImg.style.left = box.left + "px";
    viewImg.style.top = box.top + "px";
    viewImg.style.width = box.width + "px";
    viewImg.style.height = box.height + "px";
  }

  function fitView() {
    var nw = viewImg.naturalWidth;
    var nh = viewImg.naturalHeight;
    if (!nw || !nh || !view.classList.contains("is-open")) return;
    var maxW = Math.min(window.innerWidth * 0.92, 1400);
    var maxH = window.innerHeight * 0.78;
    var w = maxW;
    var h = (w * nh) / nw;
    if (h > maxH) {
      h = maxH;
      w = (h * nw) / nh;
    }
    setBox({
      left: (window.innerWidth - w) / 2,
      top: Math.max(52, (window.innerHeight - h) / 2 - 24),
      width: w,
      height: h,
    });
  }

  function openView(link, thumb, captionText) {
    fromBox = thumb.getBoundingClientRect();
    window.clearTimeout(viewTimer);
    view.hidden = false;
    view.classList.remove("is-open");
    viewImg.alt = thumb.getAttribute("alt") || "";
    viewCaption.textContent = captionText || "";
    viewSave.href = link.href;
    viewSave.setAttribute("download", link.pathname.split("/").pop());
    document.body.style.overflow = "hidden";
    viewImg.style.transition = "none";
    setBox(fromBox);
    viewImg.src = link.href;
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        viewImg.style.transition = "";
        view.classList.add("is-open");
        fitView();
      });
    });
  }

  function closeView() {
    if (view.hidden) return;
    var box = fromBox;
    if (!box) {
      view.hidden = true;
      document.body.style.overflow = "";
      return;
    }
    view.classList.remove("is-open");
    setBox(box);
    window.clearTimeout(viewTimer);
    viewTimer = window.setTimeout(function () {
      view.hidden = true;
      document.body.style.overflow = "";
    }, reduceMotion ? 0 : 540);
  }

  viewImg.addEventListener("load", fitView);
  view.querySelector(".wall-view-close").addEventListener("click", closeView);
  view.addEventListener("click", function (event) {
    if (event.target === view) closeView();
  });
  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && !view.hidden) closeView();
  });

  function wireLink(link) {
    link.addEventListener("click", function (event) {
      event.preventDefault();
      var thumb = link.querySelector("img") || link;
      if (!thumb.getBoundingClientRect) return;
      var fig = link.closest("figure") || link.closest("article");
      var caption = fig && fig.querySelector("figcaption, h2");
      openView(link, thumb, caption ? caption.textContent : "");
    });
  }

  Array.prototype.forEach.call(
    document.querySelectorAll("[data-lightbox-gallery] a, a.project-shot-link"),
    wireLink
  );

  // Expose for showroom wallpaper coverflow (same overlay).
  window.SweetPotatOsLightbox = { openView: openView, closeView: closeView, fitView: fitView };
})();
