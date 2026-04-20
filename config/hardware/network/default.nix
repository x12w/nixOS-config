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

  networking.bridges."virbr1".interfaces = [ ]; # 不绑定物理网卡，仅作为虚拟交换机

  # 给网桥配置静态 IP（宿主机的身份）
  networking.interfaces."virbr1".ipv4.addresses = [
    {
      address = "10.0.0.2";
      prefixLength = 24;
    }
  ];

  # 确保 NetworkManager 不会乱动这个网桥
  networking.networkmanager.unmanaged = [ "virbr1" ];
}
