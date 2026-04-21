{ lib, ... }:

{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  #镜像源设置
  nix.settings = {
    substituters = lib.mkForce [
      # "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      # "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];

  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
