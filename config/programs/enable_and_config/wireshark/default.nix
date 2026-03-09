{ pkgs, ... }:

{
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;
}
