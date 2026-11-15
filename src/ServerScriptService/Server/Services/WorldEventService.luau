--!strict
-- Global Growth Feature #1: "THE WORLD IS ENDING"
-- Every 30 minutes (1800s), triggers a dramatic 90s world-changing apocalypse:
--   1. MeteorShower  -> Blazing meteors crash across the map + drop Apocalypse Star Shards
--   2. GiantMonster  -> 60-stud Titan of the End roams the arena with shockwave stomps
--   3. GravityLoss   -> Workspace.Gravity drops to 42 (Moon-Jump chaos + floating orbs!)

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local GameConfig = require(Shared.GameConfig)
local ItemCatalog = require(Shared.ItemCatalog)
local Remotes = require(Shared.Remotes)

local ItemSpawnService = require(script.Parent.ItemSpawnService)

local WorldEventService = {}
WorldEventService.IsActive = false
WorldEventService.CurrentEvent = nil :: Types.WorldEventType?
WorldEventService.ActiveUntil = 0
WorldEventService.NextEventAt = 0
WorldEventService._eventIndex = 0
WorldEventService._activeProps = {} :: { Instance }

local EVENT_ROTATION: { Types.WorldEventType } = {
    "MeteorShower",
    "GiantMonster",
    "GravityLoss",
}

local function clearEventProps()
    for _, inst in ipairs(WorldEventService._activeProps) do
        if inst and inst.Parent then
            inst:Destroy()
        end
    end
    WorldEventService._activeProps = {}
end

local function getFXFolder(): Instance
    local gw = Workspace:FindFirstChild("GameWorld")
    local fx = if gw then gw:FindFirstChild("WorldEventFX") else nil
    return fx or Workspace
end

local function runMeteorShower(duration: number)
    local fxRoot = getFXFolder()
    local meteorStarItem = ItemCatalog.Get("world_ending_meteor_core")
    task.spawn(function()
        local stopAt = os.clock() + duration
        local dropCount = 0
        while WorldEventService.IsActive and WorldEventService.CurrentEvent == "MeteorShower" and os.clock() < stopAt do
            local ang = math.random() * math.pi * 2
            local dist = math.random(35, 310)
            local targetPos = Vector3.new(math.cos(ang) * dist, 5, math.sin(ang) * dist)

            -- Warning circle on ground
            local warnRing = Instance.new("Part")
            warnRing.Name = "MeteorTargetRing"
            warnRing.Size = Vector3.new(0.5, 20, 20)
            warnRing.Shape = Enum.PartType.Cylinder
            warnRing.Color = Color3.fromRGB(255, 55, 45)
            warnRing.Material = Enum.Material.Neon
            warnRing.Transparency = 0.45
            warnRing.Anchored = true
            warnRing.CanCollide = false
            warnRing.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, 0, math.rad(90))
            warnRing.Parent = fxRoot
            table.insert(WorldEventService._activeProps, warnRing)

            -- Plunging Meteor Sphere
            local meteor = Instance.new("Part")
            meteor.Name = "FallingMeteor"
            meteor.Size = Vector3.new(10, 10, 10)
            meteor.Shape = Enum.PartType.Ball
            meteor.Color = Color3.fromRGB(255, 115, 35)
            meteor.Material = Enum.Material.Neon
            meteor.Anchored = true
            meteor.CanCollide = false
            meteor.CFrame = CFrame.new(targetPos + Vector3.new(35, 160, -25))
            meteor.Parent = fxRoot
            table.insert(WorldEventService._activeProps, meteor)

            local tween = TweenService:Create(
                meteor,
                TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0)) }
            )
            tween:Play()

            task.delay(1.15, function()
                if warnRing.Parent then
                    warnRing:Destroy()
                end
                if meteor.Parent then
                    meteor:Destroy()
                end
                -- Knockback players very close to meteor impact
                for _, player in ipairs(Players:GetPlayers()) do
                    local char = player.Character
                    local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
                    if hrp and (hrp.Position - targetPos).Magnitude < 16 then
                        hrp.AssemblyLinearVelocity = (hrp.Position - targetPos).Unit * 45 + Vector3.new(0, 40, 0)
                    end
                end
                -- Every 4th meteor drops an Impossible Apocalypse Star Shard!
                dropCount += 1
                if meteorStarItem and (dropCount % 4 == 0) and WorldEventService.IsActive then
                    ItemSpawnService.SpawnSpecificItemAt(meteorStarItem, targetPos + Vector3.new(0, 5, 0), "WorldEvent", true)
                end
            end)

            task.wait(2.2)
        end
    end)
end

local function runGiantMonster(duration: number)
    local fxRoot = getFXFolder()
    local titan = Instance.new("Model")
    titan.Name = "TitanOfTheEnd"

    local torso = Instance.new("Part")
    torso.Name = "TitanCore"
    torso.Size = Vector3.new(26, 44, 18)
    torso.Color = Color3.fromRGB(25, 18, 34)
    torso.Material = Enum.Material.Basalt
    torso.Anchored = true
    torso.CanCollide = true
    torso.CFrame = CFrame.new(0, 26, -120)
    torso.Parent = titan
    titan.PrimaryPart = torso

    local eye = Instance.new("Part")
    eye.Name = "TitanLaserEye"
    eye.Size = Vector3.new(12, 6, 4)
    eye.Color = Color3.fromRGB(255, 45, 75)
    eye.Material = Enum.Material.Neon
    eye.Anchored = true
    eye.CanCollide = false
    eye.CFrame = torso.CFrame * CFrame.new(0, 14, 9.5)
    eye.Parent = titan

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 45, 75)
    light.Range = 60
    light.Brightness = 3
    light.Parent = eye

    titan.Parent = fxRoot
    table.insert(WorldEventService._activeProps, titan)

    local titanLoot = ItemCatalog.Get("world_ending_meteor_core")
    task.spawn(function()
        local stopAt = os.clock() + duration
        local angle = 0
        while WorldEventService.IsActive and WorldEventService.CurrentEvent == "GiantMonster" and os.clock() < stopAt do
            angle += 0.35
            local pos = Vector3.new(math.cos(angle) * 115, 26, math.sin(angle) * 115)
            local lookAt = Vector3.new(math.cos(angle + 0.5) * 115, 26, math.sin(angle + 0.5) * 115)
            local nextCF = CFrame.lookAt(pos, lookAt)
            torso.CFrame = nextCF
            eye.CFrame = nextCF * CFrame.new(0, 14, -9.5)

            -- Drop Apocalypse Relic behind the Titan's footsteps periodically
            if titanLoot and math.random() < 0.25 then
                ItemSpawnService.SpawnSpecificItemAt(
                    titanLoot,
                    Vector3.new(pos.X, 7.5, pos.Z),
                    "WorldEvent",
                    true
                )
            end
            task.wait(1.8)
        end
    end)
end

local function runGravityLoss(duration: number)
    Workspace.Gravity = GameConfig.ZERO_G_GRAVITY
    local fxRoot = getFXFolder()

    -- Spawn floating cosmic zero-G rings across the sky
    for i = 1, 14 do
        local ang = (i / 14) * math.pi * 2
        local r = math.random(45, 260)
        local orb = Instance.new("Part")
        orb.Name = "ZeroGOrb_" .. tostring(i)
        orb.Size = Vector3.new(8, 8, 8)
        orb.Shape = Enum.PartType.Ball
        orb.Color = Color3.fromRGB(0, 235, 255)
        orb.Material = Enum.Material.ForceField
        orb.Anchored = true
        orb.CanCollide = false
        orb.CFrame = CFrame.new(math.cos(ang) * r, math.random(22, 65), math.sin(ang) * r)
        orb.Parent = fxRoot
        table.insert(WorldEventService._activeProps, orb)
    end

    task.delay(duration, function()
        if not WorldEventService.IsActive or WorldEventService.CurrentEvent ~= "GravityLoss" then
            Workspace.Gravity = GameConfig.NORMAL_GRAVITY
        end
    end)
end

function WorldEventService.TriggerWorldEnding(eventType: Types.WorldEventType?, durationOverride: number?)
    if WorldEventService.IsActive then
        WorldEventService.EndWorldEnding()
    end

    local chosen: Types.WorldEventType
    if eventType then
        chosen = eventType
    else
        WorldEventService._eventIndex = (WorldEventService._eventIndex % #EVENT_ROTATION) + 1
        chosen = EVENT_ROTATION[WorldEventService._eventIndex]
    end

    local dur = durationOverride or GameConfig.WORLD_ENDING_DURATION_SECONDS
    WorldEventService.IsActive = true
    WorldEventService.CurrentEvent = chosen
    WorldEventService.ActiveUntil = os.time() + dur

    -- Boost rare loot spawns during apocalypse!
    ItemSpawnService.SetWorldEventLuckBonus(2.25)

    -- Dramatic apocalyptic sky tint
    Lighting.FogColor = if chosen == "GravityLoss"
        then Color3.fromRGB(16, 22, 58)
        else Color3.fromRGB(58, 18, 22)
    Lighting.Ambient = if chosen == "GravityLoss"
        then Color3.fromRGB(45, 75, 130)
        else Color3.fromRGB(115, 42, 42)

    if chosen == "MeteorShower" then
        runMeteorShower(dur)
    elseif chosen == "GiantMonster" then
        runGiantMonster(dur)
    elseif chosen == "GravityLoss" then
        runGravityLoss(dur)
    end

    Remotes.GetEvent("WorldEndingFX"):FireAllClients({
        Active = true,
        EventType = chosen,
        Duration = dur,
    })

    Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
        Type = "WorldEndingStarted",
        EventType = chosen,
    })
end

function WorldEventService.EndWorldEnding()
    if not WorldEventService.IsActive then
        return
    end
    WorldEventService.IsActive = false
    WorldEventService.CurrentEvent = nil
    WorldEventService.NextEventAt = os.time() + GameConfig.WORLD_ENDING_INTERVAL_SECONDS

    Workspace.Gravity = GameConfig.NORMAL_GRAVITY
    Lighting.FogColor = Color3.fromRGB(15, 20, 36)
    Lighting.Ambient = Color3.fromRGB(46, 51, 71)
    ItemSpawnService.SetWorldEventLuckBonus(1.0)
    clearEventProps()

    Remotes.GetEvent("WorldEndingFX"):FireAllClients({
        Active = false,
    })
end

function WorldEventService.Step(nowTime: number)
    if WorldEventService.IsActive then
        if nowTime >= WorldEventService.ActiveUntil then
            WorldEventService.EndWorldEnding()
        end
    else
        if nowTime >= WorldEventService.NextEventAt then
            WorldEventService.TriggerWorldEnding()
        end
    end
end

function WorldEventService.GetTimerState(nowTime: number?): { IsActive: boolean, EventType: Types.WorldEventType?, SecondsLeft: number }
    local now = nowTime or os.time()
    if WorldEventService.IsActive then
        return {
            IsActive = true,
            EventType = WorldEventService.CurrentEvent,
            SecondsLeft = math.max(0, WorldEventService.ActiveUntil - now),
        }
    end
    return {
        IsActive = false,
        EventType = nil,
        SecondsLeft = math.max(0, WorldEventService.NextEventAt - now),
    }
end

function WorldEventService.Start()
    Workspace.Gravity = GameConfig.NORMAL_GRAVITY
    WorldEventService.NextEventAt = os.time() + GameConfig.WORLD_ENDING_INTERVAL_SECONDS
end

return WorldEventService
