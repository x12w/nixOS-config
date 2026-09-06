{ pkgs, ... }:

# Windows 字体（用户自备，不随仓库分发，纯求值方案）：
# build 期不打包字体，而是在运行时让 fontconfig 直接扫描本地目录。
# 把 .ttf/.ttc 拷进 /etc/nixos/config/fonts/windows_fonts/ 即可生效（应用重启即识别）。
# - 配置里只有字符串路径，不访问文件系统 —— 无需 --impure
# - 目录缺失/为空时 ignore_missing 静默跳过 —— 从 GitHub 纯 clone 也能正常构建
# - 添加字体无需任何 git/锁文件操作
{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif # 保证 serif 默认字体存在
      noto-fonts-color-emoji
      sarasa-gothic
      nerd-fonts.jetbrains-mono # 已含 JetBrains Mono 全部字重 + Nerd 图标
      # 不内置 corefonts/vista-fonts：家族与 windows_fonts 重复，且仓库不捆绑字体，
      # 缺失的家族（Courier New / Andale Mono / Constantia）拷贝到 windows_fonts/ 即可
    ];

    fontconfig.defaultFonts = {
      serif = [ "Noto Serif CJK SC" ];
      sansSerif = [ "Noto Sans CJK SC" ];
      monospace = [ "JetBrainsMono Nerd Font" "Sarasa Mono SC" "Noto Sans Mono CJK SC" ];
      emoji = [ "Noto Color Emoji" ];
    };

    # Windows 字体目录：运行时由 fontconfig 扫描（写入 /etc/fonts/local.conf）。
    # 注意：新版 fontconfig 对缺失目录本就静默忽略，勿加已废弃的 ignore_missing 属性（会报 warning）
    fontconfig.localConf = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <dir>/etc/nixos/config/fonts/windows_fonts</dir>
      </fontconfig>
    '';

    # 恢复旧 home-manager 配置中的 BGR 子像素渲染；
    # 如屏幕不适可改 "rgb" 或 "none"
    fontconfig.subpixel.rgba = "vbgr";

    fontDir.enable = true;

    fontconfig.enable = true;
  };
}
