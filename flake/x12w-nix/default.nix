{ inputs, ... }:

{
  imports = [
    ../../config/configuration.nix
    ../../config/hardware-configuration.nix

    inputs.daeuniverse.nixosModules.dae
    inputs.daeuniverse.nixosModules.daed

    inputs.home-manager.nixosModules.home-manager

    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";

      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users.x12w = {
        imports = [
          ../../home/home.nix
          inputs.catppuccin.homeModules.catppuccin # 引入模块
          inputs.nixvim.homeModules.nixvim
          inputs.plasma-manager.homeModules.plasma-manager
        ];
      };
    }

    inputs.catppuccin.nixosModules.catppuccin

    # easyconnect-flake.nixosModules.default

    { nixpkgs.overlays = [ inputs.nur.overlays.default ]; }

  ];
}
