--!strict
-- Daily Quests, Redeemable Promo Codes, Black-Market Merchant Buffs & Rebirth Tiers

export type PromoCodeDef = {
    Code: string,
    RewardCash: number,
    LuckDurationSeconds: number?,
    Description: string,
    DescriptionTR: string,
    Active: boolean,
}

export type QuestDef = {
    Id: string,
    StatKey: "Extracted" | "Steals" | "Likes" | "Heists",
    Target: number,
    RewardCash: number,
    Title: string,
    TitleTR: string,
}

export type MerchantItemDef = {
    Id: string,
    Name: string,
    NameTR: string,
    Description: string,
    DescriptionTR: string,
    Cost: number,
    DurationSeconds: number,
    Icon: string,
    BuffType: "LuckElixir" | "Featherweight" | "ShadowCloak" | "MysteryCrate",
}

local PromoCodes: { [string]: PromoCodeDef } = {
    IMPOSSIBLE = {
        Code = "IMPOSSIBLE",
        RewardCash = 1500,
        Description = "Starter bonus +$1,500 Cash!",
        DescriptionTR = "Başlangıç bonusu +$1.500 Nakit!",
        Active = true,
    },
    FROZENSUN = {
        Code = "FROZENSUN",
        RewardCash = 2500,
        LuckDurationSeconds = 180,
        Description = "+$2,500 Cash & 3m 2x Luck Boost!",
        DescriptionTR = "+$2.500 Nakit ve 3 dk 2x Şans Artışı!",
        Active = true,
    },
    SECRET001 = {
        Code = "SECRET001",
        RewardCash = 3000,
        LuckDurationSeconds = 300,
        Description = "+$3,000 Cash & 5m Secret Hunter Luck!",
        DescriptionTR = "+$3.000 Nakit ve 5 dk Gizli Avcı Şansı!",
        Active = true,
    },
    HEISTCREW = {
        Code = "HEISTCREW",
        RewardCash = 2000,
        Description = "Squad Up! +$2,000 Cash!",
        DescriptionTR = "Takımını Kur! +$2.000 Nakit!",
        Active = true,
    },
    WORLDENDING = {
        Code = "WORLDENDING",
        RewardCash = 3500,
        Description = "Apocalypse Prep! +$3,500 Cash!",
        DescriptionTR = "Kıyamet Hazırlığı! +$3.500 Nakit!",
        Active = true,
    },
    TRLAUNCH2026 = {
        Code = "TRLAUNCH2026",
        RewardCash = 5000,
        LuckDurationSeconds = 240,
        Description = "Grand Launch Gift: +$5,000 Cash & 4m Luck!",
        DescriptionTR = "Büyük Açılış Hediyesi: +$5.000 Nakit & 4 dk Şans!",
        Active = true,
    },
}

local DailyQuests: { QuestDef } = {
    {
        Id = "quest_extract_5",
        StatKey = "Extracted",
        Target = 5,
        RewardCash = 3500,
        Title = "Extract 5 Relics to Base",
        TitleTR = "Üssüne 5 Eşya Teslim Et",
    },
    {
        Id = "quest_steal_2",
        StatKey = "Steals",
        Target = 2,
        RewardCash = 5500,
        Title = "Steal 2 Items from Rivals",
        TitleTR = "Rakiplerden 2 Eşya Çal",
    },
    {
        Id = "quest_like_2",
        StatKey = "Likes",
        Target = 2,
        RewardCash = 2000,
        Title = "Flex Visit: Like 2 Bases",
        TitleTR = "Üs Gez: 2 Üssü Beğen",
    },
    {
        Id = "quest_heist_1",
        StatKey = "Heists",
        Target = 1,
        RewardCash = 7500,
        Title = "Complete 1 Co-op Big Heist",
        TitleTR = "1 Takım Büyük Soygunu Tamamla",
    },
}

local MerchantItems: { MerchantItemDef } = {
    {
        Id = "merch_luck_elixir",
        Name = "2x Impossible Luck Elixir",
        NameTR = "2x İmkânsız Şans İksiri",
        Description = "Doubles Rare/Impossible/Secret & Mutation luck for 5 minutes!",
        DescriptionTR = "5 dakika boyunca Nadir/İmkânsız/Gizli ve Mutasyon şansını 2 katına çıkarır!",
        Cost = 4500,
        DurationSeconds = 300,
        Icon = "🍀",
        BuffType = "LuckElixir",
    },
    {
        Id = "merch_feather_charm",
        Name = "Featherweight Charm",
        NameTR = "Tüy Ağırlık Tılsımı",
        Description = "Zero walkspeed slowdown while carrying heavy Impossible items (5 min)!",
        DescriptionTR = "Ağır eşyaları taşırken hız cezasını tamamen kaldırır (5 dk)!",
        Cost = 3200,
        DurationSeconds = 300,
        Icon = "🪶",
        BuffType = "Featherweight",
    },
    {
        Id = "merch_shadow_cloak",
        Name = "Shadow Beacon Cloak",
        NameTR = "Gölge Pelerini",
        Description = "Hides your glowing Sky Beacon while sneaking relics home (3 min)!",
        DescriptionTR = "Eşyayı üsse kaçırırken gökyüzü işaret ışığını gizler (3 dk)!",
        Cost = 5000,
        DurationSeconds = 180,
        Icon = "👻",
        BuffType = "ShadowCloak",
    },
    {
        Id = "merch_mystery_crate",
        Name = "Black-Market Mystery Crate",
        NameTR = "Karaborsa Gizem Kasası",
        Description = "Instantly rolls a Rare+ item (up to 0.01% Secret!) straight into your hands!",
        DescriptionTR = "Anında Nadir+ (ve %0.01 Gizli şanslı!) rastgele bir eşya düşürür!",
        Cost = 9500,
        DurationSeconds = 0,
        Icon = "🎁",
        BuffType = "MysteryCrate",
    },
}

local MerchantById: { [string]: MerchantItemDef } = {}
for _, m in ipairs(MerchantItems) do
    MerchantById[m.Id] = m
end

local QuestAndCodeConfig = {
    PromoCodes = table.freeze(PromoCodes),
    DailyQuests = table.freeze(DailyQuests),
    MerchantItems = table.freeze(MerchantItems),
    MerchantById = table.freeze(MerchantById),
    -- Rebirth thresholds: Cost in Cash to ascend (keeps Secrets, Cosmetics, Rebirths!)
    REBIRTH_BASE_COST = 250000,
    REBIRTH_COST_MULTIPLIER = 2.6,
    REBIRTH_INCOME_BONUS_PER_LEVEL = 0.50, -- +50% permanent Cash & Income per Rebirth!
    REBIRTH_LUCK_BONUS_PER_LEVEL = 0.10, -- +10% permanent Luck per Rebirth!
}

function QuestAndCodeConfig.GetRebirthCost(currentRebirths: number): number
    return math.floor(QuestAndCodeConfig.REBIRTH_BASE_COST * (QuestAndCodeConfig.REBIRTH_COST_MULTIPLIER ^ currentRebirths))
end

return table.freeze(QuestAndCodeConfig)
