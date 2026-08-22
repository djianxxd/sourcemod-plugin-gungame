public void GG_ConfigNewSection(const char[] NewSection)
{
    if ( strcmp(NewSection, "Config", false) == 0 )
    {
        ConfigState = CONFIG_STATE_CONFIG;
    }
}

public void GG_ConfigKeyValue(const char[] Key, const char[] Value)
{
    if ( ConfigState == CONFIG_STATE_CONFIG )
    {
        if ( strcmp(Key, "Prune", false) == 0 ) {
            Prune = StringToInt(Value);
        } else if ( strcmp(Key, "HandicapTopRank", false) == 0 ) {
            g_cfgHandicapTopRank = StringToInt(Value);
        } else if ( strcmp(Key, "DontAddWinsOnBot", false) == 0 ) {
            g_Cfg_DontAddWinsOnBot = view_as<bool>(StringToInt(Value));
        }
    }
}

public void GG_ConfigParseEnd()
{
    ConfigState = CONFIG_STATE_NONE;
}
