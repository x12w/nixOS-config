# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./config/hardware-configuration.nix

      ./config/programs/enable_only
      ./config/programs/enable_and_config

      ./config/services/enable_only
      ./config/services/enable_and_config

      ./config/fonts

      ./config/hardware/nvidia
      ./config/hardware/firmware
      ./config/hardware/network
      ./config/hardware/bluetooth

      ./config/boot

      ./config/users/x12w

      ./config/i18n
    ];



  # time zone.
  time.timeZone = "Asia/Shanghai";

  #镜像源设置
  nix.settings = {
    substituters = lib.mkForce [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];

  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # 配置固定路径映射
  environment.etc = {
    "jdk8".source = pkgs.jdk8;
    "jdk17".source = pkgs.jdk17;
    "jdk21".source = pkgs.jdk21;
  };

  # 环境变量
  environment.variables = {
    TMUX_TMPDIR = "/tmp";
  };

  system.stateVersion = "25.11";

}
