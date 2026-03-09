{ pkgs, ... }:

{

  programs.nixvim = {

    imports = [
      ./plugins
      ./plugins/extra
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

    # --- 皮肤与视觉 ---
    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
    };
  }; # programs.nixvim 结束
}
