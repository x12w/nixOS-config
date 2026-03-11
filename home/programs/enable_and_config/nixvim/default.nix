{ pkgs, ... }:

{

  programs.nixvim = {

    imports = [
      ./plugins
      ./keymaps
    ];

    enable = true;
    defaultEditor = true;

    # --- 全局基础设置 (vim.opt) ---
    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      termguicolors = true;
      mouse = "a";
      clipboard = "unnamedplus";
    };

    diagnostic.settings = {
      # 在行末直接显示错误信息
      virtual_text = true;
      # 在错误位置显示波浪线/高亮
      underline = true;
      # 更新频率（配合上面的 updatetime）
      update_in_insert = false;
      # 配置错误图标
      severity_sort = true;
    };

    # --- 皮肤与视觉 ---
    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
    };
  }; # programs.nixvim 结束
}
