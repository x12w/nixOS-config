{ pkgs, inputs, ... }:

{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      wqy_zenhei
      jetbrains-mono
      sarasa-gothic
      nerd-fonts.jetbrains-mono
      wqy_zenhei
      corefonts
      vista-fonts
      (pkgs.runCommand "local-win-fonts" { } ''
        mkdir -p $out/share/fonts/truetype
        # 这里的 ${inputs.winfonts} 会被自动替换为该 Git 仓库在 Nix Store 里的路径
        cp -r ${inputs.winfonts}/**/*.{ttf,ttc,TTF,TTC} $out/share/fonts/truetype/ || true
      '')
    ];

    fontconfig.defaultFonts = {
      serif = [ "Noto Serif CJK SC" ];
      sansSerif = [ "Noto Sans CJK SC" ];
      monospace = [ "Noto Sans Mono CJK SC" ];
    };

    fontDir.enable = true;

    fontconfig.enable = true;
  };
}
