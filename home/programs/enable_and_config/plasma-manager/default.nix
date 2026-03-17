{ pkgs, ... }:
{
  programs.plasma = {
    enable = true;
    overrideConfig = true;

    # --- 1. 桌面外观 (Workspace) ---
    # 对应文档中的 programs.plasma.workspace.*
    workspace = {
      clickItemTo = "select";
      lookAndFeel = "com.github.vinceliuice.Layan";

      # 修正：cursor 选项在官方文档中是嵌套结构
      cursor = {
        theme = "Bibata-Modern-Ice";
        size = 24;
      };

      # 修正：幻灯片壁纸配置
      wallpaperSlideShow = {
        path = "/home/x12w/图片/壁纸/";
        interval = 300;
      };
    };

    # --- 2. 窗口管理与虚拟桌面 (KWin) ---
    kwin = {
      # 16 个虚拟桌面，4 行布局
      virtualDesktops = {
        number = 16;
        rows = 4;
      };
      # 对应 kwinrc.Plugins.wobblywindowsEnabled
      effects.wobblyWindows.enable = true;
    };

    # --- 3. 完整快捷键映射 (Shortcuts) ---
    # 严格匹配你文件中定义的键值对
    shortcuts = {
      "kwin" = {
        # 窗口基础操作
        "Window Close" = "Alt+F4";
        "Window Maximize" = "Meta+PgUp";
        "Window Minimize" = "Meta+PgDown";
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Show Desktop" = "Meta+D";
        "Kill Window" = "Meta+Ctrl+Esc";
        "Edit Tiles" = "Meta+T";

        # Polonium 磁贴插件快捷键
        "PoloniumFocusAbove" = "Meta+K";
        "PoloniumFocusBelow" = "Meta+J";
        "PoloniumFocusLeft" = "Meta+H";
        "PoloniumFocusRight" = "Meta+L";
        "PoloniumResizeAbove" = "Meta+Ctrl+K";
        "PoloniumResizeBelow" = "Meta+Ctrl+J";
        "PoloniumResizeLeft" = "Meta+Ctrl+H";
        "PoloniumResizeRight" = "Meta+Ctrl+L";
        "PoloniumRetileWindow" = "Meta+Shift+Space";
        "PoloniumCycleEngine" = "Meta+|";

        # 虚拟桌面切换与窗口移动
        "Switch to Next Desktop" = "Ctrl+K";
        "Switch to Previous Desktop" = "Ctrl+J";
        "Switch to Desktop 1" = "Ctrl+F1";
        "Switch to Desktop 2" = "Ctrl+F2";
        "Switch to Desktop 3" = "Ctrl+F3";
        "Window to Desktop 1" = "Meta+!";
        "Window to Desktop 2" = "Meta+@";
        "Window to Desktop 3" = "Meta+#";
        "Window to Desktop 4" = "Meta+$";
        "Window to Next Desktop" = "Ctrl+Shift+L";
        "Window to Previous Desktop" = "Ctrl+Shift+H";
        "Window to Next Screen" = "Meta+Shift+Right";
        "Window to Previous Screen" = "Meta+Shift+Left";

        # 缩放
        "view_actual_size" = "Meta+0";
        "view_zoom_in" = [
          "Meta++"
          "Meta+="
        ];
        "view_zoom_out" = "Meta+-";
      };

      "plasmashell" = {
        # 任务栏
        "activate task manager entry 1" = "Meta+1";
        "activate task manager entry 2" = "Meta+2";
        "activate task manager entry 3" = "Meta+3";
        "activate task manager entry 4" = "Meta+4";
        "activate task manager entry 5" = "Meta+5";
        "manage activities" = "Meta+Q";
        "show-on-mouse-pos" = "Meta+V";
        "activate application launcher" = [
          "Meta"
          "Alt+F1"
        ];
      };

      "ksmserver" = {
        "Lock Session" = [
          "Meta+L"
          "Screensaver"
        ];
        "Log Out" = "Ctrl+Alt+Del";
      };

      "kmix" = {
        "mute" = "Volume Mute";
        "decrease_volume" = "Volume Down";
        "increase_volume" = "Volume Up";
        "mic_mute" = [
          "Microphone Mute"
          "Meta+Volume Mute"
        ];
      };

      "services/kitty.desktop"."_launch" = "Ctrl+Alt+T";
    };

    # --- 4. 底层配置 (configFile) ---
    # 用于处理官方未直接提供高级选项的设置
    configFile = {
      "ksplashrc"."KSplash"."Theme" = "Catppuccin-Frappe-Blue";

      # 启用 Polonium 并设置内边距
      "kwinrc"."Plugins"."poloniumEnabled" = true;
      "kwinrc"."Tiling"."padding" = 4;

      # 输入法 Wayland 支持
      "kwinrc"."Wayland"."VirtualKeyboardEnabled" = true;
      # "kwinrc"."Wayland"."InputMethod[$e]" = "/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop";
      "kwinrc"."Wayland"."VirtualKeyboard" = "org.fcitx.Fcitx5";

      # 键盘布局
      "kxkbrc"."Layout"."LayoutList" = "us";
      "kxkbrc"."Layout"."Use" = true;

      # 锁屏幻灯片同步
      "kscreenlockerrc"."Greeter"."WallpaperPlugin" = "org.kde.slideshow";
      "kscreenlockerrc"."Greeter/Wallpaper/org.kde.slideshow/General"."SlidePaths" = "/home/x12w/图片/壁纸/";
    };

    panels = [
      {
        location = "top";
        height = 36;
        widgets = [
          # 必须在这里显式列出所有你需要的部件，否则它们会被删除
          "org.kde.plasma.kickoff"
          "org.kde.plasma.icontasks" # 任务栏
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray" # 系统托盘（包含输入法图标）
          "org.kde.plasma.digitalclock" # 数字时钟
        ];
      }
    ];
  };
}
