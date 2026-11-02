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

/** Home-page logo easter egg: the Tuber Vault. */
(function () {
  var hit = document.getElementById("tuber-vault-hit");
  var vault = document.getElementById("tuber-vault");
  var logo = document.getElementById("tuber-vault-logo");
  var closeBtn = document.getElementById("tuber-vault-close");
  if (!hit || !vault || !logo) return;

  var tagline = document.querySelector("[data-vault-tagline]");
  var cleanTag = tagline ? tagline.textContent : "";
  var vaultTag = "Tuber vault · harvest override";
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$#*&%<>/\\|";
  var timers = [];
  var open = false;

  function clearTimers() {
    while (timers.length) window.clearTimeout(timers.pop());
  }

  function scrambleInto(el, finalText, delay) {
    var i = 0;
    var rounds = reduceMotion ? 1 : 14;
    el.classList.add("is-glitching");
    function tick() {
      if (i >= rounds) {
        el.textContent = finalText;
        el.classList.remove("is-glitching");
        return;
      }
      var out = "";
      for (var c = 0; c < finalText.length; c++) {
        if (finalText.charAt(c) === " ") {
          out += " ";
        } else if (c < Math.floor((i / rounds) * finalText.length)) {
          out += finalText.charAt(c);
        } else {
          out += glyphs.charAt(Math.floor(Math.random() * glyphs.length));
        }
      }
      el.textContent = out;
      i += 1;
      timers.push(window.setTimeout(tick, 28));
    }
    timers.push(window.setTimeout(tick, delay));
  }

  function runLines() {
    var lines = vault.querySelectorAll("[data-vault-line]");
    Array.prototype.forEach.call(lines, function (line, index) {
      line.textContent = "";
      scrambleInto(line, line.getAttribute("data-final") || "", index * 220);
    });
  }

  function setVault(next) {
    open = next;
    document.body.classList.toggle("tuber-vault-open", open);
    hit.setAttribute("aria-expanded", open ? "true" : "false");
    vault.hidden = !open;
    vault.setAttribute("aria-hidden", open ? "false" : "true");
    logo.src = open
      ? (logo.getAttribute("data-glitch") || logo.src)
      : (logo.getAttribute("data-clean") || logo.src);
    if (tagline) tagline.textContent = open ? vaultTag : cleanTag;
    clearTimers();
    if (open) {
      runLines();
      if (closeBtn) closeBtn.focus();
      if (window.location.hash !== "#tuber-vault") {
        history.pushState({ tuberVault: true }, "", "#tuber-vault");
      }
    } else if (window.location.hash === "#tuber-vault") {
      history.pushState("", "", window.location.pathname + window.location.search);
    }
  }

  hit.addEventListener("click", function () {
    setVault(!open);
  });
  if (closeBtn) {
    closeBtn.addEventListener("click", function () {
      setVault(false);
      hit.focus();
    });
  }
  vault.addEventListener("click", function (event) {
    if (event.target === vault) setVault(false);
  });
  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && open) {
      setVault(false);
      hit.focus();
    }
  });
  window.addEventListener("popstate", function () {
    setVault(window.location.hash === "#tuber-vault");
  });
  if (window.location.hash === "#tuber-vault") setVault(true);
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
