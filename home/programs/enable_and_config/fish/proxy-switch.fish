set -l ROUTER_IP 192.168.8.1
set -l DEFAULT_PI_IP 192.168.8.31
set -l GLOBAL_HELPER /run/current-system/sw/bin/proxy-switch-global
set -l GLOBAL_STATE /run/proxy-switch-global
set -l MODE "$argv[1]"
set -l TARGET_IP "$argv[2]"

if test (count $argv) -gt 2
    echo '用法: proxy-switch [on|global|off|restore|status] [IP]' >&2
    return 1
end

# 保留旧用法 proxy-switch <IP>。
if string match -qr '^[0-9.]+$' "$MODE"
    if test (count $argv) -ne 1
        echo '直接指定 IP 时不接受第二个参数' >&2
        return 1
    end
    set TARGET_IP "$MODE"
    set MODE on
end

if test -z "$MODE"
    if test -d "$GLOBAL_STATE"
        set MODE restore
    else
        set -l current_gw (ip -4 route show default | awk '{print $3}' | head -n 1)
        if test "$current_gw" = "$ROUTER_IP"
            set MODE on
        else
            set MODE off
        end
    end
end

if test -n "$TARGET_IP"
    if not contains -- "$MODE" on global
        echo '只有 on/global 模式接受目标 IP' >&2
        return 1
    end
    if not string match -qr '^([0-9]{1,3}\.){3}[0-9]{1,3}$' "$TARGET_IP"
        echo '目标必须是 IPv4 地址' >&2
        return 1
    end
    for octet in (string split . "$TARGET_IP")
        if test "$octet" -gt 255
            echo '目标 IPv4 地址无效' >&2
            return 1
        end
    end
end

switch "$MODE"
    case global
        test -z "$TARGET_IP"; and set TARGET_IP "$DEFAULT_PI_IP"
        if not test -x "$GLOBAL_HELPER"
            echo '请先应用 /etc/nixos 的系统配置，以安装本机全局代理服务' >&2
            return 1
        end
        sudo -v; or return 1
        # 读取现用节点，不修改 PassWall；凭据只经过内存/管道。
        set -l node_config (command ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=5 \
            "root@$TARGET_IP" 'cat /tmp/etc/passwall/acl/default/TCP_UDP_SOCKS_DNS.json')
        if test $status -ne 0
            echo '读取节点失败；需要可免密登录且已验证主机密钥的软路由 SSH' >&2
            return 1
        end
        printf '%s\n' $node_config | sudo "$GLOBAL_HELPER" on "$TARGET_IP"
        return $pipestatus[-1]

    case restore
        if test -d "$GLOBAL_STATE"
            sudo "$GLOBAL_HELPER" off; or return 1
        else
            echo '本机全局代理未启用，当前网关和 DNS 保持不变'
        end

    case on off
        # 先退出 TUN 并恢复 daed，再执行原有网关切换。
        if test -d "$GLOBAL_STATE"
            sudo "$GLOBAL_HELPER" off; or return 1
        end
        if test "$MODE" = on
            test -z "$TARGET_IP"; and set TARGET_IP "$DEFAULT_PI_IP"
            if not ping -c 1 -W 1 "$TARGET_IP" > /dev/null
                echo "无法连接到 $TARGET_IP" >&2
                return 1
            end
        else
            set TARGET_IP "$ROUTER_IP"
        end
        sudo ip route replace default via "$TARGET_IP"; or return 1
        printf 'nameserver %s\n' "$TARGET_IP" | sudo tee /etc/resolv.conf > /dev/null
        or return 1
        if test "$MODE" = on
            echo "已切换至软路由分流模式（网关/DNS $TARGET_IP）"
        else
            echo "已恢复直连网关（网关/DNS $TARGET_IP）"
        end

    case status
        if test -d "$GLOBAL_STATE"
            if systemctl is-active --quiet proxy-switch-global.service; and systemctl is-active --quiet proxy-switch-node.service
                echo '本机全局代理：TCP/UDP、DNS、IPv4/IPv6；局域网直连'
            else
                echo '全局代理服务已停止或异常；请检查服务日志，或运行 proxy-switch restore 恢复'
                return 1
            end
        else
            set -l current_gw (ip -4 route show default | awk '{print $3}' | head -n 1)
            set -l dns (awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf)
            if test "$current_gw" = "$ROUTER_IP"
                echo "直连网关模式 | 网关 $current_gw | DNS $dns"
            else
                echo "软路由分流模式 | 网关 $current_gw | DNS $dns"
            end
        end

    case '*'
        echo '用法: proxy-switch [on|global|off|restore|status] [IP]'
        echo "  on       使用软路由分流（默认 $DEFAULT_PI_IP）"
        echo '  global   仅本机全局 TUN 代理，运行时读取软路由当前 VLESS/REALITY 节点'
        echo '  restore  退出全局代理，回到进入前的网络状态'
        echo '  off      退出全局代理并切回直连网关'
        echo '  status   查看当前模式'
        echo '  不带参数：全局模式下恢复原状态，否则切换软路由/直连网关'
        return 1
end
