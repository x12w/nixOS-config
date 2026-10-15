# 本机全局代理

先应用系统配置：

```sh
sudo nixos-rebuild switch --flake /etc/nixos#x12w-nix
```

在新的 fish 终端中使用：

```fish
proxy-switch global                 # 读取 192.168.8.31 当前节点并进入本机全局模式
proxy-switch global 192.168.8.31     # 显式指定软路由
proxy-switch status
proxy-switch restore                # 恢复进入全局模式前的网络状态
proxy-switch on                     # 退出全局模式，使用原有软路由分流
proxy-switch off                    # 退出全局模式，切回 192.168.8.1 网关
```

`on/off` 保留原有的网关和 DNS 切换行为；无参数时仍切换这两种模式。
在全局模式下，无参数等同于 `restore`，不会擅自切换进入前的网关。

`global` 通过已验证主机密钥的免密 SSH，只读获取 PassWall 当前运行的
`/tmp/etc/passwall/acl/default/TCP_UDP_SOCKS_DNS.json`，沿用其默认节点。
目前支持本机正在使用的单跳 VLESS + REALITY TCP 节点；不支持的节点会在修改网络前报错。
节点凭据不进入 Nix 配置或 store，只保存在 root 可访问的 `/run/proxy-switch-global`，
退出后删除。首次启动时需要解析节点自身的地址，随后使用固定的 IPv4 节点地址连接；
这条 IPv4 隧道可以承载 IPv4 和 IPv6 目标流量。节点改变后先 `restore` 再 `global`。

全局模式使用 sing-box TUN，接管本机默认网络命名空间中的 TCP/UDP 和 IPv4/IPv6。
节点连接保留原有 Xray 设置，通过本机 `127.0.0.1:18080` SOCKS 连接 TUN 与 Xray；
这段回环连接支持 TCP/UDP，不是仅支持 TCP 的 SSH 端口转发。
局域网保持直连。DNS 的 TCP/UDP 53 请求被重定向至本机 DNS 入站，再经代理访问 DoH；
其他应用的 DoH/DoT 同样通过全局隧道。不会改写 `/etc/resolv.conf` 或原默认网关。
不对虚拟机、容器或手动创建的其他网络命名空间作同等保障。

启动时临时停止原先运行的 daed，避免两套透明代理冲突；退出时按原状态恢复。
独立 nftables OUTPUT 规则覆盖所有物理网卡，阻断未经过 TUN 的公网流量，
只放行带指定标记的代理节点连接及局域网、DHCP 等必要流量。
不放行已经建立的公网直连，因此已有直连连接可能在切换时断开。
服务崩溃会自动重试，防直连规则保留；显式 `restore/on/off` 才退出保护。
启动失败会尝试恢复原模式；恢复失败时保留状态和保护，避免静默直连。

该模式是运行时开关，重启电脑后不自动启用。外部修改/清空防火墙可能移除保护，
因此不能把它视为对抗管理员或任意特权程序的隔离边界。

排查命令：

```sh
systemctl status proxy-switch-global.service
systemctl status proxy-switch-node.service
sudo journalctl -u proxy-switch-global.service -n 50
sudo nft list table inet proxy_switch_global
```

验证代码：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s /etc/nixos/config/scripts/proxy-switch
fish -n /etc/nixos/home/programs/enable_and_config/fish/proxy-switch.fish
# PATH 中需包含 ip、nft、sing-box；只修改隔离网络命名空间。
PROXY_SWITCH_HOST_NETNS="$(readlink /proc/self/ns/net)" \
  unshare --user --map-root-user --net python3 /etc/nixos/config/scripts/proxy-switch/check-netns.py
```
