--!strict
-- Global Leaderboards (OrderedDataStore + 3D Plaza Monolith Boards + Client Modal Data)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Utils = require(Shared.Utils)

local DataService = require(script.Parent.DataService)
local WorldBuilder = require(script.Parent.WorldBuilder)

export type LeaderboardEntry = {
    Rank: number,
    UserId: number,
    Name: string,
    Value: number,
}

local LeaderboardService = {}
LeaderboardService._cachedBoards = {
    NetWorth = {} :: { LeaderboardEntry },
    Steals = {} :: { LeaderboardEntry },
    Secrets = {} :: { LeaderboardEntry },
}
LeaderboardService._nameCache = {} :: { [number]: string }

local function resolvePlayerName(userId: number): string
    local online = Players:GetPlayerByUserId(userId)
    if online then
        LeaderboardService._nameCache[userId] = online.Name
        return online.Name
    end
    if LeaderboardService._nameCache[userId] then
        return LeaderboardService._nameCache[userId]
    end
    local ok, name = pcall(function()
        return Players:GetNameFromUserIdAsync(userId)
    end)
    if ok and type(name) == "string" then
        LeaderboardService._nameCache[userId] = name
        return name
    end
    return "Player_" .. tostring(userId)
end

local function fetchOrderedBoard(dsName: string): { LeaderboardEntry }?
    local okStore, ods = pcall(function()
        return DataStoreService:GetOrderedDataStore(dsName)
    end)
    if not okStore or not ods then
        return nil
    end

    local okPages, pages = pcall(function()
        return ods:GetSortedAsync(false, 10)
    end)
    if not okPages or not pages then
        return nil
    end

    local current = pages:GetCurrentPage()
    local rows: { LeaderboardEntry } = {}
    for rank, entry in ipairs(current) do
        local uid = tonumber(entry.key) or 0
        table.insert(rows, {
            Rank = rank,
            UserId = uid,
            Name = resolvePlayerName(uid),
            Value = tonumber(entry.value) or 0,
        })
    end
    return rows
end

function LeaderboardService.BuildInServerFallback(boardKey: "NetWorth" | "Steals" | "Secrets"): { LeaderboardEntry }
    local rows: { LeaderboardEntry } = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local profile = DataService.GetProfile(player)
        if profile then
            local val = if boardKey == "NetWorth"
                then DataService.ComputeNetWorth(profile)
                elseif boardKey == "Steals" then profile.TotalSteals
                else profile.SecretCount
            table.insert(rows, {
                Rank = 0,
                UserId = player.UserId,
                Name = player.Name,
                Value = val,
            })
        end
    end
    table.sort(rows, function(a, b)
        return a.Value > b.Value
    end)
    for i, r in ipairs(rows) do
        r.Rank = i
    end
    return rows
end

function LeaderboardService.PushOnlineScores()
    if RunService:IsStudio() then
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local profile = DataService.GetProfile(player)
        if profile then
            local key = tostring(player.UserId)
            local netWorth = DataService.ComputeNetWorth(profile)
            pcall(function()
                DataStoreService:GetOrderedDataStore(GameConfig.ORDERED_WEALTH_DS):SetAsync(key, netWorth)
            end)
            pcall(function()
                DataStoreService:GetOrderedDataStore(GameConfig.ORDERED_STEALS_DS):SetAsync(key, profile.TotalSteals)
            end)
            pcall(function()
                DataStoreService:GetOrderedDataStore(GameConfig.ORDERED_SECRETS_DS):SetAsync(key, profile.SecretCount)
            end)
        end
    end
end

function LeaderboardService.RefreshAllBoards()
    local globalWorth = if not RunService:IsStudio() then fetchOrderedBoard(GameConfig.ORDERED_WEALTH_DS) else nil
    local globalSteals = if not RunService:IsStudio() then fetchOrderedBoard(GameConfig.ORDERED_STEALS_DS) else nil
    local globalSecrets = if not RunService:IsStudio() then fetchOrderedBoard(GameConfig.ORDERED_SECRETS_DS) else nil

    LeaderboardService._cachedBoards.NetWorth = if globalWorth and #globalWorth > 0
        then globalWorth
        else LeaderboardService.BuildInServerFallback("NetWorth")

    LeaderboardService._cachedBoards.Steals = if globalSteals and #globalSteals > 0
        then globalSteals
        else LeaderboardService.BuildInServerFallback("Steals")

    LeaderboardService._cachedBoards.Secrets = if globalSecrets and #globalSecrets > 0
        then globalSecrets
        else LeaderboardService.BuildInServerFallback("Secrets")

    -- Update 3D Central Plaza SurfaceGui Monoliths
    local worthBoard = WorldBuilder.LeaderboardBoards.NetWorth
    if worthBoard then
        local bg = worthBoard:FindFirstChildOfClass("Frame")
        local rowsLbl = if bg then bg:FindFirstChild("Rows") :: TextLabel? else nil
        if rowsLbl then
            local lines = {}
            for _, row in ipairs(LeaderboardService._cachedBoards.NetWorth) do
                table.insert(lines, string.format("#%d  %-16s  %s", row.Rank, row.Name, Utils.FormatCash(row.Value)))
            end
            rowsLbl.Text = if #lines > 0 then table.concat(lines, "\n") else "No rankings yet!"
        end
    end

    local secretBoard = WorldBuilder.LeaderboardBoards.Secrets
    if secretBoard then
        local bg = secretBoard:FindFirstChildOfClass("Frame")
        local rowsLbl = if bg then bg:FindFirstChild("Rows") :: TextLabel? else nil
        if rowsLbl then
            local lines = {}
            for _, row in ipairs(LeaderboardService._cachedBoards.Secrets) do
                table.insert(lines, string.format("#%d  %-16s  %d Secrets", row.Rank, row.Name, row.Value))
            end
            rowsLbl.Text = if #lines > 0 then table.concat(lines, "\n") else "Be the first to find a 0.01% Secret!"
        end
    end
end

function LeaderboardService.GetSnapshot(): { NetWorth: { LeaderboardEntry }, Steals: { LeaderboardEntry }, Secrets: { LeaderboardEntry } }
    LeaderboardService.RefreshAllBoards()
    return LeaderboardService._cachedBoards
end

function LeaderboardService.Start()
    Remotes.GetFunction("GetLeaderboard").OnServerInvoke = function()
        return LeaderboardService.GetSnapshot()
    end

    task.spawn(function()
        while true do
            LeaderboardService.PushOnlineScores()
            LeaderboardService.RefreshAllBoards()
            task.wait(GameConfig.LEADERBOARD_REFRESH_SECONDS)
        end
    end)
end

return LeaderboardService
