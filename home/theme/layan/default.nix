{ pkgs, lib, ... }:

let
  # 定义自定义的 Layan KDE 派生
  layan-kde-theme = pkgs.stdenv.mkDerivation {
    pname = "layan-kde-theme";
    version = "master";

    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "Layan-kde";
      rev = "master";
      # 注意：如果构建时报错 hash 不对，请将其替换为报错信息中的那个
      sha256 = "sha256-gy3sHVoCo4q7ihFuLvQEil7t4GdrbcfatOulAy2MZ9U=";
    };

    # 安装阶段：将源码中的目录映射到 Nix 标准路径
    installPhase = ''
      # 1. 创建目标目录
      mkdir -p $out/share/plasma/look-and-feel
      mkdir -p $out/share/plasma/desktoptheme
      mkdir -p $out/share/aurorae/themes
      mkdir -p $out/share/color-schemes
      mkdir -p $out/share/Kvantum
      mkdir -p $out/share/wallpapers

      # 2. 拷贝对应的组件
      cp -r plasma/look-and-feel/* $out/share/plasma/look-and-feel/
      cp -r plasma/desktoptheme/* $out/share/plasma/desktoptheme/
      cp -r aurorae/* $out/share/aurorae/themes/
      cp -r color-schemes/* $out/share/color-schemes/
      cp -r Kvantum/* $out/share/Kvantum/
      cp -r wallpaper/* $out/share/wallpapers/
    '';
  };
in

{
  home.packages = [
    layan-kde-theme
  ];

  qt = {
    enable = true;
    platformTheme.name = lib.mkForce "kvantum";
    style.name = lib.mkForce "kvantum";
  };

  gtk = {
    enable = true;
    theme = {
      name = lib.mkForce "Layan-Dark";
      package = lib.mkForce pkgs.layan-gtk-theme;
    };

    iconTheme = {
      name = lib.mkForce "Tela-dark";
      package = lib.mkForce pkgs.tela-icon-theme;
    };
  };
}
