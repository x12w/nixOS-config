{
  services.sing-box = {
    enable = true;

    settings = {
      log = {
        level = "info";
        timestamp = true;
      };

      dns = {
        servers = [
          {
            tag = "direct-dns";
            server = "223.5.5.5";
            type = "udp";
          }
        ];
        rules = [
          {
            domain_suffix = [ "panel.x12w.com" ];
            server = "direct-dns";
          }
        ];
        final = "direct-dns";
      };

      inbounds = [
        # SOCKS/HTTP 本地代理
        {
          type = "mixed";
          tag = "mixed-in";
          listen = "127.0.0.1";
          listen_port = 2080;
        }
        # TUN 透明代理 (需要 CAP_NET_ADMIN, nixpkgs 服务已配置)
        {
          type = "tun";
          tag = "tun-in";
          interface_name = "singbox_tun";
          address = [ "172.19.0.1/30" ];
          mtu = 9000;
          auto_route = true;
          strict_route = true;
          stack = "system";
        }
      ];

      outbounds = [
        # VLESS+REALITY 出站
        {
          type = "vless";
          tag = "proxy";
          server = "panel.x12w.com";
          server_port = 25339;
          uuid = "62210a47-fa27-407c-88ef-f411a62162f2";
          flow = "xtls-rprx-vision";
          tls = {
            enabled = true;
            server_name = "www.cloudflare.com";
            reality = {
              enabled = true;
              public_key = "gFYJYYSw1hoJRlKM4q8YVnORdGjMvO07mt6GDrNzFWA";
              short_id = "91";
            };
            utls = {
              enabled = true;
              fingerprint = "chrome";
            };
          };
          packet_encoding = "xudp";
        }
        {
          type = "direct";
          tag = "direct";
        }
        {
          type = "block";
          tag = "block";
        }
      ];

      route = {
        auto_detect_interface = true;
        default_domain_resolver = "direct-dns";
        rules = [
          # 防止 TUN 劫持 loopback 流量 (127.0.0.0/8)
          {
            ip_cidr = [ "127.0.0.0/8" "::1/128" ];
            outbound = "direct";
          }
          {
            ip_is_private = true;
            outbound = "direct";
          }
          {
            domain_suffix = [ "panel.x12w.com" ];
            outbound = "direct";
          }
          {
            outbound = "proxy";
          }
        ];
      };

      experimental = {
        cache_file = {
          enabled = true;
          path = "/var/lib/sing-box/cache.db";
        };
        clash_api = {
          external_controller = "127.0.0.1:9090";
          external_ui = "/var/lib/sing-box/dashboard";
          default_mode = "rule";
        };
      };
    };
  };
}
