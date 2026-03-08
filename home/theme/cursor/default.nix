{ pkgs, ... }:

{
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice"; # 可选: Bibata-Modern-Amber, Bibata-Modern-Classic 等
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
