--!strict
-- Weighted Item Spawning Service (Biomes, 15m Special Rift, World Ending Bonus & 0.01% Secrets)

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local GameConfig = require(Shared.GameConfig)
local RarityConfig = require(Shared.RarityConfig)
local MutationConfig = require(Shared.MutationConfig)
local ItemCatalog = require(Shared.ItemCatalog)
local BiomeConfig = require(Shared.BiomeConfig)
local Utils = require(Shared.Utils)

local WorldBuilder = require(script.Parent.WorldBuilder)
local ItemVisualBuilder = require(script.Parent.ItemVisualBuilder)

export type WorldSpawnNode = {
    Uid: string,
    ItemDef: Types.ItemDefinition,
    Mutation: Types.MutationId,
    BiomeId: string,
    Position: Vector3,
    Model: Model?,
    SpawnedAt: number,
    IsDropped: boolean,
}

local ItemSpawnService = {}
ItemSpawnService._activeNodes = {} :: { [string]: WorldSpawnNode }
ItemSpawnService._rng = Random.new()
ItemSpawnService._onPickupCallback = nil :: ((player: Player, node: WorldSpawnNode) -> ())?
ItemSpawnService._riftOpenCheck = nil :: (() -> (boolean, number))?
ItemSpawnService._worldEventLuckBonus = 1.0

function ItemSpawnService.SetPickupCallback(cb: (player: Player, node: WorldSpawnNode) -> ())
    ItemSpawnService._onPickupCallback = cb
end

function ItemSpawnService.SetRiftCheck(fn: () -> (boolean, number))
    ItemSpawnService._riftOpenCheck = fn
end

function ItemSpawnService.SetWorldEventLuckBonus(mult: number)
    ItemSpawnService._worldEventLuckBonus = math.max(1.0, mult)
end

function ItemSpawnService.GetActiveNodes(): { [string]: WorldSpawnNode }
    return ItemSpawnService._activeNodes
end

function ItemSpawnService.GetRarestActiveNode(): WorldSpawnNode?
    local best: WorldSpawnNode? = nil
    local bestOrder = -1
    local bestValue = -1
    for _, node in pairs(ItemSpawnService._activeNodes) do
        local order = RarityConfig.Get(node.ItemDef.Rarity).Order
        if order > bestOrder or (order == bestOrder and node.ItemDef.BaseCashValue > bestValue) then
            bestOrder = order
            bestValue = node.ItemDef.BaseCashValue
            best = node
        end
    end
    return best
end

function ItemSpawnService.RemoveWorldNode(uid: string)
    local node = ItemSpawnService._activeNodes[uid]
    if not node then
        return
    end
    if node.Model then
        node.Model:Destroy()
        node.Model = nil
    end
    ItemSpawnService._activeNodes[uid] = nil
end

function ItemSpawnService.SpawnSpecificItemAt(
    itemDef: Types.ItemDefinition,
    worldPos: Vector3,
    biomeId: string,
    isDropped: boolean?,
    mutationOverride: Types.MutationId?
): WorldSpawnNode
    local uid = Utils.GenerateUid("spawn")
    local worldRoot = Workspace:FindFirstChild("GameWorld")
    local itemsFolder = if worldRoot then worldRoot:FindFirstChild("WorldItems") else Workspace

    local mut: Types.MutationId = mutationOverride or "Normal"
    local mutDef = MutationConfig.Get(mut)
    local cf = CFrame.new(worldPos)
    local model = ItemVisualBuilder.BuildItemModel(itemDef, cf, { Scale = 1.0, ShowBillboard = true, Mutation = mut })
    model.Name = "WorldItem_" .. uid
    model:SetAttribute("SpawnUid", uid)
    model:SetAttribute("BiomeId", biomeId)
    model:SetAttribute("Mutation", mut)

    -- Attach interactive ProximityPrompt for server-validated pickup
    local primary = model.PrimaryPart
    if primary then
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "StealPickupPrompt"
        prompt.ActionText = "Grab " .. mutDef.Prefix .. itemDef.Name
        prompt.ObjectText = RarityConfig.Get(itemDef.Rarity).DisplayName
        prompt.HoldDuration = if itemDef.Rarity == "Secret" or itemDef.Rarity == "Impossible" then 0.35 else 0.15
        prompt.MaxActivationDistance = 11
        prompt.RequiresLineOfSight = false
        prompt.Parent = primary

        prompt.Triggered:Connect(function(player: Player)
            local node = ItemSpawnService._activeNodes[uid]
            if not node then
                return
            end
            if ItemSpawnService._onPickupCallback then
                ItemSpawnService._onPickupCallback(player, node)
            end
        end)
    end

    model.Parent = itemsFolder or Workspace

    local node: WorldSpawnNode = {
        Uid = uid,
        ItemDef = itemDef,
        Mutation = mut,
        BiomeId = biomeId,
        Position = worldPos,
        Model = model,
        SpawnedAt = os.time(),
        IsDropped = isDropped == true,
    }
    ItemSpawnService._activeNodes[uid] = node
    return node
end

function ItemSpawnService.SpawnInBiome(biomeId: string, luckMultiplier: number?): WorldSpawnNode?
    local center = WorldBuilder.BiomeCenters[biomeId]
    if biomeId == "SpecialRift" then
        center = GameConfig.RIFT_ARENA_POSITION + Vector3.new(0, 5, 0)
    end
    if not center then
        return nil
    end

    local totalLuck = (luckMultiplier or 1.0) * ItemSpawnService._worldEventLuckBonus
    local rolledRarity = RarityConfig.RollRarity(totalLuck, ItemSpawnService._rng)
    local pool = ItemCatalog.GetPool(biomeId, rolledRarity)
    local chosen = Utils.PickRandom(pool, ItemSpawnService._rng)
    if not chosen then
        return nil
    end

    local mutLuck = if biomeId == "SpecialRift" then totalLuck * 1.5 else totalLuck
    local rolledMutation = MutationConfig.RollMutation(mutLuck, ItemSpawnService._rng)

    local offsetX = ItemSpawnService._rng:NextNumber(-44, 44)
    local offsetZ = ItemSpawnService._rng:NextNumber(-44, 44)
    local spawnPos = center + Vector3.new(offsetX, 6.5, offsetZ)
    return ItemSpawnService.SpawnSpecificItemAt(chosen, spawnPos, biomeId, false, rolledMutation)
end

function ItemSpawnService.ClearBiomeSpawns(biomeId: string)
    for uid, node in pairs(ItemSpawnService._activeNodes) do
        if node.BiomeId == biomeId and not node.IsDropped then
            ItemSpawnService.RemoveWorldNode(uid)
        end
    end
end

function ItemSpawnService.CountInBiome(biomeId: string): number
    local count = 0
    for _, node in pairs(ItemSpawnService._activeNodes) do
        if node.BiomeId == biomeId and not node.IsDropped then
            count += 1
        end
    end
    return count
end

function ItemSpawnService.StepSpawner()
    local now = os.time()

    -- Expire dropped world items that nobody grabbed within despawn window
    for uid, node in pairs(ItemSpawnService._activeNodes) do
        if node.IsDropped and (now - node.SpawnedAt) >= GameConfig.WORLD_DROP_DESPAWN_SECONDS then
            ItemSpawnService.RemoveWorldNode(uid)
        end
    end

    -- Replenish permanent biomes
    for _, biome in ipairs(BiomeConfig.Biomes) do
        local current = ItemSpawnService.CountInBiome(biome.Id)
        if current < GameConfig.MAX_WORLD_ITEMS_PER_BIOME then
            ItemSpawnService.SpawnInBiome(biome.Id, biome.LuckMultiplier)
        end
    end

    -- Replenish 15-min Special Rift Dimension if active
    if ItemSpawnService._riftOpenCheck then
        local isOpen, riftLuck = ItemSpawnService._riftOpenCheck()
        if isOpen then
            local riftCount = ItemSpawnService.CountInBiome("SpecialRift")
            if riftCount < GameConfig.MAX_RIFT_ITEMS then
                ItemSpawnService.SpawnInBiome("SpecialRift", riftLuck)
            end
        end
    end
end

function ItemSpawnService.Start()
    -- Initial world seed across all 5 biomes
    for _, biome in ipairs(BiomeConfig.Biomes) do
        for _ = 1, GameConfig.MAX_WORLD_ITEMS_PER_BIOME do
            ItemSpawnService.SpawnInBiome(biome.Id, biome.LuckMultiplier)
        end
    end

    task.spawn(function()
        while true do
            task.wait(GameConfig.SPAWN_TICK_SECONDS)
            ItemSpawnService.StepSpawner()
        end
    end)
end

return ItemSpawnService
