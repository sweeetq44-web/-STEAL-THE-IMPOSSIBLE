--!strict
-- Procedural High-Detail 3D Item Visual Builder
-- Constructs distinct 3D Roblox models for Frozen Sun, Mini Apocalypse, Time Eater,
-- The Last Eye (with TrackingEyePart tag), Galaxy Egg, 0.01% Secrets, and all Relics.

local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local RarityConfig = require(Shared.RarityConfig)
local MutationConfig = require(Shared.MutationConfig)

local ItemVisualBuilder = {}

local function makePart(props: {
    Name: string,
    Size: Vector3,
    Shape: Enum.PartType?,
    Color: Color3,
    Material: Enum.Material,
    Transparency: number?,
    Parent: Instance,
    CFrameOffset: CFrame?,
    BaseCFrame: CFrame,
}): Part
    local p = Instance.new("Part")
    p.Name = props.Name
    p.Size = props.Size
    p.Shape = props.Shape or Enum.PartType.Block
    p.Color = props.Color
    p.Material = props.Material
    p.Transparency = props.Transparency or 0
    p.Anchored = true
    p.CanCollide = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CFrame = props.BaseCFrame * (props.CFrameOffset or CFrame.new())
    p.Parent = props.Parent
    return p
end

local function attachParticles(parentPart: Part, colorA: Color3, colorB: Color3, isSecret: boolean)
    local light = Instance.new("PointLight")
    light.Color = colorA
    light.Range = if isSecret then 26 else 16
    light.Brightness = if isSecret then 3.2 else 1.8
    light.Parent = parentPart

    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(colorA, colorB)
    emitter.LightEmission = 0.85
    emitter.Rate = if isSecret then 28 else 10
    emitter.Speed = NumberRange.new(1.5, 4.0)
    emitter.Lifetime = NumberRange.new(0.8, 1.8)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Parent = parentPart
end

function ItemVisualBuilder.BuildItemModel(
    itemDef: Types.ItemDefinition,
    originCFrame: CFrame,
    options: { Scale: number?, ShowBillboard: boolean?, CustomLabel: string?, Mutation: Types.MutationId? }?
): Model
    local opts = options or {}
    local scale = opts.Scale or 1.0
    local rarityInfo = RarityConfig.Get(itemDef.Rarity)
    local mutationId: Types.MutationId = opts.Mutation or "Normal"
    local mutationDef = MutationConfig.Get(mutationId)
    local hasMutation = (mutationId ~= "Normal")
    local isSecret = itemDef.Rarity == "Secret" or (itemDef.IsSecret == true)

    local model = Instance.new("Model")
    model.Name = "ItemModel_" .. itemDef.Id
    model:SetAttribute("ItemId", itemDef.Id)
    model:SetAttribute("Rarity", itemDef.Rarity)
    model:SetAttribute("Mutation", mutationId)
    model:SetAttribute("SpecialBehavior", itemDef.SpecialBehavior or "")

    local root = makePart({
        Name = "PrimaryHandle",
        Size = Vector3.new(2.2, 2.2, 2.2) * scale,
        Shape = Enum.PartType.Ball,
        Color = itemDef.PrimaryColor,
        Material = Enum.Material.Neon,
        Transparency = 1,
        Parent = model,
        BaseCFrame = originCFrame,
    })
    model.PrimaryPart = root

    local style = itemDef.VisualStyle

    if style == "FrozenSun" then
        -- Blazing golden star encased inside crystalline ice spikes!
        makePart({
            Name = "SolarCore",
            Size = Vector3.new(1.9, 1.9, 1.9) * scale,
            Shape = Enum.PartType.Ball,
            Color = itemDef.SecondaryColor,
            Material = Enum.Material.Neon,
            Parent = model,
            BaseCFrame = originCFrame,
        })
        makePart({
            Name = "IceShell",
            Size = Vector3.new(2.6, 2.6, 2.6) * scale,
            Shape = Enum.PartType.Block,
            Color = itemDef.PrimaryColor,
            Material = Enum.Material.Ice,
            Transparency = 0.32,
            Parent = model,
            CFrameOffset = CFrame.Angles(math.rad(45), math.rad(45), 0),
            BaseCFrame = originCFrame,
        })
        for i = 1, 4 do
            local ang = (i - 1) * (math.pi / 2)
            makePart({
                Name = "FrostSpike" .. tostring(i),
                Size = Vector3.new(0.45, 2.8, 0.45) * scale,
                Color = Color3.fromRGB(225, 250, 255),
                Material = Enum.Material.Glass,
                Transparency = 0.15,
                Parent = model,
                CFrameOffset = CFrame.Angles(0, ang, math.rad(35)),
                BaseCFrame = originCFrame,
            })
        end
    elseif style == "MiniApocalypse" then
        -- Cute/fierce floating dragon head, glowing eyes, swept magma wings & tail
        makePart({
            Name = "DragonBody",
            Size = Vector3.new(1.5, 1.3, 2.2) * scale,
            Color = itemDef.SecondaryColor,
            Material = Enum.Material.Basalt,
            Parent = model,
            BaseCFrame = originCFrame,
        })
        makePart({
            Name = "DragonCore",
            Size = Vector3.new(1.0, 0.9, 1.5) * scale,
            Shape = Enum.PartType.Ball,
            Color = itemDef.PrimaryColor,
            Material = Enum.Material.Neon,
            Parent = model,
            CFrameOffset = CFrame.new(0, 0.1 * scale, -0.55 * scale),
            BaseCFrame = originCFrame,
        })
        for _, side in ipairs({ -1, 1 }) do
            makePart({
                Name = if side < 0 then "WingL" else "WingR",
                Size = Vector3.new(2.1, 0.18, 1.2) * scale,
                Color = itemDef.PrimaryColor,
                Material = Enum.Material.Neon,
                Transparency = 0.15,
                Parent = model,
                CFrameOffset = CFrame.new(side * 1.45 * scale, 0.4 * scale, 0.1 * scale)
                    * CFrame.Angles(0, 0, side * math.rad(22)),
                BaseCFrame = originCFrame,
            })
            makePart({
                Name = if side < 0 then "EyeL" else "EyeR",
                Size = Vector3.new(0.28, 0.28, 0.28) * scale,
                Shape = Enum.PartType.Ball,
                Color = Color3.fromRGB(255, 235, 85),
                Material = Enum.Material.Neon,
                Parent = model,
                CFrameOffset = CFrame.new(side * 0.42 * scale, 0.3 * scale, -1.05 * scale),
                BaseCFrame = originCFrame,
            })
        end
    elseif style == "TimeEater" or style == "ClockworkGear" then
        -- Floating golden timepiece with spinning counter-clockwise clock hands!
        makePart({
            Name = "ClockRim",
            Size = Vector3.new(0.55, 2.6, 2.6) * scale,
            Shape = Enum.PartType.Cylinder,
            Color = itemDef.PrimaryColor,
            Material = Enum.Material.Metal,
            Parent = model,
            CFrameOffset = CFrame.Angles(0, math.rad(90), 0),
            BaseCFrame = originCFrame,
        })
        makePart({
            Name = "TimeFace",
            Size = Vector3.new(0.65, 2.0, 2.0) * scale,
            Shape = Enum.PartType.Cylinder,
            Color = itemDef.SecondaryColor,
            Material = Enum.Material.Neon,
            Transparency = 0.2,
            Parent = model,
            CFrameOffset = CFrame.Angles(0, math.rad(90), 0),
            BaseCFrame = originCFrame,
        })
        local handA = makePart({
            Name = "MinuteHand",
            Size = Vector3.new(0.18, 1.0, 0.18) * scale,
            Color = Color3.fromRGB(25, 25, 45),
            Material = Enum.Material.SmoothPlastic,
            Parent = model,
            CFrameOffset = CFrame.new(0, 0.4 * scale, -0.38 * scale),
            BaseCFrame = originCFrame,
        })
        CollectionService:AddTag(handA, "ReverseClockHand")
    elseif style == "TheLastEye" then
        -- Mysterious floating eye that tracks nearest player!
        local eyeball = makePart({
            Name = "Sclera",
            Size = Vector3.new(2.3, 2.3, 2.3) * scale,
            Shape = Enum.PartType.Ball,
            Color = Color3.fromRGB(240, 235, 255),
            Material = Enum.Material.SmoothPlastic,
            Parent = model,
            BaseCFrame = originCFrame,
        })
        local iris = makePart({
            Name = "TrackingIris",
            Size = Vector3.new(1.25, 1.25, 0.6) * scale,
            Shape = Enum.PartType.Ball,
            Color = itemDef.PrimaryColor,
            Material = Enum.Material.Neon,
            Parent = model,
            CFrameOffset = CFrame.new(0, 0, -0.95 * scale),
            BaseCFrame = originCFrame,
        })
        makePart({
            Name = "VoidPupil",
            Size = Vector3.new(0.55, 0.95, 0.45) * scale,
            Shape = Enum.PartType.Ball,
            Color = Color3.fromRGB(10, 8, 22),
            Material = Enum.Material.SmoothPlastic,
            Parent = model,
            CFrameOffset = CFrame.new(0, 0, -1.16 * scale),
            BaseCFrame = originCFrame,
        })
        -- Orbiting Watcher Halo
        makePart({
            Name = "WatcherHalo",
            Size = Vector3.new(3.1, 0.22, 3.1) * scale,
            Color = itemDef.SecondaryColor,
            Material = Enum.Material.Neon,
            Transparency = 0.25,
            Parent = model,
            CFrameOffset = CFrame.Angles(math.rad(22), 0, math.rad(15)),
            BaseCFrame = originCFrame,
        })
        CollectionService:AddTag(eyeball, "TrackingEyeCore")
        CollectionService:AddTag(iris, "TrackingEyeIris")
    elseif style == "GalaxyEgg" then
        -- Shimmering cosmic egg with twin planetary rings!
        makePart({
            Name = "EggShell",
            Size = Vector3.new(2.1, 2.8, 2.1) * scale,
            Shape = Enum.PartType.Ball,
            Color = itemDef.PrimaryColor,
            Material = Enum.Material.Glass,
            Parent = model,
            BaseCFrame = originCFrame,
        })
        makePart({
            Name = "EggNebulaCore",
            Size = Vector3.new(1.5, 2.1, 1.5) * scale,
            Shape = Enum.PartType.Ball,
            Color = itemDef.SecondaryColor,
            Material = Enum.Material.Neon,
            Transparency = 0.25,
            Parent = model,
            BaseCFrame = originCFrame,
        })
        makePart({
            Name = "OrbitRing1",
            Size = Vector3.new(3.4, 0.16, 3.4) * scale,
            Color = Color3.fromRGB(0, 245, 255),
            Material = Enum.Material.Neon,
            Transparency = 0.2,
            Parent = model,
            CFrameOffset = CFrame.Angles(math.rad(28), 0, math.rad(18)),
            BaseCFrame = originCFrame,
        })
        makePart({
            Name = "OrbitRing2",
            Size = Vector3.new(3.1, 0.14, 3.1) * scale,
            Color = itemDef.SecondaryColor,
            Material = Enum.Material.Neon,
            Transparency = 0.25,
            Parent = model,
            CFrameOffset = CFrame.Angles(math.rad(-32), 0, math.rad(-22)),
            BaseCFrame = originCFrame,
        })
    elseif style == "CrownRelic" then
        makePart({
            Name = "CrownBase",
            Size = Vector3.new(0.7, 2.2, 2.2) * scale,
            Shape = Enum.PartType.Cylinder,
            Color = itemDef.PrimaryColor,
            Material = Enum.Material.Metal,
            Parent = model,
            CFrameOffset = CFrame.Angles(0, 0, math.rad(90)),
            BaseCFrame = originCFrame,
        })
        for i = 1, 4 do
            local ang = (i - 1) * (math.pi / 2)
            makePart({
                Name = "CrownJewel" .. tostring(i),
                Size = Vector3.new(0.45, 1.1, 0.45) * scale,
                Color = itemDef.SecondaryColor,
                Material = Enum.Material.Neon,
                Parent = model,
                CFrameOffset = CFrame.new(math.cos(ang) * 0.85 * scale, 0.65 * scale, math.sin(ang) * 0.85 * scale),
                BaseCFrame = originCFrame,
            })
        end
    else
        -- CrystalRelic / CubeArtifact / OrbSingularity / DragonTotem / VoidPrism
        local isCube = (style == "CubeArtifact")
        makePart({
            Name = "CoreShape",
            Size = Vector3.new(1.8, 1.8, 1.8) * scale,
            Shape = if isCube then Enum.PartType.Block else Enum.PartType.Ball,
            Color = itemDef.PrimaryColor,
            Material = Enum.Material.Neon,
            Parent = model,
            CFrameOffset = CFrame.Angles(math.rad(30), math.rad(45), 0),
            BaseCFrame = originCFrame,
        })
        makePart({
            Name = "OuterFrame",
            Size = Vector3.new(2.3, 2.3, 2.3) * scale,
            Shape = Enum.PartType.Block,
            Color = itemDef.SecondaryColor,
            Material = Enum.Material.Glass,
            Transparency = 0.45,
            Parent = model,
            CFrameOffset = CFrame.Angles(math.rad(-25), math.rad(20), math.rad(35)),
            BaseCFrame = originCFrame,
        })
    end

    local pColorA = if hasMutation then mutationDef.Color else itemDef.PrimaryColor
    local pColorB = if hasMutation then mutationDef.ParticleColor else itemDef.SecondaryColor
    attachParticles(root, pColorA, pColorB, isSecret or mutationId == "Celestial")

    if hasMutation then
        makePart({
            Name = "MutationRing",
            Size = Vector3.new(0.2, 3.6, 3.6) * scale,
            Shape = Enum.PartType.Cylinder,
            Color = mutationDef.Color,
            Material = Enum.Material.Neon,
            Transparency = 0.4,
            Parent = model,
            CFrameOffset = CFrame.new(0, -1.25 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
            BaseCFrame = originCFrame,
        })
    end

    if opts.ShowBillboard ~= false then
        local bb = Instance.new("BillboardGui")
        bb.Name = "ItemOverhead"
        bb.Size = UDim2.fromOffset(230, 72)
        bb.StudsOffset = Vector3.new(0, 3.3 * scale, 0)
        bb.AlwaysOnTop = false
        bb.MaxDistance = 95
        bb.Parent = root

        local bg = Instance.new("Frame")
        bg.Size = UDim2.fromScale(1, 1)
        bg.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
        bg.BackgroundTransparency = 0.18
        bg.BorderSizePixel = 0
        bg.Parent = bb

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = bg

        local stroke = Instance.new("UIStroke")
        stroke.Color = if hasMutation then mutationDef.Color else rarityInfo.Color
        stroke.Thickness = if isSecret or hasMutation then 2.4 else 1.6
        stroke.Parent = bg

        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1, -10, 0.38, 0)
        rarityLabel.Position = UDim2.fromOffset(5, 3)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Font = Enum.Font.GothamBlack
        rarityLabel.TextScaled = true
        rarityLabel.TextColor3 = rarityInfo.Color
        rarityLabel.Text = if hasMutation
            then (rarityInfo.DisplayName .. " • " .. mutationDef.DisplayName)
            else rarityInfo.DisplayName
        rarityLabel.Parent = bg

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -10, 0.52, 0)
        nameLabel.Position = UDim2.new(0, 5, 0.42, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.TextColor3 = if hasMutation then mutationDef.Color else Color3.fromRGB(248, 250, 255)
        nameLabel.Text = opts.CustomLabel or (itemDef.Icon .. " " .. mutationDef.Prefix .. itemDef.Name)
        nameLabel.Parent = bg
    end

    CollectionService:AddTag(model, "ImpossibleItemModel")
    return model
end

return ItemVisualBuilder
