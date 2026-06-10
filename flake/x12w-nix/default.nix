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

              tmpdir="$(mktemp -d)"
              unzip -q "$src" -d "$tmpdir"

              mkdir -p "$out/share/kwin/scripts/polonium"

              # Polonium 的 kwinscript 解压后是 pkg/metadata.json + pkg/contents/...
              cp -r "$tmpdir/pkg/"* "$out/share/kwin/scripts/polonium/"

              runHook postInstall
            '';
          };
        })

        (final: prev: {
          karousel = prev.stdenvNoCC.mkDerivation {
            pname = "karousel";
            version = "0.17";

            src = prev.fetchurl {
              url = "https://github.com/peterfajdiga/karousel/releases/download/v0.17/karousel_0_17.tar.gz";
              hash = "sha256-SS4pYtwOUQ5HeaDu38KqMRwu4+S2YhZI6uYO2+ML0cM=";
            };

            nativeBuildInputs = [
              prev.gnutar
              prev.gzip
              prev.findutils
              prev.coreutils
            ];

            dontUnpack = true;

            installPhase = ''
              runHook preInstall

              tmpdir="$(mktemp -d)"
              tar -xzf "$src" -C "$tmpdir"

              metadata="$(find "$tmpdir" -name metadata.json -type f | head -n 1)"

              if [ -z "$metadata" ]; then
                echo "error: metadata.json not found in Karousel archive"
                find "$tmpdir" -maxdepth 4 -type f | sort
                exit 1
              fi

              root="$(dirname "$metadata")"

              mkdir -p "$out/share/kwin/scripts/karousel"
              cp -r "$root"/* "$out/share/kwin/scripts/karousel/"

              runHook postInstall
            '';
          };

          kwin4-effect-geometry-change = prev.stdenvNoCC.mkDerivation {
            pname = "kwin4-effect-geometry-change";
            version = "1.5";

            src = prev.fetchurl {
              url = "https://github.com/peterfajdiga/kwin4_effect_geometry_change/releases/download/v1.5/kwin4_effect_geometry_change_1_5.tar.gz";
              hash = "sha256-dmUaJEZfg8gy65bcnTSzrBLHXRtxKYwqxGGopLLMCFA=";
            };

            nativeBuildInputs = [
              prev.gnutar
              prev.gzip
              prev.findutils
              prev.coreutils
            ];

            dontUnpack = true;

            installPhase = ''
              runHook preInstall

              tmpdir="$(mktemp -d)"
              tar -xzf "$src" -C "$tmpdir"

              metadata="$(find "$tmpdir" -name metadata.json -type f | head -n 1)"
              if [ -z "$metadata" ]; then
                echo "error: metadata.json not found in geometry-change effect archive"
                find "$tmpdir" -maxdepth 4 -type f | sort
                exit 1
              fi

              root="$(dirname "$metadata")"

              mkdir -p "$out/share/kwin/effects/kwin4_effect_geometry_change"
              cp -r "$root"/* "$out/share/kwin/effects/kwin4_effect_geometry_change/"

              runHook postInstall
            '';
          };
        })
      ];
    }

  ];
}
