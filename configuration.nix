# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  # 手动定义最新版 daed 软件包
  daed-latest = pkgs.stdenv.mkDerivation rec {
    pname = "daed";
    version = "1.22.0"; # 在此指定你想要的精确版本

    # 直接从 GitHub Releases 下载预编译的二进制压缩包
    src = pkgs.fetchurl {
      url = "https://github.com/daeuniverse/daed/releases/download/v${version}/daed-linux-x86_64.zip";
      # 先填这个占位符，执行构建时 Nix 会报错并给出正确的 hash
      hash = "sha256-PmoNZ5QNSK8YqKPd3oFon3+BjfEc+47J+TAWFre0RBY=";
    };

    nativeBuildInputs = [
      pkgs.unzip
      pkgs.autoPatchelfHook
    ];

    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    dontBuild = true;
    dontConfigure = true;

    # 核心修正：直接拷贝那个带有平台后缀的二进制文件并重命名
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin

      # 根据 ls 日志，文件名就是这个：
      if [ -f "daed-linux-x86_64" ]; then
        cp daed-linux-x86_64 $out/bin/daed
      else
        echo "仍在尝试搜索二进制文件..."
        find . -type f -executable -exec cp {} $out/bin/daed \;
      fi

      chmod +x $out/bin/daed
      runHook postInstall
    '';

    meta = {
      mainProgram = "daed";
      description = "A modern web dashboard for dae";
      homepage = "https://github.com/daeuniverse/daed";
    };
  };
  in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = false;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev"; # 对于 EFI 模式，保持 nodev

    # --removable ---
    efiInstallAsRemovable = true;
    # ------------------------------------

    useOSProber = true; # 引导其它硬盘上的系统
  };

  boot.plymouth.enable = true;

  boot.loader.efi.canTouchEfiVariables = false;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "x12w-nix"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  #networking.proxy.default = "http://127.0.0.1:7897";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.

  #镜像源设置
  nix.settings = {
    substituters = lib.mkForce [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];

  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      wqy_zenhei
      jetbrains-mono
      sarasa-gothic
      nerd-fonts.jetbrains-mono
      wqy_zenhei
    ];

    fontconfig.defaultFonts = {
      serif = [ "Noto Serif CJK SC" ];
      sansSerif = [ "Noto Sans CJK SC" ];
      monospace = [ "Noto Sans Mono CJK SC" ];
    };

    fontDir.enable = true;
  };


  users.users.x12w = {
    isNormalUser = true;
    description = "x12w";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];

    shell = pkgs.zsh;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {

  modesetting.enable = true;

  powerManagement.enable = true;

  open = true;

  nvidiaSettings = true;

  package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia.prime = {
  nvidiaBusId = "PCI:1:0:0";
  amdgpuBusId = "PCI:0:2:0";

  sync.enable = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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

    # --- Python ---
    python3
    python3Packages.pip
    python3Packages.black
  ];

  catppuccin = {
    flavor = "mocha"; # 选择你喜欢的：latte, frappe, macchiato, mocha
    accent = "sapphire";
    enable = true;    # 这会尝试为所有支持的 program.* 开启主题
    grub.enable = true;
    plymouth.enable = true;
  };

  #系统服务

  #开启蓝牙硬件支持
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.blueman.enable = true;

  #代理
  services.daed = {
    enable = true;
    # 强制使用我们上面定义的最新版包
    package = daed-latest;

    openFirewall = {
      enable = true;
      port = 12345;
    };
  };



  #启用flatpak
  services.flatpak.enable = true;
  # 让桌面环境（如 KDE/GNOME）能搜到 Flatpak 安装的软件图标
  xdg.portal.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    # 如果插件报错找不到某些库，在这里添加
  ];

/*
  programs.clash-verge = {
    enable = true;
    package = pkgs.clash-verge-rev;
    tunMode = false;
    serviceMode = false;
    autoStart = false;
  };
*/

  programs.zsh = {
  enable = true;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
};


    i18n.inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5.addons = with pkgs; [
        fcitx5-rime          # Rime 鼠须管
        qt6Packages.fcitx5-chinese-addons # 包含拼音、五笔等基础插件
        fcitx5-gtk           # GTK 程序的兼容层
        fcitx5-lua           # 扩展支持
      ];
    };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = true; # 启用密码登录
    PermitRootLogin = "no";        # 禁止 root 直接登录
  };
};

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
