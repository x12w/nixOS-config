{ pkgs, ... }:

let
  queryDrivers = [
    "${pkgs.gcc}/bin/gcc"
    "${pkgs.gcc}/bin/g++"
    "${pkgs.gcc}/bin/c++"

    "/run/current-system/sw/bin/gcc"
    "/run/current-system/sw/bin/g++"
    "/run/current-system/sw/bin/c++"

    "/nix/store/*/bin/*gcc*"
    "/nix/store/*/bin/*g++*"
    "/nix/store/*/bin/*c++*"
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
          "${pkgs.coreutils}/bin/env"
          "LC_ALL=C"
          "LANG=C"
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
              "-xc++"
              "--gcc-toolchain=${pkgs.gcc}"
              "-isystem"
              "${pkgs.gcc.cc}/include/c++/${pkgs.gcc.version}"
              "-isystem"
              "${pkgs.gcc.cc}/include/c++/${pkgs.gcc.version}/x86_64-unknown-linux-gnu"
              "-isystem"
              "${pkgs.gcc.cc}/include/c++/${pkgs.gcc.version}/backward"
              "-isystem"
              "${pkgs.glibc.dev}/include"
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
