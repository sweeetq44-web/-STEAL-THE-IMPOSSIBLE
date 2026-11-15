--!strict
-- Server Bootstrapper for STEAL THE IMPOSSIBLE (8-Player Server)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services.DataService)
local WorldBuilder = require(Services.WorldBuilder)
local SecretService = require(Services.SecretService)
local BaseService = require(Services.BaseService)
local ItemSpawnService = require(Services.ItemSpawnService)
local CarryStealService = require(Services.CarryStealService)
local SpecialZoneService = require(Services.SpecialZoneService)
local WorldEventService = require(Services.WorldEventService)
local SquadService = require(Services.SquadService)
local HeistService = require(Services.HeistService)
local ShopService = require(Services.ShopService)
local MonetizationService = require(Services.MonetizationService)
local LeaderboardService = require(Services.LeaderboardService)
local QuestCodeService = require(Services.QuestCodeService)
local TradeService = require(Services.TradeService)
local AdminTestService = require(Services.AdminTestService)

-- 1. Ensure Remotes & 3D World Architecture exist before players load
Remotes.EnsureFolder()
WorldBuilder.BuildIfMissing()

-- 2. Start Services in dependency-safe order
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
QuestCodeService.Start()
TradeService.Start()
AdminTestService.Start()

-- Wire JumpPads across biomes to launch explorers back toward Plaza
for _, pad in ipairs(CollectionService:GetTagged("JumpPad")) do
    if pad:IsA("BasePart") then
        local cd: { [number]: number } = {}
        pad.Touched:Connect(function(hit)
            local char = hit.Parent
            local player = if char then Players:GetPlayerFromCharacter(char) else nil
            local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
            if not player or not hrp then
                return
            end
            local now = os.clock()
            if cd[player.UserId] and (now - cd[player.UserId]) < 1.2 then
                return
            end
            cd[player.UserId] = now
            local dirToCenter = (Vector3.new(0, 12, 0) - hrp.Position)
            local flatDir = Vector3.new(dirToCenter.X, 0, dirToCenter.Z)
            local unit = if flatDir.Magnitude > 1 then flatDir.Unit else Vector3.new(0, 0, -1)
            hrp.AssemblyLinearVelocity = unit * 95 + Vector3.new(0, 72, 0)
        end)
    end
end

-- Wire BaseRaidSafe ProximityPrompts (Owner collects cash, Rivals raid when shield is down!)
for _, safePart in ipairs(CollectionService:GetTagged("BaseRaidSafe")) do
    local prompt = safePart:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        local slotNum = safePart:GetAttribute("BaseSlot") :: number?
        prompt.Triggered:Connect(function(player)
            if not slotNum then
                return
            end
            local mySlot = BaseService.GetPlayerSlot(player)
            if mySlot == slotNum then
                local ok, amt = BaseService.CollectBaseSafe(player)
                Remotes.GetEvent("ActionFeedback"):FireClient(player, {
                    Success = ok,
                    Message = if ok then ("Collected +" .. tostring(amt) .. " Cash from Safe!") else "Safe is empty!",
                })
            else
                local ok, msg, amt = BaseService.RaidBaseSafe(player, slotNum)
                Remotes.GetEvent("ActionFeedback"):FireClient(player, {
                    Success = ok,
                    Message = if ok then ("RAIDED +" .. tostring(amt) .. " Cash!") else msg,
                })
            end
        end)
    end
end

-- 3. Player Lifecycle (8-player Base assignment + Profile hydration)
local function onPlayerAdded(player: Player)
    if #Players:GetPlayers() > GameConfig.MAX_PLAYERS then
        player:Kick("Server is full (8/8 players).")
        return
    end

    DataService.LoadPlayer(player)
    MonetizationService.SyncMarketplaceOwnership(player)
    BaseService.ClaimBaseForPlayer(player)
    BaseService.SyncProfileToClient(player)
end

local function onPlayerRemoving(player: Player)
    BaseService.ReleaseBaseForPlayer(player)
    DataService.UnloadPlayer(player)
end

for _, existing in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, existing)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- 4. Master Scheduler Tick (15-min Special Zone + 30-min THE WORLD IS ENDING)
task.spawn(function()
    local timerSyncEvent = Remotes.GetEvent("WorldTimerSync")
    while true do
        local now = os.time()
        SpecialZoneService.Step(now)
        WorldEventService.Step(now)

        timerSyncEvent:FireAllClients({
            Rift = SpecialZoneService.GetTimerState(now),
            WorldEnding = WorldEventService.GetTimerState(now),
        })

        task.wait(1.0)
    end
end)
