{
  description = "x12w's nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    daeuniverse.url = "github:daeuniverse/flake.nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    nur.url = "github:nix-community/NUR";

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
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # 固定在 PR #14052 合入之前的最后一个 main 提交（49b95d84 的父提交）。
    # 该 PR 让 Ghostty 弃用 GtkGLArea，改为自建 EGL context 并用 legacy 入口
    # eglGetDisplay(EGL_DEFAULT_DISPLAY)；在 libglvnd 下这条路径会解析到 Mesa 而不是
    # NVIDIA，Mesa 没有对应 DRI 驱动，于是回退 llvmpipe 软渲染（着色器背景跑 CPU）。
    # 等上游 PR #14319（改用 EGL_PLATFORM_SURFACELESS_MESA）合并后，改回跟踪 main。
    ghostty.url = "github:ghostty-org/ghostty/d30379c5b9e3dad0963a0c6881896b9b38963801";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    easyconnect.url = "github:x12w/SCUT_easyconnect_nix/main";

    baidunetdisk.url = "github:x12w/baidunetdisk-nix/main";

    sops-nix.url = "github:Mic92/sops-nix";

    codex-app.url = "github:x12w/codex-app-nix/main";
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
      plasma-manager,
      ghostty,
      nix-cachyos-kernel,
      easyconnect,
      baidunetdisk,
      codex-app,
      ...
    }@inputs:
    {

      nixosConfigurations.x12w-nix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # 关联现有的配置文件
          ./flake/x12w-nix
        ];
      };

      packages.x86_64-linux.installer =
        (nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./flake/installer
          ];
        }).config.system.build.isoImage;

    };
}
