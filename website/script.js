document.addEventListener("DOMContentLoaded", () => {
  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* Translations */
  const translations = {
    tr: {
      brand_tagline: "Cloudflared Manager",
      brand_subtitle: "macOS için Tunnel Studio",
      nav_features: "Özellikler",
      nav_download: "İndir",
      hero_eyebrow: "Yeni nesil Cloudflare Tunnel deneyimi",
      hero_title: "Lokaldeki her servisi <span class=\"accent\">tek tıkla</span> internete açın.",
      hero_lede: "Menü çubuğundan hızlı kontrol, 3 farklı tünel tipi, otomatik DNS yönlendirme ve gelişmiş yedekleme. Modern bir macOS deneyimi için tasarlandı.",
      hero_preview_label: "Önizleme",
      hero_image_alt: "Menü bar önizleme",
      hero_chip_menu: "Menü çubuğu",
      hero_chip_quick: "Hızlı tünel",
      hero_chip_status: "Durum & link",
      cta_download: "macOS için indir",
      cta_preview: "Önizleme gör",
      chip_os: "macOS 13+",
      chip_ui: "SwiftUI · Menü Çubuğu",
      chip_cf: "Cloudflare Zero Trust",
      stat_tunnels: "Başlatılan tünel",
      stat_updates: "Saniyede durum güncellemesi",
      belt_swiftui: "SwiftUI 4.0",
      belt_theme: "11 renk teması",
      belt_menu: "Menü çubuğu kontrolleri",
      belt_backup: "Yedekleme + otomasyon",
      features_eyebrow: "Özellikler",
      features_title: "Tek panel, hızlı kurulum, akıcı paylaşımlar.",
      features_desc: "Gereksiz detay yok: menü çubuğundan başlat/durdur, hızlı link paylaş, gerektiğinde yedekle.",
      feature1_title: "Tek panel kontrol",
      feature1_desc: "HTTP, TCP ve hızlı tünelleri aynı yerden aç/kapat, durum LED'iyle izle.",
      feature2_title: "Hızlı paylaş",
      feature2_desc: "Geçici URL'lerle demo ve testleri saniyeler içinde gönder.",
      feature3_title: "Yedekle & tema",
      feature3_desc: "11 vurgu rengi, açık/koyu ve tek tuşla yedekleme ile hafif kurulum.",
      download_eyebrow: "İndirme",
      download_title: "Kurulum 3 adımda hazır.",
      download_desc: "DMG'yi indirip Uygulamalar'a taşıyın, Homebrew ile cloudflared'ı kurun, Cloudflare hesabınızı bağlayın.",
      download_btn: "DMG indir",
      download_copy: "brew komutunu kopyala",
      step1_title: "DMG'yi indir",
      step1_desc: "Sürükle-bırak ile Uygulamalar klasörüne taşı.",
      step2_title: "cloudflared kurulumu",
      step2_desc: "Homebrew komutu veya manuel kurulum destekli.",
      step3_title: "Giriş yap",
      step3_desc: "`cloudflared login` ile domain'ini seç, tüneli başlat.",
      version_label: "Sürüm",
      platforms: "macOS 13+ (Intel & Apple Silicon)",
      list_update: "Otomatik güncelleme bildirimi",
      list_logs: "Log ve geçmiş export'u",
      list_backup: "Yedekleme & geri yükleme",
      list_theme: "Koyu/Açık tema ve 11 vurgu",
      req_min: "Minimum",
      req_min_desc: "4 GB RAM · 300 MB disk",
      req_dep: "Bağımlılık",
      req_dep_desc: "cloudflared CLI (brew)",
      card_dmg_title: "DMG Paketi",
      card_dmg_desc: "Kod imzalı, otomatik güncelleme uyarıları.",
      card_dmg_link: "Releases sayfası →",
      card_cli_title: "Terminal kurulumu",
      card_cli_desc: "`brew install cloudflare/cloudflare/cloudflared`",
      card_cli_link: "cloudflared login komutunu kopyala",
      faq_eyebrow: "SSS",
      faq_title: "Sık sorulan sorular.",
      faq_desc: "Kısa cevaplarla kurulum ve güvenlik detayları.",
      faq1_title: "Hangi macOS sürümü?",
      faq1_desc: "Ventura 13.0 ve üzeri, Intel veya Apple Silicon desteklenir.",
      faq2_title: "Cloudflare hesabı gerekli mi?",
      faq2_desc: "Evet, giriş Cloudflare üzerinden yapılır. Ücretsiz plan yeterlidir.",
      footer_desc: "macOS menü çubuğundan Cloudflare Tunnel gücünü kontrol edin.",
      footer_cta: "Hemen indir",
      footer_top: "Yukarı çık",
    },
    en: {
      brand_tagline: "Cloudflared Manager",
      brand_subtitle: "Tunnel Studio for macOS",
      nav_features: "Features",
      nav_download: "Download",
      hero_eyebrow: "Next-gen Cloudflare Tunnel experience",
      hero_title: "Expose every local service <span class=\"accent\">with one click</span>.",
      hero_lede: "Quick control from the menu bar, 3 tunnel types, auto DNS routing, and backups. Designed for a modern macOS workflow.",
      hero_preview_label: "Preview",
      hero_image_alt: "Menu bar preview",
      hero_chip_menu: "Menu bar",
      hero_chip_quick: "Quick tunnel",
      hero_chip_status: "Status & link",
      cta_download: "Download for macOS",
      cta_preview: "See preview",
      chip_os: "macOS 13+",
      chip_ui: "SwiftUI · Menu Bar",
      chip_cf: "Cloudflare Zero Trust",
      stat_tunnels: "Tunnels started",
      stat_updates: "Status updates per second",
      belt_swiftui: "SwiftUI 4.0",
      belt_theme: "11 color themes",
      belt_menu: "Menu bar controls",
      belt_backup: "Backup + automation",
      features_eyebrow: "Features",
      features_title: "Single panel, fast setup, seamless sharing.",
      features_desc: "No clutter: start/stop from the menu bar, share quick links, back up when needed.",
      feature1_title: "Single panel control",
      feature1_desc: "Open/close HTTP, TCP, and quick tunnels from one place; monitor with status LED.",
      feature2_title: "Share fast",
      feature2_desc: "Send demo/test links in seconds with temporary URLs.",
      feature3_title: "Back up & theme",
      feature3_desc: "11 accent colors, light/dark, and one-tap backups for a lightweight setup.",
      download_eyebrow: "Download",
      download_title: "Ready in 3 steps.",
      download_desc: "Download the DMG, move it to Applications, install cloudflared with Homebrew, link your Cloudflare account.",
      download_btn: "Download DMG",
      download_copy: "Copy brew command",
      step1_title: "Download DMG",
      step1_desc: "Drag & drop into Applications.",
      step2_title: "Install cloudflared",
      step2_desc: "Use the Homebrew command or manual install.",
      step3_title: "Sign in",
      step3_desc: "Select your domain with `cloudflared login`, start the tunnel.",
      version_label: "Version",
      platforms: "macOS 13+ (Intel & Apple Silicon)",
      list_update: "Auto update alerts",
      list_logs: "Log & history export",
      list_backup: "Backup & restore",
      list_theme: "Light/Dark + 11 accents",
      req_min: "Minimum",
      req_min_desc: "4 GB RAM · 300 MB disk",
      req_dep: "Dependency",
      req_dep_desc: "cloudflared CLI (brew)",
      card_dmg_title: "DMG Package",
      card_dmg_desc: "Code signed, with auto-update alerts.",
      card_dmg_link: "View releases →",
      card_cli_title: "Terminal install",
      card_cli_desc: "`brew install cloudflare/cloudflare/cloudflared`",
      card_cli_link: "Copy cloudflared login command",
      faq_eyebrow: "FAQ",
      faq_title: "Frequently asked questions.",
      faq_desc: "Quick answers about setup and security.",
      faq1_title: "Which macOS version?",
      faq1_desc: "Ventura 13.0+; supports Intel and Apple Silicon.",
      faq2_title: "Is a Cloudflare account required?",
      faq2_desc: "Yes, sign-in goes through Cloudflare. Free plan is enough.",
      footer_desc: "Control Cloudflare Tunnels from the macOS menu bar.",
      footer_cta: "Download now",
      footer_top: "Back to top",
    },
  };

  /* Scroll reveal */
  const revealEls = document.querySelectorAll(".reveal");
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("visible");
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15 }
  );
  revealEls.forEach((el) => observer.observe(el));

  /* Animated counters */
  const counters = document.querySelectorAll(".stat-number");
  counters.forEach((counter) => {
    const target = Number(counter.dataset.count || 0);
    let start = 0;
    const duration = 1400;
    const step = (timestamp) => {
      if (!counter._start) counter._start = timestamp;
      const progress = Math.min((timestamp - counter._start) / duration, 1);
      const value = Math.floor(progress * target);
      counter.textContent = value.toLocaleString("tr-TR");
      if (progress < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  });

  /* Copy to clipboard */
  const copyButtons = document.querySelectorAll("[data-copy], .copyable");
  copyButtons.forEach((btn) => {
    btn.addEventListener("click", async (e) => {
      e.preventDefault();
      const text = btn.dataset.copy || btn.textContent || "";
      try {
        await navigator.clipboard.writeText(text.trim());
        const original = btn.textContent;
        btn.textContent = "Kopyalandı!";
        setTimeout(() => (btn.textContent = original), 1400);
      } catch (err) {
        console.error("Kopyalama hatası", err);
      }
    });
  });

  /* Nav hide/show on scroll direction */
  const nav = document.querySelector(".nav");
  let lastScroll = window.scrollY || window.pageYOffset;
  const hideThreshold = 30; // start hiding after a small scroll
  const delta = 4; // minimal movement to trigger
  let ticking = false;

  const handleScroll = (offset) => {
    if (!nav) return;
    nav.classList.toggle("scrolled", offset > 24);
    const diff = offset - lastScroll;
    const scrollingDown = diff > delta;
    const scrollingUp = diff < -delta;
    if (offset > hideThreshold && scrollingDown) {
      nav.classList.add("nav-hidden");
    } else if (scrollingUp) {
      nav.classList.remove("nav-hidden");
    }
    lastScroll = offset;
    ticking = false;
  };

  const onScroll = () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => handleScroll(window.scrollY || window.pageYOffset));
  };

  document.addEventListener("scroll", onScroll, { passive: true });
  handleScroll(lastScroll);

  /* Language toggle */
  const langToggle = document.querySelector(".lang-toggle");
  let currentLang = "tr";

  const applyTranslations = (lang) => {
    const dict = translations[lang] || translations.tr;
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.dataset.i18n;
      if (!key) return;
      const value = dict[key];
      if (value) el.innerHTML = value;
    });
    document.querySelectorAll("[data-i18n-alt]").forEach((el) => {
      const key = el.dataset.i18nAlt;
      if (!key) return;
      const value = dict[key];
      if (value) el.setAttribute("alt", value);
    });
    document.documentElement.lang = lang === "en" ? "en" : "tr";
    if (langToggle) {
      const nextLabel = lang === "tr" ? "EN" : "TR";
      const ariaLabel = lang === "tr" ? "Switch to English" : "Türkçeye geç";
      langToggle.textContent = nextLabel;
      langToggle.setAttribute("aria-label", ariaLabel);
    }
  };

  langToggle?.addEventListener("click", () => {
    currentLang = currentLang === "tr" ? "en" : "tr";
    applyTranslations(currentLang);
  });

  applyTranslations(currentLang);

  /* Smooth scroll for anchor links */
  const anchorLinks = document.querySelectorAll('a[href^="#"]');
  anchorLinks.forEach((link) => {
    link.addEventListener("click", (e) => {
      const targetId = link.getAttribute("href");
      const targetEl = document.querySelector(targetId);
      if (targetEl) {
        e.preventDefault();
        targetEl.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    });
  });
});
