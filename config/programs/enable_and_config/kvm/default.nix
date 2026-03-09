{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    # 启用 UEFI 支持 (用于运行 Windows 11 或现代 Linux)
    qemu = {
      package = pkgs.qemu_kvm;
      # NVIDIA 显卡硬件加速
      swtpm.enable = true; # 模拟 TPM，Windows 11 必需
    };
  };
}
