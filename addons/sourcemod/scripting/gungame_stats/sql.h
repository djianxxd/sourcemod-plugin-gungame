enum DbType
{
    DbTypeSqlite,
    DbTypeMysql,
    DbTypePgsql,
    MaxDbTypes
};

DbType g_DbType;
Database g_DbConnection;

char g_sql_createPlayerTable[MaxDbTypes][512]   =
{
    "CREATE TABLE IF NOT EXISTS gungame_playerdata (   id INTEGER PRIMARY KEY AUTOINCREMENT, wins int(12) NOT NULL default 0, authid varchar(255) NOT NULL default '', name varchar(255) NOT NULL default '', timestamp timestamp NOT NULL default CURRENT_TIMESTAMP );",
    "CREATE TABLE IF NOT EXISTS `gungame_playerdata`(`id` int(11) NOT NULL auto_increment,`wins` int(12) NOT NULL default '0',`authid` varchar(255) NOT NULL default '',`name` varchar(255) NOT NULL default '',`timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP,PRIMARY KEY  (`id`),KEY `wins` (`wins`),KEY `authid` (`authid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;",
    "CREATE TABLE gungame_playerdata (id serial, wins int NOT NULL default 0, authid varchar(255) NOT NULL default '', name  varchar(255) NOT NULL default '', timestamp timestamp NOT NULL default CURRENT_TIMESTAMP, PRIMARY KEY (id));"
};
char g_sql_createPlayerTableIndex1[MaxDbTypes][128]  =
{
    "CREATE INDEX wins ON gungame_playerdata(wins);",
    "",
    "CREATE INDEX gg_playerdata_wins ON gungame_playerdata(wins);"
};
char g_sql_createPlayerTableIndex2[MaxDbTypes][128]  =
{
    "CREATE INDEX authid ON gungame_playerdata(authid);",
    "",
    "CREATE INDEX gg_playerdata_authid ON gungame_playerdata(authid);"
};
char g_sql_checkTableExists[MaxDbTypes][128]    =
{
    "SELECT name FROM sqlite_master WHERE name = 'gungame_playerdata';",
    "SHOW TABLES like 'gungame_playerdata';",
    "SELECT table_name FROM information_schema.tables WHERE table_name = 'gungame_playerdata';"
};
char g_sql_dropPlayerTable[96]      = "DROP TABLE IF EXISTS gungame_playerdata;";

char g_sql_insertPlayer[160]         = "INSERT INTO gungame_playerdata (wins, name, timestamp, authid) VALUES (%i, '%s', current_timestamp, '%s');";
char g_sql_updatePlayerByAuth[160]   = "UPDATE gungame_playerdata SET wins = %i, name = '%s', timestamp = current_timestamp WHERE authid = '%s';";
char g_sql_getPlayerPlaceByWins[96] = "SELECT count(*) FROM gungame_playerdata WHERE wins > %i;";
char g_sql_getPlayersCount[64]      = "SELECT count(*) FROM gungame_playerdata;";
char g_sql_getPlayerByAuth[128]      = "SELECT id, wins, name FROM gungame_playerdata WHERE authid = '%s';";
char g_sql_updatePlayerTsById[96]   = "UPDATE gungame_playerdata SET timestamp = current_timestamp WHERE id = %i;";
char g_sql_getTopPlayers[160]        = "SELECT id, wins, name, authid FROM gungame_playerdata ORDER by wins desc, id LIMIT %i OFFSET %i;";

char g_sql_prunePlayers[MaxDbTypes][128]    =
{
    "DELETE FROM gungame_playerdata WHERE timestamp < %i;",
    "DELETE FROM gungame_playerdata WHERE timestamp < current_timestamp - interval %i day;",
    "DELETE FROM gungame_playerdata WHERE timestamp < current_timestamp - interval '%i day';"
};
