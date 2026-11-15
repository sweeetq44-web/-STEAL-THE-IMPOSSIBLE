--!strict
-- Shop & Style Modal:
--   * 100% F2P Cash Upgrades & Gadgets
--   * Ethical Cosmetic-Only Robux Shop (99, 149, 49, 199, 79, 299 Robux)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local BaseConfig = require(Shared.BaseConfig)
local CosmeticCatalog = require(Shared.CosmeticCatalog)
local Remotes = require(Shared.Remotes)
local Localization = require(Shared.Localization)
local Utils = require(Shared.Utils)

local UITheme = require(script.Parent.UITheme)
local HUDController = require(script.Parent.HUDController)

local ShopCosmeticController = {}
local modalPanel: Frame
local bodyFrame: ScrollingFrame

local function clearChildren(parent: Instance)
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end
end

local function makeSectionHeader(text: string, color: Color3, order: number)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = color
    lbl.Text = text
    lbl.LayoutOrder = order
    lbl.Parent = bodyFrame
end

function ShopCosmeticController.Refresh()
    if not bodyFrame then
        return
    end
    clearChildren(bodyFrame)

    local profile = HUDController.CurrentProfile
    local lang = HUDController.GetLanguage()
    if not profile then
        return
    end

    local order = 1

    -- Ethical Zero Pay-To-Win Banner
    makeSectionHeader("🛡️ " .. Localization.Get("NO_P2W_BADGE", lang), UITheme.Colors.Green, order)
    order += 1

    -- Section 1: F2P Cash Tech Upgrades
    makeSectionHeader("⚙️ CASH UPGRADES (EARNED IN-GAME)", UITheme.Colors.Cyan, order)
    order += 1

    for _, tech in ipairs(BaseConfig.TechUpgrades) do
        local lvl = profile.TechLevels[tech.Id] or 0
        local nextCost = BaseConfig.GetTechCost(tech.Id, lvl)

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 70)
        card.BackgroundColor3 = UITheme.Colors.BgCard
        UITheme.AddCorner(card, 10)
        UITheme.AddStroke(card, UITheme.Colors.Cyan, 1.3)
        card.LayoutOrder = order
        order += 1
        card.Parent = bodyFrame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.65, 0, 0, 26)
        title.Position = UDim2.fromOffset(12, 8)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 15
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = UITheme.Colors.TextMain
        title.Text = string.format("%s  [Lv %d/%d]", if lang == "tr" then tech.NameTR else tech.Name, lvl, tech.MaxLevel)
        title.Parent = card

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0.65, 0, 0, 28)
        desc.Position = UDim2.fromOffset(12, 36)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextColor3 = UITheme.Colors.TextMuted
        desc.Text = if lang == "tr" then tech.DescriptionTR else tech.Description
        desc.Parent = card

        local btnText = if nextCost then Utils.FormatCash(nextCost) else "MAX"
        local btn = UITheme.MakeButton({
            Text = btnText,
            Size = UDim2.fromOffset(135, 42),
            Position = UDim2.new(1, -148, 0, 14),
            Color = if nextCost and profile.Cash >= nextCost then UITheme.Colors.Cyan else UITheme.Colors.BgHover,
            TextColor = if nextCost and profile.Cash >= nextCost then Color3.fromRGB(14, 18, 28) else UITheme.Colors.TextMuted,
            Parent = card,
            FontSize = 14,
        })
        btn.MouseButton1Click:Connect(function()
            Remotes.GetEvent("RequestUpgradeTech"):FireServer(tech.Id)
        end)
    end

    -- Section 2: F2P Cash Gadgets
    makeSectionHeader("⚡ UTILITY GADGETS (CASH)", UITheme.Colors.Green, order)
    order += 1

    for _, gadget in ipairs(BaseConfig.Gadgets) do
        local owned = profile.OwnedGadgets[gadget.Id] == true
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 70)
        card.BackgroundColor3 = UITheme.Colors.BgCard
        UITheme.AddCorner(card, 10)
        UITheme.AddStroke(card, UITheme.Colors.Green, 1.3)
        card.LayoutOrder = order
        order += 1
        card.Parent = bodyFrame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.65, 0, 0, 26)
        title.Position = UDim2.fromOffset(12, 8)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 15
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = UITheme.Colors.TextMain
        title.Text = string.format("%s %s", gadget.Icon, if lang == "tr" then gadget.NameTR else gadget.Name)
        title.Parent = card

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0.65, 0, 0, 28)
        desc.Position = UDim2.fromOffset(12, 36)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextColor3 = UITheme.Colors.TextMuted
        desc.Text = if lang == "tr" then gadget.DescriptionTR else gadget.Description
        desc.Parent = card

        local btn = UITheme.MakeButton({
            Text = if owned then Localization.Get("OWNED", lang) else Utils.FormatCash(gadget.Cost),
            Size = UDim2.fromOffset(135, 42),
            Position = UDim2.new(1, -148, 0, 14),
            Color = if owned then UITheme.Colors.BgHover elseif profile.Cash >= gadget.Cost then UITheme.Colors.Green else UITheme.Colors.BgHover,
            TextColor = if not owned and profile.Cash >= gadget.Cost then Color3.fromRGB(14, 18, 28) else UITheme.Colors.TextMain,
            Parent = card,
            FontSize = 14,
        })
        btn.MouseButton1Click:Connect(function()
            if not owned then
                Remotes.GetEvent("RequestBuyGadget"):FireServer(gadget.Id)
            end
        end)
    end

    -- Section 3: Robux Cosmetic Storefront (99, 149, 49, 199, 79, 299 Robux)
    makeSectionHeader("💎 ROBUX COSMETICS (STYLE & FLEX ONLY)", UITheme.Colors.Gold, order)
    order += 1

    for _, prod in ipairs(CosmeticCatalog.Products) do
        local owned = profile.OwnedProducts[prod.Id] == true
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 78)
        card.BackgroundColor3 = UITheme.Colors.BgCard
        UITheme.AddCorner(card, 10)
        UITheme.AddStroke(card, prod.BadgeColor, 1.6)
        card.LayoutOrder = order
        order += 1
        card.Parent = bodyFrame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.65, 0, 0, 26)
        title.Position = UDim2.fromOffset(12, 8)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 15
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = prod.BadgeColor
        title.Text = if lang == "tr" then prod.NameTR else prod.Name
        title.Parent = card

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0.65, 0, 0, 34)
        desc.Position = UDim2.fromOffset(12, 36)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextColor3 = UITheme.Colors.TextMuted
        desc.Text = if lang == "tr" then prod.DescriptionTR else prod.Description
        desc.Parent = card

        local buyBtn = UITheme.MakeButton({
            Text = if owned then ("✓ " .. Localization.Get("OWNED", lang)) else ("R$ " .. tostring(prod.RobuxPrice)),
            Size = UDim2.fromOffset(135, 44),
            Position = UDim2.new(1, -148, 0, 17),
            Color = if owned then UITheme.Colors.Green else UITheme.Colors.Gold,
            TextColor = Color3.fromRGB(14, 18, 28),
            Parent = card,
            FontSize = 15,
        })
        buyBtn.MouseButton1Click:Connect(function()
            if not owned then
                Remotes.GetEvent("RequestPromptProduct"):FireServer(prod.Id)
            end
        end)
    end

    -- Section 4: Equip Owned Cosmetics
    makeSectionHeader("🎨 EQUIP OWNED COSMETICS", UITheme.Colors.Purple, order)
    order += 1

    for _, asset in ipairs(CosmeticCatalog.Assets) do
        if CosmeticCatalog.PlayerOwnsAsset(profile.OwnedProducts, asset.Id) then
            local isEquipped =
                profile.EquippedCosmetics.CharacterSkin == asset.Id
                or profile.EquippedCosmetics.BaseDesign == asset.Id
                or profile.EquippedCosmetics.AnimationPack == asset.Id
                or profile.EquippedCosmetics.PetSkin == asset.Id
                or (asset.Category == "VipTag" and profile.EquippedCosmetics.VipTagEnabled)

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -10, 0, 52)
            row.BackgroundColor3 = UITheme.Colors.BgCard
            UITheme.AddCorner(row, 8)
            UITheme.AddStroke(row, asset.SecondaryColor, 1.2)
            row.LayoutOrder = order
            order += 1
            row.Parent = bodyFrame

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.68, 0, 1, 0)
            lbl.Position = UDim2.fromOffset(12, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextColor3 = UITheme.Colors.TextMain
            lbl.Text = string.format("[%s] %s", asset.Category, if lang == "tr" then asset.NameTR else asset.Name)
            lbl.Parent = row

            local eqBtn = UITheme.MakeButton({
                Text = if isEquipped then Localization.Get("EQUIPPED", lang) else Localization.Get("EQUIP", lang),
                Size = UDim2.fromOffset(118, 34),
                Position = UDim2.new(1, -130, 0, 9),
                Color = if isEquipped then UITheme.Colors.Purple else UITheme.Colors.BgHover,
                Parent = row,
                FontSize = 13,
            })
            eqBtn.MouseButton1Click:Connect(function()
                Remotes.GetEvent("RequestEquipCosmetic"):FireServer(asset.Id)
            end)
        end
    end
end

function ShopCosmeticController.Init(rootGui: ScreenGui)
    local panel, body, closeBtn = UITheme.CreateModal("ShopCosmeticModal", "🛒 SHOP & COSMETIC STYLE", rootGui, UITheme.Colors.Gold)
    modalPanel = panel
    bodyFrame = body
    closeBtn.MouseButton1Click:Connect(function()
        modalPanel.Visible = false
    end)
    HUDController.RegisterModal("Shop", modalPanel, ShopCosmeticController.Refresh)
end

return ShopCosmeticController
