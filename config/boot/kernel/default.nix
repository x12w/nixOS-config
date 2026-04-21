{ pkgs, lib, ... }:

let
  cachySource = pkgs.fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux"; # 注意这里是 linux，不是 linux-cachyos
    # 锁定到 7.0 的稳定补丁分支
    rev = "cachyos-7.0.0-1";
    hash = "sha256-Ybd0pKC07JqFX+U/xYNUFnpKBeEXwhJgXqa2qocEOu4=";
  };

  cachyConfigRepo = pkgs.fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    rev = "master";
    hash = "sha256-ehDv8bF7k/2Kf4b8CCoSm51U/MOoFuLsRXqe5wZ57sE="; # 记得更新这里的 Hash
  };

  customKernel =
    (pkgs.linuxManualConfig {
      version = "7.0.0-cachyos";
      modDirVersion = "7.0.0";
      src = cachySource;
      configfile = "${cachyConfigRepo}/linux-cachyos/config";
      allowImportFromDerivation = true;
    }).overrideAttrs
      (old: {
        # 强制注入 passthru 属性，让 NixOS 模块能看到这个内核支持的特性
        passthru = (old.passthru or { }) // {
          features = (old.passthru.features or { }) // {
            ia32Emulation = true; # 专门对付 graphics.enable32Bit 的检查
          };
        };
      });
in

{

  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor customKernel);

  /*
    boot.kernelPackages = pkgs.linuxPackagesFor (
      (pkgs.linuxManualConfig {
        version = "7.0.0-cachyos"; # 自定义版本显示
        modDirVersion = "7.0.0";
        src = cachySource;
        configfile = "${cachyConfigRepo}/linux-cachyos/config";
        allowImportFromDerivation = true;
      })
      // {
        features = {
          ia32Emulation = true;
          iwlwifi = true;
          efi = true;
        };
      }
    );
  */

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
