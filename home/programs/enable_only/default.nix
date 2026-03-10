{ pkgs, ... }:

{
  # 允许 Home Manager 管理自己
  programs.home-manager.enable = true;

  programs.tmux.enable = true;

  home.packages = with pkgs; [
    eza
    fzf
    zoxide
    peazip
    (bottles.override { removeWarningPopup = true; })
    lutris
    protonplus
    hmcl
    kdePackages.plasma-browser-integration
    libreoffice-qt-fresh
    prismlauncher
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

    catppuccin-kde # 提供全局主题、色彩方案和窗口装饰
    catppuccin-papirus-folders # 提供配套图标
    bibata-cursors
    layan-gtk-theme
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtsvg
    kdePackages.kimageformats
    polonium

    jetbrains.clion
    feishu
    zerotierone
    vlc

    # --- NUR ---
    nur.repos.xddxdd.baidunetdisk
  ];
}
