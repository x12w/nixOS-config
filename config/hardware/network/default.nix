{
  networking.hostName = "x12w-nix"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  # networking.proxy.default = "http://127.0.0.1:7897";

  # Enable networking
  networking.networkmanager.enable = true;

  networking.firewall = {
  enable = true;
  # 必须信任 tun 接口，否则流量无法流转
  # trustedInterfaces = [ "tun0" ];
  };
}
