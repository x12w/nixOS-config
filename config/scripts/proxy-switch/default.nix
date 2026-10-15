{ pkgs, ... }:

let
  controller = pkgs.writeShellApplication {
    name = "proxy-switch-global";
    runtimeInputs = with pkgs; [ python3 iproute2 nftables systemd curl sing-box xray ];
    text = ''
      exec python3 ${./controller.py} "$@"
    '';
  };
in
{
  environment.systemPackages = [ controller ];
  networking.firewall.trustedInterfaces = [ "proxy-global" ];

  # Started explicitly by proxy-switch; neither boot nor rebuild enables it.
  systemd.services.proxy-switch-global = {
    description = "Per-host global proxy with IPv4/IPv6 TUN";
    wants = [ "proxy-switch-node.service" ];
    after = [ "network.target" "proxy-switch-node.service" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /run/proxy-switch-global/config.json";
      Restart = "on-failure";
      RestartSec = 2;
      UMask = "0077";
      # Do not remove the state or firewall on failure: fail closed until off.
    };
  };

  systemd.services.proxy-switch-node = {
    description = "Xray transport for the per-host global proxy";
    after = [ "network.target" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.xray}/bin/xray run -config /run/proxy-switch-global/xray.json";
      Restart = "on-failure";
      RestartSec = 2;
      UMask = "0077";
    };
  };
}
