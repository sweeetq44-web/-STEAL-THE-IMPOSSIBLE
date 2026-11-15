--!strict
-- Procedural 3D World Architecture for STEAL THE IMPOSSIBLE
-- Constructs:
--   * Central Plaza ("The Nexus Hub") with SpawnLocations, Leaderboard Monoliths & Rift Portal Arch
--   * 8 Symmetric Personal Bases (Base_1 .. Base_8) with Deposit Pads & Security Gates
--   * 5 Distinct Biomes with glowing Sky Bridges & Parkour Islands
--   * 15-Minute Special Rift Sky Arena
--   * Co-op Big Heist Vault with Synchronized Squad Locks

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GameConfig = require(Shared.GameConfig)
local BiomeConfig = require(Shared.BiomeConfig)
local BaseConfig = require(Shared.BaseConfig)

local WorldBuilder = {}

WorldBuilder.BiomeCenters = {} :: { [string]: Vector3 }
WorldBuilder.BaseFolders = {} :: { [number]: Folder }
WorldBuilder.LeaderboardBoards = {} :: { [string]: SurfaceGui }
WorldBuilder.RiftPortalRing = nil :: Part?
WorldBuilder.RiftArenaFolder = nil :: Folder?
WorldBuilder.HeistLockPlates = {} :: { Part }
WorldBuilder.HeistVaultDoor = nil :: Part?

local function createPart(props: {
    Name: string,
    Size: Vector3,
    CFrame: CFrame,
    Color: Color3,
    Material: Enum.Material?,
    Shape: Enum.PartType?,
    Transparency: number?,
    CanCollide: boolean?,
    Parent: Instance,
}): Part
    local p = Instance.new("Part")
    p.Name = props.Name
    p.Size = props.Size
    p.CFrame = props.CFrame
    p.Color = props.Color
    p.Material = props.Material or Enum.Material.SmoothPlastic
    p.Shape = props.Shape or Enum.PartType.Block
    p.Transparency = props.Transparency or 0
    p.Anchored = true
    p.CanCollide = if props.CanCollide == nil then true else props.CanCollide
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = props.Parent
    return p
end

local function createSurfaceSign(part: Part, title: string, accentColor: Color3, face: Enum.NormalId?)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "WorldSign"
    gui.Face = face or Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 22
    gui.Parent = part

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 4
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(0.92, 0.85)
    label.Position = UDim2.fromScale(0.04, 0.075)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.TextColor3 = Color3.fromRGB(248, 250, 255)
    label.TextScaled = true
    label.Text = title
    label.Parent = frame
end

local function createBridge(fromPos: Vector3, toPos: Vector3, width: number, color: Color3, accent: Color3, parent: Instance)
    local delta = toPos - fromPos
    local dist = delta.Magnitude
    local mid = fromPos + delta * 0.5
    local cf = CFrame.lookAt(mid, toPos)

    createPart({
        Name = "EnergyBridge",
        Size = Vector3.new(width, 2.5, dist),
        CFrame = cf * CFrame.new(0, -1.2, 0),
        Color = color,
        Material = Enum.Material.Metal,
        Parent = parent,
    })

    for _, side in ipairs({ -1, 1 }) do
        createPart({
            Name = "BridgeRail",
            Size = Vector3.new(0.8, 0.6, dist),
            CFrame = cf * CFrame.new(side * (width * 0.48), 0.3, 0),
            Color = accent,
            Material = Enum.Material.Neon,
            CanCollide = false,
            Parent = parent,
        })
    end
end

local function buildCentralPlaza(worldRoot: Folder)
    local plaza = Instance.new("Folder")
    plaza.Name = "CentralPlaza"
    plaza.Parent = worldRoot

    -- Outer safety ocean / void floor well beneath bridges
    createPart({
        Name = "VoidSeaFloor",
        Size = Vector3.new(1200, 4, 1200),
        CFrame = CFrame.new(0, -32, 0),
        Color = Color3.fromRGB(10, 14, 26),
        Material = Enum.Material.SmoothPlastic,
        Parent = plaza,
    })

    -- Main Circular Plaza Floor
    createPart({
        Name = "PlazaFloor",
        Size = Vector3.new(4, GameConfig.PLAZA_RADIUS * 2, GameConfig.PLAZA_RADIUS * 2),
        CFrame = CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Shape = Enum.PartType.Cylinder,
        Color = Color3.fromRGB(26, 31, 48),
        Material = Enum.Material.Marble,
        Parent = plaza,
    })

    createPart({
        Name = "PlazaNeonRing",
        Size = Vector3.new(0.6, GameConfig.PLAZA_RADIUS * 1.92, GameConfig.PLAZA_RADIUS * 1.92),
        CFrame = CFrame.new(0, 4.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Shape = Enum.PartType.Cylinder,
        Color = Color3.fromRGB(0, 235, 255),
        Material = Enum.Material.Neon,
        Transparency = 0.35,
        CanCollide = false,
        Parent = plaza,
    })

    -- Inner Plaza Spawn Ring (8 SpawnLocations)
    for i = 1, 8 do
        local ang = ((i - 1) / 8) * math.pi * 2
        local spawnPos = Vector3.new(math.cos(ang) * 24, 4.5, math.sin(ang) * 24)
        local sp = Instance.new("SpawnLocation")
        sp.Name = "HubSpawn_" .. tostring(i)
        sp.Size = Vector3.new(6, 1, 6)
        sp.CFrame = CFrame.lookAt(spawnPos, Vector3.new(0, 4.5, 0))
        sp.Anchored = true
        sp.Enabled = true
        sp.Neutral = true
        sp.Color = Color3.fromRGB(0, 215, 255)
        sp.Material = Enum.Material.Neon
        sp.Transparency = 0.25
        sp.Parent = plaza
    end

    -- 15-Minute Special Rift Portal Arch at Center (0, 12, 0)
    local portalFolder = Instance.new("Folder")
    portalFolder.Name = "SpecialRiftPortal"
    portalFolder.Parent = plaza

    -- Step ring around PortalPedestal so players walk straight in from PlazaFloor (Y=4 -> Y=6)
    createPart({
        Name = "PortalStep",
        Size = Vector3.new(26, 1.2, 26),
        CFrame = CFrame.new(0, 4.6, 0),
        Color = Color3.fromRGB(28, 34, 52),
        Material = Enum.Material.Metal,
        Parent = portalFolder,
    })

    createPart({
        Name = "PortalPedestal",
        Size = Vector3.new(20, 2, 20),
        CFrame = CFrame.new(0, 5, 0),
        Color = Color3.fromRGB(18, 22, 36),
        Material = Enum.Material.Obsidian,
        Parent = portalFolder,
    })

    -- 4 Diagonal Plaza Express Spokes (between Bases) straight to Outer Ring Highway
    for _, deg in ipairs({ 45, 135, 225, 315 }) do
        local rad = math.rad(deg)
        local dir = Vector3.new(math.cos(rad), 0, math.sin(rad))
        createBridge(
            dir * (GameConfig.PLAZA_RADIUS - 2) + Vector3.new(0, 4, 0),
            dir * 198 + Vector3.new(0, 5, 0),
            12,
            Color3.fromRGB(26, 32, 48),
            Color3.fromRGB(0, 235, 255),
            plaza
        )
    end

    for _, side in ipairs({ -1, 1 }) do
        createPart({
            Name = "PortalPillar",
            Size = Vector3.new(3, 22, 3),
            CFrame = CFrame.new(side * 9, 16, 0),
            Color = Color3.fromRGB(32, 38, 56),
            Material = Enum.Material.Metal,
            Parent = portalFolder,
        })
    end

    createPart({
        Name = "PortalCrown",
        Size = Vector3.new(22, 3, 4),
        CFrame = CFrame.new(0, 27, 0),
        Color = Color3.fromRGB(0, 255, 220),
        Material = Enum.Material.Neon,
        Parent = portalFolder,
    })

    local portalGate = createPart({
        Name = "PortalGateRing",
        Size = Vector3.new(15, 19, 1.5),
        CFrame = CFrame.new(0, 15.5, 0),
        Color = Color3.fromRGB(0, 255, 215),
        Material = Enum.Material.ForceField,
        Transparency = 0.85,
        CanCollide = false,
        Parent = portalFolder,
    })
    portalGate:SetAttribute("RiftPortalActive", false)
    WorldBuilder.RiftPortalRing = portalGate
    createSurfaceSign(portalGate, "15M SPECIAL RIFT\n[LOCKED]", Color3.fromRGB(0, 255, 220), Enum.NormalId.Front)

    -- 3D Plaza Global Leaderboard Monolith (Net Worth & Secret Hall of Fame)
    local boardData = {
        { Key = "NetWorth", Title = "🏆 GLOBAL RICHEST (NET WORTH)", Pos = Vector3.new(-38, 12, -38), Color = Color3.fromRGB(255, 205, 55) },
        { Key = "Secrets", Title = "✨ 0.01% SECRET COLLECTORS", Pos = Vector3.new(38, 12, -38), Color = Color3.fromRGB(0, 255, 245) },
    }
    for _, b in ipairs(boardData) do
        local monolith = createPart({
            Name = "LeaderboardMonolith_" .. b.Key,
            Size = Vector3.new(22, 14, 2.5),
            CFrame = CFrame.lookAt(b.Pos, Vector3.new(0, 12, 0)),
            Color = Color3.fromRGB(16, 20, 32),
            Material = Enum.Material.Metal,
            Parent = plaza,
        })

        local gui = Instance.new("SurfaceGui")
        gui.Name = "BoardGui"
        gui.Face = Enum.NormalId.Front
        gui.CanvasSize = Vector2.new(640, 400)
        gui.Parent = monolith

        local bg = Instance.new("Frame")
        bg.Size = UDim2.fromScale(1, 1)
        bg.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
        bg.BorderSizePixel = 0
        bg.Parent = gui

        local stroke = Instance.new("UIStroke")
        stroke.Color = b.Color
        stroke.Thickness = 5
        stroke.Parent = bg

        local header = Instance.new("TextLabel")
        header.Name = "Header"
        header.Size = UDim2.new(1, -20, 0.18, 0)
        header.Position = UDim2.fromOffset(10, 8)
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.GothamBlack
        header.TextColor3 = b.Color
        header.TextScaled = true
        header.Text = b.Title
        header.Parent = bg

        local body = Instance.new("TextLabel")
        body.Name = "Rows"
        body.Size = UDim2.new(1, -30, 0.78, 0)
        body.Position = UDim2.new(0, 15, 0.2, 0)
        body.BackgroundTransparency = 1
        body.Font = Enum.Font.GothamBold
        body.TextColor3 = Color3.fromRGB(235, 240, 255)
        body.TextSize = 24
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.Text = "Loading global rankings..."
        body.Parent = bg

        WorldBuilder.LeaderboardBoards[b.Key] = gui
    end

    -- Interactive Plaza Kiosks (Merchant, Promo Codes & Rebirth Shrine)
    local kiosks = {
        { Name = "MerchantKiosk", Title = "🍀 BLACK-MARKET\nMERCHANT", Pos = Vector3.new(-36, 8, 34), Color = Color3.fromRGB(48, 225, 138), Modal = "Quests" },
        { Name = "CodeTerminal", Title = "🎟️ PROMO CODES\n& DAILY QUESTS", Pos = Vector3.new(36, 8, 34), Color = Color3.fromRGB(0, 235, 255), Modal = "Quests" },
        { Name = "RebirthShrine", Title = "♻️ ASCENSION\nREBIRTH SHRINE", Pos = Vector3.new(0, 8, 48), Color = Color3.fromRGB(255, 205, 55), Modal = "Quests" },
    }
    for _, k in ipairs(kiosks) do
        local stall = createPart({
            Name = k.Name,
            Size = Vector3.new(10, 8, 6),
            CFrame = CFrame.lookAt(k.Pos, Vector3.new(0, 8, 0)),
            Color = Color3.fromRGB(22, 26, 42),
            Material = Enum.Material.Metal,
            Parent = plaza,
        })
        stall:SetAttribute("KioskPanel", k.Modal)
        CollectionService:AddTag(stall, "PlazaKiosk")
        createSurfaceSign(stall, k.Title, k.Color, Enum.NormalId.Front)

        local kPrompt = Instance.new("ProximityPrompt")
        kPrompt.Name = "KioskPrompt"
        kPrompt.ActionText = "Open"
        kPrompt.ObjectText = k.Name
        kPrompt.HoldDuration = 0
        kPrompt.MaxActivationDistance = 14
        kPrompt.Parent = stall
    end
end

local function buildEightBases(worldRoot: Folder)
    local basesRoot = Instance.new("Folder")
    basesRoot.Name = "PlayerBases"
    basesRoot.Parent = worldRoot

    for slotIndex = 1, GameConfig.MAX_PLAYERS do
        local baseCF = BaseConfig.GetSlotCFrame(slotIndex)
        local basePos = baseCF.Position
        createBridge(
            basePos.Unit * (GameConfig.PLAZA_RADIUS - 2) + Vector3.new(0, 4, 0),
            basePos + baseCF.LookVector * 26,
            12,
            Color3.fromRGB(32, 38, 54),
            Color3.fromRGB(95, 185, 255),
            basesRoot
        )

        -- Outer Ring Highway Bridge segment connecting around the 8 Bases at radius 196
        local a1 = ((slotIndex - 1) / GameConfig.MAX_PLAYERS) * math.pi * 2
        local a2 = (slotIndex / GameConfig.MAX_PLAYERS) * math.pi * 2
        local p1 = Vector3.new(math.cos(a1) * 196, 5, math.sin(a1) * 196)
        local p2 = Vector3.new(math.cos(a2) * 196, 5, math.sin(a2) * 196)
        createBridge(p1, p2, 16, Color3.fromRGB(28, 34, 52), Color3.fromRGB(0, 225, 255), basesRoot)

        -- Connect Base rear flank to Outer Ring Highway for smooth escape routes
        createBridge(
            basePos - baseCF.LookVector * 26,
            basePos.Unit * 196 + Vector3.new(0, 1, 0),
            12,
            Color3.fromRGB(32, 38, 54),
            Color3.fromRGB(95, 185, 255),
            basesRoot
        )

        local folder = Instance.new("Folder")
        folder.Name = "Base_" .. tostring(slotIndex)
        folder:SetAttribute("BaseSlot", slotIndex)
        folder.Parent = basesRoot

        -- Base Floor Platform
        createPart({
            Name = "BaseFloor",
            Size = Vector3.new(54, 2, 54),
            CFrame = baseCF,
            Color = Color3.fromRGB(24, 28, 42),
            Material = Enum.Material.SmoothPlastic,
            Parent = folder,
        })

        -- Glowing Extraction / Deposit Pad near entrance
        local depositPad = createPart({
            Name = "DepositPad",
            Size = Vector3.new(14, 0.8, 12),
            CFrame = baseCF * CFrame.new(0, 1.3, -17),
            Color = Color3.fromRGB(45, 255, 145),
            Material = Enum.Material.Neon,
            CanCollide = false,
            Parent = folder,
        })
        depositPad:SetAttribute("BaseSlot", slotIndex)
        CollectionService:AddTag(depositPad, "BaseDepositPad")

        -- Security Laser Shield Gate across entrance
        local gate = createPart({
            Name = "SecurityGate",
            Size = Vector3.new(26, 12, 1.5),
            CFrame = baseCF * CFrame.new(0, 7, -26.5),
            Color = Color3.fromRGB(65, 195, 255),
            Material = Enum.Material.ForceField,
            Transparency = 0.65,
            CanCollide = false,
            Parent = folder,
        })
        gate:SetAttribute("BaseSlot", slotIndex)
        CollectionService:AddTag(gate, "BaseSecurityGate")

        -- Side perimeter walls
        for _, side in ipairs({ -1, 1 }) do
            createPart({
                Name = "SideWall_" .. tostring(side),
                Size = Vector3.new(2, 10, 54),
                CFrame = baseCF * CFrame.new(side * 26, 6, 0),
                Color = Color3.fromRGB(34, 40, 58),
                Material = Enum.Material.Metal,
                Parent = folder,
            })
        end

        createPart({
            Name = "BackWall",
            Size = Vector3.new(54, 12, 2),
            CFrame = baseCF * CFrame.new(0, 7, 26),
            Color = Color3.fromRGB(34, 40, 58),
            Material = Enum.Material.Metal,
            Parent = folder,
        })

        local signPart = createPart({
            Name = "OwnerSign",
            Size = Vector3.new(22, 6, 1.5),
            CFrame = baseCF * CFrame.new(0, 15, -26),
            Color = Color3.fromRGB(16, 20, 34),
            Material = Enum.Material.Metal,
            Parent = folder,
        })
        createSurfaceSign(signPart, "BASE #" .. tostring(slotIndex) .. "\nUNCLAIMED", Color3.fromRGB(95, 185, 255), Enum.NormalId.Front)

        -- Pre-place 24 Flex Showcase Pedestal anchors (activated progressively by BaseTier 1..5)
        local pedestalsFolder = Instance.new("Folder")
        pedestalsFolder.Name = "Pedestals"
        pedestalsFolder.Parent = folder

        for pIdx = 1, 24 do
            local row = math.floor((pIdx - 1) / 4)
            local col = (pIdx - 1) % 4
            local offsetX = (col - 1.5) * 10.5
            local offsetZ = -6 + row * 5.8
            local pedestal = createPart({
                Name = "Pedestal_" .. tostring(pIdx),
                Size = Vector3.new(4.2, 2.2, 4.2),
                CFrame = baseCF * CFrame.new(offsetX, 2.1, offsetZ),
                Color = Color3.fromRGB(38, 44, 66),
                Material = Enum.Material.Marble,
                Transparency = if pIdx <= 4 then 0 else 1,
                CanCollide = if pIdx <= 4 then true else false,
                Parent = pedestalsFolder,
            })
            pedestal:SetAttribute("PedestalIndex", pIdx)
            pedestal:SetAttribute("BaseSlot", slotIndex)
            CollectionService:AddTag(pedestal, "FlexPedestal")
        end

        -- Raidable Cash Safe inside Base corner (protects via Base Shield; High-Stakes doubles passive rate!)
        local raidSafe = createPart({
            Name = "RaidSafe",
            Size = Vector3.new(6, 6, 6),
            CFrame = baseCF * CFrame.new(-19, 4, -17),
            Color = Color3.fromRGB(255, 200, 55),
            Material = Enum.Material.Metal,
            Parent = folder,
        })
        raidSafe:SetAttribute("BaseSlot", slotIndex)
        CollectionService:AddTag(raidSafe, "BaseRaidSafe")
        createSurfaceSign(raidSafe, "VAULT SAFE\n$0", Color3.fromRGB(255, 205, 55), Enum.NormalId.Front)

        local safePrompt = Instance.new("ProximityPrompt")
        safePrompt.Name = "SafePrompt"
        safePrompt.ActionText = "Collect / Raid Safe"
        safePrompt.ObjectText = "Base #" .. tostring(slotIndex) .. " Safe"
        safePrompt.HoldDuration = 0.4
        safePrompt.MaxActivationDistance = 12
        safePrompt.Parent = raidSafe

        WorldBuilder.BaseFolders[slotIndex] = folder
    end
end

local function buildBiomesAndVault(worldRoot: Folder)
    local biomesFolder = Instance.new("Folder")
    biomesFolder.Name = "WorldBiomes"
    biomesFolder.Parent = worldRoot

    for _, biome in ipairs(BiomeConfig.Biomes) do
        local center = BiomeConfig.GetBiomePosition(biome)
        WorldBuilder.BiomeCenters[biome.Id] = center

        local bFolder = Instance.new("Folder")
        bFolder.Name = biome.Id
        bFolder.Parent = biomesFolder

        -- Main Biome Platform
        createPart({
            Name = "BiomePlatform",
            Size = biome.PlatformSize,
            CFrame = CFrame.new(center),
            Color = biome.PrimaryColor,
            Material = biome.FloorMaterial,
            Parent = bFolder,
        })

        -- Glowing Biome Trim & Corner Pillars
        for _, sx in ipairs({ -1, 1 }) do
            for _, sz in ipairs({ -1, 1 }) do
                createPart({
                    Name = "BiomeObelisk",
                    Size = Vector3.new(6, 36, 6),
                    CFrame = CFrame.new(center + Vector3.new(sx * 52, 18, sz * 52)),
                    Color = biome.AccentColor,
                    Material = Enum.Material.Neon,
                    Transparency = 0.2,
                    Parent = bFolder,
                })
            end
        end

        -- Center Biome Landmark Altar
        local altar = createPart({
            Name = "BiomeAltar",
            Size = Vector3.new(18, 4, 18),
            CFrame = CFrame.new(center + Vector3.new(0, 6, 0)),
            Color = biome.AccentColor,
            Material = Enum.Material.Neon,
            Transparency = 0.35,
            Parent = bFolder,
        })
        createSurfaceSign(altar, biome.Name:upper(), biome.AccentColor, Enum.NormalId.Top)

        -- Biome-Specific 3D Landmarks & Jump Pads
        local jumpPad = createPart({
            Name = "BiomeJumpPad",
            Size = Vector3.new(8, 1, 8),
            CFrame = CFrame.new(center + Vector3.new(0, 4.6, 36)),
            Color = Color3.fromRGB(0, 255, 215),
            Material = Enum.Material.Neon,
            CanCollide = false,
            Parent = bFolder,
        })
        jumpPad:SetAttribute("LaunchPower", 95)
        CollectionService:AddTag(jumpPad, "JumpPad")

        if biome.Id == "FrostCitadel" then
            for i = 1, 4 do
                local ang = i * (math.pi / 2)
                createPart({
                    Name = "IceSpire_" .. tostring(i),
                    Size = Vector3.new(7, 34, 7),
                    CFrame = CFrame.new(center + Vector3.new(math.cos(ang) * 32, 18, math.sin(ang) * 32))
                        * CFrame.Angles(math.rad(14), ang, math.rad(10)),
                    Color = Color3.fromRGB(165, 238, 255),
                    Material = Enum.Material.Ice,
                    Transparency = 0.2,
                    Parent = bFolder,
                })
            end
        elseif biome.Id == "AbyssalCaldera" then
            createPart({
                Name = "MagmaCraterPool",
                Size = Vector3.new(1.5, 42, 42),
                CFrame = CFrame.new(center + Vector3.new(0, 4.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
                Shape = Enum.PartType.Cylinder,
                Color = Color3.fromRGB(255, 85, 25),
                Material = Enum.Material.Neon,
                CanCollide = false,
                Parent = bFolder,
            })
        elseif biome.Id == "ChronosRuins" then
            createPart({
                Name = "ChronosGiantRing",
                Size = Vector3.new(3, 46, 46),
                CFrame = CFrame.new(center + Vector3.new(0, 28, 0)) * CFrame.Angles(math.rad(20), 0, 0),
                Shape = Enum.PartType.Cylinder,
                Color = Color3.fromRGB(255, 210, 90),
                Material = Enum.Material.Metal,
                Transparency = 0.35,
                CanCollide = false,
                Parent = bFolder,
            })
        elseif biome.Id == "WatchersSanctum" then
            local statueBase = createPart({
                Name = "WatcherTower",
                Size = Vector3.new(12, 34, 12),
                CFrame = CFrame.new(center + Vector3.new(0, 20, -34)),
                Color = Color3.fromRGB(32, 20, 56),
                Material = Enum.Material.Slate,
                Parent = bFolder,
            })
            local giantIris = createPart({
                Name = "GiantWatcherEye",
                Size = Vector3.new(9, 9, 9),
                Shape = Enum.PartType.Ball,
                CFrame = statueBase.CFrame * CFrame.new(0, 20, 0),
                Color = Color3.fromRGB(215, 75, 255),
                Material = Enum.Material.Neon,
                Parent = bFolder,
            })
            CollectionService:AddTag(giantIris, "TrackingEyeIris")
        elseif biome.Id == "AstralVoid" then
            createPart({
                Name = "AstralUpperIsland",
                Size = Vector3.new(34, 3, 34),
                CFrame = CFrame.new(center + Vector3.new(0, 28, 0)),
                Color = Color3.fromRGB(48, 38, 105),
                Material = Enum.Material.Neon,
                Transparency = 0.25,
                Parent = bFolder,
            })
        end

        -- Connect Outer Ring Highway outward to Biome
        local flatDir = Vector3.new(center.X, 0, center.Z).Unit
        createBridge(
            flatDir * 194 + Vector3.new(0, 5, 0),
            center - flatDir * 58 + Vector3.new(0, 4, 0),
            16,
            biome.PrimaryColor,
            biome.AccentColor,
            bFolder
        )
    end

    -- 15-Minute Special Rift Sky Arena
    local riftFolder = Instance.new("Folder")
    riftFolder.Name = "SpecialRiftArena"
    riftFolder.Parent = worldRoot

    local riftPos = GameConfig.RIFT_ARENA_POSITION
    createPart({
        Name = "RiftPlatform",
        Size = Vector3.new(110, 4, 110),
        CFrame = CFrame.new(riftPos),
        Color = Color3.fromRGB(20, 28, 38),
        Material = Enum.Material.Glass,
        Transparency = 0.15,
        Parent = riftFolder,
    })

    local exitPad = createPart({
        Name = "RiftReturnPad",
        Size = Vector3.new(14, 1, 14),
        CFrame = CFrame.new(riftPos + Vector3.new(0, 2.5, 42)),
        Color = Color3.fromRGB(0, 255, 215),
        Material = Enum.Material.Neon,
        CanCollide = false,
        Parent = riftFolder,
    })
    CollectionService:AddTag(exitPad, "RiftReturnPad")
    WorldBuilder.RiftArenaFolder = riftFolder

    -- Co-op Big Heist Facility ("THE IMPOSSIBLE VAULT")
    local vaultFolder = Instance.new("Folder")
    vaultFolder.Name = "BigHeistVault"
    vaultFolder.Parent = worldRoot

    local vPos = GameConfig.VAULT_POSITION
    createBridge(
        Vector3.new(0, 5, -194),
        vPos + Vector3.new(0, 3, 52),
        18,
        Color3.fromRGB(36, 36, 48),
        Color3.fromRGB(255, 200, 55),
        vaultFolder
    )

    createPart({
        Name = "VaultFloor",
        Size = Vector3.new(105, 6, 105),
        CFrame = CFrame.new(vPos),
        Color = Color3.fromRGB(24, 24, 34),
        Material = Enum.Material.Metal,
        Parent = vaultFolder,
    })

    local vaultDoor = createPart({
        Name = "VaultSecurityDoor",
        Size = Vector3.new(26, 18, 3),
        CFrame = CFrame.new(vPos + Vector3.new(0, 12, 8)),
        Color = Color3.fromRGB(255, 185, 45),
        Material = Enum.Material.DiamondPlate,
        Parent = vaultFolder,
    })
    WorldBuilder.HeistVaultDoor = vaultDoor
    createSurfaceSign(vaultDoor, "CO-OP BIG HEIST VAULT\nSTEP ON ALL PLATES TOGETHER!", Color3.fromRGB(255, 205, 55), Enum.NormalId.Front)

    -- Interior Treasure Room Stacks behind Vault Door
    for bx = -14, 14, 14 do
        createPart({
            Name = "GoldBullionStack_" .. tostring(bx),
            Size = Vector3.new(8, 5, 10),
            CFrame = CFrame.new(vPos + Vector3.new(bx, 5.5, -24)),
            Color = Color3.fromRGB(255, 215, 55),
            Material = Enum.Material.Metal,
            Parent = vaultFolder,
        })
    end

    -- 2 Synchronized Co-op Heist Security Plates outside the vault door
    WorldBuilder.HeistLockPlates = {}
    for idx, xOff in ipairs({ -18, 18 }) do
        local plate = createPart({
            Name = "HeistLockPlate_" .. tostring(idx),
            Size = Vector3.new(10, 1, 10),
            CFrame = CFrame.new(vPos + Vector3.new(xOff, 3.5, 24)),
            Color = Color3.fromRGB(255, 65, 75),
            Material = Enum.Material.Neon,
            CanCollide = false,
            Parent = vaultFolder,
        })
        plate:SetAttribute("PlateIndex", idx)
        CollectionService:AddTag(plate, "HeistLockPlate")
        table.insert(WorldBuilder.HeistLockPlates, plate)
    end
end

function WorldBuilder.BuildIfMissing()
    local existing = Workspace:FindFirstChild("GameWorld")
    if existing and existing:IsA("Folder") then
        -- Hydrate centers for pre-built worlds
        for _, biome in ipairs(BiomeConfig.Biomes) do
            WorldBuilder.BiomeCenters[biome.Id] = BiomeConfig.GetBiomePosition(biome)
        end
        return
    end

    local worldRoot = Instance.new("Folder")
    worldRoot.Name = "GameWorld"
    worldRoot.Parent = Workspace

    -- Container folders for dynamic runtime spawns
    local worldItems = Instance.new("Folder")
    worldItems.Name = "WorldItems"
    worldItems.Parent = worldRoot

    local worldEvents = Instance.new("Folder")
    worldEvents.Name = "WorldEventFX"
    worldEvents.Parent = worldRoot

    buildCentralPlaza(worldRoot)
    buildEightBases(worldRoot)
    buildBiomesAndVault(worldRoot)
end

return WorldBuilder
