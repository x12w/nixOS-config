{ inputs, ... }:

{
  imports = [
    # 1. 导入官方 ISO 最小化安装镜像的基础模块
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

    # 2. 导入主逻辑配置
    ../../config/configuration.nix

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

        # 允许非自由软件
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
        ../../home/home.nix
        inputs.catppuccin.homeModules.catppuccin
        inputs.nixvim.homeModules.nixvim
        inputs.plasma-manager.homeModules.plasma-manager
      ];
    }
  ];
}
