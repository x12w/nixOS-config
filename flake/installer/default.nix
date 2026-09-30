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
    inputs.easyconnect.nixosModules.default
    inputs.home-manager.nixosModules.home-manager

    # 与主系统共用同一份 overlay（NUR / cachyos 内核 / baidunetdisk、codex-app 等自定义包）
    ../overlays

    # 4. 镜像环境补丁
    (
      { lib, pkgs, ... }:
      {
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
