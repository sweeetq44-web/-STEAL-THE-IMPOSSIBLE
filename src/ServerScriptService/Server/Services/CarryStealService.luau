--!strict
-- Addictive Core Mechanic: Carry -> Chase -> Tackle/Steal -> Base Deposit Extraction
-- Strictly server-authoritative with anti-exploit distance, rate limits & immunity windows.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local GameConfig = require(Shared.GameConfig)
local RarityConfig = require(Shared.RarityConfig)
local BaseConfig = require(Shared.BaseConfig)
local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local DataService = require(script.Parent.DataService)
local BaseService = require(script.Parent.BaseService)
local ItemSpawnService = require(script.Parent.ItemSpawnService)
local ItemVisualBuilder = require(script.Parent.ItemVisualBuilder)

export type CarryRecord = {
    ItemDef: Types.ItemDefinition,
    Mutation: Types.MutationId,
    ObtainedFrom: string,
    PickedUpAt: number,
    ImmunityUntil: number,
    CarryModel: Model?,
    BeaconBeamPart: Part?,
}

local CarryStealService = {}
CarryStealService._carriers = {} :: { [number]: CarryRecord }
CarryStealService._tackleCooldowns = {} :: { [number]: number }
CarryStealService._pickupCooldowns = {} :: { [number]: number }
CarryStealService._rateLimiter = Utils.CreateRateLimiter()

function CarryStealService.IsCarrying(player: Player): boolean
    return CarryStealService._carriers[player.UserId] ~= nil
end

function CarryStealService.GetCarryRecord(player: Player): CarryRecord?
    return CarryStealService._carriers[player.UserId]
end

function CarryStealService.ApplyCarrierWalkSpeed(player: Player)
    local char = player.Character
    local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
    if not hum then
        return
    end

    local record = CarryStealService._carriers[player.UserId]
    if not record then
        local speedBoost = player:GetAttribute("GadgetSpeedBoost") :: number?
        hum.WalkSpeed = GameConfig.DEFAULT_WALKSPEED + (speedBoost or 0)
        return
    end

    local rarityInfo = RarityConfig.Get(record.ItemDef.Rarity)
    local penalty = rarityInfo.CarrySpeedPenalty
    local profile = DataService.GetProfile(player)
    if profile then
        -- Featherweight Charm eliminates carry speed penalty completely!
        if (profile.ActiveBuffs.FeatherUntil or 0) > os.time() then
            penalty = 0
        else
            local tierDef = BaseConfig.GetTier(profile.BaseTier)
            local techLvl = profile.TechLevels.carry_boots or 0
            local reduction = math.min(0.85, tierDef.CarryPenaltyReduction + techLvl * 0.04)
            penalty = penalty * (1 - reduction)
        end
    end
    local speedBoost = player:GetAttribute("GadgetSpeedBoost") :: number?
    hum.WalkSpeed = math.max(10, GameConfig.DEFAULT_WALKSPEED * (1 - penalty)) + (speedBoost or 0)
end

local function clearCarryVisuals(record: CarryRecord)
    if record.CarryModel then
        record.CarryModel:Destroy()
        record.CarryModel = nil
    end
    if record.BeaconBeamPart then
        record.BeaconBeamPart:Destroy()
        record.BeaconBeamPart = nil
    end
end

local function attachCarryVisuals(player: Player, record: CarryRecord)
    clearCarryVisuals(record)
    local char = player.Character
    local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    if not char or not hrp then
        return
    end

    local carryCF = hrp.CFrame * CFrame.new(0, 1.8, 1.8)
    local model = ItemVisualBuilder.BuildItemModel(record.ItemDef, carryCF, { Scale = 0.85, ShowBillboard = true, Mutation = record.Mutation })
    model.Name = "CarriedRelic_" .. player.Name

    local primary = model.PrimaryPart
    if primary then
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored = false
                desc.CanCollide = false
                if desc ~= primary then
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = primary
                    weld.Part1 = desc
                    weld.Parent = desc
                end
            end
        end

        local attachWeld = Instance.new("WeldConstraint")
        attachWeld.Part0 = hrp
        attachWeld.Part1 = primary
        attachWeld.Parent = primary
    end
    model.Parent = char
    record.CarryModel = model

    -- Add tall Sky Beacon so rivals can spot and chase carriers of Rare+ items (unless Shadow Cloak active!)
    local profile = DataService.GetProfile(player)
    local cloakActive = profile ~= nil and (profile.ActiveBuffs.ShadowCloakUntil or 0) > os.time()
    local rarityInfo = RarityConfig.Get(record.ItemDef.Rarity)
    if rarityInfo.BeaconEnabled and not cloakActive then
        local beacon = Instance.new("Part")
        beacon.Name = "CarrySkyBeacon"
        beacon.Size = Vector3.new(95, 1.4, 1.4)
        beacon.Shape = Enum.PartType.Cylinder
        beacon.Color = rarityInfo.Color
        beacon.Material = Enum.Material.Neon
        beacon.Transparency = 0.62
        beacon.CanCollide = false
        beacon.CastShadow = false
        beacon.Massless = true
        beacon.CFrame = hrp.CFrame * CFrame.new(0, 48, 0) * CFrame.Angles(0, 0, math.rad(90))
        beacon.Parent = char

        local bWeld = Instance.new("WeldConstraint")
        bWeld.Part0 = hrp
        bWeld.Part1 = beacon
        bWeld.Parent = beacon

        record.BeaconBeamPart = beacon
    end
end

local function syncCarryState(player: Player)
    local record = CarryStealService._carriers[player.UserId]
    player:SetAttribute("CarryingItemId", if record then record.ItemDef.Id else "")
    player:SetAttribute("CarryingRarity", if record then record.ItemDef.Rarity else "")

    Remotes.GetEvent("CarryStateSync"):FireAllClients({
        UserId = player.UserId,
        PlayerName = player.Name,
        ItemId = if record then record.ItemDef.Id else nil,
        ItemName = if record then record.ItemDef.Name else nil,
        ItemNameTR = if record then record.ItemDef.NameTR else nil,
        Mutation = if record then record.Mutation else nil,
        Rarity = if record then record.ItemDef.Rarity else nil,
        Icon = if record then record.ItemDef.Icon else nil,
    })
end

function CarryStealService.GiveCarryItem(
    player: Player,
    itemDef: Types.ItemDefinition,
    obtainedFrom: string,
    mutation: Types.MutationId?
): boolean
    if CarryStealService._carriers[player.UserId] ~= nil then
        return false
    end

    local now = os.clock()
    local record: CarryRecord = {
        ItemDef = itemDef,
        Mutation = mutation or "Normal",
        ObtainedFrom = obtainedFrom,
        PickedUpAt = now,
        ImmunityUntil = now + GameConfig.STEAL_IMMUNITY_DURATION,
        CarryModel = nil,
        BeaconBeamPart = nil,
    }
    CarryStealService._carriers[player.UserId] = record
    attachCarryVisuals(player, record)
    CarryStealService.ApplyCarrierWalkSpeed(player)
    syncCarryState(player)

    local rarityInfo = RarityConfig.Get(itemDef.Rarity)
    if rarityInfo.Order >= 4 then
        Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
            Type = "HighRarityPickedUp",
            PlayerName = player.Name,
            ItemName = itemDef.Name,
            ItemNameTR = itemDef.NameTR,
            Rarity = itemDef.Rarity,
            Icon = itemDef.Icon,
        })
    end

    return true
end

function CarryStealService.TryPickupWorldNode(player: Player, node: ItemSpawnService.WorldSpawnNode): boolean
    if CarryStealService._carriers[player.UserId] ~= nil then
        return false
    end

    local now = os.clock()
    local lastPickup = CarryStealService._pickupCooldowns[player.UserId]
    if lastPickup ~= nil and (now - lastPickup) < GameConfig.PICKUP_COOLDOWN then
        return false
    end

    -- Server-side distance verification
    local char = player.Character
    local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    if hrp then
        if (hrp.Position - node.Position).Magnitude > 18 then
            return false
        end
    end

    CarryStealService._pickupCooldowns[player.UserId] = now
    local itemDef = node.ItemDef
    local biomeId = node.BiomeId
    local mut = node.Mutation
    ItemSpawnService.RemoveWorldNode(node.Uid)

    return CarryStealService.GiveCarryItem(player, itemDef, biomeId, mut)
end

-- Core Addictive Steal / Tackle Mechanic
function CarryStealService.AttemptSteal(thief: Player, targetPlayer: Player): (boolean, string)
    if thief == targetPlayer then
        return false, "Cannot steal from yourself"
    end
    if CarryStealService._carriers[thief.UserId] ~= nil then
        return false, "Already carrying an item"
    end

    local targetRecord = CarryStealService._carriers[targetPlayer.UserId]
    if not targetRecord then
        return false, "Target is not carrying an item"
    end

    local now = os.clock()
    if now < targetRecord.ImmunityUntil then
        return false, "Target has brief steal immunity"
    end

    -- Tackle cooldown scaled down by Magnetic Snatch Gloves tech
    local profile = DataService.GetProfile(thief)
    local techLvl = if profile then (profile.TechLevels.tackle_reach or 0) else 0
    local effectiveCd = math.max(1.5, GameConfig.TACKLE_COOLDOWN - techLvl * 0.2)
    local lastTackle = CarryStealService._tackleCooldowns[thief.UserId]
    if lastTackle ~= nil and (now - lastTackle) < effectiveCd then
        return false, "Tackle on cooldown"
    end

    -- Distance validation (Server-Authoritative!)
    local thiefChar = thief.Character
    local targetChar = targetPlayer.Character
    local thiefRoot = if thiefChar then thiefChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    local targetRoot = if targetChar then targetChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

    if thiefRoot and targetRoot then
        local dist = (thiefRoot.Position - targetRoot.Position).Magnitude
        if dist > GameConfig.STEAL_REACH_STUDS then
            return false, "Too far away"
        end
    end

    -- Cannot steal once target is already safely inside their own Base Extraction Zone
    local targetSlot = BaseService.GetPlayerSlot(targetPlayer)
    if targetSlot and targetRoot then
        local baseCF = BaseService.GetBaseCFrame(targetSlot)
        local localPos = baseCF:PointToObjectSpace(targetRoot.Position)
        if math.abs(localPos.X) <= 22 and localPos.Z >= -24 and localPos.Z <= 24 then
            return false, "Target reached their Base Shield!"
        end
    end

    -- Execute Clean Steal Transfer!
    CarryStealService._tackleCooldowns[thief.UserId] = now
    clearCarryVisuals(targetRecord)
    CarryStealService._carriers[targetPlayer.UserId] = nil
    CarryStealService.ApplyCarrierWalkSpeed(targetPlayer)
    syncCarryState(targetPlayer)

    -- Brief stumble slow on previous carrier
    local targetHum = if targetChar then targetChar:FindFirstChildOfClass("Humanoid") else nil
    if targetHum then
        targetHum.WalkSpeed = 7
        task.delay(GameConfig.STUN_DURATION_ON_STOLEN, function()
            if targetPlayer.Parent then
                CarryStealService.ApplyCarrierWalkSpeed(targetPlayer)
            end
        end)
    end

    -- Award thief steal stats & small steal bonus
    if profile then
        profile.TotalSteals += 1
        DataService.EnsureDailyQuestReset(profile)
        profile.QuestProgress.Steals += 1
        local stealBonus = math.max(25, math.floor(targetRecord.ItemDef.BaseCashValue * GameConfig.STEAL_THIEF_CASH_BONUS))
        DataService.AddCash(thief, stealBonus)
        BaseService.SyncProfileToClient(thief)
    end

    CarryStealService.GiveCarryItem(thief, targetRecord.ItemDef, targetRecord.ObtainedFrom, targetRecord.Mutation)

    Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
        Type = "ItemStolenFromPlayer",
        ThiefName = thief.Name,
        VictimName = targetPlayer.Name,
        ItemName = targetRecord.ItemDef.Name,
        ItemNameTR = targetRecord.ItemDef.NameTR,
        Rarity = targetRecord.ItemDef.Rarity,
        Icon = targetRecord.ItemDef.Icon,
    })

    return true, "STOLEN!"
end

-- Helper used by Tackle button (finds closest carrier within reach automatically)
function CarryStealService.TackleNearestCarrier(attacker: Player): (boolean, string)
    local now = os.clock()
    local profile = DataService.GetProfile(attacker)
    local techLvl = if profile then (profile.TechLevels.tackle_reach or 0) else 0
    local effectiveCd = math.max(1.5, GameConfig.TACKLE_COOLDOWN - techLvl * 0.2)
    local lastTackle = CarryStealService._tackleCooldowns[attacker.UserId]
    if lastTackle ~= nil and (now - lastTackle) < effectiveCd then
        return false, "Cooldown"
    end

    local char = attacker.Character
    local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    if not root then
        return false, "No character"
    end

    local bestTarget: Player? = nil
    local bestDist = GameConfig.STEAL_REACH_STUDS
    for carrierId, _ in pairs(CarryStealService._carriers) do
        if carrierId ~= attacker.UserId then
            local p = Players:GetPlayerByUserId(carrierId)
            local tChar = if p then p.Character else nil
            local tRoot = if tChar then tChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
            if p and tRoot then
                local d = (root.Position - tRoot.Position).Magnitude
                if d <= bestDist then
                    bestDist = d
                    bestTarget = p
                end
            end
        end
    end

    if bestTarget then
        return CarryStealService.AttemptSteal(attacker, bestTarget)
    end

    -- Missed lunge still records cooldown
    CarryStealService._tackleCooldowns[attacker.UserId] = now
    return false, "No carrier in reach"
end

function CarryStealService.DepositCarriedItem(player: Player): boolean
    local record = CarryStealService._carriers[player.UserId]
    if not record then
        return false
    end

    clearCarryVisuals(record)
    CarryStealService._carriers[player.UserId] = nil
    CarryStealService.ApplyCarrierWalkSpeed(player)
    syncCarryState(player)

    local ok = BaseService.AddExtractedItemToBase(player, record.ItemDef, record.ObtainedFrom, record.Mutation)
    if ok then
        BaseService.SyncProfileToClient(player)
        Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
            Type = "ItemExtracted",
            PlayerName = player.Name,
            ItemName = record.ItemDef.Name,
            ItemNameTR = record.ItemDef.NameTR,
            Rarity = record.ItemDef.Rarity,
            Icon = record.ItemDef.Icon,
        })
    end
    return ok
end

function CarryStealService.DropCarriedItemToWorld(player: Player)
    local record = CarryStealService._carriers[player.UserId]
    if not record then
        return
    end
    local dropPos = Vector3.new(0, 8, 0)
    local char = player.Character
    local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    if hrp then
        dropPos = hrp.Position + Vector3.new(0, 1.5, 0)
    end

    clearCarryVisuals(record)
    CarryStealService._carriers[player.UserId] = nil
    CarryStealService.ApplyCarrierWalkSpeed(player)
    syncCarryState(player)

    ItemSpawnService.SpawnSpecificItemAt(record.ItemDef, dropPos, record.ObtainedFrom, true, record.Mutation)
end

function CarryStealService.Start()
    BaseService.SetCarryCheck(CarryStealService.IsCarrying)
    ItemSpawnService.SetPickupCallback(function(player, node)
        CarryStealService.TryPickupWorldNode(player, node)
    end)

    -- Bind Base Deposit Pads
    for _, pad in ipairs(CollectionService:GetTagged("BaseDepositPad")) do
        if pad:IsA("BasePart") then
            pad.Touched:Connect(function(hit: BasePart)
                local model = hit:FindFirstAncestorOfClass("Model")
                local player = if model then Players:GetPlayerFromCharacter(model) else nil
                if not player then
                    return
                end
                local padSlot = pad:GetAttribute("BaseSlot") :: number?
                local playerSlot = BaseService.GetPlayerSlot(player)
                if padSlot and playerSlot == padSlot and CarryStealService.IsCarrying(player) then
                    CarryStealService.DepositCarriedItem(player)
                end
            end)
        end
    end

    -- Bind Tackle/Steal Request
    Remotes.GetEvent("RequestTackleSteal").OnServerEvent:Connect(function(player, targetUserId)
        if not CarryStealService._rateLimiter:Check(player.UserId, "Tackle", 0.35) then
            return
        end
        if type(targetUserId) == "number" then
            local target = Players:GetPlayerByUserId(math.floor(targetUserId))
            if target then
                CarryStealService.AttemptSteal(player, target)
                return
            end
        end
        CarryStealService.TackleNearestCarrier(player)
    end)

    -- Drop carried item on death or disconnect
    Players.PlayerAdded:Connect(function(player: Player)
        player.CharacterAdded:Connect(function(char: Model)
            local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
            if hum then
                hum.Died:Connect(function()
                    if CarryStealService.IsCarrying(player) then
                        CarryStealService.DropCarriedItemToWorld(player)
                    end
                end)
                CarryStealService.ApplyCarrierWalkSpeed(player)
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        if CarryStealService.IsCarrying(player) then
            CarryStealService.DropCarriedItemToWorld(player)
        end
        CarryStealService._tackleCooldowns[player.UserId] = nil
        CarryStealService._pickupCooldowns[player.UserId] = nil
        CarryStealService._rateLimiter:ClearPlayer(player.UserId)
    end)
end

return CarryStealService
