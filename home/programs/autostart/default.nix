{ pkgs, ... }:

{
  xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".source =
    "${pkgs.fcitx5}/share/applications/org.fcitx.Fcitx5.desktop";
}
