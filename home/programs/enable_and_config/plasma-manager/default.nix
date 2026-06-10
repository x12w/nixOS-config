{ pkgs, ... }:
{
  programs.plasma = {
    enable = true;
    overrideConfig = false;

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
        path = "${../../../../pictures}";
        interval = 300;
      };
    };

    # --- 2. 窗口管理与虚拟桌面 (KWin) ---
    kwin = {
      virtualDesktops = {
        number = 16;
        rows = 4;
      };

      effects.wobblyWindows.enable = true;

      edgeBarrier = 0;
      cornerBarrier = false;

      tiling.padding = 4;

      scripts.polonium = {
        enable = false;

        settings = {
          borderVisibility = "noBorderTiled";
          callbackDelay = 100;
          enableDebug = false;

          filter = {
            processes = [
              "org.kde.krunner"
              "plasmashell"
            ];

            windowTitles = [
              "Picture-in-Picture"
            ];
          };

          layout = {
            engine = "binaryTree";
            insertionPoint = "activeWindow";
            rotate = false;
          };

          maximizeSingleWindow = true;
          resizeAmount = 100;
          saveOnTileEdit = true;
          tilePopups = false;
        };
      };
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

        # --- Karousel: focus ---
        "karousel-focus-left" = "Meta+H";
        "karousel-focus-right" = "Meta+L";
        "karousel-focus-up" = "Meta+K";
        "karousel-focus-down" = "Meta+J";
        "karousel-focus-start" = "Meta+Home";
        "karousel-focus-end" = "Meta+End";

        # --- Karousel: move window ---
        "karousel-window-move-left" = "Meta+Shift+H";
        "karousel-window-move-right" = "Meta+Shift+L";
        "karousel-window-move-up" = "Meta+Shift+K";
        "karousel-window-move-down" = "Meta+Shift+J";
        "karousel-window-move-start" = "Meta+Shift+Home";
        "karousel-window-move-end" = "Meta+Shift+End";

        # --- Karousel: move column ---
        "karousel-column-move-left" = "Meta+Ctrl+Shift+H";
        "karousel-column-move-right" = "Meta+Ctrl+Shift+L";
        "karousel-column-move-start" = "Meta+Ctrl+Shift+Home";
        "karousel-column-move-end" = "Meta+Ctrl+Shift+End";

        # --- Karousel: width / layout ---
        "karousel-column-width-increase" = "Meta+Ctrl+=";
        "karousel-column-width-decrease" = "Meta+Ctrl+-";
        "karousel-cycle-preset-widths" = "Meta+R";
        "karousel-cycle-preset-widths-reverse" = "Meta+Shift+R";
        "karousel-columns-width-equalize" = "Meta+Ctrl+X";
        "karousel-column-toggle-stacked" = "Meta+X";

        # --- Karousel: floating ---
        "karousel-window-toggle-floating" = "Meta+F";

        # --- Karousel: scroll ---
        "karousel-grid-scroll-focused" = "Meta+Alt+Return";
        "karousel-grid-scroll-left-column" = "Meta+Alt+H";
        "karousel-grid-scroll-right-column" = "Meta+Alt+L";
        "karousel-grid-scroll-left" = "Meta+Alt+PgUp";
        "karousel-grid-scroll-right" = "Meta+Alt+PgDown";
        "karousel-grid-scroll-start" = "Meta+Alt+Home";
        "karousel-grid-scroll-end" = "Meta+Alt+End";

        # --- Karousel: grid placement ---
        "karousel-screen-switch" = "Meta+Ctrl+Return";

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
          "Meta+Z"
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

      "services/com.mitchellh.ghostty.desktop"."_launch" = "Ctrl+Alt+T";
    };

    # --- 4. 底层配置 (configFile) ---
    # 用于处理官方未直接提供高级选项的设置
    configFile = {
      "ksplashrc"."KSplash"."Theme" = "Catppuccin-Frappe-Blue";

      "kwinrc"."Plugins"."karouselEnabled" = true;
      "kwinrc"."Plugins"."kwin4_effect_geometry_changeEnabled" = true;
      # 输入法 Wayland 支持
      "kwinrc"."Wayland"."VirtualKeyboardEnabled" = true;
      # "kwinrc"."Wayland"."InputMethod[$e]" = "/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop";
      "kwinrc"."Wayland"."VirtualKeyboard" = "org.fcitx.Fcitx5";

      # 键盘布局
      "kxkbrc"."Layout"."LayoutList" = "us";
      "kxkbrc"."Layout"."Use" = true;

      # 锁屏幻灯片同步
      "kscreenlockerrc"."Greeter"."WallpaperPlugin" = "org.kde.slideshow";
      "kscreenlockerrc"."Greeter/Wallpaper/org.kde.slideshow/General"."SlidePaths" = "${
        ../../../../pictures
      }";
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
