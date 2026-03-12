{
  description = "x12w's nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    daeuniverse.url = "github:daeuniverse/flake.nix";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix/release-25.11";
    nur.url = "github:nix-community/NUR";

    winfonts = {
      url = "git+file:///etc/nixos/config/fonts/windows_fonts";
      flake = false; # 告诉 Nix 这只是一个普通文件夹，里面没有 flake.nix
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # easyconnect-flake.url = "path:/home/x12w/projects/nix/easyconnect";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      catppuccin,
      nur,
      niri,
      dms,
      dgop,
      nixvim,
      ...
    }@inputs:
    {

      nixosConfigurations.x12w-nix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # 关联现有的配置文件
          ./configuration.nix
          ./config/hardware-configuration.nix

          inputs.daeuniverse.nixosModules.dae
          inputs.daeuniverse.nixosModules.daed

          home-manager.nixosModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.x12w = {
              imports = [
                ./home.nix
                inputs.catppuccin.homeModules.catppuccin # 引入模块
                nixvim.homeModules.nixvim
              ];
            };
          }

          catppuccin.nixosModules.catppuccin

          # easyconnect-flake.nixosModules.default

          { nixpkgs.overlays = [ nur.overlays.default ]; }
        ];
      };

      packages.x86_64-linux.installer =
        (nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            # 1. 导入官方 ISO 最小化安装镜像的基础模块
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

            # 2. 导入你的主逻辑配置 (确保它不再导入 hardware-configuration.nix)
            ./configuration.nix

            # 3. 必须显式包含的外部功能模块
            inputs.daeuniverse.nixosModules.dae
            inputs.daeuniverse.nixosModules.daed
            inputs.catppuccin.nixosModules.catppuccin
            inputs.home-manager.nixosModules.home-manager

            # 4. 镜像环境补丁
            (
              { lib, pkgs, ... }:
              {
                # 确保 Overlay 生效，解决 NUR 找不到的问题
                nixpkgs.overlays = [ inputs.nur.overlays.default ];

                # 允许非自由软件 (如果百度网盘需要)
                nixpkgs.config.allowUnfree = true;

                # 自动登录
                services.displayManager.autoLogin.user = "x12w";

                # 这里的 fileSystems 不需要写，installation-cd-minimal 会自动处理
              }
            )

            # 5. Home Manager 用户配置
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.x12w.imports = [
                ./home.nix
                inputs.catppuccin.homeModules.catppuccin
                inputs.nixvim.homeModules.nixvim
              ];
            }
          ];
        }).config.system.build.isoImage;

    };
}
