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

    # package = config.boot.kernelPackages.nvidiaPackages.stable;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "580.142";
      sha256_64bit = "sha256-IJFfzz/+icNVDPk7YKBKKFRTFQ2S4kaOGRGkNiBEdWM=";
      sha256_aarch64 = lib.fakeHash;
      openSha256 = "sha256-v968LbRqy8jB9+yHy9ceP2TDdgyqfDQ6P41NsCoM2AY=";
      settingsSha256 = "sha256-BnrIlj5AvXTfqg/qcBt2OS9bTDDZd3uhf5jqOtTMTQM=";
      persistencedSha256 = lib.fakeSha256;
    };

  };

  hardware.nvidia.prime = {
    nvidiaBusId = "PCI:1:0:0";
    amdgpuBusId = "PCI:0:2:0";

    sync.enable = true;
  };
}
