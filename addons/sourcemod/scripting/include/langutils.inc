#if defined _langutils_included_
  #endinput
#endif
#define _langutils_included_

void FormatLanguageNumberTextEx(int client, char[] text, int size, int number, const char[] tplName)
{
    SetGlobalTransTarget(client);
    char tpl[64];
    int num10 = number % 10;
    int num100 = number % 100;

    if ( number == 1 ) {
        Format(tpl, sizeof(tpl), "1>%s", tplName);
    } else if ( (num10 == 1) && (num100 != 11) ) {
        Format(tpl, sizeof(tpl), "x1>%s", tplName);
    } else if ( (num10 >= 2) && (num10 <= 4) && ((num100 < 12) || (num100 > 14)) ) {
        Format(tpl, sizeof(tpl), "x2-x4>%s", tplName);
    } else {
        Format(tpl, sizeof(tpl), "x5-x20>%s", tplName);
    }
    Format(text, size, "%t", tpl, number);
}
