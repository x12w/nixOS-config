{ lib, ... }:

{
  home.activation = {
    # 任务名称：removeGtkrcConflict
    removeGtkrcConflict = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      # 使用 $HOME 环境变量来定位文件
      # -f 确保如果文件不存在也不会报错
      $DRY_RUN_CMD rm -rf $HOME/.gtkrc-2.0.backup
      $DRY_RUN_CMD rm -rf $HOME/.config/gtk-2.0/gtkrc.backup

      # 如果你希望彻底一点，甚至可以把原本的真实文件也删了
      # 让 Home Manager 每次都能重新建立软链接
      # $DRY_RUN_CMD rm -f $HOME/.config/gtk-2.0/gtkrc
    '';
  };
}
