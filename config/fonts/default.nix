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
        # 使用 find 递归查找所有子目录下的 ttf 和 ttc 文件 
        find ${inputs.winfonts} -type f -iregex ".*\.tt[cf]" -exec cp {} $out/share/fonts/truetype/ \;
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
