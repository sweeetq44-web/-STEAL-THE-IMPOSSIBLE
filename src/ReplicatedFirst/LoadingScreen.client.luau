--!strict
-- Sleek ReplicatedFirst Loading Screen for STEAL THE IMPOSSIBLE

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingOverlay"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(10, 12, 22)
bg.BorderSizePixel = 0
bg.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.8, 0, 0, 72)
title.Position = UDim2.fromScale(0.1, 0.38)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(0, 245, 255)
title.Text = "STEAL THE IMPOSSIBLE"
title.Parent = bg

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(0.7, 0, 0, 34)
sub.Position = UDim2.fromScale(0.15, 0.50)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.GothamMedium
sub.TextScaled = true
sub.TextColor3 = Color3.fromRGB(190, 205, 235)
sub.Text = "Syncing 8 Bases, Biomes & 0.01% Secrets..."
sub.Parent = bg

task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(0.8)
    local fade = TweenService:Create(bg, TweenInfo.new(0.45), { BackgroundTransparency = 1 })
    TweenService:Create(title, TweenInfo.new(0.45), { TextTransparency = 1 }):Play()
    TweenService:Create(sub, TweenInfo.new(0.45), { TextTransparency = 1 }):Play()
    fade:Play()
    fade.Completed:Wait()
    gui:Destroy()
end)
