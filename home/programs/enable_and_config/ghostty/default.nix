{ pkgs, inputs, ... }:

{
  programs.ghostty = {
    enable = true;
    package = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # 这里就是声明式的配置文件内容
    settings = {
      theme = "catppuccin-mocha";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      window-decoration = false;
      cursor-style = "block";
      shell-integration = "fish";
      background-opacity = 0.7;
      background-blur-radius = 20;

      # 启用 GPU 硬件加速相关的特性
      font-thicken = true; # 字体加粗效果更自然
    };
  };
}
