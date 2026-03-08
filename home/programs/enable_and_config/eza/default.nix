{
  programs.eza = {
    enable = true;
    # 自动生成常用的别名（比如 ls, ll, la）
    enableFishIntegration = true; 
    # 额外参数：开启图标、Git 状态显示、文件权限颜色
    extraOptions = [
      "--group-directories-first" # 文件夹排在最前面
      "--header"                  # 显示表头
    ];
  };
}
