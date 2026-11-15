--!strict
-- Studio / Creator Live-Testing Commands (/test meteor, /test monster, /test gravity, /test rift, /test secret, /test cash)
-- Strictly gated to RunService:IsStudio() or GameConfig.CREATOR_USER_IDS.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GameConfig = require(Shared.GameConfig)
local ItemCatalog = require(Shared.ItemCatalog)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local BaseService = require(script.Parent.BaseService)
local ItemSpawnService = require(script.Parent.ItemSpawnService)
local SpecialZoneService = require(script.Parent.SpecialZoneService)
local WorldEventService = require(script.Parent.WorldEventService)

local AdminTestService = {}

local function isAuthorized(player: Player): boolean
    if RunService:IsStudio() then
        return true
    end
    for _, uid in ipairs(GameConfig.CREATOR_USER_IDS) do
        if uid == player.UserId then
            return true
        end
    end
    return false
end

function AdminTestService.ExecuteCommand(player: Player, rawCommand: string)
    if not isAuthorized(player) then
        return
    end
    local parts = string.split(string.lower(rawCommand), " ")
    if parts[1] ~= "/test" then
        return
    end

    local cmd = parts[2] or ""
    local arg = parts[3]

    if cmd == "meteor" then
        WorldEventService.TriggerWorldEnding("MeteorShower", 35)
    elseif cmd == "monster" then
        WorldEventService.TriggerWorldEnding("GiantMonster", 35)
    elseif cmd == "gravity" then
        WorldEventService.TriggerWorldEnding("GravityLoss", 35)
    elseif cmd == "rift" then
        SpecialZoneService.OpenRift(90)
    elseif cmd == "cash" then
        local amt = tonumber(arg) or 100000
        DataService.AddCash(player, amt)
        BaseService.SyncProfileToClient(player)
    elseif cmd == "secret" or cmd == "item" or cmd == "celestial" then
        local itemId = if cmd == "secret" then "secret_zero_singularity" else (arg or "frozen_sun")
        local forcedMut: any = if cmd == "celestial" then "Celestial" else nil
        local def = ItemCatalog.Get(itemId)
        local char = player.Character
        local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
        if def and hrp then
            ItemSpawnService.SpawnSpecificItemAt(def, hrp.Position + hrp.CFrame.LookVector * 8, def.BiomeId, false, forcedMut)
        end
    elseif cmd == "rebirth" then
        DataService.AddCash(player, 1000000)
        BaseService.SyncProfileToClient(player)
    elseif cmd == "endworld" then
        WorldEventService.EndWorldEnding()
    end
end

function AdminTestService.Start()
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(msg)
            if string.sub(msg, 1, 5) == "/test" then
                AdminTestService.ExecuteCommand(player, msg)
            end
        end)
    end)

    Remotes.GetEvent("RequestAdminCommand").OnServerEvent:Connect(function(player, command)
        if type(command) == "string" then
            AdminTestService.ExecuteCommand(player, command)
        end
    end)
end

return AdminTestService
