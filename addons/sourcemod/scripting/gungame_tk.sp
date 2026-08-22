#pragma semicolon 1

#include <sourcemod>
#include <gungame_const>
#include <gungame>
#include <gungame_config>
#include <colors>
#include <langutils>

#pragma newdecls required

State ConfigState;
int TkLooseLevel;

/**
 * This is a meant to make the tk optional where you lose a level by team killing another teammate.
 */

public Plugin myinfo =
{
    name = "GunGame:SM TK Management",
    author = GUNGAME_AUTHOR,
    description = "Team Killed Management System",
    version = GUNGAME_VERSION,
    url = GUNGAME_URL
};

public void OnPluginStart()
{
    LoadTranslations("gungame_tk");
}

public Action GG_OnClientDeath(int Killer, int Victim, int WeaponId, bool TeamKilled)
{
    if ( !TeamKilled || !TkLooseLevel )
    {
        return Plugin_Continue;
    }
    /* Tk a player */
    int lost = GG_RemoveLevelMulti(Killer, TkLooseLevel);
    if ( !lost )
    {
        return Plugin_Continue;
    }

    char kName[MAX_NAME_SIZE], vName[MAX_NAME_SIZE];
    GetClientName(Killer, kName, sizeof(kName));
    GetClientName(Victim, vName, sizeof(vName));

    if ( TkLooseLevel > 1)
    {
        char subtext[64];
        for ( int i = 1; i <= MaxClients; i++ )
        {
            if ( IsClientInGame(i) )
            {
                SetGlobalTransTarget(i);
                FormatLanguageNumberTextEx(i, subtext, sizeof(subtext), lost, "levels");
                CPrintToChatEx(i, Killer, "%t", "Has lost levels due to team kill", kName, vName, subtext);
            }
        }
    }
    else
    {
        CPrintToChatAllEx(Killer, "%t", "Has lost a level due to team kill", kName, vName);
    }

    return Plugin_Handled;
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
        if ( strcmp("TkLooseLevel", key, false) == 0 ) {
            TkLooseLevel = StringToInt(value);
        }
    }
}

public void GG_ConfigParseEnd()
{
    ConfigState = CONFIG_STATE_NONE;
}
