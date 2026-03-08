{
  # Starship 配置
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}
