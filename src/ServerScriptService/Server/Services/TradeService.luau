--!strict
-- Atomic Server-Authoritative Player-to-Player Trading System
-- Features anti-scam confirm reset on offer modification + full ownership validation!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local DataService = require(script.Parent.DataService)
local BaseService = require(script.Parent.BaseService)

export type TradeOfferSide = {
    UserId: number,
    PlayerName: string,
    ItemUids: { string },
    Cash: number,
    Confirmed: boolean,
}

export type ActiveTrade = {
    TradeId: string,
    SideA: TradeOfferSide,
    SideB: TradeOfferSide,
    CreatedAt: number,
}

local TradeService = {}
TradeService._trades = {} :: { [string]: ActiveTrade }
TradeService._playerTrade = {} :: { [number]: string }
TradeService._pendingRequests = {} :: { [number]: { FromUserId: number, FromName: string } }
TradeService._rateLimiter = Utils.CreateRateLimiter()

local function getSides(trade: ActiveTrade, userId: number): (TradeOfferSide?, TradeOfferSide?)
    if trade.SideA.UserId == userId then
        return trade.SideA, trade.SideB
    elseif trade.SideB.UserId == userId then
        return trade.SideB, trade.SideA
    end
    return nil, nil
end

local function buildSidePayload(side: TradeOfferSide): any
    local profile = DataService.GetProfileByUserId(side.UserId)
    local itemPreviews = {}
    if profile then
        local uidSet: { [string]: boolean } = {}
        for _, uid in ipairs(side.ItemUids) do
            uidSet[uid] = true
        end
        for _, inst in ipairs(profile.VaultItems) do
            if uidSet[inst.Uid] then
                table.insert(itemPreviews, {
                    Uid = inst.Uid,
                    ItemId = inst.ItemId,
                    Mutation = inst.Mutation,
                    HatchedCreature = inst.HatchedCreature,
                })
            end
        end
    end
    return {
        UserId = side.UserId,
        PlayerName = side.PlayerName,
        Cash = side.Cash,
        Confirmed = side.Confirmed,
        Items = itemPreviews,
    }
end

local function syncTrade(trade: ActiveTrade)
    local pA = Players:GetPlayerByUserId(trade.SideA.UserId)
    local pB = Players:GetPlayerByUserId(trade.SideB.UserId)
    local payload = {
        TradeId = trade.TradeId,
        SideA = buildSidePayload(trade.SideA),
        SideB = buildSidePayload(trade.SideB),
    }
    if pA then
        Remotes.GetEvent("TradeStateSync"):FireClient(pA, payload)
    end
    if pB then
        Remotes.GetEvent("TradeStateSync"):FireClient(pB, payload)
    end
end

function TradeService.SendTradeRequest(sender: Player, targetUserId: number): (boolean, string)
    if sender.UserId == targetUserId then
        return false, "Cannot trade with yourself"
    end
    if TradeService._playerTrade[sender.UserId] ~= nil then
        return false, "Already in a trade"
    end
    if TradeService._playerTrade[targetUserId] ~= nil then
        return false, "Target player is busy"
    end
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target then
        return false, "Player offline"
    end

    TradeService._pendingRequests[targetUserId] = {
        FromUserId = sender.UserId,
        FromName = sender.Name,
    }
    Remotes.GetEvent("TradeInvitePrompt"):FireClient(target, {
        FromUserId = sender.UserId,
        FromName = sender.Name,
    })
    return true, "Trade request sent!"
end

function TradeService.RespondTradeRequest(target: Player, fromUserId: number, accept: boolean): (boolean, ActiveTrade?)
    local pending = TradeService._pendingRequests[target.UserId]
    if not pending or pending.FromUserId ~= fromUserId then
        return false, nil
    end
    TradeService._pendingRequests[target.UserId] = nil

    if not accept then
        return false, nil
    end
    local sender = Players:GetPlayerByUserId(fromUserId)
    if not sender or TradeService._playerTrade[sender.UserId] ~= nil or TradeService._playerTrade[target.UserId] ~= nil then
        return false, nil
    end

    local tid = Utils.GenerateUid("trade")
    local trade: ActiveTrade = {
        TradeId = tid,
        SideA = {
            UserId = sender.UserId,
            PlayerName = sender.Name,
            ItemUids = {},
            Cash = 0,
            Confirmed = false,
        },
        SideB = {
            UserId = target.UserId,
            PlayerName = target.Name,
            ItemUids = {},
            Cash = 0,
            Confirmed = false,
        },
        CreatedAt = os.time(),
    }
    TradeService._trades[tid] = trade
    TradeService._playerTrade[sender.UserId] = tid
    TradeService._playerTrade[target.UserId] = tid
    syncTrade(trade)
    return true, trade
end

function TradeService.UpdateOffer(player: Player, itemUids: { string }, offerCash: number): (boolean, string)
    local tid = TradeService._playerTrade[player.UserId]
    local trade = if tid then TradeService._trades[tid] else nil
    local profile = DataService.GetProfile(player)
    if not trade or not profile then
        return false, "No active trade"
    end

    local mine, _other = getSides(trade, player.UserId)
    if not mine then
        return false, "Invalid trade participant"
    end

    local cleanCash = math.max(0, math.floor(offerCash))
    if cleanCash > profile.Cash then
        return false, "Insufficient Cash"
    end

    -- Verify player owns every unique offered item UID
    local ownedByUid: { [string]: boolean } = {}
    for _, inst in ipairs(profile.VaultItems) do
        ownedByUid[inst.Uid] = true
    end

    local verifiedUids: { string } = {}
    local seen: { [string]: boolean } = {}
    for _, uid in ipairs(itemUids) do
        if type(uid) == "string" and ownedByUid[uid] and not seen[uid] and #verifiedUids < 8 then
            seen[uid] = true
            table.insert(verifiedUids, uid)
        end
    end

    mine.ItemUids = verifiedUids
    mine.Cash = cleanCash
    -- Anti-scam protection: ANY offer change un-confirms both participants!
    trade.SideA.Confirmed = false
    trade.SideB.Confirmed = false
    syncTrade(trade)
    return true, "Offer updated"
end

function TradeService.CancelTrade(player: Player)
    local tid = TradeService._playerTrade[player.UserId]
    if not tid then
        return
    end
    local trade = TradeService._trades[tid]
    TradeService._trades[tid] = nil
    if trade then
        TradeService._playerTrade[trade.SideA.UserId] = nil
        TradeService._playerTrade[trade.SideB.UserId] = nil
        local pA = Players:GetPlayerByUserId(trade.SideA.UserId)
        local pB = Players:GetPlayerByUserId(trade.SideB.UserId)
        if pA then
            Remotes.GetEvent("TradeStateSync"):FireClient(pA, nil)
        end
        if pB then
            Remotes.GetEvent("TradeStateSync"):FireClient(pB, nil)
        end
    else
        TradeService._playerTrade[player.UserId] = nil
    end
end

local function executeAtomicTrade(trade: ActiveTrade): (boolean, string)
    local pA = Players:GetPlayerByUserId(trade.SideA.UserId)
    local pB = Players:GetPlayerByUserId(trade.SideB.UserId)
    local profA = if pA then DataService.GetProfile(pA) else nil
    local profB = if pB then DataService.GetProfile(pB) else nil
    if not pA or not pB or not profA or not profB then
        return false, "Participant offline"
    end

    if profA.Cash < trade.SideA.Cash or profB.Cash < trade.SideB.Cash then
        return false, "Cash verification failed"
    end

    -- Check inventory space
    local netA = #profA.VaultItems - #trade.SideA.ItemUids + #trade.SideB.ItemUids
    local netB = #profB.VaultItems - #trade.SideB.ItemUids + #trade.SideA.ItemUids
    if netA > GameConfig.MAX_VAULT_INVENTORY or netB > GameConfig.MAX_VAULT_INVENTORY then
        return false, "Vault full"
    end

    local function extractAndValidate(profile: Types.PlayerProfile, uids: { string }): (boolean, { Types.OwnedItemInstance })
        local want: { [string]: boolean } = {}
        for _, uid in ipairs(uids) do
            want[uid] = true
        end
        local moving: { Types.OwnedItemInstance } = {}
        for _, inst in ipairs(profile.VaultItems) do
            if want[inst.Uid] then
                table.insert(moving, inst)
            end
        end
        if #moving ~= #uids then
            return false, {}
        end
        return true, moving
    end

    local okA, movingFromA = extractAndValidate(profA, trade.SideA.ItemUids)
    local okB, movingFromB = extractAndValidate(profB, trade.SideB.ItemUids)
    if not okA or not okB then
        return false, "Item ownership changed"
    end

    -- Remove from source vaults
    local setA: { [string]: boolean } = {}
    for _, u in ipairs(trade.SideA.ItemUids) do
        setA[u] = true
    end
    local setB: { [string]: boolean } = {}
    for _, u in ipairs(trade.SideB.ItemUids) do
        setB[u] = true
    end

    local nextVaultA: { Types.OwnedItemInstance } = {}
    for _, inst in ipairs(profA.VaultItems) do
        if not setA[inst.Uid] then
            table.insert(nextVaultA, inst)
        end
    end
    for _, inst in ipairs(movingFromB) do
        inst.PedestalSlot = nil
        profA.DiscoveredItems[inst.ItemId] = (profA.DiscoveredItems[inst.ItemId] or 0) + 1
        table.insert(nextVaultA, inst)
    end

    local nextVaultB: { Types.OwnedItemInstance } = {}
    for _, inst in ipairs(profB.VaultItems) do
        if not setB[inst.Uid] then
            table.insert(nextVaultB, inst)
        end
    end
    for _, inst in ipairs(movingFromA) do
        inst.PedestalSlot = nil
        profB.DiscoveredItems[inst.ItemId] = (profB.DiscoveredItems[inst.ItemId] or 0) + 1
        table.insert(nextVaultB, inst)
    end

    profA.VaultItems = nextVaultA
    profB.VaultItems = nextVaultB
    profA.Cash = profA.Cash - trade.SideA.Cash + trade.SideB.Cash
    profB.Cash = profB.Cash - trade.SideB.Cash + trade.SideA.Cash

    DataService.MarkDirty(pA)
    DataService.MarkDirty(pB)

    local sA = BaseService.GetPlayerSlot(pA)
    if sA then
        BaseService.RefreshBaseVisuals(sA)
    end
    local sB = BaseService.GetPlayerSlot(pB)
    if sB then
        BaseService.RefreshBaseVisuals(sB)
    end

    BaseService.SyncProfileToClient(pA)
    BaseService.SyncProfileToClient(pB)
    return true, "Trade completed!"
end

function TradeService.ConfirmTrade(player: Player): (boolean, string)
    local tid = TradeService._playerTrade[player.UserId]
    local trade = if tid then TradeService._trades[tid] else nil
    if not trade then
        return false, "No active trade"
    end
    local mine, other = getSides(trade, player.UserId)
    if not mine or not other then
        return false, "Invalid participant"
    end
    mine.Confirmed = true
    syncTrade(trade)

    if mine.Confirmed and other.Confirmed then
        local ok, msg = executeAtomicTrade(trade)
        TradeService.CancelTrade(player)
        return ok, msg
    end
    return true, "Waiting for partner confirmation"
end

function TradeService.Start()
    Remotes.GetEvent("RequestSendTrade").OnServerEvent:Connect(function(player, targetUserId)
        if type(targetUserId) ~= "number" then
            return
        end
        if not TradeService._rateLimiter:Check(player.UserId, "SendTrade", 1.0) then
            return
        end
        TradeService.SendTradeRequest(player, math.floor(targetUserId))
    end)

    Remotes.GetEvent("RequestRespondTrade").OnServerEvent:Connect(function(player, fromUserId, accept)
        if type(fromUserId) ~= "number" or type(accept) ~= "boolean" then
            return
        end
        TradeService.RespondTradeRequest(player, math.floor(fromUserId), accept)
    end)

    Remotes.GetEvent("RequestUpdateTradeOffer").OnServerEvent:Connect(function(player, uids, offerCash)
        if type(uids) ~= "table" or type(offerCash) ~= "number" then
            return
        end
        if not TradeService._rateLimiter:Check(player.UserId, "UpdateTrade", 0.25) then
            return
        end
        TradeService.UpdateOffer(player, uids, offerCash)
    end)

    Remotes.GetEvent("RequestConfirmTrade").OnServerEvent:Connect(function(player)
        if not TradeService._rateLimiter:Check(player.UserId, "ConfirmTrade", 0.4) then
            return
        end
        TradeService.ConfirmTrade(player)
    end)

    Remotes.GetEvent("RequestCancelTrade").OnServerEvent:Connect(function(player)
        TradeService.CancelTrade(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        TradeService.CancelTrade(player)
        TradeService._pendingRequests[player.UserId] = nil
        TradeService._rateLimiter:ClearPlayer(player.UserId)
    end)
end

return TradeService
