{ pkgs, ... }: 

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # --- 全局基础设置 ---
    opts = {
      number = true;           # 显示行号
      relativenumber = true;   # 相对行号
      shiftwidth = 2;          # 缩进宽度
      tabstop = 2;
      expandtab = true;        # 使用空格代替制表符
      smartindent = true;
      termguicolors = true;    # 开启真彩色
      mouse = "a";             # 开启鼠标支持
      clipboard = "unnamedplus"; # 使用系统剪贴板
    };

    # --- 皮肤与视觉 ---
    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
    };

    plugins = {
      # 状态栏与标签页
      lualine.enable = true;
      bufferline.enable = true;
      # 文件树与模糊搜索
      nvim-tree.enable = true;
      telescope.enable = true;
      # 语法高亮 (Treesitter 会自动安装对应的语法解析器)
      treesitter = {
        enable = true;
        nixGrammars = true;
        settings.highlight.enable = true;
      };

      # --- 自动补全 (Autocomplete) ---
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

      # --- LSP 核心配置  ---
      lsp = {
        enable = true;
        servers = {
          # 1. Nix 
          nil_ls.enable = true;
          # 2. Rust
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
          # 3. Python
          pyright.enable = true;
          # 4. C / C++
          clangd.enable = true;
          # 5. Go
          gopls.enable = true;
          # 6. Web (TS, JS, HTML, CSS)
          ts_ls.enable = true; # 旧称 tsserver
          html.enable = true;
          cssls.enable = true;
          # 7. Lua 
          lua_ls.enable = true;
        };
      };

      # --- 自动格式化 (Format on Save) ---
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

    plugins.better-escape = {
      enable = true;
      settings = {
        timeout = 200; # 这里的超时独立于全局 timeoutlen
        default_mappings = false; # 禁用默认的 jk 映射，我们要自定义
        mappings = {
          i = {
            j = {
              j = "<Esc>"; # 只有双击 j 才会退出
            };
          };
        };
      };
    };
    };

    # --- 常用快捷键 ---
    keymaps = [
      { mode = "n"; key = "<leader>e"; action = "<cmd>NvimTreeToggle<CR>"; }
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; }
      { mode = "n"; key = "gd"; action = "lua vim.lsp.buf.definition()"; } # 跳转定义
      { mode = "n"; key = "K"; action = "lua vim.lsp.buf.hover()"; }      # 查看文档说明
    ];
  };
};
