{ pkgs, ... }:

{
  users.users.x12w = {
    isNormalUser = true;
    description = "x12w";
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" "wireshark" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];

    shell = pkgs.fish;
  };
}
