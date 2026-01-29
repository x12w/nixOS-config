{
  description = "x12w's nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    daed.url = "github:daeuniverse/flake.nix";
  };

  outputs = { self, nixpkgs, daeuniverse, ... }@inputs: {

    nixosConfigurations.x12w-nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # 关联现有的配置文件
        ./configuration.nix
        daeuniverse.nixosModules.daed
        daeuniverse.nixosModules.dae
      ];
    };

  };
}
