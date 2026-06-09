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

    {
      nixpkgs.overlays = [
        inputs.nur.overlays.default
        inputs.nix-cachyos-kernel.overlays.pinned

        (final: prev: {
          polonium = prev.stdenvNoCC.mkDerivation {
            pname = "polonium";
            version = "1.1-a1";

            src = prev.fetchurl {
              url = "https://github.com/zeroxoneafour/polonium/releases/download/v1.1-a1/polonium.kwinscript";
              hash = "sha256-kzL9kIbZgtLpLHYsxC5fWDNumn6yDm4vMDoFKlSCbHk=";
            };

            nativeBuildInputs = [
              prev.unzip
            ];

            dontUnpack = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/kwin/scripts/polonium
              unzip "$src" -d $out/share/kwin/scripts/polonium

              runHook postInstall
            '';
          };
        })
      ];
    }

  ];
}
