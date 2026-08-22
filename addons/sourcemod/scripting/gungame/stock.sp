
stock GameName DetectGame() {
    char gameName[30];
    GetGameFolderName(gameName, sizeof(gameName));
    if (StrEqual(gameName, "cstrike", false)) {
        return Css;
    } else if (StrEqual(gameName, "csgo", false)) {
        return Csgo;
    } else {
        LogError("ERROR: Unsupported game %s. Please contact the author.", gameName);
        return None;
    }
}
