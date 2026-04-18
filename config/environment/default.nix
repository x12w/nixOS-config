{
  environment = {
    interactiveShellInit = ''
      # 透明代理一键切换函数
      proxy-switch() {
          # --- 配置区 ---
          local DEFAULT_PI_IP="192.168.8.31"  # 你可以改成你现在的树莓派IP
          local ROUTER_IP="192.168.8.1"
          # --------------

          # 使用 ''${1:-...} 是为了在 Nix 字符串中正确表示 $1
          local TARGET_IP="''${1:-$DEFAULT_PI_IP}"
          
          # 获取当前网关，注意此处变量前面的双单引号转义
          local current_gw
          current_gw=$(ip route show default | awk '{print $3}' | head -n 1)

          if [ "$current_gw" = "$ROUTER_IP" ]; then
              echo "📡 切换至代理模式 | 目标网关: $TARGET_IP"
              
              # 检查树莓派是否在线
              if ! ping -c 1 -W 1 "$TARGET_IP" > /dev/null; then
                  echo "❌ 错误: 无法连接到树莓派 $TARGET_IP"
                  return 1
              fi

              sudo ip route replace default via "$TARGET_IP"
              # 只有在非 systemd-resolved 模式下才需要这一行
              echo "nameserver $TARGET_IP" | sudo tee /etc/resolv.conf > /dev/null
              echo "✅ 已成功转发流量至树莓派。"
          else
              echo "🏠 恢复直连模式 | 目标网关: $ROUTER_IP"
              sudo ip route replace default via "$ROUTER_IP"
              echo "nameserver $ROUTER_IP" | sudo tee /etc/resolv.conf > /dev/null
              echo "✅ 已恢复主路由直连。"
          fi
      }
    '';
  };
}
