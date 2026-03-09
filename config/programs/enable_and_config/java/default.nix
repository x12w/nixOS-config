{ pkgs, ... }:

{
  programs.java = {
    enable = true;
    package = pkgs.jdk17; # 设置系统默认版本
  };
}
