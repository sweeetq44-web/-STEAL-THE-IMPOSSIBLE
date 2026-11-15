--!strict
-- Complete Item Catalog for STEAL THE IMPOSSIBLE
-- Includes the 5 signature Impossible items, Biome loot, Co-op Vault relics,
-- 0.01% SECRET COLLECTION, Galaxy Egg Hatch Pool, and Weekly Limited Items.

local Types = require(script.Parent.Types)
local WeeklyItems = require(script.Parent.WeeklyItems)
local MutationConfig = require(script.Parent.MutationConfig)

export type GalaxyCreatureDef = {
    Id: string,
    Name: string,
    NameTR: string,
    Icon: string,
    ChanceWeight: number,
    BonusIncomeMultiplier: number,
    Color: Color3,
}

local BaseItems: { Types.ItemDefinition } = {
    -- =========================================================================
    -- 5 SIGNATURE "IMPOSSIBLE" ITEMS (Featured in Game Pitch)
    -- =========================================================================
    {
        Id = "frozen_sun",
        Name = "Frozen Sun",
        NameTR = "Buzdan Güneş",
        Description = "A blazing miniature star locked inside eternal crystalline ice.",
        DescriptionTR = "Buzdan yapılmış güneş. Sonsuz kristal buzun içinde parlayan bir yıldız.",
        Icon = "🧊",
        Rarity = "Impossible",
        BiomeId = "FrostCitadel",
        BaseCashValue = 75000,
        PassiveIncomePerSec = 620,
        VisualStyle = "FrozenSun",
        PrimaryColor = Color3.fromRGB(115, 235, 255),
        SecondaryColor = Color3.fromRGB(255, 195, 55),
        SpecialBehavior = "FrostHalo",
    },
    {
        Id = "mini_apocalypse",
        Name = "Mini Apocalypse",
        NameTR = "Mini Kıyamet",
        Description = "A pocket-sized dragon capable of unleashing miniature cataclysms.",
        DescriptionTR = "Kıyamet çıkarabilen minik ejderha. Taşıyıcısının omzunda alev saçar.",
        Icon = "🐉",
        Rarity = "Impossible",
        BiomeId = "AbyssalCaldera",
        BaseCashValue = 78000,
        PassiveIncomePerSec = 650,
        VisualStyle = "MiniApocalypse",
        PrimaryColor = Color3.fromRGB(255, 75, 45),
        SecondaryColor = Color3.fromRGB(45, 25, 35),
        SpecialBehavior = "MiniFireAura",
    },
    {
        Id = "time_eater",
        Name = "Time Eater",
        NameTR = "Zaman Yiyen",
        Description = "An ancient fractured timepiece that devours seconds from existence.",
        DescriptionTR = "Zamanı yiyen saat. Akrep ve yelkovanı tersine döner.",
        Icon = "⏳",
        Rarity = "Impossible",
        BiomeId = "ChronosRuins",
        BaseCashValue = 80000,
        PassiveIncomePerSec = 670,
        VisualStyle = "TimeEater",
        PrimaryColor = Color3.fromRGB(255, 215, 95),
        SecondaryColor = Color3.fromRGB(110, 225, 255),
        SpecialBehavior = "ReverseClock",
    },
    {
        Id = "the_last_eye",
        Name = "The Last Eye",
        NameTR = "Son Göz",
        Description = "A mysterious eldritch eye that relentlessly locks onto and tracks players.",
        DescriptionTR = "Oyuncuyu takip eden gizemli göz. Etrafındaki her hareketi izler.",
        Icon = "👁️",
        Rarity = "Impossible",
        BiomeId = "WatchersSanctum",
        BaseCashValue = 84000,
        PassiveIncomePerSec = 700,
        VisualStyle = "TheLastEye",
        PrimaryColor = Color3.fromRGB(210, 75, 255),
        SecondaryColor = Color3.fromRGB(25, 255, 210),
        SpecialBehavior = "TracksPlayer",
    },
    {
        Id = "galaxy_egg",
        Name = "Galaxy Egg",
        NameTR = "Galaksi Yumurtası",
        Description = "A cosmic egg pulsing with nebulae. Flex it or hatch a Galaxy Creature!",
        DescriptionTR = "İçinden rastgele galaksi yaratığı çıkan yumurta. Üssünde sergile veya çatlat!",
        Icon = "🌌",
        Rarity = "Impossible",
        BiomeId = "AstralVoid",
        BaseCashValue = 88000,
        PassiveIncomePerSec = 740,
        VisualStyle = "GalaxyEgg",
        PrimaryColor = Color3.fromRGB(120, 85, 255),
        SecondaryColor = Color3.fromRGB(255, 115, 225),
        SpecialBehavior = "HatchableEgg",
    },

    -- =========================================================================
    -- 0.01% SECRET COLLECTION (Triggers Global Announcement Across All Servers!)
    -- =========================================================================
    {
        Id = "secret_zero_singularity",
        Name = "Absolute Zero Singularity",
        NameTR = "Mutlak Sıfır Tekilliği",
        Description = "0.01% SECRET! A frozen black hole shattering thermodynamics itself.",
        DescriptionTR = "%0.01 GİZLİ! Termodinamiği donduran donmuş kara delik.",
        Icon = "💠",
        Rarity = "Secret",
        BiomeId = "FrostCitadel",
        BaseCashValue = 500000,
        PassiveIncomePerSec = 4200,
        VisualStyle = "OrbSingularity",
        PrimaryColor = Color3.fromRGB(0, 255, 255),
        SecondaryColor = Color3.fromRGB(255, 255, 255),
        SpecialBehavior = "FrostHalo",
        IsSecret = true,
    },
    {
        Id = "secret_primordial_ash",
        Name = "Primordial Worldburner",
        NameTR = "Kadim Dünya Yakan",
        Description = "0.01% SECRET! The first ember that ignited the cosmos.",
        DescriptionTR = "%0.01 GİZLİ! Evreni tutuşturan ilk kadim kor.",
        Icon = "🔥",
        Rarity = "Secret",
        BiomeId = "AbyssalCaldera",
        BaseCashValue = 520000,
        PassiveIncomePerSec = 4400,
        VisualStyle = "DragonTotem",
        PrimaryColor = Color3.fromRGB(255, 50, 120),
        SecondaryColor = Color3.fromRGB(255, 215, 65),
        SpecialBehavior = "MiniFireAura",
        IsSecret = true,
    },
    {
        Id = "secret_eternity_fracture",
        Name = "Fracture of Eternity",
        NameTR = "Sonsuzluk Kırığı",
        Description = "0.01% SECRET! Every past and future timeline compressed into gold.",
        DescriptionTR = "%0.01 GİZLİ! Tüm geçmiş ve gelecek zamanların sıkıştırılmış hali.",
        Icon = "⌛",
        Rarity = "Secret",
        BiomeId = "ChronosRuins",
        BaseCashValue = 540000,
        PassiveIncomePerSec = 4600,
        VisualStyle = "ClockworkGear",
        PrimaryColor = Color3.fromRGB(255, 240, 130),
        SecondaryColor = Color3.fromRGB(0, 245, 255),
        SpecialBehavior = "ReverseClock",
        IsSecret = true,
    },
    {
        Id = "secret_omniscient_pupil",
        Name = "The Omniscient Pupil",
        NameTR = "Her Şeyi Gören Gözbebeği",
        Description = "0.01% SECRET! It sees across every server simultaneously.",
        DescriptionTR = "%0.01 GİZLİ! Aynı anda tüm sunucuları görür.",
        Icon = "🧿",
        Rarity = "Secret",
        BiomeId = "WatchersSanctum",
        BaseCashValue = 560000,
        PassiveIncomePerSec = 4800,
        VisualStyle = "TheLastEye",
        PrimaryColor = Color3.fromRGB(0, 255, 215),
        SecondaryColor = Color3.fromRGB(255, 55, 225),
        SpecialBehavior = "TracksPlayer",
        IsSecret = true,
    },
    {
        Id = "secret_big_bang_embryo",
        Name = "Big Bang Embryo",
        NameTR = "Büyük Patlama Embriyosu",
        Description = "0.01% SECRET! An entire unborn universe swirling inside crystal.",
        DescriptionTR = "%0.01 GİZLİ! Kristalin içinde dönen doğmamış bir evren.",
        Icon = "✨",
        Rarity = "Secret",
        BiomeId = "AstralVoid",
        BaseCashValue = 600000,
        PassiveIncomePerSec = 5200,
        VisualStyle = "GalaxyEgg",
        PrimaryColor = Color3.fromRGB(255, 95, 255),
        SecondaryColor = Color3.fromRGB(95, 255, 255),
        SpecialBehavior = "HatchableEgg",
        IsSecret = true,
    },
    {
        Id = "secret_glitch_crown",
        Name = "Developer's Impossible Crown",
        NameTR = "İmkânsızlığın Tacı",
        Description = "0.01% SECRET! Only found inside the 15-min Special Rift Dimension.",
        DescriptionTR = "%0.01 GİZLİ! Sadece 15 dakikalık Özel Yarık Boyutunda bulunur.",
        Icon = "💎",
        Rarity = "Secret",
        BiomeId = "SpecialRift",
        BaseCashValue = 650000,
        PassiveIncomePerSec = 5600,
        VisualStyle = "CrownRelic",
        PrimaryColor = Color3.fromRGB(0, 255, 195),
        SecondaryColor = Color3.fromRGB(255, 215, 0),
        IsSecret = true,
    },

    -- =========================================================================
    -- BIOME 1: FROST CITADEL (Common -> Mythic)
    -- =========================================================================
    {
        Id = "frost_icicle_shard",
        Name = "Cryo Shard",
        NameTR = "Buzul Parçası",
        Description = "A sharp piece of unmelting glacier crystal.",
        DescriptionTR = "Erimeyen buzul kristalinden keskin bir parça.",
        Icon = "❄️",
        Rarity = "Common",
        BiomeId = "FrostCitadel",
        BaseCashValue = 120,
        PassiveIncomePerSec = 3,
        VisualStyle = "CrystalRelic",
        PrimaryColor = Color3.fromRGB(145, 225, 255),
        SecondaryColor = Color3.fromRGB(220, 248, 255),
    },
    {
        Id = "frost_snow_lantern",
        Name = "Winterbound Lantern",
        NameTR = "Kış Feneri",
        Description = "Captures cold blue aurora light inside frost glass.",
        DescriptionTR = "Buz camının içinde soğuk aurora ışığını hapseder.",
        Icon = "🏮",
        Rarity = "Uncommon",
        BiomeId = "FrostCitadel",
        BaseCashValue = 360,
        PassiveIncomePerSec = 8,
        VisualStyle = "CubeArtifact",
        PrimaryColor = Color3.fromRGB(90, 215, 255),
        SecondaryColor = Color3.fromRGB(190, 255, 255),
    },
    {
        Id = "frost_permafrost_cube",
        Name = "Sub-Zero Tesseract",
        NameTR = "Sıfır Altı Küpü",
        Description = "Freezes air molecules that drift too close.",
        DescriptionTR = "Yaklaşan havayı donduran gizemli küp.",
        Icon = "🟦",
        Rarity = "Rare",
        BiomeId = "FrostCitadel",
        BaseCashValue = 1150,
        PassiveIncomePerSec = 22,
        VisualStyle = "CubeArtifact",
        PrimaryColor = Color3.fromRGB(65, 185, 255),
        SecondaryColor = Color3.fromRGB(205, 245, 255),
    },
    {
        Id = "frost_glacial_crown",
        Name = "Glacial Monarch Crown",
        NameTR = "Buzul Kralı Tacı",
        Description = "Worn by forgotten rulers of the northern peaks.",
        DescriptionTR = "Kuzey zirvelerinin unutulmuş hükümdarlarının tacı.",
        Icon = "👑",
        Rarity = "Epic",
        BiomeId = "FrostCitadel",
        BaseCashValue = 4200,
        PassiveIncomePerSec = 54,
        VisualStyle = "CrownRelic",
        PrimaryColor = Color3.fromRGB(120, 235, 255),
        SecondaryColor = Color3.fromRGB(240, 250, 255),
    },
    {
        Id = "frost_aurora_heart",
        Name = "Heart of the Aurora",
        NameTR = "Aurora Kalbi",
        Description = "Beats once every ten seconds with polar magnetism.",
        DescriptionTR = "Her on saniyede bir kutup ışığıyla atar.",
        Icon = "🩵",
        Rarity = "Mythic",
        BiomeId = "FrostCitadel",
        BaseCashValue = 14500,
        PassiveIncomePerSec = 135,
        VisualStyle = "OrbSingularity",
        PrimaryColor = Color3.fromRGB(65, 255, 215),
        SecondaryColor = Color3.fromRGB(115, 165, 255),
    },

    -- =========================================================================
    -- BIOME 2: ABYSSAL CALDERA (Common -> Mythic)
    -- =========================================================================
    {
        Id = "caldera_obsidian_chip",
        Name = "Molten Obsidian",
        NameTR = "Erimiş Obsidyen",
        Description = "Volcanic glass still glowing from the crater floor.",
        DescriptionTR = "Krater tabanından yeni çıkmış sıcak volkanik cam.",
        Icon = "🪨",
        Rarity = "Common",
        BiomeId = "AbyssalCaldera",
        BaseCashValue = 130,
        PassiveIncomePerSec = 3,
        VisualStyle = "CrystalRelic",
        PrimaryColor = Color3.fromRGB(255, 110, 45),
        SecondaryColor = Color3.fromRGB(45, 35, 45),
    },
    {
        Id = "caldera_ember_core",
        Name = "Living Ember Core",
        NameTR = "Yaşayan Kor Çekirdeği",
        Description = "Hums softly like a sleeping volcano.",
        DescriptionTR = "Uyuyan bir yanardağ gibi derinden uğuldar.",
        Icon = "🔥",
        Rarity = "Uncommon",
        BiomeId = "AbyssalCaldera",
        BaseCashValue = 390,
        PassiveIncomePerSec = 9,
        VisualStyle = "OrbSingularity",
        PrimaryColor = Color3.fromRGB(255, 125, 35),
        SecondaryColor = Color3.fromRGB(255, 215, 70),
    },
    {
        Id = "caldera_magma_cube",
        Name = "Magma Containment Cube",
        NameTR = "Magma Muhafaza Küpü",
        Description = "Pressurized lava suspended in magnetic basalt.",
        DescriptionTR = "Manyetik bazalt içinde sıkıştırılmış lav.",
        Icon = "🟥",
        Rarity = "Rare",
        BiomeId = "AbyssalCaldera",
        BaseCashValue = 1220,
        PassiveIncomePerSec = 24,
        VisualStyle = "CubeArtifact",
        PrimaryColor = Color3.fromRGB(255, 75, 35),
        SecondaryColor = Color3.fromRGB(255, 185, 50),
    },
    {
        Id = "caldera_infernal_idol",
        Name = "Infernal Drake Totem",
        NameTR = "Cehennem Ejder Totemi",
        Description = "Carved dragon idol infused with brimstone.",
        DescriptionTR = "Kükürt ateşiyle işlenmiş kadim ejderha totemi.",
        Icon = "🐲",
        Rarity = "Epic",
        BiomeId = "AbyssalCaldera",
        BaseCashValue = 4500,
        PassiveIncomePerSec = 58,
        VisualStyle = "DragonTotem",
        PrimaryColor = Color3.fromRGB(255, 65, 55),
        SecondaryColor = Color3.fromRGB(255, 200, 75),
    },
    {
        Id = "caldera_phoenix_core",
        Name = "Superheated Phoenix Egg",
        NameTR = "Anka Çekirdeği",
        Description = "Radiates fierce solar flares when carried.",
        DescriptionTR = "Taşındığında yoğun güneş patlamaları saçar.",
        Icon = "🌋",
        Rarity = "Mythic",
        BiomeId = "AbyssalCaldera",
        BaseCashValue = 15200,
        PassiveIncomePerSec = 142,
        VisualStyle = "OrbSingularity",
        PrimaryColor = Color3.fromRGB(255, 95, 25),
        SecondaryColor = Color3.fromRGB(255, 240, 125),
    },

    -- =========================================================================
    -- BIOME 3: CHRONOS RUINS (Common -> Mythic)
    -- =========================================================================
    {
        Id = "chronos_brass_cog",
        Name = "Ancient Brass Cog",
        NameTR = "Kadim Pirinç Dişli",
        Description = "Spinning effortlessly without an engine.",
        DescriptionTR = "Motoru olmadan kendi kendine dönen antik dişli.",
        Icon = "⚙️",
        Rarity = "Common",
        BiomeId = "ChronosRuins",
        BaseCashValue = 135,
        PassiveIncomePerSec = 4,
        VisualStyle = "ClockworkGear",
        PrimaryColor = Color3.fromRGB(225, 185, 95),
        SecondaryColor = Color3.fromRGB(130, 95, 45),
    },
    {
        Id = "chronos_sand_vial",
        Name = "Floating Sandglass",
        NameTR = "Yüzen Kum Saati",
        Description = "Its golden sand drifts upward.",
        DescriptionTR = "Altın kumları yukarı doğru akıyor.",
        Icon = "⌛",
        Rarity = "Uncommon",
        BiomeId = "ChronosRuins",
        BaseCashValue = 410,
        PassiveIncomePerSec = 9,
        VisualStyle = "CrystalRelic",
        PrimaryColor = Color3.fromRGB(255, 210, 105),
        SecondaryColor = Color3.fromRGB(95, 215, 255),
    },
    {
        Id = "chronos_pendulum",
        Name = "Paradox Pendulum",
        NameTR = "Paradoks Sarkacı",
        Description = "Swings slightly ahead of physical time.",
        DescriptionTR = "Fiziksel zamandan bir saniye önde sallanır.",
        Icon = "🕰️",
        Rarity = "Rare",
        BiomeId = "ChronosRuins",
        BaseCashValue = 1280,
        PassiveIncomePerSec = 25,
        VisualStyle = "ClockworkGear",
        PrimaryColor = Color3.fromRGB(255, 200, 75),
        SecondaryColor = Color3.fromRGB(165, 245, 255),
    },
    {
        Id = "chronos_astrolabe",
        Name = "Astronomer's Astrolabe",
        NameTR = "Zaman Usturlabı",
        Description = "Maps the exact collision of dimensions.",
        DescriptionTR = "Boyutların kesişim noktasını hesaplar.",
        Icon = "🧭",
        Rarity = "Epic",
        BiomeId = "ChronosRuins",
        BaseCashValue = 4600,
        PassiveIncomePerSec = 60,
        VisualStyle = "ClockworkGear",
        PrimaryColor = Color3.fromRGB(255, 225, 110),
        SecondaryColor = Color3.fromRGB(190, 105, 255),
    },
    {
        Id = "chronos_hourglass_king",
        Name = "Sovereign Sundial",
        NameTR = "Hükümdar Güneş Saati",
        Description = "Warps shadows around whoever possesses it.",
        DescriptionTR = "Sahibinin etrafındaki gölgeleri büker.",
        Icon = "☀️",
        Rarity = "Mythic",
        BiomeId = "ChronosRuins",
        BaseCashValue = 15800,
        PassiveIncomePerSec = 148,
        VisualStyle = "TimeEater",
        PrimaryColor = Color3.fromRGB(255, 215, 70),
        SecondaryColor = Color3.fromRGB(80, 235, 255),
    },

    -- =========================================================================
    -- BIOME 4: WATCHERS' SANCTUM (Common -> Mythic)
    -- =========================================================================
    {
        Id = "watcher_echo_prism",
        Name = "Whispering Prism",
        NameTR = "Fısıldayan Prizma",
        Description = "Refracts footsteps from empty corridors.",
        DescriptionTR = "Boş koridorlardaki ayak seslerini yansıtır.",
        Icon = "🔮",
        Rarity = "Common",
        BiomeId = "WatchersSanctum",
        BaseCashValue = 140,
        PassiveIncomePerSec = 4,
        VisualStyle = "VoidPrism",
        PrimaryColor = Color3.fromRGB(185, 110, 255),
        SecondaryColor = Color3.fromRGB(80, 35, 130),
    },
    {
        Id = "watcher_void_lantern",
        Name = "Abyssal Lantern",
        NameTR = "Hiçlik Feneri",
        Description = "Illuminates invisible shadows instead of light.",
        DescriptionTR = "Işık yerine görünmez gölgeleri aydınlatır.",
        Icon = "🟣",
        Rarity = "Uncommon",
        BiomeId = "WatchersSanctum",
        BaseCashValue = 430,
        PassiveIncomePerSec = 10,
        VisualStyle = "CubeArtifact",
        PrimaryColor = Color3.fromRGB(175, 75, 255),
        SecondaryColor = Color3.fromRGB(35, 240, 215),
    },
    {
        Id = "watcher_gaze_totem",
        Name = "Sentinel Monolith",
        NameTR = "Nöbetçi Dikilitaş",
        Description = "Its etched pupil blinks when thieves approach.",
        DescriptionTR = "Hırsız yaklaştığında oyulmuş gözü kırpılır.",
        Icon = "🧿",
        Rarity = "Rare",
        BiomeId = "WatchersSanctum",
        BaseCashValue = 1350,
        PassiveIncomePerSec = 26,
        VisualStyle = "VoidPrism",
        PrimaryColor = Color3.fromRGB(195, 70, 255),
        SecondaryColor = Color3.fromRGB(45, 255, 210),
    },
    {
        Id = "watcher_eclipse_mask",
        Name = "Oracle's Veil",
        NameTR = "Kâhinin Peçesi",
        Description = "Grants uncanny awareness of rival chases.",
        DescriptionTR = "Peşindeki rakipleri hissetmeni sağlayan antik maske.",
        Icon = "🎭",
        Rarity = "Epic",
        BiomeId = "WatchersSanctum",
        BaseCashValue = 4800,
        PassiveIncomePerSec = 62,
        VisualStyle = "VoidPrism",
        PrimaryColor = Color3.fromRGB(160, 65, 255),
        SecondaryColor = Color3.fromRGB(255, 95, 195),
    },
    {
        Id = "watcher_third_lens",
        Name = "Astral Watcher Lens",
        NameTR = "Astral Gözcü Merceği",
        Description = "Peeks slightly through solid vault doors.",
        DescriptionTR = "Kasa kapılarının ötesini gören mistik mercek.",
        Icon = "👁️",
        Rarity = "Mythic",
        BiomeId = "WatchersSanctum",
        BaseCashValue = 16200,
        PassiveIncomePerSec = 155,
        VisualStyle = "TheLastEye",
        PrimaryColor = Color3.fromRGB(195, 65, 255),
        SecondaryColor = Color3.fromRGB(55, 255, 225),
        SpecialBehavior = "TracksPlayer",
    },

    -- =========================================================================
    -- BIOME 5: ASTRAL VOID (Common -> Mythic)
    -- =========================================================================
    {
        Id = "astral_stardust",
        Name = "Condensed Stardust",
        NameTR = "Yoğun Yıldız Tozu",
        Description = "Weightless glitter scraped off a shooting star.",
        DescriptionTR = "Kayan bir yıldızdan toplanmış ağırlıksız parıltı.",
        Icon = "⭐",
        Rarity = "Common",
        BiomeId = "AstralVoid",
        BaseCashValue = 145,
        PassiveIncomePerSec = 4,
        VisualStyle = "CrystalRelic",
        PrimaryColor = Color3.fromRGB(130, 175, 255),
        SecondaryColor = Color3.fromRGB(255, 165, 245),
    },
    {
        Id = "astral_comet_fragment",
        Name = "Orbital Meteorite",
        NameTR = "Yörünge Meteoriti",
        Description = "Hovers three inches above any surface.",
        DescriptionTR = "Her yüzeyin üç parmak üzerinde süzülür.",
        Icon = "☄️",
        Rarity = "Uncommon",
        BiomeId = "AstralVoid",
        BaseCashValue = 450,
        PassiveIncomePerSec = 10,
        VisualStyle = "OrbSingularity",
        PrimaryColor = Color3.fromRGB(115, 145, 255),
        SecondaryColor = Color3.fromRGB(255, 130, 235),
    },
    {
        Id = "astral_nebula_cube",
        Name = "Nebula Bottle",
        NameTR = "Nebula Şişesi",
        Description = "A swirling pink galaxy sealed inside zero-G glass.",
        DescriptionTR = "Sıfır yerçekimli camın içinde dönen pembe galaksi.",
        Icon = "🪐",
        Rarity = "Rare",
        BiomeId = "AstralVoid",
        BaseCashValue = 1400,
        PassiveIncomePerSec = 28,
        VisualStyle = "CubeArtifact",
        PrimaryColor = Color3.fromRGB(135, 95, 255),
        SecondaryColor = Color3.fromRGB(255, 110, 215),
    },
    {
        Id = "astral_quasar_core",
        Name = "Quasar Heart",
        NameTR = "Kuasar Kalbi",
        Description = "Spinning beam of pure cosmic plasma.",
        DescriptionTR = "Saf kozmik plazmadan dönen bir çekirdek.",
        Icon = "💫",
        Rarity = "Epic",
        BiomeId = "AstralVoid",
        BaseCashValue = 5000,
        PassiveIncomePerSec = 65,
        VisualStyle = "OrbSingularity",
        PrimaryColor = Color3.fromRGB(95, 185, 255),
        SecondaryColor = Color3.fromRGB(255, 95, 235),
    },
    {
        Id = "astral_celestial_crown",
        Name = "Crown of Constellations",
        NameTR = "Takımyıldız Tacı",
        Description = "Each jewel corresponds to a living star system.",
        DescriptionTR = "Her mücevheri yaşayan bir yıldız sistemini simgeler.",
        Icon = "🌠",
        Rarity = "Mythic",
        BiomeId = "AstralVoid",
        BaseCashValue = 17000,
        PassiveIncomePerSec = 165,
        VisualStyle = "CrownRelic",
        PrimaryColor = Color3.fromRGB(115, 195, 255),
        SecondaryColor = Color3.fromRGB(255, 185, 255),
    },

    -- =========================================================================
    -- 15-MINUTE SPECIAL RIFT & CO-OP BIG HEIST EXCLUSIVE LOOT
    -- =========================================================================
    {
        Id = "rift_quantum_hypercube",
        Name = "Quantum Hypercube",
        NameTR = "Kuantum Hiperküpü",
        Description = "Exists in four dimensions only while the 15-min Rift is open.",
        DescriptionTR = "Sadece 15 dakikalık Yarık açıkken dört boyutta var olur.",
        Icon = "🟪",
        Rarity = "Mythic",
        BiomeId = "SpecialRift",
        BaseCashValue = 22000,
        PassiveIncomePerSec = 195,
        VisualStyle = "CubeArtifact",
        PrimaryColor = Color3.fromRGB(0, 255, 185),
        SecondaryColor = Color3.fromRGB(185, 65, 255),
    },
    {
        Id = "rift_mirage_relic",
        Name = "Atlantean Pearl",
        NameTR = "Atlantis İncisi",
        Description = "Glowing bioluminescent treasure from the Rift ocean.",
        DescriptionTR = "Yarık okyanusundan parlayan biyolüminesan hazine.",
        Icon = "🫧",
        Rarity = "Epic",
        BiomeId = "SpecialRift",
        BaseCashValue = 6200,
        PassiveIncomePerSec = 78,
        VisualStyle = "OrbSingularity",
        PrimaryColor = Color3.fromRGB(65, 255, 235),
        SecondaryColor = Color3.fromRGB(45, 130, 255),
    },
    {
        Id = "rift_dimension_key",
        Name = "Impossible Rift Key",
        NameTR = "İmkânsız Yarık Anahtarı",
        Description = "A master key forged between worlds during Rift openings.",
        DescriptionTR = "Yarık açılışlarında dünyalar arasında dövülen usta anahtar.",
        Icon = "🗝️",
        Rarity = "Impossible",
        BiomeId = "SpecialRift",
        BaseCashValue = 95000,
        PassiveIncomePerSec = 820,
        VisualStyle = "CrownRelic",
        PrimaryColor = Color3.fromRGB(0, 255, 225),
        SecondaryColor = Color3.fromRGB(255, 215, 65),
    },
    {
        Id = "heist_vault_core",
        Name = "Titan Bank Core",
        NameTR = "Titan Kasa Çekirdeği",
        Description = "Extracted only via synchronized Squad Co-op Heists!",
        DescriptionTR = "Sadece Takım Soygunu ile kasadan çıkarılabilir!",
        Icon = "💰",
        Rarity = "Impossible",
        BiomeId = "BigHeistVault",
        BaseCashValue = 92000,
        PassiveIncomePerSec = 780,
        VisualStyle = "CubeArtifact",
        PrimaryColor = Color3.fromRGB(255, 215, 55),
        SecondaryColor = Color3.fromRGB(35, 225, 145),
    },
    {
        Id = "world_ending_meteor_core",
        Name = "Apocalypse Star Shard",
        NameTR = "Kıyamet Yıldızı Parçası",
        Description = "Dropped directly during THE WORLD IS ENDING catastrophe!",
        DescriptionTR = "DÜNYA YOK OLUYOR felaketi sırasında gökten düşer!",
        Icon = "☄️",
        Rarity = "Impossible",
        BiomeId = "WorldEvent",
        BaseCashValue = 98000,
        PassiveIncomePerSec = 860,
        VisualStyle = "FrozenSun",
        PrimaryColor = Color3.fromRGB(255, 90, 45),
        SecondaryColor = Color3.fromRGB(255, 225, 95),
        SpecialBehavior = "MiniFireAura",
    },
}

-- Merge Weekly Items dynamically
local AllItemsList: { Types.ItemDefinition } = {}
local ById: { [string]: Types.ItemDefinition } = {}
local ByBiomeAndRarity: { [string]: { [Types.RarityId]: { Types.ItemDefinition } } } = {}
local SecretsList: { Types.ItemDefinition } = {}

local function registerItem(def: Types.ItemDefinition)
    table.insert(AllItemsList, def)
    ById[def.Id] = def
    if def.IsSecret or def.Rarity == "Secret" then
        table.insert(SecretsList, def)
    end
    if not ByBiomeAndRarity[def.BiomeId] then
        ByBiomeAndRarity[def.BiomeId] = {}
    end
    if not ByBiomeAndRarity[def.BiomeId][def.Rarity] then
        ByBiomeAndRarity[def.BiomeId][def.Rarity] = {}
    end
    table.insert(ByBiomeAndRarity[def.BiomeId][def.Rarity], def)
end

for _, item in ipairs(BaseItems) do
    registerItem(item)
end
for _, weeklyItem in ipairs(WeeklyItems.Items) do
    registerItem(weeklyItem)
end

-- Galaxy Egg random creature hatch pool ("İçinden rastgele galaksi yaratığı çıkan yumurta")
local GalaxyCreatures: { GalaxyCreatureDef } = {
    {
        Id = "nebula_fox",
        Name = "Nebula Fox",
        NameTR = "Nebula Tilkisi",
        Icon = "🦊",
        ChanceWeight = 42,
        BonusIncomeMultiplier = 1.25,
        Color = Color3.fromRGB(165, 125, 255),
    },
    {
        Id = "starlight_owl",
        Name = "Starlight Owl",
        NameTR = "Yıldızışığı Baykuşu",
        Icon = "🦉",
        ChanceWeight = 30,
        BonusIncomeMultiplier = 1.45,
        Color = Color3.fromRGB(95, 225, 255),
    },
    {
        Id = "quasar_wyrm",
        Name = "Quasar Wyrm",
        NameTR = "Kuasar Ejderi",
        Icon = "🐉",
        ChanceWeight = 18,
        BonusIncomeMultiplier = 1.75,
        Color = Color3.fromRGB(255, 115, 220),
    },
    {
        Id = "supernova_griffin",
        Name = "Supernova Griffin",
        NameTR = "Süpernova Grifonu",
        Icon = "🦅",
        ChanceWeight = 8,
        BonusIncomeMultiplier = 2.25,
        Color = Color3.fromRGB(255, 210, 75),
    },
    {
        Id = "celestial_leviathan",
        Name = "Void Celestial Leviathan",
        NameTR = "Kozmik Leviathan",
        Icon = "🌌",
        ChanceWeight = 2,
        BonusIncomeMultiplier = 3.50,
        Color = Color3.fromRGB(0, 255, 235),
    },
}

local ItemCatalog = {
    All = table.freeze(AllItemsList),
    ById = table.freeze(ById),
    Secrets = table.freeze(SecretsList),
    GalaxyCreatures = table.freeze(GalaxyCreatures),
}

function ItemCatalog.Get(itemId: string): Types.ItemDefinition?
    return ById[itemId]
end

function ItemCatalog.GetPool(biomeId: string, rarity: Types.RarityId): { Types.ItemDefinition }
    local biomeMap = ByBiomeAndRarity[biomeId]
    if biomeMap and biomeMap[rarity] and #biomeMap[rarity] > 0 then
        return biomeMap[rarity]
    end
    -- Fallback across any item matching rarity
    local fallback: { Types.ItemDefinition } = {}
    for _, item in ipairs(AllItemsList) do
        if item.Rarity == rarity and item.BiomeId ~= "WorldEvent" and item.BiomeId ~= "BigHeistVault" then
            table.insert(fallback, item)
        end
    end
    if #fallback > 0 then
        return fallback
    end
    -- Second fallback: anything in the requested biome
    if biomeMap then
        for _, list in pairs(biomeMap) do
            for _, item in ipairs(list) do
                table.insert(fallback, item)
            end
        end
    end
    return fallback
end

function ItemCatalog.RollGalaxyCreature(rng: Random?): GalaxyCreatureDef
    local total = 0
    for _, c in ipairs(GalaxyCreatures) do
        total += c.ChanceWeight
    end
    local roll = (if rng then rng:NextNumber() else math.random()) * total
    local accum = 0
    for _, c in ipairs(GalaxyCreatures) do
        accum += c.ChanceWeight
        if roll <= accum then
            return c
        end
    end
    return GalaxyCreatures[1]
end

function ItemCatalog.GetInstanceMultiplier(inst: Types.OwnedItemInstance): number
    local mult = 1.0
    if inst.HatchedCreature then
        for _, c in ipairs(GalaxyCreatures) do
            if c.Id == inst.HatchedCreature then
                mult = mult * c.BonusIncomeMultiplier
                break
            end
        end
    end
    if inst.Mutation then
        mult = mult * MutationConfig.Get(inst.Mutation).ValueMultiplier
    end
    return mult
end

function ItemCatalog.GetMasteredBiomeCount(discoveredItems: { [string]: number }): number
    local biomeCoreItems: { [string]: { string } } = {}
    for _, item in ipairs(AllItemsList) do
        if not item.IsSecret and not item.IsWeekly and item.BiomeId ~= "WorldEvent" and item.BiomeId ~= "BigHeistVault" and item.BiomeId ~= "SpecialRift" then
            biomeCoreItems[item.BiomeId] = biomeCoreItems[item.BiomeId] or {}
            table.insert(biomeCoreItems[item.BiomeId], item.Id)
        end
    end

    local mastered = 0
    for _, ids in pairs(biomeCoreItems) do
        local allFound = (#ids > 0)
        for _, id in ipairs(ids) do
            if (discoveredItems[id] or 0) <= 0 then
                allFound = false
                break
            end
        end
        if allFound then
            mastered += 1
        end
    end
    return mastered
end

return table.freeze(ItemCatalog)
