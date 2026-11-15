--!strict
-- Global Leaderboards UI (World Richest Net Worth, Most Stolen, 0.01% Secret Hunters)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local UITheme = require(script.Parent.UITheme)
local HUDController = require(script.Parent.HUDController)

local LeaderboardController = {}
local modalPanel: Frame
local bodyFrame: ScrollingFrame
local activeCategory: "NetWorth" | "Steals" | "Secrets" = "NetWorth"

local function clearChildren(parent: Instance)
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end
end

function LeaderboardController.Refresh()
    if not bodyFrame then
        return
    end
    clearChildren(bodyFrame)

    -- Category Tab Bar
    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1, -10, 0, 42)
    tabs.BackgroundTransparency = 1
    tabs.LayoutOrder = 1
    tabs.Parent = bodyFrame

    local tl = Instance.new("UIListLayout")
    tl.FillDirection = Enum.FillDirection.Horizontal
    tl.Padding = UDim.new(0, 8)
    tl.Parent = tabs

    for _, tabDef in ipairs({
        { Key = "NetWorth", Label = "🏆 Richest (Net Worth)" },
        { Key = "Steals", Label = "⚡ Most Steals" },
        { Key = "Secrets", Label = "✨ Secret Hunters" },
    }) do
        local isSel = (activeCategory == tabDef.Key)
        local btn = UITheme.MakeButton({
            Text = tabDef.Label,
            Size = UDim2.fromOffset(180, 36),
            Color = if isSel then UITheme.Colors.Gold else UITheme.Colors.BgCard,
            TextColor = if isSel then Color3.fromRGB(14, 18, 28) else UITheme.Colors.TextMain,
            Parent = tabs,
            FontSize = 13,
        })
        btn.MouseButton1Click:Connect(function()
            activeCategory = tabDef.Key :: any
            LeaderboardController.Refresh()
        end)
    end

    local ok, data = pcall(function()
        return Remotes.GetFunction("GetLeaderboard"):InvokeServer()
    end)
    if not ok or type(data) ~= "table" then
        return
    end

    local rows = data[activeCategory] or {}
    for idx, entry in ipairs(rows) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 48)
        row.BackgroundColor3 = UITheme.Colors.BgCard
        UITheme.AddCorner(row, 9)
        UITheme.AddStroke(row, if entry.Rank == 1 then UITheme.Colors.Gold else UITheme.Colors.Stroke, 1.3)
        row.LayoutOrder = idx + 2
        row.Parent = bodyFrame

        local left = Instance.new("TextLabel")
        left.Size = UDim2.new(0.6, 0, 1, 0)
        left.Position = UDim2.fromOffset(14, 0)
        left.BackgroundTransparency = 1
        left.Font = Enum.Font.GothamBlack
        left.TextSize = 15
        left.TextXAlignment = Enum.TextXAlignment.Left
        left.TextColor3 = if entry.Rank <= 3 then UITheme.Colors.Gold else UITheme.Colors.TextMain
        left.Text = string.format("#%d   %s", entry.Rank, tostring(entry.Name))
        left.Parent = row

        local right = Instance.new("TextLabel")
        right.Size = UDim2.new(0.35, 0, 1, 0)
        right.Position = UDim2.new(0.62, 0, 0, 0)
        right.BackgroundTransparency = 1
        right.Font = Enum.Font.GothamBold
        right.TextSize = 15
        right.TextXAlignment = Enum.TextXAlignment.Right
        right.TextColor3 = UITheme.Colors.Cyan
        right.Text = if activeCategory == "NetWorth" then Utils.FormatCash(entry.Value) else tostring(entry.Value)
        right.Parent = row
    end
end

function LeaderboardController.Init(rootGui: ScreenGui)
    local panel, body, closeBtn = UITheme.CreateModal("LeaderboardModal", "🏆 GLOBAL LEADERBOARDS", rootGui, UITheme.Colors.Gold)
    modalPanel = panel
    bodyFrame = body
    closeBtn.MouseButton1Click:Connect(function()
        modalPanel.Visible = false
    end)
    HUDController.RegisterModal("Rank", modalPanel, LeaderboardController.Refresh)
end

return LeaderboardController
