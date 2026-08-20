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
    lutris
    protonplus
    protonup-qt
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
    foliate
    obsidian
    wechat
    qq
    rnote
    baidunetdisk
    cc-switch
    claude-code
    bilibili

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
