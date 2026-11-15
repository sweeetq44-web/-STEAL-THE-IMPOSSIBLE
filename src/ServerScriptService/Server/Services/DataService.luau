--!strict
-- Persistent Player Profile Management (DataStoreService + Retry + BindToClose + Leaderstats)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local GameConfig = require(Shared.GameConfig)
local ItemCatalog = require(Shared.ItemCatalog)
local BaseConfig = require(Shared.BaseConfig)
local QuestAndCodeConfig = require(Shared.QuestAndCodeConfig)
local Utils = require(Shared.Utils)

local DataService = {}
DataService._profiles = {} :: { [number]: Types.PlayerProfile }
DataService._dirty = {} :: { [number]: boolean }
DataService._saving = {} :: { [number]: boolean }
DataService._store = nil :: any

local PROFILE_VERSION = 2

local function currentDayKey(): number
    return math.floor(os.time() / 86400)
end

function DataService.CreateDefaultProfile(): Types.PlayerProfile
    return {
        Version = PROFILE_VERSION,
        Cash = GameConfig.STARTING_CASH,
        TotalEarned = GameConfig.STARTING_CASH,
        TotalSteals = 0,
        TotalExtracted = 0,
        SecretCount = 0,
        Rebirths = 0,
        BaseTier = 1,
        HighStakesMode = false,
        UncollectedSafeCash = 0,
        TechLevels = {
            carry_boots = 0,
            tackle_reach = 0,
            vault_multiplier = 0,
        },
        OwnedGadgets = {},
        VaultItems = {},
        DiscoveredItems = {},
        DiscoveredSecrets = {},
        OwnedProducts = {},
        RedeemedCodes = {},
        QuestDayKey = currentDayKey(),
        QuestProgress = {
            Extracted = 0,
            Steals = 0,
            Likes = 0,
            Heists = 0,
        },
        ClaimedQuests = {},
        ActiveBuffs = {
            LuckUntil = 0,
            FeatherUntil = 0,
            ShadowCloakUntil = 0,
        },
        EquippedCosmetics = {
            CharacterSkin = nil,
            BaseDesign = nil,
            AnimationPack = nil,
            PetSkin = nil,
            VipTagEnabled = false,
        },
        TotalBaseLikes = 0,
        LikedPlayerTargets = {},
        PreferredLanguage = "en",
        LastSavedAt = os.time(),
    }
end

function DataService.EnsureDailyQuestReset(profile: Types.PlayerProfile)
    local today = currentDayKey()
    if profile.QuestDayKey ~= today then
        profile.QuestDayKey = today
        profile.QuestProgress = {
            Extracted = 0,
            Steals = 0,
            Likes = 0,
            Heists = 0,
        }
        profile.ClaimedQuests = {}
    end
end

local function reconcileProfile(raw: any): Types.PlayerProfile
    local defaults = DataService.CreateDefaultProfile()
    if type(raw) ~= "table" then
        return defaults
    end
    for k, v in pairs(defaults :: any) do
        if raw[k] == nil then
            raw[k] = Utils.DeepCopy(v)
        elseif type(v) == "table" and type(raw[k]) == "table" and k ~= "VaultItems" then
            for subK, subV in pairs(v) do
                if raw[k][subK] == nil then
                    raw[k][subK] = Utils.DeepCopy(subV)
                end
            end
        end
    end
    raw.Version = PROFILE_VERSION
    DataService.EnsureDailyQuestReset(raw)
    return raw :: Types.PlayerProfile
end

function DataService.GetRebirthIncomeMultiplier(profile: Types.PlayerProfile): number
    return 1 + (profile.Rebirths or 0) * QuestAndCodeConfig.REBIRTH_INCOME_BONUS_PER_LEVEL
end

function DataService.GetBiomeMasteryMultiplier(profile: Types.PlayerProfile): number
    local mastered = ItemCatalog.GetMasteredBiomeCount(profile.DiscoveredItems)
    return 1 + mastered * 0.15
end

function DataService.GetPlayerLuckMultiplier(player: Player): number
    local profile = DataService._profiles[player.UserId]
    if not profile then
        return 1.0
    end
    local mult = 1.0 + (profile.Rebirths or 0) * QuestAndCodeConfig.REBIRTH_LUCK_BONUS_PER_LEVEL
    mult += ItemCatalog.GetMasteredBiomeCount(profile.DiscoveredItems) * 0.15
    if (profile.ActiveBuffs.LuckUntil or 0) > os.time() then
        mult = mult * 2.0
    end
    return mult
end

function DataService.ComputeNetWorth(profile: Types.PlayerProfile): number
    local total = math.floor(profile.Cash + (profile.UncollectedSafeCash or 0))
    for _, inst in ipairs(profile.VaultItems) do
        local def = ItemCatalog.Get(inst.ItemId)
        if def then
            local mult = ItemCatalog.GetInstanceMultiplier(inst)
            total += math.floor(def.BaseCashValue * mult)
        end
    end
    return total
end

function DataService.ComputePassiveIncomePerSec(profile: Types.PlayerProfile): number
    local tierDef = BaseConfig.GetTier(profile.BaseTier)
    local baseSum = 0
    for _, inst in ipairs(profile.VaultItems) do
        local def = ItemCatalog.Get(inst.ItemId)
        if def then
            -- Flexed pedestal items generate 100% passive income; vault storage items generate 35%
            local slotFactor = if inst.PedestalSlot ~= nil then 1.0 else 0.35
            local mult = ItemCatalog.GetInstanceMultiplier(inst)
            baseSum += def.PassiveIncomePerSec * slotFactor * mult
        end
    end
    local rebirthMult = DataService.GetRebirthIncomeMultiplier(profile)
    local masteryMult = DataService.GetBiomeMasteryMultiplier(profile)
    local highStakesMult = if profile.HighStakesMode then 2.0 else 1.0
    return math.floor(baseSum * tierDef.IncomeMultiplier * rebirthMult * masteryMult * highStakesMult)
end

local function getStore(): any
    if DataService._store ~= nil then
        return DataService._store
    end
    local ok, ds = pcall(function()
        return DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)
    end)
    if ok then
        DataService._store = ds
        return ds
    end
    return nil
end

function DataService.LoadPlayer(player: Player): Types.PlayerProfile
    local userId = player.UserId
    local key = "player_" .. tostring(userId)
    local profile: Types.PlayerProfile? = nil

    local store = getStore()
    if store ~= nil then
        for attempt = 1, 3 do
            local ok, res = pcall(function()
                return store:GetAsync(key)
            end)
            if ok then
                profile = reconcileProfile(res)
                break
            else
                if RunService:IsStudio() then
                    break
                end
                task.wait(0.5 * attempt)
            end
        end
    end

    if not profile then
        profile = DataService.CreateDefaultProfile()
    end

    local resolved = profile :: Types.PlayerProfile
    DataService._profiles[userId] = resolved
    DataService._dirty[userId] = false
    DataService.SyncLeaderstats(player)
    return resolved
end

function DataService.GetProfile(player: Player): Types.PlayerProfile?
    return DataService._profiles[player.UserId]
end

function DataService.GetProfileByUserId(userId: number): Types.PlayerProfile?
    return DataService._profiles[userId]
end

function DataService.MarkDirty(player: Player)
    DataService._dirty[player.UserId] = true
    DataService.SyncLeaderstats(player)
end

function DataService.SyncLeaderstats(player: Player)
    local profile = DataService._profiles[player.UserId]
    if not profile then
        return
    end
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player

        local cashVal = Instance.new("NumberValue")
        cashVal.Name = "Cash"
        cashVal.Parent = leaderstats

        local worthVal = Instance.new("NumberValue")
        worthVal.Name = "NetWorth"
        worthVal.Parent = leaderstats

        local stealsVal = Instance.new("IntValue")
        stealsVal.Name = "Steals"
        stealsVal.Parent = leaderstats

        local rebirthVal = Instance.new("IntValue")
        rebirthVal.Name = "Rebirths"
        rebirthVal.Parent = leaderstats
    end

    local cashObj = leaderstats:FindFirstChild("Cash") :: NumberValue?
    local worthObj = leaderstats:FindFirstChild("NetWorth") :: NumberValue?
    local stealsObj = leaderstats:FindFirstChild("Steals") :: IntValue?
    local rebirthObj = leaderstats:FindFirstChild("Rebirths") :: IntValue?
    if cashObj then
        cashObj.Value = math.floor(profile.Cash)
    end
    if worthObj then
        worthObj.Value = DataService.ComputeNetWorth(profile)
    end
    if stealsObj then
        stealsObj.Value = profile.TotalSteals
    end
    if rebirthObj then
        rebirthObj.Value = profile.Rebirths or 0
    end
end

function DataService.AddCash(player: Player, amount: number)
    local profile = DataService._profiles[player.UserId]
    if not profile or amount == 0 then
        return
    end
    profile.Cash = math.max(0, profile.Cash + amount)
    if amount > 0 then
        profile.TotalEarned += amount
    end
    DataService.MarkDirty(player)
end

function DataService.SavePlayer(player: Player, force: boolean?): boolean
    local userId = player.UserId
    local profile = DataService._profiles[userId]
    if not profile then
        return true
    end
    if not force and not DataService._dirty[userId] then
        return true
    end
    if DataService._saving[userId] then
        return false
    end

    DataService._saving[userId] = true
    profile.LastSavedAt = os.time()

    local store = getStore()
    local savedOk = false
    if store ~= nil then
        local key = "player_" .. tostring(userId)
        for attempt = 1, 3 do
            local ok, err = pcall(function()
                store:SetAsync(key, profile)
            end)
            if ok then
                savedOk = true
                DataService._dirty[userId] = false
                break
            else
                if RunService:IsStudio() then
                    -- Unpublished Studio places cannot write DataStore; keep in-memory clean
                    savedOk = true
                    break
                end
                warn(string.format("[DataService] Save attempt %d failed for %s: %s", attempt, player.Name, tostring(err)))
                task.wait(0.4 * attempt)
            end
        end
    else
        savedOk = true
    end

    DataService._saving[userId] = nil
    return savedOk
end

function DataService.UnloadPlayer(player: Player)
    DataService.SavePlayer(player, true)
    DataService._profiles[player.UserId] = nil
    DataService._dirty[player.UserId] = nil
    DataService._saving[player.UserId] = nil
end

function DataService.SaveAll()
    for _, player in ipairs(Players:GetPlayers()) do
        DataService.SavePlayer(player, true)
    end
end

function DataService.Start()
    task.spawn(function()
        while true do
            task.wait(GameConfig.AUTOSAVE_INTERVAL_SECONDS)
            for _, player in ipairs(Players:GetPlayers()) do
                if DataService._dirty[player.UserId] then
                    DataService.SavePlayer(player, false)
                end
            end
        end
    end)

    game:BindToClose(function()
        DataService.SaveAll()
        task.wait(1.0)
    end)
end

return DataService
