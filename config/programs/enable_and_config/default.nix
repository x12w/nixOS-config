{ pkgs, ... }:

{
  imports = [
    ./catppuccin
    ./niri
    ./dms
    ./obs
    ./clash-verge-rev
    ./steam
    ./kvm
    ./java
    ./wireshark
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    # 如果插件报错找不到某些库，在这里添加
  ];
}
