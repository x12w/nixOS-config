{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    google-chrome
    wpsoffice-cn
    qq
    wechat-uos
    vscode
    fastfetch
    blueman
    nvtopPackages.nvidia
    wineWowPackages.stagingFull
    winetricks
    zip
    docker-compose
    distrobox
    direnv
    nil
    btrfs-progs # 核心工具 (通常已内置)
    btdu        # Btrfs 磁盘空间分析器 (非常牛，能看到压缩后的真实占用)
    btrfs-assistant # 图形化管理界面 (如果你想要 GUI 控制 Snapper)
    snapper
    fish

    # --- kvm ---
    spice-gtk         # 增强剪贴板共享和屏幕缩放
    virt-viewer       # 远程查看器
    bridge-utils      # 桥接网络工具

    # --- Rust ---
    rustc
    cargo

    # --- Haskell ---
    ghc
    stack

    # --- C/C++ ---
    gcc
    gdb
    cmake
    gnumake

    # --- Java ---
    jdk
    maven
    jdk8
    jdk17
    jdk21

    # --- Python ---
    python3
    python3Packages.pip
    python3Packages.black
  ];

  # 启用 virt-manager 图形界面
  programs.virt-manager.enable = true;

  programs.zsh.enable = true;

  programs.fish.enable = true;

  # programs.easyconnect.enable = true;
}
