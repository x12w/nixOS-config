{
  programs.kitty = {
    enable = true;

    # 使用 settings 来配置 kitty.conf 中的选项
    settings = {
      # 明确指定字体，使用系统中已有的 JetBrainsMono Nerd Font
      font_family = "JetBrainsMono Nerd Font";
      font_size = "12.0";

      # 2. 核心：调整字符宽度和高度
      # 如果觉得间距太大，可以设置为负像素值（如 -1px 或 -0.5px）
      "modify_font cell_width" = "100%";  # 或者用 "-1px"
      "modify_font cell_height" = "-2px";
      "modify_font baseline" = "0";

      # 3. 渲染优化
      disable_ligatures = "never"; # 保持连字效果

      window_padding_width = "4";

      # 隐藏标题栏（在 KDE 下配合 Kvantum 效果更佳）
      hide_window_decorations = "no";

      # 设置背景透明度（配合 NVIDIA 驱动和 Plasma 合成器）
      background_opacity = "0.80";
    };
  };
}
