sourcemod-plugin-gungame
========================

SourceMod 版 GunGame（枪械晋级 / 死斗升级）插件。

基于 teame06 的经典 GunGame 插件，已全面迁移至 SourcePawn 过渡语法
（newdecls），并针对 SourceMod 1.12（spcomp 1.12.0.7246）完成适配与编译验证。

更多细节参见 http://forums.alliedmods.net/showthread.php?t=93977
以及项目 /doc 目录。

## 插件列表

| 插件 | 说明 |
|------|------|
| gungame.sp | 核心插件 |
| gungame_afk.sp | 挂机（AFK）管理 |
| gungame_bot.sp | 机器人管理 |
| gungame_config.sp | 配置文件解析 |
| gungame_display_winner.sp | 获胜者展示 |
| gungame_logging.sp | 日志记录 |
| gungame_mapvoting.sp | 比赛结束后的地图投票 |
| gungame_stats.sp | 玩家获胜数据统计 + Top10 排行菜单（SQLite/MySQL/PgSQL） |
| gungame_tk.sp | 队友伤害（TK）处理 |
| gungame_warmup_configs.sp | 热身阶段配置执行 |
| gungame_winner_effects.sp | 获胜者特效 |

## 编译构建

需要 SourceMod 1.11+ 自带的 [spcomp](https://www.sourcemod.net/downloads.php) 编译器。
项目自定义 include 位于 `scripting/include`（colors、gungame API、langutils、url）。

Windows 一键编译：

    scripting\compile_gungame.cmd

手动编译：

    spcomp gungame.sp -iscripting\include -o../plugins/gungame.smx

核心插件还可启用 SDKHooks 支持编译：

    spcomp gungame.sp -iscripting\include -o../plugins/gungame_sdkhooks.smx WITH_SDKHOOKS=1

## 本分支改动说明

* 全部 11 个插件已转换为过渡语法：实现文件使用
  `#pragma newdecls required`；公开接口 include 保持旧语法，
  以便第三方子插件继续正常编译。
* 数据库键与统计查询中的 SteamID 统一由 `STEAM_1:` 规范化为 `STEAM_0:`。
* `addons/sourcemod/plugins` 内含预编译 `.smx`；
  `gungame_sdkhooks.smx` 为启用 SDKHooks 的核心插件变体。

## 部署注意

`plugins` 目录中**只能保留一个核心插件**：`gungame.smx` 或
`gungame_sdkhooks.smx`，二者同时存在会触发防冲突检查，
两个插件都将拒绝加载（AskPluginLoad2 检测）。未选用的变体请放入
`plugins/disabled/` 或删除。
