--!strict
-- Rarity Tiers & Exact Drop Probabilities
-- Total weights sum to exactly 100.00% (Secret = 0.01%)

local Types = require(script.Parent.Types)

export type RarityMap = { [Types.RarityId]: Types.RarityInfo }

local RarityOrder: { Types.RarityId } = {
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Mythic",
    "Impossible",
    "Secret",
}

local Rarities: RarityMap = {
    Common = {
        Id = "Common",
        DisplayName = "COMMON",
        DisplayNameTR = "SIRADAN",
        Order = 1,
        DropWeight = 52.00,
        Color = Color3.fromRGB(185, 195, 210),
        AccentColor = Color3.fromRGB(130, 145, 165),
        ValueMultiplier = 1.0,
        CarrySpeedPenalty = 0.04,
        BeaconEnabled = false,
        GlobalAnnounce = false,
    },
    Uncommon = {
        Id = "Uncommon",
        DisplayName = "UNCOMMON",
        DisplayNameTR = "NADİR OLMAYAN",
        Order = 2,
        DropWeight = 25.00,
        Color = Color3.fromRGB(80, 225, 130),
        AccentColor = Color3.fromRGB(35, 165, 85),
        ValueMultiplier = 1.8,
        CarrySpeedPenalty = 0.06,
        BeaconEnabled = false,
        GlobalAnnounce = false,
    },
    Rare = {
        Id = "Rare",
        DisplayName = "RARE",
        DisplayNameTR = "NADİR",
        Order = 3,
        DropWeight = 13.00,
        Color = Color3.fromRGB(65, 165, 255),
        AccentColor = Color3.fromRGB(30, 105, 215),
        ValueMultiplier = 3.5,
        CarrySpeedPenalty = 0.08,
        BeaconEnabled = true,
        GlobalAnnounce = false,
    },
    Epic = {
        Id = "Epic",
        DisplayName = "EPIC",
        DisplayNameTR = "DESTANSI",
        Order = 4,
        DropWeight = 6.50,
        Color = Color3.fromRGB(185, 85, 255),
        AccentColor = Color3.fromRGB(130, 40, 210),
        ValueMultiplier = 8.0,
        CarrySpeedPenalty = 0.11,
        BeaconEnabled = true,
        GlobalAnnounce = false,
    },
    Mythic = {
        Id = "Mythic",
        DisplayName = "MYTHIC",
        DisplayNameTR = "MİTİK",
        Order = 5,
        DropWeight = 2.60,
        Color = Color3.fromRGB(255, 95, 125),
        AccentColor = Color3.fromRGB(220, 35, 75),
        ValueMultiplier = 20.0,
        CarrySpeedPenalty = 0.14,
        BeaconEnabled = true,
        GlobalAnnounce = false,
    },
    Impossible = {
        Id = "Impossible",
        DisplayName = "IMPOSSIBLE",
        DisplayNameTR = "İMKÂNSIZ",
        Order = 6,
        DropWeight = 0.89,
        Color = Color3.fromRGB(255, 200, 45),
        AccentColor = Color3.fromRGB(255, 125, 20),
        ValueMultiplier = 65.0,
        CarrySpeedPenalty = 0.17,
        BeaconEnabled = true,
        GlobalAnnounce = false,
    },
    Secret = {
        Id = "Secret",
        DisplayName = "0.01% SECRET",
        DisplayNameTR = "%0.01 GİZLİ",
        Order = 7,
        DropWeight = 0.01, -- Exact 0.01% Secret Collection probability!
        Color = Color3.fromRGB(0, 255, 245),
        AccentColor = Color3.fromRGB(255, 65, 235),
        ValueMultiplier = 350.0,
        CarrySpeedPenalty = 0.19,
        BeaconEnabled = true,
        GlobalAnnounce = true,
    },
}

local RarityConfig = {
    Order = table.freeze(RarityOrder),
    Tiers = table.freeze(Rarities),
}

function RarityConfig.Get(rarityId: Types.RarityId): Types.RarityInfo
    return Rarities[rarityId] or Rarities.Common
end

function RarityConfig.RollRarity(luckMultiplier: number?, rng: Random?): Types.RarityId
    local mult = math.max(1, luckMultiplier or 1)
    local r = if rng then rng:NextNumber() else math.random()

    -- Secret keeps exact 0.01% rarity baseline unless explicitly boosted inside Secret Rift
    local secretChance = (Rarities.Secret.DropWeight / 100) * math.min(mult, 2.5)
    if r < secretChance then
        return "Secret"
    end

    -- Roll remaining rarities proportionally with optional luck boost on high tiers
    local weights: { { id: Types.RarityId, w: number } } = {}
    local total = 0
    for _, rarityId in ipairs(RarityOrder) do
        if rarityId ~= "Secret" then
            local info = Rarities[rarityId]
            local boosted = info.DropWeight
            if info.Order >= 4 then
                boosted = boosted * mult
            end
            total += boosted
            table.insert(weights, { id = rarityId, w = boosted })
        end
    end

    local roll = (if rng then rng:NextNumber() else math.random()) * total
    local accum = 0
    for _, entry in ipairs(weights) do
        accum += entry.w
        if roll <= accum then
            return entry.id
        end
    end
    return "Common"
end

return table.freeze(RarityConfig)
