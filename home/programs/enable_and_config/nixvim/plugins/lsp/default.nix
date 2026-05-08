{ pkgs, ... }:

let
  queryDrivers = [
    "/nix/store/*/bin/*gcc*"
    "/nix/store/*/bin/*g++*"
    "/run/current-system/sw/bin/gcc"
    "/run/current-system/sw/bin/g++"
  ];
in
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
        cmd = [
          "${pkgs.clang-tools}/bin/clangd"
          "--background-index"
          "--clang-tidy"
          "--completion-style=detailed"
          "--header-insertion=iwyu"
          "--query-driver=${builtins.concatStringsSep "," queryDrivers}"
        ];
        extraOptions = {
          init_options = {
            fallbackFlags = [
              "-std=c++20"
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
