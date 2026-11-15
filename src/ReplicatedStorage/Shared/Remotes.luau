--!strict
-- Typed RemoteEvent & RemoteFunction Registry for Client-Server Networking

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

Remotes.EventNames = {
    -- State Sync & Notifications
    "StateSync",
    "WorldTimerSync",
    "CarryStateSync",
    "FeedAnnouncement",
    "GlobalSecretAnnouncement",
    "WorldEndingFX",
    "SpecialRiftFX",

    -- Core Steal / Tackle / Gadget Gameplay
    "RequestTackleSteal",
    "RequestUseGadget",

    -- Base & Flex Your Base & Raids
    "RequestUpgradeBase",
    "RequestUpgradeTech",
    "RequestBuyGadget",
    "RequestAssignPedestal",
    "RequestClearPedestal",
    "RequestHatchGalaxyEgg",
    "RequestVisitBase",
    "RequestLikeBase",
    "RequestReturnHome",
    "RequestToggleHighStakes",
    "RequestCollectBaseSafe",
    "RequestRechargeShield",
    "RequestRaidBaseSafe",
    "BaseSnapshotPush",

    -- Daily Quests, Promo Codes, Black-Market Merchant & Rebirth
    "RequestRedeemCode",
    "RequestClaimQuest",
    "RequestBuyMerchantItem",
    "RequestRebirth",
    "ActionFeedback",

    -- Atomic Player-to-Player Trading
    "RequestSendTrade",
    "RequestRespondTrade",
    "RequestUpdateTradeOffer",
    "RequestConfirmTrade",
    "RequestCancelTrade",
    "TradeInvitePrompt",
    "TradeStateSync",

    -- Squad & Co-op Big Heist
    "RequestCreateSquad",
    "RequestLeaveSquad",
    "RequestInviteSquad",
    "RequestAcceptSquad",
    "SquadInvitePrompt",
    "SquadStateSync",
    "HeistStateSync",

    -- Cosmetics, Shop & Language
    "RequestPromptProduct",
    "RequestEquipCosmetic",
    "RequestPreviewStudioCosmetic",
    "RequestSetLanguage",
    "CosmeticFXBurst",

    -- Studio / Creator Admin Test
    "RequestAdminCommand",
}

Remotes.FunctionNames = {
    "GetServerBases",
    "GetLeaderboard",
    "GetInitialProfile",
}

function Remotes.EnsureFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if folder and folder:IsA("Folder") then
        return folder
    end
    local newFolder = Instance.new("Folder")
    newFolder.Name = "Remotes"
    newFolder.Parent = ReplicatedStorage

    for _, name in ipairs(Remotes.EventNames) do
        local ev = Instance.new("RemoteEvent")
        ev.Name = name
        ev.Parent = newFolder
    end

    for _, name in ipairs(Remotes.FunctionNames) do
        local fn = Instance.new("RemoteFunction")
        fn.Name = name
        fn.Parent = newFolder
    end

    return newFolder
end

function Remotes.GetEvent(name: string): RemoteEvent
    local folder = ReplicatedStorage:WaitForChild("Remotes")
    return folder:WaitForChild(name) :: RemoteEvent
end

function Remotes.GetFunction(name: string): RemoteFunction
    local folder = ReplicatedStorage:WaitForChild("Remotes")
    return folder:WaitForChild(name) :: RemoteFunction
end

return table.freeze(Remotes)
