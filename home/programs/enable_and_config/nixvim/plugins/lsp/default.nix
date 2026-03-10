{
  plugins.lsp = {
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
}
