--!strict
-- Live Feed Toasts, 0.01% Global Secret Announcement Banner & THE WORLD IS ENDING Warning Banner

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local Localization = require(Shared.Localization)

local UITheme = require(script.Parent.UITheme)
local SoundController = require(script.Parent.SoundController)

local NotificationController = {}
NotificationController._feedFrame = nil :: Frame?
NotificationController._secretBanner = nil :: Frame?
NotificationController._worldBanner = nil :: Frame?
NotificationController._langGetter = function(): Localization.LanguageCode
    return "en"
end

function NotificationController.SetLanguageGetter(fn: () -> Localization.LanguageCode)
    NotificationController._langGetter = fn
end

function NotificationController.PushToast(text: string, accentColor: Color3?)
    local feed = NotificationController._feedFrame
    if not feed then
        return
    end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 34)
    toast.BackgroundColor3 = UITheme.Colors.BgDark
    toast.BackgroundTransparency = 0.14
    toast.BorderSizePixel = 0
    UITheme.AddCorner(toast, 8)
    UITheme.AddStroke(toast, accentColor or UITheme.Colors.Cyan, 1.5)
    toast.Parent = feed

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -14, 1, 0)
    lbl.Position = UDim2.fromOffset(7, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.TextColor3 = UITheme.Colors.TextMain
    lbl.Text = text
    lbl.Parent = toast

    task.delay(4.5, function()
        if toast.Parent then
            local t = TweenService:Create(toast, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
            t:Play()
            t.Completed:Wait()
            toast:Destroy()
        end
    end)
end

function NotificationController.ShowGlobalSecretBanner(payload: any)
    local banner = NotificationController._secretBanner
    if not banner then
        return
    end
    local lang = NotificationController._langGetter()
    local titleLbl = banner:FindFirstChild("Title") :: TextLabel?
    local msgLbl = banner:FindFirstChild("Msg") :: TextLabel?
    if titleLbl then
        titleLbl.Text = "✨ " .. Localization.Get("SECRET_BANNER_TITLE", lang) .. " ✨"
    end
    local itemName = if lang == "tr" and payload.ItemNameTR then payload.ItemNameTR else payload.ItemName
    if msgLbl then
        msgLbl.Text = string.format("%s  %s  →  %s", tostring(payload.Icon or "💎"), tostring(payload.PlayerName), tostring(itemName))
    end

    banner.Visible = true
    SoundController.Play("Secret")
    task.delay(7.0, function()
        if banner then
            banner.Visible = false
        end
    end)
end

function NotificationController.ShowWorldEndingBanner(active: boolean, eventType: string?)
    local wb = NotificationController._worldBanner
    if not wb then
        return
    end
    if not active then
        wb.Visible = false
        return
    end
    local lang = NotificationController._langGetter()
    local evKey = if eventType == "MeteorShower"
        then "EVENT_METEOR"
        elseif eventType == "GiantMonster" then "EVENT_MONSTER"
        else "EVENT_GRAVITY"
    local lbl = wb:FindFirstChild("Msg") :: TextLabel?
    if lbl then
        lbl.Text = "⚠️ " .. Localization.Get("WORLD_END_ACTIVE", lang) .. " — " .. Localization.Get(evKey, lang) .. " ⚠️"
    end
    wb.Visible = true
    SoundController.Play("Apocalypse")
end

function NotificationController.Init(rootGui: ScreenGui)
    -- Right-side live feed stack
    local feed = Instance.new("Frame")
    feed.Name = "LiveFeedStack"
    feed.Size = UDim2.new(0, 320, 0, 210)
    feed.Position = UDim2.new(1, -334, 0, 86)
    feed.BackgroundTransparency = 1
    feed.Parent = rootGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = feed
    NotificationController._feedFrame = feed

    -- Dramatic Global Secret Announcement Banner
    local secret = Instance.new("Frame")
    secret.Name = "GlobalSecretBanner"
    secret.Size = UDim2.new(0.64, 0, 0, 84)
    secret.Position = UDim2.fromScale(0.18, 0.14)
    secret.BackgroundColor3 = Color3.fromRGB(14, 20, 34)
    secret.Visible = false
    secret.ZIndex = 45
    UITheme.AddCorner(secret, 14)
    UITheme.AddStroke(secret, UITheme.Colors.Gold, 3)
    secret.Parent = rootGui

    local sTitle = Instance.new("TextLabel")
    sTitle.Name = "Title"
    sTitle.Size = UDim2.new(1, -20, 0, 32)
    sTitle.Position = UDim2.fromOffset(10, 6)
    sTitle.BackgroundTransparency = 1
    sTitle.Font = Enum.Font.GothamBlack
    sTitle.TextScaled = true
    sTitle.TextColor3 = UITheme.Colors.Gold
    sTitle.ZIndex = 46
    sTitle.Parent = secret

    local sMsg = Instance.new("TextLabel")
    sMsg.Name = "Msg"
    sMsg.Size = UDim2.new(1, -20, 0, 38)
    sMsg.Position = UDim2.fromOffset(10, 40)
    sMsg.BackgroundTransparency = 1
    sMsg.Font = Enum.Font.GothamBlack
    sMsg.TextScaled = true
    sMsg.TextColor3 = UITheme.Colors.Cyan
    sMsg.ZIndex = 46
    sMsg.Parent = secret
    NotificationController._secretBanner = secret

    -- THE WORLD IS ENDING Warning Banner
    local worldBanner = Instance.new("Frame")
    worldBanner.Name = "WorldEndingBanner"
    worldBanner.Size = UDim2.new(0.54, 0, 0, 44)
    worldBanner.Position = UDim2.fromScale(0.23, 0.085)
    worldBanner.BackgroundColor3 = Color3.fromRGB(85, 12, 22)
    worldBanner.Visible = false
    worldBanner.ZIndex = 40
    UITheme.AddCorner(worldBanner, 10)
    UITheme.AddStroke(worldBanner, UITheme.Colors.Red, 2.2)
    worldBanner.Parent = rootGui

    local wMsg = Instance.new("TextLabel")
    wMsg.Name = "Msg"
    wMsg.Size = UDim2.new(1, -16, 1, 0)
    wMsg.Position = UDim2.fromOffset(8, 0)
    wMsg.BackgroundTransparency = 1
    wMsg.Font = Enum.Font.GothamBlack
    wMsg.TextScaled = true
    wMsg.TextColor3 = Color3.fromRGB(255, 235, 235)
    wMsg.ZIndex = 41
    wMsg.Parent = worldBanner
    NotificationController._worldBanner = worldBanner

    -- Listen to server broadcasts
    Remotes.GetEvent("GlobalSecretAnnouncement").OnClientEvent:Connect(function(payload)
        NotificationController.ShowGlobalSecretBanner(payload)
    end)

    Remotes.GetEvent("WorldEndingFX").OnClientEvent:Connect(function(payload)
        NotificationController.ShowWorldEndingBanner(payload.Active == true, payload.EventType)
    end)

    Remotes.GetEvent("FeedAnnouncement").OnClientEvent:Connect(function(ev)
        if type(ev) ~= "table" then
            return
        end
        local lang = NotificationController._langGetter()
        if ev.Type == "ItemStolenFromPlayer" then
            local iName = if lang == "tr" and ev.ItemNameTR then ev.ItemNameTR else ev.ItemName
            NotificationController.PushToast(string.format("%s %s STOLE %s from %s!", tostring(ev.Icon or "⚡"), ev.ThiefName, iName, ev.VictimName), UITheme.Colors.Red)
            SoundController.Play("Steal")
        elseif ev.Type == "ItemExtracted" then
            local iName = if lang == "tr" and ev.ItemNameTR then ev.ItemNameTR else ev.ItemName
            NotificationController.PushToast(string.format("%s %s secured %s!", tostring(ev.Icon or "✅"), ev.PlayerName, iName), UITheme.Colors.Green)
            SoundController.Play("Extract")
        elseif ev.Type == "HighRarityPickedUp" then
            local iName = if lang == "tr" and ev.ItemNameTR then ev.ItemNameTR else ev.ItemName
            NotificationController.PushToast(string.format("%s %s grabbed [%s] %s! CHASE THEM!", tostring(ev.Icon or "🔥"), ev.PlayerName, ev.Rarity, iName), UITheme.Colors.Gold)
            SoundController.Play("Pickup")
        elseif ev.Type == "SpecialRiftOpened" then
            local tName = if lang == "tr" and ev.ThemeNameTR then ev.ThemeNameTR else ev.ThemeName
            NotificationController.PushToast("🌀 15M SPECIAL RIFT OPEN: " .. tostring(tName) .. "!", UITheme.Colors.Cyan)
        elseif ev.Type == "HeistBreached" then
            NotificationController.PushToast(string.format("💰 BIG HEIST! %s & %s breached the Vault!", tostring(ev.PlayerA), tostring(ev.PlayerB)), UITheme.Colors.Gold)
        elseif ev.Type == "EggHatched" then
            local cName = if lang == "tr" and ev.CreatureNameTR then ev.CreatureNameTR else ev.CreatureName
            NotificationController.PushToast(string.format("%s %s hatched %s (%.2fx)!", tostring(ev.Icon or "🌌"), ev.PlayerName, cName, ev.Multiplier or 1), UITheme.Colors.Purple)
        elseif ev.Type == "BaseLiked" then
            NotificationController.PushToast(string.format("❤️ %s liked your Base! (+$%d)", tostring(ev.VisitorName), ev.Reward or 75), UITheme.Colors.Purple)
        elseif ev.Type == "BaseUpgrade" then
            NotificationController.PushToast(string.format("🏛️ %s upgraded Base to Tier %d!", tostring(ev.PlayerName), ev.Tier or 2), UITheme.Colors.Cyan)
        elseif ev.Type == "BaseRaided" then
            NotificationController.PushToast(string.format("🏴‍☠️ %s raided $%d from %s's Safe!", tostring(ev.RaiderName), ev.Amount or 0, tostring(ev.VictimName)), UITheme.Colors.Red)
        elseif ev.Type == "PlayerRebirth" then
            NotificationController.PushToast(string.format("⚡ %s ASCENDED to Rebirth %d!", tostring(ev.PlayerName), ev.Rebirths or 1), UITheme.Colors.Gold)
        end
    end)

    Remotes.GetEvent("ActionFeedback").OnClientEvent:Connect(function(res)
        if type(res) == "table" and res.Message then
            local color = if res.Success then UITheme.Colors.Green else UITheme.Colors.Red
            NotificationController.PushToast(tostring(res.Message), color)
            if res.Success then
                SoundController.Play("Extract")
            end
        end
    end)
end

return NotificationController
