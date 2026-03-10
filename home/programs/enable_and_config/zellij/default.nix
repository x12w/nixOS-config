{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    settings = {
      theme = "catppuccin-mocha"; # 保持视觉一致性
      default_layout = "default"; # 使用紧凑布局，最大化代码空间
      pane_frames = false; # 关闭面板边框，让界面更清爽

      # 界面微调
      ui = {
        pane_frames = {
          rounded_corners = true;
        };
      };
    };
  };
}
