{ pkgs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = false;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev"; # 对于 EFI 模式，保持 nodev

    configurationLimit = 5;

    # --removable ---
    efiInstallAsRemovable = true;
    # ------------------------------------

    useOSProber = true; # 引导其它硬盘上的系统
  };

  boot.plymouth.enable = true;

  boot.loader.efi.canTouchEfiVariables = false;

  boot.supportedFilesystems = [ "fuse" ];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    # 同样需要关闭反向路径过滤，防止内核丢弃 TUN 流量
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };
}
