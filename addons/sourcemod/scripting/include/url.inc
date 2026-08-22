#if defined _url_included_
  #endinput
#endif
#define _url_included_

static const char HEXCHARS[17] = "0123456789ABCDEF";

void url_encode(const char[] strFrom, int lenFrom, char[] strTo, int lenTo)
{
    int c;
    int to = 0, from = 0;
    char[] strTmp = new char[lenFrom*3+1];

    while ( from < lenFrom ) {
        c = strFrom[from++];
        if ( c == '\0' ) {
            break;
        } else if ( c == ' ' ) {
            strTmp[to++] = '+';
        } else if ( IsCharAlpha(c) || IsCharNumeric(c) || ('_' == c) || ('-' == c) || ('.' == c) ) {
            strTmp[to++] = c;
        } else {
            strTmp[to++] = '%';
            strTmp[to++] = HEXCHARS[c >> 4];
            strTmp[to++] = HEXCHARS[c & 15];
        }
    }
    strTmp[to] = '\0';
    strcopy(strTo, lenTo, strTmp);
}
