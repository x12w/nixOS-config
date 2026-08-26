# NVIDIA 驱动修复说明

> 记录驱动/内核升级后遇到的构建失败及对应修复，便于日后 Debug 后回溯修改。

## 最近一次修复：kernel 7.2.0 编译失败（gpio const API 变更）

### 现象

系统更新时构建失败，报错如下：

```
error: Cannot build '/nix/store/...-nvidia-open-610.57.04-7.2.0.drv'.
Reason: builder failed with exit code 2.
...
common/inc/nv-linux.h:1737:51: error: passing 'const struct gpio_device *' to
parameter of type 'struct gpio_device *' discards qualifiers
[-Werror,-Wincompatible-pointer-types-discards-qualifiers]
```

### 根因

- 运行组合：`7.1.6-cachyos-lto` + nvidia-open `610.43.03`（正常）。
- 升级后组合：内核 **`7.2.0-cachyos-bore-lto`** + nvidia-open **`610.57.04`**（失败）。
- 内核 7.2.0 将 `gpio_device_get_chip()` 参数改为 `const struct gpio_device *`，
  而 NVIDIA 610.57.04 的 `nv-linux.h` 内 `__to_hwgpio()` 仍以非 const 指针调用，
  clang 在 `-Werror` 下将该警告当作错误，模块编译失败。

### 修复（`default.nix` 中 `hardware.nvidia.package`）

参照 Gentoo [nvidia-drivers-610.57.04 补丁][gentoo] 的做法，为 open 内核模块
追加 `-Wno-error=incompatible-pointer-types-discards-qualifiers`，把该警告从
error 降级为普通 warning：

```nix
package = let
  nvidiaPkgs = config.boot.kernelPackages.nvidiaPackages;
in
nvidiaPkgs.latest
// {
  # open 是 passthru 属性，overrideAttrs 不会重建它，需用 // 显式替换。
  open = nvidiaPkgs.latest.open.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i 's/-Wno-error/& -Wno-error=incompatible-pointer-types-discards-qualifiers/' kernel-open/Kbuild
    '';
  });
};
```

### 为什么这样改（Debug 要点）

1. **用 `//` 而不是 `overrideAttrs`**：`nvidiaPackages.latest.open` 是
   passthru 属性，`overrideAttrs` 只改 derivation 本身、不重建 passthru，
   直接 override 顶层 attr 会被 passthru 覆盖回去（drv 不变，修复无效）。
   必须 `latest // { open = ... }` 替换。
2. **Kbuild 里已有 `-Wno-error`**（`kernel-open/Kbuild`），sed 把它扩为
   `-Wno-error=incompatible-pointer-types-discards-qualifiers` 即可命中。
3. **cachyos-kernel flake 内置的补丁不生效**：它加在 `linuxPackages-cachyos-*`
   的 `latest.open` 上，而本配置用 `pkgs.linuxPackagesFor cachyos-kernel`
   组装，nvidia 包从主 nixpkgs 继承，**不经过 cachyos 的 override**。
   且其做法（去掉 `__to_hwgpio` 参数 `const`）方向有误——`nv-linux.h:1772`
   调用方传入的是非 const 指针，去掉 const 会在别处产生新的 const 丢弃错误，
   故未采用。

### 何时可以移除

NVIDIA 后续驱动（≥ 610.58 或更新分支）在源码层面适配 `const` 后，
可删除上述 `package` override 恢复 `package = config.boot.kernelPackages.nvidiaPackages.latest;`。
验证方式：`nix build .#nixosConfigurations.x12w-nix.config.hardware.nvidia.package.open`
构建通过且无此报错即可。

### 上游参考

- Gentoo 补丁：<https://gitweb.geodns.gentoo.org/repo/sync/gentoo.git/commit/?id=2da03430470543dfaf7f233c93661eedc2dcf44c>
- NVIDIA 官方源码：<https://github.com/NVIDIA/open-gpu-kernel-modules>（`kernel-open/common/inc/nv-linux.h`）

[gentoo]: https://gitweb.geodns.gentoo.org/repo/sync/gentoo.git/commit/?id=2da03430470543dfaf7f233c93661eedc2dcf44c
