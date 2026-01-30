{ config, pkgs, ... }:

{
  # 注意：用户名和 homeDirectory 必须正确
  home.username = "x12w";
  home.homeDirectory = "/home/x12w";

  # 允许 Home Manager 管理自己
  programs.home-manager.enable = true;

  # Starship 配置
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # 开启 Zsh
  programs.zsh.enable = true;

  # 设置 Home Manager 状态版本（建议保持与系统安装时一致）
  home.stateVersion = "25.11";

  # 设置输入法环境变量
  home.sessionVariables = {
  GTK_IM_MODULE = ""; # 对应你 configuration.nix 中的 lib.mkForce ""
  QT_IM_MODULE = "";
  };

  # 配置git
  programs.git = {
  enable = true;
  userName = "x12w";
  userEmail = "w17802627260@gmail.com";
  extraConfig = {
    init.defaultBranch = "main";
  };
};
}
