@echo off
rem ============================================================
rem  GunGame build script (SourceMod 1.12)
rem  Compiles all plugins from this directory into ..\plugins\
rem ============================================================

set SPCOMP=D:\sourcemod-1.12.0-git7246-windows\addons\sourcemod\scripting\spcomp.exe
set DIR_SCRIPTING=%~dp0
set DIR_PLUGINS=%DIR_SCRIPTING%..\plugins
set LOG_COMPILE=%DIR_SCRIPTING%\compile_gungame.log

cd /d %DIR_SCRIPTING%

echo %DATE% %TIME% > "%LOG_COMPILE%"

for %%P in (
    gungame_afk.sp
    gungame_bot.sp
    gungame_config.sp
    gungame_display_winner.sp
    gungame_logging.sp
    gungame_mapvoting.sp
    gungame_stats.sp
    gungame_tk.sp
    gungame_warmup_configs.sp
    gungame_winner_effects.sp
) do (
    echo [compile] %%P
    "%SPCOMP%" "%%P" -i"%DIR_SCRIPTING%include" -o"%DIR_PLUGINS%\%%~nP.smx" >> "%LOG_COMPILE%" 2>&1 || goto :fail
)

echo [compile] gungame.sp
"%SPCOMP%" "gungame.sp" -i"%DIR_SCRIPTING%include" -o"%DIR_PLUGINS%\gungame.smx" >> "%LOG_COMPILE%" 2>&1 || goto :fail

echo [compile] gungame.sp WITH_SDKHOOKS=1
"%SPCOMP%" "gungame.sp" -i"%DIR_SCRIPTING%include" -o"%DIR_PLUGINS%\gungame_sdkhooks.smx" WITH_SDKHOOKS=1 >> "%LOG_COMPILE%" 2>&1 || goto :fail

echo.
echo Done. Output in %DIR_PLUGINS%
exit /b 0

:fail
echo.
echo COMPILE FAILED - see %LOG_COMPILE%
exit /b 1
