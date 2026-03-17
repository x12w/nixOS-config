{ pkgs, ... }:
let
  # 定义一个包含插件的 fcitx5 变量
  fcitx5Package = pkgs.qt6Packages.fcitx5-with-addons;
in
{
  xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Name=Fcitx 5
    Exec=${fcitx5Package}/bin/fcitx5-wayland-launcher --reopen
    Icon=org.fcitx.Fcitx5
    Type=Application
    Categories=Settings;
    X-GNOME-Autostart-Phase=Applications
    X-KDE-autostart-after=panel
  '';
}
