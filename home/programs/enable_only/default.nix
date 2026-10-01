{ pkgs, inputs, ... }:

{
  # 允许 Home Manager 管理自己
  programs.home-manager.enable = true;

  programs.tmux.enable = true;

  home.packages = with pkgs; [
    eza
    fzf
    zoxide
    peazip
    lutris
    protonplus
    protonup-qt
    hmcl
    kdePackages.plasma-browser-integration
    libreoffice-qt-stable
    (prismlauncher.override {
      additionalLibs = with pkgs; [
        nss
        nspr
        libgbm
        glib
        at-spi2-core
        cups
        libdrm
        libxcomposite
        libxdamage
        libxfixes
        expat
        libxcb
        libxkbcommon
        dbus
        pango
        cairo
      ];
    })
    grc
    adwaita-icon-theme
    wl-clipboard
    xclip
    go-musicfox
    lazydocker
    helix
    btop
    dust
    tealdeer
    sops
    foliate
    obsidian
    wechat
    qq
    rnote
    baidunetdisk
    cc-switch
    claude-code
    bilibili
    # zotero 10.0.2 只能跑在 Firefox 140 ESR 上（原因见 flake.nix 的 nixpkgs-fx140）
    (zotero.override {
      firefox-esr-153-unwrapped =
        inputs.nixpkgs-fx140.legacyPackages.${pkgs.stdenv.hostPlatform.system}.firefox-esr-140-unwrapped;
    })
    codex-app
    bubblewrap

    catppuccin-kde # 提供全局主题、色彩方案和窗口装饰
    catppuccin-papirus-folders # 提供配套图标
    bibata-cursors
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtsvg
    kdePackages.kimageformats

    jetbrains.clion
    feishu
    zerotierone
    vlc

  ];
}
