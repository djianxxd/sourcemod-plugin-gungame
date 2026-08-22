/**
 * Reads gunagme system config file.
 */
void OnKeyValueStart()
{
    /* Make sure to use unique section name just incase someone else uses it */
    KvWeapon = CreateKeyValues("gg_WeaponInfo", BLANK, BLANK);
    if (g_GameName == Css) {
        FormatEx(WeaponFile, sizeof(WeaponFile), "cfg\\gungame\\css\\weaponinfo.txt");
    } else if (g_GameName == Csgo) {
        FormatEx(WeaponFile, sizeof(WeaponFile), "cfg\\gungame\\csgo\\weaponinfo.txt");
    }

    if ( !FileExists(WeaponFile) )
    {
        char Error[PLATFORM_MAX_PATH + 64];
        FormatEx(Error, sizeof(Error), "FATAL ERROR File does not exists [%s]", WeaponFile);
        SetFailState("%s", Error);
    }

    WeaponOpen = KvWeapon.ImportFromFile(WeaponFile);

    if ( TrieWeapon == null )
    {
        TrieWeapon = new StringMap();
    }
    else
    {
        TrieWeapon.Clear();
    }

    if ( !WeaponOpen )
    {
        return;
    }

    KvWeapon.Rewind();

    if ( !KvWeapon.GotoFirstSubKey() )
    {
        return;
    }

    char name[MAX_WEAPON_NAME_LEN];
    int index;
    g_WeaponsMaxId          = 0;
    g_WeaponIdKnife         = 0;
    g_WeaponIdHegrenade     = 0;
    g_WeaponIdSmokegrenade  = 0;
    g_WeaponIdFlashbang     = 0;
    g_WeaponIdTaser         = 0;

    g_WeaponAmmoTypeHegrenade       = 0;
    g_WeaponAmmoTypeFlashbang       = 0;
    g_WeaponAmmoTypeSmokegrenade    = 0;
    g_WeaponAmmoTypeMolotov         = 0;
    g_WeaponAmmoTypeTaser           = 0;

    for (;;) {
        if ( !KvWeapon.GetSectionName(name, sizeof(name)) ) {
            break;
        }

        index = KvWeapon.GetNum("index");
        UTIL_StringToLower(name);

        // init weapons by name array
        TrieWeapon.SetValue(name, index);
        // init weapons count
        g_WeaponsMaxId++;
        // init weapons full names (to use in give commands)
        FormatEx(g_WeaponName[index], sizeof(g_WeaponName[]), "weapon_%s", name);
        // init weapons slots
        g_WeaponSlot[index] = view_as<Slots>(KvWeapon.GetNum("slot", 0));
        // init weapons clip size
        g_WeaponAmmo[index] = KvWeapon.GetNum("clipsize", 0);
        // init weapons that need drop knife
        g_WeaponDropKnife[index] = view_as<bool>(KvWeapon.GetNum("drop_knife", 0));
        // level index (different weapons but the same level)
        g_WeaponLevelIndex[index] = KvWeapon.GetNum("level_index", 0);

        if (!g_WeaponLevelIndex[index]) {
            char Error[1024];
            FormatEx(Error, sizeof(Error), "FATAL ERROR: Level index should not be zero for %s. You should update you %s and take it from the release zip file.",
                name, WeaponFile);
            SetFailState("%s", Error);
        }

        if (KvWeapon.GetNum("is_knife", 0)) {
            g_WeaponIdKnife                 = index;
            g_WeaponLevelIdKnife            = g_WeaponLevelIndex[index];
        } else if (KvWeapon.GetNum("is_hegrenade", 0)) {
            g_WeaponIdHegrenade             = index;
            g_WeaponLevelIdHegrenade        = g_WeaponLevelIndex[index];
            g_WeaponAmmoTypeHegrenade       = KvWeapon.GetNum("ammotype", 0);
        } else if (KvWeapon.GetNum("is_smokegrenade", 0)) {
            g_WeaponIdSmokegrenade          = index;
            g_WeaponAmmoTypeSmokegrenade    = KvWeapon.GetNum("ammotype", 0);
        } else if (KvWeapon.GetNum("is_flashbang", 0)) {
            g_WeaponIdFlashbang             = index;
            g_WeaponAmmoTypeFlashbang       = KvWeapon.GetNum("ammotype", 0);
        } else if (KvWeapon.GetNum("is_molotov", 0)) {
            g_WeaponLevelIdMolotov          = g_WeaponLevelIndex[index];
            g_WeaponAmmoTypeMolotov         = KvWeapon.GetNum("ammotype", 0);
        } else if (KvWeapon.GetNum("is_taser", 0)) {
            g_WeaponIdTaser                 = index;
            g_WeaponLevelIdTaser            = g_WeaponLevelIndex[index];
            g_WeaponAmmoTypeTaser           = KvWeapon.GetNum("ammotype", 0);
        }

        if ( !KvWeapon.GotoNextKey() ) {
            break;
        }
    }

    KvWeapon.Rewind();

    if (!(  g_WeaponsMaxId
            && g_WeaponIdKnife
            && g_WeaponIdHegrenade
            && g_WeaponIdSmokegrenade
            && g_WeaponIdFlashbang
    )) {
        char Error[1024];
        FormatEx(Error, sizeof(Error), "FATAL ERROR: Some of the weapons not found MAXID=[%i] KNIFE=[%i] HE=[%i] SMOKE=[%i] FLASH=[%i]. You should update you %s and take it from the release zip file.",
            g_WeaponsMaxId, g_WeaponIdKnife, g_WeaponIdHegrenade, g_WeaponIdSmokegrenade, g_WeaponIdFlashbang, WeaponFile);
        SetFailState("%s", Error);
    }

    if (!(  g_WeaponAmmoTypeHegrenade
            && g_WeaponAmmoTypeFlashbang
            && g_WeaponAmmoTypeSmokegrenade
    )) {
        char Error[1024];
        FormatEx(Error, sizeof(Error), "FATAL ERROR: Some of the ammo types not found HE=[%i] FLASH=[%i] SMOKE=[%i]. You should update you %s and take it from the release zip file.",
            g_WeaponAmmoTypeHegrenade, g_WeaponAmmoTypeFlashbang, g_WeaponAmmoTypeSmokegrenade, WeaponFile);
        SetFailState("%s", Error);
    }

    if (g_GameName == Csgo) {
        if (!(  g_WeaponIdTaser
        )) {
            char Error[1024];
            FormatEx(Error, sizeof(Error), "FATAL ERROR: Some of the weapons not found TASER=[%i]. You should update you %s and take it from the release zip file.",
                g_WeaponIdTaser, WeaponFile);
            SetFailState("%s", Error);
        }

        if (!(  g_WeaponAmmoTypeMolotov
                && g_WeaponAmmoTypeTaser
        )) {
            char Error[1024];
            FormatEx(Error, sizeof(Error), "FATAL ERROR: Some of the ammo types not found MOLOTOV=[%i] TASER=[%i]. You should update you %s and take it from the release zip file.",
                g_WeaponAmmoTypeMolotov, g_WeaponAmmoTypeTaser, WeaponFile);
            SetFailState("%s", Error);
        }
    }
}
