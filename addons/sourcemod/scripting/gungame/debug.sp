void OnCreateDebug() {
    RegConsoleCmd("gungamesm_display", _CmdDisplay);
    RegConsoleCmd("gungamesm_set_level", _CmdSetLevel);
}

public Action _CmdSetLevel(int client, int args) {
    char Arg[10];
    GetCmdArg(1, Arg, sizeof(Arg));

    int oldLevel = PlayerLevel[client];
    int setLevel = StringToInt(Arg)-1;
    if ( setLevel < 0 || setLevel >= WeaponOrderCount ) {
        setLevel = 0;
    }
    int newLevel = UTIL_ChangeLevel(client, setLevel - oldLevel); // todo: need to test this
    char name[MAX_NAME_SIZE];
    if ( client && IsClientConnected(client) && IsClientInGame(client) ) {
        GetClientName(client, name, sizeof(name));
    } else {
        Format(name, sizeof(name), "[Client#%d]", client);
    }

    PrintLeaderToChat(client, oldLevel, newLevel, name);

    return Plugin_Handled;
}

public Action _CmdDisplay(int client, int args) {
    char Args[64];
    char Args2[64];
    GetCmdArg(1, Args, sizeof(Args));
    GetCmdArg(2, Args2, sizeof(Args2));

    if (strcmp("weapons", Args) == 0) {
        //for(new i = 0; i <
    } else if(strcmp("config", Args) == 0) {
        Debug_DisplayConfig(client);
    } else if(strcmp("get_weapon_index", Args) == 0) {
        Debug_DisplayGetWeaponIndex(client, Args2);
    }
    // else if strcmp other commands

    return Plugin_Handled;
}

void Debug_DisplayConfig(int client) {
    // todo
    PrintToConsole(client, "Not implemented yet");
}

void Debug_DisplayGetWeaponIndex(int client, const char[] weaponName) {
    PrintToConsole(client, "Weapon index=%i for weapon name=%s", UTIL_GetWeaponIndex(weaponName), weaponName);
}
