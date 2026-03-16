{ ... }:

{
  imports = [
    ./programs/enable_only
    ./programs/enable_and_config
    ./programs/autostart

    ./theme/catppuccin
    ./theme/layan
    ./theme/cursor

    ./dotfile
    ./dotdesktop

    ./scripts/clear_conflict
  ];

  # 注意：用户名和 homeDirectory 必须正确
  home.username = "x12w";
  home.homeDirectory = "/home/x12w";

  # 设置 Home Manager 状态版本（建议保持与系统安装时一致）
  home.stateVersion = "25.11";

  # 设置输入法环境变量
  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
  };
}
