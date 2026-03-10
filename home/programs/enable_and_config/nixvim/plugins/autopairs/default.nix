{
  plugins.nvim-autopairs = {
    enable = true;
    settings = {
      check_ts = true; # 联动 Treesitter，让它在代码注释里不乱补括号
      disable_filetype = [ "TelescopePrompt" ]; # 在搜索框里禁用，避免干扰
    };
  };
}
