{ pkgs, lib, ... }:

let
  cachySource = pkgs.fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux";
    rev = "cachyos-7.0.0-1";
    hash = "sha256-Ybd0pKC07JqFX+U/xYNUFnpKBeEXwhJgXqa2qocEOu4=";
  };

  cachyConfigRepo = pkgs.fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    rev = "master";
    hash = "sha256-ehDv8bF7k/2Kf4b8CCoSm51U/MOoFuLsRXqe5wZ57sE=";
  };

  # 获取 BORE 补丁
  borePatch = pkgs.fetchpatch {
    url = "https://raw.githubusercontent.com/cachyos/kernel-patches/master/7.0/sched/0001-bore-cachy.patch";
    sha256 = "sha256-Yb9qGDg/r8VjQ4m/YJXnOI8phyqmB5vHwk14veV2lw0=";
  };

  # 创建修改后的 config，同时应用 BORE 补丁
  patchedConfig = pkgs.runCommand "patched-cachyos-bore-config" { } ''
    # 1. 拷贝原始配置
    cp ${cachyConfigRepo}/linux-cachyos-bore/config $out

    # 2. 给目标文件增加写权限
    chmod +w $out

    echo "Applying CachyOS BORE configuration patches to .config..."

    # ============ 关键：BORE 调度器配置 ============
    # 删除旧的 SCHED_BORE 配置
    sed -i '/CONFIG_SCHED_BORE/d' $out
    sed -i '/CONFIG_SCHED_ALT/d' $out
    sed -i '/CONFIG_SCHED_BMQ/d' $out

    # 添加 BORE 调度器
    echo "CONFIG_SCHED_BORE=y" >> $out

    # ============ 提升至 1000Hz ============
    sed -i 's/^CONFIG_HZ_300=y/# CONFIG_HZ_300 is not set/' $out
    sed -i 's/^CONFIG_HZ=300/CONFIG_HZ=1000/' $out
    grep -q "CONFIG_HZ_1000=y" $out || echo "CONFIG_HZ_1000=y" >> $out

    # ============ 强制全抢占（禁用 PREEMPT_DYNAMIC）============
    sed -i 's/^# CONFIG_PREEMPT_DYNAMIC is not set/CONFIG_PREEMPT_DYNAMIC=n/' $out
    sed -i 's/^CONFIG_PREEMPT_DYNAMIC=y/# CONFIG_PREEMPT_DYNAMIC is not set/' $out

    # 确保 PREEMPT=y
    sed -i 's/^# CONFIG_PREEMPT is not set/CONFIG_PREEMPT=y/' $out
    grep -q "^CONFIG_PREEMPT=y" $out || echo "CONFIG_PREEMPT=y" >> $out

    # 禁用 PREEMPT_LAZY
    sed -i 's/^CONFIG_PREEMPT_LAZY=y/# CONFIG_PREEMPT_LAZY is not set/' $out

    # ============ 启用 CACHY 配置 ============
    sed -i 's/^# CONFIG_CACHY is not set/CONFIG_CACHY=y/' $out
    grep -q "^CONFIG_CACHY=y" $out || echo "CONFIG_CACHY=y" >> $out

    # ============ 性能优化 ============
    # 透明大页
    sed -i 's/^# CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS is not set/CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS=y/' $out

    # 编译优化（O3）
    sed -i 's/^CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE=y/# CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE is not set/' $out
    sed -i 's/^# CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3 is not set/CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3=y/' $out

    # 修改版本后缀
    sed -i 's/^CONFIG_LOCALVERSION=""/CONFIG_LOCALVERSION="-cachyos-bore"/' $out

    echo "✓ Configuration patching completed"
  '';

  customKernel =
    (pkgs.linuxManualConfig {
      version = "7.0.0-cachyos-bore";
      modDirVersion = "7.0.0-cachyos-bore";
      src = cachySource;
      configfile = patchedConfig;
      allowImportFromDerivation = true;
    }).overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ borePatch ];
        passthru = (old.passthru or { }) // {
          features = (old.passthru.features or { }) // {
            ia32Emulation = true;
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
