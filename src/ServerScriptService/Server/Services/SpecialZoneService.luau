--!strict
-- 15-Minute Rotating Special Zone ("THE RIFT DIMENSION")
-- Every 15 minutes (900s), opens a high-tier rotating zone for 5 minutes (300s).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GameConfig = require(Shared.GameConfig)
local BiomeConfig = require(Shared.BiomeConfig)
local Remotes = require(Shared.Remotes)

local WorldBuilder = require(script.Parent.WorldBuilder)
local ItemSpawnService = require(script.Parent.ItemSpawnService)

local SpecialZoneService = {}
SpecialZoneService.IsActive = false
SpecialZoneService.CurrentThemeIndex = 1
SpecialZoneService.ActiveUntil = 0
SpecialZoneService.NextOpenAt = 0
SpecialZoneService._portalTouchConn = nil :: RBXScriptConnection?

function SpecialZoneService.GetCurrentTheme(): BiomeConfig.SpecialRiftTheme
    return BiomeConfig.SpecialRiftThemes[SpecialZoneService.CurrentThemeIndex] or BiomeConfig.SpecialRiftThemes[1]
end

local function updatePortalVisuals(open: boolean, theme: BiomeConfig.SpecialRiftTheme)
    local gate = WorldBuilder.RiftPortalRing
    if not gate then
        return
    end
    gate:SetAttribute("RiftPortalActive", open)
    gate.Color = theme.AccentColor
    gate.Transparency = if open then 0.2 else 0.85

    local sign = gate:FindFirstChild("WorldSign")
    local frame = if sign then sign:FindFirstChildOfClass("Frame") else nil
    local label = if frame then frame:FindFirstChildOfClass("TextLabel") else nil
    if label then
        label.Text = if open
            then ("🌀 " .. theme.Name:upper() .. "\nENTER RIFT!")
            else ("15M SPECIAL RIFT\nNEXT: " .. theme.Name:upper())
    end

    if WorldBuilder.RiftArenaFolder then
        local plat = WorldBuilder.RiftArenaFolder:FindFirstChild("RiftPlatform") :: BasePart?
        if plat then
            plat.Color = theme.PrimaryColor
        end
    end
end

function SpecialZoneService.OpenRift(durationOverride: number?)
    if SpecialZoneService.IsActive then
        return
    end
    local dur = durationOverride or GameConfig.SPECIAL_ZONE_DURATION_SECONDS
    local theme = SpecialZoneService.GetCurrentTheme()

    SpecialZoneService.IsActive = true
    SpecialZoneService.ActiveUntil = os.time() + dur
    updatePortalVisuals(true, theme)

    -- Populate Rift loot immediately!
    for _ = 1, GameConfig.MAX_RIFT_ITEMS do
        ItemSpawnService.SpawnInBiome("SpecialRift", theme.LuckMultiplier)
    end

    Remotes.GetEvent("SpecialRiftFX"):FireAllClients({
        Active = true,
        ThemeId = theme.Id,
        ThemeName = theme.Name,
        ThemeNameTR = theme.NameTR,
        TimeRemaining = dur,
    })

    Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
        Type = "SpecialRiftOpened",
        ThemeName = theme.Name,
        ThemeNameTR = theme.NameTR,
    })
end

function SpecialZoneService.CloseRift()
    if not SpecialZoneService.IsActive then
        return
    end
    SpecialZoneService.IsActive = false
    SpecialZoneService.NextOpenAt = os.time() + GameConfig.SPECIAL_ZONE_INTERVAL_SECONDS

    -- Evacuate any players still on Rift Sky Platform safely to Central Plaza
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
        if hrp and (hrp.Position - GameConfig.RIFT_ARENA_POSITION).Magnitude < 90 then
            hrp.CFrame = CFrame.new(0, 7, 26)
        end
    end

    ItemSpawnService.ClearBiomeSpawns("SpecialRift")
    SpecialZoneService.CurrentThemeIndex = (SpecialZoneService.CurrentThemeIndex % #BiomeConfig.SpecialRiftThemes) + 1
    updatePortalVisuals(false, SpecialZoneService.GetCurrentTheme())

    Remotes.GetEvent("SpecialRiftFX"):FireAllClients({
        Active = false,
        NextOpenIn = GameConfig.SPECIAL_ZONE_INTERVAL_SECONDS,
    })
end

function SpecialZoneService.Step(nowTime: number)
    if SpecialZoneService.IsActive then
        if nowTime >= SpecialZoneService.ActiveUntil then
            SpecialZoneService.CloseRift()
        end
    else
        if nowTime >= SpecialZoneService.NextOpenAt then
            SpecialZoneService.OpenRift()
        end
    end
end

function SpecialZoneService.GetTimerState(nowTime: number?): { IsOpen: boolean, SecondsLeft: number, ThemeName: string }
    local now = nowTime or os.time()
    local theme = SpecialZoneService.GetCurrentTheme()
    if SpecialZoneService.IsActive then
        return {
            IsOpen = true,
            SecondsLeft = math.max(0, SpecialZoneService.ActiveUntil - now),
            ThemeName = theme.Name,
        }
    end
    return {
        IsOpen = false,
        SecondsLeft = math.max(0, SpecialZoneService.NextOpenAt - now),
        ThemeName = theme.Name,
    }
end

function SpecialZoneService.Start()
    SpecialZoneService.NextOpenAt = os.time() + GameConfig.SPECIAL_ZONE_INTERVAL_SECONDS
    updatePortalVisuals(false, SpecialZoneService.GetCurrentTheme())

    ItemSpawnService.SetRiftCheck(function()
        return SpecialZoneService.IsActive, SpecialZoneService.GetCurrentTheme().LuckMultiplier
    end)

    -- Portal teleport to Rift Sky Arena
    local gate = WorldBuilder.RiftPortalRing
    if gate then
        local tpCooldown: { [number]: number } = {}
        gate.Touched:Connect(function(hit: BasePart)
            if not SpecialZoneService.IsActive then
                return
            end
            local model = hit:FindFirstAncestorOfClass("Model")
            local player = if model then Players:GetPlayerFromCharacter(model) else nil
            local hrp = if model then model:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
            if player and hrp then
                local now = os.clock()
                local lastTp = tpCooldown[player.UserId]
                if lastTp ~= nil and (now - lastTp) < 1.5 then
                    return
                end
                tpCooldown[player.UserId] = now
                hrp.CFrame = CFrame.new(GameConfig.RIFT_ARENA_POSITION + Vector3.new(0, 5, 32))
            end
        end)
    end

    -- Exit pad back to Central Plaza (players carrying Rift loot must sprint back!)
    for _, pad in ipairs(CollectionService:GetTagged("RiftReturnPad")) do
        if pad:IsA("BasePart") then
            local retCooldown: { [number]: number } = {}
            pad.Touched:Connect(function(hit: BasePart)
                local model = hit:FindFirstAncestorOfClass("Model")
                local player = if model then Players:GetPlayerFromCharacter(model) else nil
                local hrp = if model then model:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
                if player and hrp then
                    local now = os.clock()
                    local lastRet = retCooldown[player.UserId]
                    if lastRet ~= nil and (now - lastRet) < 1.5 then
                        return
                    end
                    retCooldown[player.UserId] = now
                    hrp.CFrame = CFrame.new(0, 7, 26)
                end
            end)
        end
    end
end

return SpecialZoneService
