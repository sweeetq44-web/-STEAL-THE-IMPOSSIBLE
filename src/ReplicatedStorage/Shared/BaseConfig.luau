--!strict
-- 8 Personal Base Configurations, Tier 1-5 Upgrades, Tech Upgrades, and Cash Gadgets

local Types = require(script.Parent.Types)
local GameConfig = require(script.Parent.GameConfig)

local UpgradeTiers: { Types.BaseUpgradeTier } = {
    {
        Tier = 1,
        Name = "Starter Vault",
        NameTR = "Başlangıç Üssü",
        Cost = 0,
        MaxPedestals = 4,
        IncomeMultiplier = 1.0,
        ShieldDuration = 20,
        CarryPenaltyReduction = 0.0,
        FloorSize = Vector3.new(54, 2, 54),
        AccentHeight = 14,
    },
    {
        Tier = 2,
        Name = "Reinforced Bunker",
        NameTR = "Güçlendirilmiş Sığınak",
        Cost = 3500,
        MaxPedestals = 8,
        IncomeMultiplier = 1.30,
        ShieldDuration = 28,
        CarryPenaltyReduction = 0.15,
        FloorSize = Vector3.new(60, 2, 60),
        AccentHeight = 18,
    },
    {
        Tier = 3,
        Name = "Sky Spire Wing",
        NameTR = "Gökyüzü Kulesi",
        Cost = 22000,
        MaxPedestals = 12,
        IncomeMultiplier = 1.65,
        ShieldDuration = 36,
        CarryPenaltyReduction = 0.30,
        FloorSize = Vector3.new(66, 2, 66),
        AccentHeight = 23,
    },
    {
        Tier = 4,
        Name = "Obsidian Citadel",
        NameTR = "Obsidyen Kale",
        Cost = 140000,
        MaxPedestals = 16,
        IncomeMultiplier = 2.15,
        ShieldDuration = 45,
        CarryPenaltyReduction = 0.45,
        FloorSize = Vector3.new(72, 2, 72),
        AccentHeight = 28,
    },
    {
        Tier = 5,
        Name = "Impossible Palace",
        NameTR = "İmkânsız Saray",
        Cost = 850000,
        MaxPedestals = 24,
        IncomeMultiplier = 3.0,
        ShieldDuration = 60,
        CarryPenaltyReduction = 0.60,
        FloorSize = Vector3.new(78, 2, 78),
        AccentHeight = 36,
    },
}

local TechUpgrades: { Types.TechUpgradeDef } = {
    {
        Id = "carry_boots",
        Name = "Antigrav Carry Boots",
        NameTR = "Ağırlıksız Taşıma Botu",
        Description = "Reduces walkspeed slowdown while carrying heavy rare items (+4% per level).",
        DescriptionTR = "Ağır nadir eşyaları taşırken hız cezasını azaltır (seviye başına +%4).",
        MaxLevel = 8,
        BaseCost = 1200,
        CostMultiplier = 2.1,
        EffectPerLevel = 0.04,
    },
    {
        Id = "tackle_reach",
        Name = "Magnetic Snatch Gloves",
        NameTR = "Manyetik Kapma Eldiveni",
        Description = "Shaves 0.2s off Tackle/Steal cooldown per level.",
        DescriptionTR = "Çalma/Saldırı bekleme süresini seviye başına 0.2 sn azaltır.",
        MaxLevel = 6,
        BaseCost = 2000,
        CostMultiplier = 2.25,
        EffectPerLevel = 0.2,
    },
    {
        Id = "vault_multiplier",
        Name = "Vault Compounder",
        NameTR = "Kasa Çoğaltıcı",
        Description = "+10% Cash bonus on every successful extraction per level.",
        DescriptionTR = "Her başarılı eşya teslimatında +%10 ekstra nakit kazandırır.",
        MaxLevel = 10,
        BaseCost = 1800,
        CostMultiplier = 2.15,
        EffectPerLevel = 0.10,
    },
}

local Gadgets: { Types.GadgetDef } = {
    {
        Id = "speed_coil",
        Name = "Kinetic Speed Coil",
        NameTR = "Kinetik Hız Bobini",
        Description = "100% Free-to-Play Cash gadget! Temporary +12 speed surge for chasing or escaping.",
        DescriptionTR = "Tamamen oyun içi parayla! Kovalamaca veya kaçış için geçici +12 hız patlaması.",
        Cost = 2500,
        Cooldown = 14,
        Icon = "⚡",
    },
    {
        Id = "magnet_radar",
        Name = "Impossible Radar",
        NameTR = "İmkânsız Radar",
        Description = "Pulses a 3D beam pointing toward the rarest active item on the map.",
        DescriptionTR = "Haritadaki en nadir aktif eşyaya doğru ışık huzmesi gönderir.",
        Cost = 6500,
        Cooldown = 18,
        Icon = "📡",
    },
    {
        Id = "phase_dash",
        Name = "Phase Blink Dash",
        NameTR = "Işınlanma Atılımı",
        Description = "Forward impulse burst to dodge rival interceptors or close the gap.",
        DescriptionTR = "Rakiplerden kaçmak veya mesafeyi kapatmak için ileri atılım.",
        Cost = 14000,
        Cooldown = 10,
        Icon = "💨",
    },
    {
        Id = "frost_bolas",
        Name = "Cryo Snare",
        NameTR = "Buz Kapanı",
        Description = "Briefly slows nearby fleeing item carriers within 24 studs.",
        DescriptionTR = "24 birim içindeki kaçan eşya taşıyıcılarını kısa süreliğine yavaşlatır.",
        Cost = 28000,
        Cooldown = 16,
        Icon = "🧊",
    },
}

local TechById: { [string]: Types.TechUpgradeDef } = {}
for _, t in ipairs(TechUpgrades) do
    TechById[t.Id] = t
end

local GadgetById: { [string]: Types.GadgetDef } = {}
for _, g in ipairs(Gadgets) do
    GadgetById[g.Id] = g
end

local BaseConfig = {
    UpgradeTiers = table.freeze(UpgradeTiers),
    TechUpgrades = table.freeze(TechUpgrades),
    TechById = table.freeze(TechById),
    Gadgets = table.freeze(Gadgets),
    GadgetById = table.freeze(GadgetById),
}

function BaseConfig.GetTier(tier: number): Types.BaseUpgradeTier
    local clamped = math.clamp(math.floor(tier), 1, #UpgradeTiers)
    return UpgradeTiers[clamped]
end

function BaseConfig.GetTechCost(techId: string, currentLevel: number): number?
    local def = TechById[techId]
    if not def or currentLevel >= def.MaxLevel then
        return nil
    end
    return math.floor(def.BaseCost * (def.CostMultiplier ^ currentLevel))
end

-- Returns world CFrame of Base slot 1..8 arranged symmetrically around the Central Plaza
function BaseConfig.GetSlotCFrame(slotIndex: number): CFrame
    local angle = ((slotIndex - 1) / GameConfig.MAX_PLAYERS) * math.pi * 2
    local r = GameConfig.BASE_RING_RADIUS
    local pos = Vector3.new(math.cos(angle) * r, 4, math.sin(angle) * r)
    -- Face toward Central Plaza (0, 4, 0)
    return CFrame.lookAt(pos, Vector3.new(0, 4, 0))
end

return table.freeze(BaseConfig)
