--!strict
-- Client Camera Shake for THE WORLD IS ENDING & 3D Magnet Radar Ping Visuals

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)

local NotificationController = require(script.Parent.NotificationController)

local WorldEventFXController = {}
local activeWorldEvent = false

local function pulseCameraShake(intensity: number, duration: number)
    local cam = Workspace.CurrentCamera
    local char = Players.LocalPlayer.Character
    local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
    if not cam or not hum then
        return
    end
    task.spawn(function()
        local stopAt = os.clock() + duration
        while os.clock() < stopAt do
            hum.CameraOffset = Vector3.new(
                (math.random() - 0.5) * intensity,
                (math.random() - 0.5) * intensity,
                (math.random() - 0.5) * intensity
            )
            task.wait(0.05)
        end
        hum.CameraOffset = Vector3.zero
    end)
end

local function spawnRadarBeacon(targetPos: Vector3, itemName: string, rarity: string)
    local char = Players.LocalPlayer.Character
    local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    if not hrp then
        return
    end

    NotificationController.PushToast(string.format("📡 RADAR LOCKED: [%s] %s!", rarity, itemName), Color3.fromRGB(0, 235, 255))

    local dist = (targetPos - hrp.Position).Magnitude
    local beamPart = Instance.new("Part")
    beamPart.Name = "ClientRadarRay"
    beamPart.Size = Vector3.new(0.8, 0.8, dist)
    beamPart.Color = Color3.fromRGB(0, 255, 225)
    beamPart.Material = Enum.Material.Neon
    beamPart.Transparency = 0.35
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.CFrame = CFrame.lookAt((hrp.Position + targetPos) * 0.5, targetPos)
    beamPart.Parent = Workspace

    task.delay(3.5, function()
        if beamPart.Parent then
            beamPart:Destroy()
        end
    end)
end

function WorldEventFXController.Init()
    Remotes.GetEvent("WorldEndingFX").OnClientEvent:Connect(function(payload)
        activeWorldEvent = (payload.Active == true)
        if activeWorldEvent and (payload.EventType == "MeteorShower" or payload.EventType == "GiantMonster") then
            task.spawn(function()
                while activeWorldEvent do
                    pulseCameraShake(0.65, 0.45)
                    task.wait(2.8)
                end
            end)
        end
    end)

    Remotes.GetEvent("CosmeticFXBurst").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then
            return
        end
        if payload.Type == "magnet_radar" and payload.TargetPos then
            spawnRadarBeacon(payload.TargetPos, tostring(payload.ItemName), tostring(payload.Rarity))
        end
    end)
end

return WorldEventFXController
