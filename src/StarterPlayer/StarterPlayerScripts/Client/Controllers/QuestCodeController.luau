--!strict
-- Daily Quests, Promo Code Terminal, Black-Market Merchant & Rebirth Ascension Modal UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local QuestAndCodeConfig = require(Shared.QuestAndCodeConfig)
local Remotes = require(Shared.Remotes)
local Localization = require(Shared.Localization)
local Utils = require(Shared.Utils)

local UITheme = require(script.Parent.UITheme)
local HUDController = require(script.Parent.HUDController)

local QuestCodeController = {}
local modalPanel: Frame
local bodyFrame: ScrollingFrame
local codeInputText = ""

local function clearChildren(parent: Instance)
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end
end

local function makeSectionHeader(text: string, color: Color3, order: number)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 26)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = color
    lbl.Text = text
    lbl.LayoutOrder = order
    lbl.Parent = bodyFrame
end

function QuestCodeController.Refresh()
    if not bodyFrame then
        return
    end
    clearChildren(bodyFrame)

    local profile = HUDController.CurrentProfile
    local lang = HUDController.GetLanguage()
    if not profile then
        return
    end

    local order = 0
    local function nextOrder(): number
        order += 1
        return order
    end

    -- 1. PROMO CODE TERMINAL
    makeSectionHeader("🎟️ " .. Localization.Get("REDEEM_CODE", lang), UITheme.Colors.Gold, nextOrder())

    local codeCard = Instance.new("Frame")
    codeCard.Size = UDim2.new(1, -10, 0, 60)
    codeCard.BackgroundColor3 = UITheme.Colors.BgCard
    codeCard.LayoutOrder = nextOrder()
    UITheme.AddCorner(codeCard, 10)
    UITheme.AddStroke(codeCard, UITheme.Colors.Gold, 1.4)
    codeCard.Parent = bodyFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.66, -16, 0, 38)
    box.Position = UDim2.fromOffset(12, 11)
    box.BackgroundColor3 = UITheme.Colors.BgDark
    box.Font = Enum.Font.GothamBold
    box.TextSize = 15
    box.TextColor3 = UITheme.Colors.TextMain
    box.PlaceholderText = "IMPOSSIBLE / FROZENSUN / SECRET001..."
    box.Text = codeInputText
    box.ClearTextOnFocus = false
    UITheme.AddCorner(box, 8)
    box.Parent = codeCard
    box:GetPropertyChangedSignal("Text"):Connect(function()
        codeInputText = box.Text
    end)

    local redeemBtn = UITheme.MakeButton({
        Text = Localization.Get("REDEEM_CODE", lang),
        Size = UDim2.new(0.32, -8, 0, 38),
        Position = UDim2.new(0.68, 0, 0, 11),
        Color = UITheme.Colors.Gold,
        TextColor = Color3.fromRGB(14, 18, 28),
        Parent = codeCard,
        FontSize = 13,
    })
    redeemBtn.MouseButton1Click:Connect(function()
        if #box.Text > 0 then
            Remotes.GetEvent("RequestRedeemCode"):FireServer(box.Text)
            codeInputText = ""
            box.Text = ""
        end
    end)

    -- 2. DAILY QUESTS
    makeSectionHeader("🎯 " .. Localization.Get("DAILY_QUESTS", lang), Color3.fromRGB(255, 110, 175), nextOrder())

    for _, q in ipairs(QuestAndCodeConfig.DailyQuests) do
        local prog = (profile.QuestProgress :: any)[q.StatKey] or 0
        local claimed = profile.ClaimedQuests[q.Id] == true
        local ready = (not claimed) and prog >= q.Target

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 58)
        card.BackgroundColor3 = UITheme.Colors.BgCard
        card.LayoutOrder = nextOrder()
        UITheme.AddCorner(card, 10)
        UITheme.AddStroke(card, if claimed then UITheme.Colors.Green elseif ready then UITheme.Colors.Gold else UITheme.Colors.Stroke, 1.3)
        card.Parent = bodyFrame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.65, 0, 0, 26)
        title.Position = UDim2.fromOffset(12, 6)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = UITheme.Colors.TextMain
        title.Text = string.format("%s  (%d/%d)", if lang == "tr" then q.TitleTR else q.Title, math.min(prog, q.Target), q.Target)
        title.Parent = card

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(0.65, 0, 0, 22)
        sub.Position = UDim2.fromOffset(12, 32)
        sub.BackgroundTransparency = 1
        sub.Font = Enum.Font.GothamMedium
        sub.TextSize = 12
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextColor3 = UITheme.Colors.Green
        sub.Text = "Reward: +" .. Utils.FormatCash(q.RewardCash)
        sub.Parent = card

        local claimBtn = UITheme.MakeButton({
            Text = if claimed then Localization.Get("QUEST_CLAIMED", lang) elseif ready then Localization.Get("CLAIM_QUEST", lang) else string.format("%d/%d", prog, q.Target),
            Size = UDim2.fromOffset(145, 36),
            Position = UDim2.new(1, -158, 0, 11),
            Color = if claimed then UITheme.Colors.BgHover elseif ready then UITheme.Colors.Green else UITheme.Colors.BgDark,
            TextColor = if ready then Color3.fromRGB(14, 18, 28) else UITheme.Colors.TextMuted,
            Parent = card,
            FontSize = 12,
        })
        if ready then
            claimBtn.MouseButton1Click:Connect(function()
                Remotes.GetEvent("RequestClaimQuest"):FireServer(q.Id)
            end)
        end
    end

    -- 3. BLACK-MARKET MERCHANT
    makeSectionHeader("🧙 " .. Localization.Get("BLACK_MARKET", lang), UITheme.Colors.Purple, nextOrder())

    for _, item in ipairs(QuestAndCodeConfig.MerchantItems) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 62)
        card.BackgroundColor3 = UITheme.Colors.BgCard
        card.LayoutOrder = nextOrder()
        UITheme.AddCorner(card, 10)
        UITheme.AddStroke(card, UITheme.Colors.Purple, 1.3)
        card.Parent = bodyFrame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.66, 0, 0, 26)
        title.Position = UDim2.fromOffset(12, 6)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = UITheme.Colors.Purple
        title.Text = string.format("%s %s", item.Icon, if lang == "tr" then item.NameTR else item.Name)
        title.Parent = card

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0.66, 0, 0, 24)
        desc.Position = UDim2.fromOffset(12, 32)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.GothamMedium
        desc.TextSize = 12
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextColor3 = UITheme.Colors.TextMuted
        desc.Text = if lang == "tr" then item.DescriptionTR else item.Description
        desc.Parent = card

        local canAfford = profile.Cash >= item.Cost
        local buyBtn = UITheme.MakeButton({
            Text = Utils.FormatCash(item.Cost),
            Size = UDim2.fromOffset(145, 36),
            Position = UDim2.new(1, -158, 0, 13),
            Color = if canAfford then UITheme.Colors.Purple else UITheme.Colors.BgHover,
            Parent = card,
            FontSize = 13,
        })
        buyBtn.MouseButton1Click:Connect(function()
            Remotes.GetEvent("RequestBuyMerchantItem"):FireServer(item.Id)
        end)
    end

    -- 4. REBIRTH / ASCENSION SHRINE
    local rebirths = profile.Rebirths or 0
    local rebirthCost = QuestAndCodeConfig.GetRebirthCost(rebirths)
    makeSectionHeader("⚡ " .. Localization.Get("REBIRTH_TITLE", lang), UITheme.Colors.Cyan, nextOrder())

    local rebCard = Instance.new("Frame")
    rebCard.Size = UDim2.new(1, -10, 0, 92)
    rebCard.BackgroundColor3 = UITheme.Colors.BgCard
    rebCard.LayoutOrder = nextOrder()
    UITheme.AddCorner(rebCard, 10)
    UITheme.AddStroke(rebCard, UITheme.Colors.Cyan, 1.8)
    rebCard.Parent = bodyFrame

    local rTitle = Instance.new("TextLabel")
    rTitle.Size = UDim2.new(0.62, 0, 0, 28)
    rTitle.Position = UDim2.fromOffset(12, 8)
    rTitle.BackgroundTransparency = 1
    rTitle.Font = Enum.Font.GothamBlack
    rTitle.TextSize = 16
    rTitle.TextXAlignment = Enum.TextXAlignment.Left
    rTitle.TextColor3 = UITheme.Colors.Cyan
    rTitle.Text = string.format("⚡ %s: %d  (+%d%% Income, +%d%% Luck)", Localization.Get("REBIRTH_COUNT", lang), rebirths, rebirths * 50, rebirths * 10)
    rTitle.Parent = rebCard

    local rDesc = Instance.new("TextLabel")
    rDesc.Size = UDim2.new(0.62, 0, 0, 48)
    rDesc.Position = UDim2.fromOffset(12, 38)
    rDesc.BackgroundTransparency = 1
    rDesc.Font = Enum.Font.GothamMedium
    rDesc.TextSize = 12
    rDesc.TextWrapped = true
    rDesc.TextXAlignment = Enum.TextXAlignment.Left
    rDesc.TextColor3 = UITheme.Colors.TextMuted
    rDesc.Text = Localization.Get("REBIRTH_DESC", lang)
    rDesc.Parent = rebCard

    local canRebirth = profile.Cash >= rebirthCost
    local rebBtn = UITheme.MakeButton({
        Text = string.format("⚡ %s\n(%s)", Localization.Get("REBIRTH_BUTTON", lang), Utils.FormatCash(rebirthCost)),
        Size = UDim2.fromOffset(180, 62),
        Position = UDim2.new(1, -194, 0, 15),
        Color = if canRebirth then UITheme.Colors.Cyan else UITheme.Colors.BgHover,
        TextColor = if canRebirth then Color3.fromRGB(14, 18, 28) else UITheme.Colors.TextMuted,
        Parent = rebCard,
        FontSize = 13,
    })
    rebBtn.MouseButton1Click:Connect(function()
        Remotes.GetEvent("RequestRebirth"):FireServer()
    end)
end

function QuestCodeController.Init(rootGui: ScreenGui)
    local panel, body, closeBtn = UITheme.CreateModal("QuestCodeModal", "🎯 QUESTS, CODES, MERCHANT & REBIRTH", rootGui, Color3.fromRGB(255, 110, 175))
    modalPanel = panel
    bodyFrame = body
    closeBtn.MouseButton1Click:Connect(function()
        modalPanel.Visible = false
    end)
    HUDController.RegisterModal("Quests", modalPanel, QuestCodeController.Refresh)
end

return QuestCodeController
