{ pkgs, ... }:

let
  # 手动下载 zjstatus 插件
  zjstatus = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm";
    # 这是 2026 年 3 月版本的哈希值。如果下载失败，请根据报错提示更新哈希
    sha256 = "sha256-TeQm0gscv4YScuknrutbSdksF/Diu50XP4W/fwFU3VM=";
  };
in

{
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
        pane
        // 这里的 size=1 且无边框的面板就是我们的“高级状态栏”
        pane size=1 borderless=true {
            plugin location="file:${zjstatus}" {
                _allow_run_commands true

                // --- 配色方案 (Catppuccin Mocha) ---
                color_fg "#cdd6f4"
                color_bg "#1e1e2e"
                color_black "#181825"
                color_red "#f38ba8"
                color_green "#a6e3a1"
                color_yellow "#f9e2af"
                color_blue "#89b4fa"
                color_magenta "#cba6f7"
                color_cyan "#89dceb"
                color_white "#f5e0dc"
                color_orange "#fab387"

                // --- 布局结构 ---
                format_left  "#[fg=$blue,bold] 󰠚 {session} {mode}#[fg=$fg,bg=$bg] {tabs}"
                format_center ""
                format_right "#[fg=$green,bold] {cwd} #[fg=$cyan,bold]󱑎 {datetime}"
                format_space  "#[bg=$bg]"

                // --- 标签页样式 ---
                tab_normal   "#[fg=$white,bg=$black] {index} {name} "
                tab_active   "#[fg=$black,bg=$magenta,bold,italic] {index} {name} "

                // --- 时间格式 ---
                datetime        "#[fg=$fg,bg=$bg,bold] {format}"
                datetime_format "%H:%M:%S"
                datetime_timezone "Asia/Shanghai"

                // --- 模式显示（把英文缩短，更有设计感） ---
                mode_normal        "#[fg=$green,bold] NORMAL "
                mode_locked        "#[fg=$red,bold] LOCKED "
                mode_pane          "#[fg=$magenta,bold] PANE "
                mode_tab           "#[fg=$yellow,bold] TAB "
                mode_scroll        "#[fg=$orange,bold] SCROLL "
                mode_enter_search  "#[fg=$orange,bold] ENT-SEARCH "
                mode_search        "#[fg=$orange,bold] SEARCH "
                mode_resize        "#[fg=$blue,bold] RESIZE "

                // --- git 信息 ---
                command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                command_git_branch_format      "#[fg=$magenta,bold]󰊢 {stdout} "
                command_git_branch_interval    "10"
                command_git_branch_rendermode  "static"

                // 然后修改 format_right，把 git 分支加进去
                format_right "#[fg=$magenta]{command_git_branch}#[fg=$green,bold] {cwd} #[fg=$cyan,bold]󱑎 {datetime}"
            }
        }
    }
  '';
}
