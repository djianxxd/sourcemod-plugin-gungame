#pragma semicolon 1

#include <sourcemod>
#include <gungame_const>
#include <gungame>
#include <gungame_stats>
#include <gungame_config>
#include <colors>
#include <langutils>

#include "gungame_stats/gungame_stats.h"
#include "gungame_stats/config.h"
#include "gungame_stats/menu.h"

#include "gungame_stats/sql.h"
#include "gungame_stats/sql.sp"

#include "gungame_stats/menu.sp"
#include "gungame_stats/config.sp"
#include "gungame_stats/natives.sp"

#pragma newdecls required

public Plugin myinfo =
{
    name = "GunGame:SM Stats",
    author = GUNGAME_AUTHOR,
    description = "Stats for GunGame:SM",
    version = GUNGAME_VERSION,
    url = GUNGAME_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("gungame_st");
    OnCreateNatives();
    return APLRes_Success;
}

public void OnPluginStart()
{
    FwdLoadRank = CreateGlobalForward("GG_OnLoadRank", ET_Ignore);
    FwdLoadPlayerWins = CreateGlobalForward("GG_OnLoadPlayerWins", ET_Ignore, Param_Cell);

    LoadTranslations("gungame_stats");
    OnCreateKeyValues();

    RegConsoleCmd("top10", _CmdTop);
    RegConsoleCmd("top", _CmdTop);
    RegConsoleCmd("rank", _CmdRank);
    RegAdminCmd("gg_rebuild", _CmdRebuild, GUNGAME_ADMINFLAG, "Rebuilds the top rank from the player data information");
    RegAdminCmd("gg_import", _CmdImport, GUNGAME_ADMINFLAG, "Imports the winners file from es gungame.");
    RegAdminCmd("gg_reset", _CmdReset, GUNGAME_ADMINFLAG, "Reset all gungame stats.");
    RegAdminCmd("gg_importdb", _CmdImportDb, GUNGAME_ADMINFLAG, "Imports the winners from gungame players data file into database.");
}

public void OnClientAuthorized(int client, const char[] auth)
{
    /* Normalize incoming auth to legacy STEAM_0 form used as database keys */
    char steamid[64];
    strcopy(steamid, sizeof(steamid), auth);
    if ( strncmp(steamid, "STEAM_1:", 8) == 0 ) {
        steamid[6] = '0';
    }

    RetrieveKeyValues(client, steamid);
}

public void OnMapStart()
{
    SaveProcess = false;
}

public void OnMapEnd()
{
    EndProcess();
}

public void OnPluginEnd()
{
    EndProcess();
}

public void GG_OnStartup(bool Command)
{
    if ( !IsActive )
    {
        IsActive = true;
        char Auth[64];
        for(int i = 1; i <= MaxClients; i++)
        {
            if ( IsClientAuthorized(i) )
            {
                GetClientAuthId(i, AuthId_Steam2, Auth, sizeof(Auth));
                OnClientAuthorized(i, Auth);
            }
        }
    }
}

public void GG_OnShutdown(bool Command)
{
    if(IsActive)
    {
        IsActive = false;

        EndProcess();

        for(int i = 1; i <= MaxClients; i++)
        {
            if ( IsClientInGame(i) )
            {
                OnClientDisconnect(i);
            }
        }
    }
}

public void OnClientDisconnect(int client)
{
    g_PlayerWinsLoaded[client] = false;
    PlayerWinsData[client] = 0;
    PlayerPlaceData[client] = 0;
}

public Action _CmdTop(int client, int args)
{
    if ( IsActive )
    {
        ShowTopMenu(client);
    }
    return Plugin_Handled;
}

public Action _CmdRank(int client, int args)
{
    if ( IsActive )
    {
        ShowRank(client);
    }
    return Plugin_Handled;
}

void EndProcess()
{
    if ( SaveProcess )
    {
        return;
    }

    SaveProcess = true;
    SavePlayerDataInfo();
}

public void GG_OnWinner(int client, const char[] Weapon, int victim) {
    if ( IsClientInGame(client) && !IsFakeClient(client) ) {
        if ( g_Cfg_DontAddWinsOnBot && victim && IsFakeClient(victim) ) {
            return;
        }

        ++PlayerWinsData[client];
        SavePlayerData(client);
    }
}
