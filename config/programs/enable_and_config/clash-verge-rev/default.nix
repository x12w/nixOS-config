{ pkgs, ... }:

{
  programs.clash-verge = {
    enable = false;
    package = pkgs.clash-verge-rev;
    tunMode = false;
    serviceMode = false;
    autoStart = false;
    };
}
