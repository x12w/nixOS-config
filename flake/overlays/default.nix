{ inputs, ... }:

# 系统(x12w-nix)与安装镜像(installer)共用的 overlay。
# 两边必须完全一致：home/programs/enable_only 等模块里用的 baidunetdisk、codex-app
# 这类包名只由这里的 overlay 提供,少一个就是 "undefined variable"。
{
  nixpkgs.overlays = [
    inputs.nur.overlays.default
    inputs.nix-cachyos-kernel.overlays.pinned

    (final: prev: {
      kdePackages = prev.kdePackages.overrideScope (kfinal: kprev: {
        kde-gtk-config = kprev.kde-gtk-config.overrideAttrs (old: {
          # Both GTK modules leave live signal handlers when GTK unloads them.
          # Keep their code mapped for the lifetime of the process; otherwise
          # portal-gtk calls the unmapped reload_colours callback at login.
          postPatch = (old.postPatch or "") + ''
            for module in color-reload-module window-decorations-reload-module; do
              substituteInPlace "$module/CMakeLists.txt" \
                --replace-fail 'add_library(' 'add_link_options("LINKER:-z,nodelete")
            add_library('
            done
          '';
        });
      });
    })

    # baidunetdisk 8.7.0 — from standalone flake
    (final: prev: {
      baidunetdisk = inputs.baidunetdisk.packages.x86_64-linux.default;
    })

    # codex-app
    (final: prev: {
      codex-app = inputs.codex-app.packages.x86_64-linux.default;
    })

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

      /*
        qq = prev.qq.overrideAttrs (old: {
        version = "3.2.29-49738";

        src = prev.fetchurl {
        url = "https://qqdl.gtimg.cn/qqfile/QQ/9.9.31/release/00e6a3e7/QQ_3.2.29_260528_amd64_01.deb";
        hash = "sha256-HjgoB5ZzyUmvA9HgNXYUoZHY5kgZZhi1J0cLyoZjiU=";
        };

        installPhase =
        builtins.replaceStrings
        [ "rm -r $out/opt/QQ/resources/app/sharp-lib" ]
        [ "# keep bundled sharp-lib for newer QQ" ]
        old.installPhase;
        });
      */
    })
  ];
}
