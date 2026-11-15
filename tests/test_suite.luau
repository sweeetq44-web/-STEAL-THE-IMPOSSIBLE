--!strict
-- Comprehensive End-to-End Automated Test Suite for STEAL THE IMPOSSIBLE
-- Exercises the REAL Luau production modules inside the Luau VM!

return function(requireModule: (string) -> any, Mock: any)
    local passed = 0
    local failed = 0

    local function assertTrue(cond: boolean, label: string)
        if cond then
            passed += 1
        else
            failed += 1
            print("FAIL:", label)
        end
    end

    local function assertEq(actual: any, expected: any, label: string)
        if actual == expected then
            passed += 1
        else
            failed += 1
            print(string.format("FAIL: %s (expected=%s, actual=%s)", label, tostring(expected), tostring(actual)))
        end
    end

    -- Load Shared Modules
    local GameConfig = requireModule("ReplicatedStorage/Shared/GameConfig")
    local RarityConfig = requireModule("ReplicatedStorage/Shared/RarityConfig")
    local ItemCatalog = requireModule("ReplicatedStorage/Shared/ItemCatalog")
    local WeeklyItems = requireModule("ReplicatedStorage/Shared/WeeklyItems")
    local BiomeConfig = requireModule("ReplicatedStorage/Shared/BiomeConfig")
    local BaseConfig = requireModule("ReplicatedStorage/Shared/BaseConfig")
    local CosmeticCatalog = requireModule("ReplicatedStorage/Shared/CosmeticCatalog")
    local Localization = requireModule("ReplicatedStorage/Shared/Localization")
    local Remotes = requireModule("ReplicatedStorage/Shared/Remotes")
    local Utils = requireModule("ReplicatedStorage/Shared/Utils")

    -- Initialize Remotes & World
    Remotes.EnsureFolder()

    -- Load Server Services
    local DataService = requireModule("ServerScriptService/Server/Services/DataService")
    local WorldBuilder = requireModule("ServerScriptService/Server/Services/WorldBuilder")
    local SecretService = requireModule("ServerScriptService/Server/Services/SecretService")
    local BaseService = requireModule("ServerScriptService/Server/Services/BaseService")
    local ItemSpawnService = requireModule("ServerScriptService/Server/Services/ItemSpawnService")
    local CarryStealService = requireModule("ServerScriptService/Server/Services/CarryStealService")
    local SpecialZoneService = requireModule("ServerScriptService/Server/Services/SpecialZoneService")
    local WorldEventService = requireModule("ServerScriptService/Server/Services/WorldEventService")
    local SquadService = requireModule("ServerScriptService/Server/Services/SquadService")
    local HeistService = requireModule("ServerScriptService/Server/Services/HeistService")
    local ShopService = requireModule("ServerScriptService/Server/Services/ShopService")
    local MonetizationService = requireModule("ServerScriptService/Server/Services/MonetizationService")
    local LeaderboardService = requireModule("ServerScriptService/Server/Services/LeaderboardService")

    WorldBuilder.BuildIfMissing()
    DataService.Start()
    SecretService.Start()
    BaseService.Start()
    ItemSpawnService.Start()
    CarryStealService.Start()
    SpecialZoneService.Start()
    WorldEventService.Start()
    SquadService.Start()
    HeistService.Start()
    ShopService.Start()
    MonetizationService.Start()
    LeaderboardService.Start()

    -- TEST 1: Config & Rarity Exact Probabilities (Secret = 0.01%)
    assertEq(GameConfig.MAX_PLAYERS, 8, "Server size is 8 players")
    assertEq(GameConfig.SPECIAL_ZONE_INTERVAL_SECONDS, 900, "Special zone opens every 15 minutes (900s)")
    assertEq(GameConfig.WORLD_ENDING_INTERVAL_SECONDS, 1800, "World Is Ending triggers every 30 minutes (1800s)")
    assertEq(RarityConfig.Tiers.Secret.DropWeight, 0.01, "Secret rarity exact weight is 0.01%")

    local weightSum = 0
    for _, rId in ipairs(RarityConfig.Order) do
        weightSum += RarityConfig.Tiers[rId].DropWeight
    end
    assertTrue(math.abs(weightSum - 100.0) < 0.001, "All rarity weights sum to 100.00%")

    -- TEST 2: All 5 Signature Items + Weekly Items + 0.01% Secrets exist
    for _, sigId in ipairs({ "frozen_sun", "mini_apocalypse", "time_eater", "the_last_eye", "galaxy_egg" }) do
        assertTrue(ItemCatalog.Get(sigId) ~= nil, "Signature item exists: " .. sigId)
    end
    assertEq(ItemCatalog.Get("the_last_eye").SpecialBehavior, "TracksPlayer", "The Last Eye has TracksPlayer behavior")
    assertEq(ItemCatalog.Get("galaxy_egg").SpecialBehavior, "HatchableEgg", "Galaxy Egg is hatchable")
    assertTrue(#WeeklyItems.Items >= 3, "Weekly items loaded cleanly into ItemCatalog")
    assertTrue(#ItemCatalog.Secrets >= 6, "Secret collection contains 0.01% secrets")

    -- TEST 3: Ethical Robux Monetization Catalog Exact Pricing
    local expectedPrices = {
        prod_custom_skins = 99,
        prod_custom_bases = 149,
        prod_custom_animations = 49,
        prod_vip_nametag = 199,
        prod_custom_pets = 79,
        prod_extra_cosmetic_pack = 299,
    }
    for pid, price in pairs(expectedPrices) do
        local prod = CosmeticCatalog.GetProduct(pid)
        assertTrue(prod ~= nil and prod.RobuxPrice == price, "Robux product price matches: " .. pid .. " = " .. tostring(price))
    end

    -- TEST 4: 8 Players Join & Claim All 8 Bases, 9th Player Cannot Claim Extra Slot
    local players: { any } = {}
    for i = 1, 8 do
        local p = Mock.CreatePlayer(1000 + i, "Hunter" .. tostring(i))
        DataService.LoadPlayer(p)
        local slot = BaseService.ClaimBaseForPlayer(p)
        assertEq(slot, i, "Player " .. tostring(i) .. " claimed Base slot #" .. tostring(i))
        table.insert(players, p)
    end
    local extraP = Mock.CreatePlayer(9999, "Extra9th")
    assertEq(BaseService.ClaimBaseForPlayer(extraP), nil, "9th player blocked from claiming a 9th base")
    Mock.RemovePlayer(extraP)

    -- TEST 5: World Architecture Built (CentralPlaza, 8 Bases, 5 Biomes, SpecialRift, BigHeistVault)
    local gw = Mock.Globals.workspace:FindFirstChild("GameWorld")
    assertTrue(gw ~= nil, "GameWorld built in Workspace")
    assertEq(#BiomeConfig.Biomes, 5, "5 World Biomes configured")
    for _, b in ipairs(BiomeConfig.Biomes) do
        assertTrue(WorldBuilder.BiomeCenters[b.Id] ~= nil, "Biome center built: " .. b.Id)
    end

    -- TEST 6: Addictive Core Mechanic -> Pick Up Frozen Sun, Chase, Anti-Cheat Distance Check, Valid Steal & Deposit!
    local thief = players[1]
    local victim = players[2]
    local frozenSun = ItemCatalog.Get("frozen_sun")
    local spawnPos = Mock.Globals.Vector3.new(20, 5, 20)
    local node = ItemSpawnService.SpawnSpecificItemAt(frozenSun, spawnPos, "FrostCitadel", false)

    -- Too far away -> anti-exploit rejects pickup
    victim.Character.HumanoidRootPart.Position = Mock.Globals.Vector3.new(200, 5, 200)
    assertEq(CarryStealService.TryPickupWorldNode(victim, node), false, "Anti-exploit rejects pickup from 200 studs away")

    -- Move close -> victim grabs Frozen Sun!
    victim.Character.HumanoidRootPart.Position = Mock.Globals.Vector3.new(22, 5, 20)
    assertEq(CarryStealService.TryPickupWorldNode(victim, node), true, "Victim picks up Frozen Sun within reach")
    assertEq(CarryStealService.IsCarrying(victim), true, "Victim is now carrying Frozen Sun")

    -- Bypass brief 1.6s immunity window for steal test & place thief out of reach first
    CarryStealService.GetCarryRecord(victim).ImmunityUntil = 0
    thief.Character.HumanoidRootPart.Position = Mock.Globals.Vector3.new(80, 5, 80)
    local okFar, _ = CarryStealService.AttemptSteal(thief, victim)
    assertEq(okFar, false, "Anti-exploit rejects steal from >10.5 studs")

    -- Move thief within tackle reach -> STEAL SUCCEEDS!
    thief.Character.HumanoidRootPart.Position = Mock.Globals.Vector3.new(25, 5, 20)
    local okSteal, _ = CarryStealService.AttemptSteal(thief, victim)
    assertEq(okSteal, true, "Thief successfully tackles & steals Frozen Sun!")
    assertEq(CarryStealService.IsCarrying(victim), false, "Victim no longer carries item")
    assertEq(CarryStealService.IsCarrying(thief), true, "Thief now carries stolen Frozen Sun")
    assertEq(DataService.GetProfile(thief).TotalSteals, 1, "Thief steal counter incremented")

    -- Thief extracts safely at Base Deposit Pad!
    local cashBefore = DataService.GetProfile(thief).Cash
    assertEq(CarryStealService.DepositCarriedItem(thief), true, "Thief extracts Frozen Sun at Base")
    assertEq(CarryStealService.IsCarrying(thief), false, "Thief carry state cleared after extract")
    assertTrue(DataService.GetProfile(thief).Cash > cashBefore, "Thief earned extraction Cash bonus")
    assertEq(#DataService.GetProfile(thief).VaultItems, 1, "Frozen Sun stored in Vault & Pedestal")

    -- TEST 7: Galaxy Egg Hatching
    local eggDef = ItemCatalog.Get("galaxy_egg")
    assertEq(CarryStealService.GiveCarryItem(players[3], eggDef, "AstralVoid"), true, "Player 3 carries Galaxy Egg")
    assertEq(CarryStealService.DepositCarriedItem(players[3]), true, "Player 3 deposits Galaxy Egg")
    local eggInst = DataService.GetProfile(players[3]).VaultItems[1]
    local hatchOk, creatureId = SecretService.HatchGalaxyEgg(players[3], eggInst.Uid)
    assertEq(hatchOk, true, "Galaxy Egg hatched into random cosmic creature: " .. tostring(creatureId))

    -- TEST 8: 0.01% SECRET COLLECTION + MessagingService Global Announcement
    local secretItem = ItemCatalog.Get("secret_zero_singularity")
    local beforeMsgs = #SecretService.GetRecentAnnouncements()
    local globalSecretEvent = Remotes.GetEvent("GlobalSecretAnnouncement")
    local beforeFired = #globalSecretEvent._firedClients
    CarryStealService.GiveCarryItem(players[4], secretItem, "FrostCitadel")
    CarryStealService.DepositCarriedItem(players[4])
    local recent = SecretService.GetRecentAnnouncements()
    assertEq(#recent, beforeMsgs + 1, "0.01% Secret recorded in global secret announcement log!")
    assertEq(recent[1].PlayerName, "Hunter4", "Global announcement includes finder's name")
    assertEq(#globalSecretEvent._firedClients, beforeFired + 1, "GlobalSecretAnnouncement Remote fired to all clients!")
    assertEq(DataService.GetProfile(players[4]).SecretCount, 1, "Player 4 SecretCount incremented")

    -- TEST 9: 15-Minute Special Rift Zone Cycle
    SpecialZoneService.OpenRift(300)
    assertEq(SpecialZoneService.IsActive, true, "15-min Special Rift opens cleanly")
    assertTrue(ItemSpawnService.CountInBiome("SpecialRift") > 0, "Special Rift spawned exclusive items")
    SpecialZoneService.CloseRift()
    assertEq(SpecialZoneService.IsActive, false, "15-min Special Rift closes cleanly")

    -- TEST 10: 30-Minute "THE WORLD IS ENDING" (Meteor Shower, Giant Monster, Gravity Loss)
    WorldEventService.TriggerWorldEnding("GravityLoss", 45)
    assertEq(WorldEventService.IsActive, true, "World Ending GravityLoss started")
    assertEq(Mock.Globals.workspace.Gravity, GameConfig.ZERO_G_GRAVITY, "Workspace.Gravity lowered to 42 during GravityLoss")
    WorldEventService.EndWorldEnding()
    assertEq(Mock.Globals.workspace.Gravity, GameConfig.NORMAL_GRAVITY, "Workspace.Gravity restored to 196.2 after World Ending")

    WorldEventService.TriggerWorldEnding("MeteorShower", 10)
    assertEq(WorldEventService.CurrentEvent, "MeteorShower", "MeteorShower active")
    WorldEventService.EndWorldEnding()

    WorldEventService.TriggerWorldEnding("GiantMonster", 10)
    assertEq(WorldEventService.CurrentEvent, "GiantMonster", "GiantMonster active")
    WorldEventService.EndWorldEnding()

    -- TEST 11: FLEX YOUR BASE (Upgrades, Pedestals, Visit & Duplicate-Like Protection)
    DataService.AddCash(thief, 5000)
    local upgOk = BaseService.UpgradeBase(thief)
    assertEq(upgOk, true, "Thief upgraded Base to Tier 2")
    assertEq(DataService.GetProfile(thief).BaseTier, 2, "BaseTier persisted as 2")

    local likeOk1 = BaseService.LikeBase(players[2], thief.UserId)
    local likeOk2 = BaseService.LikeBase(players[2], thief.UserId)
    assertEq(likeOk1, true, "Visitor likes Thief's base")
    assertEq(likeOk2, false, "Duplicate like from same player blocked")
    assertEq(DataService.GetProfile(thief).TotalBaseLikes, 1, "Base likes count accurate")

    -- TEST 12: Squad & Co-op Big Heist Vault
    local sqOk, squad = SquadService.CreateSquad(players[5])
    assertEq(sqOk, true, "Player 5 created Squad")
    SquadService.InvitePlayer(players[5], players[6].UserId)
    local accOk = SquadService.AcceptInvite(players[6], squad.SquadId)
    assertEq(accOk, true, "Player 6 accepted Squad invite")
    local heistOk = HeistService.CheckAndTriggerCoopHeist({ players[5], players[6] })
    assertEq(heistOk, true, "Squad triggered Co-op Big Heist Vault!")
    assertEq(CarryStealService.IsCarrying(players[5]), true, "Player 5 carrying Titan Bank Core from Vault")
    assertEq(CarryStealService.IsCarrying(players[6]), true, "Player 6 carrying Titan Bank Core from Vault")

    -- TEST 13: Robux ProcessReceipt & Cosmetic Equipping + Localization EN/TR
    local receiptDecision = MonetizationService.ProcessReceipt({
        PlayerId = players[7].UserId,
        ProductId = CosmeticCatalog.GetProduct("prod_vip_nametag").GamePassId,
    })
    assertEq(receiptDecision, Mock.Globals.Enum.ProductPurchaseDecision.PurchaseGranted, "Marketplace ProcessReceipt grants VIP Tag")
    assertEq(DataService.GetProfile(players[7]).EquippedCosmetics.VipTagEnabled, true, "VIP Tag auto-equipped on purchase")

    assertEq(Localization.Get("WORLD_END_ACTIVE", "en"), "THE WORLD IS ENDING!", "EN translation check")
    assertEq(Localization.Get("WORLD_END_ACTIVE", "tr"), "DÜNYA YOK OLUYOR!", "TR translation check")

    -- TEST 14: RateLimiter & Leaderboard Sorting
    local rl = Utils.CreateRateLimiter()
    assertEq(rl:Check(555, "test", 1.0, 10.0), true, "RateLimiter allows first call")
    assertEq(rl:Check(555, "test", 1.0, 10.2), false, "RateLimiter blocks spam within cooldown")
    assertEq(rl:Check(555, "test", 1.0, 11.1), true, "RateLimiter allows after cooldown")

    local board = LeaderboardService.GetSnapshot()
    assertTrue(#board.NetWorth >= 8, "Leaderboard tracks all 8 players sorted by Net Worth")
    assertTrue(board.NetWorth[1].Value >= board.NetWorth[2].Value, "Leaderboard sorted descending")

    -- TEST 15: F2P Cash Upgrades & Gadgets + Inside-Base Shield Steal Protection
    local buyer = players[8]
    DataService.AddCash(buyer, 25000)
    local techOk = requireModule("ServerScriptService/Server/Services/ShopService").BuyTechUpgrade(buyer, "carry_boots")
    local gadOk = requireModule("ServerScriptService/Server/Services/ShopService").BuyGadget(buyer, "magnet_radar")
    assertEq(techOk, true, "F2P player bought Antigrav Carry Boots upgrade with Cash")
    assertEq(gadOk, true, "F2P player bought Magnet Radar gadget with Cash")

    -- Target standing safely inside own Base cannot be robbed!
    local shieldedCarrier = players[2]
    local shieldSlot = BaseService.GetPlayerSlot(shieldedCarrier)
    local shieldCF = BaseService.GetBaseCFrame(shieldSlot)
    shieldedCarrier.Character.HumanoidRootPart.Position = shieldCF.Position
    thief.Character.HumanoidRootPart.Position = shieldCF.Position + Mock.Globals.Vector3.new(2, 0, 0)
    CarryStealService.GiveCarryItem(shieldedCarrier, ItemCatalog.Get("time_eater"), "ChronosRuins")
    CarryStealService.GetCarryRecord(shieldedCarrier).ImmunityUntil = 0
    local stealInsideBaseOk, reason = CarryStealService.AttemptSteal(thief, shieldedCarrier)
    assertEq(stealInsideBaseOk, false, "Target protected inside their Base Shield: " .. tostring(reason))

    -- TEST 16: Client Controllers Init & Render Smoke Test
    local localPlr = players[1]
    Mock.Globals.game:GetService("Players").LocalPlayer = localPlr
    local pg = Mock.Globals.Instance.new("PlayerGui", "PlayerGui")
    pg.Parent = localPlr
    local rootGui = Mock.Globals.Instance.new("ScreenGui", "StealTheImpossibleUI")
    rootGui.Parent = pg

    local NotificationController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/NotificationController")
    local HUDController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/HUDController")
    local ActionController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/ActionController")
    local BaseManagerController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/BaseManagerController")
    local FlexVisitController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/FlexVisitController")
    local ShopCosmeticController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/ShopCosmeticController")
    local CodexIndexController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/CodexIndexController")
    local SquadHeistController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/SquadHeistController")
    local LeaderboardController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/LeaderboardController")
    local QuestCodeController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/QuestCodeController")
    local TradeController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/TradeController")
    local WorldEventFXController = requireModule("StarterPlayer/StarterPlayerScripts/Client/Controllers/WorldEventFXController")

    NotificationController.SetLanguageGetter(HUDController.GetLanguage)
    NotificationController.Init(rootGui)
    HUDController.Init(rootGui)
    ActionController.Init(rootGui)
    BaseManagerController.Init(rootGui)
    FlexVisitController.Init(rootGui)
    ShopCosmeticController.Init(rootGui)
    CodexIndexController.Init(rootGui)
    SquadHeistController.Init(rootGui)
    LeaderboardController.Init(rootGui)
    QuestCodeController.Init(rootGui)
    TradeController.Init(rootGui)
    WorldEventFXController.Init()
    HUDController.ApplyState({
        Profile = DataService.GetProfile(localPlr),
        NetWorth = DataService.ComputeNetWorth(DataService.GetProfile(localPlr)),
        IncomePerSec = DataService.ComputePassiveIncomePerSec(DataService.GetProfile(localPlr)),
        BaseSlot = 1,
        ShieldRemaining = 60,
    })
    BaseManagerController.Refresh()
    ShopCosmeticController.Refresh()
    CodexIndexController.Refresh()
    SquadHeistController.Refresh()
    QuestCodeController.Refresh()
    TradeController.Refresh()
    assertTrue(rootGui:FindFirstChild("StatsBar") ~= nil, "Client StatsBar mounted cleanly")
    assertTrue(rootGui:FindFirstChild("ShopCosmeticModal") ~= nil, "Client ShopCosmeticModal mounted cleanly")
    assertTrue(rootGui:FindFirstChild("CodexIndexModal") ~= nil, "Client CodexIndexModal mounted cleanly")
    assertTrue(rootGui:FindFirstChild("QuestCodeModal") ~= nil, "Client QuestCodeModal mounted cleanly")
    assertTrue(rootGui:FindFirstChild("TradeModal") ~= nil, "Client TradeModal mounted cleanly")

    ----------------------------------------------------------------------
    -- TEST 17: v2 Item Mutations, Multipliers & 3D Visuals
    ----------------------------------------------------------------------
    print("\n--- Test 17: v2 Item Mutations & Visuals ---")
    local MutationConfig = requireModule("ReplicatedStorage/Shared/MutationConfig")
    local QuestAndCodeConfig = requireModule("ReplicatedStorage/Shared/QuestAndCodeConfig")
    local ItemVisualBuilder = requireModule("ServerScriptService/Server/Services/ItemVisualBuilder")
    local QuestCodeService = requireModule("ServerScriptService/Server/Services/QuestCodeService")
    local TradeService = requireModule("ServerScriptService/Server/Services/TradeService")
    QuestCodeService.Start()
    TradeService.Start()

    local celDef = MutationConfig.Get("Celestial")
    assertEq(celDef.ValueMultiplier, 7.5, "Celestial mutation gives 7.5x multiplier")
    local celInst = {
        Uid = "mut_test",
        ItemId = "frozen_sun",
        ObtainedAt = 1,
        ObtainedFrom = "FrozenGlacier",
        Mutation = "Celestial",
        HatchedCreature = nil,
        PedestalSlot = 1,
    }
    assertEq(ItemCatalog.GetInstanceMultiplier(celInst), 7.5, "Instance multiplier applies Celestial 7.5x")
    local mutModel = ItemVisualBuilder.BuildItemModel(ItemCatalog.Get("frozen_sun"), Mock.Globals.CFrame.new(0, 10, 0), { Mutation = "Celestial" })
    assertTrue(mutModel:FindFirstChild("MutationRing") ~= nil, "Celestial model generates MutationRing")

    ----------------------------------------------------------------------
    -- TEST 18: Promo Codes, Daily Quests & Black-Market Merchant Buffs
    ----------------------------------------------------------------------
    print("\n--- Test 18: Promo Codes, Quests & Black-Market Merchant ---")
    local p1 = players[1]
    local p2 = players[2]
    local cashBeforeCode = DataService.GetProfile(p1).Cash
    local codeOk, _ = QuestCodeService.RedeemCode(p1, " impossible ")
    assertTrue(codeOk, "Promo code IMPOSSIBLE redeems cleanly (case/whitespace normalized)")
    assertEq(DataService.GetProfile(p1).Cash, cashBeforeCode + 1500, "Promo code adds +$1500")
    local codeDupOk, _ = QuestCodeService.RedeemCode(p1, "IMPOSSIBLE")
    assertTrue(not codeDupOk, "Duplicate promo code redemption blocked")

    local luckCodeOk, _ = QuestCodeService.RedeemCode(p1, "FROZENSUN")
    assertTrue(luckCodeOk, "FROZENSUN code redeems with luck buff")
    assertTrue(DataService.GetPlayerLuckMultiplier(p1) >= 2.0, "Luck Elixir doubles player luck multiplier")

    -- Complete a Daily Quest (Like 2 bases -> set progress directly + LikeBase)
    local qProf = DataService.GetProfile(p1)
    qProf.QuestProgress.Likes = 2
    local cashBeforeClaim = qProf.Cash
    local claimOk, _ = QuestCodeService.ClaimQuest(p1, "quest_like_2")
    assertTrue(claimOk, "Daily Quest quest_like_2 claims cleanly")
    assertEq(qProf.Cash, cashBeforeClaim + 2000, "Claiming quest rewards $2000")
    local doubleClaimOk, _ = QuestCodeService.ClaimQuest(p1, "quest_like_2")
    assertTrue(not doubleClaimOk, "Daily Quest double-claim blocked")

    -- Buy Shadow Cloak & Featherweight Charm from Merchant
    DataService.AddCash(p1, 20000)
    local cloakBuyOk, _ = QuestCodeService.BuyMerchantItem(p1, "merch_shadow_cloak")
    local featherBuyOk, _ = QuestCodeService.BuyMerchantItem(p1, "merch_feather_charm")
    assertTrue(cloakBuyOk and featherBuyOk, "Merchant Shadow Cloak & Featherweight Charm purchased cleanly")
    CarryStealService.GiveCarryItem(p1, ItemCatalog.Get("time_eater"), "ChronoRuins", "VoidTouched")
    local recCloaked = CarryStealService.GetCarryRecord(p1)
    assertTrue(recCloaked ~= nil and recCloaked.BeaconBeamPart == nil, "Shadow Cloak hides CarrySkyBeacon!")
    assertEq(p1.Character:FindFirstChildOfClass("Humanoid").WalkSpeed, GameConfig.DEFAULT_WALKSPEED, "Featherweight Charm eliminates carry walkspeed penalty!")
    CarryStealService.DepositCarriedItem(p1)

    ----------------------------------------------------------------------
    -- TEST 19: Rebirth / Ascension Prestige System
    ----------------------------------------------------------------------
    print("\n--- Test 19: Rebirth / Ascension System ---")
    local rebCost0 = QuestAndCodeConfig.GetRebirthCost(0)
    assertEq(rebCost0, 250000, "First Rebirth costs $250,000")
    -- Add a 0.01% Secret to p1's vault before rebirth to prove Secrets are preserved!
    BaseService.AddExtractedItemToBase(p1, ItemCatalog.Get("secret_zero_singularity"), "WorldEvent", "Celestial")
    DataService.AddCash(p1, 300000)
    local rebOk, _ = QuestCodeService.AscendRebirth(p1)
    assertTrue(rebOk, "Rebirth ascension succeeds when affordable")
    local p1AfterReb = DataService.GetProfile(p1)
    assertEq(p1AfterReb.Rebirths, 1, "Rebirths count incremented to 1")
    assertEq(p1AfterReb.BaseTier, 1, "BaseTier reset to Tier 1 on Rebirth")
    local secretPreserved = false
    for _, inst in ipairs(p1AfterReb.VaultItems) do
        if inst.ItemId == "secret_zero_singularity" and inst.Mutation == "Celestial" then
            secretPreserved = true
        end
    end
    assertTrue(secretPreserved, "0.01% Secret & its Celestial mutation are preserved across Rebirth!")

    ----------------------------------------------------------------------
    -- TEST 20: Base Security Shield, High-Stakes 2x Mode & Raid Safe
    ----------------------------------------------------------------------
    print("\n--- Test 20: Base Shield, High-Stakes 2x & Raid Safe ---")
    local stdIncome = DataService.ComputePassiveIncomePerSec(p1AfterReb)
    local hsOk, hsOn = BaseService.ToggleHighStakes(p1)
    assertTrue(hsOk and hsOn, "High-Stakes 2x mode toggles ON")
    assertEq(DataService.ComputePassiveIncomePerSec(p1AfterReb), math.floor(stdIncome * 2), "High-Stakes mode doubles passive income/sec")

    local slot1 = BaseService.GetPlayerSlot(p1)
    p1AfterReb.UncollectedSafeCash = 2000
    -- While shield is active, p2 cannot raid p1's safe!
    BaseService.ActivateBaseShield(p1)
    local raidBlockedOk, _ = BaseService.RaidBaseSafe(p2, slot1)
    assertTrue(not raidBlockedOk, "RaidBaseSafe blocked while victim's Base Laser Shield is active")
    -- Drop shield and move p2 right to p1's Raid Safe
    BaseService._shieldUntil[slot1] = 0
    local safeWorldPos = (BaseConfig.GetSlotCFrame(slot1) * Mock.Globals.CFrame.new(-19, 4, -17)).Position
    p2.Character.HumanoidRootPart.Position = safeWorldPos
    local raidOk, _, stolenCash = BaseService.RaidBaseSafe(p2, slot1)
    assertTrue(raidOk, "RaidBaseSafe succeeds when victim shield is down")
    assertEq(stolenCash, 700, "Raider steals 35% ($700) of $2000 Safe Cash")
    assertEq(p1AfterReb.UncollectedSafeCash, 1300, "Victim retains remaining Safe Cash")

    ----------------------------------------------------------------------
    -- TEST 21: Atomic Player-to-Player Safe Trading (Anti-Scam)
    ----------------------------------------------------------------------
    print("\n--- Test 21: Atomic P2P Trading ---")
    local trSentOk, _ = TradeService.SendTradeRequest(p1, p2.UserId)
    assertTrue(trSentOk, "Trade invite sent from p1 to p2")
    local trAccOk, activeTrade = TradeService.RespondTradeRequest(p2, p1.UserId, true)
    assertTrue(trAccOk and activeTrade ~= nil, "Trade session created when accepted")

    -- Add an item to p1's vault for trading
    BaseService.AddExtractedItemToBase(p1, ItemCatalog.Get("frozen_sun"), "FrozenGlacier", "Shiny")
    local tradeItemUid = p1AfterReb.VaultItems[#p1AfterReb.VaultItems].Uid
    DataService.AddCash(p1, 1000)
    local p2StartCash = DataService.GetProfile(p2).Cash
    local upgOfferOk, _ = TradeService.UpdateOffer(p1, { tradeItemUid }, 500)
    assertTrue(upgOfferOk, "Trade offer updated with validated Vault item UID + $500 Cash")

    -- Anti-scam: confirm p2, then modify p1's offer -> p2's Confirmed MUST reset to false!
    TradeService.ConfirmTrade(p2)
    assertTrue(activeTrade.SideB.Confirmed == true, "Partner confirmed trade")
    TradeService.UpdateOffer(p1, { tradeItemUid }, 600)
    assertTrue(activeTrade.SideB.Confirmed == false, "Anti-scam: partner Confirm resets to false when offer changes!")

    TradeService.ConfirmTrade(p1)
    local execOk, execMsg = TradeService.ConfirmTrade(p2)
    assertTrue(execOk, "Atomic trade executes once both confirm: " .. tostring(execMsg))
    assertEq(DataService.GetProfile(p2).Cash, p2StartCash + 600, "Atomic trade transfers Cash cleanly")
    local p2ReceivedItem = false
    for _, inst in ipairs(DataService.GetProfile(p2).VaultItems) do
        if inst.Uid == tradeItemUid then
            p2ReceivedItem = true
        end
    end
    assertTrue(p2ReceivedItem, "Atomic trade transfers Vault item cleanly to recipient")

    ----------------------------------------------------------------------
    -- TEST 22: v2 3D Landmarks, Plaza Kiosks & JumpPads Verified in Workspace
    ----------------------------------------------------------------------
    print("\n--- Test 22: v2 3D World Architecture Landmarks ---")
    local plaza = Mock.Globals.workspace.GameWorld:FindFirstChild("CentralPlaza")
    assertTrue(plaza ~= nil and plaza:FindFirstChild("MerchantKiosk") ~= nil, "MerchantKiosk present in CentralPlaza")
    assertEq(plaza:FindFirstChild("MerchantKiosk"):GetAttribute("KioskPanel"), "Quests", "MerchantKiosk opens Quests modal")
    assertTrue(plaza:FindFirstChild("MerchantKiosk"):FindFirstChildOfClass("ProximityPrompt") ~= nil, "MerchantKiosk has interactive ProximityPrompt")
    assertTrue(plaza ~= nil and plaza:FindFirstChild("CodeTerminal") ~= nil, "CodeTerminal present in CentralPlaza")
    assertTrue(plaza ~= nil and plaza:FindFirstChild("RebirthShrine") ~= nil, "RebirthShrine present in CentralPlaza")
    local jumpPads = Mock.Globals.game:GetService("CollectionService"):GetTagged("JumpPad")
    assertTrue(#jumpPads >= 5, "JumpPads tagged across biomes (" .. tostring(#jumpPads) .. ")")
    local raidSafes = Mock.Globals.game:GetService("CollectionService"):GetTagged("BaseRaidSafe")
    assertEq(#raidSafes, 8, "All 8 player bases contain a RaidSafe")
    assertTrue(raidSafes[1]:FindFirstChildOfClass("ProximityPrompt") ~= nil, "BaseRaidSafe has interactive ProximityPrompt")

    print(string.format("\nTEST SUMMARY: %d passed, %d failed", passed, failed))
    return failed == 0
end
