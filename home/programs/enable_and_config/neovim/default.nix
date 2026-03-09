{ pkgs, ... }:

{
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
    ];
  };
}
