{
  services.udev.extraRules = ''
    # 允许普通用户访问 HIDRAW 设备（用于 VIA 调词典/改键）
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666"
  '';
}
