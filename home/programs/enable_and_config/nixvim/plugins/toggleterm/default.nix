{
  plugins.toggleterm = {
    enable = true;
    settings = {
      # 快捷键：Ctrl + \ 或者你自己喜欢的，比如 Meta + t
      open_mapping = "[[<C-\\>]]";
      direction = "horizontal";
      size = 15;
      float_opts = {
        border = "curved"; # 圆角边框，匹配 Catppuccin
      };
    };
  };
}
