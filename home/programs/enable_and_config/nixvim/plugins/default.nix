{
  # --- 插件配置 (plugins) ---
  plugins = {
    web-devicons.enable = true;
    lualine.enable = true;
    bufferline.enable = true;
    bufdelete.enable = true;
    nvim-tree.enable = false;

    toggleterm = {
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

    neo-tree = {
      enable = true;

      settings = {
        enable_git_status = true;
        enable_diagnostics = true;
        close_if_last_window = true;

        window = {
          width = 30;
          position = "left";

          mapping = {
            "v" = "openvsplit";
            "s" = "open_split";
            "t" = "open_tabnew";
          };
        };

        filesystem = {
          follow_current_file = {
            enabled = true;
          };
          filtered_items = {
            visible = true;
            hide_dotfiles = false;
          };
        };
      };
    };

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

    nvim-autopairs = {
      enable = true;
      settings = {
        check_ts = true; # 联动 Treesitter，让它在代码注释里不乱补括号
        disable_filetype = [ "TelescopePrompt" ]; # 在搜索框里禁用，避免干扰
      };
    };

    ts-autotag = {
      enable = true;
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
}
