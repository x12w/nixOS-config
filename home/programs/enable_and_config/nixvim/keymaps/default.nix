{
  globals.mapleader = " ";

  # --- 常用快捷键 (keymaps 属于 programs.nixvim 的直接子项) ---
  keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<CR>";
    }
    {
      mode = "n";
      key = "<leader>f";
      action = "<cmd>Neotree reveal<CR>";
    }
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<CR>";
    }
    {
      mode = "n";
      key = "gd";
      action = "lua vim.lsp.buf.definition()";
    }
    {
      mode = "n";
      key = "K";
      action = "lua vim.lsp.buf.hover()";
    }

    {
      mode = "n";
      key = "L"; # 注意是大写 L
      action = "<cmd>bnext<CR>";
      options.desc = "下一个标签页";
    }
    # 使用 Shift + h 切换到上一个标签 (Buffer)
    {
      mode = "n";
      key = "H"; # 注意是大写 H
      action = "<cmd>bprevious<CR>";
      options.desc = "上一个标签页";
    }
    # 关闭当前标签页 (Buffer)
    {
      mode = "n";
      key = "<leader>x";
      action = "<cmd>Bdelete<CR>";
      options.desc = "关闭当前标签页";
    }
    {
      mode = "t";
      key = "<Esc>";
      action = "<C-\\><C-n>";
    }
  ];
}
