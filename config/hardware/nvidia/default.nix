{ lib, config, ... }:

{
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {

  modesetting.enable = true;

  powerManagement.enable = true;

  powerManagement.finegrained = false;

  open = true;

  nvidiaSettings = true;

  # package = config.boot.kernelPackages.nvidiaPackages.stable;
  package =
    config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "580.126.18";
      sha256_64bit = "sha256-p3gbLhwtZcZYCRTHbnntRU0ClF34RxHAMwcKCSqatJ0=";
      sha256_aarch64 = "sha256-pruxWQlLurymRL7PbR24NA6dNowwwX35p6j9mBIDcNs=";
      openSha256 = "sha256-1Q2wuDdZ6KiA/2L3IDN4WXF8t63V/4+JfrFeADI1Cjg=";
      settingsSha256 = "sha256-QMx4rUPEGp/8Mc+Bd8UmIet/Qr0GY8bnT/oDN8GAoEI=";
      persistencedSha256 = lib.fakeSha256;
    };

  };

  hardware.nvidia.prime = {
  nvidiaBusId = "PCI:1:0:0";
  amdgpuBusId = "PCI:0:2:0";

  sync.enable = true;
  };
}
