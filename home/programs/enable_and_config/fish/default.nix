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
      # snap = "sudo snapper -c root create --description 'Manual'";

      ls = "eza --icons";
      # ll 显示详细信息、图标、Git 状态
      ll = "eza -lh --icons --git";
      # lt 显示文件夹树状图
      lt = "eza --tree --icons";

      cat = "bat";

      how = "tldr";
    };

    # 插件：推荐几个常用的
    plugins = [
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      } # 快速跳转文件夹
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      } # 让命令输出五颜六色
    ];

    functions = {
      # 1. 创建快照: snap <name>
      snap = {
        body = ''
          if test (count $argv) -eq 1
              sudo snapper -c root create --description "$argv[1]"
              echo "已成功创建快照: $argv[1]"
          else
              echo "用法错误。示例: snap before_update"
          end
        '';
      };

      # 2. 回滚快照: restore <name>
      restore = {
        body = ''
          if test (count $argv) -eq 1
              # 通过描述（Description）查找到对应的快照 ID
              # tail -n 1 确保如果有重复名称，选择最新的一条
              set -l id (sudo snapper -c root list | grep "$argv[1]" | awk '{print $1}' | tail -n 1)
            
              if test -n "$id"
                echo "正在回滚到快照 ID: $id (描述: $argv[1])..."
                sudo snapper -c root rollback $id
                echo "回滚成功！请重启系统以进入快照状态。"
              else
                echo "未找到名为 '$argv[1]' 的快照。"
              end
          else
              echo "用法错误。示例: restore before_update"
          end
        '';
      };

      snapall = {
        body = ''
          if test (count $argv) -eq 1
              set -l desc "$argv[1]"
              # 1. 获取所有配置名称（跳过表头）
              # 2. 遍历每一个配置执行创建操作
              for cfg in (snapper list-configs | tail -n +3 | awk '{print $1}')
                sudo snapper -c $cfg create --description "$desc"
                echo "已为配置 [$cfg] 创建快照: $desc"
              end
            echo "所有分区的快照均已建立。"
          else
            echo "用法错误。示例: snapall before_big_change"
          end
        '';
      };

      restoreall = {
        body = ''
          if test (count $argv) -eq 1
              set -l desc "$argv[1]"
              set -l targets
              set -l found_any false

              # 1. 预扫描：检查哪些分区存在该名称的快照
              for cfg in (snapper list-configs | tail -n +3 | awk '{print $1}')
                  set -l id (sudo snapper -c $cfg list | grep "$desc" | awk '{print $1}' | tail -n 1)
                  if test -n "$id"
                    set -a targets "$cfg:$id"
                    set found_any true
                  end
              end

              if test "$found_any" = false
                echo "在任何分区中都未找到描述为 '$desc' 的快照。"
                return 1
              end

              # 2. 显示回滚计划并请求确认
              echo "警告：准备执行全盘回滚！"
              echo "此操作将覆盖当前数据，重启后生效。"
              echo "--------------------------------"
              for target in $targets
                set -l parts (string split ":" $target)
                echo "   - 分区 [$parts[1]] -> 回滚至快照 ID: $parts[2]"
              end
              echo "--------------------------------"
            
              echo -n "确认要继续吗？请输入 'y' 并按回车: "
              read -l confirm
            
              if test "$confirm" = "y" -o "$confirm" = "Y"
                for target in $targets
                    set -l parts (string split ":" $target)
                    echo "正在处理 [$parts[1]]..."
                    sudo snapper -c $parts[1] rollback $parts[2]
                end
                echo "所有操作已完成。请执行 'reboot' 重启系统！"
              else
                echo "操作已取消，未执行任何回滚。"
              end
          else
            echo "用法错误。示例: restoreall before_big_update"
          end
        '';
      };

      snaplist = {
        body = ''
          # 遍历所有 Snapper 配置
          for cfg in (snapper list-configs | tail -n +3 | awk '{print $1}')
              echo "------------------------------------------------------"
              echo "📂 配置分区: 【$cfg】 的快照列表"
              echo "------------------------------------------------------"
              sudo snapper -c $cfg list
              echo "" # 换行美化
          end
        '';
      };

      proxy-switch = {
        body = ''
          set -l DEFAULT_PI_IP "192.168.8.31"
          set -l ROUTER_IP "192.168.8.1"
          set -l TARGET_IP "$argv[1]"

          if test -z "$TARGET_IP"
              set TARGET_IP "$DEFAULT_PI_IP"
          end

          set -l current_gw (ip route show default | awk '{print $3}' | head -n 1)

          if test "$current_gw" = "$ROUTER_IP"
              echo "📡 切换至代理模式 | 目标网关: $TARGET_IP"
              if not ping -c 1 -W 1 "$TARGET_IP" > /dev/null
                  echo "❌ 错误: 无法连接到树莓派 $TARGET_IP"
                  return 1
              end
              sudo ip route replace default via "$TARGET_IP"
              echo "nameserver $TARGET_IP" | sudo tee /etc/resolv.conf > /dev/null
          else
              echo "🏠 恢复直连模式 | 目标网关: $ROUTER_IP"
              sudo ip route replace default via "$ROUTER_IP"
              echo "nameserver $ROUTER_IP" | sudo tee /etc/resolv.conf > /dev/null
          end
        '';
      };

      proxy-vm = {
        body = ''
          function proxy-vm
              set -l vm_lan_ip "10.0.0.1"
              set -l vm_ssh_user "root"
              
              # 1. 检查输入
              if test (count $argv) -eq 0; or test "$argv[1]" != "on" -a "$argv[1]" != "off"
                  echo "用法: proxy-vm [on|off]"
                  return 1
              end

              if test "$argv[1]" = "on"
                  # 获取当前的真实物理网关 (跳过虚拟网段)
                  set -l real_gw (ip route show | grep default | grep -v "10.0.0" | awk '{print $3}' | head -n 1)
                  
                  echo "🔍 正在从虚拟机同步节点信息..."
                  
                  # 2. 远程获取节点地址 (需提前配置 SSH 免密)
                  set -l node_addr (ssh -o ConnectTimeout=2 $vm_ssh_user@$vm_lan_ip "uci get passwall.@global[0].tcp_node" 2>/dev/null | xargs -I {} ssh $vm_ssh_user@$vm_lan_ip "uci get passwall.{}.address" 2>/dev/null)

                  if test -z "$node_addr"
                      echo "❌ 无法获取节点。请确认虚拟机已开启、PassWall 已配置且 SSH 免密已打通。"
                      return 1
                  end

                  echo "🌐 节点地址: $node_addr"
                  
                  # 3. 解析并特赦 IP，防止回环
                  set -l node_ips (dig +short $node_addr | grep -E '^[0-9.]+$')
                  if test -z "$node_ips"
                      set node_ips $node_addr
                  end

                  for ip in $node_ips
                      sudo ip route add $ip via $real_gw 2>/dev/null
                      echo "✅ 特赦节点: $ip -> $real_gw"
                  end

                  # 4. 切换默认网关和 DNS
                  sudo ip route replace default via $vm_lan_ip
                  echo "nameserver $vm_lan_ip" | sudo tee /etc/resolv.conf > /dev/null
                  
                  echo "🚀 旁路代理已开启！"

              else
                  echo "🏠 正在恢复原生网络配置..."
                  # 重启 NetworkManager 强行重置路由表和 DNS
                  sudo systemctl restart NetworkManager
                  echo "✅ 已恢复由 NetworkManager 管理的默认路由。"
              end
          end
        '';
      };
    };
  };
}
