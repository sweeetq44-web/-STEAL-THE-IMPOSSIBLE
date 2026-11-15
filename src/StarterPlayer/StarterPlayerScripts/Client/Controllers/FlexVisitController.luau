--!strict
-- Global Growth Feature #3: "FLEX YOUR BASE" Browser, Visit Teleport & Like System

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local Localization = require(Shared.Localization)
local Utils = require(Shared.Utils)

local UITheme = require(script.Parent.UITheme)
local HUDController = require(script.Parent.HUDController)

local FlexVisitController = {}
local modalPanel: Frame
local bodyFrame: ScrollingFrame

local function clearChildren(parent: Instance)
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end
end

function FlexVisitController.Refresh()
    if not bodyFrame then
        return
    end
    clearChildren(bodyFrame)

    local lang = HUDController.GetLanguage()
    local ok, bases = pcall(function()
        return Remotes.GetFunction("GetServerBases"):InvokeServer()
    end)
    if not ok or type(bases) ~= "table" then
        return
    end

    for idx, b in ipairs(bases) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 96)
        card.BackgroundColor3 = UITheme.Colors.BgCard
        UITheme.AddCorner(card, 10)
        UITheme.AddStroke(card, if b.Vip then UITheme.Colors.Gold else UITheme.Colors.Purple, 1.5)
        card.LayoutOrder = idx
        card.Parent = bodyFrame

        local vipTag = if b.Vip then "👑 [VIP] " else ""
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.56, 0, 0, 30)
        title.Position = UDim2.fromOffset(14, 10)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 16
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = if b.Vip then UITheme.Colors.Gold else UITheme.Colors.TextMain
        title.Text = string.format("%s%s  (Base #%d • Tier %d)", vipTag, tostring(b.PlayerName), b.Slot, b.BaseTier)
        title.Parent = card

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(0.56, 0, 0, 44)
        sub.Position = UDim2.fromOffset(14, 42)
        sub.BackgroundTransparency = 1
        sub.Font = Enum.Font.GothamMedium
        sub.TextSize = 13
        sub.TextWrapped = true
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextColor3 = UITheme.Colors.TextMuted
        local shieldStr = if b.ShieldActive then "🛡️ Shielded" else "⚡ Unshielded"
        local riskStr = if b.HighStakesMode then string.format("  |  🔐 Safe: %s", Utils.FormatCash(b.UncollectedSafeCash or 0)) else ""
        sub.Text = string.format(
            "Net Worth: %s  |  Rarest: %s  |  ❤️ %d\n%s%s",
            Utils.FormatCash(b.NetWorth or 0),
            tostring(b.RarestItem or "None"),
            b.Likes or 0,
            shieldStr,
            riskStr
        )
        sub.Parent = card

        local visitBtn = UITheme.MakeButton({
            Text = Localization.Get("VISIT_BASE", lang),
            Size = UDim2.fromOffset(128, 38),
            Position = UDim2.new(1, -276, 0, 28),
            Color = UITheme.Colors.Cyan,
            TextColor = Color3.fromRGB(14, 18, 28),
            Parent = card,
            FontSize = 13,
        })
        visitBtn.MouseButton1Click:Connect(function()
            Remotes.GetEvent("RequestVisitBase"):FireServer(b.Slot)
            modalPanel.Visible = false
        end)

        local likeBtn = UITheme.MakeButton({
            Text = Localization.Get("LIKE_BASE", lang),
            Size = UDim2.fromOffset(128, 38),
            Position = UDim2.new(1, -138, 0, 28),
            Color = UITheme.Colors.Purple,
            Parent = card,
            FontSize = 13,
        })
        likeBtn.MouseButton1Click:Connect(function()
            Remotes.GetEvent("RequestLikeBase"):FireServer(b.UserId)
            task.delay(0.25, function()
                if modalPanel.Visible then
                    FlexVisitController.Refresh()
                end
            end)
        end)
    end
end

function FlexVisitController.Init(rootGui: ScreenGui)
    local panel, body, closeBtn = UITheme.CreateModal("FlexVisitModal", "✨ FLEX YOUR BASE — SERVER SHOWCASE", rootGui, UITheme.Colors.Purple)
    modalPanel = panel
    bodyFrame = body
    closeBtn.MouseButton1Click:Connect(function()
        modalPanel.Visible = false
    end)
    HUDController.RegisterModal("Flex", modalPanel, FlexVisitController.Refresh)
end

return FlexVisitController
