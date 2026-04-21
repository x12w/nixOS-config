{ pkgs, lib, ... }:

{
  imports = [
    # Include the results of the hardware scan.

    ./programs/enable_only
    ./programs/enable_and_config

    ./services/enable_only
    ./services/enable_and_config

    ./fonts

    ./hardware/nvidia
    ./hardware/firmware
    ./hardware/network
    ./hardware/bluetooth

    ./boot

    ./environment

    ./users/x12w

    ./i18n

    ./scripts/snap_check

    ./nix
  ];

  # time zone.
  time.timeZone = "Asia/Shanghai";

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
