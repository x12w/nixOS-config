{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;

    extraPackages = with pkgs; [
      fd
      ripgrep
      jq
      imagemagick
      ffmpeg
      resvg
      poppler
      fzf
      ueberzugpp
      _7zz
    ];

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "mtime";
        preview_protocol = "ueberzug";
      };
    };
  };
}
