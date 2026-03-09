{pkgs, ...}:

{
  imports = [
    ./catppuccin
    ./niri
    ./dms
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    # 如果插件报错找不到某些库，在这里添加
  ];

/*
  programs.clash-verge = {
    enable = true;
    package = pkgs.clash-verge-rev;
    tunMode = false;
    serviceMode = false;
    autoStart = false;
  };
*/

  programs.java = {
    enable = true;
    package = pkgs.jdk17; # 设置系统默认版本
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };

  programs.steam = {
    enable = true;
    # 为 Steam 远程开启防火墙端口
    remotePlay.openFirewall = true;
    # 为专用服务器开启防火墙端口
    dedicatedServer.openFirewall = true;
  };

  # Steam 需要 32 位图形驱动才能运行
  hardware.graphics.enable32Bit = true;

  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;

  # kvm
  virtualisation.libvirtd = {
    enable = true;
    # 启用 UEFI 支持 (用于运行 Windows 11 或现代 Linux)
    qemu = {
      package = pkgs.qemu_kvm;
      # NVIDIA 显卡硬件加速
      swtpm.enable = true; # 模拟 TPM，Windows 11 必需
    };
  };
}
