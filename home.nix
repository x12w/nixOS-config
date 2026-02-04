{ config, pkgs, ... }:

{
  # 注意：用户名和 homeDirectory 必须正确
  home.username = "x12w";
  home.homeDirectory = "/home/x12w";

  # 允许 Home Manager 管理自己
  programs.home-manager.enable = true;

  # Starship 配置
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # 每次命令之间不留空行
      add_newline = false;

      # 提示符形状
      character = {
      success_symbol = "[➜](bold green)";
      error_symbol = "[➜](bold red)";
      };

      # 目录样式
      directory = {
        truncation_length = 3;
        truncate_to_repo = true; # 在 git 仓库中缩短路径
        style = "bold italic blue";
      };

      # Git 状态 (这是 Starship 最强的地方)
      git_branch = {
        symbol = "󰊢 ";
        style = "bold yellow";
      };

      git_status = {
        format = "([$all_status$conflicted$ahead_behind]($style) )";
        style = "red";
      };

      # 编程语言图标 (需要 Nerd Fonts)
      python.symbol = " ";
      rust.symbol = " ";
      nix_shell.symbol = " ";
    };
  };

  # 开启 Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;      # 开启自动建议
    syntaxHighlighting.enable = true; # 开启语法高亮
  };

  # 设置 Home Manager 状态版本（建议保持与系统安装时一致）
  home.stateVersion = "25.11";

  # 设置输入法环境变量
  home.sessionVariables = {
  GTK_IM_MODULE = ""; # 对应 configuration.nix 中的 lib.mkForce ""
  QT_IM_MODULE = "";
  };

  # 配置git
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "x12w";
        email = "w17802627260@gmail.com";
      };

      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true; # 自动关联已有的 Zsh 配置
  };

  programs.vscode = {
    enable = true;


    profiles.default = {
      # 插件列表
      extensions = with pkgs.vscode-extensions; [

        # --- C/C++ ---
        ms-vscode.cpptools          # C++ 开发支持

        # --- Java ---
        redhat.java                 # Java 实验项目支持
        vscjava.vscode-java-debug

        # --- Nix ---
        jnoortheen.nix-ide          # Nix 配置语法支持

        # --- Python ---
        ms-python.python
        ms-python.pylint

        # --- Rust ---
        rust-lang.rust-analyzer  # 核心 LSP 支持
        tamasfe.even-better-toml # 优化 Cargo.toml 编辑体验
        serayuzgur.crates        # 自动检测 Rust 依赖库版本

        # --- Haskell ---
        haskell.haskell          # 核心 Haskell 插件 (提供 HLS 支持)
        justusadam.language-haskell # 增强的语法高亮
      ];

      # 用户设置 (settings.json)
      userSettings = {
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "catppuccin-mocha";
        "editor.fontSize" = 14;
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace'";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "editor.formatOnSave" = true;
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true; # 将 nvim 设为默认编辑器
    viAlias = true;
    vimAlias = true;

    # 安装 LazyVim 运行所需的额外系统依赖
    extraPackages = with pkgs; [
      # 基础工具
      ripgrep
      fd
      git
      lua-language-server

      # 语言服务器 (LSP)

      # --- C/C++ ---
      clang-tools          # C++ (clangd)

      # --- Java ---
      jdk
      jdt-language-server

      # --- Nix ---
      nil

      # --- Rust ---
      rustc
      cargo
      rust-analyzer
      clippy
      rustfmt

      # --- Haskell ---
      ghc
      haskell-language-server
      cabal-install
      stack
      haskellPackages.fourmolu



      # --- Python ---
      pyright

      # 其他通用工具
      nodePackages.typescript-language-server

      jetbrains.clion
      feishu
    ];
  };

  home.packages = with pkgs; [
    eza
    fzf
    zoxide
    peazip

    catppuccin-kde          # 提供全局主题、色彩方案和窗口装饰
    catppuccin-papirus-folders # 提供配套图标
    bibata-cursors

    # --- NUR ---
    nur.repos.xddxdd.baidunetdisk
  ];

  catppuccin = {
    flavor = "mocha"; # 选择你喜欢的：latte, frappe, macchiato, mocha
    accent = "sapphire";
    enable = true;    # 这会尝试为所有支持的 program.* 开启主题

    cursors.enable = false; # 光标主题
    fcitx5.enable = true;
    kvantum.enable = true;
    kvantum.apply = true;
  };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice"; # 可选: Bibata-Modern-Amber, Bibata-Modern-Classic 等
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };



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

      # 设置背景透明度（配合你的 NVIDIA 驱动和 Plasma 合成器 [cite: 53]）
      background_opacity = "0.95";
    };
  };
}
