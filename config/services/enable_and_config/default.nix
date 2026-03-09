{
  #代理
  services.daed = {
    enable = true;

    openFirewall = {
      enable = true;
      port = 12345;
    };
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly"; # 每周执行一次
    fileSystems = [ "/" ]; # Btrfs 挂载点
  };

  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "daily";

    configs = {
      root = {
        SUBVOLUME = "/";
        ALLOW_USERS = [ "x12w" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        # 迁移后的新写法：直接写成属性
        TIMELINE_LIMIT_HOURLY = 10;
        TIMELINE_LIMIT_DAILY = 5;
        TIMELINE_LIMIT_WEEKLY = 0;
        TIMELINE_LIMIT_MONTHLY = 0;
        TIMELINE_LIMIT_YEARLY = 0;
      };

      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = [ "x12w" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        # 迁移后的新写法
        TIMELINE_LIMIT_HOURLY = 5;
        TIMELINE_LIMIT_DAILY = 3;
        TIMELINE_LIMIT_WEEKLY = 0;
        TIMELINE_LIMIT_MONTHLY = 0;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    };
  };

  #启用flatpak
  services.flatpak.enable = true;
  # 让桌面环境（如 KDE/GNOME）能搜到 Flatpak 安装的软件图标
  xdg.portal.enable = true;

  # 开启 Docker
  virtualisation.docker.enable = true;
  # 开启显卡支持
  hardware.nvidia-container-toolkit.enable = true;

  # zerotier
  services.zerotierone.enable = true;
  networking.firewall.allowedUDPPorts = [ 9993 ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true; # 启用密码登录
      PermitRootLogin = "no";        # 禁止 root 直接登录
    };
  };



  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
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
}
