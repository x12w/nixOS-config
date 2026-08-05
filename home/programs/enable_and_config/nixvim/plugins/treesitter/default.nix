{
  # 语法高亮
  plugins.treesitter = {
    enable = true;

    highlight.enable = true;
    indent.enable = true;

    # 确保以下语言的语法解析器已安装
    # 其他语言在打开对应文件时自动按需安装
    settings.ensure_installed = [
      "go"
      "zig"
      "nix"
      "python"
      "rust"
      "c"
      "cpp"
      "lua"
      "javascript"
      "typescript"
      "html"
      "css"
      "bash"
    ];
  };
}
