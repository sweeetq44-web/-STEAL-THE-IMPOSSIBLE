--!strict
-- 0.01% SECRET COLLECTION & Galaxy Egg Hatching + Global MessagingService Announcements

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local GameConfig = require(Shared.GameConfig)
local ItemCatalog = require(Shared.ItemCatalog)
local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local DataService = require(script.Parent.DataService)

local SecretService = {}
SecretService._subscribed = false
SecretService._recentAnnouncements = {} :: { { PlayerName: string, ItemId: string, ItemName: string, Timestamp: number } }

function SecretService.PublishSecretDiscovery(player: Player, itemDef: Types.ItemDefinition)
    local profile = DataService.GetProfile(player)
    local isFirstPersonal = false
    if profile then
        if not profile.DiscoveredSecrets[itemDef.Id] then
            profile.DiscoveredSecrets[itemDef.Id] = os.time()
            isFirstPersonal = true
        end
        profile.SecretCount += 1
        DataService.MarkDirty(player)
    end

    local payload = {
        PlayerName = player.DisplayName ~= "" and player.DisplayName or player.Name,
        Username = player.Name,
        UserId = player.UserId,
        ItemId = itemDef.Id,
        ItemName = itemDef.Name,
        ItemNameTR = itemDef.NameTR,
        Icon = itemDef.Icon,
        Rarity = itemDef.Rarity,
        IsFirstPersonal = isFirstPersonal,
        Timestamp = os.time(),
    }

    -- Broadcast immediately to current server
    Remotes.GetEvent("GlobalSecretAnnouncement"):FireAllClients(payload)
    table.insert(SecretService._recentAnnouncements, 1, {
        PlayerName = payload.PlayerName,
        ItemId = itemDef.Id,
        ItemName = itemDef.Name,
        Timestamp = payload.Timestamp,
    })
    if #SecretService._recentAnnouncements > 20 then
        table.remove(SecretService._recentAnnouncements)
    end

    -- Publish globally across ALL active Roblox servers via MessagingService
    task.spawn(function()
        pcall(function()
            MessagingService:PublishAsync(GameConfig.MESSAGING_SECRET_TOPIC, payload)
        end)
    end)
end

function SecretService.HatchGalaxyEgg(player: Player, instanceUid: string): (boolean, string?, Types.OwnedItemInstance?)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile not loaded", nil
    end

    local targetItem: Types.OwnedItemInstance? = nil
    for _, inst in ipairs(profile.VaultItems) do
        if inst.Uid == instanceUid then
            targetItem = inst
            break
        end
    end

    if not targetItem then
        return false, "Item not found", nil
    end

    local def = ItemCatalog.Get(targetItem.ItemId)
    if not def or def.SpecialBehavior ~= "HatchableEgg" then
        return false, "Only Galaxy Eggs can be hatched", nil
    end

    if targetItem.HatchedCreature ~= nil then
        return false, "Already hatched into " .. targetItem.HatchedCreature, nil
    end

    local creature = ItemCatalog.RollGalaxyCreature()
    targetItem.HatchedCreature = creature.Id
    DataService.MarkDirty(player)

    Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
        Type = "EggHatched",
        PlayerName = player.Name,
        ItemName = def.Name,
        CreatureName = creature.Name,
        CreatureNameTR = creature.NameTR,
        Icon = creature.Icon,
        Multiplier = creature.BonusIncomeMultiplier,
    })

    return true, creature.Id, targetItem
end

function SecretService.GetRecentAnnouncements(): { { PlayerName: string, ItemId: string, ItemName: string, Timestamp: number } }
    return Utils.DeepCopy(SecretService._recentAnnouncements)
end

function SecretService.Start()
    if SecretService._subscribed then
        return
    end
    SecretService._subscribed = true

    task.spawn(function()
        pcall(function()
            MessagingService:SubscribeAsync(GameConfig.MESSAGING_SECRET_TOPIC, function(message)
                local data = message and message.Data
                if type(data) ~= "table" then
                    return
                end
                -- Skip duplicate echo if player is right here in this server
                if Players:GetPlayerByUserId(tonumber(data.UserId) or 0) ~= nil then
                    return
                end
                Remotes.GetEvent("GlobalSecretAnnouncement"):FireAllClients(data)
            end)
        end)
    end)
end

return SecretService
