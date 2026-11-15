--!strict
-- World Biomes, 15-Minute Rotating Special Rift Dimensions, and Co-op Heist Vault

export type BiomeDef = {
    Id: string,
    Name: string,
    NameTR: string,
    Description: string,
    DescriptionTR: string,
    AngleDegrees: number,
    Radius: number,
    PlatformSize: Vector3,
    PrimaryColor: Color3,
    AccentColor: Color3,
    FloorMaterial: Enum.Material,
    LuckMultiplier: number,
    SignatureItemId: string,
}

export type SpecialRiftTheme = {
    Id: string,
    Name: string,
    NameTR: string,
    PrimaryColor: Color3,
    AccentColor: Color3,
    LuckMultiplier: number,
}

local Biomes: { BiomeDef } = {
    {
        Id = "FrostCitadel",
        Name = "Frost Citadel",
        NameTR = "Buzul Kalesi",
        Description = "Frozen glacial spires guarding the legendary Frozen Sun.",
        DescriptionTR = "Efsanevi Buzdan Güneş'i koruyan donmuş buzul kuleleri.",
        AngleDegrees = 0,
        Radius = 325,
        PlatformSize = Vector3.new(125, 8, 125),
        PrimaryColor = Color3.fromRGB(115, 205, 245),
        AccentColor = Color3.fromRGB(225, 250, 255),
        FloorMaterial = Enum.Material.Ice,
        LuckMultiplier = 1.0,
        SignatureItemId = "frozen_sun",
    },
    {
        Id = "AbyssalCaldera",
        Name = "Abyssal Caldera",
        NameTR = "Cehennem Krateri",
        Description = "Scorching basalt craters where Mini Apocalypse stalks the rim.",
        DescriptionTR = "Mini Kıyamet'in dolaştığı yakıcı bazalt kraterleri.",
        AngleDegrees = 72,
        Radius = 325,
        PlatformSize = Vector3.new(125, 8, 125),
        PrimaryColor = Color3.fromRGB(55, 38, 42),
        AccentColor = Color3.fromRGB(255, 85, 35),
        FloorMaterial = Enum.Material.Basalt,
        LuckMultiplier = 1.05,
        SignatureItemId = "mini_apocalypse",
    },
    {
        Id = "ChronosRuins",
        Name = "Chronos Ruins",
        NameTR = "Zaman Harabeleri",
        Description = "Ancient floating gears echoing with the ticking Time Eater.",
        DescriptionTR = "Zaman Yiyen'in tik taklarıyla yankılanan antik dişliler.",
        AngleDegrees = 144,
        Radius = 325,
        PlatformSize = Vector3.new(125, 8, 125),
        PrimaryColor = Color3.fromRGB(185, 155, 95),
        AccentColor = Color3.fromRGB(95, 225, 255),
        FloorMaterial = Enum.Material.Marble,
        LuckMultiplier = 1.1,
        SignatureItemId = "time_eater",
    },
    {
        Id = "WatchersSanctum",
        Name = "Watchers' Sanctum",
        NameTR = "Gözcülerin Tapınağı",
        Description = "Shadowed obelisks watched over by The Last Eye.",
        DescriptionTR = "Son Göz tarafından izlenen gölgeli dikilitaşlar.",
        AngleDegrees = 216,
        Radius = 325,
        PlatformSize = Vector3.new(125, 8, 125),
        PrimaryColor = Color3.fromRGB(45, 28, 72),
        AccentColor = Color3.fromRGB(205, 75, 255),
        FloorMaterial = Enum.Material.Slate,
        LuckMultiplier = 1.15,
        SignatureItemId = "the_last_eye",
    },
    {
        Id = "AstralVoid",
        Name = "Astral Void",
        NameTR = "Astral Boşluk",
        Description = "Starlit cosmos floating above the horizon, cradle of Galaxy Eggs.",
        DescriptionTR = "Galaksi Yumurtalarının doğduğu yıldızlı kozmik platform.",
        AngleDegrees = 288,
        Radius = 325,
        PlatformSize = Vector3.new(125, 8, 125),
        PrimaryColor = Color3.fromRGB(24, 28, 62),
        AccentColor = Color3.fromRGB(255, 115, 235),
        FloorMaterial = Enum.Material.SmoothPlastic,
        LuckMultiplier = 1.2,
        SignatureItemId = "galaxy_egg",
    },
}

local SpecialRiftThemes: { SpecialRiftTheme } = {
    {
        Id = "GlitchMatrix",
        Name = "Glitch Matrix",
        NameTR = "Glitch Matrisi",
        PrimaryColor = Color3.fromRGB(18, 28, 34),
        AccentColor = Color3.fromRGB(0, 255, 185),
        LuckMultiplier = 2.5,
    },
    {
        Id = "SunkenAtlantis",
        Name = "Sunken Atlantis",
        NameTR = "Batık Atlantis",
        PrimaryColor = Color3.fromRGB(22, 65, 95),
        AccentColor = Color3.fromRGB(65, 245, 255),
        LuckMultiplier = 2.5,
    },
    {
        Id = "MirrorMirage",
        Name = "Mirror Mirage",
        NameTR = "Ayna Serabı",
        PrimaryColor = Color3.fromRGB(195, 180, 225),
        AccentColor = Color3.fromRGB(255, 105, 215),
        LuckMultiplier = 2.6,
    },
    {
        Id = "QuantumAnomaly",
        Name = "Quantum Anomaly",
        NameTR = "Kuantum Anomalisi",
        PrimaryColor = Color3.fromRGB(32, 18, 52),
        AccentColor = Color3.fromRGB(255, 215, 65),
        LuckMultiplier = 2.8,
    },
}

local ById: { [string]: BiomeDef } = {}
for _, b in ipairs(Biomes) do
    ById[b.Id] = b
end

local BiomeConfig = {
    Biomes = table.freeze(Biomes),
    ById = table.freeze(ById),
    SpecialRiftThemes = table.freeze(SpecialRiftThemes),
}

function BiomeConfig.GetBiomePosition(biome: BiomeDef): Vector3
    local rad = math.rad(biome.AngleDegrees)
    return Vector3.new(math.cos(rad) * biome.Radius, 8, math.sin(rad) * biome.Radius)
end

return table.freeze(BiomeConfig)
