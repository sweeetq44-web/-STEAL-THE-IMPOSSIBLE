--!strict
-- Cosmetic-First Robux Monetization Catalog
-- Prices match exact design specification (customizable per live A/B test):
--   Custom Character Skins: 99 Robux
--   Custom Base Designs: 149 Robux
--   Custom Animations: 49 Robux
--   VIP Name Tag: 199 Robux
--   Custom Pet Appearances: 79 Robux
--   Extra Cosmetic Pack: 299 Robux
-- 100% Ethical: ZERO gameplay power or pay-to-win advantages.

local Types = require(script.Parent.Types)

local Products: { Types.RobuxProductDef } = {
    {
        Id = "prod_custom_skins",
        Category = "CharacterSkin",
        Name = "Custom Character Skins",
        NameTR = "Özel Karakter Skinleri",
        Description = "Unlock 4 dazzling cosmetic character themes: Cyber Phantom, Frost Monarch, Solar Knight & Void Stalker.",
        DescriptionTR = "4 özel kozmetik karakter görünümü açar: Cyber Phantom, Frost Monarch, Solar Knight & Void Stalker.",
        RobuxPrice = 99,
        GamePassId = 900000101,
        UnlocksCosmetics = { "skin_cyber_phantom", "skin_frost_monarch", "skin_solar_knight", "skin_void_stalker" },
        BadgeColor = Color3.fromRGB(95, 205, 255),
    },
    {
        Id = "prod_custom_bases",
        Category = "BaseDesign",
        Name = "Custom Base Designs",
        NameTR = "Özel Üs Tasarımları",
        Description = "Flex your base in style! Unlocks Neon Cyber, Golden Palace, Obsidian Hellfire & Crystal Glacier themes.",
        DescriptionTR = "Üssünü tarzla sergile! Neon Siber, Altın Saray, Obsidyen Cehennem & Kristal Buzul temaları.",
        RobuxPrice = 149,
        GamePassId = 900000102,
        UnlocksCosmetics = { "base_neon_cyber", "base_golden_palace", "base_obsidian_hellfire", "base_crystal_glacier" },
        BadgeColor = Color3.fromRGB(255, 195, 65),
    },
    {
        Id = "prod_custom_animations",
        Category = "AnimationPack",
        Name = "Custom Animations",
        NameTR = "Özel Animasyonlar",
        Description = "Show off signature extraction victory dances, floating relic carry poses & heroic emotes.",
        DescriptionTR = "Eşya teslimat zafer dansları, özel taşıma pozları ve kahraman ifadeleri.",
        RobuxPrice = 49,
        GamePassId = 900000103,
        UnlocksCosmetics = { "anim_heroic_hover", "anim_royal_strut", "anim_cyber_spin" },
        BadgeColor = Color3.fromRGB(115, 245, 155),
    },
    {
        Id = "prod_vip_nametag",
        Category = "VipTag",
        Name = "VIP Name Tag",
        NameTR = "VIP İsim Etiketi",
        Description = "Prestigious animated golden [VIP] overhead & leaderboard badge with crown flair.",
        DescriptionTR = "Taç simgeli prestijli animasyonlu altın [VIP] isim etiketi ve sıralama rozeti.",
        RobuxPrice = 199,
        GamePassId = 900000104,
        UnlocksCosmetics = { "vip_gold_crown" },
        BadgeColor = Color3.fromRGB(255, 215, 45),
        Featured = true,
    },
    {
        Id = "prod_custom_pets",
        Category = "PetSkin",
        Name = "Custom Pet Appearances",
        NameTR = "Özel Pet Görünümleri",
        Description = "Purely cosmetic floating shoulder companions: Frost Wisp, Mini Ember Dragon, Starlight Orb & Clockwork Owl.",
        DescriptionTR = "Tamamen kozmetik omuz arkadaşı petler: Buz Perisi, Mini Kor Ejderha, Yıldız Küresi & Saat Baykuşu.",
        RobuxPrice = 79,
        GamePassId = 900000105,
        UnlocksCosmetics = { "pet_frost_wisp", "pet_ember_dragon", "pet_starlight_orb", "pet_clockwork_owl" },
        BadgeColor = Color3.fromRGB(255, 115, 220),
    },
    {
        Id = "prod_extra_cosmetic_pack",
        Category = "CosmeticBundle",
        Name = "Extra Cosmetic Pack",
        NameTR = "Ekstra Kozmetik Paketi",
        Description = "Ultimate style bundle! Exclusive Celestial Trail, Diamond Base Trim, Galaxy Aura & Crowned Void Skin.",
        DescriptionTR = "En kapsamlı kozmetik paketi! Göksel İz, Elmas Üs Çerçevesi, Galaksi Aurası & Taçlı Hiçlik Skini.",
        RobuxPrice = 299,
        GamePassId = 900000106,
        UnlocksCosmetics = {
            "skin_void_emperor",
            "base_diamond_celestial",
            "pet_void_phoenix",
            "anim_galaxy_ascension",
            "vip_gold_crown",
        },
        BadgeColor = Color3.fromRGB(190, 85, 255),
        Featured = true,
    },
}

local Assets: { Types.CosmeticAssetDef } = {
    -- Character Skins
    {
        Id = "skin_cyber_phantom",
        Category = "CharacterSkin",
        Name = "Cyber Phantom",
        NameTR = "Siber Hayalet",
        RequiredProductId = "prod_custom_skins",
        PrimaryColor = Color3.fromRGB(20, 26, 38),
        SecondaryColor = Color3.fromRGB(0, 255, 225),
        Material = Enum.Material.Neon,
        TrailEnabled = true,
    },
    {
        Id = "skin_frost_monarch",
        Category = "CharacterSkin",
        Name = "Frost Monarch",
        NameTR = "Buzul Hükümdarı",
        RequiredProductId = "prod_custom_skins",
        PrimaryColor = Color3.fromRGB(115, 220, 255),
        SecondaryColor = Color3.fromRGB(235, 250, 255),
        Material = Enum.Material.Ice,
        TrailEnabled = true,
    },
    {
        Id = "skin_solar_knight",
        Category = "CharacterSkin",
        Name = "Solar Knight",
        NameTR = "Güneş Şövalyesi",
        RequiredProductId = "prod_custom_skins",
        PrimaryColor = Color3.fromRGB(255, 185, 45),
        SecondaryColor = Color3.fromRGB(255, 85, 35),
        Material = Enum.Material.Metal,
        TrailEnabled = true,
    },
    {
        Id = "skin_void_stalker",
        Category = "CharacterSkin",
        Name = "Void Stalker",
        NameTR = "Hiçlik Avcısı",
        RequiredProductId = "prod_custom_skins",
        PrimaryColor = Color3.fromRGB(35, 18, 65),
        SecondaryColor = Color3.fromRGB(200, 75, 255),
        Material = Enum.Material.SmoothPlastic,
        TrailEnabled = true,
    },
    {
        Id = "skin_void_emperor",
        Category = "CharacterSkin",
        Name = "Galaxy Void Emperor",
        NameTR = "Galaksi İmparatoru",
        RequiredProductId = "prod_extra_cosmetic_pack",
        PrimaryColor = Color3.fromRGB(15, 15, 35),
        SecondaryColor = Color3.fromRGB(0, 255, 245),
        Material = Enum.Material.ForceField,
        TrailEnabled = true,
    },

    -- Base Designs
    {
        Id = "base_neon_cyber",
        Category = "BaseDesign",
        Name = "Neon Cyber Vault",
        NameTR = "Neon Siber Kasa",
        RequiredProductId = "prod_custom_bases",
        PrimaryColor = Color3.fromRGB(18, 22, 34),
        SecondaryColor = Color3.fromRGB(0, 255, 200),
        Material = Enum.Material.Metal,
    },
    {
        Id = "base_golden_palace",
        Category = "BaseDesign",
        Name = "Golden Palace",
        NameTR = "Altın Saray",
        RequiredProductId = "prod_custom_bases",
        PrimaryColor = Color3.fromRGB(245, 238, 220),
        SecondaryColor = Color3.fromRGB(255, 200, 55),
        Material = Enum.Material.Marble,
    },
    {
        Id = "base_obsidian_hellfire",
        Category = "BaseDesign",
        Name = "Obsidian Hellfire",
        NameTR = "Obsidyen Cehennem",
        RequiredProductId = "prod_custom_bases",
        PrimaryColor = Color3.fromRGB(28, 20, 24),
        SecondaryColor = Color3.fromRGB(255, 75, 35),
        Material = Enum.Material.Basalt,
    },
    {
        Id = "base_crystal_glacier",
        Category = "BaseDesign",
        Name = "Crystal Glacier",
        NameTR = "Kristal Buzul",
        RequiredProductId = "prod_custom_bases",
        PrimaryColor = Color3.fromRGB(165, 230, 255),
        SecondaryColor = Color3.fromRGB(235, 255, 255),
        Material = Enum.Material.Ice,
    },
    {
        Id = "base_diamond_celestial",
        Category = "BaseDesign",
        Name = "Celestial Diamond",
        NameTR = "Göksel Elmas",
        RequiredProductId = "prod_extra_cosmetic_pack",
        PrimaryColor = Color3.fromRGB(25, 22, 55),
        SecondaryColor = Color3.fromRGB(255, 110, 245),
        Material = Enum.Material.Glass,
    },

    -- Animations
    {
        Id = "anim_heroic_hover",
        Category = "AnimationPack",
        Name = "Heroic Hover Pose",
        NameTR = "Kahraman Süzülme Pozu",
        RequiredProductId = "prod_custom_animations",
        PrimaryColor = Color3.fromRGB(115, 245, 155),
        SecondaryColor = Color3.fromRGB(255, 255, 255),
    },
    {
        Id = "anim_royal_strut",
        Category = "AnimationPack",
        Name = "Royal Trophy March",
        NameTR = "Kraliyet Zafer Yürüyüşü",
        RequiredProductId = "prod_custom_animations",
        PrimaryColor = Color3.fromRGB(255, 210, 75),
        SecondaryColor = Color3.fromRGB(255, 150, 45),
    },
    {
        Id = "anim_cyber_spin",
        Category = "AnimationPack",
        Name = "Cyber Spin Victory",
        NameTR = "Siber Zafer Dönüşü",
        RequiredProductId = "prod_custom_animations",
        PrimaryColor = Color3.fromRGB(0, 245, 255),
        SecondaryColor = Color3.fromRGB(190, 85, 255),
    },
    {
        Id = "anim_galaxy_ascension",
        Category = "AnimationPack",
        Name = "Galaxy Ascension",
        NameTR = "Galaksi Yükselişi",
        RequiredProductId = "prod_extra_cosmetic_pack",
        PrimaryColor = Color3.fromRGB(210, 95, 255),
        SecondaryColor = Color3.fromRGB(95, 255, 255),
    },

    -- VIP Tag
    {
        Id = "vip_gold_crown",
        Category = "VipTag",
        Name = "VIP Crown Tag",
        NameTR = "VIP Taç Etiketi",
        RequiredProductId = "prod_vip_nametag",
        PrimaryColor = Color3.fromRGB(255, 215, 45),
        SecondaryColor = Color3.fromRGB(255, 125, 35),
        TagText = "👑 VIP",
    },

    -- Pet Appearances (cosmetic only!)
    {
        Id = "pet_frost_wisp",
        Category = "PetSkin",
        Name = "Frost Wisp",
        NameTR = "Buz Perisi",
        RequiredProductId = "prod_custom_pets",
        PrimaryColor = Color3.fromRGB(120, 235, 255),
        SecondaryColor = Color3.fromRGB(240, 255, 255),
    },
    {
        Id = "pet_ember_dragon",
        Category = "PetSkin",
        Name = "Ember Dragonling",
        NameTR = "Kor Ejdercik",
        RequiredProductId = "prod_custom_pets",
        PrimaryColor = Color3.fromRGB(255, 85, 35),
        SecondaryColor = Color3.fromRGB(255, 210, 75),
    },
    {
        Id = "pet_starlight_orb",
        Category = "PetSkin",
        Name = "Starlight Orb",
        NameTR = "Yıldız Küresi",
        RequiredProductId = "prod_custom_pets",
        PrimaryColor = Color3.fromRGB(190, 115, 255),
        SecondaryColor = Color3.fromRGB(255, 195, 255),
    },
    {
        Id = "pet_clockwork_owl",
        Category = "PetSkin",
        Name = "Clockwork Owl",
        NameTR = "Kurmalı Baykuş",
        RequiredProductId = "prod_custom_pets",
        PrimaryColor = Color3.fromRGB(255, 200, 85),
        SecondaryColor = Color3.fromRGB(110, 225, 255),
    },
    {
        Id = "pet_void_phoenix",
        Category = "PetSkin",
        Name = "Celestial Void Phoenix",
        NameTR = "Göksel Hiçlik Ankası",
        RequiredProductId = "prod_extra_cosmetic_pack",
        PrimaryColor = Color3.fromRGB(0, 255, 235),
        SecondaryColor = Color3.fromRGB(255, 75, 225),
    },
}

local ProductById: { [string]: Types.RobuxProductDef } = {}
local ProductByGamePassId: { [number]: Types.RobuxProductDef } = {}
for _, p in ipairs(Products) do
    ProductById[p.Id] = p
    ProductByGamePassId[p.GamePassId] = p
end

local AssetById: { [string]: Types.CosmeticAssetDef } = {}
for _, a in ipairs(Assets) do
    AssetById[a.Id] = a
end

local CosmeticCatalog = {
    Products = table.freeze(Products),
    ProductById = table.freeze(ProductById),
    ProductByGamePassId = table.freeze(ProductByGamePassId),
    Assets = table.freeze(Assets),
    AssetById = table.freeze(AssetById),
}

function CosmeticCatalog.GetAsset(assetId: string): Types.CosmeticAssetDef?
    return AssetById[assetId]
end

function CosmeticCatalog.GetProduct(productId: string): Types.RobuxProductDef?
    return ProductById[productId]
end

function CosmeticCatalog.PlayerOwnsAsset(ownedProducts: { [string]: boolean }, assetId: string): boolean
    local asset = AssetById[assetId]
    if not asset then
        return false
    end
    if ownedProducts[asset.RequiredProductId] then
        return true
    end
    -- Extra Cosmetic Pack grants VIP + bundle exclusives
    if ownedProducts["prod_extra_cosmetic_pack"] then
        local bundle = ProductById["prod_extra_cosmetic_pack"]
        if bundle then
            for _, unlockedId in ipairs(bundle.UnlocksCosmetics) do
                if unlockedId == assetId then
                    return true
                end
            end
        end
    end
    return false
end

return table.freeze(CosmeticCatalog)
