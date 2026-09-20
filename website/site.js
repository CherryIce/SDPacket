(() => {
  "use strict";

  const storageKey = "moving-box-site-language";
  const supportedLanguages = new Set(["zh", "en"]);
  const page = document.body.dataset.page || "home";

  const metadata = {
    home: {
      zh: {
        title: "搬家箱 — 每一个箱子，都找得到",
        description:
          "搬家箱是一款本地优先的搬家整理工具，用照片、编号、二维码和搬运状态，把纸箱与数字记录稳稳对应起来。",
      },
      en: {
        title: "Moving Box — Know Where Every Box Belongs",
        description:
          "A local-first moving organizer that keeps physical boxes and digital records aligned with photos, codes, QR labels, and move status.",
      },
    },
    privacy: {
      zh: {
        title: "搬家箱隐私政策",
        description:
          "了解搬家箱如何处理本地记录、照片、语音识别、二维码、导出、备份与系统权限。",
      },
      en: {
        title: "Moving Box Privacy Policy",
        description:
          "Learn how Moving Box handles local records, photos, speech recognition, QR codes, exports, backups, and system permissions.",
      },
    },
  };

  function initialLanguage() {
    const queryLanguage = new URLSearchParams(window.location.search).get("lang");
    if (supportedLanguages.has(queryLanguage)) return queryLanguage;

    try {
      const savedLanguage = window.localStorage.getItem(storageKey);
      if (supportedLanguages.has(savedLanguage)) return savedLanguage;
    } catch (_) {
      // The site remains fully usable when browser storage is unavailable.
    }

    return navigator.language.toLowerCase().startsWith("zh") ? "zh" : "en";
  }

  function updateInternalLinks(language) {
    document.querySelectorAll("[data-language-link]").forEach((link) => {
      const href = link.getAttribute("href");
      if (!href || href.startsWith("#") || href.startsWith("mailto:")) return;

      try {
        const url = new URL(href, window.location.href);
        if (!["http:", "https:", "file:"].includes(url.protocol)) return;
        if (url.protocol !== "file:" && url.origin !== window.location.origin) return;
        url.searchParams.set("lang", language);
        link.href = url.href;
      } catch (_) {
        // Keep the original destination when a link cannot be parsed.
      }
    });
  }

  function setLanguage(language, persist = true) {
    if (!supportedLanguages.has(language)) return;

    document.documentElement.lang = language === "zh" ? "zh-CN" : "en";

    document.querySelectorAll("[data-zh][data-en]").forEach((element) => {
      element.textContent = element.dataset[language];
    });

    document.querySelectorAll("[data-alt-zh][data-alt-en]").forEach((image) => {
      image.alt = image.dataset[`alt${language === "zh" ? "Zh" : "En"}`];
    });

    document.querySelectorAll("[data-aria-zh][data-aria-en]").forEach((element) => {
      element.setAttribute(
        "aria-label",
        element.dataset[`aria${language === "zh" ? "Zh" : "En"}`],
      );
    });

    document.querySelectorAll("[data-language-panel]").forEach((panel) => {
      panel.hidden = panel.dataset.languagePanel !== language;
    });

    document.querySelectorAll("[data-lang-choice]").forEach((button) => {
      button.setAttribute(
        "aria-pressed",
        String(button.dataset.langChoice === language),
      );
    });

    document.querySelectorAll("[data-anchor-zh][data-anchor-en]").forEach((link) => {
      const anchor = link.dataset[`anchor${language === "zh" ? "Zh" : "En"}`];
      const href = link.getAttribute("href") || "";
      if (href.startsWith("#")) link.setAttribute("href", `#${anchor}`);
    });

    const pageMetadata = metadata[page]?.[language];
    if (pageMetadata) {
      document.title = pageMetadata.title;
      const description = document.querySelector('meta[name="description"]');
      if (description) description.content = pageMetadata.description;
    }

    updateInternalLinks(language);

    if (persist) {
      try {
        window.localStorage.setItem(storageKey, language);
      } catch (_) {
        // The selection still applies to the current page view.
      }
    }
  }

  setLanguage(initialLanguage(), false);

  document.querySelectorAll("[data-lang-choice]").forEach((button) => {
    button.addEventListener("click", () => setLanguage(button.dataset.langChoice));
  });

  document.querySelectorAll("[data-current-year]").forEach((element) => {
    element.textContent = String(new Date().getFullYear());
  });

  const header = document.querySelector("[data-header]");
  const updateHeader = () => {
    header?.classList.toggle("is-scrolled", window.scrollY > 12);
  };
  updateHeader();
  window.addEventListener("scroll", updateHeader, { passive: true });

  const menuButton = document.querySelector("[data-menu-button]");
  const navigation = document.querySelector("[data-nav]");

  function closeMenu() {
    menuButton?.setAttribute("aria-expanded", "false");
    navigation?.classList.remove("is-open");
    document.body.classList.remove("menu-open");
  }

  menuButton?.addEventListener("click", () => {
    const open = menuButton.getAttribute("aria-expanded") !== "true";
    menuButton.setAttribute("aria-expanded", String(open));
    navigation?.classList.toggle("is-open", open);
    document.body.classList.toggle("menu-open", open);
  });

  navigation?.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", closeMenu);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeMenu();
  });

  window.matchMedia("(min-width: 861px)").addEventListener?.("change", (event) => {
    if (event.matches) closeMenu();
  });
})();
