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

/** Home-page logo easter egg: the Tuber Vault (+ deeper root on letter P). */
(function () {
  var hit = document.getElementById("tuber-vault-hit");
  var vault = document.getElementById("tuber-vault");
  var logo = document.getElementById("tuber-vault-logo");
  var closeBtn = document.getElementById("tuber-vault-close");
  var outer = document.getElementById("tuber-vault-outer");
  var deep = document.getElementById("tuber-vault-deep");
  var deepClose = document.getElementById("tuber-vault-deep-close");
  if (!hit || !vault || !logo || !outer || !deep) return;

  var tagline = document.querySelector("[data-vault-tagline]");
  function cleanTagline() {
    if (!tagline) return "";
    return tagline.getAttribute("data-i18n-clean") || tagline.textContent || "";
  }
  var vaultTag = "Tuber vault · harvest override";
  var deepTag = "Mashed core · root access";
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$#*&%<>/\\|";
  var timers = [];
  var open = false;
  var deepOpen = false;
  var SEED = "p";

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

  function runLines(selector) {
    var lines = vault.querySelectorAll(selector);
    Array.prototype.forEach.call(lines, function (line, index) {
      line.textContent = "";
      scrambleInto(line, line.getAttribute("data-final") || "", index * 220);
    });
  }

  function syncHash() {
    var want = deepOpen ? "#tuber-core" : open ? "#tuber-vault" : "";
    if ((window.location.hash || "") === want) return;
    if (!want) {
      history.pushState("", "", window.location.pathname + window.location.search);
      return;
    }
    history.pushState({ tuberVault: true, deep: deepOpen }, "", want);
  }

  function setDeep(next) {
    if (!open && next) return;
    deepOpen = next;
    document.body.classList.toggle("tuber-core-open", deepOpen);
    deep.hidden = !deepOpen;
    outer.hidden = deepOpen;
    clearTimers();
    if (deepOpen) {
      if (tagline) tagline.textContent = deepTag;
      runLines("[data-deep-line]");
      if (deepClose) deepClose.focus();
    } else if (open) {
      if (tagline) tagline.textContent = vaultTag;
      runLines("[data-vault-line]");
      if (closeBtn) closeBtn.focus();
    }
    syncHash();
  }

  function setVault(next) {
    open = next;
    if (!open) deepOpen = false;
    document.body.classList.toggle("tuber-vault-open", open);
    document.body.classList.toggle("tuber-core-open", open && deepOpen);
    hit.setAttribute("aria-expanded", open ? "true" : "false");
    vault.hidden = !open;
    vault.setAttribute("aria-hidden", open ? "false" : "true");
    deep.hidden = !(open && deepOpen);
    outer.hidden = !open || deepOpen;
    logo.src = open
      ? (logo.getAttribute("data-glitch") || logo.src)
      : (logo.getAttribute("data-clean") || logo.src);
    if (tagline) {
      tagline.textContent = !open ? cleanTagline() : deepOpen ? deepTag : vaultTag;
    }
    clearTimers();
    if (open) {
      if (deepOpen) runLines("[data-deep-line]");
      else runLines("[data-vault-line]");
      if (deepOpen && deepClose) deepClose.focus();
      else if (closeBtn) closeBtn.focus();
    }
    syncHash();
  }

  function applyHash() {
    var hash = window.location.hash || "";
    if (hash === "#tuber-core") {
      if (!open) setVault(true);
      setDeep(true);
    } else if (hash === "#tuber-vault") {
      if (!open) setVault(true);
      else if (deepOpen) setDeep(false);
    } else if (open) {
      setVault(false);
    }
  }

  hit.addEventListener("click", function () {
    if (open) setVault(false);
    else setVault(true);
  });
  if (closeBtn) {
    closeBtn.addEventListener("click", function () {
      setVault(false);
      hit.focus();
    });
  }
  if (deepClose) {
    deepClose.addEventListener("click", function () {
      setDeep(false);
    });
  }
  vault.addEventListener("click", function (event) {
    if (event.target === vault) {
      setVault(false);
      hit.focus();
    }
  });
  document.addEventListener("keydown", function (event) {
    if (!open) return;
    if (event.key === "Escape") {
      if (deepOpen) setDeep(false);
      else {
        setVault(false);
        hit.focus();
      }
      return;
    }
    if (deepOpen) return;
    if (event.target && /INPUT|TEXTAREA|SELECT/.test(event.target.tagName)) return;
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    if ((event.key || "").toLowerCase() === SEED) {
      event.preventDefault();
      setDeep(true);
    }
  });
  window.addEventListener("popstate", applyHash);
  applyHash();
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
