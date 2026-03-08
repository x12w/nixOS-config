{
  # 使用 systemd-tmpfiles 自动化管理目录
  systemd.tmpfiles.rules = [
    # 格式说明：
    # 类型(v=btrfs子卷) 路径 权限 用户 组 生存时间(不用填) 参数
    
    "v /.snapshots 0750 root root -"
    "v /home/.snapshots 0750 root root -"
  ];
}
