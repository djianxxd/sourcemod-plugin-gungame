#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colors>
#include <gungame_const>
#include <gungame>
#include <gungame_config>
#include <langutils>

#if defined WITH_SDKHOOKS
#include <sdkhooks>
#endif

#undef REQUIRE_PLUGIN
#include <gungame_stats>

#pragma newdecls required

#include "gungame/gungame.h"
#include "gungame/menu.h"
#include "gungame/config.h"
#include "gungame/keyvalue.h"
#include "gungame/event.h"
#include "gungame/offset.h"
#include "gungame/util.h"

#if defined GUNGAME_DEBUG
#include "gungame/debug.h"
#include "gungame/debug.sp"
#endif

#include "gungame/stock.sp"
#include "gungame/util.sp"
#include "gungame/natives.sp"
#include "gungame/offset.sp"
#include "gungame/config.sp"
#include "gungame/keyvalue.sp"
#include "gungame/event.sp"
#include "gungame/menu.sp"
#include "gungame/commands.sp"

public Plugin myinfo = {
    #if defined WITH_SDKHOOKS
    name = "GunGame:SM (with SDK Hooks support)",
    #else
    name = "GunGame:SM",
    #endif
    author = GUNGAME_AUTHOR,
    description = "GunGame:SM for SourceMod",
    version = GUNGAME_VERSION,
    url = GUNGAME_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    char file[PLATFORM_MAX_PATH];
    int filesCount = 0;

    BuildPath(Path_SM, file, sizeof(file), "plugins/gungame.smx");
    if (FileExists(file)) {
        filesCount++;
    }
    BuildPath(Path_SM, file, sizeof(file), "plugins/gungame_sdkhooks.smx");
    if (FileExists(file)) {
        filesCount++;
    }

    if (filesCount > 1) {
        SetFailState("ERROR: Check that you DONT have both gungame.smx and gungame_sdkhooks.smx in the plugins folder.");
        return APLRes_Failure;
    }

    /*
    MarkNativeAsOptional("SDKHook");
    MarkNativeAsOptional("SDKUnhook");
    */
    RegPluginLibrary("gungame");
    OnCreateNatives();
    return APLRes_Success;
}

public void OnLibraryAdded(const char[] name) {
    if ( StrEqual(name, "gungame_st") ) {
        StatsEnabled = true;
    }
    /*
    if (strcmp(name, "sdkhooks.ext") == 0) {
        g_SdkHooksEnabled = true;
    }
    */
}

public void OnLibraryRemoved(const char[] name) {
    if ( StrEqual(name, "gungame_st") ) {
        StatsEnabled = false;
    }
    /*
    if (strcmp(name, "sdkhooks.ext") == 0) {
        g_SdkHooksEnabled = false;
    }
    */
}

public void OnAllPluginsLoaded() {
    StatsEnabled = LibraryExists("gungame_st");
    /*
    g_SdkHooksEnabled = (GetExtensionFileStatus("sdkhooks.ext") == 1);
    */
}

/*
public Action Timer_CheckSdkHooks(Handle timer) {
    g_SdkHooksEnabled = (GetExtensionFileStatus("sdkhooks.ext") == 1);
}
*/

public void OnPluginStart() {
    g_GameName = DetectGame();
    if (g_GameName == None) {
        SetFailState("ERROR: Unsupported game. Please contact the author.");
    }

    StatsEnabled = LibraryExists("gungame_st");
    /*
    g_SdkHooksEnabled = (GetExtensionFileStatus("sdkhooks.ext") == 1);
    if ( !g_SdkHooksEnabled ) {
        InsertServerCommand("sm exts load sdkhooks");
        CreateTimer(0.1, Timer_CheckSdkHooks);
    }
    */

    LoadTranslations("gungame");
    PlayerLevelsBeforeDisconnect = new StringMap();
    PlayerHandicapTimes = new StringMap();

    // ConVar
    mp_friendlyfire = FindConVar("mp_friendlyfire");
    mp_restartgame = FindConVar("mp_restartgame");

    ConVar Version = CreateConVar("sm_gungamesm_version", GUNGAME_VERSION,    "GunGame Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    /* Just to make sure they it updates the convar version if they just had the plugin reload on map change */
    Version.SetString(GUNGAME_VERSION);

    gungame_enabled = CreateConVar("gungame_enabled", "1", "Display if GunGame is enabled or disabled", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    /* Dynamic Forwards */
    FwdDeath = CreateGlobalForward("GG_OnClientDeath", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    FwdLevelChange = CreateGlobalForward("GG_OnClientLevelChange", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    FwdPoint = CreateGlobalForward("GG_OnClientPointChange", ET_Hook, Param_Cell, Param_Cell, Param_Cell);
    FwdLeader = CreateGlobalForward("GG_OnLeaderChange", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    FwdWinner = CreateGlobalForward("GG_OnWinner", ET_Ignore, Param_Cell, Param_String, Param_Cell);
    FwdSoundWinner = CreateGlobalForward("GG_OnSoundWinner", ET_Hook, Param_Cell);
    FwdTripleLevel = CreateGlobalForward("GG_OnTripleLevel", ET_Ignore, Param_Cell);
    FwdWarmupEnd = CreateGlobalForward("GG_OnWarmupEnd", ET_Ignore);
    FwdWarmupStart = CreateGlobalForward("GG_OnWarmupStart", ET_Ignore);

    FwdVoteStart = CreateGlobalForward("GG_OnStartMapVote", ET_Ignore);
    FwdDisableRtv = CreateGlobalForward("GG_OnDisableRtv", ET_Ignore);

    FwdStart = CreateGlobalForward("GG_OnStartup", ET_Ignore, Param_Cell);
    FwdShutdown = CreateGlobalForward("GG_OnShutdown", ET_Ignore, Param_Cell);

    OnKeyValueStart();
    OnOffsetStart();
    OnCreateCommand();

    #if defined GUNGAME_DEBUG
    OnCreateDebug();
    #endif

    g_Cvar_Turbo = CreateConVar("sm_gg_turbo", "0", "Turbo mode");
    g_Cvar_MultiLevelAmount = CreateConVar("sm_gg_multilevelamount", "3", "Multi level amount");

    g_Cvar_Turbo.AddChangeHook(ConVarChanged_Turbo);
    g_Cvar_MultiLevelAmount.AddChangeHook(ConVarChanged_MultiLevelAmount);
}

public void OnClientPutInServer(int client) {
    if ( IsFakeClient(client) ) {
        g_SkipSpawn[client] = true;
    } else {
        g_SkipSpawn[client] = false;
    }

    if ( g_SdkHooksEnabled && ( g_Cfg_BlockWeaponSwitchIfKnife || g_Cfg_BlockWeaponSwitchOnNade ) ) {
        g_BlockSwitch[client] = false;
        #if defined WITH_SDKHOOKS
        SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
        #endif
    }
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if ( RestoreLevelOnReconnect )
    {
        int level = 0;

        /* Normalize incoming auth to legacy STEAM_0 form used as keys */
        char steamid[64];
        strcopy(steamid, sizeof(steamid), auth);
        if ( strncmp(steamid, "STEAM_1:", 8) == 0 ) {
            steamid[6] = '0';
        }

        if ( PlayerLevelsBeforeDisconnect.GetValue(steamid, level) )
        {
            if ( PlayerLevel[client] < level )
            {
                PlayerLevel[client] = level;
                UTIL_RecalculateLeader(client, 0, level);
            }
        }
    }

    UTIL_UpdatePlayerScoreLevel(client);
}

public void OnPluginEnd()
{
    gungame_enabled.IntValue = 0;
}

public void OnMapEnd()
{
    /* Kill timer on map change if was in warmup round. */
    if ( WarmupTimer != null )
    {
        KillTimer(WarmupTimer);
        WarmupTimer = null;
    }

    /* Clear out data */
    WarmupInitialized = false;
    WarmupCounter = 0;
    MapStatus = 0;
    HostageEntInfo = 0;
    IsVotingCalled = false;
    g_isCalledEnableFriendlyFire = false;
    g_isCalledDisableRtv = false;
    GameWinner = 0;
    CurrentLeader = 0;
    PlayerLevelsBeforeDisconnect.Clear();
    PlayerHandicapTimes.Clear();

    for ( Sounds i = Welcome; i < MaxSounds; i++ )
    {
        EventSounds[i][0] = '\0';
    }

    if ( IsObjectiveHooked )
    {
        if ( MapStatus & OBJECTIVE_BOMB )
        {
            IsObjectiveHooked = false;
            UnhookEvent("bomb_planted", _BombState);
            UnhookEvent("bomb_exploded", _BombState);
            UnhookEvent("bomb_defused", _BombState);
            UnhookEvent("bomb_pickup", _BombPickup);
        }

        if ( MapStatus & OBJECTIVE_HOSTAGE )
        {
            IsObjectiveHooked = false;
            UnhookEvent("hostage_killed", _HostageKilled);
        }
    }
}

public void OnClientDisconnect(int client)
{
    if ( g_SdkHooksEnabled && g_Cfg_BlockWeaponSwitchIfKnife ) {
        #if defined WITH_SDKHOOKS
        SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
        #endif
    }

    /* Clear current leader if player is leader */
    if ( CurrentLeader == client )
    {
        UTIL_RecalculateLeader(client, PlayerLevel[client], 0);
        if ( CurrentLeader == client )
        {
            CurrentLeader = 0;
        }
    }

    if ( AutoFriendlyFire && (PlayerState[client] & GRENADE_LEVEL) )
    {
        PlayerState[client] &= ~GRENADE_LEVEL;

        if ( --PlayerOnGrenade < 1 )
        {
            if ( g_cfgFriendlyFireOnOff ) {
                UTIL_ChangeFriendlyFire(false);
            } else {
                UTIL_ChangeFriendlyFire(true);
            }
        }
    }

    if ( !IsFakeClient(client) )
    {
        char steamid[64];
        GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

        /* Normalize STEAM_1:... back to legacy STEAM_0:... used as keys */
        if ( strncmp(steamid, "STEAM_1:", 8) == 0 ) {
            steamid[6] = '0';
        }

        PlayerLevelsBeforeDisconnect.SetValue(steamid, PlayerLevel[client]);
    }

    PlayerLevel[client] = 0;
    CurrentKillsPerWeap[client] = 0;
    CurrentLevelPerRound[client] = 0;
    CurrentLevelPerRoundTriple[client] = 0;
    PlayerState[client] = 0;

    if ( IsClientInGame(client) && IsPlayerAlive(client) )
    {
        UTIL_StopTripleEffects(client);
    }
}

public void GG_OnStartup(bool Command)
{
    if ( !IsActive )
    {
        IsActive = true;

        OnEventStart();
    }

    if ( !IsActive )
    {
        return;
    }

    UTIL_DisableBuyZones();

    if ( !WarmupInitialized && WarmupEnabled )
    {
        StartWarmupRound();
    }

    UTIL_FindMapObjective();

    if ( !IsObjectiveHooked )
    {
        if ( MapStatus & OBJECTIVE_BOMB )
        {
            IsObjectiveHooked = true;
            HookEvent("bomb_planted", _BombState);
            HookEvent("bomb_exploded", _BombState);
            HookEvent("bomb_defused", _BombState);
            HookEvent("bomb_pickup", _BombPickup);
        }

        if ( MapStatus & OBJECTIVE_HOSTAGE )
        {
            IsObjectiveHooked = true;
            HookEvent("hostage_killed", _HostageKilled);
        }
    }

    char Hi[PLATFORM_MAX_PATH];
    for (Sounds i = Welcome; i < MaxSounds; i++) {
        if (EventSounds[i][0]) {
            Format(Hi, sizeof(Hi), "sound/%s", EventSounds[i]);
            AddFileToDownloadsTable(Hi);
            PrecacheSoundFixed(i);
        }
    }

    Tcount = 0;
    CTcount = 0;
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientInGame(i) )
        {
            switch ( GetClientTeam(i) ) {
                case TEAM_T: {
                    Tcount++;
                }
                case TEAM_CT: {
                    CTcount++;
                }
            }
        }
    }

    if ( g_Cfg_HandicapUpdate )
    {
        StartHandicapUpdate();
    }
    else
    {
        StopHandicapUpdate();
    }
}

public void GG_OnShutdown(bool Command)
{
    if ( !IsActive )
    {
        return;
    }

    UTIL_EnableBuyZones();

    IsActive = false;
    InternalIsActive = false;
    WarmupInitialized = false;
    WarmupCounter = 0;
    IsVotingCalled = false;
    g_isCalledEnableFriendlyFire = false;
    g_isCalledDisableRtv = false;
    GameWinner = 0;
    CurrentLeader = 0;
    PlayerLevelsBeforeDisconnect.Clear();
    PlayerHandicapTimes.Clear();

    OnEventShutdown();

    if ( Command )
    {
        for ( int i = 1; i <= MaxClients; i++ )
        {
            if ( IsClientInGame(i) )
            {
                OnClientDisconnect(i);
            }
        }

        if ( WarmupTimer != null )
        {
            KillTimer(WarmupTimer);
            WarmupTimer = null;
        }
    }

    if ( IsObjectiveHooked )
    {
        if ( MapStatus & OBJECTIVE_BOMB )
        {
            IsObjectiveHooked = false;
            UnhookEvent("bomb_planted", _BombState);
            UnhookEvent("bomb_exploded", _BombState);
            UnhookEvent("bomb_defused", _BombState);
            UnhookEvent("bomb_pickup", _BombPickup);
        }

        if ( MapStatus & OBJECTIVE_HOSTAGE )
        {
            IsObjectiveHooked = false;
            UnhookEvent("hostage_killed", _HostageKilled);
        }
    }
}

/**
 * Print messages to chat about leaders.
 *
 * @param int client
 * @param int oldLevel
 * @param int newLevel
 * @param String name
 * @return void
 */
void PrintLeaderToChat(int client, int oldLevel, int newLevel, const char[] name)
{
    if ( !CurrentLeader || newLevel <= oldLevel )
    {
        return;
    }
    // newLevel > oldLevel
    if ( CurrentLeader == client )
    {
        // say leading on level X
        if ( g_Cfg_ShowLeaderWeapon ) {
            CPrintToChatAllEx(client, "%t", "Is leading on level weapon", name, newLevel + 1, WeaponOrderName[newLevel]);
        } else {
            CPrintToChatAllEx(client, "%t", "Is leading on level", name, newLevel + 1);
        }
        return;
    }
    // CurrentLeader != client
    if ( newLevel < PlayerLevel[CurrentLeader] )
    {
        // say how much to the lead
        char subtext[64];
        FormatLanguageNumberTextEx(client, subtext, sizeof(subtext), PlayerLevel[CurrentLeader]-newLevel, "levels");
        CPrintToChat(client, "%t", "You are levels behind leader", subtext);
        return;
    }
    // new level == leader level
    // say tied to the lead on level X
    CPrintToChatAllEx(client, "%t", "Is tied with the leader on level", name, newLevel + 1);
}

void StartWarmupRound()
{
    WarmupInitialized = true;
    PrintToServer("[GunGame] Warmup round has started.");
    char subtext[64];
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientInGame(i) )
        {
            SetGlobalTransTarget(i);
            FormatLanguageNumberTextEx(i, subtext, sizeof(subtext), Warmup_TimeLength - WarmupCounter, "seconds left");
            PrintHintText(i, "%t", "Warmup round seconds left", subtext);
        }
    }

    /* Start Warmup round */
    WarmupTimer = CreateTimer(1.0, EndOfWarmup, _, TIMER_REPEAT);

    Call_StartForward(FwdWarmupStart);
    Call_Finish();
}

/* End of Warmup */
public Action EndOfWarmup(Handle timer)
{
    if ( ++WarmupCounter <= Warmup_TimeLength )
    {
        if ( Warmup_TimeLength - WarmupCounter < 5)
        {
            UTIL_PlaySound(0, WarmupTimerSound);
        }
        char subtext[64];
        for ( int i = 1; i <= MaxClients; i++ )
        {
            if ( IsClientInGame(i) )
            {
                SetGlobalTransTarget(i);
                FormatLanguageNumberTextEx(i, subtext, sizeof(subtext), Warmup_TimeLength - WarmupCounter, "seconds left");
                PrintHintText(i, "%t", "Warmup round seconds left", subtext);
            }
        }
        return Plugin_Continue;
    }

    WarmupTimer = null;
    //WarmupEnabled = false; // Delayed warmup ending
    DisableWarmupOnRoundEnd = true;

    /* Restart Game */
    mp_restartgame.IntValue = 1;

    CPrintToChatAll("%t", "Warmup round has ended");

    for ( int i = 1; i <= MaxClients; i++ )
    {
        PlayerLevel[i] = 0;
        UTIL_UpdatePlayerScoreLevel(i);
    }

    Call_StartForward(FwdWarmupEnd);
    Call_Finish();

    return Plugin_Stop;
}

void StartHandicapUpdate()
{
    if ( g_Timer_HandicapUpdate != null )
    {
        return;
    }
    g_Timer_HandicapUpdate = CreateTimer(g_Cfg_HandicapUpdate, Timer_HandicapUpdate, _, TIMER_REPEAT);
}

void StopHandicapUpdate()
{
    if ( g_Timer_HandicapUpdate == null )
    {
        return;
    }
    KillTimer(g_Timer_HandicapUpdate);
    g_Timer_HandicapUpdate = null;
}

public Action Timer_HandicapUpdate(Handle timer)
{
    if ( WarmupEnabled || !HandicapMode )
    {
        return Plugin_Continue;
    }

    // get very minimum level
    int minimum = UTIL_GetMinimumLevel(g_Cfg_HandicapSkipBots);
    if ( minimum == -1 ) {
        return Plugin_Continue;
    }
    // get handicap level for players above very minimum level
    int level = UTIL_GetHandicapLevel(0, minimum);
    if ( level <= minimum ) {
        return Plugin_Continue;
    }

    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientInGame(i) && (PlayerLevel[i] == minimum) )
        {
            if ( g_Cfg_HandicapSkipBots && IsFakeClient(i) ) {
                continue;
            }
            if ( !IsFakeClient(i)
                 && !TopRankHandicap
                 && StatsEnabled
                 && ( !GG_IsPlayerWinsLoaded(i) /* HINT: gungame_stats */
                    || GG_IsPlayerInTopRank(i) ) /* HINT: gungame_stats */
            )
            {
                continue;
            }
            PlayerLevel[i] = level;
            CurrentKillsPerWeap[i] = 0;
            CPrintToChat(i, "%t", "Your level has been updated by handicap");
            if ( TurboMode && IsPlayerAlive(i) )
            {
                UTIL_GiveNextWeapon(i, level);
            }
            UTIL_UpdatePlayerScoreLevel(i);
        }
    }

    return Plugin_Continue;
}

public void GG_OnLoadPlayerWins(int client)
{
    if ( !(PlayerState[client] & FIRST_JOIN) )
    {
        return;
    }
    if ( UTIL_SetHandicapForClient(client) && IsPlayerAlive(client) )
    {
        UTIL_GiveNextWeapon(client, PlayerLevel[client]);
    }
}


/**
 * TODO:
 * KillCam event message should probably should block in DeathMatch Style.
 * BarTime probably used to show how long left till respawn.
 */

public void OnMapStart() {
    PrecacheModel(MULTI_LEVEL_EFFECT2);
    PrecacheModel(MULTI_LEVEL_EFFECT1);
}
