{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      # 插件列表
      extensions = with pkgs.vscode-extensions; [

        # --- C/C++ ---
        ms-vscode.cpptools # C++ 开发支持

        # --- Java ---
        redhat.java # Java 实验项目支持
        vscjava.vscode-java-debug

        # --- Nix ---
        jnoortheen.nix-ide # Nix 配置语法支持

        # --- Python ---
        ms-python.python
        ms-python.pylint

        # --- Rust ---
        rust-lang.rust-analyzer # 核心 LSP 支持
        tamasfe.even-better-toml # 优化 Cargo.toml 编辑体验
        serayuzgur.crates # 自动检测 Rust 依赖库版本

        # --- Haskell ---
        haskell.haskell # 核心 Haskell 插件 (提供 HLS 支持)
        justusadam.language-haskell # 增强的语法高亮

        vscodevim.vim
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

        "vim.leader" = "<space>";
        "vim.useSystemClipboard" = true;
        "vim.useCtrlKeys" = true;
        "editor.lineNumbers" = "relative";
        "vim.toggleRelativeLineNumbers" = true;

        # jj 退出插入模式
        "vim.insertModeKeyBindings" = [
          {
            before = [
              "j"
              "j"
            ];
            after = [ "<Esc>" ];
          }
        ];

        # 普通模式快捷键
        "vim.normalModeKeyBindingsNonRecursive" = [
          # <leader>e -> 打开/聚焦文件浏览器
          {
            before = [
              "<leader>"
              "e"
            ];
            commands = [ "workbench.view.explorer" ];
          }

          # <leader>f -> 在侧边栏中定位当前文件
          {
            before = [
              "<leader>"
              "f"
            ];
            commands = [ "revealInExplorer" ];
          }

          # <leader>ff -> 类似 Telescope find_files
          {
            before = [
              "<leader>"
              "f"
              "f"
            ];
            commands = [ "workbench.action.quickOpen" ];
          }

          # gd -> 跳转定义
          {
            before = [
              "g"
              "d"
            ];
            commands = [ "editor.action.revealDefinition" ];
          }

          # K -> hover
          {
            before = [ "K" ];
            commands = [ "editor.action.showHover" ];
          }

          # L -> 下一个标签页
          {
            before = [ "L" ];
            commands = [ "workbench.action.nextEditor" ];
          }

          # H -> 上一个标签页
          {
            before = [ "H" ];
            commands = [ "workbench.action.previousEditor" ];
          }

          # <leader>x -> 关闭当前标签页
          {
            before = [
              "<leader>"
              "x"
            ];
            commands = [ "workbench.action.closeActiveEditor" ];
          }

          # <leader>w -> 切换 minimap
          {
            before = [
              "<leader>"
              "w"
            ];
            commands = [ "editor.action.toggleMinimap" ];
          }

          # - -> 打开/聚焦文件浏览器
          {
            before = [ "-" ];
            commands = [ "workbench.view.explorer" ];
          }
        ];
      };
    };
  };
}
