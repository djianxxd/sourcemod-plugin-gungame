#pragma semicolon 1

#include <sourcemod>
#include <gungame_const>
#include <gungame>
#include <gungame_config>

#pragma newdecls required

public Plugin myinfo = {
    name = "GunGame:SM Warmup Configs Execution",
    author = GUNGAME_AUTHOR,
    description = "Execute warmup configs on warmup start and end",
    version = GUNGAME_VERSION,
    url = GUNGAME_URL
};

public void GG_OnWarmupEnd() {
    char ConfigGameDirName[PLATFORM_MAX_PATH];
    GG_ConfigGetDir(ConfigGameDirName, sizeof(ConfigGameDirName));
    InsertServerCommand("exec \\%s\\gungame.warmupend.cfg", ConfigGameDirName);
}

public void GG_OnWarmupStart() {
    char ConfigGameDirName[PLATFORM_MAX_PATH];
    GG_ConfigGetDir(ConfigGameDirName, sizeof(ConfigGameDirName));
    InsertServerCommand("exec \\%s\\gungame.warmupstart.cfg", ConfigGameDirName);
}
