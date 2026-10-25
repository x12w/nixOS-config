{ pkgs, inputs, ... }:

{
  programs.ghostty = {
    enable = true;
    package = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # 这里就是声明式的配置文件内容
    settings = {
      theme = "catppuccin-mocha";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      window-decoration = false;
      cursor-style = "block";
      shell-integration = "fish";
      shell-integration-features = "ssh-env,ssh-terminfo";
      background-opacity = 0.1;
      # background-blur 现在接受数值作为模糊半径（旧版 boolean + background-blur-radius 已废弃）
      background-blur = 5;

      # 背景
      custom-shader = "${./shaders/inverted_quadtree.glsl}";

      # 启用 GPU 硬件加速相关的特性
      font-thicken = true; # 字体加粗效果更自然
      # term = "ghostty";
    };

    systemd.enable = true;
  };

  # 当前固定的 Ghostty 可能在注册 SIGUSR2 处理器前通知 systemd 已就绪，
  # 导致 systemd 262 拒绝启动 notify-reload 服务。改用 notify，并保留配置重载。
  # 升级到包含 https://github.com/ghostty-org/ghostty/pull/14399 的版本后可移除。
  xdg.configFile."systemd/user/app-com.mitchellh.ghostty.service.d/notify.conf".text = ''
    [Service]
    Type=notify
    ExecReload=${pkgs.coreutils}/bin/kill -USR2 $MAINPID
  '';

}
