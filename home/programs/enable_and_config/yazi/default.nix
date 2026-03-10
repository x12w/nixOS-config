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
    ];

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "mtime";
      };
    };
  };
}
