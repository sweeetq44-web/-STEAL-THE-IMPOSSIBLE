--!strict
-- Shared Luau Type Definitions for STEAL THE IMPOSSIBLE

export type RarityId =
    "Common"
    | "Uncommon"
    | "Rare"
    | "Epic"
    | "Mythic"
    | "Impossible"
    | "Secret"

export type MutationId =
    "Normal"
    | "Shiny"
    | "Frostbitten"
    | "Glitch"
    | "VoidTouched"
    | "Celestial"

export type RarityInfo = {
    Id: RarityId,
    DisplayName: string,
    DisplayNameTR: string,
    Order: number,
    DropWeight: number, -- out of 100.0 (Secret = 0.01%)
    Color: Color3,
    AccentColor: Color3,
    ValueMultiplier: number,
    CarrySpeedPenalty: number, -- e.g. 0.08 = 8% slower while carrying
    BeaconEnabled: boolean,
    GlobalAnnounce: boolean,
}

export type ItemVisualStyle =
    "FrozenSun"
    | "MiniApocalypse"
    | "TimeEater"
    | "TheLastEye"
    | "GalaxyEgg"
    | "CrystalRelic"
    | "CubeArtifact"
    | "OrbSingularity"
    | "CrownRelic"
    | "DragonTotem"
    | "ClockworkGear"
    | "VoidPrism"

export type ItemDefinition = {
    Id: string,
    Name: string,
    NameTR: string,
    Description: string,
    DescriptionTR: string,
    Icon: string,
    Rarity: RarityId,
    BiomeId: string,
    BaseCashValue: number,
    PassiveIncomePerSec: number,
    VisualStyle: ItemVisualStyle,
    PrimaryColor: Color3,
    SecondaryColor: Color3,
    SpecialBehavior: string?, -- "TracksPlayer" | "HatchableEgg" | "MiniFireAura" | "ReverseClock" | "FrostHalo"
    IsWeekly: boolean?,
    IsSecret: boolean?,
    WeeklyTag: string?,
}

export type OwnedItemInstance = {
    Uid: string,
    ItemId: string,
    Mutation: MutationId?,
    ObtainedAt: number,
    ObtainedFrom: string,
    PedestalSlot: number?, -- nil = stored in vault, 1..24 = flexed on pedestal
    HatchedCreature: string?, -- set if GalaxyEgg hatched
    SerialNumber: number?,
}

export type BaseUpgradeTier = {
    Tier: number,
    Name: string,
    NameTR: string,
    Cost: number,
    MaxPedestals: number,
    IncomeMultiplier: number,
    ShieldDuration: number,
    CarryPenaltyReduction: number,
    FloorSize: Vector3,
    AccentHeight: number,
}

export type TechUpgradeDef = {
    Id: string,
    Name: string,
    NameTR: string,
    Description: string,
    DescriptionTR: string,
    MaxLevel: number,
    BaseCost: number,
    CostMultiplier: number,
    EffectPerLevel: number,
}

export type GadgetDef = {
    Id: string,
    Name: string,
    NameTR: string,
    Description: string,
    DescriptionTR: string,
    Cost: number,
    Cooldown: number,
    Icon: string,
}

export type CosmeticCategory =
    "CharacterSkin"
    | "BaseDesign"
    | "AnimationPack"
    | "VipTag"
    | "PetSkin"
    | "CosmeticBundle"

export type RobuxProductDef = {
    Id: string,
    Category: CosmeticCategory,
    Name: string,
    NameTR: string,
    Description: string,
    DescriptionTR: string,
    RobuxPrice: number,
    GamePassId: number, -- Replace with live Roblox GamePass ID upon publishing
    DevProductId: number?, -- Optional repeatable DevProduct ID
    UnlocksCosmetics: { string },
    BadgeColor: Color3,
    Featured: boolean?,
}

export type CosmeticAssetDef = {
    Id: string,
    Category: CosmeticCategory,
    Name: string,
    NameTR: string,
    RequiredProductId: string,
    PrimaryColor: Color3,
    SecondaryColor: Color3,
    Material: Enum.Material?,
    TrailEnabled: boolean?,
    TagText: string?,
}

export type WorldEventType = "MeteorShower" | "GiantMonster" | "GravityLoss"

export type SquadData = {
    SquadId: string,
    LeaderUserId: number,
    Members: { number },
    CreatedAt: number,
}

export type PlayerProfile = {
    Version: number,
    Cash: number,
    TotalEarned: number,
    TotalSteals: number,
    TotalExtracted: number,
    SecretCount: number,
    Rebirths: number,
    BaseTier: number,
    HighStakesMode: boolean,
    UncollectedSafeCash: number,
    TechLevels: { [string]: number },
    OwnedGadgets: { [string]: boolean },
    VaultItems: { OwnedItemInstance },
    DiscoveredItems: { [string]: number }, -- ItemId -> count found
    DiscoveredSecrets: { [string]: number }, -- SecretId -> first timestamp
    OwnedProducts: { [string]: boolean },
    RedeemedCodes: { [string]: boolean },
    QuestDayKey: number,
    QuestProgress: {
        Extracted: number,
        Steals: number,
        Likes: number,
        Heists: number,
    },
    ClaimedQuests: { [string]: boolean },
    ActiveBuffs: {
        LuckUntil: number,
        FeatherUntil: number,
        ShadowCloakUntil: number,
    },
    EquippedCosmetics: {
        CharacterSkin: string?,
        BaseDesign: string?,
        AnimationPack: string?,
        PetSkin: string?,
        VipTagEnabled: boolean,
    },
    TotalBaseLikes: number,
    LikedPlayerTargets: { [string]: boolean },
    PreferredLanguage: "en" | "tr",
    LastSavedAt: number,
}

return {}
