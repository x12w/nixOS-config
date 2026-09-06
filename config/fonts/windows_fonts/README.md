# Windows 字体目录（用户自备）

系统通过 fontconfig 在运行时扫描本目录，把用到的 `.ttf` / `.ttc` 字体文件丢进来即可。

## 用法

1. 把想用的字体文件（`.ttf` / `.ttc`）直接拷贝到这个目录
2. 完成。应用重启（或跑一次 `rebuild` 刷新 fontconfig 配置）即可生效

无需任何额外操作：不需要 `--impure`、不需要 git 操作、不需要改锁文件。

## 说明

- 目录为空（只含本 README）时构建不受影响 —— 从 GitHub 纯 clone 也能正常构建
- 字体文件被 git 忽略（见本目录 `.gitignore`），**不会**提交进仓库，仓库不捆绑任何字体
- 之前由 `corefonts`/`vista-fonts` 提供的部分家族（Courier New、Andale Mono、Constantia）已不再内置，需要的话拷贝对应文件到本目录即可
- 实现方式：`config/fonts/default.nix` 里的 `fonts.fontconfig.localConf` 添加了本目录的运行时扫描（纯求值，构建期不打包字体）
