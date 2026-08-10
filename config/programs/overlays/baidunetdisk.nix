{
  stdenv,
  lib,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  # Electron/chrome runtime dependencies
  libappindicator,
  libdbusmenu,
  libgbm,
  libglvnd,
  libdrm,
  mesa,
  alsa-lib,
  atk,
  at-spi2-core,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  dbus-glib,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  # GTK3
  gtk3,
  # GTK2 — libbrowserengine.so links against gtkmm-2.4
  gtk2,
  gtkmm2,
  glibmm,
  cairomm,
  pangomm,
  atkmm,
  libsigcxx,
  libnotify,
  libpulseaudio,
  libxkbcommon,
  nspr,
  nss,
  pango,
  systemd,
  xorg,
  xz,
}:

let
  pname = "baidunetdisk";
  version = "8.6.0";

  src = fetchurl {
    url = "http://wppkg.baidupcs.com/issue/netdisk/Linuxguanjia/${version}/baidunetdisk_${version}_amd64.deb";
    sha256 = "sha256-KPYogv41RptACMEyTkPSqRCTlby9/AUgfgSKhId1nVY=";
  };

  # All libraries the electron runtime needs at runtime.
  # Used for both buildInputs (autoPatchelfHook discovery) and
  # the wrapper's LD_LIBRARY_PATH fallback.
  runtimeLibs = [
    stdenv.cc.cc.lib
    alsa-lib
    atk
    at-spi2-core
    at-spi2-atk
    cairo
    cups
    dbus
    dbus-glib
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk2
    gtk3
    libappindicator
    libdbusmenu
    libdrm
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxshmfence
    # libXt needed by uiohook-napi .node addon
    xorg.libXt
    xz
    # gtkmm-2.4 stack for libbrowserengine.so
    gtkmm2
    glibmm
    cairomm
    pangomm
    atkmm
    libsigcxx
  ];

in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = runtimeLibs;

  # Don't strip — chrome shared objects break when stripped
  dontStrip = true;

  unpackPhase = ''
    dpkg -x $src .
  '';

  installPhase = ''
    mkdir -p $out/lib/baidunetdisk $out/bin

    # Copy everything from the deb
    cp -r opt/baidunetdisk/* $out/lib/baidunetdisk/

    pushd $out/lib/baidunetdisk

    # --- Clean up platform-specific node_modules ---
    # These contain prebuilt .node addons for Windows/macOS that reference
    # libraries we can't satisfy (e.g. libpython3.6m).  We delete them
    # before autoPatchelfHook scans so it doesn't fail on those.
    find resources/app.asar.unpacked -path "*/build/node_gyp_bins/*" -delete 2>/dev/null || true
    find resources/app.asar.unpacked -path "*/windows-notification-state/*" -delete 2>/dev/null || true
    find resources/app.asar.unpacked -path "*/macos-notification-state/*" -delete 2>/dev/null || true
    find resources/app.asar.unpacked -path "*/windows-quiet-hours/*" -delete 2>/dev/null || true

    # --- Remove bundled Chrome/Electron libraries we source from nixpkgs ---
    # Keep libffmpeg.so — it's tightly coupled to the electron version.
    # Keep libEGL.so / libGLESv2.so — the bundled electron dlopen()s them
    # from its own directory.
    rm -f \
      chrome-sandbox \
      chrome_crashpad_handler \
      libvk_swiftshader.so \
      libvulkan.so \
      libvulkan.so.1

    # Remove unused chrome resource files that inflate closure.
    # Keep icudtl.dat, snapshot_blob.bin, v8_context_snapshot.bin —
    # these are required by the bundled chromium runtime.
    # Keep resources.pak — needed for chrome:// pages.
    # The .pak files are needed for locale/UI resources.
    rm -f \
      vk_swiftshader_icd.json

    # Remove unnecessary files
    rm -rf \
      LICENSE.* \
      locales \
      resources/8bb88996964c4e3202fecaaa5605af03 \
      resources/default.db \
      resources/dir.icns \
      resources/resource.db
    popd

    # Create wrapper script.
    # LD_LIBRARY_PATH is needed because Electron dlopen()s libraries like
    # libEGL at runtime — these aren't captured by RUNPATH alone.
    makeWrapper $out/lib/baidunetdisk/baidunetdisk $out/bin/baidunetdisk \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --add-flags "--no-sandbox" \
      --add-flags "$out/lib/baidunetdisk/resources/app.asar"

    # Install icons
    install -Dm644 $out/lib/baidunetdisk/baidunetdisk.svg \
      $out/share/icons/hicolor/scalable/apps/baidunetdisk.svg

    # Install desktop file manually (copyDesktopItems hook is unreliable
    # when installPhase is overridden)
    mkdir -p $out/share/applications
    cat > $out/share/applications/baidunetdisk.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Name=Baidu Netdisk
Name[zh_CN]=百度网盘
Name[zh_TW]=百度網盤
Comment=Baidu Netdisk
Comment[zh_CN]=百度网盘
Comment[zh_TW]=百度網盤
Exec=baidunetdisk %U
Terminal=false
Type=Application
Icon=baidunetdisk
StartupWMClass=baidunetdisk
MimeType=x-scheme-handler/baiduyunguanjia;
Categories=Network;
DESKTOP_EOF
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "baidunetdisk";
      desktopName = "Baidu Netdisk";
      exec = "baidunetdisk %U";
      terminal = false;
      icon = "baidunetdisk";
      startupWMClass = "baidunetdisk";
      comment = "Baidu Netdisk";
      mimeTypes = [ "x-scheme-handler/baiduyunguanjia" ];
      categories = [ "Network" ];
      extraConfig = {
        "Name[zh_CN]" = "百度网盘";
        "Name[zh_TW]" = "百度網盤";
        "Comment[zh_CN]" = "百度网盘";
        "Comment[zh_TW]" = "百度網盤";
      };
    })
  ];

  meta = with lib; {
    description = "Baidu Netdisk";
    homepage = "https://pan.baidu.com/";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfreeRedistributable;
    mainProgram = "baidunetdisk";
  };
}
