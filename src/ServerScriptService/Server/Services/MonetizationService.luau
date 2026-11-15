--!strict
-- Ethical Cosmetic-First Robux Monetization & Cosmetic Appearance Service
-- Handles GamePass checks, ProcessReceipt, equipping Skins / Base Designs / Animations / VIP / Pets

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local CosmeticCatalog = require(Shared.CosmeticCatalog)
local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local DataService = require(script.Parent.DataService)
local BaseService = require(script.Parent.BaseService)

local MonetizationService = {}
MonetizationService._rateLimiter = Utils.CreateRateLimiter()

local function applyCharacterCosmetics(player: Player)
    local profile = DataService.GetProfile(player)
    local char = player.Character
    if not profile or not char then
        return
    end

    local head = char:FindFirstChild("Head") :: BasePart?
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?

    -- 1. VIP Gold Crown Overhead Name Tag
    if head then
        local oldVip = head:FindFirstChild("VIPOverheadGui")
        if oldVip then
            oldVip:Destroy()
        end
        if profile.EquippedCosmetics.VipTagEnabled then
            local bb = Instance.new("BillboardGui")
            bb.Name = "VIPOverheadGui"
            bb.Size = UDim2.fromOffset(170, 38)
            bb.StudsOffset = Vector3.new(0, 2.7, 0)
            bb.AlwaysOnTop = false
            bb.MaxDistance = 85
            bb.Parent = head

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.fromScale(1, 1)
            lbl.BackgroundColor3 = Color3.fromRGB(22, 18, 12)
            lbl.BackgroundTransparency = 0.25
            lbl.Font = Enum.Font.GothamBlack
            lbl.TextScaled = true
            lbl.TextColor3 = Color3.fromRGB(255, 215, 55)
            lbl.Text = "👑 VIP  " .. player.Name
            lbl.Parent = bb

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 8)
            c.Parent = lbl
        end
    end

    -- 2. Custom Character Skin Aura / Trail
    if hrp then
        local oldAura = char:FindFirstChild("CosmeticSkinAura")
        if oldAura then
            oldAura:Destroy()
        end
        local skinId = profile.EquippedCosmetics.CharacterSkin
        if skinId then
            local asset = CosmeticCatalog.GetAsset(skinId)
            if asset then
                local aura = Instance.new("Highlight")
                aura.Name = "CosmeticSkinAura"
                aura.FillColor = asset.PrimaryColor
                aura.OutlineColor = asset.SecondaryColor
                aura.FillTransparency = 0.72
                aura.OutlineTransparency = 0.1
                aura.Parent = char
            end
        end

        -- 3. Purely Cosmetic Shoulder Pet Companion
        local oldPet = char:FindFirstChild("CosmeticPetCompanion")
        if oldPet then
            oldPet:Destroy()
        end
        local petId = profile.EquippedCosmetics.PetSkin
        if petId then
            local petAsset = CosmeticCatalog.GetAsset(petId)
            if petAsset then
                local pet = Instance.new("Part")
                pet.Name = "CosmeticPetCompanion"
                pet.Size = Vector3.new(1.3, 1.3, 1.3)
                pet.Shape = Enum.PartType.Ball
                pet.Color = petAsset.PrimaryColor
                pet.Material = Enum.Material.Neon
                pet.CanCollide = false
                pet.Massless = true
                pet.CFrame = hrp.CFrame * CFrame.new(2.3, 2.2, 1.2)
                pet.Parent = char

                local weld = Instance.new("WeldConstraint")
                weld.Part0 = hrp
                weld.Part1 = pet
                weld.Parent = pet

                local light = Instance.new("PointLight")
                light.Color = petAsset.SecondaryColor
                light.Range = 10
                light.Brightness = 1.6
                light.Parent = pet
            end
        end
    end

    player:SetAttribute("EquippedAnimationPack", profile.EquippedCosmetics.AnimationPack or "")
end

function MonetizationService.GrantProduct(player: Player, productId: string): boolean
    local profile = DataService.GetProfile(player)
    local prod = CosmeticCatalog.GetProduct(productId)
    if not profile or not prod then
        return false
    end

    profile.OwnedProducts[productId] = true
    -- Auto-equip VIP tag immediately on purchase
    if prod.Category == "VipTag" or productId == "prod_extra_cosmetic_pack" then
        profile.EquippedCosmetics.VipTagEnabled = true
    end
    DataService.MarkDirty(player)
    applyCharacterCosmetics(player)
    BaseService.SyncProfileToClient(player)
    return true
end

function MonetizationService.SyncMarketplaceOwnership(player: Player)
    local profile = DataService.GetProfile(player)
    if not profile then
        return
    end
    for _, prod in ipairs(CosmeticCatalog.Products) do
        if not profile.OwnedProducts[prod.Id] and prod.GamePassId > 0 then
            local ok, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, prod.GamePassId)
            end)
            if ok and owns then
                profile.OwnedProducts[prod.Id] = true
            end
        end
    end
    applyCharacterCosmetics(player)
end

function MonetizationService.EquipCosmetic(player: Player, assetId: string?): (boolean, string)
    local profile = DataService.GetProfile(player)
    if not profile then
        return false, "Profile missing"
    end
    if assetId == nil or assetId == "" then
        return false, "Invalid asset"
    end

    local asset = CosmeticCatalog.GetAsset(assetId)
    if not asset then
        return false, "Cosmetic not found"
    end

    if not CosmeticCatalog.PlayerOwnsAsset(profile.OwnedProducts, assetId) then
        return false, "Not owned"
    end

    if asset.Category == "CharacterSkin" then
        profile.EquippedCosmetics.CharacterSkin = if profile.EquippedCosmetics.CharacterSkin == assetId then nil else assetId
    elseif asset.Category == "BaseDesign" then
        profile.EquippedCosmetics.BaseDesign = if profile.EquippedCosmetics.BaseDesign == assetId then nil else assetId
        local slot = BaseService.GetPlayerSlot(player)
        if slot then
            BaseService.RefreshBaseVisuals(slot)
        end
    elseif asset.Category == "AnimationPack" then
        profile.EquippedCosmetics.AnimationPack = if profile.EquippedCosmetics.AnimationPack == assetId then nil else assetId
    elseif asset.Category == "PetSkin" then
        profile.EquippedCosmetics.PetSkin = if profile.EquippedCosmetics.PetSkin == assetId then nil else assetId
    elseif asset.Category == "VipTag" then
        profile.EquippedCosmetics.VipTagEnabled = not profile.EquippedCosmetics.VipTagEnabled
    end

    DataService.MarkDirty(player)
    applyCharacterCosmetics(player)
    BaseService.SyncProfileToClient(player)
    return true, "Updated!"
end

-- Developer Receipt Handler for repeatable DevProducts
function MonetizationService.ProcessReceipt(receiptInfo: { PlayerId: number, ProductId: number }): Enum.ProductPurchaseDecision
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    for _, prod in ipairs(CosmeticCatalog.Products) do
        if prod.DevProductId == receiptInfo.ProductId or prod.GamePassId == receiptInfo.ProductId then
            local granted = MonetizationService.GrantProduct(player, prod.Id)
            if granted then
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.Start()
    MarketplaceService.ProcessReceipt = MonetizationService.ProcessReceipt

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
        if wasPurchased then
            local prod = CosmeticCatalog.ProductByGamePassId[gamePassId]
            if prod then
                MonetizationService.GrantProduct(player, prod.Id)
            end
        end
    end)

    Remotes.GetEvent("RequestPromptProduct").OnServerEvent:Connect(function(player, productId)
        if type(productId) ~= "string" then
            return
        end
        if not MonetizationService._rateLimiter:Check(player.UserId, "PromptBuy", 0.6) then
            return
        end
        local prod = CosmeticCatalog.GetProduct(productId)
        if not prod then
            return
        end

        if RunService:IsStudio() then
            -- In unpublished Studio playtest, allow instant cosmetic unlock preview for testing!
            MonetizationService.GrantProduct(player, prod.Id)
            return
        end

        pcall(function()
            MarketplaceService:PromptGamePassPurchase(player, prod.GamePassId)
        end)
    end)

    Remotes.GetEvent("RequestEquipCosmetic").OnServerEvent:Connect(function(player, assetId)
        if type(assetId) ~= "string" then
            return
        end
        if not MonetizationService._rateLimiter:Check(player.UserId, "EquipCosmetic", 0.25) then
            return
        end
        MonetizationService.EquipCosmetic(player, assetId)
    end)

    Remotes.GetEvent("RequestSetLanguage").OnServerEvent:Connect(function(player, lang)
        if lang ~= "en" and lang ~= "tr" then
            return
        end
        local profile = DataService.GetProfile(player)
        if profile then
            profile.PreferredLanguage = lang
            DataService.MarkDirty(player)
            BaseService.SyncProfileToClient(player)
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.2)
            applyCharacterCosmetics(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        MonetizationService._rateLimiter:ClearPlayer(player.UserId)
    end)
end

return MonetizationService
