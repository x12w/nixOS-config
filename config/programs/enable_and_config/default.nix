{ pkgs, ... }:

{
  imports = [
    ./catppuccin
    # ./niri
    # ./hyprland
    ./obs
    ./clash-verge-rev
    ./steam
    ./kvm
    ./java
    ./wireshark
    ./fuse
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    # 如果插件报错找不到某些库，在这里添加
  ];
}
