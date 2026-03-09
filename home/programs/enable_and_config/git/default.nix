{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "x12w";
        email = "w17802627260@gmail.com";
      };

      init = {
        defaultBranch = "main";
      };

      safe = {
        directory = "/etc/nixos";
      };
    };
  };
}
