{
  description = "x12w's nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    daeuniverse.url = "github:daeuniverse/flake.nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {

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
          # 替换为用户名
          home-manager.users.x12w = import ./home.nix;
        }
      ];
    };

  };
}
