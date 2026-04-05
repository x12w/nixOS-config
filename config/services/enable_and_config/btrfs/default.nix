{
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly"; # 每周执行一次
    fileSystems = [ "/" ]; # Btrfs 挂载点
  };
}
