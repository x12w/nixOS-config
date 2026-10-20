{ pkgs, ... }:
{
  # 开启 Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker.override {
    systemdLibs = pkgs.systemd;
  };
  # 开启显卡支持
  hardware.nvidia-container-toolkit.enable = true;
}
