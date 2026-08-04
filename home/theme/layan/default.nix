{
  pkgs,
  lib,
  config,
  ...
}:

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

  # nixos-unstable 移除了 layan-gtk-theme (依赖已废弃的 gtk-engine-murrine)。
  # 从 Vinceliuice 源码构建，GTK3/GTK4 主题不受影响，GTK2 部分因缺少
  # murrine 引擎不会生效（GTK2 应用极少，不影响日常使用）。
  layan-gtk-theme = pkgs.stdenv.mkDerivation {
    pname = "layan-gtk-theme";
    version = "master";

    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "Layan-gtk-theme";
      rev = "master";
      sha256 = "sha256-8YxCmXA0p/HNUK19KO3IAzDF2Rr24b0BDlbLOc70EFU="; # 首次构建时替换
    };

    installPhase = ''
      mkdir -p $out/share/themes
      bash install.sh -d $out/share/themes -n Layan-Dark -c dark -s standard
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
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    theme = {
      name = lib.mkForce "Layan-Dark";
      package = lib.mkForce layan-gtk-theme;
    };

    iconTheme = {
      name = lib.mkForce "Tela-dark";
      package = lib.mkForce pkgs.tela-icon-theme;
    };
  };
}
