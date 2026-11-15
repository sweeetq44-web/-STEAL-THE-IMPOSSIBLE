--!strict
-- Free-to-Play Cash Progression Shop: Tech Upgrades & In-Game Utility Gadgets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local BaseConfig = require(Shared.BaseConfig)
local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local DataService = require(script.Parent.DataService)
local BaseService = require(script.Parent.BaseService)
local CarryStealService = require(script.Parent.CarryStealService)
local ItemSpawnService = require(script.Parent.ItemSpawnService)

local ShopService = {}
ShopService._gadgetCooldowns = {} :: { [string]: number }
ShopService._rateLimiter = Utils.CreateRateLimiter()

function ShopService.BuyTechUpgrade(player: Player, techId: string): (boolean, string)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile missing"
    end
    local currentLevel = profile.TechLevels[techId]
    if currentLevel == nil then
        return false, "Invalid tech"
    end
    local cost = BaseConfig.GetTechCost(techId, currentLevel)
    if not cost then
        return false, "Already Max Level!"
    end
    if profile.Cash < cost then
        return false, "Not enough Cash"
    end

    profile.Cash -= cost
    profile.TechLevels[techId] = currentLevel + 1
    DataService.MarkDirty(player)
    CarryStealService.ApplyCarrierWalkSpeed(player)
    BaseService.SyncProfileToClient(player)
    return true, "Upgraded!"
end

function ShopService.BuyGadget(player: Player, gadgetId: string): (boolean, string)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile missing"
    end
    local def = BaseConfig.GadgetById[gadgetId]
    if not def then
        return false, "Invalid gadget"
    end
    if profile.OwnedGadgets[gadgetId] then
        return false, "Already owned"
    end
    if profile.Cash < def.Cost then
        return false, "Not enough Cash"
    end

    profile.Cash -= def.Cost
    profile.OwnedGadgets[gadgetId] = true
    DataService.MarkDirty(player)
    BaseService.SyncProfileToClient(player)
    return true, "Purchased!"
end

function ShopService.ActivateGadget(player: Player, gadgetId: string): (boolean, any?)
    local profile = DataService.GetProfile(player)
    if not profile or not profile.OwnedGadgets[gadgetId] then
        return false, "Gadget not owned"
    end
    local def = BaseConfig.GadgetById[gadgetId]
    if not def then
        return false, "Invalid gadget"
    end

    local key = tostring(player.UserId) .. ":" .. gadgetId
    local now = os.clock()
    local readyAt = ShopService._gadgetCooldowns[key] or 0
    if now < readyAt then
        return false, string.format("Cooldown %.1fs", readyAt - now)
    end
    ShopService._gadgetCooldowns[key] = now + def.Cooldown

    local char = player.Character
    local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

    if gadgetId == "speed_coil" then
        player:SetAttribute("GadgetSpeedBoost", 12)
        CarryStealService.ApplyCarrierWalkSpeed(player)
        task.delay(4.5, function()
            if player.Parent then
                player:SetAttribute("GadgetSpeedBoost", 0)
                CarryStealService.ApplyCarrierWalkSpeed(player)
            end
        end)
        return true, { Type = "speed_coil", Duration = 4.5 }
    elseif gadgetId == "phase_dash" then
        if hrp then
            hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * 65 + Vector3.new(0, 12, 0)
        end
        return true, { Type = "phase_dash" }
    elseif gadgetId == "magnet_radar" then
        local rarest = ItemSpawnService.GetRarestActiveNode()
        if rarest then
            return true, {
                Type = "magnet_radar",
                TargetPos = rarest.Position,
                ItemName = rarest.ItemDef.Name,
                Rarity = rarest.ItemDef.Rarity,
            }
        end
        return true, { Type = "magnet_radar", TargetPos = nil }
    elseif gadgetId == "frost_bolas" then
        if hrp then
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player and CarryStealService.IsCarrying(other) then
                    local oChar = other.Character
                    local oRoot = if oChar then oChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
                    local oHum = if oChar then oChar:FindFirstChildOfClass("Humanoid") else nil
                    if oRoot and oHum and (oRoot.Position - hrp.Position).Magnitude <= 26 then
                        oHum.WalkSpeed = 8
                        task.delay(2.5, function()
                            if other.Parent then
                                CarryStealService.ApplyCarrierWalkSpeed(other)
                            end
                        end)
                    end
                end
            end
        end
        return true, { Type = "frost_bolas" }
    end

    return false, "Unknown gadget"
end

function ShopService.Start()
    Remotes.GetEvent("RequestUpgradeTech").OnServerEvent:Connect(function(player, techId)
        if type(techId) ~= "string" then
            return
        end
        if not ShopService._rateLimiter:Check(player.UserId, "UpgradeTech", 0.3) then
            return
        end
        ShopService.BuyTechUpgrade(player, techId)
    end)

    Remotes.GetEvent("RequestBuyGadget").OnServerEvent:Connect(function(player, gadgetId)
        if type(gadgetId) ~= "string" then
            return
        end
        if not ShopService._rateLimiter:Check(player.UserId, "BuyGadget", 0.4) then
            return
        end
        ShopService.BuyGadget(player, gadgetId)
    end)

    Remotes.GetEvent("RequestUseGadget").OnServerEvent:Connect(function(player, gadgetId)
        if type(gadgetId) ~= "string" then
            return
        end
        if not ShopService._rateLimiter:Check(player.UserId, "UseGadget", 0.4) then
            return
        end
        local ok, payload = ShopService.ActivateGadget(player, gadgetId)
        if ok and payload then
            Remotes.GetEvent("CosmeticFXBurst"):FireClient(player, payload)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        ShopService._rateLimiter:ClearPlayer(player.UserId)
    end)
end

return ShopService
