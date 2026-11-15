--!strict
-- Squad / Team Party & Co-op Big Heist UI + Squad Invite Popup

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local Localization = require(Shared.Localization)

local UITheme = require(script.Parent.UITheme)
local HUDController = require(script.Parent.HUDController)

local SquadHeistController = {}
local modalPanel: Frame
local bodyFrame: ScrollingFrame
local currentSquad: any = nil
local inviteBanner: Frame
local pendingSquadId: string? = nil

local function clearChildren(parent: Instance)
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end
end

function SquadHeistController.Refresh()
    if not bodyFrame then
        return
    end
    clearChildren(bodyFrame)

    local lang = HUDController.GetLanguage()

    -- Instructions for Big Heist Vault
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -10, 0, 56)
    info.BackgroundColor3 = UITheme.Colors.BgCard
    info.Font = Enum.Font.GothamBold
    info.TextSize = 13
    info.TextWrapped = true
    info.TextColor3 = UITheme.Colors.Gold
    info.Text = "💰 BIG HEIST VAULT: Team up with 2–4 friends, head to the Vault behind Plaza, and stand on BOTH glowing Lock Plates simultaneously to crack the Titan Bank Core!"
    UITheme.AddCorner(info, 8)
    info.LayoutOrder = 1
    info.Parent = bodyFrame

    if not currentSquad then
        local createBtn = UITheme.MakeButton({
            Text = "🤝 " .. Localization.Get("CREATE_SQUAD", lang),
            Size = UDim2.new(1, -10, 0, 44),
            Color = UITheme.Colors.Green,
            TextColor = Color3.fromRGB(14, 18, 28),
            Parent = bodyFrame,
            FontSize = 15,
        })
        createBtn.LayoutOrder = 2
        createBtn.MouseButton1Click:Connect(function()
            Remotes.GetEvent("RequestCreateSquad"):FireServer()
        end)
    else
        local leaveBtn = UITheme.MakeButton({
            Text = Localization.Get("LEAVE_SQUAD", lang),
            Size = UDim2.new(1, -10, 0, 38),
            Color = UITheme.Colors.Red,
            Parent = bodyFrame,
            FontSize = 14,
        })
        leaveBtn.LayoutOrder = 2
        leaveBtn.MouseButton1Click:Connect(function()
            Remotes.GetEvent("RequestLeaveSquad"):FireServer()
        end)

        for idx, member in ipairs(currentSquad.Members or {}) do
            local row = Instance.new("TextLabel")
            row.Size = UDim2.new(1, -10, 0, 34)
            row.BackgroundColor3 = UITheme.Colors.BgCard
            row.Font = Enum.Font.GothamBold
            row.TextSize = 14
            row.TextColor3 = if member.IsLeader then UITheme.Colors.Gold else UITheme.Colors.TextMain
            row.Text = string.format("   %s %s", if member.IsLeader then "👑" else "🛡️", tostring(member.Name))
            row.TextXAlignment = Enum.TextXAlignment.Left
            UITheme.AddCorner(row, 8)
            row.LayoutOrder = 10 + idx
            row.Parent = bodyFrame
        end
    end

    -- Online players list to invite
    local order = 30
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -10, 0, 46)
            row.BackgroundColor3 = UITheme.Colors.BgCard
            UITheme.AddCorner(row, 8)
            row.LayoutOrder = order
            order += 1
            row.Parent = bodyFrame

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(0.65, 0, 1, 0)
            nameLbl.Position = UDim2.fromOffset(12, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 14
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextColor3 = UITheme.Colors.TextMain
            nameLbl.Text = plr.Name
            nameLbl.Parent = row

            local invBtn = UITheme.MakeButton({
                Text = Localization.Get("INVITE", lang),
                Size = UDim2.fromOffset(110, 32),
                Position = UDim2.new(1, -122, 0, 7),
                Color = UITheme.Colors.Cyan,
                TextColor = Color3.fromRGB(14, 18, 28),
                Parent = row,
                FontSize = 13,
            })
            invBtn.MouseButton1Click:Connect(function()
                Remotes.GetEvent("RequestInviteSquad"):FireServer(plr.UserId)
            end)
        end
    end
end

function SquadHeistController.Init(rootGui: ScreenGui)
    local panel, body, closeBtn = UITheme.CreateModal("SquadHeistModal", "🤝 SQUAD & CO-OP BIG HEIST", rootGui, Color3.fromRGB(255, 145, 55))
    modalPanel = panel
    bodyFrame = body
    closeBtn.MouseButton1Click:Connect(function()
        modalPanel.Visible = false
    end)
    HUDController.RegisterModal("Squad", modalPanel, SquadHeistController.Refresh)

    -- Incoming Squad Invite Popup
    inviteBanner = Instance.new("Frame")
    inviteBanner.Name = "SquadInvitePopup"
    inviteBanner.Size = UDim2.fromOffset(310, 88)
    inviteBanner.Position = UDim2.new(0.5, -155, 0, 74)
    inviteBanner.BackgroundColor3 = UITheme.Colors.BgDark
    inviteBanner.Visible = false
    inviteBanner.ZIndex = 35
    UITheme.AddCorner(inviteBanner, 12)
    UITheme.AddStroke(inviteBanner, UITheme.Colors.Green, 2)
    inviteBanner.Parent = rootGui

    local invTitle = Instance.new("TextLabel")
    invTitle.Name = "Title"
    invTitle.Size = UDim2.new(1, -16, 0, 34)
    invTitle.Position = UDim2.fromOffset(8, 6)
    invTitle.BackgroundTransparency = 1
    invTitle.Font = Enum.Font.GothamBold
    invTitle.TextSize = 14
    invTitle.TextColor3 = UITheme.Colors.TextMain
    invTitle.ZIndex = 36
    invTitle.Parent = inviteBanner

    local accBtn = UITheme.MakeButton({
        Text = "✓ Accept",
        Size = UDim2.fromOffset(130, 34),
        Position = UDim2.fromOffset(14, 46),
        Color = UITheme.Colors.Green,
        TextColor = Color3.fromRGB(14, 18, 28),
        Parent = inviteBanner,
        FontSize = 13,
    })
    accBtn.ZIndex = 36
    accBtn.MouseButton1Click:Connect(function()
        if pendingSquadId then
            Remotes.GetEvent("RequestAcceptSquad"):FireServer(pendingSquadId)
        end
        inviteBanner.Visible = false
    end)

    local decBtn = UITheme.MakeButton({
        Text = "✕ Decline",
        Size = UDim2.fromOffset(130, 34),
        Position = UDim2.fromOffset(162, 46),
        Color = UITheme.Colors.Red,
        Parent = inviteBanner,
        FontSize = 13,
    })
    decBtn.ZIndex = 36
    decBtn.MouseButton1Click:Connect(function()
        inviteBanner.Visible = false
    end)

    Remotes.GetEvent("SquadStateSync").OnClientEvent:Connect(function(sq)
        currentSquad = sq
        if modalPanel.Visible then
            SquadHeistController.Refresh()
        end
    end)

    Remotes.GetEvent("SquadInvitePrompt").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then
            return
        end
        pendingSquadId = payload.SquadId
        invTitle.Text = string.format("🤝 %s invited you to Squad!", tostring(payload.LeaderName))
        inviteBanner.Visible = true
    end)
end

return SquadHeistController
