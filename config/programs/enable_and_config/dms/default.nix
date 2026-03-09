{ inputs, pkgs, ... }:

{
  imports = [
    inputs.dms.nixosModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    enableSystemMonitoring = true;
    dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
