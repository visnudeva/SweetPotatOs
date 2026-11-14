(function () {
  var STORAGE_KEY = "spo-lang";
  var STRINGS = {
    en: {
      "nav.aria": "Site",
      "nav.menu": "Menu",
      "nav.download": "Download",
      "nav.showroom": "Showroom",
      "nav.changelog": "Changelog",
      "nav.keybinds": "Keybinds",
      "nav.projects": "Projects",
      "nav.contact": "Contact",
      "nav.support": "Support",
      "lang.aria": "Language",
      "origin.made": "Made in Réunion Island",
      "origin.title": "Where is Réunion Island? Open map",
      "footer.year": "sweetpotatos 2026",
      "common.close": "Close",
      "common.saveOriginal": "Save original",

      "home.title": "SweetPotatOs — Arch-based Linux for old potato PCs",
      "home.desc": "Arch-based Linux distro with a live graphical ISO, SweetPotato Swirl desktop, and Calamares installer.",
      "home.tagline": "A unique minimalist distro made with love",
      "home.tag": "Arch-based Linux distro",
      "home.lead1": "A live graphical ISO with the SweetPotato <strong>Swirl</strong> desktop and a Calamares installer — because reviving slow old potato PCs shouldn't mean sacrificing looks for speed.",
      "home.lead2": "64-bit. The installer needs 1 GB of RAM and 8 GB of disk.<br> The ISO size and the <code>.sha256</code> file are on the <a href=\"https://sourceforge.net/projects/sweetpotatos/files/2026.11_Fourth_Harvest/\">Files page</a>.",
      "home.notice.aria": "Who this distro is for",
      "home.notice1": "This distro comes fully configured with a tiling window manager and gesture controls, ready to use out of the box without requiring any configuration changes.",
      "home.notice2": "However, <strong>pre-configured does not mean beginner-friendly</strong>. The interface follows a keyboard- and gesture-first workflow designed for power users. If you're unfamiliar with tiling window managers, keybindings, or gestures, even basic tasks such as opening a browser may not be immediately obvious.",
      "home.notice3": "Once the workflow is learned, the system is designed to be fast, efficient, and intuitive for users who prefer a keyboard-driven experience.",
      "home.what": "What you get",
      "home.what1": "Live <strong>Swirl</strong> session (<code>liveuser</code>, empty password, sudo without password)",
      "home.what2": "Autologin on tty1 → SweetPotato desktop",
      "home.what3": "Installer autostarts (also <code>Mod+i</code> / <em>Install SweetPotatOs</em>)",
      "home.what4": "Installed system uses GRUB and Ly on tty2 (pick the <strong>Swirl</strong> session)",
      "home.swirl": "Swirl",
      "home.swirl1": "<a href=\"projects.html#swirl\">Swirl</a> is the Wayland compositor SweetPotatOs ships: a light scrolling tiling window manager forked from Scroll/Sway, with a layout inspired by Niri. Windows sit as <strong>columns on an infinite horizontal strip</strong>; workspaces move vertically. Config stays Sway-compatible under <code>~/.config/swirl/</code>.",
      "home.swirl2": "Swirl ships the compositor together with <code>swirlbar</code>, <code>swaymsg</code>, the power-off bar, and <code>swirlmenu</code>. The older <code>swaybar</code>, <code>swaymsg</code>, and <code>swaynag</code> names still work as aliases.",
      "home.swirl3": "<strong>Smart Brightness</strong> is on by default: fullscreen video (mpv, YouTube in a browser, and similar) goes to max backlight, then your level comes back when you leave. Toggle with <code>Mod+Ctrl+b</code>.",
      "home.th.gesture": "Gesture",
      "home.th.action": "Action",
      "home.th.windows": "Windows",
      "home.th.autotile": "Auto-tile",
      "home.g1": "3-finger left / right",
      "home.g1a": "Scroll the window strip",
      "home.g2": "4-finger up / down",
      "home.g2a": "Next / previous workspace",
      "home.w1a": "Full width",
      "home.w2a": "50 / 50",
      "home.w3a": "New window half; others keep their size",
      "home.apps": "Default apps",
      "home.app.browser": "Browser",
      "home.app.files": "Files",
      "home.app.editor": "Editor",
      "home.app.calc": "Calculator",
      "home.app.term": "Terminal",
      "home.app.shell": "Shell",
      "home.app.video": "Video",
      "home.app.imageedit": "Image edit",
      "home.app.music": "Music / radio",
      "home.app.share": "Nearby share",
      "home.app.pdf": "PDF",
      "home.app.images": "Images",
      "home.app.torrents": "Torrents",
      "home.app.wall": "Wallpaper draw",
      "home.app.webcam": "Webcam",
      "home.app.color": "Color picker",
      "home.app.packages": "Packages",
      "home.app.disks": "Disks",
      "home.app.monitor": "System monitor",
      "home.updates": "Staying updated",
      "home.updates1": "From <strong>Third Harvest</strong> onward, desktop and SweetPotatOs package fixes ship as a <strong>rolling</strong> channel. On an installed system:",
      "home.updates2": "That installs or upgrades SPO-owned packages (theme, Swirl, Spore, Tuber, …) and refreshes shipped <code>~/.config</code> defaults. New apps added on the channel (for example Tuber replacing Transmission) land on the next update — you do not need a fresh ISO. It does <strong>not</strong> run a full Arch <code>pacman -Syu</code> (kernel / base stay on the Arch lane). New Harvest ISOs remain for fresh installs and marketing.",
      "home.updates3": "If experiments leave the desktop messy, reset shipped config to the channel defaults. It clears <code>user_edits</code> forks, keeps <code>~/.config/swirl/config.d/user</code> and your display layout, then sprouts like an update. Run it as your user (not root), then <code>Mod+Shift+c</code> if Swirl did not reload:",
      "home.overrides": "Custom Swirl config (overrides)",
      "home.overrides1": "Do <strong>not</strong> edit the main <code>~/.config/swirl/config</code> for personal binds — updates replace that file. Put your changes in the override file instead:",
      "home.overrides2": "It is seeded once on first install, included <strong>last</strong> by the main config (so your lines win), and is <strong>never overwritten</strong> by <code>sweetpotatos-update</code> / sprout. Edit it, then reload with <code>Mod+Shift+c</code>.",
      "home.overrides.who": "Who owns what",
      "home.th.path": "Path",
      "home.th.role": "Role",
      "home.role1": "SweetPotato defaults — replaced by updates",
      "home.role2": "Your overrides — yours forever",
      "home.role3": "Optional whole-file forks that also survive updates",
      "home.overrides.ex": "Examples",
      "home.overrides.exnote": " (add under the header in <code>config.d/user</code>):",
      "home.overrides.tip": "Tip: the cheatsheet (<code>Mod+?</code>) also points at this file. The full bind list is on the <a href=\"keybinds.html\">keybinds</a> page.",
      "home.usb": "Write ISO to USB",
      "home.usb.note": "Prefer verifying the download with the <code>.sha256</code> file next to the ISO on the Files page.",

      "contact.title": "SweetPotatOs — Contact",
      "contact.desc": "Send a message to the SweetPotatOs maintainer.",
      "contact.h1": "Contact",
      "contact.lead": "Questions, feedback, or “it runs on my potato”? Send a message — it goes straight to the maintainer’s inbox. No account needed.",
      "contact.privacy": "Your email is only used to reply to you — never shared, sold, or used for mailing lists.",
      "contact.name": "Name",
      "contact.email": "Email",
      "contact.message": "Message",
      "contact.send": "Send message",

      "support.title": "SweetPotatOs — Support",
      "support.desc": "Support SweetPotatOs development with Ko-fi, GitHub Sponsors, merch, or a free star on GitHub.",
      "support.h1": "Support SweetPotatOs",
      "support.lead": "SweetPotatOs is a one-person harvest — nights of compositor tweaks, package builds, and “does it still boot on that dusty laptop?” testing. If the project has been useful to you, here’s how you can keep the sweet potatoes growing.",
      "support.donate": "Donate",
      "support.kofi.p": "The simplest thank-you. A coffee (or a ube latte) goes straight into build time, hosting, and the next harvest — no subscription required unless you want one.",
      "support.kofi.btn": "Buy me a coffee",
      "support.merch": "Merch",
      "support.shop.p": "Wear the potato. Stickers, shirts, and prints from the Podgaia Designs collection — a little something for your desk or backpack, and a little something back to the project.",
      "support.shop.btn": "Visit the shop",
      "support.sponsor": "Sponsor",
      "support.gh.p": "Prefer to support from the same place you star and fork? GitHub Sponsors is a tidy monthly (or one-off) way to back the work behind Swirl, Spore, Tuber, Laniakea, and the distro itself. The Sponsors profile is still under review — until it goes live, Ko-fi is the best path.",
      "support.soon": "Coming soon",
      "support.free.aria": "Free ways to help",
      "support.free1": "<strong>Can’t donate right now?</strong> That’s completely fine. A <a href=\"https://github.com/visnudeva/SweetPotatOs\" target=\"_blank\" rel=\"noopener noreferrer\">star on GitHub</a> helps more than you’d think — it makes the project easier to find, cheers on the maintainer, and tells search engines this little distro is loved.",
      "support.free2": "Sharing a screenshot, mentioning SweetPotatOs to a friend with an old PC, or opening a thoughtful issue all count as real support too.",
      "support.star": "Star SweetPotatOs",

      "projects.title": "SweetPotatOs — Projects",
      "projects.desc": "SweetPotatOs source, Swirl, Spore, Tuber, Laniakea, and SweetPotato themer.",
      "projects.h1": "Projects",
      "projects.lead": "The distro, the compositor, the apps that ship with it, and SweetPotato themer.",
      "projects.spo": "The Arch live ISO, installer, and package channel.",
      "projects.swirl": "Scrolling tiling Wayland compositor. Columns sit on a horizontal strip.",
      "projects.spore": "Terminal web radio and local music, with a visualizer.",
      "projects.tuber": "Light terminal BitTorrent client.",
      "projects.laniakea": "Generative flow-field wallpaper. Watch it draw, pick a shape mask, then Apply.",
      "projects.themer": "Desktop themer for Swirl: colors, bar, lock screen, and terminal.",

      "keybinds.title": "SweetPotatOs — Keybinds",
      "keybinds.desc": "SweetPotatOs Swirl keybinds. Mod is the Super / Windows key.",
      "keybinds.h1": "Keybinds",
      "keybinds.lead": "<code>Mod</code> is the Super / Windows key. On the desktop, <code>Mod+?</code> opens this same list.",
      "keybinds.th.bind": "Bind",
      "keybinds.th.action": "Action",
      "keybinds.th.key": "Key",
      "keybinds.th.command": "Command",
      "keybinds.th.note": "Note",
      "keybinds.th.gesture": "Gesture",
      "keybinds.apps": "Apps",
      "keybinds.window": "Window / layout",
      "keybinds.ws": "Workspaces / overview",
      "keybinds.display": "Displays / look",
      "keybinds.system": "System",
      "keybinds.media": "Screenshots / media keys",
      "keybinds.gestures": "Gestures",
      "keybinds.resize": "Resize mode",
      "keybinds.resize.after": "After <code>Mod+Shift+r</code>:",
      "keybinds.customize": "Customize",
      "keybinds.customize.p": "Edit <code>~/.config/swirl/config.d/user</code>, then <code>Mod+Shift+c</code> (survives updates; later binds win over defaults). See <a href=\"index.html#overrides\">custom Swirl config</a> on the home page.",
      "keybinds.updates": "Desktop / package updates",
      "keybinds.updates.p": "A notice appears once a week when updates are ready. After an update, a note says what changed. Run pruning as your user, then <code>Mod+Shift+c</code> if Swirl did not reload.",
      "kb.launcher": "App launcher (Esc closes it)",
      "kb.terminal": "Terminal (foot, fish)",
      "kb.browser": "Web browser (Brave Origin)",
      "kb.files": "Files (Thunar)",
      "kb.editor": "Editor (Geany)",
      "kb.music": "Music / radio (Spore)",
      "kb.torrents": "Torrents (tuber)",
      "kb.network": "Network (Wi‑Fi)",
      "kb.installer": "Installer (live ISO)",
      "kb.close": "Close window",
      "kb.col": "Toggle column 100% ↔ 50%",
      "kb.full": "Fullscreen",
      "kb.float": "Floating toggle",
      "kb.split": "Split horizontal / vertical",
      "kb.parent": "Focus parent",
      "kb.focus.vim": "Focus left / down / up",
      "kb.focus.arrow": "Focus left / right",
      "kb.move.vim": "Move window (vim keys)",
      "kb.move.arrow": "Move window",
      "kb.drag": "Move floating window",
      "kb.rdrag": "Resize floating window",
      "kb.overview": "Overview (desktop stripes, all windows)",
      "kb.leave.ov": "Leave overview (click focuses that window/desktop)",
      "kb.ws.ud": "Workspace above / below (exits overview)",
      "kb.move.ws": "Move window to workspace above / below",
      "kb.ws.num": "Workspace 1–10 (exits overview)",
      "kb.move.num": "Move window to workspace 1–10",
      "kb.wall": "Wallpaper",
      "kb.laniakea": "Laniakea",
      "kb.themer": "SweetPotato themer",
      "kb.gaps": "Corners and gaps",
      "kb.displays": "Displays (nwg-displays)",
      "kb.bright": "Smart Brightness (toggle; fullscreen video → max)",
      "kb.lock": "Lock",
      "kb.caffeine": "Caffeine (idle lock off)",
      "kb.reload": "Reload config",
      "kb.exit": "Exit Swirl",
      "kb.power": "Power menu",
      "kb.resize": "Resize mode",
      "kb.cheat": "Keybind cheatsheet (toggle)",
      "kb.ss.full": "Screenshot (full)",
      "kb.ss.region": "Screenshot (region)",
      "kb.record": "Screen record toggle",
      "kb.audio": "Volume / mute / mic / media",
      "kb.brightness": "Brightness up / down",
      "kb.g1": "3-finger L/R",
      "kb.g1a": "Scroll the window strip",
      "kb.g2": "4-finger up/down",
      "kb.g2a": "Next / previous workspace",
      "kb.resize.keys": "Resize focused window",
      "kb.resize.leave": "Leave resize mode",
      "kb.upd": "Update the desktop",
      "kb.prune": "Reset shipped desktop config after experiments go wrong (keeps <code>config.d/user</code> and kanshi; clears <code>user_edits</code>)",

      "showroom.title": "SweetPotatOs — Showroom",
      "showroom.desc": "SweetPotatOs screencast, 9to5Linux review, desktop screenshots, themer, Laniakea, and wallpapers.",
      "showroom.h1": "Showroom",
      "showroom.lead": "The desktop in motion, a community review, screenshots, the color themes, Laniakea, and the wallpapers that ship with the theme.",
      "showroom.screencast": "Screencast",
      "showroom.screencast.cap": "Swirl on SweetPotatOs — Fourth Harvest",
      "showroom.screencast.meta": "2m 36s screencast",
      "showroom.review": "Community review",
      "showroom.review.hint": "9to5Linux walks through Fourth Harvest — Swirl, the app set, and why old potato PCs are the point.",
      "showroom.shots": "Screenshots",
      "showroom.shots.hint": "Click a still to open it larger.",
      "showroom.cap.gaps": "Desktop with gaps",
      "showroom.cap.spore": "Spore radio",
      "showroom.cap.keybinds": "Keybinds",
      "showroom.cap.files": "Files and terminal",
      "showroom.cap.themer": "Themer",
      "showroom.cap.overview": "Overview",
      "showroom.themes": "Themes",
      "showroom.themes.p": "<code>Mod+Ctrl+t</code> opens SweetPotato themer: the dark and light presets, plus sliders for the accent and highlight. Apply commits the choice. The same controls are below. A slider keeps that preset’s lightness and saturation and changes the hue. On the desktop, windows that are already open refresh their accents. The surface stays until those windows are closed and opened again.",
      "showroom.themer.dark": "Dark",
      "showroom.themer.light": "Light",
      "showroom.themer.accent": "Accent",
      "showroom.themer.highlight": "Highlight",
      "showroom.themer.reset": "Reset",
      "showroom.themer.colors": "Your colors",
      "showroom.laniakea.h": "Laniakea",
      "showroom.laniakea.p": "Open it from the app menu. A generative flow field draws inside a shape mask; <strong>Apply</strong> sets it as the wallpaper. The same shape picker sits below as a live preview — change the mask or hit Redraw to start a new field.",
      "showroom.laniakea.shape": "Shape mask",
      "showroom.laniakea.redraw": "Redraw",
      "showroom.laniakea.hint": "Preview only — Apply lives in the desktop app.",
      "showroom.laniakea.live": "Live draw",
      "showroom.walls": "Wallpapers",
      "showroom.walls.p": "New installs start on <strong>Neon kanji default</strong>. On the desktop, <code>Mod+Ctrl+w</code> opens the picker. Rest the pointer on either side to move through them. The one in front opens here, and you can save the original from that view.",
      "showroom.prev": "Previous wallpaper",
      "showroom.next": "Next wallpaper",
      "showroom.mode.aria": "Dark or light",
      "showroom.theme.aria": "Color theme",
      "showroom.accent.aria": "Accent hue",
      "showroom.highlight.aria": "Highlight hue",
      "showroom.mask.circle": "Circle",
      "showroom.mask.triup": "Triangle up",
      "showroom.mask.tridn": "Triangle down",
      "showroom.mask.diamond": "Diamond",
      "showroom.mask.hex": "Hexagon",
      "showroom.mask.rvert": "Vertical rectangle",
      "showroom.mask.rhoriz": "Horizontal rectangle",
      "showroom.mask.wide": "Wide",

      "changelog.title": "SweetPotatOs — Changelog",
      "changelog.desc": "Release notes for SweetPotatOs Harvest ISOs from First Harvest onward.",
      "changelog.h1": "Changelog",
      "changelog.tag": "Harvest releases",
      "changelog.lead": "What changed in each SweetPotatOs ISO from <strong>First Harvest</strong> onward. Newer releases are listed first.",
      "changelog.rolling.aria": "Fifth Harvest changes on the update channel",
      "changelog.rolling1": "Desktop changes below are already live for <strong>Fourth Harvest</strong>",
      "changelog.rolling2": "installs via <code>sudo sweetpotatos-update</code>",
      "changelog.rolling3": "No need to wait for the Fifth Harvest ISO.",
      "changelog.out.aria": "Fourth Harvest released",
      "changelog.out.now": "Out now",
      "changelog.out.sub": "Released 28 October 2026 ·",
      "changelog.fifth.label": "<strong>Fifth Harvest</strong> ISO — planned release",
      "changelog.about": "about",
      "changelog.daysLeft": "days left",
      "changelog.dayLeft": "day left",
      "changelog.today": "today",
      "changelog.releasedDec": "Released December 2026",
      "changelog.toc": "Releases",
      "changelog.planned": "(planned ISO)",
      "changelog.expand": "Expand",
      "changelog.collapse": "Collapse",
      "changelog.notes.en": "Release notes stay in English (technical detail)."
    },
    fr: {
      "nav.aria": "Site",
      "nav.menu": "Menu",
      "nav.download": "Télécharger",
      "nav.showroom": "Vitrine",
      "nav.changelog": "Journal",
      "nav.keybinds": "Raccourcis",
      "nav.projects": "Projets",
      "nav.contact": "Contact",
      "nav.support": "Soutenir",
      "lang.aria": "Langue",
      "origin.made": "Fabriqué à La Réunion",
      "origin.title": "Où est La Réunion ? Ouvrir la carte",
      "footer.year": "sweetpotatos 2026",
      "common.close": "Fermer",
      "common.saveOriginal": "Enregistrer l’original",

      "home.title": "SweetPotatOs — Linux Arch pour vieux PC patates",
      "home.desc": "Distribution Linux basée sur Arch, ISO graphique live, bureau SweetPotato Swirl et installateur Calamares.",
      "home.tagline": "Une distro minimaliste unique, faite avec amour",
      "home.tag": "Distribution Linux basée sur Arch",
      "home.lead1": "Une ISO graphique live avec le bureau SweetPotato <strong>Swirl</strong> et l’installateur Calamares — parce que faire revivre de vieux PC patates ne devrait pas vouloir dire sacrifier le style pour la vitesse.",
      "home.lead2": "64 bits. L’installateur demande 1 Go de RAM et 8 Go de disque.<br> La taille de l’ISO et le fichier <code>.sha256</code> sont sur la <a href=\"https://sourceforge.net/projects/sweetpotatos/files/2026.11_Fourth_Harvest/\">page Fichiers</a>.",
      "home.notice.aria": "À qui s’adresse cette distro",
      "home.notice1": "Cette distro arrive entièrement configurée avec un gestionnaire de fenêtres en mosaïque et des gestes, prête à l’emploi sans réglages obligatoires.",
      "home.notice2": "Cependant, <strong>préconfiguré ne veut pas dire débutant</strong>. L’interface privilégie le clavier et les gestes, pour des utilisateurs avertis. Si les mosaïques, raccourcis ou gestes ne vous sont pas familiers, même ouvrir un navigateur peut ne pas être évident au premier abord.",
      "home.notice3": "Une fois le flux appris, le système est pensé pour être rapide, efficace et intuitif pour qui préfère une expérience pilotée au clavier.",
      "home.what": "Ce que vous obtenez",
      "home.what1": "Session <strong>Swirl</strong> live (<code>liveuser</code>, mot de passe vide, sudo sans mot de passe)",
      "home.what2": "Connexion auto sur tty1 → bureau SweetPotato",
      "home.what3": "L’installateur démarre tout seul (aussi <code>Mod+i</code> / <em>Install SweetPotatOs</em>)",
      "home.what4": "Système installé avec GRUB et Ly sur tty2 (choisir la session <strong>Swirl</strong>)",
      "home.swirl": "Swirl",
      "home.swirl1": "<a href=\"projects.html#swirl\">Swirl</a> est le compositeur Wayland livré avec SweetPotatOs : un gestionnaire de fenêtres en mosaïque défilante, fourche de Scroll/Sway, avec une disposition inspirée de Niri. Les fenêtres sont des <strong>colonnes sur une bande horizontale infinie</strong> ; les espaces de travail bougent à la verticale. La config reste compatible Sway sous <code>~/.config/swirl/</code>.",
      "home.swirl2": "Swirl livre le compositeur avec <code>swirlbar</code>, <code>swaymsg</code>, la barre d’extinction et <code>swirlmenu</code>. Les anciens noms <code>swaybar</code>, <code>swaymsg</code> et <code>swaynag</code> restent des alias.",
      "home.swirl3": "<strong>Smart Brightness</strong> est activé par défaut : la vidéo plein écran (mpv, YouTube dans un navigateur, etc.) monte le rétroéclairage au max, puis votre niveau revient en sortant. Bascule avec <code>Mod+Ctrl+b</code>.",
      "home.th.gesture": "Geste",
      "home.th.action": "Action",
      "home.th.windows": "Fenêtres",
      "home.th.autotile": "Mosaïque auto",
      "home.g1": "3 doigts gauche / droite",
      "home.g1a": "Faire défiler la bande de fenêtres",
      "home.g2": "4 doigts haut / bas",
      "home.g2a": "Espace de travail suivant / précédent",
      "home.w1a": "Pleine largeur",
      "home.w2a": "50 / 50",
      "home.w3a": "Nouvelle fenêtre à moitié ; les autres gardent leur taille",
      "home.apps": "Applications par défaut",
      "home.app.browser": "Navigateur",
      "home.app.files": "Fichiers",
      "home.app.editor": "Éditeur",
      "home.app.calc": "Calculatrice",
      "home.app.term": "Terminal",
      "home.app.shell": "Shell",
      "home.app.video": "Vidéo",
      "home.app.imageedit": "Retouche image",
      "home.app.music": "Musique / radio",
      "home.app.share": "Partage à proximité",
      "home.app.pdf": "PDF",
      "home.app.images": "Images",
      "home.app.torrents": "Torrents",
      "home.app.wall": "Fond d’écran génératif",
      "home.app.webcam": "Webcam",
      "home.app.color": "Pipette couleur",
      "home.app.packages": "Paquets",
      "home.app.disks": "Disques",
      "home.app.monitor": "Moniteur système",
      "home.updates": "Rester à jour",
      "home.updates1": "Depuis la <strong>Third Harvest</strong>, les correctifs du bureau et des paquets SweetPotatOs arrivent en canal <strong>rolling</strong>. Sur un système installé :",
      "home.updates2": "Cela installe ou met à jour les paquets SPO (thème, Swirl, Spore, Tuber, …) et rafraîchit les défauts de <code>~/.config</code>. Les nouvelles apps du canal (par ex. Tuber à la place de Transmission) arrivent à la prochaine mise à jour — pas besoin d’une nouvelle ISO. Cela ne lance <strong>pas</strong> un <code>pacman -Syu</code> Arch complet (noyau / base restent sur la voie Arch). Les ISO Harvest restent pour les installs neuves et la com.",
      "home.updates3": "Si des expériences ont embrouillé le bureau, réinitialisez la config livrée aux défauts du canal. Cela efface les forks <code>user_edits</code>, garde <code>~/.config/swirl/config.d/user</code> et votre disposition d’écran, puis sprout comme une mise à jour. Lancez-le en tant qu’utilisateur (pas root), puis <code>Mod+Shift+c</code> si Swirl ne s’est pas rechargé :",
      "home.overrides": "Config Swirl perso (surcharges)",
      "home.overrides1": "Ne <strong>modifiez pas</strong> le fichier principal <code>~/.config/swirl/config</code> pour vos raccourcis — les mises à jour le remplacent. Placez vos changements dans le fichier de surcharge :",
      "home.overrides2": "Il est créé une fois à l’install, inclus en <strong>dernier</strong> par la config principale (vos lignes gagnent), et n’est <strong>jamais écrasé</strong> par <code>sweetpotatos-update</code> / sprout. Éditez-le, puis rechargez avec <code>Mod+Shift+c</code>.",
      "home.overrides.who": "Qui possède quoi",
      "home.th.path": "Chemin",
      "home.th.role": "Rôle",
      "home.role1": "Défauts SweetPotato — remplacés par les mises à jour",
      "home.role2": "Vos surcharges — à vous pour toujours",
      "home.role3": "Forks de fichiers entiers optionnels qui survivent aussi aux mises à jour",
      "home.overrides.ex": "Exemples",
      "home.overrides.exnote": " (à ajouter sous l’en-tête dans <code>config.d/user</code>) :",
      "home.overrides.tip": "Astuce : l’aide-mémoire (<code>Mod+?</code>) pointe aussi vers ce fichier. La liste complète des raccourcis est sur la page <a href=\"keybinds.html\">raccourcis</a>.",
      "home.usb": "Écrire l’ISO sur une clé USB",
      "home.usb.note": "Préférez vérifier le téléchargement avec le fichier <code>.sha256</code> à côté de l’ISO sur la page Fichiers.",

      "contact.title": "SweetPotatOs — Contact",
      "contact.desc": "Envoyer un message au mainteneur de SweetPotatOs.",
      "contact.h1": "Contact",
      "contact.lead": "Questions, retours, ou « ça tourne sur ma patate » ? Envoyez un message — il arrive directement dans la boîte du mainteneur. Pas de compte requis.",
      "contact.privacy": "Votre e-mail ne sert qu’à vous répondre — jamais partagé, vendu, ni utilisé pour des listes.",
      "contact.name": "Nom",
      "contact.email": "E-mail",
      "contact.message": "Message",
      "contact.send": "Envoyer",

      "support.title": "SweetPotatOs — Soutenir",
      "support.desc": "Soutenir le développement de SweetPotatOs via Ko-fi, GitHub Sponsors, merch, ou une étoile gratuite sur GitHub.",
      "support.h1": "Soutenir SweetPotatOs",
      "support.lead": "SweetPotatOs, c’est une récolte en solo — des nuits de réglages de compositeur, de builds de paquets, et de « ça démarre encore sur ce vieux portable poussiéreux ? ». Si le projet vous a servi, voici comment faire pousser les patates douces.",
      "support.donate": "Donner",
      "support.kofi.p": "Le merci le plus simple. Un café (ou un latte ube) va directement dans le temps de build, l’hébergement et la prochaine harvest — pas d’abonnement obligatoire.",
      "support.kofi.btn": "Offrir un café",
      "support.merch": "Merch",
      "support.shop.p": "Portez la patate. Stickers, t-shirts et prints de la collection Podgaia Designs — un petit quelque chose pour le bureau ou le sac, et un petit quelque chose pour le projet.",
      "support.shop.btn": "Voir la boutique",
      "support.sponsor": "Sponsor",
      "support.gh.p": "Vous préférez soutenir depuis le même endroit où vous mettez des étoiles ? GitHub Sponsors est une façon propre (mensuelle ou ponctuelle) de soutenir Swirl, Spore, Tuber, Laniakea et la distro. Le profil Sponsors est encore en revue — en attendant, Ko-fi est le meilleur chemin.",
      "support.soon": "Bientôt",
      "support.free.aria": "Aider gratuitement",
      "support.free1": "<strong>Pas possible de donner pour l’instant ?</strong> Aucun souci. Une <a href=\"https://github.com/visnudeva/SweetPotatOs\" target=\"_blank\" rel=\"noopener noreferrer\">étoile sur GitHub</a> aide plus qu’on ne croit — elle rend le projet plus visible, encourage le mainteneur, et dit aux moteurs de recherche que cette petite distro est aimée.",
      "support.free2": "Partager une capture, parler de SweetPotatOs à un ami avec un vieux PC, ou ouvrir une issue soignée, ça compte aussi comme un vrai soutien.",
      "support.star": "Étoiler SweetPotatOs",

      "projects.title": "SweetPotatOs — Projets",
      "projects.desc": "Sources SweetPotatOs, Swirl, Spore, Tuber, Laniakea et le themer SweetPotato.",
      "projects.h1": "Projets",
      "projects.lead": "La distro, le compositeur, les apps livrées, et le themer SweetPotato.",
      "projects.spo": "L’ISO live Arch, l’installateur et le canal de paquets.",
      "projects.swirl": "Compositeur Wayland en mosaïque défilante. Les colonnes vivent sur une bande horizontale.",
      "projects.spore": "Radio web et musique locale en terminal, avec visualiseur.",
      "projects.tuber": "Client BitTorrent léger en terminal.",
      "projects.laniakea": "Fond d’écran génératif en champs de flux. Regardez le dessin, choisissez un masque, puis Apply.",
      "projects.themer": "Themer de bureau pour Swirl : couleurs, barre, écran de verrouillage et terminal.",

      "keybinds.title": "SweetPotatOs — Raccourcis",
      "keybinds.desc": "Raccourcis Swirl de SweetPotatOs. Mod est la touche Super / Windows.",
      "keybinds.h1": "Raccourcis",
      "keybinds.lead": "<code>Mod</code> est la touche Super / Windows. Sur le bureau, <code>Mod+?</code> ouvre cette même liste.",
      "keybinds.th.bind": "Raccourci",
      "keybinds.th.action": "Action",
      "keybinds.th.key": "Touche",
      "keybinds.th.command": "Commande",
      "keybinds.th.note": "Note",
      "keybinds.th.gesture": "Geste",
      "keybinds.apps": "Applications",
      "keybinds.window": "Fenêtre / disposition",
      "keybinds.ws": "Espaces de travail / aperçu",
      "keybinds.display": "Écrans / apparence",
      "keybinds.system": "Système",
      "keybinds.media": "Captures / touches multimédia",
      "keybinds.gestures": "Gestes",
      "keybinds.resize": "Mode redimensionnement",
      "keybinds.resize.after": "Après <code>Mod+Shift+r</code> :",
      "keybinds.customize": "Personnaliser",
      "keybinds.customize.p": "Éditez <code>~/.config/swirl/config.d/user</code>, puis <code>Mod+Shift+c</code> (survit aux mises à jour ; les binds plus bas gagnent). Voir la <a href=\"index.html#overrides\">config Swirl perso</a> sur l’accueil.",
      "keybinds.updates": "Mises à jour bureau / paquets",
      "keybinds.updates.p": "Un avis apparaît une fois par semaine quand des mises à jour sont prêtes. Après une mise à jour, une note dit ce qui a changé. Lancez le pruning en tant qu’utilisateur, puis <code>Mod+Shift+c</code> si Swirl ne s’est pas rechargé.",
      "kb.launcher": "Lanceur d’apps (Échap pour fermer)",
      "kb.terminal": "Terminal (foot, fish)",
      "kb.browser": "Navigateur web (Brave Origin)",
      "kb.files": "Fichiers (Thunar)",
      "kb.editor": "Éditeur (Geany)",
      "kb.music": "Musique / radio (Spore)",
      "kb.torrents": "Torrents (tuber)",
      "kb.network": "Réseau (Wi‑Fi)",
      "kb.installer": "Installateur (ISO live)",
      "kb.close": "Fermer la fenêtre",
      "kb.col": "Basculer colonne 100 % ↔ 50 %",
      "kb.full": "Plein écran",
      "kb.float": "Basculer flottant",
      "kb.split": "Couper horizontal / vertical",
      "kb.parent": "Focus parent",
      "kb.focus.vim": "Focus gauche / bas / haut",
      "kb.focus.arrow": "Focus gauche / droite",
      "kb.move.vim": "Déplacer la fenêtre (touches vim)",
      "kb.move.arrow": "Déplacer la fenêtre",
      "kb.drag": "Déplacer une fenêtre flottante",
      "kb.rdrag": "Redimensionner une fenêtre flottante",
      "kb.overview": "Aperçu (bandes de bureaux, toutes les fenêtres)",
      "kb.leave.ov": "Quitter l’aperçu (clic = focus fenêtre/bureau)",
      "kb.ws.ud": "Espace au-dessus / en dessous (quitte l’aperçu)",
      "kb.move.ws": "Envoyer la fenêtre à l’espace au-dessus / en dessous",
      "kb.ws.num": "Espace 1–10 (quitte l’aperçu)",
      "kb.move.num": "Envoyer la fenêtre vers l’espace 1–10",
      "kb.wall": "Fond d’écran",
      "kb.laniakea": "Laniakea",
      "kb.themer": "Themer SweetPotato",
      "kb.gaps": "Coins et espacements",
      "kb.displays": "Écrans (nwg-displays)",
      "kb.bright": "Smart Brightness (bascule ; vidéo plein écran → max)",
      "kb.lock": "Verrouiller",
      "kb.caffeine": "Caféine (pas de verrouillage d’inactivité)",
      "kb.reload": "Recharger la config",
      "kb.exit": "Quitter Swirl",
      "kb.power": "Menu d’alimentation",
      "kb.resize": "Mode redimensionnement",
      "kb.cheat": "Aide-mémoire des raccourcis (bascule)",
      "kb.ss.full": "Capture (plein écran)",
      "kb.ss.region": "Capture (région)",
      "kb.record": "Enregistrement d’écran (bascule)",
      "kb.audio": "Volume / muet / micro / média",
      "kb.brightness": "Luminosité haut / bas",
      "kb.g1": "3 doigts G/D",
      "kb.g1a": "Faire défiler la bande de fenêtres",
      "kb.g2": "4 doigts haut/bas",
      "kb.g2a": "Espace de travail suivant / précédent",
      "kb.resize.keys": "Redimensionner la fenêtre focalisée",
      "kb.resize.leave": "Quitter le mode redimensionnement",
      "kb.upd": "Mettre à jour le bureau",
      "kb.prune": "Réinitialiser la config bureau livrée après de mauvaises expériences (garde <code>config.d/user</code> et kanshi ; efface <code>user_edits</code>)",

      "showroom.title": "SweetPotatOs — Vitrine",
      "showroom.desc": "Screencast SweetPotatOs, revue 9to5Linux, captures, themer, Laniakea et fonds d’écran.",
      "showroom.h1": "Vitrine",
      "showroom.lead": "Le bureau en mouvement, une revue communautaire, des captures, les thèmes de couleurs, Laniakea, et les fonds livrés avec le thème.",
      "showroom.screencast": "Screencast",
      "showroom.screencast.cap": "Swirl sur SweetPotatOs — Fourth Harvest",
      "showroom.screencast.meta": "Screencast de 2 min 36",
      "showroom.review": "Revue communautaire",
      "showroom.review.hint": "9to5Linux parcourt la Fourth Harvest — Swirl, le jeu d’apps, et pourquoi les vieux PC patates sont le point.",
      "showroom.shots": "Captures d’écran",
      "showroom.shots.hint": "Cliquez une image pour l’agrandir.",
      "showroom.cap.gaps": "Bureau avec espacements",
      "showroom.cap.spore": "Radio Spore",
      "showroom.cap.keybinds": "Raccourcis",
      "showroom.cap.files": "Fichiers et terminal",
      "showroom.cap.themer": "Themer",
      "showroom.cap.overview": "Aperçu",
      "showroom.themes": "Thèmes",
      "showroom.themes.p": "<code>Mod+Ctrl+t</code> ouvre le themer SweetPotato : presets sombre et clair, plus curseurs pour l’accent et la surbrillance. Apply valide le choix. Les mêmes contrôles sont ci-dessous. Un curseur garde la luminosité et la saturation du preset et change la teinte. Sur le bureau, les fenêtres déjà ouvertes rafraîchissent leurs accents. La surface reste jusqu’à fermeture/réouverture de ces fenêtres.",
      "showroom.themer.dark": "Sombre",
      "showroom.themer.light": "Clair",
      "showroom.themer.accent": "Accent",
      "showroom.themer.highlight": "Surbrillance",
      "showroom.themer.reset": "Réinitialiser",
      "showroom.themer.colors": "Vos couleurs",
      "showroom.laniakea.h": "Laniakea",
      "showroom.laniakea.p": "Ouvrez-le depuis le menu d’apps. Un champ de flux génératif se dessine dans un masque ; <strong>Apply</strong> l’applique comme fond d’écran. Le même sélecteur de forme est ci-dessous en aperçu live — changez le masque ou Redraw pour un nouveau champ.",
      "showroom.laniakea.shape": "Masque de forme",
      "showroom.laniakea.redraw": "Redraw",
      "showroom.laniakea.hint": "Aperçu seulement — Apply est dans l’app bureau.",
      "showroom.laniakea.live": "Dessin live",
      "showroom.walls": "Fonds d’écran",
      "showroom.walls.p": "Les installs neuves démarrent sur <strong>Neon kanji default</strong>. Sur le bureau, <code>Mod+Ctrl+w</code> ouvre le sélecteur. Posez le pointeur sur les côtés pour parcourir. Celui devant s’ouvre ici, et vous pouvez enregistrer l’original depuis cette vue.",
      "showroom.prev": "Fond précédent",
      "showroom.next": "Fond suivant",
      "showroom.mode.aria": "Sombre ou clair",
      "showroom.theme.aria": "Thème de couleur",
      "showroom.accent.aria": "Teinte d’accent",
      "showroom.highlight.aria": "Teinte de surbrillance",
      "showroom.mask.circle": "Cercle",
      "showroom.mask.triup": "Triangle haut",
      "showroom.mask.tridn": "Triangle bas",
      "showroom.mask.diamond": "Losange",
      "showroom.mask.hex": "Hexagone",
      "showroom.mask.rvert": "Rectangle vertical",
      "showroom.mask.rhoriz": "Rectangle horizontal",
      "showroom.mask.wide": "Large",

      "changelog.title": "SweetPotatOs — Journal",
      "changelog.desc": "Notes de version des ISO Harvest SweetPotatOs depuis First Harvest.",
      "changelog.h1": "Journal",
      "changelog.tag": "Versions Harvest",
      "changelog.lead": "Ce qui a changé dans chaque ISO SweetPotatOs depuis la <strong>First Harvest</strong>. Les plus récentes en premier.",
      "changelog.rolling.aria": "Changements Fifth Harvest sur le canal de mise à jour",
      "changelog.rolling1": "Les changements bureau ci-dessous sont déjà en ligne pour les installs <strong>Fourth Harvest</strong>",
      "changelog.rolling2": "via <code>sudo sweetpotatos-update</code>",
      "changelog.rolling3": "Pas besoin d’attendre l’ISO Fifth Harvest.",
      "changelog.out.aria": "Fourth Harvest publiée",
      "changelog.out.now": "Disponible",
      "changelog.out.sub": "Publiée le 28 octobre 2026 ·",
      "changelog.fifth.label": "ISO <strong>Fifth Harvest</strong> — sortie prévue",
      "changelog.about": "environ",
      "changelog.daysLeft": "jours restants",
      "changelog.dayLeft": "jour restant",
      "changelog.today": "aujourd’hui",
      "changelog.releasedDec": "Publiée en décembre 2026",
      "changelog.toc": "Versions",
      "changelog.planned": "(ISO prévue)",
      "changelog.expand": "Déplier",
      "changelog.collapse": "Replier",
      "changelog.notes.en": "Les notes de version restent en anglais (détail technique)."
    }
  };

  var MAP_URL =
    "https://www.openstreetmap.org/?mlat=-21.115&mlon=55.536#map=5/-21.12/55.54";

  function currentLang() {
    var fromDom = document.documentElement.getAttribute("data-lang");
    if (fromDom === "en" || fromDom === "fr") return fromDom;
    try {
      var stored = localStorage.getItem(STORAGE_KEY);
      if (stored === "en" || stored === "fr") return stored;
    } catch (e) {}
    var nav = (
      (navigator.languages && navigator.languages[0]) ||
      navigator.language ||
      "en"
    ).toLowerCase();
    return nav.indexOf("fr") === 0 ? "fr" : "en";
  }

  function t(key, lang) {
    lang = lang || currentLang();
    var pack = STRINGS[lang] || STRINGS.en;
    if (pack[key] != null) return pack[key];
    if (STRINGS.en[key] != null) return STRINGS.en[key];
    return null;
  }

  function setText(el, value) {
    if (el.hasAttribute("data-i18n-html")) {
      el.innerHTML = value;
    } else {
      el.textContent = value;
    }
  }

  function apply(lang) {
    if (lang !== "en" && lang !== "fr") lang = "en";
    document.documentElement.lang = lang;
    document.documentElement.setAttribute("data-lang", lang);
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch (e) {}

    var pack = STRINGS[lang] || STRINGS.en;

    Array.prototype.forEach.call(
      document.querySelectorAll("[data-i18n]"),
      function (el) {
        var key = el.getAttribute("data-i18n");
        if (key && pack[key] != null) el.textContent = pack[key];
      }
    );

    Array.prototype.forEach.call(
      document.querySelectorAll("[data-i18n-html]"),
      function (el) {
        var key = el.getAttribute("data-i18n-html");
        if (key && pack[key] != null) el.innerHTML = pack[key];
      }
    );

    Array.prototype.forEach.call(
      document.querySelectorAll("[data-i18n-aria]"),
      function (el) {
        var key = el.getAttribute("data-i18n-aria");
        if (key && pack[key] != null) el.setAttribute("aria-label", pack[key]);
      }
    );

    Array.prototype.forEach.call(
      document.querySelectorAll("[data-i18n-title]"),
      function (el) {
        var key = el.getAttribute("data-i18n-title");
        if (key && pack[key] != null) el.setAttribute("title", pack[key]);
      }
    );

    Array.prototype.forEach.call(
      document.querySelectorAll("[data-i18n-placeholder]"),
      function (el) {
        var key = el.getAttribute("data-i18n-placeholder");
        if (key && pack[key] != null) el.setAttribute("placeholder", pack[key]);
      }
    );

    var titleKey = document.documentElement.getAttribute("data-i18n-page-title");
    if (titleKey && pack[titleKey] != null) document.title = pack[titleKey];

    var descKey = document.documentElement.getAttribute("data-i18n-page-desc");
    if (descKey && pack[descKey] != null) {
      var meta = document.querySelector('meta[name="description"]');
      if (meta) meta.setAttribute("content", pack[descKey]);
    }

    Array.prototype.forEach.call(
      document.querySelectorAll("[data-set-lang]"),
      function (btn) {
        var active = btn.getAttribute("data-set-lang") === lang;
        btn.setAttribute("aria-pressed", active ? "true" : "false");
        btn.classList.toggle("is-active", active);
      }
    );

    // Vault tagline cache: refresh clean string after language apply
    var tagline = document.querySelector("[data-vault-tagline]");
    if (tagline && pack["home.tagline"] != null) {
      tagline.setAttribute("data-i18n-clean", pack["home.tagline"]);
    }

    document.dispatchEvent(
      new CustomEvent("spo:lang", { detail: { lang: lang } })
    );
  }

  function wireLangSwitch() {
    document.addEventListener("click", function (event) {
      var btn = event.target.closest("[data-set-lang]");
      if (!btn) return;
      event.preventDefault();
      apply(btn.getAttribute("data-set-lang"));
    });
  }

  window.SweetPotatOsI18n = {
    t: t,
    apply: apply,
    currentLang: currentLang,
    MAP_URL: MAP_URL,
    STRINGS: STRINGS
  };

  wireLangSwitch();
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      apply(currentLang());
    });
  } else {
    apply(currentLang());
  }
})();
