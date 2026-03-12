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

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # easyconnect-flake.url = "path:/home/x12w/projects/nix/easyconnect";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      catppuccin,
      nur,
      niri,
      dms,
      dgop,
      nixvim,
      ...
    }@inputs:
    {

      nixosConfigurations.x12w-nix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # 关联现有的配置文件
          ./flake/x12w-nix
        ];
      };

      packages.x86_64-linux.installer =
        (nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./flake/installer
          ];
        }).config.system.build.isoImage;

    };
}
