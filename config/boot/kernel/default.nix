{
  pkgs,
  ...
}:

let
  cachyos-kernel = pkgs.cachyosKernels.linux-cachyos-bore-lto;
in

{
  boot.kernelPackages = pkgs.linuxPackagesFor cachyos-kernel;

  # 开启 Btrfs 的一些高级特性
  boot.supportedFilesystems = [ "btrfs" ];

  # Use latest kernel.
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "usbcore.autosuspend=-1"
  ];

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
