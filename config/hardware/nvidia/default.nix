{
  pkgs,
  lib,
  config,
  ...
}:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {

    modesetting.enable = true;

    powerManagement.enable = true;

    powerManagement.finegrained = false;

    open = true;

    nvidiaSettings = true;

    # 内核 >= 7.2 时 gpio_device_get_chip() 参数改为 const，
    # NVIDIA 610.57.04 驱动未适配，clang 编译报 -Werror 错误。
    # 参照 Gentoo nvidia-drivers-610.57.04 的做法，把这个
    # 警告从 error 降级为普通 warning（不影响构建结果）。
    # https://gitweb.geodns.gentoo.org/repo/sync/gentoo.git/commit/?id=2da03430470543dfaf7f233c93661eedc2dcf44c
    package = let
      nvidiaPkgs = config.boot.kernelPackages.nvidiaPackages;
    in
    nvidiaPkgs.latest
    // {
      # open 是 passthru 属性，overrideAttrs 不会重建它，需用 // 显式替换。
      # 与 cachyos-kernel flake 的 nvidia 补丁挂点一致。
      open = nvidiaPkgs.latest.open.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's/-Wno-error/& -Wno-error=incompatible-pointer-types-discards-qualifiers/' kernel-open/Kbuild
        '';
      });
    };
    /*
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "580.142";
        sha256_64bit = "sha256-IJFfzz/+icNVDPk7YKBKKFRTFQ2S4kaOGRGkNiBEdWM=";
        sha256_aarch64 = lib.fakeHash;
        openSha256 = "sha256-v968LbRqy8jB9+yHy9ceP2TDdgyqfDQ6P41NsCoM2AY=";
        settingsSha256 = "sha256-BnrIlj5AvXTfqg/qcBt2OS9bTDDZd3uhf5jqOtTMTQM=";
        persistencedSha256 = lib.fakeSha256;
      };
    */

  };

  hardware.nvidia.prime = {
    nvidiaBusId = "PCI:1:0:0";
    amdgpuBusId = "PCI:0:2:0";

    sync.enable = true;
  };
}
