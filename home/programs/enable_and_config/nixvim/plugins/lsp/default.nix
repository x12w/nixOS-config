{ pkgs, ... }:

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
      clangd = {
        enable = true;
        package = pkgs.clang-tools;

        # NOTE: Do NOT pass --query-driver here. The clangd wrapper script
        # deliberately skips setting CPATH/CPLUS_INCLUDE_PATH when
        # --query-driver is present, which breaks header discovery for
        # C++ standard library headers (like <concepts>).
        # Removing --query-driver lets the wrapper inject the correct
        # include paths from the Nix clang/gcc environment.
        cmd = [
          "${pkgs.clang-tools}/bin/clangd"
          "--background-index"
          "--clang-tidy"
          "--completion-style=detailed"
          "--header-insertion=iwyu"
        ];

        extraOptions = {
          init_options = {
            # Fallback flags used when no compile_commands.json is found.
            # The wrapper already sets CPLUS_INCLUDE_PATH for system headers;
            # these ensure the right C++ standard is used.
            fallbackFlags = [
              "-std=c++23"
            ];
          };
        };
      };
      gopls.enable = true;
      ts_ls.enable = true;
      html.enable = true;
      cssls.enable = true;
      lua_ls.enable = true;
    };
  };
}
