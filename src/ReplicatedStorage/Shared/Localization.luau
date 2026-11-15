--!strict
-- Global EN + Turkish (TR) Localization Dictionary for STEAL THE IMPOSSIBLE

export type LanguageCode = "en" | "tr"

local Translations: { [string]: { en: string, tr: string } } = {
    GAME_TITLE = { en = "STEAL THE IMPOSSIBLE", tr = "STEAL THE IMPOSSIBLE" },
    CASH = { en = "Cash", tr = "Nakit" },
    INCOME_PER_SEC = { en = "/sec", tr = "/sn" },
    NET_WORTH = { en = "Net Worth", tr = "Servet" },
    CARRYING = { en = "CARRYING", tr = "TAŞINIYOR" },
    RUN_TO_BASE = { en = "RUN BACK TO YOUR BASE TO SECURE!", tr = "GÜVENCEYE ALMAK İÇİN ÜSSÜNE KOŞ!" },
    TACKLE_BTN = { en = "STEAL / TACKLE", tr = "ÇAL / MÜDAHALE ET" },
    GADGET_BTN = { en = "USE GADGET", tr = "EKİPMAN KULLAN" },
    RIFT_OPEN_IN = { en = "15M SPECIAL RIFT IN", tr = "15 DK ÖZEL YARIK" },
    RIFT_ACTIVE = { en = "RIFT OPEN:", tr = "YARIK AÇIK:" },
    WORLD_END_IN = { en = "WORLD ENDING IN", tr = "DÜNYA SONU" },
    WORLD_END_ACTIVE = { en = "THE WORLD IS ENDING!", tr = "DÜNYA YOK OLUYOR!" },
    BASE_MENU = { en = "Base & Vault", tr = "Üs & Kasa" },
    FLEX_MENU = { en = "Flex Bases", tr = "Üs Gez" },
    SHOP_MENU = { en = "Shop & Style", tr = "Mağaza" },
    INDEX_MENU = { en = "Secret Index", tr = "Gizli Koleksiyon" },
    SQUAD_MENU = { en = "Squad Heist", tr = "Takım Soygunu" },
    RANK_MENU = { en = "Leaderboard", tr = "Sıralama" },
    UPGRADE_BASE = { en = "Upgrade Base", tr = "Üssü Yükselt" },
    EQUIP_PEDESTAL = { en = "Flex on Pedestal", tr = "Stantta Sergile" },
    HATCH_EGG = { en = "Hatch Galaxy Egg", tr = "Galaksi Yumurtası Çatlat" },
    VISIT_BASE = { en = "Visit Base", tr = "Üssü Ziyaret Et" },
    LIKE_BASE = { en = "Like Base ❤️", tr = "Üssü Beğen ❤️" },
    RETURN_HOME = { en = "Return to My Base", tr = "Kendi Üssüme Dön" },
    BUY = { en = "Buy", tr = "Satın Al" },
    EQUIP = { en = "Equip", tr = "Kuşan" },
    EQUIPPED = { en = "Equipped", tr = "Kuşanıldı" },
    OWNED = { en = "Owned", tr = "Sahipsin" },
    NO_P2W_BADGE = {
        en = "100% COSMETIC ONLY — ZERO PAY-TO-WIN",
        tr = "%100 KOZMETİK — PARAYLA GÜÇ SATIN ALINMAZ",
    },
    SECRET_BANNER_TITLE = {
        en = "0.01% SECRET COLLECTION DISCOVERY!",
        tr = "%0,01 GİZLİ KOLEKSİYON KEŞFİ!",
    },
    CREATE_SQUAD = { en = "Create Squad", tr = "Takım Kur" },
    LEAVE_SQUAD = { en = "Leave Squad", tr = "Takımdan Ayrıl" },
    INVITE = { en = "Invite", tr = "Davet Et" },
    START_HEIST = { en = "Start Big Heist", tr = "Büyük Soygunu Başlat" },
    LANG_LABEL = { en = "Language: EN", tr = "Dil: TR" },
    EVENT_METEOR = { en = "METEOR SHOWER", tr = "METEOR YAĞMURU" },
    EVENT_MONSTER = { en = "GIANT MONSTER", tr = "DEV CANAVAR" },
    EVENT_GRAVITY = { en = "GRAVITY LOSS", tr = "YERÇEKİMİ KAYBI" },
    QUESTS_MENU = { en = "Quests & Codes", tr = "Görev & Kod" },
    TRADE_MENU = { en = "Trade", tr = "Takas" },
    REDEEM = { en = "Redeem", tr = "Kullan" },
    CLAIM = { en = "Claim", tr = "Ödülü Al" },
    CLAIMED = { en = "Claimed", tr = "Alındı" },
    REBIRTH_BTN = { en = "ASCEND / REBIRTH", tr = "YÜKSEL / REBIRTH" },
    HIGH_STAKES = { en = "High-Stakes 2x Safe", tr = "Yüksek Risk 2x Kasa" },
    COLLECT_SAFE = { en = "Collect Safe", tr = "Kasayı Topla" },
    ACTIVATE_SHIELD = { en = "Recharge Shield", tr = "Kalkanı Yenile" },
    RAID_SAFE = { en = "RAID SAFE!", tr = "KASAYI SOY!" },
    HOME_COMPASS = { en = "YOUR BASE", tr = "ÜSSÜN" },
}

local Localization = {}

function Localization.Get(key: string, lang: LanguageCode?): string
    local entry = Translations[key]
    if not entry then
        return key
    end
    local code: LanguageCode = if lang == "tr" then "tr" else "en"
    return entry[code]
end

return table.freeze(Localization)
