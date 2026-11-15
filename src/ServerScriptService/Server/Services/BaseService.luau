--!strict
-- 8 Personal Player Bases, Tier 1-5 Growth, Showcase Pedestals, Passive Income & FLEX YOUR BASE

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local GameConfig = require(Shared.GameConfig)
local BaseConfig = require(Shared.BaseConfig)
local ItemCatalog = require(Shared.ItemCatalog)
local MutationConfig = require(Shared.MutationConfig)
local CosmeticCatalog = require(Shared.CosmeticCatalog)
local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local DataService = require(script.Parent.DataService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local ItemVisualBuilder = require(script.Parent.ItemVisualBuilder)
local SecretService = require(script.Parent.SecretService)

local BaseService = {}

-- SlotIndex (1..8) -> UserId (or nil if unclaimed)
BaseService._slotOwners = {} :: { [number]: number? }
BaseService._playerSlots = {} :: { [number]: number }
BaseService._shieldUntil = {} :: { [number]: number }
BaseService._shieldCooldownUntil = {} :: { [number]: number }
BaseService._rateLimiter = Utils.CreateRateLimiter()
BaseService._carryCheckFn = nil :: ((player: Player) -> boolean)?

function BaseService.SetCarryCheck(fn: (player: Player) -> boolean)
    BaseService._carryCheckFn = fn
end

function BaseService.GetPlayerSlot(player: Player): number?
    return BaseService._playerSlots[player.UserId]
end

function BaseService.GetSlotOwnerUserId(slotIndex: number): number?
    return BaseService._slotOwners[slotIndex]
end

function BaseService.GetBaseCFrame(slotIndex: number): CFrame
    return BaseConfig.GetSlotCFrame(slotIndex)
end

function BaseService.IsBaseShieldActive(slotIndex: number): boolean
    return (BaseService._shieldUntil[slotIndex] or 0) > os.time()
end

function BaseService.ActivateBaseShield(player: Player): (boolean, string)
    local slot = BaseService._playerSlots[player.UserId]
    local profile = DataService.GetProfile(player)
    if not slot or not profile then
        return false, "No base"
    end
    local now = os.time()
    local cdUntil = BaseService._shieldCooldownUntil[player.UserId]
    if cdUntil ~= nil and now < cdUntil then
        return false, "Shield recharging"
    end
    local tierDef = BaseConfig.GetTier(profile.BaseTier)
    BaseService._shieldUntil[slot] = now + tierDef.ShieldDuration
    BaseService._shieldCooldownUntil[player.UserId] = now + tierDef.ShieldDuration + 15
    BaseService.RefreshBaseVisuals(slot)
    BaseService.SyncProfileToClient(player)
    return true, "Shield Active!"
end

function BaseService.ClaimBaseForPlayer(player: Player): number?
    local existing = BaseService._playerSlots[player.UserId]
    if existing then
        return existing
    end
    for slot = 1, GameConfig.MAX_PLAYERS do
        if BaseService._slotOwners[slot] == nil then
            BaseService._slotOwners[slot] = player.UserId
            BaseService._playerSlots[player.UserId] = slot
            local profile = DataService.GetProfile(player)
            local tierDef = BaseConfig.GetTier(if profile then profile.BaseTier else 1)
            BaseService._shieldUntil[slot] = os.time() + tierDef.ShieldDuration
            player:SetAttribute("BaseSlot", slot)
            BaseService.RefreshBaseVisuals(slot)
            return slot
        end
    end
    return nil
end

function BaseService.ReleaseBaseForPlayer(player: Player)
    local slot = BaseService._playerSlots[player.UserId]
    if not slot then
        return
    end
    BaseService._slotOwners[slot] = nil
    BaseService._playerSlots[player.UserId] = nil
    BaseService._rateLimiter:ClearPlayer(player.UserId)
    BaseService.RefreshBaseVisuals(slot)
end

local function updateSignText(folder: Folder, text: string, color: Color3)
    local sign = folder:FindFirstChild("OwnerSign")
    if not sign then
        return
    end
    local gui = sign:FindFirstChild("WorldSign")
    if not gui then
        return
    end
    local frame = gui:FindFirstChildOfClass("Frame")
    if not frame then
        return
    end
    local stroke = frame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = color
    end
    local label = frame:FindFirstChildOfClass("TextLabel")
    if label then
        label.Text = text
    end
end

function BaseService.RefreshBaseVisuals(slotIndex: number)
    local folder = WorldBuilder.BaseFolders[slotIndex]
    if not folder then
        return
    end

    local ownerUserId = BaseService._slotOwners[slotIndex]
    local ownerPlayer = if ownerUserId then Players:GetPlayerByUserId(ownerUserId) else nil
    local profile = if ownerUserId then DataService.GetProfileByUserId(ownerUserId) else nil

    -- Default visuals
    local primaryColor = Color3.fromRGB(24, 28, 42)
    local accentColor = Color3.fromRGB(95, 185, 255)
    local floorMaterial = Enum.Material.SmoothPlastic
    local maxPedestals = 4
    local signTitle = "BASE #" .. tostring(slotIndex) .. "\nUNCLAIMED"

    if ownerPlayer and profile then
        local tierDef = BaseConfig.GetTier(profile.BaseTier)
        maxPedestals = tierDef.MaxPedestals
        local worth = DataService.ComputeNetWorth(profile)
        local vipPrefix = if profile.EquippedCosmetics.VipTagEnabled then "[VIP] " else ""
        signTitle = string.format("%s%s's BASE (T%d)\n%s  |  ❤️ %d", vipPrefix, ownerPlayer.Name, profile.BaseTier, Utils.FormatCash(worth), profile.TotalBaseLikes)

        local designId = profile.EquippedCosmetics.BaseDesign
        if designId then
            local asset = CosmeticCatalog.GetAsset(designId)
            if asset then
                primaryColor = asset.PrimaryColor
                accentColor = asset.SecondaryColor
                floorMaterial = asset.Material or Enum.Material.SmoothPlastic
            end
        end
    end

    local floorPart = folder:FindFirstChild("BaseFloor") :: BasePart?
    if floorPart then
        floorPart.Color = primaryColor
        floorPart.Material = floorMaterial
    end

    local gatePart = folder:FindFirstChild("SecurityGate") :: BasePart?
    if gatePart then
        local shielded = BaseService.IsBaseShieldActive(slotIndex)
        gatePart.Color = if shielded then accentColor else Color3.fromRGB(255, 75, 85)
        gatePart.Transparency = if shielded then 0.55 else 0.88
    end

    local safePart = folder:FindFirstChild("RaidSafe") :: BasePart?
    if safePart then
        local safeGui = safePart:FindFirstChild("WorldSign")
        local safeFrame = if safeGui then safeGui:FindFirstChildOfClass("Frame") else nil
        local safeLbl = if safeFrame then safeFrame:FindFirstChildOfClass("TextLabel") else nil
        if safeLbl then
            local safeCash = if profile then math.floor(profile.UncollectedSafeCash or 0) else 0
            local shieldTxt = if BaseService.IsBaseShieldActive(slotIndex) then "🛡️ SHIELDED" else "🔓 VULNERABLE"
            safeLbl.Text = string.format("VAULT SAFE: %s\n%s", Utils.FormatCash(safeCash), shieldTxt)
        end
    end

    updateSignText(folder, signTitle, accentColor)

    -- Refresh pedestals & render flexed 3D models
    local pedestalsFolder = folder:FindFirstChild("Pedestals")
    if not pedestalsFolder then
        return
    end

    local slotToItem: { [number]: Types.OwnedItemInstance } = {}
    if profile then
        for _, inst in ipairs(profile.VaultItems) do
            if inst.PedestalSlot ~= nil then
                slotToItem[inst.PedestalSlot] = inst
            end
        end
    end

    for _, child in ipairs(pedestalsFolder:GetChildren()) do
        if child:IsA("BasePart") then
            local pIdx = child:GetAttribute("PedestalIndex") :: number?
            if pIdx then
                local unlocked = (ownerPlayer ~= nil) and (pIdx <= maxPedestals)
                child.Transparency = if unlocked then 0 else 1
                child.CanCollide = unlocked
                child.Color = if unlocked then primaryColor else Color3.fromRGB(38, 44, 66)

                -- Clear previous showcase model
                local oldDisplay = child:FindFirstChild("FlexDisplay")
                if oldDisplay then
                    oldDisplay:Destroy()
                end

                local itemInst = slotToItem[pIdx]
                if unlocked and itemInst then
                    local itemDef = ItemCatalog.Get(itemInst.ItemId)
                    if itemDef then
                        local customLabel: string? = nil
                        if itemInst.HatchedCreature then
                            for _, c in ipairs(ItemCatalog.GalaxyCreatures) do
                                if c.Id == itemInst.HatchedCreature then
                                    customLabel = c.Icon .. " " .. c.Name .. " (" .. itemDef.Name .. ")"
                                    break
                                end
                            end
                        end
                        local model = ItemVisualBuilder.BuildItemModel(
                            itemDef,
                            child.CFrame * CFrame.new(0, 3.2, 0),
                            { Scale = 1.05, ShowBillboard = true, CustomLabel = customLabel, Mutation = itemInst.Mutation }
                        )
                        model.Name = "FlexDisplay"
                        model.Parent = child
                    end
                end
            end
        end
    end
end

function BaseService.AutoPlaceItemIfFreePedestal(player: Player, inst: Types.OwnedItemInstance)
    local profile = DataService.GetProfile(player)
    if not profile then
        return
    end
    local tierDef = BaseConfig.GetTier(profile.BaseTier)
    local used: { [number]: boolean } = {}
    for _, existing in ipairs(profile.VaultItems) do
        if existing.PedestalSlot then
            used[existing.PedestalSlot] = true
        end
    end
    for idx = 1, tierDef.MaxPedestals do
        if not used[idx] then
            inst.PedestalSlot = idx
            return
        end
    end
end

function BaseService.AddExtractedItemToBase(
    player: Player,
    itemDef: Types.ItemDefinition,
    obtainedFrom: string,
    mutation: Types.MutationId?
): (boolean, Types.OwnedItemInstance?)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, nil
    end

    local mut: Types.MutationId = mutation or "Normal"
    local mutMult = MutationConfig.Get(mut).ValueMultiplier
    local techLvl = profile.TechLevels.vault_multiplier or 0
    local rebirthMult = DataService.GetRebirthIncomeMultiplier(profile)

    if #profile.VaultItems >= GameConfig.MAX_VAULT_INVENTORY then
        local bonus = math.floor(itemDef.BaseCashValue * mutMult * (1 + techLvl * 0.10) * rebirthMult)
        DataService.AddCash(player, bonus)
        return true, nil
    end

    local inst: Types.OwnedItemInstance = {
        Uid = Utils.GenerateUid("relic"),
        ItemId = itemDef.Id,
        Mutation = mut,
        ObtainedAt = os.time(),
        ObtainedFrom = obtainedFrom,
        PedestalSlot = nil,
        HatchedCreature = nil,
    }
    table.insert(profile.VaultItems, inst)
    profile.TotalExtracted += 1
    DataService.EnsureDailyQuestReset(profile)
    profile.QuestProgress.Extracted += 1
    profile.DiscoveredItems[itemDef.Id] = (profile.DiscoveredItems[itemDef.Id] or 0) + 1

    BaseService.AutoPlaceItemIfFreePedestal(player, inst)

    -- Extraction cash reward boosted by Mutation, Vault Compounder tech & Rebirths
    local extractionBonus = math.floor(itemDef.BaseCashValue * 0.25 * mutMult * (1 + techLvl * 0.10) * rebirthMult)
    DataService.AddCash(player, extractionBonus)
    DataService.MarkDirty(player)

    local slot = BaseService._playerSlots[player.UserId]
    if slot then
        local tierDef = BaseConfig.GetTier(profile.BaseTier)
        BaseService._shieldUntil[slot] = os.time() + tierDef.ShieldDuration
        BaseService.RefreshBaseVisuals(slot)
    end

    if itemDef.IsSecret or itemDef.Rarity == "Secret" then
        SecretService.PublishSecretDiscovery(player, itemDef)
    end

    return true, inst
end

function BaseService.UpgradeBase(player: Player): (boolean, string)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile unavailable"
    end
    local nextTier = profile.BaseTier + 1
    if nextTier > #BaseConfig.UpgradeTiers then
        return false, "Already at Max Tier!"
    end
    local nextDef = BaseConfig.GetTier(nextTier)
    if profile.Cash < nextDef.Cost then
        return false, "Not enough Cash"
    end

    profile.Cash -= nextDef.Cost
    profile.BaseTier = nextTier
    DataService.MarkDirty(player)

    local slot = BaseService._playerSlots[player.UserId]
    if slot then
        BaseService.RefreshBaseVisuals(slot)
    end

    Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
        Type = "BaseUpgrade",
        PlayerName = player.Name,
        Tier = nextTier,
        TierName = nextDef.Name,
    })

    return true, nextDef.Name
end

function BaseService.AssignPedestal(player: Player, itemUid: string, pedestalSlot: number): (boolean, string)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile unavailable"
    end
    local tierDef = BaseConfig.GetTier(profile.BaseTier)
    local cleanSlot = math.floor(pedestalSlot)
    if cleanSlot < 1 or cleanSlot > tierDef.MaxPedestals then
        return false, "Pedestal slot locked or invalid"
    end

    local targetItem: Types.OwnedItemInstance? = nil
    for _, inst in ipairs(profile.VaultItems) do
        if inst.Uid == itemUid then
            targetItem = inst
        elseif inst.PedestalSlot == cleanSlot then
            inst.PedestalSlot = nil
        end
    end

    if not targetItem then
        return false, "Item not found"
    end

    targetItem.PedestalSlot = cleanSlot
    DataService.MarkDirty(player)
    local slot = BaseService._playerSlots[player.UserId]
    if slot then
        BaseService.RefreshBaseVisuals(slot)
    end
    return true, "Equipped"
end

function BaseService.ClearPedestal(player: Player, pedestalSlot: number): boolean
    local profile = DataService.GetProfile(player)
    if not profile then
        return false
    end
    for _, inst in ipairs(profile.VaultItems) do
        if inst.PedestalSlot == pedestalSlot then
            inst.PedestalSlot = nil
        end
    end
    DataService.MarkDirty(player)
    local slot = BaseService._playerSlots[player.UserId]
    if slot then
        BaseService.RefreshBaseVisuals(slot)
    end
    return true
end

function BaseService.GetServerBasesSnapshot(): { any }
    local list = {}
    for slot = 1, GameConfig.MAX_PLAYERS do
        local ownerId = BaseService._slotOwners[slot]
        if ownerId then
            local p = Players:GetPlayerByUserId(ownerId)
            local profile = DataService.GetProfileByUserId(ownerId)
            if p and profile then
                local rarestLabel = "None"
                local bestWorth = -1
                local flexedItems = {}
                for _, inst in ipairs(profile.VaultItems) do
                    local def = ItemCatalog.Get(inst.ItemId)
                    if def then
                        if inst.PedestalSlot ~= nil then
                            table.insert(flexedItems, {
                                Name = def.Name,
                                NameTR = def.NameTR,
                                Rarity = def.Rarity,
                                Icon = def.Icon,
                                Slot = inst.PedestalSlot,
                                HatchedCreature = inst.HatchedCreature,
                            })
                        end
                        if def.BaseCashValue > bestWorth then
                            bestWorth = def.BaseCashValue
                            rarestLabel = def.Icon .. " " .. def.Name
                        end
                    end
                end
                table.insert(list, {
                    Slot = slot,
                    UserId = ownerId,
                    PlayerName = p.Name,
                    DisplayName = p.DisplayName,
                    BaseTier = profile.BaseTier,
                    NetWorth = DataService.ComputeNetWorth(profile),
                    Likes = profile.TotalBaseLikes,
                    RarestItem = rarestLabel,
                    Vip = profile.EquippedCosmetics.VipTagEnabled,
                    HighStakesMode = profile.HighStakesMode,
                    UncollectedSafeCash = math.floor(profile.UncollectedSafeCash or 0),
                    ShieldActive = BaseService.IsBaseShieldActive(slot),
                    FlexedItems = flexedItems,
                })
            end
        end
    end
    table.sort(list, function(a, b)
        return a.NetWorth > b.NetWorth
    end)
    return list
end

function BaseService.TeleportToBase(visitor: Player, targetSlot: number): (boolean, string)
    if BaseService._carryCheckFn and BaseService._carryCheckFn(visitor) then
        return false, "Drop or extract your carried item before teleporting!"
    end
    local ownerId = BaseService._slotOwners[targetSlot]
    if not ownerId then
        return false, "Base slot is unclaimed"
    end
    local char = visitor.Character
    local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    if not hrp then
        return false, "Character unavailable"
    end
    local baseCF = BaseConfig.GetSlotCFrame(targetSlot)
    -- Place visitor right in front of the showcase entrance
    hrp.CFrame = baseCF * CFrame.new(0, 4.5, -20)
    return true, "Teleported"
end

function BaseService.LikeBase(visitor: Player, targetUserId: number): (boolean, string)
    if visitor.UserId == targetUserId then
        return false, "Cannot like your own base"
    end
    local visitorProfile = DataService.GetProfile(visitor)
    local targetProfile = DataService.GetProfileByUserId(targetUserId)
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not visitorProfile or not targetProfile or not targetPlayer then
        return false, "Base owner offline"
    end

    local key = tostring(targetUserId)
    if visitorProfile.LikedPlayerTargets[key] then
        return false, "Already liked this player's base!"
    end

    visitorProfile.LikedPlayerTargets[key] = true
    DataService.EnsureDailyQuestReset(visitorProfile)
    visitorProfile.QuestProgress.Likes += 1
    targetProfile.TotalBaseLikes += 1
    DataService.AddCash(targetPlayer, GameConfig.BASE_LIKE_REWARD_CASH)
    DataService.MarkDirty(visitor)
    DataService.MarkDirty(targetPlayer)

    local targetSlot = BaseService._playerSlots[targetUserId]
    if targetSlot then
        BaseService.RefreshBaseVisuals(targetSlot)
    end

    Remotes.GetEvent("FeedAnnouncement"):FireClient(targetPlayer, {
        Type = "BaseLiked",
        VisitorName = visitor.Name,
        Reward = GameConfig.BASE_LIKE_REWARD_CASH,
    })

    return true, "Liked!"
end

function BaseService.ToggleHighStakes(player: Player): (boolean, boolean)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, false
    end
    -- Collect any pending safe cash automatically when turning off High Stakes
    if profile.HighStakesMode and (profile.UncollectedSafeCash or 0) > 0 then
        DataService.AddCash(player, profile.UncollectedSafeCash)
        profile.UncollectedSafeCash = 0
    end
    profile.HighStakesMode = not profile.HighStakesMode
    DataService.MarkDirty(player)
    local slot = BaseService._playerSlots[player.UserId]
    if slot then
        BaseService.RefreshBaseVisuals(slot)
    end
    BaseService.SyncProfileToClient(player)
    return true, profile.HighStakesMode
end

function BaseService.CollectBaseSafe(player: Player): (boolean, number)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, 0
    end
    local amount = math.floor(profile.UncollectedSafeCash or 0)
    if amount <= 0 then
        return false, 0
    end
    profile.UncollectedSafeCash = 0
    DataService.AddCash(player, amount)
    DataService.MarkDirty(player)
    local slot = BaseService._playerSlots[player.UserId]
    if slot then
        BaseService.RefreshBaseVisuals(slot)
    end
    BaseService.SyncProfileToClient(player)
    return true, amount
end

function BaseService.RaidBaseSafe(raider: Player, targetSlot: number): (boolean, string, number)
    local ownerId = BaseService._slotOwners[targetSlot]
    if not ownerId then
        return false, "Unclaimed base", 0
    end
    if ownerId == raider.UserId then
        return false, "Cannot raid your own base", 0
    end
    if BaseService.IsBaseShieldActive(targetSlot) then
        return false, "Base Laser Shield is active!", 0
    end
    local targetPlayer = Players:GetPlayerByUserId(ownerId)
    local targetProfile = DataService.GetProfileByUserId(ownerId)
    if not targetPlayer or not targetProfile then
        return false, "Target offline", 0
    end

    -- Verify raider distance to the Raid Safe
    local rChar = raider.Character
    local rRoot = if rChar then rChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    local baseCF = BaseConfig.GetSlotCFrame(targetSlot)
    local safeWorldPos = (baseCF * CFrame.new(-19, 4, -17)).Position
    if rRoot and (rRoot.Position - safeWorldPos).Magnitude > 16 then
        return false, "Get closer to the Vault Safe!", 0
    end

    local safeCash = math.floor(targetProfile.UncollectedSafeCash or 0)
    if safeCash < 50 then
        return false, "Vault Safe is empty!", 0
    end

    local stolenAmount = math.max(25, math.floor(safeCash * 0.35))
    targetProfile.UncollectedSafeCash = math.max(0, safeCash - stolenAmount)
    DataService.AddCash(raider, stolenAmount)
    DataService.MarkDirty(targetPlayer)
    BaseService.RefreshBaseVisuals(targetSlot)
    BaseService.SyncProfileToClient(raider)
    BaseService.SyncProfileToClient(targetPlayer)

    Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
        Type = "BaseRaided",
        RaiderName = raider.Name,
        VictimName = targetPlayer.Name,
        Amount = stolenAmount,
    })

    return true, "Raided!", stolenAmount
end

function BaseService.SyncProfileToClient(player: Player)
    local profile = DataService.GetProfile(player)
    if not profile then
        return
    end
    local slot = BaseService._playerSlots[player.UserId]
    Remotes.GetEvent("StateSync"):FireClient(player, {
        Profile = profile,
        NetWorth = DataService.ComputeNetWorth(profile),
        IncomePerSec = DataService.ComputePassiveIncomePerSec(profile),
        BaseSlot = slot,
        ShieldRemaining = if slot then math.max(0, (BaseService._shieldUntil[slot] or 0) - os.time()) else 0,
    })
end

function BaseService.Start()
    -- Wire Client Remote handlers with strict validation
    Remotes.GetEvent("RequestUpgradeBase").OnServerEvent:Connect(function(player)
        if not BaseService._rateLimiter:Check(player.UserId, "UpgradeBase", 0.5) then
            return
        end
        local ok = BaseService.UpgradeBase(player)
        if ok then
            BaseService.SyncProfileToClient(player)
        end
    end)

    Remotes.GetEvent("RequestAssignPedestal").OnServerEvent:Connect(function(player, itemUid, slotNum)
        if type(itemUid) ~= "string" or type(slotNum) ~= "number" then
            return
        end
        if not BaseService._rateLimiter:Check(player.UserId, "AssignPedestal", 0.25) then
            return
        end
        local ok = BaseService.AssignPedestal(player, itemUid, slotNum)
        if ok then
            BaseService.SyncProfileToClient(player)
        end
    end)

    Remotes.GetEvent("RequestClearPedestal").OnServerEvent:Connect(function(player, slotNum)
        if type(slotNum) ~= "number" then
            return
        end
        if BaseService.ClearPedestal(player, slotNum) then
            BaseService.SyncProfileToClient(player)
        end
    end)

    Remotes.GetEvent("RequestHatchGalaxyEgg").OnServerEvent:Connect(function(player, itemUid)
        if type(itemUid) ~= "string" then
            return
        end
        if not BaseService._rateLimiter:Check(player.UserId, "HatchEgg", 0.6) then
            return
        end
        local ok = SecretService.HatchGalaxyEgg(player, itemUid)
        if ok then
            local slot = BaseService._playerSlots[player.UserId]
            if slot then
                BaseService.RefreshBaseVisuals(slot)
            end
            BaseService.SyncProfileToClient(player)
        end
    end)

    Remotes.GetEvent("RequestVisitBase").OnServerEvent:Connect(function(player, targetSlot)
        if type(targetSlot) ~= "number" then
            return
        end
        if not BaseService._rateLimiter:Check(player.UserId, "VisitBase", 1.0) then
            return
        end
        BaseService.TeleportToBase(player, math.floor(targetSlot))
    end)

    Remotes.GetEvent("RequestLikeBase").OnServerEvent:Connect(function(player, targetUserId)
        if type(targetUserId) ~= "number" then
            return
        end
        if not BaseService._rateLimiter:Check(player.UserId, "LikeBase", 1.0) then
            return
        end
        local ok = BaseService.LikeBase(player, math.floor(targetUserId))
        if ok then
            BaseService.SyncProfileToClient(player)
            local target = Players:GetPlayerByUserId(math.floor(targetUserId))
            if target then
                BaseService.SyncProfileToClient(target)
            end
        end
    end)

    Remotes.GetEvent("RequestReturnHome").OnServerEvent:Connect(function(player)
        if not BaseService._rateLimiter:Check(player.UserId, "ReturnHome", 1.0) then
            return
        end
        local slot = BaseService._playerSlots[player.UserId]
        if slot then
            BaseService.TeleportToBase(player, slot)
        end
    end)

    Remotes.GetEvent("RequestToggleHighStakes").OnServerEvent:Connect(function(player)
        if not BaseService._rateLimiter:Check(player.UserId, "HighStakes", 0.5) then
            return
        end
        BaseService.ToggleHighStakes(player)
    end)

    Remotes.GetEvent("RequestCollectBaseSafe").OnServerEvent:Connect(function(player)
        if not BaseService._rateLimiter:Check(player.UserId, "CollectSafe", 0.5) then
            return
        end
        BaseService.CollectBaseSafe(player)
    end)

    Remotes.GetEvent("RequestRechargeShield").OnServerEvent:Connect(function(player)
        if not BaseService._rateLimiter:Check(player.UserId, "RechargeShield", 1.0) then
            return
        end
        BaseService.ActivateBaseShield(player)
    end)

    Remotes.GetEvent("RequestRaidBaseSafe").OnServerEvent:Connect(function(player, targetSlot)
        if type(targetSlot) ~= "number" then
            return
        end
        if not BaseService._rateLimiter:Check(player.UserId, "RaidSafe", 1.0) then
            return
        end
        BaseService.RaidBaseSafe(player, math.floor(targetSlot))
    end)

    Remotes.GetFunction("GetServerBases").OnServerInvoke = function(_player)
        return BaseService.GetServerBasesSnapshot()
    end

    Remotes.GetFunction("GetInitialProfile").OnServerInvoke = function(player)
        local profile = DataService.GetProfile(player)
        if not profile then
            return nil
        end
        local slot = BaseService._playerSlots[player.UserId]
        return {
            Profile = profile,
            NetWorth = DataService.ComputeNetWorth(profile),
            IncomePerSec = DataService.ComputePassiveIncomePerSec(profile),
            BaseSlot = slot,
            ShieldRemaining = if slot then math.max(0, (BaseService._shieldUntil[slot] or 0) - os.time()) else 0,
        }
    end

    -- Passive Cash/sec loop (High-Stakes 2x goes into Raidable Safe; Standard goes directly to Cash!)
    task.spawn(function()
        while true do
            task.wait(GameConfig.PASSIVE_INCOME_INTERVAL)
            for _, player in ipairs(Players:GetPlayers()) do
                local profile = DataService.GetProfile(player)
                if profile then
                    local income = DataService.ComputePassiveIncomePerSec(profile)
                    if income > 0 then
                        if profile.HighStakesMode then
                            profile.UncollectedSafeCash = (profile.UncollectedSafeCash or 0) + income
                            DataService.MarkDirty(player)
                        else
                            DataService.AddCash(player, income)
                        end
                        BaseService.SyncProfileToClient(player)
                    end
                end
            end
        end
    end)
end

return BaseService
