void OnCreateNatives()
{
    CreateNative("GG_DisplayTop", __DisplayTop);
    CreateNative("GG_GetClientWins", __GetPlayerWins);
    CreateNative("GG_CountPlayersInStat", __CountPlayersInStat);
    CreateNative("GG_GetPlayerPlaceInStat", __GetPlayerPlaceInStat);
    CreateNative("GG_IsPlayerInTopRank", __IsPlayerInTopRank);
    CreateNative("GG_IsPlayerWinsLoaded", __IsPlayerWinsLoaded);
    CreateNative("GG_ShowRank", __ShowRank);
}

public int __DisplayTop(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(client < 1 || client > MaxClients)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index [%d]", client);
    } else if(!IsClientInGame(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client is not currently ingame [%d]", client);
    }

    ShowTopMenu(client);
    return 1;
}

public int __ShowRank(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(client < 1 || client > MaxClients)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index [%d]", client);
    } else if(!IsClientInGame(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client is not currently ingame [%d]", client);
    }

    ShowRank(client);
    return 1;
}

public int __GetPlayerPlaceInStat(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(client < 1 || client > MaxClients)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index [%d]", client);
    } else if(!IsClientInGame(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client is not currently ingame [%d]", client);
    }

    return GetPlayerPlaceInStat(client);
}

public int __CountPlayersInStat(Handle plugin, int numParams)
{
    return CountPlayersInStat();
}

public int __GetPlayerWins(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(client < 1 || client > MaxClients)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index [%d]", client);
    } else if(!IsClientInGame(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client is not currently ingame [%d]", client);
    }

    return PlayerWinsData[client];
}

public int __IsPlayerInTopRank(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(client < 1 || client > MaxClients)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index [%d]", client);
    } else if(!IsClientInGame(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client is not currently ingame [%d]", client);
    }

    return IsPlayerInTopRank(client);
}

public int __IsPlayerWinsLoaded(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(client < 1 || client > MaxClients)
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index [%d]", client);
    } else if(!IsClientInGame(client)) {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client is not currently ingame [%d]", client);
    }

    return g_PlayerWinsLoaded[client];
}
