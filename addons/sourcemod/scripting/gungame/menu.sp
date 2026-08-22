/**
 * Menu
 */

public int CommandPanelHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: /* !level */
                CreateLevelPanel(client);
            case 2: /* !weapons */
                ShowWeaponLevelPanel(client);
            case 3: /* !score */
                ShowPlayerLevelMenu(client);
            case 4: /* !top */
            {
                if ( StatsEnabled )
                {
                    GG_DisplayTop(client); /* HINT: gungame_stats */
                }
                else
                {
                    CPrintToChat(client, "%t", "GunGame Stats is disabled");
                }
            }
            case 5: /* !leader */
                ShowLeaderMenu(client);
            case 6: /* !rank */
            {
                if ( StatsEnabled )
                {
                    GG_ShowRank(client); /* HINT: gungame_stats */
                }
                else
                {
                    CPrintToChat(client, "%t", "GunGame Stats is disabled");
                }
            }
            case 7: /* !rules */
                ShowRulesMenu(client);
        }
    }
    return 0;
}

public int ScoreCommandPanelHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        switch(param2)
        {
            case 2: /* !top */
            {
                if ( StatsEnabled )
                {
                    GG_DisplayTop(client); /* HINT: gungame_stats */
                }
            }
            case 3: /* !leader */
                ShowLeaderMenu(client);
            case 4: /* !score */
                ShowPlayerLevelMenu(client);
        }
    }
    return 0;
}

public int EmptyPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
    /* Don't care what they pressed. */
    return 0;
}

void CreateLevelPanel(int client)
{
    SetGlobalTransTarget(client);
    char text[256];
    char subtext[64];

    Panel LevelPanel = new Panel();
    Format(text, sizeof(text), "%t", "LevelPanel: Level Information");
    LevelPanel.SetTitle(text);
    LevelPanel.DrawItem(BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

    int Level = PlayerLevel[client],
        killsPerLevel = UTIL_GetCustomKillPerLevel(Level);

    Format(text, sizeof(text), "%t", "LevelPanel: Level");
    LevelPanel.DrawItem(text);
    Format(text, sizeof(text), "%t", "LevelPanel: You are on level",
        Level + 1, WeaponOrderName[Level], CurrentKillsPerWeap[client], killsPerLevel);
    LevelPanel.DrawText(text);

    if ( CurrentLeader == client )
    {
        Format(text, sizeof(text), "%t", "LevelPanel: You are currently the leader");
        LevelPanel.DrawText(text);
        LevelPanel.DrawText(BLANK_SPACE);
    } else {
        LevelPanel.DrawItem(BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    }

    Format(text, sizeof(text), "%t", "LevelPanel: Wins");
    LevelPanel.DrawItem(text);

    if ( StatsEnabled )
    {
        FormatLanguageNumberTextEx(client, subtext, sizeof(subtext),
            GG_GetClientWins(client), /* HINT: gungame_stats */
            "times"
        );
        Format(text, sizeof(text), "%t", "LevelPanel: You have won times", subtext);
        LevelPanel.DrawText(text);
    }
    else
    {
        Format(text, sizeof(text), "%t", "GunGame Stats is disabled");
        CRemoveTags(text, sizeof(text));
        LevelPanel.DrawText(text);
    }
    LevelPanel.DrawText(BLANK_SPACE);

    Format(text, sizeof(text), "%t", "LevelPanel: Leader");
    LevelPanel.DrawItem(text);

    if ( CurrentLeader && IsClientInGame(CurrentLeader) )
    {
        int level = PlayerLevel[CurrentLeader];

        if ( level )
        {
            char Name[64];
            GetClientName(CurrentLeader, Name, sizeof(Name));
            Format(text, sizeof(text), "%t", "LevelPanel: The current leader is on level", Name, level + 1, WeaponOrderName[level]);
            LevelPanel.DrawText(text);
            if ( CurrentLeader != client )
            {
                if ( level == Level )
                {
                    Format(text, sizeof(text), "%t", "LevelPanel: You have tied with the leader");
                    LevelPanel.DrawText(text);
                }
                else if ( level > Level )
                {
                    FormatLanguageNumberTextEx(client, subtext, sizeof(subtext), level - Level, "levels");
                    CRemoveTags(subtext, sizeof(subtext));
                    Format(text, sizeof(text), "%t", "LevelPanel: You are levels from the leader", subtext);
                    LevelPanel.DrawText(text);
                }
            }
        } else {
            Format(text, sizeof(text), "%t", "LevelPanel: There is currently no leader");
            LevelPanel.DrawText(text);
        }
    } else {
        Format(text, sizeof(text), "%t", "LevelPanel: There is currently no leader");
        LevelPanel.DrawText(text);
    }

    LevelPanel.DrawItem(BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    LevelPanel.CurrentKey = 4;
    Format(text, sizeof(text), "%t", "LevelPanel: Scores");
    LevelPanel.DrawItem(text, ITEMDRAW_CONTROL);
    Format(text, sizeof(text), "%t", "LevelPanel: Press 4 to show scores");
    LevelPanel.DrawText(text);

    LevelPanel.DrawItem(BLANK, ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
    LevelPanel.CurrentKey = 9;
    Format(text, sizeof(text), "%t", "Panel: Exit");
    LevelPanel.DrawItem(text, ITEMDRAW_CONTROL);

    LevelPanel.Send(client, ScoreCommandPanelHandler, GUNGAME_MENU_TIME);
    delete LevelPanel;
}

void ShowPlayerLevelMenu(int client)
{
    SetGlobalTransTarget(client);
    char text[256];
    char subtext[64];

    Menu menu = new Menu(EmptyMenuHandler);
    char Name[64];

    Format(text, sizeof(text), "%t", "PlayersLevelPanel: Players level information");
    menu.SetTitle(text);
    SetGlobalTransTarget(client);

    int counter = -1;
    for ( int i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientInGame(i) )
        {
            GetClientName(i, Name, sizeof(Name));
            if ( StatsEnabled )
            {
                FormatLanguageNumberTextEx(client, subtext, sizeof(subtext),
                    GG_GetClientWins(i), /* HINT: gungame_stats */
                    "wins"
                );
                Format(text, sizeof(text), "%t", "PlayersLevelPanel: Level Wins Name", PlayerLevel[i] + 1, subtext, Name, WeaponOrderName[PlayerLevel[i]]);
            }
            else
            {
                Format(text, sizeof(text), "%t", "PlayersLevelPanel: Level Name", PlayerLevel[i] + 1, Name, WeaponOrderName[PlayerLevel[i]]);
            }
            menu.AddItem(BLANK, text, ++counter%7? ITEMDRAW_DISABLED: ITEMDRAW_DEFAULT);
        }
    }

    menu.Display(client, GUNGAME_MENU_TIME);
}

void ShowLeaderMenu(int client)
{
    SetGlobalTransTarget(client);
    char text[256];

    Menu menu = new Menu(EmptyMenuHandler);
    char Name[64];

    if ( CurrentLeader ) {
        Format(text, sizeof(text), "%t%t", "LeaderMenu: Leaders", "LeaderMenu: Leader level and weapon", PlayerLevel[CurrentLeader] + 1, WeaponOrderName[PlayerLevel[CurrentLeader]]);
    } else {
        Format(text, sizeof(text), "%t", "LeaderMenu: Leaders");
    }
    menu.SetTitle(text);
    SetGlobalTransTarget(client);

    int counter = -1;
    if ( CurrentLeader )
    {
        int level = PlayerLevel[CurrentLeader];
        for ( int i = 1; i <= MaxClients; i++ )
        {
            if ( IsClientInGame(i) && PlayerLevel[i] == level )
            {
                GetClientName(i, Name, sizeof(Name));
                menu.AddItem(BLANK, Name, ++counter%7? ITEMDRAW_DISABLED: ITEMDRAW_DEFAULT);
            }
        }
    }
    else
    {
        Format(text, sizeof(text), "%t", "LeaderMenu: No leaders");
        menu.AddItem(BLANK, text, ++counter%7? ITEMDRAW_DISABLED: ITEMDRAW_DEFAULT);
    }

    menu.Display(client, GUNGAME_MENU_TIME);
}

public int EmptyMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if ( action == MenuAction_End )
    {
        delete menu;
    }
    return 0;
}


/* Move into a real menu */
void ShowJoinMsgPanel(int client)
{
    SetGlobalTransTarget(client);
    char text[256];
    Panel faluco = new Panel();
    int Count;

    Format(text, sizeof(text), "%t", "JoinPanel: This server is running the GunGame:SM");
    faluco.SetTitle(text);
    faluco.DrawText(BLANK_SPACE);

    if(BotCanWin)
    {
        Format(text, sizeof(text), "%t", "JoinPanel: Bots can win the game is ENABLED!!");
        faluco.DrawText(text);
        Count++;
    }

    if(TurboMode)
    {
        Format(text, sizeof(text), "%t", "JoinPanel: Turbo Mode is ENABLED!!");
        faluco.DrawText(text);
        Count++;
    }

    if(KnifePro)
    {
        Format(text, sizeof(text), "%t", "JoinPanel: Knife Pro is ENABLED!!");
        faluco.DrawText(text);
        Count++;
    }

    if(KnifeElite)
    {
        Format(text, sizeof(text), "%t", "JoinPanel: Knife Elite is ENABLED!!");
        faluco.DrawText(text);
        Count++;
    }

    if(MinKillsPerLevel > 1)
    {
        Format(text, sizeof(text), "%t", "JoinPanel: Multikill Mode is ENABLED!!");
        faluco.DrawText(text);
        Count++;
    }

    if(Count)
    {
        faluco.DrawText(BLANK_SPACE);
    }

    Format(text, sizeof(text), "%t", "JoinPanel: Type !rules for instructions on how to play");
    faluco.DrawText(text);
    Format(text, sizeof(text), "%t", "JoinPanel: Type !level to get your level info and who is leading");
    faluco.DrawText(text);
    Format(text, sizeof(text), "%t", "JoinPanel: Type !score to get a list of all players scores and winnings");
    faluco.DrawText(text);
    Format(text, sizeof(text), "%t", "JoinPanel: Type !commands to get a full list of gungame commands");
    faluco.DrawText(text);

    faluco.DrawText(BLANK_SPACE);
    Format(text, sizeof(text), "%t", "Panel: Exit");
    faluco.DrawItem(text, ITEMDRAW_CONTROL);

    faluco.Send(client, EmptyPanelHandler, GUNGAME_MENU_TIME);
    delete faluco;
}

void ShowCommandPanel(int client)
{
    SetGlobalTransTarget(client);
    char text[256];
    Panel Ham = new Panel();
    Format(text, sizeof(text), "%t", "CommandPanel: [GunGame] Command list information");
    Ham.SetTitle(text);
    Ham.DrawText(BLANK_SPACE);
    Format(text, sizeof(text), "%t", "CommandPanel: !level to see your current level and who is winning");
    Ham.DrawItem(text);
    Format(text, sizeof(text), "%t", "CommandPanel: !weapons to see the weapon order");
    Ham.DrawItem(text);
    Format(text, sizeof(text), "%t", "CommandPanel: !score to see all player current scores");
    Ham.DrawItem(text);
    Format(text, sizeof(text), "%t", "CommandPanel: !top to see the top winners on the server");
    Ham.DrawItem(text);
    Format(text, sizeof(text), "%t", "CommandPanel: !leader to see current leaders");
    Ham.DrawItem(text);
    Format(text, sizeof(text), "%t", "CommandPanel: !rank to see your place in stats");
    Ham.DrawItem(text);
    Format(text, sizeof(text), "%t", "CommandPanel: !rules to see the rules and how to play");
    Ham.DrawItem(text);
    Ham.DrawItem(BLANK, ITEMDRAW_SPACER);

    Ham.CurrentKey = 9;
    Format(text, sizeof(text), "%t", "Panel: Exit");
    Ham.DrawItem(text);

    Ham.Send(client, CommandPanelHandler, GUNGAME_MENU_TIME);
    delete Ham;
}

void ShowWeaponLevelPanel(int client)
{
    ClientOnPage[client] = 0;
    DisplayWeaponLevelPanel(client);
}

void DisplayWeaponLevelPanel(int client)
{
    SetGlobalTransTarget(client);
    char text[256];
    Panel Ham = new Panel();

    Format(text, sizeof(text), "%t", "WeaponLevelPanel: [GunGame] Weapon Levels");
    Ham.SetTitle(text);
    Ham.DrawText(BLANK_SPACE);

    for ( int i = ClientOnPage[client] * 7, end = i + 7; i < end; i++ )
    {
        if ( i < WeaponOrderCount )
        {
            Format(text, sizeof(text), "%t", "WeaponLevelPanel: Order Weapon Kills", i + 1, WeaponOrderName[i], UTIL_GetCustomKillPerLevel(i));
            Ham.DrawText(text);
        }
    }

    Ham.DrawText(BLANK_SPACE);
    Ham.CurrentKey = 7;

    Format(text, sizeof(text), "%t", "Panel: Back");
    Ham.DrawItem(text, ITEMDRAW_CONTROL);
    Format(text, sizeof(text), "%t", "Panel: Next");
    Ham.DrawItem(text, ITEMDRAW_CONTROL);
    Format(text, sizeof(text), "%t", "Panel: Exit");
    Ham.DrawItem(text, ITEMDRAW_CONTROL);

    Ham.Send(client, WeaponMenuHandler, GUNGAME_MENU_TIME);
    delete Ham;
}

public int WeaponMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 7:
            {
                if(--ClientOnPage[param1] < 0)
                {
                    ClientOnPage[param1] = WeaponLevelPages - 1;
                }

                DisplayWeaponLevelPanel(param1);
            }
            case 8:
            {
                if(++ClientOnPage[param1] >= WeaponLevelPages)
                {
                    ClientOnPage[param1] = 0;
                }

                DisplayWeaponLevelPanel(param1);
            }
        }
    }
    return 0;
}

void ShowRulesMenu(int client)
{
    ClientOnPage[client] = 0;
    DisplayRulesMenu(client);
}

public int RulesMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 7:
            {
                --ClientOnPage[param1];
                DisplayRulesMenu(param1);
            }
            case 8:
            {
                ++ClientOnPage[param1];
                DisplayRulesMenu(param1);
            }
        }
    }
    return 0;
}

void DisplayRulesMenu(int client)
{
    SetGlobalTransTarget(client);
    char text[256];
    char subtext[64];

    Panel menu = new Panel();
    Format(text, sizeof(text), "%t", "RulesPanel: [GunGame] Rules information");
    menu.SetTitle(text);
    menu.DrawText(BLANK_SPACE);

    int itemsCount = 4;
    if ( ObjectiveBonus )       itemsCount++;
    if ( AutoFriendlyFire )     itemsCount++;
    if ( MaxLevelPerRound > 1 ) itemsCount++;
    if ( KnifePro )             itemsCount++;
    if ( KnifeElite )           itemsCount++;
    if ( TurboMode )            itemsCount++;
    if ( CommitSuicide )        itemsCount++;

    int itemsOnPage = 3;
    int pagesCount  = (itemsCount - 1)/itemsOnPage + 1;

    if ( ClientOnPage[client] < 0 )             ClientOnPage[client] = pagesCount - 1;
    if ( ClientOnPage[client] >= pagesCount )   ClientOnPage[client] = 0;
    int itemStart   = ClientOnPage[client] * itemsOnPage + 1;
    int itemEnd     = itemStart + itemsOnPage - 1;

    Format(text, sizeof(text), "%t", "RulesPanel: Page", ClientOnPage[client] + 1, pagesCount);
    menu.DrawText(text);
    menu.DrawText(BLANK_SPACE);

    int item = 0;
    if ( (++item >= itemStart) && (itemEnd <= itemEnd) ) {
        FormatLanguageNumberTextEx(client, subtext, sizeof(subtext), MinKillsPerLevel, "points");
        CRemoveTags(subtext, sizeof(subtext));
        Format(text, sizeof(text), "%t", "RulesPanel: You must get kills with your current weapon to level up", subtext);
        menu.DrawText(text);
    }

    if ( (++item >= itemStart) && (itemEnd <= itemEnd) ) {
        Format(text, sizeof(text), "%t", "RulesPanel: If you get a kill with a weapon out of order. It does not count towards your level");
        menu.DrawText(text);
    }

    /**
     * How to propertly explain Custom Weapon Level to the player?
     * If a custom minimum kill has been set for a perticular weapon. You need to need to kill x number of players with that weapon before you can level.
     * To wordy? Bad Sentence? Think of a shorter and clearer sentence.
     */

    if ( ObjectiveBonus && (++item >= itemStart) && (item <= itemEnd) ) {
        FormatLanguageNumberTextEx(client, subtext, sizeof(subtext), ObjectiveBonus, "levels");
        CRemoveTags(subtext, sizeof(subtext));
        if ( g_Cfg_ObjectiveBonusExplode ) {
            Format(text, sizeof(text), "%t", "RulesPanel: You can gain level by EXPLODING or DEFUSING the bomb", subtext);
        } else {
            Format(text, sizeof(text), "%t", "RulesPanel: You can gain level by PLANTING or DEFUSING the bomb", subtext);
        }
        menu.DrawText(text);
    }

    if ( AutoFriendlyFire && (++item >= itemStart) && (item <= itemEnd) ) {
        Format(text, sizeof(text), "%t", "RulesPanel: Friendly Fire is automatically turned ON when someone reaches GRENADE level");
        menu.DrawText(text);
    }

    if ( (MaxLevelPerRound > 1) && (++item >= itemStart) && (item <= itemEnd) ) {
        Format(text, sizeof(text), "%t", "RulesPanel: You CAN gained more than one level per round");
        menu.DrawText(text);
    }

    if ( KnifePro && (++item >= itemStart) && (item <= itemEnd) ) {
        Format(text, sizeof(text), "%t", "RulesPanel: You can steal a level from an opponent by knifing them");
        menu.DrawText(text);
    }

    if ( KnifeElite && (++item >= itemStart) && (item <= itemEnd) ) {
        Format(text, sizeof(text), "%t", "RulesPanel: After you levelup, you will only have a knife until the next round starts");
        menu.DrawText(text);
    }

    if ( TurboMode && (++item >= itemStart) && (item <= itemEnd) ) {
        Format(text, sizeof(text), "%t", "RulesPanel: You will receive your next weapon immediately when you level up");
        menu.DrawText(text);
    }

    if ( CommitSuicide && (++item >= itemStart) && (item <= itemEnd) ) {

        FormatLanguageNumberTextEx(client, subtext, sizeof(subtext), CommitSuicide, "levels");
        CRemoveTags(subtext, sizeof(subtext));
        Format(text, sizeof(text), "%t", "RulesPanel: If you commit suicide you will lose levels", subtext);
        menu.DrawText(text);
    }

    if ( (++item >= itemStart) && (item <= itemEnd) ) {
        Format(text, sizeof(text), "%t", "RulesPanel: There is a grace period at the end of each round to allow players to switch teams");
        menu.DrawText(text);
    }

    if ( (++item >= itemStart) && (item <= itemEnd) ) {
        Format(text, sizeof(text), "%t", "RulesPanel: Type !commands to see the list of gungame commands");
        menu.DrawText(text);
    }

    menu.DrawText(BLANK_SPACE);
    menu.CurrentKey = 7;

    Format(text, sizeof(text), "%t", "Panel: Back");
    menu.DrawItem(text, ITEMDRAW_CONTROL);
    Format(text, sizeof(text), "%t", "Panel: Next");
    menu.DrawItem(text, ITEMDRAW_CONTROL);
    Format(text, sizeof(text), "%t", "Panel: Exit");
    menu.DrawItem(text, ITEMDRAW_CONTROL);

    menu.Send(client, RulesMenuHandler, GUNGAME_MENU_TIME);
    delete menu;
}
