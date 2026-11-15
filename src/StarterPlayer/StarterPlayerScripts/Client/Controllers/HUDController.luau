--!strict
-- Primary Top HUD, Timers (15m Rift + 30m Apocalypse), Carry Banner, Bottom Navigation & Studio Test Panel

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local BaseConfig = require(Shared.BaseConfig)
local MutationConfig = require(Shared.MutationConfig)
local Remotes = require(Shared.Remotes)
local Localization = require(Shared.Localization)
local Utils = require(Shared.Utils)

local UITheme = require(script.Parent.UITheme)
local SoundController = require(script.Parent.SoundController)

local HUDController = {}
HUDController._modals = {} :: { [string]: Frame }
HUDController._refreshHandlers = {} :: { [string]: () -> () }
HUDController._onLanguageChanged = {} :: { (Localization.LanguageCode) -> () }
HUDController.CurrentProfile = nil :: Types.PlayerProfile?
HUDController.CurrentNetWorth = 0
HUDController.CurrentIncomePerSec = 0
HUDController.CurrentBaseSlot = 1
HUDController.CurrentShieldRemaining = 0

local cashLbl: TextLabel
local incomeLbl: TextLabel
local worthLbl: TextLabel
local buffStripLbl: TextLabel
local riftTimerLbl: TextLabel
local worldTimerLbl: TextLabel
local carryBanner: Frame
local carryLabel: TextLabel
local carryCompassLbl: TextLabel
local langBtn: TextButton
local dockButtons: { [string]: { Btn: TextButton, Key: string } } = {}
local isCarryingNow = false
local carryingTitle = ""

function HUDController.GetLanguage(): Localization.LanguageCode
    if HUDController.CurrentProfile and HUDController.CurrentProfile.PreferredLanguage == "tr" then
        return "tr"
    end
    return "en"
end

function HUDController.RegisterModal(id: string, frame: Frame, onOpen: (() -> ())?)
    HUDController._modals[id] = frame
    if onOpen then
        HUDController._refreshHandlers[id] = onOpen
    end
end

function HUDController.ToggleModal(id: string)
    local target = HUDController._modals[id]
    if not target then
        return
    end
    local willOpen = not target.Visible
    for modalId, frame in pairs(HUDController._modals) do
        frame.Visible = (modalId == id and willOpen)
    end
    SoundController.Play("Click")
    if willOpen and HUDController._refreshHandlers[id] then
        HUDController._refreshHandlers[id]()
    end
end

function HUDController.CloseAllModals()
    for _, frame in pairs(HUDController._modals) do
        frame.Visible = false
    end
end

function HUDController.OnLanguageChange(cb: (Localization.LanguageCode) -> ())
    table.insert(HUDController._onLanguageChanged, cb)
end

local function refreshLabels()
    local lang = HUDController.GetLanguage()
    local p = HUDController.CurrentProfile
    if p then
        cashLbl.Text = string.format("💵 %s", Utils.FormatCash(p.Cash))
        incomeLbl.Text = string.format("+%s%s", Utils.FormatCash(HUDController.CurrentIncomePerSec), Localization.Get("INCOME_PER_SEC", lang))
        worthLbl.Text = string.format(
            "👑 %s: %s   |   ⚡ %s: %d",
            Localization.Get("NET_WORTH", lang),
            Utils.FormatCash(HUDController.CurrentNetWorth),
            Localization.Get("REBIRTH_COUNT", lang),
            p.Rebirths or 0
        )

        local buffs: { string } = {}
        local now = os.time()
        if (p.ActiveBuffs.LuckUntil or 0) > now then
            table.insert(buffs, string.format("🍀 2x Luck %s", Utils.FormatTime(p.ActiveBuffs.LuckUntil - now)))
        end
        if (p.ActiveBuffs.FeatherUntil or 0) > now then
            table.insert(buffs, string.format("🪶 Feather %s", Utils.FormatTime(p.ActiveBuffs.FeatherUntil - now)))
        end
        if (p.ActiveBuffs.ShadowCloakUntil or 0) > now then
            table.insert(buffs, string.format("🥷 Cloak %s", Utils.FormatTime(p.ActiveBuffs.ShadowCloakUntil - now)))
        end
        if HUDController.CurrentShieldRemaining > 0 then
            table.insert(buffs, string.format("🛡️ %ds", HUDController.CurrentShieldRemaining))
        end
        if p.HighStakesMode then
            table.insert(buffs, "🔥 2X SAFE RISK")
        end
        buffStripLbl.Text = if #buffs > 0 then table.concat(buffs, "  •  ") else ""
        buffStripLbl.Visible = #buffs > 0
    end
    langBtn.Text = if lang == "tr" then "🌐 TR" else "🌐 EN"

    for _, info in pairs(dockButtons) do
        info.Btn.Text = Localization.Get(info.Key, lang)
    end
end

function HUDController.ApplyState(payload: any)
    if type(payload) ~= "table" then
        return
    end
    if payload.Profile then
        HUDController.CurrentProfile = payload.Profile
    end
    if payload.NetWorth ~= nil then
        HUDController.CurrentNetWorth = payload.NetWorth
    end
    if payload.IncomePerSec ~= nil then
        HUDController.CurrentIncomePerSec = payload.IncomePerSec
    end
    if payload.BaseSlot ~= nil then
        HUDController.CurrentBaseSlot = payload.BaseSlot
    end
    if payload.ShieldRemaining ~= nil then
        HUDController.CurrentShieldRemaining = payload.ShieldRemaining
    end
    refreshLabels()

    for _, frame in pairs(HUDController._modals) do
        if frame.Visible then
            for id, f in pairs(HUDController._modals) do
                if f == frame and HUDController._refreshHandlers[id] then
                    HUDController._refreshHandlers[id]()
                end
            end
        end
    end
end

function HUDController.Init(rootGui: ScreenGui)
    -- Top Left Stats Pill
    local statsBar = Instance.new("Frame")
    statsBar.Name = "StatsBar"
    statsBar.Size = UDim2.new(0, 440, 0, 58)
    statsBar.Position = UDim2.fromOffset(14, 12)
    statsBar.BackgroundColor3 = UITheme.Colors.BgDark
    statsBar.BackgroundTransparency = 0.08
    statsBar.BorderSizePixel = 0
    UITheme.AddCorner(statsBar, 12)
    UITheme.AddStroke(statsBar, UITheme.Colors.Cyan, 1.6)
    statsBar.Parent = rootGui

    cashLbl = Instance.new("TextLabel")
    cashLbl.Size = UDim2.new(0.45, 0, 0.56, 0)
    cashLbl.Position = UDim2.fromOffset(12, 4)
    cashLbl.BackgroundTransparency = 1
    cashLbl.Font = Enum.Font.GothamBlack
    cashLbl.TextSize = 20
    cashLbl.TextXAlignment = Enum.TextXAlignment.Left
    cashLbl.TextColor3 = UITheme.Colors.Green
    cashLbl.Text = "💵 $250"
    cashLbl.Parent = statsBar

    incomeLbl = Instance.new("TextLabel")
    incomeLbl.Size = UDim2.new(0.48, 0, 0.45, 0)
    incomeLbl.Position = UDim2.new(0.48, 0, 0.08, 0)
    incomeLbl.BackgroundTransparency = 1
    incomeLbl.Font = Enum.Font.GothamBold
    incomeLbl.TextSize = 14
    incomeLbl.TextXAlignment = Enum.TextXAlignment.Right
    incomeLbl.TextColor3 = UITheme.Colors.Cyan
    incomeLbl.Text = "+$0/sec"
    incomeLbl.Parent = statsBar

    worthLbl = Instance.new("TextLabel")
    worthLbl.Size = UDim2.new(1, -24, 0.4, 0)
    worthLbl.Position = UDim2.fromOffset(12, 33)
    worthLbl.BackgroundTransparency = 1
    worthLbl.Font = Enum.Font.GothamBold
    worthLbl.TextSize = 13
    worthLbl.TextXAlignment = Enum.TextXAlignment.Left
    worthLbl.TextColor3 = UITheme.Colors.Gold
    worthLbl.Text = "👑 Net Worth: $250   |   ⚡ Rebirths: 0"
    worthLbl.Parent = statsBar

    buffStripLbl = Instance.new("TextLabel")
    buffStripLbl.Size = UDim2.new(0, 440, 0, 22)
    buffStripLbl.Position = UDim2.fromOffset(14, 73)
    buffStripLbl.BackgroundColor3 = UITheme.Colors.BgDark
    buffStripLbl.BackgroundTransparency = 0.15
    buffStripLbl.Font = Enum.Font.GothamBold
    buffStripLbl.TextSize = 11
    buffStripLbl.TextColor3 = UITheme.Colors.Cyan
    buffStripLbl.Visible = false
    UITheme.AddCorner(buffStripLbl, 8)
    buffStripLbl.Parent = rootGui

    -- Top Center Global Event Timers (15m Rift + 30m Apocalypse)
    local timerBar = Instance.new("Frame")
    timerBar.Name = "WorldTimersBar"
    timerBar.Size = UDim2.new(0, 420, 0, 54)
    timerBar.Position = UDim2.new(0.5, -210, 0, 12)
    timerBar.BackgroundColor3 = UITheme.Colors.BgDark
    timerBar.BackgroundTransparency = 0.08
    timerBar.BorderSizePixel = 0
    UITheme.AddCorner(timerBar, 12)
    UITheme.AddStroke(timerBar, UITheme.Colors.Purple, 1.5)
    timerBar.Parent = rootGui

    riftTimerLbl = Instance.new("TextLabel")
    riftTimerLbl.Size = UDim2.new(0.5, -10, 1, 0)
    riftTimerLbl.Position = UDim2.fromOffset(8, 0)
    riftTimerLbl.BackgroundTransparency = 1
    riftTimerLbl.Font = Enum.Font.GothamBold
    riftTimerLbl.TextSize = 13
    riftTimerLbl.TextWrapped = true
    riftTimerLbl.TextColor3 = UITheme.Colors.Cyan
    riftTimerLbl.Text = "🌀 RIFT IN 15:00"
    riftTimerLbl.Parent = timerBar

    worldTimerLbl = Instance.new("TextLabel")
    worldTimerLbl.Size = UDim2.new(0.5, -10, 1, 0)
    worldTimerLbl.Position = UDim2.new(0.5, 2, 0, 0)
    worldTimerLbl.BackgroundTransparency = 1
    worldTimerLbl.Font = Enum.Font.GothamBold
    worldTimerLbl.TextSize = 13
    worldTimerLbl.TextWrapped = true
    worldTimerLbl.TextColor3 = UITheme.Colors.Red
    worldTimerLbl.Text = "☄️ WORLD END 30:00"
    worldTimerLbl.Parent = timerBar

    -- Top Right EN/TR Language Toggle
    langBtn = UITheme.MakeButton({
        Text = "🌐 EN",
        Size = UDim2.fromOffset(86, 40),
        Position = UDim2.new(1, -100, 0, 16),
        Color = UITheme.Colors.BgCard,
        Parent = rootGui,
        FontSize = 14,
    })
    langBtn.MouseButton1Click:Connect(function()
        local nextLang: Localization.LanguageCode = if HUDController.GetLanguage() == "en" then "tr" else "en"
        Remotes.GetEvent("RequestSetLanguage"):FireServer(nextLang)
        if HUDController.CurrentProfile then
            HUDController.CurrentProfile.PreferredLanguage = nextLang
        end
        refreshLabels()
        for _, cb in ipairs(HUDController._onLanguageChanged) do
            cb(nextLang)
        end
    end)

    -- Carrying Relic Alert Banner + Live Waypoint Compass
    carryBanner = Instance.new("Frame")
    carryBanner.Name = "CarryAlertBanner"
    carryBanner.Size = UDim2.new(0.52, 0, 0, 56)
    carryBanner.Position = UDim2.fromScale(0.24, 0.78)
    carryBanner.BackgroundColor3 = Color3.fromRGB(28, 22, 12)
    carryBanner.Visible = false
    UITheme.AddCorner(carryBanner, 12)
    UITheme.AddStroke(carryBanner, UITheme.Colors.Gold, 2.2)
    carryBanner.Parent = rootGui

    carryLabel = Instance.new("TextLabel")
    carryLabel.Size = UDim2.new(1, -16, 0.56, 0)
    carryLabel.Position = UDim2.fromOffset(8, 2)
    carryLabel.BackgroundTransparency = 1
    carryLabel.Font = Enum.Font.GothamBlack
    carryLabel.TextScaled = true
    carryLabel.TextColor3 = UITheme.Colors.Gold
    carryLabel.Parent = carryBanner

    carryCompassLbl = Instance.new("TextLabel")
    carryCompassLbl.Size = UDim2.new(1, -16, 0.42, 0)
    carryCompassLbl.Position = UDim2.new(0, 8, 0.56, 0)
    carryCompassLbl.BackgroundTransparency = 1
    carryCompassLbl.Font = Enum.Font.GothamBold
    carryCompassLbl.TextSize = 13
    carryCompassLbl.TextColor3 = UITheme.Colors.Green
    carryCompassLbl.Text = "🧭 BASE COMPASS"
    carryCompassLbl.Parent = carryBanner

    -- Bottom Navigation Dock (8 Buttons including Quests/Codes/Rebirth & Trading!)
    local dock = Instance.new("Frame")
    dock.Name = "BottomNavDock"
    dock.Size = UDim2.new(0, 888, 0, 52)
    dock.Position = UDim2.new(0.5, -444, 1, -66)
    dock.BackgroundColor3 = UITheme.Colors.BgDark
    dock.BackgroundTransparency = 0.08
    dock.BorderSizePixel = 0
    UITheme.AddCorner(dock, 14)
    UITheme.AddStroke(dock, UITheme.Colors.Stroke, 1.5)
    dock.Parent = rootGui

    local dockLayout = Instance.new("UIListLayout")
    dockLayout.FillDirection = Enum.FillDirection.Horizontal
    dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    dockLayout.Padding = UDim.new(0, 6)
    dockLayout.Parent = dock

    local navItems = {
        { Id = "Base", Key = "BASE_MENU", Color = UITheme.Colors.Green },
        { Id = "Flex", Key = "FLEX_MENU", Color = UITheme.Colors.Purple },
        { Id = "Quests", Key = "QUEST_MENU", Color = Color3.fromRGB(255, 110, 175) },
        { Id = "Trade", Key = "TRADE_MENU", Color = Color3.fromRGB(95, 220, 180) },
        { Id = "Shop", Key = "SHOP_MENU", Color = UITheme.Colors.Gold },
        { Id = "Index", Key = "INDEX_MENU", Color = UITheme.Colors.Cyan },
        { Id = "Squad", Key = "SQUAD_MENU", Color = Color3.fromRGB(255, 145, 55) },
        { Id = "Rank", Key = "RANK_MENU", Color = UITheme.Colors.BgHover },
    }
    for _, item in ipairs(navItems) do
        local btn = UITheme.MakeButton({
            Text = Localization.Get(item.Key, "en"),
            Size = UDim2.fromOffset(102, 38),
            Color = item.Color,
            TextColor = if item.Color == UITheme.Colors.Gold
                    or item.Color == UITheme.Colors.Cyan
                    or item.Color == UITheme.Colors.Green
                    or item.Color == Color3.fromRGB(95, 220, 180)
                then Color3.fromRGB(14, 18, 28)
                else UITheme.Colors.TextMain,
            Parent = dock,
            FontSize = 12,
        })
        btn.MouseButton1Click:Connect(function()
            HUDController.ToggleModal(item.Id)
        end)
        dockButtons[item.Id] = { Btn = btn, Key = item.Key }
    end

    -- Studio-Only Quick Test Toolbar so the creator can trigger every feature in 1 click during F5 Playtest!
    if RunService:IsStudio() then
        local testBar = Instance.new("Frame")
        testBar.Name = "StudioTestBar"
        testBar.Size = UDim2.fromOffset(168, 240)
        testBar.Position = UDim2.new(0, 14, 0, 102)
        testBar.BackgroundColor3 = UITheme.Colors.BgDark
        testBar.BackgroundTransparency = 0.15
        UITheme.AddCorner(testBar, 10)
        UITheme.AddStroke(testBar, UITheme.Colors.Gold, 1.2)
        testBar.Parent = rootGui

        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 4)
        lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
        lay.Parent = testBar

        local hdr = Instance.new("TextLabel")
        hdr.Size = UDim2.new(1, 0, 0, 22)
        hdr.BackgroundTransparency = 1
        hdr.Font = Enum.Font.GothamBlack
        hdr.TextSize = 11
        hdr.TextColor3 = UITheme.Colors.Gold
        hdr.Text = "STUDIO LIVE TEST"
        hdr.Parent = testBar

        local cmds = {
            { Label = "☄️ Test Meteor", Cmd = "/test meteor" },
            { Label = "🦖 Test Monster", Cmd = "/test monster" },
            { Label = "🪐 Test Zero-G", Cmd = "/test gravity" },
            { Label = "🌀 Open 15m Rift", Cmd = "/test rift" },
            { Label = "✨ Spawn 0.01% Secret", Cmd = "/test secret" },
            { Label = "🌟 Spawn Celestial", Cmd = "/test celestial" },
            { Label = "💵 +$100K Cash", Cmd = "/test cash 100000" },
        }
        for _, c in ipairs(cmds) do
            local tb = UITheme.MakeButton({
                Text = c.Label,
                Size = UDim2.fromOffset(148, 25),
                Color = UITheme.Colors.BgCard,
                Parent = testBar,
                FontSize = 11,
            })
            tb.MouseButton1Click:Connect(function()
                Remotes.GetEvent("RequestAdminCommand"):FireServer(c.Cmd)
            end)
        end
    end

    -- Listen to server timers & carry state
    Remotes.GetEvent("WorldTimerSync").OnClientEvent:Connect(function(timers)
        local lang = HUDController.GetLanguage()
        if timers.Rift then
            if timers.Rift.IsOpen then
                riftTimerLbl.Text = string.format("🌀 %s %s", Localization.Get("RIFT_ACTIVE", lang), Utils.FormatTime(timers.Rift.SecondsLeft))
            else
                riftTimerLbl.Text = string.format("🌀 %s %s", Localization.Get("RIFT_OPEN_IN", lang), Utils.FormatTime(timers.Rift.SecondsLeft))
            end
        end
        if timers.WorldEnding then
            if timers.WorldEnding.IsActive then
                worldTimerLbl.Text = string.format("🔥 %s (%s)", Localization.Get("WORLD_END_ACTIVE", lang), Utils.FormatTime(timers.WorldEnding.SecondsLeft))
            else
                worldTimerLbl.Text = string.format("☄️ %s %s", Localization.Get("WORLD_END_IN", lang), Utils.FormatTime(timers.WorldEnding.SecondsLeft))
            end
        end
    end)

    Remotes.GetEvent("CarryStateSync").OnClientEvent:Connect(function(info)
        local localPlayer = Players.LocalPlayer
        if info and info.UserId == localPlayer.UserId then
            if info.ItemId then
                isCarryingNow = true
                local lang = HUDController.GetLanguage()
                local name = if lang == "tr" and info.ItemNameTR then info.ItemNameTR else info.ItemName
                local mutPrefix = ""
                if info.Mutation and info.Mutation ~= "Normal" then
                    mutPrefix = "[" .. string.upper(MutationConfig.Get(info.Mutation).Prefix) .. "] "
                end
                carryingTitle = string.format("%s %s: %s%s — %s", tostring(info.Icon or "💎"), Localization.Get("CARRYING", lang), mutPrefix, tostring(name), Localization.Get("RUN_TO_BASE", lang))
                carryLabel.Text = carryingTitle
                carryBanner.Visible = true
            else
                isCarryingNow = false
                carryBanner.Visible = false
            end
        end
    end)

    -- Live Carry Compass distance update while carrying
    RunService.RenderStepped:Connect(function()
        if not isCarryingNow then
            return
        end
        local char = Players.LocalPlayer.Character
        local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
        if hrp then
            local basePos = BaseConfig.GetSlotCFrame(HUDController.CurrentBaseSlot).Position
            local dist = math.floor((basePos - hrp.Position).Magnitude)
            local lang = HUDController.GetLanguage()
            carryCompassLbl.Text = string.format("🧭 %s: %d studs  (Base #%d)", Localization.Get("BASE_COMPASS", lang), dist, HUDController.CurrentBaseSlot)
        end
    end)

    -- Open Quests / Codes / Merchant / Rebirth modal when activating Plaza Kiosks
    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        if player ~= Players.LocalPlayer then
            return
        end
        local parent = prompt.Parent
        if parent and parent:GetAttribute("KioskPanel") then
            HUDController.ToggleModal("Quests")
        end
    end)

    Remotes.GetEvent("StateSync").OnClientEvent:Connect(HUDController.ApplyState)
end

return HUDController
