--!strict
-- Global Growth Feature #2: "SECRET COLLECTION (0.01%)" & Weekly Limited Codex

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local ItemCatalog = require(Shared.ItemCatalog)
local WeeklyItems = require(Shared.WeeklyItems)
local RarityConfig = require(Shared.RarityConfig)

local UITheme = require(script.Parent.UITheme)
local HUDController = require(script.Parent.HUDController)

local CodexIndexController = {}
local modalPanel: Frame
local bodyFrame: ScrollingFrame

local function clearChildren(parent: Instance)
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end
end

function CodexIndexController.Refresh()
    if not bodyFrame then
        return
    end
    clearChildren(bodyFrame)

    local profile = HUDController.CurrentProfile
    local lang = HUDController.GetLanguage()

    -- Header showing Weekly LiveOps Banner
    local weeklyBanner = Instance.new("TextLabel")
    weeklyBanner.Size = UDim2.new(1, -10, 0, 36)
    weeklyBanner.BackgroundColor3 = Color3.fromRGB(28, 22, 52)
    weeklyBanner.Font = Enum.Font.GothamBlack
    weeklyBanner.TextSize = 14
    weeklyBanner.TextColor3 = UITheme.Colors.Gold
    weeklyBanner.Text = "📅 WEEKLY DROP: " .. if lang == "tr" then WeeklyItems.ACTIVE_WEEK_TITLE_TR else WeeklyItems.ACTIVE_WEEK_TITLE
    UITheme.AddCorner(weeklyBanner, 8)
    weeklyBanner.LayoutOrder = 1
    weeklyBanner.Parent = bodyFrame

    local masteredCount = if profile then ItemCatalog.GetMasteredBiomeCount(profile.DiscoveredItems) else 0
    local masteryBanner = Instance.new("TextLabel")
    masteryBanner.Size = UDim2.new(1, -10, 0, 28)
    masteryBanner.BackgroundColor3 = UITheme.Colors.BgCard
    masteryBanner.Font = Enum.Font.GothamBold
    masteryBanner.TextSize = 13
    masteryBanner.TextColor3 = UITheme.Colors.Cyan
    masteryBanner.Text = string.format("🏆 BIOME MASTERY: %d/5 Biomes Complete (+%d%% Permanent Cash Bonus!)", masteredCount, masteredCount * 20)
    UITheme.AddCorner(masteryBanner, 8)
    masteryBanner.LayoutOrder = 2
    masteryBanner.Parent = bodyFrame

    -- Sort items with 0.01% Secrets & Impossible & Weekly first!
    local sorted = {}
    for _, def in ipairs(ItemCatalog.All) do
        table.insert(sorted, def)
    end
    table.sort(sorted, function(a, b)
        local ra = RarityConfig.Get(a.Rarity).Order
        local rb = RarityConfig.Get(b.Rarity).Order
        if ra ~= rb then
            return ra > rb
        end
        return a.BaseCashValue > b.BaseCashValue
    end)

    for idx, def in ipairs(sorted) do
        local rarity = RarityConfig.Get(def.Rarity)
        local foundCount = if profile then (profile.DiscoveredItems[def.Id] or 0) else 0
        local isSecretUndiscovered = (def.Rarity == "Secret" and foundCount == 0)

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 62)
        card.BackgroundColor3 = UITheme.Colors.BgCard
        UITheme.AddCorner(card, 9)
        UITheme.AddStroke(card, rarity.Color, if def.Rarity == "Secret" then 2 else 1.2)
        card.LayoutOrder = idx + 3
        card.Parent = bodyFrame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.7, 0, 0, 26)
        title.Position = UDim2.fromOffset(12, 6)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 15
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = if foundCount > 0 then rarity.Color else UITheme.Colors.TextMuted
        local dispName = if isSecretUndiscovered then "??? [0.01% SECRET]" elseif lang == "tr" then def.NameTR else def.Name
        local weeklyPrefix = if def.IsWeekly then "[WEEKLY] " else ""
        title.Text = string.format("%s %s%s (%s)", if isSecretUndiscovered then "❓" else def.Icon, weeklyPrefix, dispName, rarity.DisplayName)
        title.Parent = card

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(0.95, 0, 0, 24)
        sub.Position = UDim2.fromOffset(12, 33)
        sub.BackgroundTransparency = 1
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 12
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextColor3 = UITheme.Colors.TextMuted
        sub.Text = if isSecretUndiscovered
            then "Biome: " .. def.BiomeId .. " — 0.01% Global Announcement on Discovery!"
            else (if lang == "tr" then def.DescriptionTR else def.Description)
        sub.Parent = card

        local status = Instance.new("TextLabel")
        status.Size = UDim2.fromOffset(115, 32)
        status.Position = UDim2.new(1, -125, 0, 14)
        status.BackgroundTransparency = 1
        status.Font = Enum.Font.GothamBold
        status.TextSize = 13
        status.TextXAlignment = Enum.TextXAlignment.Right
        status.TextColor3 = if foundCount > 0 then UITheme.Colors.Green else UITheme.Colors.TextMuted
        status.Text = if foundCount > 0 then ("Found ×" .. tostring(foundCount)) else "Undiscovered"
        status.Parent = card
    end
end

function CodexIndexController.Init(rootGui: ScreenGui)
    local panel, body, closeBtn = UITheme.CreateModal("CodexIndexModal", "✨ SECRET COLLECTION & ITEM CODEX", rootGui, UITheme.Colors.Cyan)
    modalPanel = panel
    bodyFrame = body
    closeBtn.MouseButton1Click:Connect(function()
        modalPanel.Visible = false
    end)
    HUDController.RegisterModal("Index", modalPanel, CodexIndexController.Refresh)
end

return CodexIndexController
