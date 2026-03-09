{ pkgs, ... }:

{
  programs.nixvim = {
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

    # --- 插件配置 (plugins) ---
    plugins = {
      web-devicons.enable = true;
      lualine.enable = true;
      bufferline.enable = true;
      nvim-tree.enable = true;
      telescope.enable = true;

      # 快速双击 j 退出插入模式
      better-escape = {
        enable = true;
        settings = {
          timeout = 200;
          default_mappings = false;
          mappings = {
            i = {
              j = {
                j = "<Esc>";
              };
            };
          };
        };
      };

      # 语法高亮
      treesitter = {
        enable = true;
        nixGrammars = true;
        settings.highlight.enable = true;
      };

      # 自动补全
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
            { name = "luasnip"; }
          ];
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          };
        };
      };

      # LSP 核心配置
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
          pyright.enable = true;
          clangd.enable = true;
          gopls.enable = true;
          ts_ls.enable = true;
          html.enable = true;
          cssls.enable = true;
          lua_ls.enable = true;
        };
      };

      # 自动格式化
      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lsp_fallback = true;
            timeout_ms = 500;
          };
          formatters_by_ft = {
            nix = [ "nixfmt" ];
            python = [ "black" ];
            rust = [ "rustfmt" ];
            javascript = [ "prettier" ];
            typescript = [ "prettier" ];
          };
        };
      };
    }; # plugins 结束

    # --- 常用快捷键 (keymaps 属于 programs.nixvim 的直接子项) ---
    keymaps = [
      { mode = "n"; key = "<leader>e"; action = "<cmd>NvimTreeToggle<CR>"; }
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; }
      { mode = "n"; key = "gd"; action = "lua vim.lsp.buf.definition()"; }
      { mode = "n"; key = "K"; action = "lua vim.lsp.buf.hover()"; }
    ];
  }; # programs.nixvim 结束
} # 整个大括号结束
