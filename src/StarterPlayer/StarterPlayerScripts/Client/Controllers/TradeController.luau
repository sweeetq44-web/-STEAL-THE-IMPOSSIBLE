--!strict
-- Atomic P2P Safe Trading UI Controller

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local ItemCatalog = require(Shared.ItemCatalog)
local MutationConfig = require(Shared.MutationConfig)
local Remotes = require(Shared.Remotes)
local Localization = require(Shared.Localization)
local Utils = require(Shared.Utils)

local UITheme = require(script.Parent.UITheme)
local HUDController = require(script.Parent.HUDController)

local TradeController = {}
local modalPanel: Frame
local bodyFrame: ScrollingFrame
local currentTrade: any = nil
local pendingInvite: { FromUserId: number, FromName: string }? = nil
local selectedUids: { [string]: boolean } = {}
local offerCashValue = 0

local function clearChildren(parent: Instance)
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end
end

local function pushOfferUpdate()
    local list: { string } = {}
    for uid, on in pairs(selectedUids) do
        if on then
            table.insert(list, uid)
        end
    end
    Remotes.GetEvent("RequestUpdateTradeOffer"):FireServer(list, offerCashValue)
end

function TradeController.Refresh()
    if not bodyFrame then
        return
    end
    clearChildren(bodyFrame)

    local lang = HUDController.GetLanguage()
    local profile = HUDController.CurrentProfile
    local localUserId = Players.LocalPlayer.UserId

    -- Pending incoming invite banner inside Trade modal
    if pendingInvite and not currentTrade then
        local invCard = Instance.new("Frame")
        invCard.Size = UDim2.new(1, -10, 0, 62)
        invCard.BackgroundColor3 = UITheme.Colors.BgCard
        UITheme.AddCorner(invCard, 10)
        UITheme.AddStroke(invCard, UITheme.Colors.Gold, 1.8)
        invCard.Parent = bodyFrame

        local invLbl = Instance.new("TextLabel")
        invLbl.Size = UDim2.new(0.58, 0, 1, 0)
        invLbl.Position = UDim2.fromOffset(12, 0)
        invLbl.BackgroundTransparency = 1
        invLbl.Font = Enum.Font.GothamBlack
        invLbl.TextSize = 14
        invLbl.TextXAlignment = Enum.TextXAlignment.Left
        invLbl.TextColor3 = UITheme.Colors.Gold
        invLbl.Text = string.format("🤝 %s invited you to Trade!", pendingInvite.FromName)
        invLbl.Parent = invCard

        local fromId = pendingInvite.FromUserId
        local accBtn = UITheme.MakeButton({
            Text = "Accept",
            Size = UDim2.fromOffset(105, 36),
            Position = UDim2.new(1, -222, 0, 13),
            Color = UITheme.Colors.Green,
            TextColor = Color3.fromRGB(14, 18, 28),
            Parent = invCard,
            FontSize = 13,
        })
        accBtn.MouseButton1Click:Connect(function()
            pendingInvite = nil
            Remotes.GetEvent("RequestRespondTrade"):FireServer(fromId, true)
        end)

        local decBtn = UITheme.MakeButton({
            Text = "Decline",
            Size = UDim2.fromOffset(100, 36),
            Position = UDim2.new(1, -112, 0, 13),
            Color = UITheme.Colors.Red,
            Parent = invCard,
            FontSize = 13,
        })
        decBtn.MouseButton1Click:Connect(function()
            pendingInvite = nil
            Remotes.GetEvent("RequestRespondTrade"):FireServer(fromId, false)
            TradeController.Refresh()
        end)
    end

    if not currentTrade then
        -- Player Picker to send Trade Requests
        local hint = Instance.new("TextLabel")
        hint.Size = UDim2.new(1, -10, 0, 28)
        hint.BackgroundTransparency = 1
        hint.Font = Enum.Font.GothamBold
        hint.TextSize = 14
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.TextColor3 = UITheme.Colors.Cyan
        hint.Text = "🤝 " .. Localization.Get("SEND_TRADE", lang)
        hint.Parent = bodyFrame

        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId ~= localUserId then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -10, 0, 52)
                row.BackgroundColor3 = UITheme.Colors.BgCard
                UITheme.AddCorner(row, 10)
                UITheme.AddStroke(row, UITheme.Colors.Stroke, 1.2)
                row.Parent = bodyFrame

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(0.65, 0, 1, 0)
                nameLbl.Position = UDim2.fromOffset(12, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Font = Enum.Font.GothamBlack
                nameLbl.TextSize = 15
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextColor3 = UITheme.Colors.TextMain
                nameLbl.Text = "👤 " .. p.DisplayName .. " (@" .. p.Name .. ")"
                nameLbl.Parent = row

                local sendBtn = UITheme.MakeButton({
                    Text = Localization.Get("SEND_TRADE", lang),
                    Size = UDim2.fromOffset(150, 34),
                    Position = UDim2.new(1, -162, 0, 9),
                    Color = UITheme.Colors.Cyan,
                    TextColor = Color3.fromRGB(14, 18, 28),
                    Parent = row,
                    FontSize = 12,
                })
                sendBtn.MouseButton1Click:Connect(function()
                    Remotes.GetEvent("RequestSendTrade"):FireServer(p.UserId)
                end)
            end
        end
        return
    end

    -- ACTIVE TRADE VIEW
    local mySide = if currentTrade.SideA.UserId == localUserId then currentTrade.SideA else currentTrade.SideB
    local partnerSide = if currentTrade.SideA.UserId == localUserId then currentTrade.SideB else currentTrade.SideA

    local summaryCard = Instance.new("Frame")
    summaryCard.Size = UDim2.new(1, -10, 0, 130)
    summaryCard.BackgroundColor3 = UITheme.Colors.BgCard
    UITheme.AddCorner(summaryCard, 10)
    UITheme.AddStroke(summaryCard, UITheme.Colors.Cyan, 1.6)
    summaryCard.Parent = bodyFrame

    local partnerItemsText = {}
    for _, it in ipairs(partnerSide.Items or {}) do
        local def = ItemCatalog.Get(it.ItemId)
        local mut = MutationConfig.Get(it.Mutation)
        if def then
            table.insert(partnerItemsText, string.format("%s [%s] %s", def.Icon, mut.Prefix, def.Name))
        end
    end

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0.65, 0, 0, 114)
    statusLbl.Position = UDim2.fromOffset(12, 8)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Font = Enum.Font.GothamBold
    statusLbl.TextSize = 13
    statusLbl.TextWrapped = true
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextYAlignment = Enum.TextYAlignment.Top
    statusLbl.TextColor3 = UITheme.Colors.TextMain
    statusLbl.Text = string.format(
        "YOU (%s): %d items + %s\nPARTNER %s (%s): %d items + %s\nPartner Offers: %s",
        if mySide.Confirmed then "✅ READY" else "EDITING",
        #(mySide.ItemUids or mySide.Items or {}),
        Utils.FormatCash(mySide.Cash or 0),
        partnerSide.PlayerName,
        if partnerSide.Confirmed then "✅ READY" else "EDITING",
        #(partnerSide.Items or {}),
        Utils.FormatCash(partnerSide.Cash or 0),
        if #partnerItemsText > 0 then table.concat(partnerItemsText, ", ") else "None"
    )
    statusLbl.Parent = summaryCard

    local confBtn = UITheme.MakeButton({
        Text = if mySide.Confirmed then "✅ CONFIRMED" else ("🤝 " .. Localization.Get("TRADE_CONFIRM", lang)),
        Size = UDim2.fromOffset(180, 40),
        Position = UDim2.new(1, -194, 0, 14),
        Color = if mySide.Confirmed then UITheme.Colors.Green else UITheme.Colors.Gold,
        TextColor = Color3.fromRGB(14, 18, 28),
        Parent = summaryCard,
        FontSize = 13,
    })
    confBtn.MouseButton1Click:Connect(function()
        Remotes.GetEvent("RequestConfirmTrade"):FireServer()
    end)

    local cancelBtn = UITheme.MakeButton({
        Text = "❌ Cancel Trade",
        Size = UDim2.fromOffset(180, 36),
        Position = UDim2.new(1, -194, 0, 66),
        Color = UITheme.Colors.Red,
        Parent = summaryCard,
        FontSize = 12,
    })
    cancelBtn.MouseButton1Click:Connect(function()
        Remotes.GetEvent("RequestCancelTrade"):FireServer()
    end)

    -- Cash Offer Quick Controls
    local cashBar = Instance.new("Frame")
    cashBar.Size = UDim2.new(1, -10, 0, 48)
    cashBar.BackgroundColor3 = UITheme.Colors.BgCard
    UITheme.AddCorner(cashBar, 8)
    cashBar.Parent = bodyFrame

    local cashLbl = Instance.new("TextLabel")
    cashLbl.Size = UDim2.new(0.42, 0, 1, 0)
    cashLbl.Position = UDim2.fromOffset(12, 0)
    cashLbl.BackgroundTransparency = 1
    cashLbl.Font = Enum.Font.GothamBold
    cashLbl.TextSize = 14
    cashLbl.TextXAlignment = Enum.TextXAlignment.Left
    cashLbl.TextColor3 = UITheme.Colors.Gold
    cashLbl.Text = "Offer Cash: " .. Utils.FormatCash(offerCashValue)
    cashLbl.Parent = cashBar

    local cashAmounts = { 500, 2500, 10000 }
    for i, amt in ipairs(cashAmounts) do
        local b = UITheme.MakeButton({
            Text = "+" .. Utils.FormatCash(amt),
            Size = UDim2.fromOffset(88, 32),
            Position = UDim2.new(0.45 + (i - 1) * 0.14, 0, 0, 8),
            Color = UITheme.Colors.BgHover,
            Parent = cashBar,
            FontSize = 12,
        })
        b.MouseButton1Click:Connect(function()
            local maxCash = if profile then profile.Cash else 0
            offerCashValue = math.min(maxCash, offerCashValue + amt)
            pushOfferUpdate()
        end)
    end
    local clrCashBtn = UITheme.MakeButton({
        Text = "Reset $0",
        Size = UDim2.fromOffset(82, 32),
        Position = UDim2.new(0.87, 0, 0, 8),
        Color = UITheme.Colors.Red,
        Parent = cashBar,
        FontSize = 11,
    })
    clrCashBtn.MouseButton1Click:Connect(function()
        offerCashValue = 0
        pushOfferUpdate()
    end)

    -- My Vault Items to toggle into Trade
    if profile then
        for _, inst in ipairs(profile.VaultItems) do
            local def = ItemCatalog.Get(inst.ItemId)
            if def then
                local mut = MutationConfig.Get(inst.Mutation)
                local selected = selectedUids[inst.Uid] == true
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -10, 0, 48)
                row.BackgroundColor3 = UITheme.Colors.BgCard
                UITheme.AddCorner(row, 8)
                UITheme.AddStroke(row, if selected then UITheme.Colors.Green else mut.Color, 1.2)
                row.Parent = bodyFrame

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.68, 0, 1, 0)
                lbl.Position = UDim2.fromOffset(10, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 13
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextColor3 = UITheme.Colors.TextMain
                lbl.Text = string.format("%s [%s] %s", def.Icon, mut.Prefix, def.Name)
                lbl.Parent = row

                local togBtn = UITheme.MakeButton({
                    Text = if selected then "✓ OFFERING" else "+ ADD TO TRADE",
                    Size = UDim2.fromOffset(145, 32),
                    Position = UDim2.new(1, -156, 0, 8),
                    Color = if selected then UITheme.Colors.Green else UITheme.Colors.BgHover,
                    TextColor = if selected then Color3.fromRGB(14, 18, 28) else UITheme.Colors.TextMain,
                    Parent = row,
                    FontSize = 12,
                })
                togBtn.MouseButton1Click:Connect(function()
                    selectedUids[inst.Uid] = not selected
                    pushOfferUpdate()
                end)
            end
        end
    end
end

function TradeController.Init(rootGui: ScreenGui)
    local panel, body, closeBtn = UITheme.CreateModal("TradeModal", "🤝 SAFE PLAYER TRADING", rootGui, Color3.fromRGB(95, 220, 180))
    modalPanel = panel
    bodyFrame = body
    closeBtn.MouseButton1Click:Connect(function()
        modalPanel.Visible = false
    end)
    HUDController.RegisterModal("Trade", modalPanel, TradeController.Refresh)

    Remotes.GetEvent("TradeInvitePrompt").OnClientEvent:Connect(function(info)
        if type(info) == "table" then
            pendingInvite = info
            if modalPanel.Visible then
                TradeController.Refresh()
            end
        end
    end)

    Remotes.GetEvent("TradeStateSync").OnClientEvent:Connect(function(trade)
        currentTrade = trade
        if not trade then
            selectedUids = {}
            offerCashValue = 0
        end
        if modalPanel.Visible then
            TradeController.Refresh()
        end
    end)
end

return TradeController
