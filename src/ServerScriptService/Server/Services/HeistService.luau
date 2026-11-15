--!strict
-- Co-op Big Heist Facility ("THE IMPOSSIBLE VAULT")
-- Two+ squadmates step onto synchronized Vault Lock Plates to crack the Titan Bank Core!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GameConfig = require(Shared.GameConfig)
local ItemCatalog = require(Shared.ItemCatalog)
local MutationConfig = require(Shared.MutationConfig)
local Remotes = require(Shared.Remotes)

local WorldBuilder = require(script.Parent.WorldBuilder)
local SquadService = require(script.Parent.SquadService)
local CarryStealService = require(script.Parent.CarryStealService)
local DataService = require(script.Parent.DataService)
local BaseService = require(script.Parent.BaseService)

local HeistService = {}
HeistService.VaultCooldownUntil = 0
HeistService.IsVaultOpen = false
HeistService._plateOccupants = {} :: { [number]: Player? }

local function setVaultDoorState(open: boolean)
    HeistService.IsVaultOpen = open
    local door = WorldBuilder.HeistVaultDoor
    if door then
        door.CanCollide = not open
        door.Transparency = if open then 0.78 else 0
        door.Color = if open then Color3.fromRGB(45, 255, 145) else Color3.fromRGB(255, 185, 45)
    end
end

function HeistService.CheckAndTriggerCoopHeist(playersOnPlates: { Player }): (boolean, string)
    local now = os.time()
    if HeistService.IsVaultOpen or now < HeistService.VaultCooldownUntil then
        return false, "Vault on cooldown"
    end
    if #playersOnPlates < GameConfig.HEIST_MIN_PLAYERS then
        return false, "Need at least 2 players on synchronized plates"
    end

    -- Check if players share a Squad (gives extra Squad Multiplier) or cooperative team
    local p1 = playersOnPlates[1]
    local p2 = playersOnPlates[2]
    local sq1 = SquadService.GetPlayerSquad(p1)
    local sq2 = SquadService.GetPlayerSquad(p2)
    local sameSquad = (sq1 ~= nil and sq2 ~= nil and sq1.SquadId == sq2.SquadId)

    setVaultDoorState(true)
    HeistService.VaultCooldownUntil = now + GameConfig.HEIST_COOLDOWN_SECONDS

    -- Award high-tier heist loot & Cash to each participating raider!
    local vaultCore = ItemCatalog.Get("heist_vault_core")
    local cashBonus = if sameSquad then 5000 else 2500

    local participantList = {}
    if sameSquad and sq1 then
        participantList = SquadService.GetSquadMembersPlayers(sq1.SquadId)
    else
        participantList = playersOnPlates
    end

    for _, raider in ipairs(participantList) do
        local rProfile = DataService.GetProfile(raider)
        if rProfile then
            DataService.EnsureDailyQuestReset(rProfile)
            rProfile.QuestProgress.Heists += 1
        end
        DataService.AddCash(raider, cashBonus)
        BaseService.SyncProfileToClient(raider)
        if vaultCore and not CarryStealService.IsCarrying(raider) then
            local mut = MutationConfig.RollMutation(DataService.GetPlayerLuckMultiplier(raider))
            CarryStealService.GiveCarryItem(raider, vaultCore, "BigHeistVault", mut)
        end
    end

    Remotes.GetEvent("HeistStateSync"):FireAllClients({
        Breached = true,
        SameSquad = sameSquad,
        RaiderNames = { p1.Name, p2.Name },
        CooldownSeconds = GameConfig.HEIST_COOLDOWN_SECONDS,
    })

    Remotes.GetEvent("FeedAnnouncement"):FireAllClients({
        Type = "HeistBreached",
        PlayerA = p1.Name,
        PlayerB = p2.Name,
        SameSquad = sameSquad,
    })

    -- Close vault gate automatically after 25s escape window
    task.delay(25, function()
        setVaultDoorState(false)
    end)

    return true, "VAULT BREACHED!"
end

function HeistService.Start()
    setVaultDoorState(false)

    -- Monitor synchronized plates via proximity polling
    task.spawn(function()
        while true do
            task.wait(0.4)
            local plates = WorldBuilder.HeistLockPlates
            if #plates >= 2 and not HeistService.IsVaultOpen and os.time() >= HeistService.VaultCooldownUntil then
                local found: { Player } = {}
                local usedUsers: { [number]: boolean } = {}

                for plateIdx, plate in ipairs(plates) do
                    local occupiedBy: Player? = nil
                    for _, player in ipairs(Players:GetPlayers()) do
                        if not usedUsers[player.UserId] then
                            local char = player.Character
                            local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
                            if hrp and (hrp.Position - plate.Position).Magnitude <= 8.5 then
                                occupiedBy = player
                                usedUsers[player.UserId] = true
                                break
                            end
                        end
                    end
                    plate.Color = if occupiedBy then Color3.fromRGB(45, 255, 145) else Color3.fromRGB(255, 65, 75)
                    HeistService._plateOccupants[plateIdx] = occupiedBy
                    if occupiedBy then
                        table.insert(found, occupiedBy)
                    end
                end

                if #found >= GameConfig.HEIST_MIN_PLAYERS then
                    HeistService.CheckAndTriggerCoopHeist(found)
                end
            end
        end
    end)
end

return HeistService
