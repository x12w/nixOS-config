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

  patchedConfig = pkgs.runCommand "patched-cachyos-bore-config" { } ''
    # 1. 拷贝原始配置
    cp ${cachyConfigRepo}/linux-cachyos-bore/config $out

    # 2. 给目标文件增加写权限，否则 sed 无法修改
    chmod +w $out

    # 3. 执行修改逻辑
    echo "Applying CachyOS specific patches to .config..."

    # 开启 BORE 调度器
    sed -i 's/# CONFIG_SCHED_BORE is not set/CONFIG_SCHED_BORE=y/' $out
    grep -q "CONFIG_SCHED_BORE=y" $out || echo "CONFIG_SCHED_BORE=y" >> $out

    # 提升至 1000Hz
    sed -i 's/CONFIG_HZ_300=y/# CONFIG_HZ_300 is not set/' $out
    sed -i 's/CONFIG_HZ=300/CONFIG_HZ=1000/' $out
    grep -q "CONFIG_HZ_1000=y" $out || echo "CONFIG_HZ_1000=y" >> $out

    # 强制全抢占
    sed -i 's/CONFIG_PREEMPT_DYNAMIC=y/CONFIG_PREEMPT_DYNAMIC=n/' $out
    grep -q "CONFIG_PREEMPT=y" $out || echo "CONFIG_PREEMPT=y" >> $out

    # 修改版本后缀
    sed -i 's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-cachyos"/' $out
  '';

  customKernel =
    (pkgs.linuxManualConfig {
      version = "7.0.0-cachyos";
      modDirVersion = "7.0.0-cachyos";
      src = cachySource;
      configfile = patchedConfig;
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
