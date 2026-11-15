--!strict
-- Client Bootstrapper for STEAL THE IMPOSSIBLE

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)

local Controllers = script.Parent:WaitForChild("Controllers")
local NotificationController = require(Controllers.NotificationController)
local HUDController = require(Controllers.HUDController)
local ActionController = require(Controllers.ActionController)
local BaseManagerController = require(Controllers.BaseManagerController)
local FlexVisitController = require(Controllers.FlexVisitController)
local ShopCosmeticController = require(Controllers.ShopCosmeticController)
local CodexIndexController = require(Controllers.CodexIndexController)
local SquadHeistController = require(Controllers.SquadHeistController)
local LeaderboardController = require(Controllers.LeaderboardController)
local QuestCodeController = require(Controllers.QuestCodeController)
local TradeController = require(Controllers.TradeController)
local WorldEventFXController = require(Controllers.WorldEventFXController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Root Game UI ScreenGui
local rootGui = Instance.new("ScreenGui")
rootGui.Name = "StealTheImpossibleUI"
rootGui.ResetOnSpawn = false
rootGui.IgnoreGuiInset = false
rootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
rootGui.Parent = playerGui

-- Mobile & Small-Screen Responsive Auto-Scaler (keeps HUD & 8-button Dock crisp on phones!)
local uiScale = Instance.new("UIScale")
uiScale.Name = "ResponsiveMobileScale"
uiScale.Scale = 1
uiScale.Parent = rootGui

local function updateResponsiveScale()
    local cam = Workspace.CurrentCamera
    if not cam then
        return
    end
    local vp = cam.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then
        return
    end
    uiScale.Scale = math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.48, 1.0)
end

updateResponsiveScale()
task.spawn(function()
    while true do
        local cam = Workspace.CurrentCamera
        if cam then
            updateResponsiveScale()
            cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
            break
        end
        task.wait(0.2)
    end
end)

-- Mount all Controllers cleanly
NotificationController.SetLanguageGetter(HUDController.GetLanguage)
NotificationController.Init(rootGui)
HUDController.Init(rootGui)
ActionController.Init(rootGui)
BaseManagerController.Init(rootGui)
FlexVisitController.Init(rootGui)
ShopCosmeticController.Init(rootGui)
CodexIndexController.Init(rootGui)
SquadHeistController.Init(rootGui)
LeaderboardController.Init(rootGui)
QuestCodeController.Init(rootGui)
TradeController.Init(rootGui)
WorldEventFXController.Init()

-- Hydrate initial server profile immediately
task.spawn(function()
    local ok, initData = pcall(function()
        return Remotes.GetFunction("GetInitialProfile"):InvokeServer()
    end)
    if ok and initData then
        HUDController.ApplyState(initData)
    end
end)
