"""Runtime controller; credentials arrive on stdin, never in the Nix store."""

import argparse
import copy
import fcntl
import ipaddress
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import time
import uuid


STATE = Path("/run/proxy-switch-global")
UNIT = "proxy-switch-global.service"
NODE_UNIT = "proxy-switch-node.service"
SOCKS_PORT = 18080
TABLE = "proxy_switch_global"
TUN = "proxy-global"
MARK = 0x5053
LOCAL4 = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "224.0.0.0/24"]
LOCAL6 = ["fc00::/7", "fe80::/10", "ff02::/16"]


def run(*args, check=True, **kwargs):
    # Avoid including configuration/credentials in exceptions or command lines.
    result = subprocess.run(args, text=True, capture_output=True, **kwargs)
    if check and result.returncode:
        raise RuntimeError(f"{args[0]} 执行失败（退出码 {result.returncode}）")
    return result


def active(unit):
    return run("systemctl", "is-active", "--quiet", unit, check=False).returncode == 0


def node_from_xray(source):
    """Import only the selected default node, not DNS/direct/subscription nodes."""
    outbounds = source.get("outbounds", [])
    defaults = [r.get("outboundTag") for r in source.get("routing", {}).get("rules", [])
                if r.get("ruleTag") == "default"]
    if len(defaults) != 1:
        raise ValueError("无法唯一识别 PassWall 默认节点；未切换网络")
    nodes = [o for o in outbounds if o.get("tag") == defaults[0]]
    if len(nodes) != 1:
        raise ValueError("默认节点配置不存在或重复")
    node = nodes[0]
    stream = node.get("streamSettings", {})
    if (node.get("protocol") != "vless" or stream.get("security") != "reality"
            or stream.get("network", "tcp") not in ("tcp", "raw")
            or node.get("proxySettings")):
        raise ValueError("当前只支持单跳 VLESS + REALITY TCP 节点；未切换网络")
    if stream.get("tcpSettings", {}).get("header", {}).get("type", "none") != "none":
        raise ValueError("不支持该节点的 TCP 伪装设置")
    servers = node.get("settings", {}).get("vnext", [])
    if len(servers) != 1 or len(servers[0].get("users", [])) != 1:
        raise ValueError("节点必须包含唯一的服务器和用户")
    server, user = servers[0], servers[0]["users"][0]
    reality = stream.get("realitySettings", {})
    public_key = reality.get("publicKey") or reality.get("password")
    if not public_key or not reality.get("serverName"):
        raise ValueError("REALITY 参数不完整")
    port = int(server["port"])
    if not 1 <= port <= 65535:
        raise ValueError("节点端口无效")
    # Only bootstrap the node itself before entering global mode. Once active,
    # the endpoint is numeric and every DNS request uses the tunneled resolver.
    address = socket.getaddrinfo(server["address"], port, socket.AF_INET,
                                 socket.SOCK_STREAM)[0][4][0]
    address = str(ipaddress.IPv4Address(address))
    uuid.UUID(user["id"])
    # Keep Xray's native REALITY settings instead of translating TLS semantics
    # between cores. sing-box handles TUN/DNS; the loopback SOCKS hop supports UDP.
    transport = copy.deepcopy(node)
    transport["tag"] = "proxy"
    transport["settings"]["vnext"][0]["address"] = address
    transport["streamSettings"].setdefault("sockopt", {})["mark"] = MARK
    return {"server": address, "server_port": port, "xray": transport}


def xray_config_for(node):
    return {
        "log": {"loglevel": "warning"},
        "inbounds": [{"tag": "local", "listen": "127.0.0.1", "port": SOCKS_PORT,
                      "protocol": "socks", "settings": {"auth": "noauth", "udp": True,
                                                          "ip": "127.0.0.1"}}],
        "outbounds": [node["xray"]],
    }


def config_for(node):
    return {
        "log": {"level": "warn"},
        "dns": {
            "servers": [{"type": "https", "tag": "remote", "server": "1.1.1.1",
                         "server_port": 443, "path": "/dns-query", "detour": "proxy",
                         "tls": {"enabled": True, "server_name": "cloudflare-dns.com"}}],
            "final": "remote", "strategy": "prefer_ipv4",
        },
        "inbounds": [
            {"type": "tun", "tag": "tun", "interface_name": TUN,
             "address": ["198.18.254.1/30", "fdfe:dcba:9876::1/126"],
             "mtu": 1400, "auto_route": True, "strict_route": True,
             "auto_redirect": False, "stack": "system",
             "route_exclude_address": LOCAL4 + LOCAL6 + [node["server"] + "/32"]},
            {"type": "direct", "tag": "dns4", "listen": "127.0.0.1", "listen_port": 1053},
            {"type": "direct", "tag": "dns6", "listen": "::1", "listen_port": 1053},
        ],
        "outbounds": [{"type": "socks", "tag": "proxy", "server": "127.0.0.1",
                       "server_port": SOCKS_PORT, "version": "5"},
                      {"type": "direct", "tag": "lan"}],
        "route": {
            "auto_detect_interface": True, "default_domain_resolver": "remote",
            "rules": [
                {"inbound": ["dns4", "dns6"], "action": "hijack-dns"},
                {"port": 53, "action": "hijack-dns"},
                {"ip_cidr": LOCAL4 + LOCAL6, "outbound": "lan"},
            ],
            "final": "proxy",
        },
    }


def firewall_for(node):
    # All physical interfaces are covered. No established-connection exception:
    # pre-existing direct sessions must not bypass the guard after activation.
    return f"""table inet {TABLE} {{
  chain dns_output {{
    type nat hook output priority -101; policy accept;
    meta l4proto {{ tcp, udp }} th dport 53 redirect to :1053
  }}
  chain output {{
    type filter hook output priority 100; policy accept;
    oifname "lo" accept
    oifname "{TUN}" accept
    ip daddr 127.0.0.1 meta l4proto {{ tcp, udp }} th dport 1053 accept
    ip6 daddr ::1 meta l4proto {{ tcp, udp }} th dport 1053 accept
    meta mark {MARK} ip daddr {node['server']} tcp dport {node['server_port']} accept
    ip daddr {{ {', '.join(LOCAL4)} }} accept
    ip6 daddr {{ {', '.join(LOCAL6)} }} accept
    ip daddr 255.255.255.255 udp sport 68 udp dport 67 accept
    counter reject with icmpx type admin-prohibited
  }}
}}
"""


def protected():
    return run("nft", "list", "table", "inet", TABLE, check=False).returncode == 0


def stop():
    if not STATE.exists():
        if protected():
            raise RuntimeError("发现无状态文件的防直连规则，请先人工检查，未移除保护")
        print("本机全局代理未启用")
        return
    saved = json.loads((STATE / "state.json").read_text())
    run("systemctl", "stop", UNIT, NODE_UNIT)
    if active(UNIT) or active(NODE_UNIT):
        raise RuntimeError("代理服务仍在运行，保留防直连保护")
    if saved["daed_active"]:
        run("systemctl", "start", "daed.service")
    if protected():
        run("nft", "delete", "table", "inet", TABLE)
    shutil.rmtree(STATE)
    print("已退出本机全局代理，恢复进入前的路由/DNS及 daed 状态")


def start(router, source):
    if STATE.exists():
        saved = json.loads((STATE / "state.json").read_text())
        if active(UNIT) and active(NODE_UNIT) and protected() and saved["router"] == router:
            print("本机全局代理已启用；切换节点请先运行 proxy-switch restore")
            return
        raise RuntimeError("存在全局代理状态，请先运行 proxy-switch restore 恢复")
    if protected() or run("ip", "link", "show", TUN, check=False).returncode == 0:
        raise RuntimeError("全局代理接口或规则已存在，未覆盖现有网络状态")
    for unit in [UNIT, NODE_UNIT]:
        if run("systemctl", "show", unit, "--property=LoadState", "--value").stdout.strip() != "loaded":
            raise RuntimeError("缺少系统服务，请先 rebuild 系统配置")
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", SOCKS_PORT))
    node = node_from_xray(source)
    STATE.mkdir(mode=0o700)
    saved = {"router": router, "daed_active": active("daed.service")}
    (STATE / "state.json").write_text(json.dumps(saved))
    config = STATE / "config.json"
    config.write_text(json.dumps(config_for(node)))
    xray_config = STATE / "xray.json"
    xray_config.write_text(json.dumps(xray_config_for(node)))
    rules = STATE / "guard.nft"
    rules.write_text(firewall_for(node))
    network_changed = False
    try:
        run("sing-box", "check", "-c", str(config))
        run("xray", "run", "-test", "-config", str(xray_config))
        run("nft", "--check", "-f", str(rules))
        run("nft", "-f", str(rules))
        network_changed = True
        if saved["daed_active"]:
            run("systemctl", "stop", "daed.service")
        run("systemctl", "start", NODE_UNIT, UNIT)
        for _ in range(50):
            if active(UNIT) and active(NODE_UNIT) and run("ip", "link", "show", TUN, check=False).returncode == 0:
                break
            time.sleep(0.1)
        else:
            raise RuntimeError("TUN 接口启动超时")
        # Confirm both IP families use the TUN before doing external probes.
        for family, destination in [("-4", "1.1.1.1"), ("-6", "2606:4700:4700::1111")]:
            routes = json.loads(run("ip", family, "-j", "route", "get", destination).stdout)
            if not routes or routes[0].get("dev") != TUN:
                raise RuntimeError("IPv4/IPv6 路由没有完整进入 TUN")
        for family, url in [("-4", "https://api.ipify.org"), ("-6", "https://api6.ipify.org")]:
            result = run("curl", family, "--noproxy", "*", "--fail", "--silent",
                         "--connect-timeout", "5", "--max-time", "12", url)
            address = ipaddress.ip_address(result.stdout.strip())
            if address.version != (4 if family == "-4" else 6):
                raise RuntimeError("代理出口检查返回错误的地址类型")
    except Exception:
        if network_changed:
            try:
                stop()
            except Exception as rollback_error:
                raise RuntimeError("启动失败且恢复未完成；已保留状态/防直连保护，请运行 proxy-switch restore") from rollback_error
        else:
            shutil.rmtree(STATE)
        raise
    print("已启用本机全局代理：TCP/UDP、DNS、IPv4/IPv6；局域网保持直连")
    print("代理意外退出时阻断公网直连；proxy-switch restore 可恢复原模式")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["on", "off"])
    parser.add_argument("router", nargs="?", default="192.168.8.31")
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error("需要通过 sudo 运行")
    os.umask(0o077)
    # A root-owned fixed lock serializes enter/exit across terminals.
    with open("/run/proxy-switch-global.lock", "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if args.mode == "off":
            stop()
        else:
            router = str(ipaddress.IPv4Address(args.router))
            source = json.loads(sys.stdin.read(1024 * 1024))
            start(router, source)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, RuntimeError) as error:
        # JSON decode errors contain no data snippets; never dump the source.
        print(f"全局代理操作失败：{error}", file=sys.stderr)
        sys.exit(1)
