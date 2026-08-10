# Fontconfig 2.18.2 generates config files with xsi:nil="true" attributes
# that fontconfig's own XML parser doesn't recognize (the DTD doesn't
# define the xsi namespace). This patches them out.
#
# These attributes are harmless functionally but produce hundreds of
# warnings on every font lookup, which is problematic for Electron apps.
(final: prev: {
  fontconfig = prev.fontconfig.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      echo "Patching fontconfig config files: removing xsi:nil attributes..."
      for f in $out/share/fontconfig/conf.avail/*.conf; do
        if grep -q 'xsi:nil' "$f" 2>/dev/null; then
          echo "  fixing $f"
          sed -i 's/ xsi:nil="true"//g' "$f"
        fi
      done
    '';
  });
})
