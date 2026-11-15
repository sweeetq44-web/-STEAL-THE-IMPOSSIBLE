--!strict
-- Base Tier 1-5 Upgrades, Showcase Pedestal Flex Assignment & Galaxy Egg Hatching UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local BaseConfig = require(Shared.BaseConfig)
local ItemCatalog = require(Shared.ItemCatalog)
local MutationConfig = require(Shared.MutationConfig)
local RarityConfig = require(Shared.RarityConfig)
local Remotes = require(Shared.Remotes)
local Localization = require(Shared.Localization)
local Utils = require(Shared.Utils)

local UITheme = require(script.Parent.UITheme)
local HUDController = require(script.Parent.HUDController)

local BaseManagerController = {}
local bodyFrame: ScrollingFrame
local modalPanel: Frame

local function clearChildren(parent: Instance)
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end
end

function BaseManagerController.Refresh()
    if not bodyFrame then
        return
    end
    clearChildren(bodyFrame)

    local profile = HUDController.CurrentProfile
    local lang = HUDController.GetLanguage()
    if not profile then
        return
    end

    local currentTier = BaseConfig.GetTier(profile.BaseTier)
    local nextTier = if profile.BaseTier < #BaseConfig.UpgradeTiers then BaseConfig.GetTier(profile.BaseTier + 1) else nil

    -- Base Tier Growth Card
    local tierCard = Instance.new("Frame")
    tierCard.Size = UDim2.new(1, -10, 0, 108)
    tierCard.BackgroundColor3 = UITheme.Colors.BgCard
    UITheme.AddCorner(tierCard, 10)
    UITheme.AddStroke(tierCard, UITheme.Colors.Green, 1.5)
    tierCard.Parent = bodyFrame

    local tierTitle = Instance.new("TextLabel")
    tierTitle.Size = UDim2.new(0.65, 0, 0, 34)
    tierTitle.Position = UDim2.fromOffset(14, 10)
    tierTitle.BackgroundTransparency = 1
    tierTitle.Font = Enum.Font.GothamBlack
    tierTitle.TextSize = 18
    tierTitle.TextXAlignment = Enum.TextXAlignment.Left
    tierTitle.TextColor3 = UITheme.Colors.Green
    tierTitle.Text = string.format("🏛️ Tier %d: %s", currentTier.Tier, if lang == "tr" then currentTier.NameTR else currentTier.Name)
    tierTitle.Parent = tierCard

    local tierInfo = Instance.new("TextLabel")
    tierInfo.Size = UDim2.new(0.65, 0, 0, 50)
    tierInfo.Position = UDim2.fromOffset(14, 46)
    tierInfo.BackgroundTransparency = 1
    tierInfo.Font = Enum.Font.GothamMedium
    tierInfo.TextSize = 13
    tierInfo.TextWrapped = true
    tierInfo.TextXAlignment = Enum.TextXAlignment.Left
    tierInfo.TextColor3 = UITheme.Colors.TextMuted
    tierInfo.Text = string.format(
        "Pedestals: %d  |  Income Multiplier: %.2fx  |  Base Likes: ❤️ %d",
        currentTier.MaxPedestals,
        currentTier.IncomeMultiplier,
        profile.TotalBaseLikes
    )
    tierInfo.Parent = tierCard

    if nextTier then
        local upgBtn = UITheme.MakeButton({
            Text = string.format("%s\n(%s)", Localization.Get("UPGRADE_BASE", lang), Utils.FormatCash(nextTier.Cost)),
            Size = UDim2.fromOffset(195, 68),
            Position = UDim2.new(1, -210, 0, 20),
            Color = if profile.Cash >= nextTier.Cost then UITheme.Colors.Green else UITheme.Colors.BgHover,
            TextColor = if profile.Cash >= nextTier.Cost then Color3.fromRGB(14, 18, 28) else UITheme.Colors.TextMuted,
            Parent = tierCard,
            FontSize = 14,
        })
        upgBtn.MouseButton1Click:Connect(function()
            Remotes.GetEvent("RequestUpgradeBase"):FireServer()
        end)
    end

    -- Security Shield + High-Stakes 2x Raid Safe Card
    local safeCard = Instance.new("Frame")
    safeCard.Size = UDim2.new(1, -10, 0, 86)
    safeCard.BackgroundColor3 = UITheme.Colors.BgCard
    UITheme.AddCorner(safeCard, 10)
    UITheme.AddStroke(safeCard, if profile.HighStakesMode then UITheme.Colors.Red else UITheme.Colors.Cyan, 1.5)
    safeCard.Parent = bodyFrame

    local shieldActive = HUDController.CurrentShieldRemaining > 0
    local safeTitle = Instance.new("TextLabel")
    safeTitle.Size = UDim2.new(0.54, 0, 0, 30)
    safeTitle.Position = UDim2.fromOffset(14, 8)
    safeTitle.BackgroundTransparency = 1
    safeTitle.Font = Enum.Font.GothamBlack
    safeTitle.TextSize = 15
    safeTitle.TextXAlignment = Enum.TextXAlignment.Left
    safeTitle.TextColor3 = if profile.HighStakesMode then UITheme.Colors.Red else UITheme.Colors.Cyan
    safeTitle.Text = string.format(
        "🛡️ %s: %s   |   🔐 %s: %s",
        Localization.Get("BASE_SHIELD", lang),
        if shieldActive then (tostring(HUDController.CurrentShieldRemaining) .. "s") else "DOWN",
        Localization.Get("SAFE_CASH", lang),
        Utils.FormatCash(profile.UncollectedSafeCash or 0)
    )
    safeTitle.Parent = safeCard

    local safeHint = Instance.new("TextLabel")
    safeHint.Size = UDim2.new(0.54, 0, 0, 38)
    safeHint.Position = UDim2.fromOffset(14, 40)
    safeHint.BackgroundTransparency = 1
    safeHint.Font = Enum.Font.GothamMedium
    safeHint.TextSize = 12
    safeHint.TextWrapped = true
    safeHint.TextXAlignment = Enum.TextXAlignment.Left
    safeHint.TextColor3 = UITheme.Colors.TextMuted
    safeHint.Text = if profile.HighStakesMode
        then "🔥 High-Stakes 2x ACTIVE: Passive cash builds in your raidable Safe!"
        else "Standard Mode: Safe passive income. Turn on 2x Risk for double Safe Cash!"
    safeHint.Parent = safeCard

    local riskBtn = UITheme.MakeButton({
        Text = if profile.HighStakesMode then "🔥 2x ON" else ("⚡ " .. Localization.Get("HIGH_STAKES_MODE", lang)),
        Size = UDim2.fromOffset(130, 34),
        Position = UDim2.new(1, -415, 0, 26),
        Color = if profile.HighStakesMode then UITheme.Colors.Red else UITheme.Colors.BgHover,
        Parent = safeCard,
        FontSize = 12,
    })
    riskBtn.MouseButton1Click:Connect(function()
        Remotes.GetEvent("RequestToggleHighStakes"):FireServer()
    end)

    local collectBtn = UITheme.MakeButton({
        Text = "💰 " .. Localization.Get("COLLECT_SAFE", lang),
        Size = UDim2.fromOffset(132, 34),
        Position = UDim2.new(1, -278, 0, 26),
        Color = UITheme.Colors.Gold,
        TextColor = Color3.fromRGB(14, 18, 28),
        Parent = safeCard,
        FontSize = 12,
    })
    collectBtn.MouseButton1Click:Connect(function()
        Remotes.GetEvent("RequestCollectBaseSafe"):FireServer()
    end)

    local shieldBtn = UITheme.MakeButton({
        Text = "🛡️ " .. Localization.Get("RECHARGE_SHIELD", lang),
        Size = UDim2.fromOffset(132, 34),
        Position = UDim2.new(1, -142, 0, 26),
        Color = UITheme.Colors.Cyan,
        TextColor = Color3.fromRGB(14, 18, 28),
        Parent = safeCard,
        FontSize = 12,
    })
    shieldBtn.MouseButton1Click:Connect(function()
        Remotes.GetEvent("RequestRechargeShield"):FireServer()
    end)

    -- Vault & Showcase Pedestal Inventory List
    for idx, inst in ipairs(profile.VaultItems) do
        local def = ItemCatalog.Get(inst.ItemId)
        if def then
            local rarity = RarityConfig.Get(def.Rarity)
            local mutInfo = MutationConfig.Get(inst.Mutation)
            local totalMult = ItemCatalog.GetInstanceMultiplier(inst)
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -10, 0, 74)
            card.BackgroundColor3 = UITheme.Colors.BgCard
            UITheme.AddCorner(card, 10)
            UITheme.AddStroke(card, if mutInfo.Id ~= "Normal" then mutInfo.Color else rarity.Color, 1.4)
            card.LayoutOrder = idx + 10
            card.Parent = bodyFrame

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(0.55, 0, 0, 28)
            title.Position = UDim2.fromOffset(12, 8)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamBlack
            title.TextSize = 15
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.TextColor3 = rarity.Color
            local itemName = if lang == "tr" then def.NameTR else def.Name
            local mutPrefix = if mutInfo.Id ~= "Normal" then ("[" .. string.upper(mutInfo.Prefix) .. "] ") else ""
            local hatchSuffix = if inst.HatchedCreature then (" [" .. inst.HatchedCreature .. "]") else ""
            title.Text = string.format("%s %s%s%s", def.Icon, mutPrefix, itemName, hatchSuffix)
            title.Parent = card

            local sub = Instance.new("TextLabel")
            sub.Size = UDim2.new(0.55, 0, 0, 26)
            sub.Position = UDim2.fromOffset(12, 38)
            sub.BackgroundTransparency = 1
            sub.Font = Enum.Font.GothamMedium
            sub.TextSize = 12
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.TextColor3 = if mutInfo.Id ~= "Normal" then mutInfo.Color else UITheme.Colors.TextMuted
            local slotStr = if inst.PedestalSlot then ("Pedestal #" .. tostring(inst.PedestalSlot)) else "Vault Storage (35%)"
            local effectiveIncome = math.floor(def.PassiveIncomePerSec * totalMult)
            sub.Text = string.format("%s (%.2fx)  •  +%s/s  •  %s", rarity.DisplayName, totalMult, Utils.FormatCash(effectiveIncome), slotStr)
            sub.Parent = card

            -- Place on next available pedestal or remove
            local flexBtn = UITheme.MakeButton({
                Text = if inst.PedestalSlot then "Store" else Localization.Get("EQUIP_PEDESTAL", lang),
                Size = UDim2.fromOffset(145, 38),
                Position = UDim2.new(1, -158, 0, 18),
                Color = if inst.PedestalSlot then UITheme.Colors.BgHover else UITheme.Colors.Purple,
                Parent = card,
                FontSize = 12,
            })
            flexBtn.MouseButton1Click:Connect(function()
                if inst.PedestalSlot then
                    Remotes.GetEvent("RequestClearPedestal"):FireServer(inst.PedestalSlot)
                else
                    -- Pick first free slot or slot 1
                    local used: { [number]: boolean } = {}
                    for _, other in ipairs(profile.VaultItems) do
                        if other.PedestalSlot then
                            used[other.PedestalSlot] = true
                        end
                    end
                    local chosen = 1
                    for s = 1, currentTier.MaxPedestals do
                        if not used[s] then
                            chosen = s
                            break
                        end
                    end
                    Remotes.GetEvent("RequestAssignPedestal"):FireServer(inst.Uid, chosen)
                end
            end)

            -- Galaxy Egg Hatch Button ("İçinden rastgele galaksi yaratığı çıkan yumurta")
            if def.SpecialBehavior == "HatchableEgg" and not inst.HatchedCreature then
                local hatchBtn = UITheme.MakeButton({
                    Text = "🌌 " .. Localization.Get("HATCH_EGG", lang),
                    Size = UDim2.fromOffset(155, 38),
                    Position = UDim2.new(1, -322, 0, 18),
                    Color = UITheme.Colors.Gold,
                    TextColor = Color3.fromRGB(14, 18, 28),
                    Parent = card,
                    FontSize = 12,
                })
                hatchBtn.MouseButton1Click:Connect(function()
                    Remotes.GetEvent("RequestHatchGalaxyEgg"):FireServer(inst.Uid)
                end)
            end
        end
    end
end

function BaseManagerController.Init(rootGui: ScreenGui)
    local panel, body, closeBtn = UITheme.CreateModal("BaseManagerModal", "🏛️ BASE & VAULT MANAGER", rootGui, UITheme.Colors.Green)
    modalPanel = panel
    bodyFrame = body
    closeBtn.MouseButton1Click:Connect(function()
        modalPanel.Visible = false
    end)
    HUDController.RegisterModal("Base", modalPanel, BaseManagerController.Refresh)
end

return BaseManagerController
