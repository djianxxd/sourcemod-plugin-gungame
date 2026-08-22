/**
 * Top rank and player data will sync after map change.
 */

bool SaveProcess;

/* Player Data */
int PlayerWinsData[MAXPLAYERS + 1] = {0, ...};
bool IsActive;

int PlayerPlaceData[MAXPLAYERS + 1] = {0, ...};
int TotalWinners = 0;

GlobalForward FwdLoadRank = null;
GlobalForward FwdLoadPlayerWins = null;
int g_cfgHandicapTopWins = 0;

bool g_PlayerWinsLoaded[MAXPLAYERS + 1] = {false, ...};
