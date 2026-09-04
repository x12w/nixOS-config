{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    # 初始化脚本：相当于你的 config.fish
    interactiveShellInit = ''
      set -g fish_greeting "" # 关掉那个烦人的欢迎语
    '';

    # 所有 fish shell 都执行（含非交互）
    shellInit = ''
      # GitHub token（sops-nix 解密）— 供 nix flake update 等使用
      if test -r /run/secrets/github-token
          set -l _gh_token (string trim (cat /run/secrets/github-token))
          if not string match -q 'ghp_PLACEHOLDER*' "$_gh_token"
              set -gx GITHUB_TOKEN "$_gh_token"
          end
      end
    '';

    # 别名设置（如果你之前在 Bash 里有，可以挪过来）
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake .#x12w-nix";
      # 刚才讨论的快捷快照命令也可以放这
      # snap = "sudo snapper -c root create --description 'Manual'";

      # 注意: eza 0.20+ 的 --icons 接受可选值 [always|auto|never],
      # 必须写成 --icons=always, 否则后面跟目录名时会被当成该选项的值而报错
      ls = "eza --icons=always";
      # ll 显示详细信息、图标、Git 状态
      ll = "eza -lh --icons=always --git";
      # lt 显示文件夹树状图
      lt = "eza --tree --icons=always";

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
        description = "切换代理/直连模式: proxy-switch [on|off|status] [IP]";
        body = ''
          set -l ROUTER_IP "192.168.8.1"
          set -l DEFAULT_PI_IP "192.168.8.31"

          set -l MODE "$argv[1]"
          set -l TARGET_IP "$argv[2]"

          # 兼容旧用法: proxy-switch <IP> 直接切到该 IP 的代理模式
          if string match -qr '^[0-9.]+$' "$MODE"
              set TARGET_IP "$MODE"
              set MODE on
          end

          # 不带参数: 根据当前网关自动切换
          if test -z "$MODE"
              set -l current_gw (ip route show default | awk '{print $3}' | head -n 1)
              if test "$current_gw" = "$ROUTER_IP"
                  set MODE on
              else
                  set MODE off
              end
          end

          switch "$MODE"
              case on
                  test -z "$TARGET_IP"; and set TARGET_IP "$DEFAULT_PI_IP"
                  echo "📡 切换至代理模式 | 目标网关: $TARGET_IP"
                  if not ping -c 1 -W 1 "$TARGET_IP" > /dev/null
                      echo "❌ 错误: 无法连接到 $TARGET_IP"
                      return 1
                  end
                  sudo ip route replace default via "$TARGET_IP"; or return 1
                  echo "nameserver $TARGET_IP" | sudo tee /etc/resolv.conf > /dev/null; or return 1
                  echo "✅ 已切换至代理模式 (网关 $TARGET_IP)"

              case off
                  echo "🏠 恢复直连模式 | 目标网关: $ROUTER_IP"
                  sudo ip route replace default via "$ROUTER_IP"; or return 1
                  echo "nameserver $ROUTER_IP" | sudo tee /etc/resolv.conf > /dev/null; or return 1
                  echo "✅ 已恢复直连模式 (网关 $ROUTER_IP)"

              case status
                  set -l current_gw (ip route show default | awk '{print $3}' | head -n 1)
                  set -l dns (awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf)
                  if test "$current_gw" = "$ROUTER_IP"
                      echo "🌐 直连模式 | 网关 $current_gw | DNS $dns"
                  else
                      echo "🌐 代理模式 | 网关 $current_gw | DNS $dns"
                  end

              case '*'
                  echo "用法: proxy-switch [on|off|status] [IP]"
                  echo "  on      切换到代理模式 (默认 $DEFAULT_PI_IP)"
                  echo "  off     恢复直连模式"
                  echo "  status  查看当前模式"
                  echo "  不带参数: 根据当前网关自动切换"
                  return 1
          end
        '';
      };

      proxy-vm = {
        body = ''
          set -l vm_lan_ip "10.0.0.1"
          set -l vm_ssh_user "root"

          if test "$argv[1]" = "on"
              # 1. 寻找物理网关并【锁定】
              set -l real_gw (ip route show default | grep -vE 'virbr|docker|10.0.0' | awk '{print $3}' | head -n 1)
              set -l real_dev (ip route show default | grep -vE 'virbr|docker|10.0.0' | awk '{print $5}' | head -n 1)

              if test -z "$real_gw"
                  echo "❌ 无法定位物理网关。"
                  return 1
              end

              # 2. 特赦节点 (获取 IP 逻辑不变)
              set -l node_info (ssh -o ConnectTimeout=2 $vm_ssh_user@$vm_lan_ip "uci get passwall.@global[0].tcp_node" 2>/dev/null | xargs -I {} ssh $vm_ssh_user@$vm_lan_ip "uci get passwall.{}.address" 2>/dev/null)
              if test -n "$node_info"
                  set -l node_ips (dig +short $node_info | grep -E '^[0-9.]+$'); test -z "$node_ips"; and set node_ips $node_info
                  for ip in $node_ips
                      sudo ip route add $ip via $real_gw dev $real_dev 2>/dev/null
                  end
                  echo "✅ 节点特赦完成"
              end

              # 3. 【核心修正】强制清理所有旧的默认路由，只留虚拟机
              sudo ip route del default 2>/dev/null
              sudo ip route add default via $vm_lan_ip dev virbr1
              
              # 4. 写入 DNS
              echo -e "nameserver $vm_lan_ip\nnameserver 223.5.5.5" | sudo tee /etc/resolv.conf > /dev/null
              echo "🚀 代理模式已锁定出口至 10.0.0.1"

          else if test "$argv[1]" = "off"
              echo "🏠 恢复原生网络..."
              sudo rm -f /etc/resolv.conf
              # 删掉我们手动加的默认路由，NM 就会自动把自己的 192.168.8.1 补上来
              sudo ip route del default via $vm_lan_ip 2>/dev/null
              sudo systemctl restart NetworkManager
              echo "✅ 已重置。"
          end
        '';
      };
    };
  };
}
