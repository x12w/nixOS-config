{ pkgs, ... }:

{
  imports = [
    ./kernel
  ];

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

  # 1. 调整苹果驱动参数，使其符合 Windows 逻辑
  boot.extraModprobeConfig = ''
    # fnmode=2: F1-F12 默认为标准功能键（不需要按住 Fn）
    # swap_opt_cmd=0: 禁止交换 Alt 和 Win 键
    # iso_layout=0: 确保符号键位不按 ISO 布局偏移
    options hid_apple fnmode=2 swap_opt_cmd=0 iso_layout=0
  '';
}
