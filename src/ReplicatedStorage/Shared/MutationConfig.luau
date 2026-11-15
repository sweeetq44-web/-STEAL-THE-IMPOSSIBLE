--!strict
-- Item Mutation System (Normal, Shiny, Frostbitten, Glitch, VoidTouched, Celestial)
-- Multiplies item Cash Value & Passive Income/sec and adds distinct visual flair!

export type MutationId =
    "Normal"
    | "Shiny"
    | "Frostbitten"
    | "Glitch"
    | "VoidTouched"
    | "Celestial"

export type MutationDef = {
    Id: MutationId,
    DisplayName: string,
    DisplayNameTR: string,
    Prefix: string,
    DropWeight: number, -- out of 100.0
    ValueMultiplier: number,
    Color: Color3,
    ParticleColor: Color3,
}

local Order: { MutationId } = {
    "Normal",
    "Shiny",
    "Frostbitten",
    "Glitch",
    "VoidTouched",
    "Celestial",
}

local Mutations: { [MutationId]: MutationDef } = {
    Normal = {
        Id = "Normal",
        DisplayName = "Standard",
        DisplayNameTR = "Standart",
        Prefix = "",
        DropWeight = 84.75,
        ValueMultiplier = 1.0,
        Color = Color3.fromRGB(225, 232, 245),
        ParticleColor = Color3.fromRGB(225, 232, 245),
    },
    Shiny = {
        Id = "Shiny",
        DisplayName = "SHINY",
        DisplayNameTR = "PARLAK",
        Prefix = "✨ Shiny ",
        DropWeight = 8.00,
        ValueMultiplier = 1.75,
        Color = Color3.fromRGB(255, 235, 115),
        ParticleColor = Color3.fromRGB(255, 245, 165),
    },
    Frostbitten = {
        Id = "Frostbitten",
        DisplayName = "FROSTBITTEN",
        DisplayNameTR = "BUZLANMIŞ",
        Prefix = "❄️ Frost ",
        DropWeight = 4.00,
        ValueMultiplier = 2.25,
        Color = Color3.fromRGB(115, 235, 255),
        ParticleColor = Color3.fromRGB(205, 250, 255),
    },
    Glitch = {
        Id = "Glitch",
        DisplayName = "GLITCHED",
        DisplayNameTR = "GLİTCHLİ",
        Prefix = "⚡ Glitched ",
        DropWeight = 2.00,
        ValueMultiplier = 3.00,
        Color = Color3.fromRGB(0, 255, 185),
        ParticleColor = Color3.fromRGB(255, 55, 215),
    },
    VoidTouched = {
        Id = "VoidTouched",
        DisplayName = "VOID-TOUCHED",
        DisplayNameTR = "HİÇLİK DOKUNUŞLU",
        Prefix = "🌑 Void ",
        DropWeight = 1.00,
        ValueMultiplier = 4.00,
        Color = Color3.fromRGB(175, 65, 255),
        ParticleColor = Color3.fromRGB(75, 25, 135),
    },
    Celestial = {
        Id = "Celestial",
        DisplayName = "CELESTIAL",
        DisplayNameTR = "GÖKSEL",
        Prefix = "👑 Celestial ",
        DropWeight = 0.25,
        ValueMultiplier = 7.50,
        Color = Color3.fromRGB(255, 195, 45),
        ParticleColor = Color3.fromRGB(0, 255, 245),
    },
}

local MutationConfig = {
    Order = table.freeze(Order),
    Tiers = table.freeze(Mutations),
}

function MutationConfig.Get(mutationId: MutationId?): MutationDef
    if mutationId and Mutations[mutationId] then
        return Mutations[mutationId]
    end
    return Mutations.Normal
end

function MutationConfig.RollMutation(luckMultiplier: number?, rng: Random?): MutationId
    local mult = math.max(1.0, luckMultiplier or 1.0)
    local total = 0
    local weights: { { id: MutationId, w: number } } = {}

    for _, mId in ipairs(Order) do
        local def = Mutations[mId]
        local w = if mId == "Normal" then def.DropWeight else (def.DropWeight * mult)
        total += w
        table.insert(weights, { id = mId, w = w })
    end

    local roll = (if rng then rng:NextNumber() else math.random()) * total
    local accum = 0
    for _, entry in ipairs(weights) do
        accum += entry.w
        if roll <= accum then
            return entry.id
        end
    end
    return "Normal"
end

return table.freeze(MutationConfig)
