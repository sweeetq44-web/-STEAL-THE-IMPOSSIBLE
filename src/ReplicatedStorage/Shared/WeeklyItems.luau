--!strict
-- Weekly New Rare Items Registry (LiveOps Data-Driven Config)
-- Add new weekly items here every week without touching core game systems.

local Types = require(script.Parent.Types)

local WeeklyItems = {}

WeeklyItems.ACTIVE_WEEK_ID = "WEEK_01_COSMIC_FREEZE"
WeeklyItems.ACTIVE_WEEK_TITLE = "Cosmic Freeze Week"
WeeklyItems.ACTIVE_WEEK_TITLE_TR = "Kozmik Don Haftası"

WeeklyItems.Items = {
    {
        Id = "weekly_cryo_comet",
        Name = "Cryo Comet Heart",
        NameTR = "Kriyo Kuyruklu Yıldız Kalbi",
        Description = "A roaring comet frozen mid-orbit during Cosmic Freeze Week.",
        DescriptionTR = "Kozmik Don Haftası sırasında yörüngede donmuş dev kuyruklu yıldız kalbi.",
        Icon = "☄️",
        Rarity = "Mythic",
        BiomeId = "AstralVoid",
        BaseCashValue = 16000,
        PassiveIncomePerSec = 145,
        VisualStyle = "OrbSingularity",
        PrimaryColor = Color3.fromRGB(95, 235, 255),
        SecondaryColor = Color3.fromRGB(165, 110, 255),
        SpecialBehavior = "FrostHalo",
        IsWeekly = true,
        WeeklyTag = "WEEKLY_01",
    },
    {
        Id = "weekly_frost_chronometer",
        Name = "Permafrost Paradox",
        NameTR = "Buzul Paradoksu",
        Description = "A limited weekly clockwork relic forged inside absolute winter.",
        DescriptionTR = "Mutlak kışın içinde dövülmüş haftalık sınırlı zaman kalıntısı.",
        Icon = "❄️",
        Rarity = "Impossible",
        BiomeId = "FrostCitadel",
        BaseCashValue = 82000,
        PassiveIncomePerSec = 680,
        VisualStyle = "TimeEater",
        PrimaryColor = Color3.fromRGB(140, 245, 255),
        SecondaryColor = Color3.fromRGB(255, 255, 255),
        SpecialBehavior = "ReverseClock",
        IsWeekly = true,
        WeeklyTag = "WEEKLY_01",
    },
    {
        Id = "weekly_void_hatchling_crown",
        Name = "Starborn Crown",
        NameTR = "Yıldızdoğumlu Taç",
        Description = "Weekly exclusive crown pulsing with supernova embers.",
        DescriptionTR = "Süpernova közleriyle parlayan haftalık özel taç.",
        Icon = "👑",
        Rarity = "Epic",
        BiomeId = "SpecialRift",
        BaseCashValue = 4800,
        PassiveIncomePerSec = 48,
        VisualStyle = "CrownRelic",
        PrimaryColor = Color3.fromRGB(255, 210, 90),
        SecondaryColor = Color3.fromRGB(185, 75, 255),
        IsWeekly = true,
        WeeklyTag = "WEEKLY_01",
    },
} :: { Types.ItemDefinition }

return table.freeze(WeeklyItems)
