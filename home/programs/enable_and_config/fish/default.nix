{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    
    # 初始化脚本：相当于你的 config.fish
    interactiveShellInit = ''
      set -g fish_greeting "" # 关掉那个烦人的欢迎语
    '';

    # 别名设置（如果你之前在 Bash 里有，可以挪过来）
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake .#x12w-nix";
      # 刚才讨论的快捷快照命令也可以放这
      snap = "sudo snapper -c root create --description 'Manual'";

      ls = "eza --icons";
      # ll 显示详细信息、图标、Git 状态
      ll = "eza -lh --icons --git";
      # lt 显示文件夹树状图
      lt = "eza --tree --icons";

      cat = "bat";
    };

    # 插件：推荐几个常用的
    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z.src; }         # 快速跳转文件夹
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }     # 让命令输出五颜六色
    ];
  };
}
