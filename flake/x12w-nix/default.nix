{ inputs, ... }:

{
  imports = [
    ../../config/configuration.nix
    ../../config/hardware-configuration.nix

    inputs.daeuniverse.nixosModules.dae
    inputs.daeuniverse.nixosModules.daed

    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops

    # NUR / cachyos 内核 / baidunetdisk、codex-app 等自定义包。
    # 与安装镜像(flake/installer)共用同一份,改这里两边都生效。
    ../overlays

    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupCommand = ''mv -f "$srcPath" "$srcPath.bak"'';

      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users.x12w = {
        imports = [
          ../../home/home.nix
          inputs.catppuccin.homeModules.catppuccin # 引入模块
          inputs.nixvim.homeModules.nixvim
          inputs.plasma-manager.homeModules.plasma-manager
        ];
      };
    }

    {
      # sops-nix 密钥管理
      sops.age.keyFile = "/home/x12w/.config/sops/age/keys.txt";
      sops.defaultSopsFile = ../../secrets.yaml;
      sops.secrets.github-token = { };
    }

    inputs.catppuccin.nixosModules.catppuccin

    inputs.easyconnect.nixosModules.default

  ];
}
