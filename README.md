# NixOS 系统从零构建指南 (x12w-nix)

本指南旨在指导如何从零开始使用此配置重建系统 。该配置基于 **NixOS Unstable** 分支，集成了 **KDE Plasma 6** 、**NVIDIA 显卡驱动** 、**开发工具链** 以及 **Catppuccin** 个性化主题 。

## 1. 基础环境准备

在正式应用此配置前，需先在初始安装的系统中开启必要特性并加速下载。

### 启用 Flakes 与设置主机名

编辑临时生成的 `/etc/nixos/configuration.nix`，确保包含以下关键设置：

* 
**主机名**：`networking.hostName = "x12w-nix";` 


* 
**特性开关**：`nix.settings.experimental-features = [ "nix-command" "flakes" ];` 



### 配置国内镜像源

为了加快构建速度，建议加入以下二进制缓存服务器 ：

```nix
nix.settings.substituters = lib.mkForce [
  "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  "https://mirrors.ustc.edu.cn/nix-channels/store"
  "https://cache.nixos.org"
];

```

---

## 2. 配置文件迁移

将你的自定义配置文件拷贝到 `/etc/nixos/` 目录：

1. 
**保留**本地自动生成的 `hardware-configuration.nix`（因为它包含特定机器的挂载点和硬件 UUID） 。


2. 
**复制**此仓库中的 `configuration.nix`、`flake.nix` 等其他所有文件到 `/etc/nixos/` 。



---

## 3. 解决已知构建报错

在执行 `nixos-rebuild` 之前，必须手动处理以下两个环节，否则构建会失败：

### A. Windows 字体预加载 (版权避让)

由于版权原因，Windows 字体（`winFonts.tar.gz`）不通过 Git 跟踪，也不从网络下载 。

1. 确保你本地已打包好字体：`tar -czf winFonts.tar.gz -C ./winFont .`
2. 执行以下命令将其手动导入 Nix Store ：


```bash
nix-prefetch-url --name winFonts.tar.gz file:///path/to/your/winFonts.tar.gz

```


*注意：导入后的哈希值必须与配置文件中 `myWinFonts` 定义的 `sha256` 保持一致。*

### B. VSCode 插件认证问题

由于 VSCode 部分扩展在 Nix 构建环境（非登录状态）下下载可能会遇到认证或网络握手问题：

* 
**建议**：如果构建时 VSCode 相关的 derivation 报错，请先在 `systemPackages` 中临时注释掉 `vscode` 。


* **解决**：待系统成功进入桌面环境并登录网络后，取消注释再次构建。

---

## 4. 执行系统构建

一切就绪后，在配置目录执行：

```bash
sudo nixos-rebuild switch --flake .#x12w-nix

```
