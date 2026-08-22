#pragma semicolon 1

/*----------------------------------------------------------------------+
| INCLUDES                                                              |
+----------------------------------------------------------------------*/
#include <sourcemod>
#include <sdktools>
#include <gungame_const>
#include <gungame_config>
#include "gungame/stock.sp"

#pragma newdecls required

/*----------------------------------------------------------------------+
| PLUGIN INFO                                                           |
+----------------------------------------------------------------------*/
public Plugin myinfo = {
    name        = "GunGame:SM Winner Effects",
    author      = GUNGAME_AUTHOR,
    description = "Show winner effects on gungame win",
    version     = GUNGAME_VERSION,
    url         = GUNGAME_URL
};

/*----------------------------------------------------------------------+
| INIT VARS                                                             |
+----------------------------------------------------------------------*/
#define SPRITE_CSGO     "sprites/ledglow.vmt"
#define SPRITE_CSS      "sprites/orangeglow1.vmt"

State g_ConfigState      = CONFIG_STATE_NONE;
int g_Cfg_WinnerEffect   = 0;
int g_GlowSprite         = -1;
GameName g_GameName      = None;
int g_winner             = 0;

/*----------------------------------------------------------------------+
| LOAD CONFIG                                                           |
+----------------------------------------------------------------------*/
public void GG_ConfigNewSection(const char[] NewSection) {
    if (strcmp(NewSection, "Config", false) == 0) {
        g_ConfigState = CONFIG_STATE_CONFIG;
    }
}

public void GG_ConfigKeyValue(const char[] key, const char[] value) {
    if (g_ConfigState == CONFIG_STATE_CONFIG) {
        if  (strcmp("WinnerEffect", key, false) == 0) {
            g_Cfg_WinnerEffect = StringToInt(value);
        }
    }
}

public void GG_ConfigParseEnd() {
    g_ConfigState = CONFIG_STATE_NONE;
}

/*----------------------------------------------------------------------+
| PUBLIC EVENTS                                                         |
+----------------------------------------------------------------------*/
public void OnMapStart() {
    g_winner = 0;

    if (g_GameName == Csgo) {
        g_GlowSprite = PrecacheModel(SPRITE_CSGO);
    } else {
        g_GlowSprite = PrecacheModel(SPRITE_CSS);
    }
}

public void OnPluginStart() {
    g_GameName = DetectGame();
    if (g_GameName == None) {
        SetFailState("ERROR: Unsupported game. Please contact the author.");
    }

    HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    if (!g_Cfg_WinnerEffect) {
        return;
    }

    if (!g_winner) {
        return;
    }

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!client) {
        return;
    }

    WinnerEffectsStartOne(g_winner, client);
}

/*----------------------------------------------------------------------+
| GUNGAME EVENTS                                                        |
+----------------------------------------------------------------------*/
public void GG_OnStartup(bool Command) {
    if (!g_Cfg_WinnerEffect) {
        return;
    }

    g_winner = 0;
}

public void GG_OnWinner(int client, const char[] Weapon, int victim) {
    if (!g_Cfg_WinnerEffect) {
        return;
    }

    g_winner = client;
    WinnerEffectsStart(client);
}

/*----------------------------------------------------------------------+
| WINNER EFFECTS                                                        |
+----------------------------------------------------------------------*/
void WinnerEffectsStart(int winner) {
    if (g_Cfg_WinnerEffect == 1) {
        WinnerEffect(winner);
    }
}

void WinnerEffectsStartOne(int winner, int client) {
    if (g_Cfg_WinnerEffect == 1) {
        WinnerEffectOne(winner, client);
    }
}

void WinnerEffect(int winner) {
    for (int i=1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i)) {
            WinnerEffectOne(winner, i);
        }
    }
}

void WinnerEffectOne(int winner, int client) {
    SetPlayerWinnerEffectAll(client);
    if (winner==client) {
        SetPlayerWinnerEffectWinner(client);
    }
}

void SetPlayerWinnerEffectAll(int client) {
    // fly
    SetEntityGravity(client, 0.001);

    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);

    float pos[3], vel[3];
    GetClientEyePosition(client, pos);

    vel[0] = GetRandomFloat(-10.0, 10.0);
    vel[1] = GetRandomFloat(-10.0, 10.0);
    vel[2] = GetRandomFloat(70.0, 120.0);

    TeleportEntity(client, pos, NULL_VECTOR, vel);
}

void SetPlayerWinnerEffectWinner(int client) {
    //CreateLight(client);
    SetPlayerWinnerEffectWinnerRepeate(client);
}

void SetPlayerWinnerEffectWinnerRepeate(int client) {
    CreateTimer(0.1, Timer_SetPlayerWinnerEffectWinner, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SetPlayerWinnerEffectWinner(Handle timer, any data) {
    if (!IsClientInGame(data)||!IsPlayerAlive(data)) {
        return Plugin_Stop;
    }
    SetPlayerWinnerEffectWinnerReal(data);
    return Plugin_Continue;
}

void SetPlayerWinnerEffectWinnerReal(int client) {
    // shine
    float vec[3];
    GetClientAbsOrigin(client, vec);
    vec[2] += 40;

    TE_SetupGlowSprite(vec, g_GlowSprite, 0.5, 4.0, 70);
    TE_SendToAll();
}

// TODO: test it
stock void CreateLight(int client) {
    float clientposition[3];
    GetClientAbsOrigin(client, clientposition);
    clientposition[2] += 40.0;

    int GLOW_ENTITY = CreateEntityByName("env_glow");

    SetEntProp(GLOW_ENTITY, Prop_Data, "m_nBrightness", 70, 4);

    //new String:model[100];
    //FormatEx(model, sizeof(model), "materials/%s", g_GameName == GameName:Csgo?SPRITE_CSGO:SPRITE_CSS);
    //DispatchKeyValue(GLOW_ENTITY, "model", model);
    DispatchKeyValue(GLOW_ENTITY, "model", g_GameName == Csgo?SPRITE_CSGO:SPRITE_CSS);

    DispatchKeyValue(GLOW_ENTITY, "rendermode", "3");
    DispatchKeyValue(GLOW_ENTITY, "renderfx", "14");
    DispatchKeyValue(GLOW_ENTITY, "scale", "4.0");
    DispatchKeyValue(GLOW_ENTITY, "renderamt", "255");
    DispatchKeyValue(GLOW_ENTITY, "rendercolor", "255 255 255 255");
    DispatchSpawn(GLOW_ENTITY);
    AcceptEntityInput(GLOW_ENTITY, "ShowSprite");
    TeleportEntity(GLOW_ENTITY, clientposition, NULL_VECTOR, NULL_VECTOR);

    char target[20];
    FormatEx(target, sizeof(target), "glowclient_%d", client);
    DispatchKeyValue(client, "targetname", target);
    SetVariantString(target);
    AcceptEntityInput(GLOW_ENTITY, "SetParent");
    AcceptEntityInput(GLOW_ENTITY, "TurnOn");
}
