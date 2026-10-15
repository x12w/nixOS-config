{ pkgs, ... }:
let
  state = "/var/lib/kvm-proxy-wireguard";
  routeUp = pkgs.writeShellScript "kvm-proxy-route" ''
    set -eu
    for i in $(seq 1 50); do
      if ${pkgs.iproute2}/bin/ip link show vm-proxy0 >/dev/null 2>&1; then
        ${pkgs.iproute2}/bin/ip route replace table 177 default dev vm-proxy0
        exit 0
      fi
      sleep .1
    done
    exit 1
  '';
in {
  # Libvirt references this externally managed bridge. Without this module,
  # a fresh boot has no bridge, so the VM cannot fall back to a NAT network.
  networking.networkmanager.unmanaged = [
    "interface-name:virbr2" "interface-name:vm-proxy0" "interface-name:wg-vm-host"
  ];
  networking.wireguard.interfaces.wg-vm-host = {
    ips = [ "10.77.0.2/30" ];
    mtu = 1420;
    privateKeyFile = "${state}/host.key";
    allowedIPsAsRoutes = false;
    # Adopt only the interface created by the commissioning script.
    preSetup = ''
      if ip link show wg-vm-host >/dev/null 2>&1; then
        test "$(wg show wg-vm-host public-key)" = "5T/wkKAs0xtZ059hdJIAya+JyyOcj+aLIhq//ttf22E="
        ip link delete wg-vm-host
      fi
    '';
    peers = [{
      name = "pi";
      publicKey = "FvJwcPLNsjuthIDiw0NHXMLZv2u6o3vbRe7uok45WRw=";
      endpoint = "192.168.8.31:51821";
      allowedIPs = [ "10.77.0.1/32" ];
      persistentKeepalive = 25;
    }];
  };
  systemd.services.kvm-proxy-guard = {
    description = "Fail-closed bridge and routing for KVM proxy network";
    wantedBy = [ "multi-user.target" ];
    after = [ "firewall.service" ];
    before = [ "libvirtd.service" "kvm-vm-proxy.service" ];
    path = with pkgs; [ iproute2 nftables iptables procps coreutils gnugrep ];
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; UMask = "0077"; };
    script = ''
      set -euo pipefail
      install -d -m 700 ${state}
      # Delete+add happens in one atomic nft transaction. Never flush on stop.
      {
        if nft list table inet kvm_proxy_guard >/dev/null 2>&1; then
          echo 'delete table inet kvm_proxy_guard'
        fi
        cat <<'NFT'
      table inet kvm_proxy_guard {
        chain input {
          type filter hook input priority -200; policy accept;
          iifname "virbr2" counter drop
        }
        chain forward {
          type filter hook forward priority -200; policy accept;
          iifname "virbr2" oifname "vm-proxy0" ip saddr 192.168.100.0/24 meta l4proto { tcp, udp } accept
          iifname "virbr2" counter drop
          iifname "vm-proxy0" oifname "virbr2" ip daddr 192.168.100.0/24 ct state { established, related } accept
          oifname "virbr2" counter drop
        }
      }
      NFT
        if nft list table bridge kvm_proxy_l2 >/dev/null 2>&1; then
          echo 'delete table bridge kvm_proxy_l2'
        fi
        cat <<'NFT'
      table bridge kvm_proxy_l2 {
        chain forward {
          type filter hook forward priority -200; policy accept;
          meta ibrname "virbr2" counter drop
        }
      }
      NFT
      } > ${state}/guard.nft
      nft -c -f ${state}/guard.nft
      nft -f ${state}/guard.nft
      if ! ip link show virbr2 >/dev/null 2>&1; then
        ip link add virbr2 type bridge stp_state 0
      fi
      test -d /sys/class/net/virbr2/bridge
      ip link set virbr2 type bridge stp_state 0
      sysctl -qw net.ipv6.conf.virbr2.disable_ipv6=1
      sysctl -qw net.ipv4.conf.virbr2.rp_filter=0
      sysctl -qw net.ipv4.conf.virbr2.send_redirects=0
      ip address replace 192.168.100.1/24 dev virbr2
      ip link set virbr2 up
      sysctl -qw net.ipv4.ip_forward=1
      if ip rule show | grep -E '^(17700|17701):' | grep -v 'iif virbr2' | grep . >/dev/null; then
        echo 'KVM policy routing priorities already used' >&2; exit 1
      fi
      if ! ip rule show | grep '^17700:' >/dev/null; then
        ip rule add priority 17700 iif virbr2 lookup 177
      fi
      if ! ip rule show | grep '^17701:' >/dev/null; then
        ip rule add priority 17701 iif virbr2 prohibit
      fi
      iptables -w -C FORWARD -i virbr2 -o vm-proxy0 -s 192.168.100.0/24 -j ACCEPT 2>/dev/null || \
        iptables -w -I FORWARD 1 -i virbr2 -o vm-proxy0 -s 192.168.100.0/24 -j ACCEPT
      iptables -w -C FORWARD -i vm-proxy0 -o virbr2 -d 192.168.100.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
        iptables -w -I FORWARD 1 -i vm-proxy0 -o virbr2 -d 192.168.100.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    '';
  };
  systemd.services.libvirtd = {
    requires = [ "kvm-proxy-guard.service" ];
    after = [ "kvm-proxy-guard.service" ];
  };
  systemd.services.kvm-vm-proxy = {
    description = "KVM traffic via WireGuard and the Pi's existing proxy";
    wantedBy = [ "multi-user.target" ];
    requires = [ "kvm-proxy-guard.service" ];
    wants = [ "wireguard-wg-vm-host.target" ];
    after = [ "kvm-proxy-guard.service" "wireguard-wg-vm-host.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${state}/proxy.json";
      ExecStartPost = routeUp;
      Restart = "on-failure";
      RestartSec = 2;
      UMask = "0077";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      IPAddressDeny = "any";
      IPAddressAllow = "10.77.0.1/32";
    };
  };
}
