{
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "daily";

    configs = {
      root = {
        SUBVOLUME = "/";
        ALLOW_USERS = [ "x12w" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        # 迁移后的新写法：直接写成属性
        TIMELINE_LIMIT_HOURLY = 10;
        TIMELINE_LIMIT_DAILY = 5;
        TIMELINE_LIMIT_WEEKLY = 0;
        TIMELINE_LIMIT_MONTHLY = 0;
        TIMELINE_LIMIT_YEARLY = 0;
      };

      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = [ "x12w" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        # 迁移后的新写法
        TIMELINE_LIMIT_HOURLY = 5;
        TIMELINE_LIMIT_DAILY = 3;
        TIMELINE_LIMIT_WEEKLY = 0;
        TIMELINE_LIMIT_MONTHLY = 0;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    };
  };
}
