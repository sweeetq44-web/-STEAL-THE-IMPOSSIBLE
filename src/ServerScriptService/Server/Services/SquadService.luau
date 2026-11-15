--!strict
-- Squad / Team Party Management for Co-op Big Heists ("Arkadaşlarıyla takım kurup büyük soygunlara katılacak")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Types = require(Shared.Types)
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local SquadService = {}
SquadService._squads = {} :: { [string]: Types.SquadData }
SquadService._playerSquad = {} :: { [number]: string }
SquadService._pendingInvites = {} :: { [number]: string } -- targetUserId -> squadId
SquadService._rateLimiter = Utils.CreateRateLimiter()

function SquadService.GetPlayerSquad(player: Player): Types.SquadData?
    local squadId = SquadService._playerSquad[player.UserId]
    if not squadId then
        return nil
    end
    return SquadService._squads[squadId]
end

function SquadService.GetSquadMembersPlayers(squadId: string): { Player }
    local squad = SquadService._squads[squadId]
    if not squad then
        return {}
    end
    local res: { Player } = {}
    for _, uid in ipairs(squad.Members) do
        local p = Players:GetPlayerByUserId(uid)
        if p then
            table.insert(res, p)
        end
    end
    return res
end

local function broadcastSquad(squadId: string)
    local squad = SquadService._squads[squadId]
    if not squad then
        return
    end
    local memberInfo = {}
    for _, uid in ipairs(squad.Members) do
        local p = Players:GetPlayerByUserId(uid)
        table.insert(memberInfo, {
            UserId = uid,
            Name = if p then p.Name else "Player_" .. tostring(uid),
            IsLeader = (uid == squad.LeaderUserId),
        })
    end
    local payload = {
        SquadId = squad.SquadId,
        LeaderUserId = squad.LeaderUserId,
        Members = memberInfo,
    }
    for _, p in ipairs(SquadService.GetSquadMembersPlayers(squadId)) do
        Remotes.GetEvent("SquadStateSync"):FireClient(p, payload)
    end
end

function SquadService.CreateSquad(leader: Player): (boolean, Types.SquadData?)
    if SquadService._playerSquad[leader.UserId] ~= nil then
        return false, SquadService.GetPlayerSquad(leader)
    end
    local id = Utils.GenerateUid("squad")
    local squad: Types.SquadData = {
        SquadId = id,
        LeaderUserId = leader.UserId,
        Members = { leader.UserId },
        CreatedAt = os.time(),
    }
    SquadService._squads[id] = squad
    SquadService._playerSquad[leader.UserId] = id
    broadcastSquad(id)
    return true, squad
end

function SquadService.InvitePlayer(leader: Player, targetUserId: number): (boolean, string)
    local squad = SquadService.GetPlayerSquad(leader)
    if not squad then
        local ok, newSquad = SquadService.CreateSquad(leader)
        if not ok or not newSquad then
            return false, "Could not create squad"
        end
        squad = newSquad
    end
    local sq = squad :: Types.SquadData
    if sq.LeaderUserId ~= leader.UserId then
        return false, "Only squad leader can invite"
    end
    if #sq.Members >= GameConfig.HEIST_MAX_PLAYERS then
        return false, "Squad is full"
    end
    if targetUserId == leader.UserId then
        return false, "Cannot invite yourself"
    end
    if SquadService._playerSquad[targetUserId] ~= nil then
        return false, "Player already in a squad"
    end
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target then
        return false, "Player not found"
    end

    SquadService._pendingInvites[targetUserId] = sq.SquadId
    Remotes.GetEvent("SquadInvitePrompt"):FireClient(target, {
        SquadId = sq.SquadId,
        LeaderName = leader.Name,
        LeaderUserId = leader.UserId,
    })
    return true, "Invite sent"
end

function SquadService.AcceptInvite(player: Player, squadId: string): (boolean, string)
    if SquadService._playerSquad[player.UserId] ~= nil then
        return false, "Already in a squad"
    end
    local pending = SquadService._pendingInvites[player.UserId]
    if pending ~= squadId then
        return false, "Invite expired or invalid"
    end
    local squad = SquadService._squads[squadId]
    if not squad then
        SquadService._pendingInvites[player.UserId] = nil
        return false, "Squad disbanded"
    end
    if #squad.Members >= GameConfig.HEIST_MAX_PLAYERS then
        return false, "Squad full"
    end

    SquadService._pendingInvites[player.UserId] = nil
    table.insert(squad.Members, player.UserId)
    SquadService._playerSquad[player.UserId] = squadId
    broadcastSquad(squadId)
    return true, "Joined squad!"
end

function SquadService.LeaveSquad(player: Player)
    local squadId = SquadService._playerSquad[player.UserId]
    if not squadId then
        return
    end
    local squad = SquadService._squads[squadId]
    SquadService._playerSquad[player.UserId] = nil
    Remotes.GetEvent("SquadStateSync"):FireClient(player, nil)

    if not squad then
        return
    end

    for i, uid in ipairs(squad.Members) do
        if uid == player.UserId then
            table.remove(squad.Members, i)
            break
        end
    end

    if #squad.Members == 0 then
        SquadService._squads[squadId] = nil
    else
        if squad.LeaderUserId == player.UserId then
            squad.LeaderUserId = squad.Members[1]
        end
        broadcastSquad(squadId)
    end
end

function SquadService.Start()
    Remotes.GetEvent("RequestCreateSquad").OnServerEvent:Connect(function(player)
        if not SquadService._rateLimiter:Check(player.UserId, "CreateSquad", 0.5) then
            return
        end
        SquadService.CreateSquad(player)
    end)

    Remotes.GetEvent("RequestLeaveSquad").OnServerEvent:Connect(function(player)
        if not SquadService._rateLimiter:Check(player.UserId, "LeaveSquad", 0.5) then
            return
        end
        SquadService.LeaveSquad(player)
    end)

    Remotes.GetEvent("RequestInviteSquad").OnServerEvent:Connect(function(player, targetUserId)
        if type(targetUserId) ~= "number" then
            return
        end
        if not SquadService._rateLimiter:Check(player.UserId, "InviteSquad", 0.75) then
            return
        end
        SquadService.InvitePlayer(player, math.floor(targetUserId))
    end)

    Remotes.GetEvent("RequestAcceptSquad").OnServerEvent:Connect(function(player, squadId)
        if type(squadId) ~= "string" then
            return
        end
        if not SquadService._rateLimiter:Check(player.UserId, "AcceptSquad", 0.5) then
            return
        end
        SquadService.AcceptInvite(player, squadId)
    end)

    Players.PlayerRemoving:Connect(function(player)
        SquadService.LeaveSquad(player)
        SquadService._pendingInvites[player.UserId] = nil
        SquadService._rateLimiter:ClearPlayer(player.UserId)
    end)
end

return SquadService
