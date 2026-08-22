/**
 * Config Setting
 */

State ConfigState;
bool ConfigReset;

int MapStatus;
int MaxLevelPerRound = 0;
int MinKillsPerLevel = 1;
bool TurboMode;
int StripDeadPlayersWeapon;
bool AllowLevelUpAfterRoundEnd;
bool RemoveBonusWeaponAmmo;
bool ReloadWeapon;
bool MultiKillChat;
bool JoinMessage;
int VoteLevelLessWeaponCount;
int ObjectiveBonus;
int WorldspawnSuicide = 1;
int NadeBonusWeaponId;
bool NadeSmoke;
bool NadeFlash;
int g_Cfg_ExtraNade;
bool UnlimitedNades;
bool WarmupNades;
bool KnifePro;
int KnifeProMinLevel;
bool KnifeElite;
bool AutoFriendlyFire;
bool BotCanWin;
bool WarmupEnabled = true;
bool DisableWarmupOnRoundEnd = false;
bool WarmupInitialized;
int Warmup_TimeLength = 30;
int WarmupCounter;
bool IsVotingCalled = false;
bool g_isCalledEnableFriendlyFire = false;
bool g_isCalledDisableRtv = false;
bool TripleLevelBonus = false;
bool KnifeProHE = false;
bool ObjectiveBonusWin = false;
bool InternalIsActive = true;
int CommitSuicide = 1;
bool AlltalkOnWin = false;
bool RestoreLevelOnReconnect;
bool TripleLevelBonusGodMode;
int HandicapMode;
bool TopRankHandicap;
bool StatsEnabled;
int WarmupRandomWeaponMode = 0;
int WarmupRandomWeaponLevel = 0;
int UnlimitedNadesMinPlayers = 0;
int FFA = 0;
int NumberOfNades = 0;
int g_Cfg_LevelsInScoreboard = 0;
int g_Cfg_HandicapLevelSubstract = 0;
int g_Cfg_ArmorKevlar = 1;
int g_Cfg_ArmorHelmet = 1;
float g_Cfg_TripleLevelBonusGravity = 0.5;
float g_Cfg_TripleLevelBonusSpeed = 1.5;
bool g_Cfg_TripleLevelEffect = false;
int g_Cfg_KnifeSmoke = 0;
int g_Cfg_KnifeFlash = 0;
int g_Cfg_ObjectiveBonusExplode = 0;
int g_Cfg_ShowLeaderWeapon = 0;
int g_Cfg_ShowSpawnMsgInHintBox = 0;
int g_Cfg_ShowLeaderInHintBox = 0;
int g_Cfg_MaxHandicapLevel = 0;
int g_Cfg_ScoreboardClearDeaths = 0;
int g_Cfg_WarmupWeapon = 0;
int g_Cfg_RandomWeaponReservLevels[GUNGAME_MAX_LEVEL];
float g_Cfg_HandicapUpdate;
int g_Cfg_KnifeProRecalcPoints = 0;
bool g_Cfg_HandicapSkipBots = false;
int g_Cfg_KnifeProMaxDiff = 0;
int g_Cfg_MultiLevelAmount = 3;
int g_Cfg_HandicapTimesPerMap = 0;
int g_cfgDisableRtvLevel = 0;
int g_cfgEnableFriendlyFireLevel = 0;
bool g_cfgFriendlyFireOnOff = true;
bool g_Cfg_BlockWeaponSwitchIfKnife = false;
bool g_Cfg_BlockWeaponSwitchOnNade = false;
bool g_Cfg_HandicapUseSpectators = false;
bool g_Cfg_CanLevelUpWithPhysics = false;
bool g_Cfg_CanLevelUpWithPhysicsG = false;
bool g_Cfg_CanLevelUpWithPhysicsK = false;
bool g_Cfg_CanLevelUpWithMapNades = false;
bool g_Cfg_CanLevelUpWithNadeOnKnife = false;
bool g_Cfg_DisableLevelDown = false;
bool g_Cfg_SelfKillProtection = false;
char g_CfgGameDesc[64] = "";
int g_Cfg_MultilevelEffectType = 2;

#if defined WITH_SDKHOOKS
bool g_SdkHooksEnabled = true;
#else
bool g_SdkHooksEnabled = false;
#endif

ConVar g_Cvar_Turbo;
ConVar g_Cvar_MultiLevelAmount;
int g_Cfg_MultiplySoundVolume = 0;
int g_Cfg_BonusWeaponAmmo = 0;
int g_Cfg_ExtraTaserOnKnifeKill = 0;

int g_Cfg_MolotovBonusFlash         = 0;
int g_Cfg_MolotovBonusSmoke         = 0;
int g_Cfg_MolotovBonusWeaponId      = 0;
int g_Cfg_ExtraMolotovOnKnifeKill   = 0;

float g_Cfg_EndGameDelay        = 0.0;
int g_Cfg_WinnerFreezePlayers       = 0;
int g_Cfg_FastSwitchOnChangeWeapon  = 0;
int g_Cfg_FastSwitchOnLevelUp       = 0;
bool g_Cfg_FastSwitchSkipWeapons[MAX_WEAPONS_COUNT];

int g_Cfg_EndGameSilent = 0;
