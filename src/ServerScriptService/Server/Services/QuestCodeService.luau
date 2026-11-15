--!strict
-- Daily Quests, Promo Code Redemption, Black-Market Merchant & Rebirth/Ascension Service

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local GameConfig = require(Shared.GameConfig)
local RarityConfig = require(Shared.RarityConfig)
local MutationConfig = require(Shared.MutationConfig)
local ItemCatalog = require(Shared.ItemCatalog)
local QuestAndCodeConfig = require(Shared.QuestAndCodeConfig)
local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local DataService = require(script.Parent.DataService)
local BaseService = require(script.Parent.BaseService)
local CarryStealService = require(script.Parent.CarryStealService)

local QuestCodeService = {}
QuestCodeService._rateLimiter = Utils.CreateRateLimiter()

local function pushFeedback(player: Player, ok: boolean, message: string)
    Remotes.GetEvent("ActionFeedback"):FireClient(player, {
        Success = ok,
        Message = message,
    })
end

function QuestCodeService.RedeemCode(player: Player, rawCode: string): (boolean, string)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile unavailable"
    end
    local clean = string.upper((string.gsub(rawCode, "%s+", "")))
    local codeDef = QuestAndCodeConfig.PromoCodes[clean]
    if not codeDef or not codeDef.Active then
        return false, "Invalid or expired code"
    end
    if profile.RedeemedCodes[clean] then
        return false, "Code already redeemed!"
    end

    profile.RedeemedCodes[clean] = true
    DataService.AddCash(player, codeDef.RewardCash)
    if codeDef.LuckDurationSeconds and codeDef.LuckDurationSeconds > 0 then
        local now = os.time()
        local base = math.max(now, profile.ActiveBuffs.LuckUntil or 0)
        profile.ActiveBuffs.LuckUntil = base + codeDef.LuckDurationSeconds
    end

    DataService.MarkDirty(player)
    BaseService.SyncProfileToClient(player)
    return true, codeDef.Description
end

function QuestCodeService.ClaimQuest(player: Player, questId: string): (boolean, string)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile unavailable"
    end
    DataService.EnsureDailyQuestReset(profile)

    if profile.ClaimedQuests[questId] then
        return false, "Already claimed today!"
    end

    local targetDef: QuestAndCodeConfig.QuestDef? = nil
    for _, q in ipairs(QuestAndCodeConfig.DailyQuests) do
        if q.Id == questId then
            targetDef = q
            break
        end
    end
    if not targetDef then
        return false, "Quest not found"
    end

    local progress = (profile.QuestProgress :: any)[targetDef.StatKey] or 0
    if progress < targetDef.Target then
        return false, string.format("Progress %d/%d", progress, targetDef.Target)
    end

    profile.ClaimedQuests[questId] = true
    DataService.AddCash(player, targetDef.RewardCash)
    DataService.MarkDirty(player)
    BaseService.SyncProfileToClient(player)
    return true, string.format("Claimed +%s!", Utils.FormatCash(targetDef.RewardCash))
end

function QuestCodeService.BuyMerchantItem(player: Player, merchantId: string): (boolean, string)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile unavailable"
    end
    local def = QuestAndCodeConfig.MerchantById[merchantId]
    if not def then
        return false, "Merchant item not found"
    end
    if profile.Cash < def.Cost then
        return false, "Not enough Cash"
    end

    profile.Cash -= def.Cost
    local now = os.time()
    local msg = "Purchased " .. def.Name

    if def.BuffType == "LuckElixir" then
        profile.ActiveBuffs.LuckUntil = math.max(now, profile.ActiveBuffs.LuckUntil or 0) + def.DurationSeconds
    elseif def.BuffType == "Featherweight" then
        profile.ActiveBuffs.FeatherUntil = math.max(now, profile.ActiveBuffs.FeatherUntil or 0) + def.DurationSeconds
        CarryStealService.ApplyCarrierWalkSpeed(player)
    elseif def.BuffType == "ShadowCloak" then
        profile.ActiveBuffs.ShadowCloakUntil = math.max(now, profile.ActiveBuffs.ShadowCloakUntil or 0) + def.DurationSeconds
    elseif def.BuffType == "MysteryCrate" then
        local luck = DataService.GetPlayerLuckMultiplier(player) * 3.0
        local rolledRarity = RarityConfig.RollRarity(luck)
        -- Mystery Crate guarantees at least Rare!
        if RarityConfig.Get(rolledRarity).Order < 3 then
            rolledRarity = "Rare"
        end
        local pool = {}
        for _, item in ipairs(ItemCatalog.All) do
            if item.Rarity == rolledRarity and item.BiomeId ~= "WorldEvent" then
                table.insert(pool, item)
            end
        end
        local chosen = Utils.PickRandom(pool) or ItemCatalog.Get("frozen_sun")
        local mut = MutationConfig.RollMutation(luck)
        if chosen then
            if not CarryStealService.IsCarrying(player) then
                CarryStealService.GiveCarryItem(player, chosen, chosen.BiomeId, mut)
                msg = string.format("Crate dropped %s %s! Run to Base!", MutationConfig.Get(mut).Prefix, chosen.Name)
            else
                BaseService.AddExtractedItemToBase(player, chosen, "MysteryCrate", mut)
                msg = string.format("Crate added %s %s to Base!", MutationConfig.Get(mut).Prefix, chosen.Name)
            end
        end
    end

    DataService.MarkDirty(player)
    BaseService.SyncProfileToClient(player)
    return true, msg
end

function QuestCodeService.AscendRebirth(player: Player): (boolean, string)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile unavailable"
    end
    local cost = QuestAndCodeConfig.GetRebirthCost(profile.Rebirths or 0)
    if profile.Cash < cost then
        return false, string.format("Need %s Cash to Rebirth", Utils.FormatCash(cost))
    end

    -- Preserve ALL 0.01% Secrets, Discovered Codex, Gadgets, Codes & Cosmetics!
    local keptVault: { Types.OwnedItemInstance } = {}
    local slotCounter = 1
    for _, inst in ipairs(profile.VaultItems) do
        local def = ItemCatalog.Get(inst.ItemId)
        if def and (def.Rarity == "Secret" or def.IsSecret) then
            inst.PedestalSlot = if slotCounter <= 4 then slotCounter else nil
            slotCounter += 1
            table.insert(keptVault, inst)
        end
    end

    profile.Rebirths = (profile.Rebirths or 0) + 1
    profile.Cash = GameConfig.STARTING_CASH
    profile.UncollectedSafeCash = 0
    profile.BaseTier = 1
    profile.VaultItems = keptVault

    DataService.MarkDirty(player)
    local slot = BaseService.GetPlayerSlot(player)
    if slot then
        BaseService.RefreshBaseVisuals(slot)
    end
    BaseService.SyncProfileToClient(player)

    Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
        Type = "PlayerRebirth",
        PlayerName = player.Name,
        Rebirths = profile.Rebirths,
    })

    return true, string.format("ASCENDED TO REBIRTH %d! (+%.0f%% Income)", profile.Rebirths, profile.Rebirths * 50)
end

function QuestCodeService.Start()
    Remotes.GetEvent("RequestRedeemCode").OnServerEvent:Connect(function(player, code)
        if type(code) ~= "string" then
            return
        end
        if not QuestCodeService._rateLimiter:Check(player.UserId, "Code", 0.75) then
            return
        end
        local ok, msg = QuestCodeService.RedeemCode(player, code)
        pushFeedback(player, ok, msg)
    end)

    Remotes.GetEvent("RequestClaimQuest").OnServerEvent:Connect(function(player, questId)
        if type(questId) ~= "string" then
            return
        end
        if not QuestCodeService._rateLimiter:Check(player.UserId, "ClaimQuest", 0.4) then
            return
        end
        local ok, msg = QuestCodeService.ClaimQuest(player, questId)
        pushFeedback(player, ok, msg)
    end)

    Remotes.GetEvent("RequestBuyMerchantItem").OnServerEvent:Connect(function(player, merchId)
        if type(merchId) ~= "string" then
            return
        end
        if not QuestCodeService._rateLimiter:Check(player.UserId, "BuyMerch", 0.5) then
            return
        end
        local ok, msg = QuestCodeService.BuyMerchantItem(player, merchId)
        pushFeedback(player, ok, msg)
    end)

    Remotes.GetEvent("RequestRebirth").OnServerEvent:Connect(function(player)
        if not QuestCodeService._rateLimiter:Check(player.UserId, "Rebirth", 1.5) then
            return
        end
        local ok, msg = QuestCodeService.AscendRebirth(player)
        pushFeedback(player, ok, msg)
    end)

    Players.PlayerRemoving:Connect(function(player)
        QuestCodeService._rateLimiter:ClearPlayer(player.UserId)
    end)
end

return QuestCodeService
