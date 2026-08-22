#pragma semicolon 1

#include <sourcemod>
#include <gungame_const>
#include <gungame_config>
#include "gungame/stock.sp"

#pragma newdecls required

/**
 * Do map specific config
 * make sure to do partial name config
 *
 * ie .. de.equip.txt
 * ie .. de.config.txt
 * ie .. de_dust.equip.txt
 * ie .. de_dust.config.txt
 *
 * it will be in configs/gungame/map/
 *
 * gungame.cfg will be read first before prefix map name.
 * prefix map name will be executed first before map specfic map.
 * then map specifc config files will be loaded.
 */

public Plugin myinfo =
{
    name = "GunGame:SM Config Reader",
    author = GUNGAME_AUTHOR,
    description = "GunGame:SM Config Reader",
    version = GUNGAME_VERSION,
    url = GUNGAME_URL
};

SMCParser ConfigParser;
int ConfigCount;
int ParseConfigCount;

GlobalForward FwdConfigNewSection;
GlobalForward FwdConfigKeyValue;
GlobalForward FwdConfigParseEnd;
GlobalForward FwdConfigEnd;

ConVar g_Cvar_CfgDirName;

GameName g_GameName = None;
char ConfigGameDirName[PLATFORM_MAX_PATH];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("gungame_cfg");
    CreateNative("GG_ConfigGetDir", Native_GG_ConfigGetDir);
    return APLRes_Success;
}

public int Native_GG_ConfigGetDir(Handle plugin, int numParams) {
    SetNativeString(1, ConfigGameDirName, GetNativeCell(2));
    return 1;
}

public void OnPluginStart() {
    g_GameName = DetectGame();
    if (g_GameName == None) {
        SetFailState("ERROR: Unsupported game. Please contact the author.");
    }

    FwdConfigNewSection = CreateGlobalForward("GG_ConfigNewSection", ET_Ignore, Param_String);
    FwdConfigKeyValue = CreateGlobalForward("GG_ConfigKeyValue", ET_Ignore, Param_String, Param_String);
    FwdConfigParseEnd = CreateGlobalForward("GG_ConfigParseEnd", ET_Ignore);
    FwdConfigEnd = CreateGlobalForward("GG_ConfigEnd", ET_Ignore);
    g_Cvar_CfgDirName = CreateConVar("sm_gg_cfgdirname", "gungame", "Config directory for gungame (from cfg path)");
}

public void OnConfigsExecuted() {
    ReadConfig();
}

void ReadConfig()
{
    ConfigParser = SMC_CreateParser();

    SMC_SetParseEnd(ConfigParser, ReadConfig_ParseEnd);
    SMC_SetReaders(ConfigParser, ReadConfig_NewSection, ReadConfig_KeyValue, ReadConfig_EndSection);

    if (ConfigParser == null)
    {
        return;
    }

    char ConfigDirName[PLATFORM_MAX_PATH];
    g_Cvar_CfgDirName.GetString(ConfigDirName, sizeof(ConfigDirName));

    if (g_GameName == Css) {
        FormatEx(ConfigGameDirName, sizeof(ConfigGameDirName), "%s\\css", ConfigDirName);
    } else if (g_GameName == Csgo) {
        FormatEx(ConfigGameDirName, sizeof(ConfigGameDirName), "%s\\csgo", ConfigDirName);
    }

    char ConfigDir[PLATFORM_MAX_PATH];
    FormatEx(ConfigDir, sizeof(ConfigDir), "cfg\\%s", ConfigGameDirName);

    char ConfigFile[PLATFORM_MAX_PATH], EquipFile[PLATFORM_MAX_PATH];
    char Error[PLATFORM_MAX_PATH + 64];

    FormatEx(ConfigFile, sizeof(ConfigFile), "%s\\gungame.config.txt", ConfigDir);

    if(FileExists(ConfigFile))
    {
        ConfigCount++;
        PrintToServer("[GunGame] Loading gungame.config.txt config file");
    } else {
        FormatEx(Error, sizeof(Error), "[GunGame] FATAL *** ERROR *** can not find %s", ConfigFile);
        SetFailState("%s", Error);
    }

    FormatEx(EquipFile, sizeof(EquipFile), "%s\\gungame.equip.txt", ConfigDir);

    if(FileExists(EquipFile))
    {
        ConfigCount++;
        PrintToServer("[GunGame] Loading gungame.equip.txt config file");
    } else {
        FormatEx(Error, sizeof(Error), "[GunGame] FATAL *** ERROR *** can not find %s", EquipFile);
        SetFailState("%s", Error);
    }

    /* Build map config and map prefix config*/

    /**
     * Thanks sawce for the idea from your prefix map plugin loading for AMX Mod X
     * saved me alot of time doing it this way.
     *
     */

    char Map[32];
    int len = GetCurrentMap(Map, sizeof(Map));

    int i, b;
    while(Map[i] != '_' && Map[i] != '\0' && i < len)
    {
        i++;
    }

    char PrefixConfigFile[PLATFORM_MAX_PATH], PrefixEquipFile[PLATFORM_MAX_PATH];
    bool EquipOne, ConfigOne;

    if(Map[i] == '_')
    {
        b = Map[i];
        Map[i] = '\0';

        FormatEx(PrefixConfigFile, sizeof(PrefixConfigFile), "%s\\maps\\%s.config.txt", ConfigDir, Map);
        FormatEx(PrefixEquipFile, sizeof(PrefixEquipFile), "%s\\maps\\%s.equip.txt", ConfigDir, Map);

        if(FileExists(PrefixConfigFile))
        {
            ConfigOne = true;
            PrintToServer("[GunGame] Loading %s.config.txt config file", Map);
            ConfigCount++;
        }

        if(FileExists(PrefixEquipFile))
        {
            EquipOne = true;
            PrintToServer("[GunGame] Loading %s.equip.txt config file", Map);
            ConfigCount++;
        }

        Map[i] = b;
    }

    char MapEquipFile[PLATFORM_MAX_PATH], MapConfigFile[PLATFORM_MAX_PATH];
    bool EquipTwo, ConfigTwo;

    FormatEx(MapConfigFile, sizeof(MapConfigFile), "%s\\maps\\%s.config.txt", ConfigDir, Map);
    FormatEx(MapEquipFile, sizeof(MapEquipFile), "%s\\maps\\%s.equip.txt", ConfigDir, Map);

    if(FileExists(MapConfigFile))
    {
        PrintToServer("[GunGame] Loading %s.config.txt file", Map);
        ConfigTwo = true;
        ConfigCount++;
    }

    if(FileExists(MapEquipFile))
    {
        PrintToServer("[GunGame] Loading %s.equip.txt file", Map);
        EquipTwo = true;
        ConfigCount++;
    }

    InternalReadConfig(ConfigFile);
    InternalReadConfig(EquipFile);

    if(ConfigOne)
    {
        InternalReadConfig(PrefixConfigFile);
    }

    if(EquipOne)
    {
        InternalReadConfig(PrefixEquipFile);
    }

    if(ConfigTwo)
    {
        InternalReadConfig(MapConfigFile);
    }

    if(EquipTwo)
    {
        InternalReadConfig(MapEquipFile);
    }
}

static void InternalReadConfig(const char[] path)
{
    SMCError err = ConfigParser.ParseFile(path);

    if (err != SMCError_Okay)
    {
        char buffer[64];
        if (ConfigParser.GetErrorString(err, buffer, sizeof(buffer)))
        {
            PrintToServer("%s", buffer);
        } else {
            PrintToServer("Fatal parse error");
        }
    }
}

public SMCResult ReadConfig_NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
    if(name[0])
    {
        Call_StartForward(FwdConfigNewSection);
        Call_PushString(name);
        Call_Finish();
    }

    return SMCParse_Continue;
}

public SMCResult ReadConfig_KeyValue(SMCParser smc,
                                        const char[] key,
                                        const char[] value,
                                        bool key_quotes,
                                        bool value_quotes)
{
    /**
     * Is this check really even neccessary?
     */

    if(key[0] && value[0])
    {
        Call_StartForward(FwdConfigKeyValue);
        Call_PushString(key);
        Call_PushString(value);
        Call_Finish();
    }

    return SMCParse_Continue;
}

public SMCResult ReadConfig_EndSection(SMCParser smc)
{
    return SMCParse_Continue;
}

public void ReadConfig_ParseEnd(SMCParser smc, bool halted, bool failed)
{
    Call_StartForward(FwdConfigParseEnd);
    Call_Finish();

    if(ConfigCount == ++ParseConfigCount)
    {
        Call_StartForward(FwdConfigEnd);
        Call_Finish();
    }
}
