int PlayerState[MAXPLAYERS + 1];
int PlayerOnGrenade;

int CTcount;
int Tcount;

/* Checks to make sure clients only gain level by objective during Round Started and not during Round End*/
bool RoundStarted;

/* Changes the default MinKillsPerWeapon setting if value is greater than 0. */
int CustomKillPerLevel[GUNGAME_MAX_LEVEL];

int PlayerLevel[MAXPLAYERS + 1];
int CurrentKillsPerWeap[MAXPLAYERS + 1];
int CurrentLevelPerRound[MAXPLAYERS + 1];
int CurrentLevelPerRoundTriple[MAXPLAYERS + 1];
int CurrentLeader;
int GameWinner;
bool g_teamChange[MAXPLAYERS + 1];
int g_NumberOfNades[MAXPLAYERS + 1];
bool g_BlockSwitch[MAXPLAYERS + 1];
