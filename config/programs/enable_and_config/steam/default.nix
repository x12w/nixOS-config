{
  programs.steam = {
    enable = true;
    # 为 Steam 远程开启防火墙端口
    remotePlay.openFirewall = true;
    # 为专用服务器开启防火墙端口
    dedicatedServer.openFirewall = true;
  };
}
