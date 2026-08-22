// threaded
void DisplayTopMenu(int client)
{
    int offset, itemsOnPage = 10;
    offset = ClientOnPage[client] * itemsOnPage;

    if ( ( offset < 0 ) || ( offset >= TotalWinners ) ) {
        offset = 0;
        ClientOnPage[client] = 0;
    }
    char query[1024];
    Format(query, sizeof(query), g_sql_getTopPlayers, itemsOnPage, offset);
    #if defined SQL_DEBUG
        LogError("[DEBUG-SQL] %s", query);
    #endif
    g_DbConnection.Query(T_DisplayTopMenu, query, client);
}

public void T_DisplayTopMenu(Database owner, DBResultSet result, const char[] error, any client)
{
    if ( !IsClientConnected(client) )
    {
        return;
    }
    if ( result == null )
    {
        LogError("Failed to retrieve top players (error: %s)", error);
        return;
    }

    int offset, itemsOnPage = 10;
    offset = ClientOnPage[client] * itemsOnPage;

    if ( ( offset < 0 ) || ( offset >= TotalWinners ) ) {
        offset = 0;
        ClientOnPage[client] = 0;
    }

    int end, pages;
    end = offset + itemsOnPage;
    if ( end > TotalWinners ) {
        end = TotalWinners;
    }
    pages = RoundToCeil(float(TotalWinners)/float(itemsOnPage));

    SetGlobalTransTarget(client);
    char text[256];

    Panel menu = CreatePanel();

    if ( TotalWinners )
    {
        Format(text, sizeof(text), "%t", "TopPanel: Top", offset + 1, end, TotalWinners);
        menu.SetTitle(text);
        menu.DrawText(BLANK_SPACE);

        Format(text, sizeof(text), "%t", "Panel: Page", ClientOnPage[client] + 1, pages);
        menu.DrawText(text);
        menu.DrawText(BLANK_SPACE);

        int i = offset;
        char name[MAX_NAME_SIZE], subtext[64];
        int wins;
        while ( result.FetchRow() )
        {
            wins = result.FetchInt(1);
            result.FetchString(2, name, sizeof(name));
            FormatLanguageNumberTextEx(client, subtext, sizeof(subtext), wins, "wins");
            if ( ++i < 4 )
            {
                Format(text, sizeof(text), "%t", "TopPanel: Name Wins", name, subtext);
                menu.DrawItem(text);
            }
            else
            {
                Format(text, sizeof(text), "%t", "TopPanel: Place Name Wins", i, name, subtext);
                menu.DrawText(text);
            }
        }
    }
    else
    {
        Format(text, sizeof(text), "%t", "TopPanel: Top short");
        menu.SetTitle(text);
        menu.DrawText(BLANK_SPACE);

        Format(text, sizeof(text), "%t", "TopPanel: There are currently no players in the top");
        menu.DrawItem(text);
    }

    menu.DrawText(BLANK_SPACE);
    menu.CurrentKey = 8;

    if ( offset == 0 ) {
        menu.CurrentKey = 9;
    } else {
        Format(text, sizeof(text), "%t", "Panel: Back");
        menu.DrawItem(text, ITEMDRAW_CONTROL);
    }
    if ( end == TotalWinners ) {
        menu.CurrentKey = 10;
    } else {
        Format(text, sizeof(text), "%t", "Panel: Next");
        menu.DrawItem(text, ITEMDRAW_CONTROL);
    }
    Format(text, sizeof(text), "%t", "Panel: Exit");
    menu.DrawItem(text, ITEMDRAW_CONTROL);

    menu.Send(client, TopMenuHandler, GUNGAME_MENU_TIME);
    delete menu;
}

public int TopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if ( action == MenuAction_Select )
    {
        switch(param2)
        {
            case 8:
            {
                --ClientOnPage[param1];
                DisplayTopMenu(param1);
            }
            case 9:
            {
                ++ClientOnPage[param1];
                DisplayTopMenu(param1);
            }
        }
    }

    return 0;
}


void ShowTopMenu(int client)
{
    ClientOnPage[client] = 0;
    DisplayTopMenu(client);
}
