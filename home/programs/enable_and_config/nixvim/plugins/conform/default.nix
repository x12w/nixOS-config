{
  plugins.conform-nvim = {
    enable = true;
    settings = {
      format_on_save = {
        lsp_fallback = true;
        timeout_ms = 500;
      };
      formatters_by_ft = {
        nix = [ "nixfmt-rfc-style" ];
        python = [ "black" ];
        rust = [ "rustfmt" ];
        javascript = [ "prettier" ];
        typescript = [ "prettier" ];
      };
    };
  };
}
