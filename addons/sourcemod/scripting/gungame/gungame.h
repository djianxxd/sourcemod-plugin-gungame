#define DATE __DATE__
#define TIME __TIME__

/* PlayerState[client] */
#define KNIFE_ELITE         (1<<0)
#define FIRST_JOIN          (1<<1)
#define GRENADE_LEVEL       (1<<2)

enum Sounds
{
    Welcome,
    Knife,
    Nade,
    Steal,
    Up,
    Down,
    Triple,
    AutoFF,
    MultiKill,
    Winner,
    WarmupTimerSound,
    MaxSounds
}

char g_WeaponName[MAX_WEAPONS_COUNT][MAX_WEAPON_NAME_LEN];
Slots g_WeaponSlot[MAX_WEAPONS_COUNT];
int g_WeaponAmmo[MAX_WEAPONS_COUNT];
bool g_WeaponDropKnife[MAX_WEAPONS_COUNT];
int g_WeaponLevelIndex[MAX_WEAPONS_COUNT];

char EventSounds[MaxSounds][PLATFORM_MAX_PATH];

/* Default values for weapon order.*/
int WeaponOrderId[GUNGAME_MAX_LEVEL];
char WeaponOrderName[GUNGAME_MAX_LEVEL][24];
int WeaponOrderCount;
int RandomWeaponOrderMap[GUNGAME_MAX_LEVEL];
bool RandomWeaponOrder;

// ConVar Pointer
ConVar mp_friendlyfire = null;
ConVar mp_restartgame = null;
ConVar gungame_enabled = null;

/* Status forwards */
GlobalForward FwdLevelChange = null;
GlobalForward FwdWarmupEnd = null;
GlobalForward FwdWarmupStart = null;
GlobalForward FwdWinner = null;
GlobalForward FwdSoundWinner = null;
GlobalForward FwdTripleLevel = null;
GlobalForward FwdLeader = null;
GlobalForward FwdVoteStart = null;
GlobalForward FwdDisableRtv = null;
GlobalForward FwdDeath = null;
GlobalForward FwdPoint = null;
GlobalForward FwdStart = null;
GlobalForward FwdShutdown = null;

Handle WarmupTimer = null;

bool IsActive = false;
bool IsObjectiveHooked;
int HostageEntInfo;
StringMap PlayerLevelsBeforeDisconnect = null;
Handle g_Timer_HandicapUpdate = null;
StringMap PlayerHandicapTimes = null;
bool g_SkipSpawn[MAXPLAYERS+1] = {false, ...};

GameName g_GameName = None;
int g_WeaponsMaxId              = 0;

int g_WeaponIdKnife             = 0;
int g_WeaponIdHegrenade         = 0;
int g_WeaponIdSmokegrenade      = 0;
int g_WeaponIdFlashbang         = 0;
int g_WeaponIdTaser             = 0;

int g_WeaponLevelIdKnife        = 0;
int g_WeaponLevelIdHegrenade    = 0;
int g_WeaponLevelIdTaser        = 0;
int g_WeaponLevelIdMolotov      = 0;

int g_WeaponAmmoTypeHegrenade       = 0;
int g_WeaponAmmoTypeFlashbang       = 0;
int g_WeaponAmmoTypeSmokegrenade    = 0;
int g_WeaponAmmoTypeMolotov         = 0;
int g_WeaponAmmoTypeTaser           = 0;
bool g_BlockFastSwitchOnChange[MAXPLAYERS+1]    = {false, ...};
