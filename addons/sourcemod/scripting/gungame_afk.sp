#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <gungame_const>
#include <gungame>
#include <gungame_config>
#include <colors>

#pragma newdecls required

int OffsetOrigin;
bool AfkManagement;
int AfkDeaths;
int AfkAction;
int AfkReload;
bool IsActive;

float PlayerAfk[MAXPLAYERS + 1][3];
int PlayerAfkCount[MAXPLAYERS + 1];

State ConfigState;

public Plugin myinfo =
{
    name = "GunGame:SM Afk Management",
    author = GUNGAME_AUTHOR,
    description = "GunGame:SM Afk Management System",
    version = GUNGAME_VERSION,
    url = GUNGAME_URL
};

public void OnPluginStart()
{
    LoadTranslations("gungame_afk");

    OffsetOrigin = FindSendPropInfo("CBaseEntity", "m_vecOrigin");

    if(OffsetOrigin == INVALID_OFFSET)
    {
        char Error[128];
        FormatEx(Error, sizeof(Error), "FATAL ERROR OffsetOrigin [%d]", OffsetOrigin);
        SetFailState("%s", Error);
    }
}

public void GG_OnStartup(bool Command)
{
    if(!IsActive)
    {
        HookEvent("player_spawn", _PlayerSpawn);
        HookEvent("weapon_fire", _WeaponFire);
        IsActive = true;
    }
}

public void GG_OnShutdown(bool Command)
{
    if(IsActive)
    {
        UnhookEvent("player_spawn", _PlayerSpawn);
        UnhookEvent("weapon_fire", _WeaponFire);
        IsActive = false;
    }
}

public void _PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if(!IsActive || !AfkManagement)
    {
        return;
    }

    int client = GetClientOfUserId(event.GetInt("userid"));

    if(!client || IsFakeClient(client))
    {
        return;
    }

    /**
     * Stores where they are spawn so that they can check for afk on death.
     */
    GetEntDataVector(client, OffsetOrigin, PlayerAfk[client]);
}

public void _WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    if(!IsActive || !AfkManagement)
    {
        return;
    }

    int client = GetClientOfUserId(event.GetInt("userid"));

    if(client && !IsFakeClient(client))
    {
        PlayerAfk[client][0] += 500;
    }
}

public Action GG_OnClientDeath(int Killer, int Victim, int WeaponId, bool TeamKilled)
{
    /* Afk management only checks after the player worldspawn/suicide checks */
    if ( !AfkManagement )
    {
        return Plugin_Continue;
    }

    float Origin[3];
    GetEntDataVector(Victim, OffsetOrigin, Origin);

    /* Basically by the time you get here the player drop approx about 55-60 units. So checking z now here is invalid. */
    if ( PlayerAfk[Victim][0] == Origin[0] && PlayerAfk[Victim][1] == Origin[1] )
    {
        /* You killed an afk. */
        CPrintToChat(Killer, "%t", "You do not gain a level because you killed an afk");

        if ( AfkAction && (++PlayerAfkCount[Victim] >= AfkDeaths) )
        {
            /* Hope this works */
            if ( AfkAction & AFK_KICK )
            {
                KickClient(Victim, "[GunGame] Max afk deaths reached");
            }
            else if ( AfkAction & AFK_SPECTATE )
            {
                ChangeClientTeam(Victim, TEAM_SPECTATOR);
                PlayerAfkCount[Victim] = 0;
            }
        }

        if ( AfkReload )
        {
            return Plugin_Changed;
        }

        return Plugin_Handled;
    }

    PlayerAfkCount[Victim] = 0;
    return Plugin_Continue;
}

public void GG_ConfigNewSection(const char[] name)
{
    if ( strcmp("Config", name, false) == 0 )
    {
        ConfigState = CONFIG_STATE_CONFIG;
    }
}

public void GG_ConfigKeyValue(const char[] key, const char[] value)
{
    if ( ConfigState == CONFIG_STATE_CONFIG )
    {
        if ( strcmp("AfkManagement", key, false) == 0 ) {
            AfkManagement = view_as<bool>(StringToInt(value));
        } else if(strcmp("AfkDeaths", key, false) == 0) {
            AfkDeaths = StringToInt(value);
        } else if(strcmp("AfkAction", key, false) == 0) {
            AfkAction = StringToInt(value);
        } else if(strcmp("AfkReload", key, false) == 0) {
            AfkReload = StringToInt(value);
        }
    }
}

public void GG_ConfigParseEnd()
{
    ConfigState = CONFIG_STATE_NONE;
}

public void OnClientAuthorized(int client, const char[] auth)
{
    PlayerAfkCount[client] = 0;
}
