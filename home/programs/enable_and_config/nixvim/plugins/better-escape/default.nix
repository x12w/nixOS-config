{
  # 快速双击 j 退出插入模式
  plugins.better-escape = {
    enable = true;
    settings = {
      timeout = 200;
      default_mappings = false;
      mappings = {
        i = {
          j = {
            j = "<Esc>";
          };
        };
      };
    };
  };
}
