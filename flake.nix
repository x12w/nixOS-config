{
  description = "x12w's nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    daeuniverse.url = "github:daeuniverse/flake.nix";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix/release-25.11";
    nur.url = "github:nix-community/NUR";

    winfonts = {
      url = "git+file:///etc/nixos/config/fonts/windows_fonts";
      flake = false; # 告诉 Nix 这只是一个普通文件夹，里面没有 flake.nix
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # easyconnect-flake.url = "path:/home/x12w/projects/nix/easyconnect";
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, nur, niri, dms, dgop, ... }@inputs: {

    nixosConfigurations.x12w-nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # 关联现有的配置文件
        ./configuration.nix
        inputs.daeuniverse.nixosModules.dae
        inputs.daeuniverse.nixosModules.daed

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";

          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.x12w = {
            imports = [
              ./home.nix
              inputs.catppuccin.homeModules.catppuccin # 引入模块
            ];
          };
        }

        catppuccin.nixosModules.catppuccin

        # easyconnect-flake.nixosModules.default

        { nixpkgs.overlays = [ nur.overlays.default ]; }
      ];
    };

  };
}
