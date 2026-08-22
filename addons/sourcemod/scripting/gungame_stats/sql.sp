// non-threaded
void SqlConnect()
{
    if ( g_DbConnection != null )
    {
        return;
    }

    char error[256];
    if ( SQL_CheckConfig("gungame") ) {
        g_DbConnection = SQL_Connect("gungame", false, error, sizeof(error));
    } else {
        g_DbConnection = SQL_Connect("storage-local", false, error, sizeof(error));
    }

    if ( g_DbConnection == null )
    {
        SetFailState("Unable to connect to database (%s)", error);
        return;
    }

    char ident[16];
    SQL_ReadDriver(g_DbConnection, ident, sizeof(ident));
    if ( strcmp(ident, "sqlite") == 0 ) {
        g_DbType = DbTypeSqlite;
    } else if ( strcmp(ident, "mysql") == 0 ) {
        g_DbType = DbTypeMysql;
    } else if ( strcmp(ident, "pgsql") == 0 ) {
        g_DbType = DbTypePgsql;
    } else {
        delete g_DbConnection;
        g_DbConnection = null;
        SetFailState("Unknown db type (%s)", ident);
        return;
    }

    SQL_LockDatabase(g_DbConnection);

    bool tableExists = false;
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", g_sql_checkTableExists[g_DbType]);
    #endif
    DBResultSet result = SQL_Query(g_DbConnection, g_sql_checkTableExists[g_DbType]);
    if ( result == null )
    {
        SQL_GetError(g_DbConnection, error, sizeof(error));
        LogError("Failed to check table exists (error: %s)", error);
        SQL_UnlockDatabase(g_DbConnection);
        return;
    } else {
        tableExists = view_as<bool>(result.RowCount);
        delete result;
    }

    if ( !tableExists )
    {
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] %s", g_sql_createPlayerTable[g_DbType]);
        #endif
        if ( !SQL_FastQuery(g_DbConnection, g_sql_createPlayerTable[g_DbType]) )
        {
            SQL_GetError(g_DbConnection, error, sizeof(error));
            LogError("Could not create players table (error: %s)", error);
            SQL_UnlockDatabase(g_DbConnection);
            return;
        }
        if ( g_sql_createPlayerTableIndex1[g_DbType][0] != 0 )
        {
            #if defined SQL_DEBUG
                LogError("[DEBUG-SQL] %s", g_sql_createPlayerTableIndex1[g_DbType]);
            #endif
            if ( !SQL_FastQuery(g_DbConnection, g_sql_createPlayerTableIndex1[g_DbType]) )
            {
                SQL_GetError(g_DbConnection, error, sizeof(error));
                LogError("Could not create players table index 1 (error: %s)", error);
                SQL_UnlockDatabase(g_DbConnection);
                return;
            }
        }
        if ( g_sql_createPlayerTableIndex2[g_DbType][0] != 0 )
        {
            #if defined SQL_DEBUG
                LogError("[DEBUG-SQL] %s", g_sql_createPlayerTableIndex2[g_DbType]);
            #endif
            if ( !SQL_FastQuery(g_DbConnection, g_sql_createPlayerTableIndex2[g_DbType]) )
            {
                SQL_GetError(g_DbConnection, error, sizeof(error));
                LogError("Could not create players table index 2 (error: %s)", error);
                SQL_UnlockDatabase(g_DbConnection);
                return;
            }
        }
    }
    SQL_UnlockDatabase(g_DbConnection);
}

// threaded
void SavePlayerData(int client)
{
    int wins = PlayerWinsData[client];
    if ( !wins )
    {
        return;
    }

    char auth[64], name[MAX_NAME_SIZE];
    GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

    /* Normalize STEAM_1:... back to legacy STEAM_0:... used as database keys */
    if ( strncmp(auth, "STEAM_1:", 8) == 0 ) {
        auth[6] = '0';
    }

    GetClientName(client, name, sizeof(name));

    char nameQuoted[sizeof(name) * 2 + 1];

    g_DbConnection.Escape(name, nameQuoted, sizeof(nameQuoted));

    char query[1024];
    if ( wins == 1 ) {
        Format(query, sizeof(query), g_sql_insertPlayer, wins, nameQuoted, auth);
    } else {
        Format(query, sizeof(query), g_sql_updatePlayerByAuth, wins, nameQuoted, auth);
    }
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", query);
    #endif
    g_DbConnection.Query(T_SavePlayerData, query);
}

// threaded
public void T_SavePlayerData(Database owner, DBResultSet result, const char[] error, any data)
{
    if ( result == null )
    {
        LogError("Failed to save player data (error: %s)", error);
        return;
    }

    // Reload top rank data after winner has beed updated in the database
    LoadRank();
}

// non-threaded
int GetPlayerPlaceInStat(int client)
{
    // get from cache
    if ( !PlayerWinsData[client] || PlayerPlaceData[client] )
    {
        return PlayerPlaceData[client];
    }
    // get from database
    PlayerPlaceData[client] = GetPlayerPlace(client);
    return PlayerPlaceData[client];
}

// non-threaded
int GetPlayerPlace(int client)
{
    char query[1024];
    Format(query, sizeof(query), g_sql_getPlayerPlaceByWins, PlayerWinsData[client]);
    SQL_LockDatabase(g_DbConnection);
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", query);
    #endif
    DBResultSet result = SQL_Query(g_DbConnection, query);
    if ( result == null )
    {
        char error[255];
        SQL_GetError(g_DbConnection, error, sizeof(error));
        LogError("Failed get player place in stats (error: %s)", error);
        SQL_UnlockDatabase(g_DbConnection);
        return 0;
    }
    SQL_UnlockDatabase(g_DbConnection);
    int place;
    if ( result.FetchRow() )
    {
        place = result.FetchInt(0) + 1;
    }
    delete result;
    return place;
}

int CountPlayersInStat()
{
    return TotalWinners;
}

// threaded
void RetrieveKeyValues(int client, const char[] auth)
{
    if ( auth[0] == 'B' )
    {
        g_PlayerWinsLoaded[client] = true;
        PlayerWinsData[client] = 0;

        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] FORWARD PLAYER WINS LOADED client=%i is BOT", client);
        #endif

        Call_StartForward(FwdLoadPlayerWins);
        Call_PushCell(client);
        Call_Finish();
        return;
    }
    char query[1024];
    Format(query, sizeof(query), g_sql_getPlayerByAuth, auth);
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", query);
    #endif
    g_DbConnection.Query(T_RetrieveKeyValues, query, client);
}

public void T_RetrieveKeyValues(Database owner, DBResultSet result, const char[] error, any client)
{
    /* Make sure the client didn't disconnect while the thread was running */
    if ( !IsClientConnected(client) )
    {
        return;
    }
    if ( result == null )
    {
        LogError("Failed to retrieve player by auth (error: %s)", error);
        return;
    }
    g_PlayerWinsLoaded[client] = true;
    if ( result.FetchRow() )
    {
        int id = result.FetchInt(0);
        PlayerWinsData[client] = result.FetchInt(1);

        // update player timestamp
        char query[1024];
        Format(query, sizeof(query), g_sql_updatePlayerTsById, id);
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] %s", query);
        #endif
        g_DbConnection.Query(T_FastQueryResult, query);
    }
    else
    {
        PlayerWinsData[client] = 0;
    }
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] FORWARD PLAYER WINS LOADED client=%i, wins=%i", client, PlayerWinsData[client]);
    #endif
    Call_StartForward(FwdLoadPlayerWins);
    Call_PushCell(client);
    Call_Finish();
}

public void T_FastQueryResult(Database owner, DBResultSet result, const char[] error, any data)
{
    if ( result == null )
    {
        LogError("Fast query failed (error: %s)", error);
        return;
    }
    // reqest was successfull
}

// threaded
void SavePlayerDataInfo()
{
    if (!Prune) {
        return;
    }

    char query[1024];
    if ( g_DbType == DbTypeSqlite ) {
        Format(query, sizeof(query), g_sql_prunePlayers[g_DbType], GetTime() - Prune*86400);
    } else {
        Format(query, sizeof(query), g_sql_prunePlayers[g_DbType], Prune);
    }
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", query);
    #endif
    g_DbConnection.Query(T_SavePlayerDataInfo, query);
}

public void T_SavePlayerDataInfo(Database owner, DBResultSet result, const char[] error, any data)
{
    if ( result == null )
    {
        LogError("Could not prune players (error: %s)", error);
        return;
    }
}

void OnCreateKeyValues()
{
    SqlConnect();
    LoadRank();
}

// non-threaded
public Action _CmdImport(int client, int args)
{
    char EsFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, EsFile, sizeof(EsFile), "data/gungame/es_gg_winners_db.txt");

    if ( !FileExists(EsFile) )
    {
        ReplyToCommand(client, "[GunGame] es_gg_winners_db.txt does not exists to be imported.");
        return Plugin_Handled;
    }

    KeyValues KvGunGame = new KeyValues("gg_winners", BLANK, BLANK);
    KvGunGame.ImportFromFile(EsFile);

    /* Go to first SubKey */
    if ( !KvGunGame.GotoFirstSubKey() )
    {
        ReplyToCommand(client, "[GunGame] You have no player data to import.");
        delete KvGunGame;
        return Plugin_Handled;
    }

    char query[1024], error[255];
    int Wins;
    char Name[64];
    int ImportedWins;
    char Auth[64];

    char nameQuoted[sizeof(Name) * 2 + 1];

    do
    {
        KvGunGame.GetSectionName(Auth, sizeof(Auth));
        ImportedWins = KvGunGame.GetNum("wins");

        if ( !ImportedWins || Auth[0] != 'S' )
        {
            continue;
        }

        // Load player data
        SQL_LockDatabase(g_DbConnection);
        Format(query, sizeof(query), g_sql_getPlayerByAuth, Auth);
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] %s", query);
        #endif
        DBResultSet result = SQL_Query(g_DbConnection, query);
        if ( result == null )
        {
            SQL_GetError(g_DbConnection, error, sizeof(error));
            LogError("Failed to get player (error: %s)", error);
            SQL_UnlockDatabase(g_DbConnection);
            ReplyToCommand(client, "[GunGame] Import finished with sql error");
            delete KvGunGame;
            return Plugin_Handled;
        }
        SQL_UnlockDatabase(g_DbConnection);
        if ( result.FetchRow() )
        {
            Wins = result.FetchInt(1);
            result.FetchString(2, Name, sizeof(Name));
        }
        else
        {
            Wins = 0;
        }
        delete result;

        if ( Wins ) {
            g_DbConnection.Escape(Name, nameQuoted, sizeof(nameQuoted));
            Format(query, sizeof(query), g_sql_updatePlayerByAuth, Wins + ImportedWins, nameQuoted, Auth);
        } else {
            KvGunGame.GetString("name", Name, sizeof(Name));
            g_DbConnection.Escape(Name, nameQuoted, sizeof(nameQuoted));
            Format(query, sizeof(query), g_sql_insertPlayer, ImportedWins, nameQuoted, Auth);
        }

        // SavePlayerData
        SQL_LockDatabase(g_DbConnection);
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] %s", query);
        #endif
        if ( !SQL_FastQuery(g_DbConnection, query) )
        {
            SQL_GetError(g_DbConnection, error, sizeof(error));
            LogError("Could not save player (error: %s)", error);
            SQL_UnlockDatabase(g_DbConnection);
            ReplyToCommand(client, "[GunGame] Import finished with sql error");
            delete KvGunGame;
            return Plugin_Handled;
        }
        SQL_UnlockDatabase(g_DbConnection);
    }
    while(KvGunGame.GotoNextKey());

    delete KvGunGame;

    /* Reload the players wins in memory */
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientAuthorized(i) )
        {
            GetClientAuthId(i, AuthId_Steam2, Auth, sizeof(Auth));

            if ( strncmp(Auth, "STEAM_1:", 8) == 0 ) {
                Auth[6] = '0';
            }

            RetrieveKeyValues(i, Auth);
        }
    }

    ReplyToCommand(client, "[GunGame] Import of es player data completed. Please run gg_rebuild to update the top rank.");

    return Plugin_Handled;
}

// non-threaded
public Action _CmdImportDb(int client, int args)
{
    char KvFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, KvFile, sizeof(KvFile), "data/gungame/playerdata.txt");

    if ( !FileExists(KvFile) )
    {
        ReplyToCommand(client, "[GunGame] playerdata.txt does not exists to be imported.");
        return Plugin_Handled;
    }

    KeyValues KvGunGame = new KeyValues("gg_PlayerData", BLANK, BLANK);
    KvGunGame.ImportFromFile(KvFile);

    /* Go to first SubKey */
    if ( !KvGunGame.GotoFirstSubKey() )
    {
        ReplyToCommand(client, "[GunGame] You have no player data to import.");
        delete KvGunGame;
        return Plugin_Handled;
    }

    char query[1024], error[255];
    int Wins;
    char Name[64];
    int ImportedWins;
    char Auth[64];

    char nameQuoted[sizeof(Name) * 2 + 1];

    do
    {
        KvGunGame.GetSectionName(Auth, sizeof(Auth));
        ImportedWins = KvGunGame.GetNum("Wins");

        if ( !ImportedWins || Auth[0] != 'S' )
        {
            continue;
        }

        // Load player data
        SQL_LockDatabase(g_DbConnection);
        Format(query, sizeof(query), g_sql_getPlayerByAuth, Auth);
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] %s", query);
        #endif
        DBResultSet result = SQL_Query(g_DbConnection, query);
        if ( result == null )
        {
            SQL_GetError(g_DbConnection, error, sizeof(error));
            LogError("Failed to get player (error: %s)", error);
            SQL_UnlockDatabase(g_DbConnection);
            ReplyToCommand(client, "[GunGame] Import finished with sql error");
            delete KvGunGame;
            return Plugin_Handled;
        }
        SQL_UnlockDatabase(g_DbConnection);
        if ( result.FetchRow() )
        {
            Wins = result.FetchInt(1);
            result.FetchString(2, Name, sizeof(Name));
        }
        else
        {
            Wins = 0;
        }
        delete result;

        if ( Wins ) {
            g_DbConnection.Escape(Name, nameQuoted, sizeof(nameQuoted));
            Format(query, sizeof(query), g_sql_updatePlayerByAuth, Wins + ImportedWins, nameQuoted, Auth);
        } else {
            KvGunGame.GetString("Name", Name, sizeof(Name));
            g_DbConnection.Escape(Name, nameQuoted, sizeof(nameQuoted));
            Format(query, sizeof(query), g_sql_insertPlayer, ImportedWins, nameQuoted, Auth);
        }

        // SavePlayerData
        SQL_LockDatabase(g_DbConnection);
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] %s", query);
        #endif
        if ( !SQL_FastQuery(g_DbConnection, query) )
        {
            SQL_GetError(g_DbConnection, error, sizeof(error));
            LogError("Could not save player (error: %s)", error);
            SQL_UnlockDatabase(g_DbConnection);
            ReplyToCommand(client, "[GunGame] Import finished with sql error");
            delete KvGunGame;
            return Plugin_Handled;
        }
        SQL_UnlockDatabase(g_DbConnection);
    }
    while(KvGunGame.GotoNextKey());

    delete KvGunGame;

    /* Reload the players wins in memory */
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientAuthorized(i) )
        {
            GetClientAuthId(i, AuthId_Steam2, Auth, sizeof(Auth));

            if ( strncmp(Auth, "STEAM_1:", 8) == 0 ) {
                Auth[6] = '0';
            }

            RetrieveKeyValues(i, Auth);
        }
    }

    ReplyToCommand(client, "[GunGame] Import of player data completed. Please run gg_rebuild to update the top rank.");

    return Plugin_Handled;
}

// threaded
public Action _CmdRebuild(int client, int args)
{
    LoadRank();
    ReplyToCommand(client, "[GunGame] Top rank has been rebuilt");
    return Plugin_Handled;
}

// non-threaded
public Action _CmdReset(int client, int args)
{
    char error[256];
    SQL_LockDatabase(g_DbConnection);
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", g_sql_dropPlayerTable);
    #endif
    if ( !SQL_FastQuery(g_DbConnection, g_sql_dropPlayerTable) )
    {
        SQL_GetError(g_DbConnection, error, sizeof(error));
        LogError("Could not drop players table (error: %s)", error);
        SQL_UnlockDatabase(g_DbConnection);
        ReplyToCommand(client, "[GunGame] Error reseting stats.");
        return Plugin_Handled;
    }
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", g_sql_createPlayerTable[g_DbType]);
    #endif
    if ( !SQL_FastQuery(g_DbConnection, g_sql_createPlayerTable[g_DbType]) )
    {
        SQL_GetError(g_DbConnection, error, sizeof(error));
        LogError("Could not create players table (error: %s)", error);
        SQL_UnlockDatabase(g_DbConnection);
        ReplyToCommand(client, "[GunGame] Error reseting stats.");
        return Plugin_Handled;
    }
    if ( g_sql_createPlayerTableIndex1[g_DbType][0] != 0 )
    {
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] %s", g_sql_createPlayerTableIndex1[g_DbType]);
        #endif
        if ( !SQL_FastQuery(g_DbConnection, g_sql_createPlayerTableIndex1[g_DbType]) )
        {
            SQL_GetError(g_DbConnection, error, sizeof(error));
            LogError("Could not create players table index 1 (error: %s)", error);
            SQL_UnlockDatabase(g_DbConnection);
            return Plugin_Handled;
        }
    }
    if ( g_sql_createPlayerTableIndex2[g_DbType][0] != 0 )
    {
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] %s", g_sql_createPlayerTableIndex2[g_DbType]);
        #endif
        if ( !SQL_FastQuery(g_DbConnection, g_sql_createPlayerTableIndex2[g_DbType]) )
        {
            SQL_GetError(g_DbConnection, error, sizeof(error));
            LogError("Could not create players table index 2 (error: %s)", error);
            SQL_UnlockDatabase(g_DbConnection);
            return Plugin_Handled;
        }
    }
    SQL_UnlockDatabase(g_DbConnection);
    ReplyToCommand(client, "[GunGame] Stats has been reseted.");

    // reset current players data
    for (int i = 1; i <= MAXPLAYERS; i++)
    {
        PlayerWinsData[i] = 0;
        PlayerPlaceData[i] = 0;
    }

    // reset top 10 data
    TotalWinners = 0;
    g_cfgHandicapTopWins = 0;

    return Plugin_Handled;
}

// threaded
void LoadRank()
{
    // reset top 10 data
    TotalWinners = 0;
    g_cfgHandicapTopWins = 0;
    for ( int i = 1; i <= MAXPLAYERS; i++ )
    {
        PlayerPlaceData[i] = 0;
    }

    CountWinners();
}

// threaded
void CountWinners()
{
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", g_sql_getPlayersCount);
    #endif
    g_DbConnection.Query(T_CountWinners, g_sql_getPlayersCount);
}

public void T_CountWinners(Database owner, DBResultSet result, const char[] error, any data)
{
    if ( result == null )
    {
        LogError("Failed to count players in stat (error: %s)", error);
        return;
    }
    int count = 0;
    if ( result.FetchRow() )
    {
        count = result.FetchInt(0);
    }
    TotalWinners = count;
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] Found %i winners in the rank table", TotalWinners);
    #endif

    LoadTopRankData();
}

// threaded
void LoadTopRankData()
{
    if ( !g_cfgHandicapTopRank )
    {
        g_cfgHandicapTopWins = 0;
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] Handicap top wins = 0 (handicap top rank is disabled)");
        #endif
        Call_StartForward(FwdLoadRank);
        Call_Finish();
        return;
    }

    if ( g_cfgHandicapTopRank >= TotalWinners )
    {
        g_cfgHandicapTopWins = 1;
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] Handicap top wins = 1 (handicap top rank is more then total winners)");
        #endif
        Call_StartForward(FwdLoadRank);
        Call_Finish();
        return;
    }

    char query[1024];
    Format(query, sizeof(query), g_sql_getTopPlayers, 1, g_cfgHandicapTopRank - 1);
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", query);
    #endif
    g_DbConnection.Query(T_LoadTopRankData, query);
}

public void T_LoadTopRankData(Database owner, DBResultSet result, const char[] error, any data)
{
    if ( result == null )
    {
        LogError("Failed to load rank data (error: %s)", error);
        g_cfgHandicapTopWins = 0;
        Call_StartForward(FwdLoadRank);
        Call_Finish();
        return;
    }

    if ( result.FetchRow() )
    {
        g_cfgHandicapTopWins = result.FetchInt(1);
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] Handicap top wins = %i", g_cfgHandicapTopWins);
        #endif
    }
    else
    {
        g_cfgHandicapTopWins = 0;
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] Handicap top wins = 0 (cant fetch rows from sql)");
        #endif
    }

    Call_StartForward(FwdLoadRank);
    Call_Finish();
}

// threaded
void ShowRank(int client)
{
    int wins = PlayerWinsData[client];
    if ( !wins || PlayerPlaceData[client] )
    {
        ShowRankInChat(client);
        return;
    }

    char query[1024];
    Format(query, sizeof(query), g_sql_getPlayerPlaceByWins, wins);
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", query);
    #endif
    g_DbConnection.Query(T_ShowRank, query, client);
}

public void T_ShowRank(Database owner, DBResultSet result, const char[] error, any client)
{
    /* Make sure the client didn't disconnect while the thread was running */
    if ( !IsClientConnected(client) )
    {
        return;
    }
    if ( result == null )
    {
        LogError("Failed to retrieve player place by wins (error: %s)", error);
        return;
    }
    if ( result.FetchRow() )
    {
        PlayerPlaceData[client] = result.FetchInt(0) + 1;
    }
    ShowRankInChat(client);
}

void ShowRankInChat(int client)
{
    char name[MAX_NAME_SIZE];
    GetClientName(client, name, sizeof(name));
    if ( !PlayerPlaceData[client] )
    {
        CPrintToChatAllEx(client, "%t", "Rank: not ranked", name);
    }
    else
    {
        for ( int i = 1; i <= MaxClients; i++ )
        {
            if ( IsClientInGame(i) && !IsFakeClient(i) )
            {
                char subtext[64];
                SetGlobalTransTarget(i);
                FormatLanguageNumberTextEx(i, subtext, sizeof(subtext), PlayerWinsData[client], "with wins");
                CPrintToChatEx(i, client, "%t", "Rank: rank", name, PlayerPlaceData[client], subtext, TotalWinners);
            }
        }
    }
}


bool IsPlayerInTopRank(int client)
{
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] IsPlayerInTopRank client=%i", client);
    #endif
    if ( !g_cfgHandicapTopWins )
    {
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] ... false (top rank handicap wins not loaded)");
        #endif
        return false;
    }
    if ( PlayerWinsData[client] < g_cfgHandicapTopWins )
    {
        #if defined SQL_DEBUG
            LogError("[DEBUG-SQL] ... false (player wins less then top rank handicap wins)");
        #endif
        return false;
    }
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] ... true (player wins more or equal to top rank handicap wins)");
    #endif
    return true;
}
