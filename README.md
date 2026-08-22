sourcemod-plugin-gungame
========================

GunGame plugin for sourcemod.

Based on the classic GunGame plugin by teame06, updated to SourcePawn
transitional syntax (newdecls) and verified against SourceMod 1.12
(spcomp 1.12.0.7246).

For more details see http://forums.alliedmods.net/showthread.php?t=93977
and the /doc folder of the project.

## Plugins

| Plugin | Description |
|--------|-------------|
| gungame.sp | Core plugin |
| gungame_afk.sp | AFK management |
| gungame_bot.sp | Bot management |
| gungame_config.sp | Config file parser |
| gungame_display_winner.sp | Winner display |
| gungame_logging.sp | Logging |
| gungame_mapvoting.sp | Map voting on match end |
| gungame_stats.sp | Player win statistics + top10 menu (SQLite/MySQL/PgSQL) |
| gungame_tk.sp | Team kill handling |
| gungame_warmup_configs.sp | Warmup config execution |
| gungame_winner_effects.sp | Winner effects |

## Building

Requires [spcomp](https://www.sourcemod.net/downloads.php) from SourceMod 1.11+.
The custom includes live in `scripting/include` (colors, gungame API,
langutils, url).

One-shot build (Windows):

    scripting\compile_gungame.cmd

Manual build:

    spcomp gungame.sp -iscripting\include -o../plugins/gungame.smx

The core plugin can also be built with SDKHooks support:

    spcomp gungame.sp -iscripting\include -o../plugins/gungame_sdkhooks.smx WITH_SDKHOOKS=1

## Notes on this fork

* All plugins converted to transitional syntax (`#pragma newdecls required`
  in implementation files; public interface includes stay old-syntax so
  third-party sub-plugins keep compiling).
* Auth ids are normalized from `STEAM_1:` to `STEAM_0:` for database keys
  and stats lookups.
* Prebuilt `.smx` files are included under `addons/sourcemod/plugins`;
  `gungame_sdkhooks.smx` is the SDKHooks-enabled core variant.
