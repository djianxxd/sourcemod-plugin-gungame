#pragma semicolon 1

#include <sourcemod>
#include <gungame_const>
#include <gungame>

#pragma newdecls required

/**
 * This is a plugin for hlstatx logging of the winner of the gungame current level.
 */

public Plugin myinfo = {
    name = "GunGame:SM Winner Logger",
    author = GUNGAME_AUTHOR,
    description = "Logging of winner for external stats plugin",
    version = GUNGAME_VERSION,
    url = GUNGAME_URL
};

public void GG_OnWinner(int client, const char[] Weapon, int victim) {
    LogEventToGame("gg_win", client);
    LogEventToGame("gg_lose", victim);

    int teamWin = GetClientTeam(client);
    int teamLose = (teamWin == TEAM_CT)? TEAM_T: TEAM_CT;
    int team;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            team = GetClientTeam(i);
            if (team == teamWin) {
                LogEventToGame("gg_team_win", i);
            } else if (team == teamLose) {
                LogEventToGame("gg_team_lose", i);
            }
        }
    }
}

public void GG_OnTripleLevel(int client) {
    LogEventToGame("gg_triple_level", client);
}

public void GG_OnLeaderChange(int client, int level, int totalLevels) {
    if (client && IsClientInGame(client)) {
        LogEventToGame("gg_leader", client);
    }
}

public Action GG_OnClientLevelChange(int client, int level, int difference, bool steal, bool last, bool knife) {
    if (!difference) {
        return Plugin_Continue;
    }
    if (difference > 0) {
        LogEventToGame("gg_levelup", client);
        if (steal) {
            LogEventToGame("gg_knife_steal", client);
        }
        if (last) {
            LogEventToGame("gg_last_level", client);
        }
        if (knife) {
            LogEventToGame("gg_knife_level", client);
        }
    } else {
        LogEventToGame("gg_leveldown", client);
        for (int i = difference; i < 0; i++) {
            LogEventToGame("gg_leveldown", client);
        }
    }

    return Plugin_Continue;
}

void LogEventToGame(const char[] event, int client) {
    char Auth[64];

    if (!GetClientAuthId(client, AuthId_Steam2, Auth, sizeof(Auth))) {
        strcopy(Auth, sizeof(Auth), "UNKNOWN");
    }

    int team = GetClientTeam(client), UserId = GetClientUserId(client);
    LogToGame("\"%N<%d><%s><%s>\" triggered \"%s\"", client, UserId, Auth, (team == TEAM_T) ? "TERRORIST" : "CT", event);
}
