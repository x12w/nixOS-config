{ pkgs, ... }:

{
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
}
