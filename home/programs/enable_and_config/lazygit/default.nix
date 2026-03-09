{
  programs.lazygit = {
    enable = true;

    settings = {
      git = {
        overrideGpg = true;
      };

      gui = {
        authorColors = {
          "x12w" = "#b4befe";
          "GitHub" = "#f9e2af"; # 给 GitHub Actions 或 Bot 设一个颜色
          "Dependabot" = "#94e2d5"; # 给自动依赖更新设一个颜色
        };

        # 配合这个设置效果更佳
        showIcons = true; # 显示作者头像图标

        theme = {
          activeBorderColor = [
            "#b4befe"
            "bold"
          ]; # Catppuccin Mocha 风格
          inactiveBorderColor = [ "#a6adc8" ];
          searchingActiveBorderColor = [ "#f9e2af" ];
        };
      };
    };
  };
}
