--!strict
-- Pure-Luau Roblox Engine Mock Environment for Automated Testing of STEAL THE IMPOSSIBLE

local Mock = {}

-- 1. Basic Roblox Value Types (Vector3, Vector2, CFrame, Color3, UDim, UDim2, Enum, Random, etc.)
local Vector3MT: any = {}
Vector3MT.__index = Vector3MT

local function newVector3(x: number?, y: number?, z: number?): any
    local self = setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3MT)
    return self
end

function Vector3MT.__add(a: any, b: any)
    return newVector3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
function Vector3MT.__sub(a: any, b: any)
    return newVector3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
function Vector3MT.__mul(a: any, b: any)
    if type(a) == "number" then
        return newVector3(a * b.X, a * b.Y, a * b.Z)
    elseif type(b) == "number" then
        return newVector3(a.X * b, a.Y * b, a.Z * b)
    end
    return newVector3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
function Vector3MT:__index(k: string)
    if k == "Magnitude" then
        return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
    elseif k == "Unit" then
        local m = math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
        if m == 0 then
            return newVector3(0, 0, 0)
        end
        return newVector3(self.X / m, self.Y / m, self.Z / m)
    end
    return rawget(Vector3MT, k)
end

local Vector3Global = {
    new = newVector3,
    zero = newVector3(0, 0, 0),
    one = newVector3(1, 1, 1),
}

local Vector2Global = {
    new = function(x: number?, y: number?)
        return { X = x or 0, Y = y or 0 }
    end,
}

local CFrameMT: any = {}
local function newCFrame(x: number?, y: number?, z: number?): any
    local pos = if type(x) == "table" then x else newVector3(x or 0, y or 0, z or 0)
    local self = setmetatable({
        Position = pos,
        LookVector = newVector3(0, 0, -1),
        RightVector = newVector3(1, 0, 0),
        UpVector = newVector3(0, 1, 0),
    }, CFrameMT)
    return self
end
function CFrameMT.__mul(a: any, b: any)
    if b.Position then
        return newCFrame(a.Position + b.Position)
    end
    return a.Position + b
end
function CFrameMT:PointToObjectSpace(p: any)
    return p - self.Position
end
CFrameMT.__index = CFrameMT

local CFrameGlobal = {
    new = newCFrame,
    Angles = function()
        return newCFrame(0, 0, 0)
    end,
    lookAt = function(at: any, target: any)
        local cf = newCFrame(at)
        local delta = target - at
        if delta.Magnitude > 0 then
            cf.LookVector = delta.Unit
        end
        return cf
    end,
}

local Color3Global = {
    fromRGB = function(r: number, g: number, b: number)
        return { R = r / 255, G = g / 255, B = b / 255 }
    end,
    new = function(r: number?, g: number?, b: number?)
        return { R = r or 0, G = g or 0, B = b or 0 }
    end,
}

local UDimGlobal = {
    new = function(s: number?, o: number?)
        return { Scale = s or 0, Offset = o or 0 }
    end,
}

local UDim2Global = {
    new = function(sx: number?, ox: number?, sy: number?, oy: number?)
        return { X = { Scale = sx or 0, Offset = ox or 0 }, Y = { Scale = sy or 0, Offset = oy or 0 } }
    end,
    fromOffset = function(ox: number?, oy: number?)
        return { X = { Scale = 0, Offset = ox or 0 }, Y = { Scale = 0, Offset = oy or 0 } }
    end,
    fromScale = function(sx: number?, sy: number?)
        return { X = { Scale = sx or 0, Offset = 0 }, Y = { Scale = sy or 0, Offset = 0 } }
    end,
}

local NumberRangeGlobal = {
    new = function(a: number, b: number?)
        return { Min = a, Max = b or a }
    end,
}
local ColorSequenceGlobal = {
    new = function(a: any, b: any?)
        return { Keypoints = { a, b or a } }
    end,
}
local NumberSequenceKeypointGlobal = {
    new = function(t: number, v: number)
        return { Time = t, Value = v }
    end,
}
local NumberSequenceGlobal = {
    new = function(v: any)
        return { Keypoints = v }
    end,
}
local TweenInfoGlobal = {
    new = function(...)
        return { ... }
    end,
}

local RandomMT: any = {}
RandomMT.__index = RandomMT
function RandomMT:NextNumber(minV: number?, maxV: number?): number
    local a = minV or 0
    local b = maxV or 1
    return a + math.random() * (b - a)
end
function RandomMT:NextInteger(minV: number, maxV: number): number
    return math.random(minV, maxV)
end
local RandomGlobal = {
    new = function()
        return setmetatable({}, RandomMT)
    end,
}

local EnumGlobal = setmetatable({}, {
    __index = function(tbl, category: string)
        local sub = setmetatable({}, {
            __index = function(st, key: string)
                local val = category .. "." .. key
                st[key] = val
                return val
            end,
        })
        tbl[category] = sub
        return sub
    end,
})

-- 2. Signal & Instance Tree
local function createSignal()
    local listeners: { (...any) -> () } = {}
    return {
        Connect = function(_self: any, fn: (...any) -> ())
            table.insert(listeners, fn)
            return {
                Disconnect = function()
                    for i, l in ipairs(listeners) do
                        if l == fn then
                            table.remove(listeners, i)
                            break
                        end
                    end
                end,
            }
        end,
        Fire = function(_self: any, ...: any)
            for _, fn in ipairs(listeners) do
                fn(...)
            end
        end,
        Wait = function() end,
    }
end

local InstanceMT: any = {}
local createInstance: (className: string, name: string?) -> any

function InstanceMT:__index(key: string)
    if key == "Parent" then
        return rawget(self, "_parent")
    end
    local m = rawget(InstanceMT, key)
    if m ~= nil then
        return m
    end
    local children = rawget(self, "_children")
    if children then
        for _, ch in ipairs(children) do
            if rawget(ch, "Name") == key then
                return ch
            end
        end
    end
    return rawget(self, key)
end

function InstanceMT:__newindex(key: string, val: any)
    if key == "Parent" then
        local oldParent = rawget(self, "_parent")
        if oldParent then
            local oc = rawget(oldParent, "_children")
            for i, c in ipairs(oc) do
                if c == self then
                    table.remove(oc, i)
                    break
                end
            end
        end
        rawset(self, "_parent", val)
        if val then
            local vc = rawget(val, "_children")
            if vc then
                table.insert(vc, self)
            end
        end
        return
    end
    rawset(self, key, val)
end

function InstanceMT:FindFirstChild(name: string): any
    for _, ch in ipairs(rawget(self, "_children")) do
        if rawget(ch, "Name") == name then
            return ch
        end
    end
    return nil
end

function InstanceMT:FindFirstChildOfClass(cls: string): any
    for _, ch in ipairs(rawget(self, "_children")) do
        if rawget(ch, "ClassName") == cls then
            return ch
        end
    end
    return nil
end

function InstanceMT:FindFirstAncestorOfClass(cls: string): any
    local cur = rawget(self, "_parent")
    while cur do
        if rawget(cur, "ClassName") == cls then
            return cur
        end
        cur = rawget(cur, "_parent")
    end
    return nil
end

function InstanceMT:WaitForChild(name: string): any
    return self:FindFirstChild(name)
end

function InstanceMT:GetChildren(): { any }
    local out = {}
    for _, ch in ipairs(rawget(self, "_children")) do
        table.insert(out, ch)
    end
    return out
end

function InstanceMT:GetDescendants(): { any }
    local out = {}
    local function walk(node: any)
        for _, ch in ipairs(rawget(node, "_children")) do
            table.insert(out, ch)
            walk(ch)
        end
    end
    walk(self)
    return out
end

function InstanceMT:IsA(cls: string): boolean
    local myCls = rawget(self, "ClassName")
    if myCls == cls then
        return true
    end
    if cls == "BasePart" and (myCls == "Part" or myCls == "SpawnLocation" or myCls == "MeshPart" or myCls == "WedgePart" or myCls == "CornerWedgePart") then
        return true
    end
    if cls == "GuiObject" and (myCls == "Frame" or myCls == "TextLabel" or myCls == "TextButton" or myCls == "ScrollingFrame" or myCls == "TextBox") then
        return true
    end
    if cls == "Folder" and myCls == "Folder" then
        return true
    end
    return false
end

function InstanceMT:GetPropertyChangedSignal(_prop: string)
    return createSignal()
end

function InstanceMT:SetAttribute(k: string, v: any)
    rawget(self, "_attributes")[k] = v
end

function InstanceMT:GetAttribute(k: string): any
    return rawget(self, "_attributes")[k]
end

function InstanceMT:Destroy()
    self.Parent = nil
end

function InstanceMT:Kick(reason: string?)
    rawset(self, "_kickedReason", reason or "Kicked")
end

createInstance = function(className: string, name: string?): any
    local obj: any = {
        ClassName = className,
        Name = name or className,
        _children = {},
        _parent = nil,
        _attributes = {},
        Size = newVector3(4, 1, 4),
        Position = newVector3(0, 0, 0),
        CFrame = newCFrame(0, 0, 0),
        Color = Color3Global.fromRGB(255, 255, 255),
        Material = "Enum.Material.SmoothPlastic",
        Transparency = 0,
        Anchored = true,
        CanCollide = true,
        WalkSpeed = 18,
        Text = "",
        Visible = true,
        Value = 0,
        Touched = createSignal(),
        Triggered = createSignal(),
        Died = createSignal(),
        Chatted = createSignal(),
        CharacterAdded = createSignal(),
        MouseButton1Click = createSignal(),
        Ended = createSignal(),
        Completed = createSignal(),
    }
    if className == "RemoteEvent" then
        local clientSig = createSignal()
        local serverSig = createSignal()
        obj.OnServerEvent = serverSig
        obj.OnClientEvent = clientSig
        obj._firedClients = {}
        obj.FireClient = function(_self: any, plr: any, ...: any)
            table.insert(obj._firedClients, { Player = plr, Args = { ... } })
        end
        obj.FireAllClients = function(_self: any, ...: any)
            table.insert(obj._firedClients, { Player = "ALL", Args = { ... } })
            clientSig:Fire(...)
        end
        obj.FireServer = function(_self: any, ...: any)
            -- Filled by test if simulating client
        end
    elseif className == "RemoteFunction" then
        obj.OnServerInvoke = nil
        obj.InvokeServer = function(_self: any, ...: any)
            return nil
        end
    elseif className == "Sound" then
        obj.Play = function() end
    end
    return setmetatable(obj, InstanceMT)
end

-- 3. Services
local CollectionTags: { [string]: { any } } = {}
local CollectionService = {
    AddTag = function(_s: any, inst: any, tag: string)
        CollectionTags[tag] = CollectionTags[tag] or {}
        table.insert(CollectionTags[tag], inst)
    end,
    GetTagged = function(_s: any, tag: string)
        return CollectionTags[tag] or {}
    end,
}

local MockDataStoreData: { [string]: { [string]: any } } = {}
local DataStoreService = {
    GetDataStore = function(_s: any, name: string)
        MockDataStoreData[name] = MockDataStoreData[name] or {}
        local store = MockDataStoreData[name]
        return {
            GetAsync = function(_st: any, key: string)
                return store[key]
            end,
            SetAsync = function(_st: any, key: string, val: any)
                store[key] = val
            end,
        }
    end,
    GetOrderedDataStore = function(_s: any, name: string)
        MockDataStoreData[name] = MockDataStoreData[name] or {}
        local store = MockDataStoreData[name]
        return {
            SetAsync = function(_st: any, key: string, val: number)
                store[key] = val
            end,
            GetSortedAsync = function(_st: any, ascending: boolean, limit: number)
                local rows = {}
                for k, v in pairs(store) do
                    table.insert(rows, { key = k, value = v })
                end
                table.sort(rows, function(a, b)
                    if ascending then
                        return a.value < b.value
                    end
                    return a.value > b.value
                end)
                local page = {}
                for i = 1, math.min(limit, #rows) do
                    table.insert(page, rows[i])
                end
                return {
                    GetCurrentPage = function()
                        return page
                    end,
                }
            end,
        }
    end,
}

local PublishedGlobalMessages: { any } = {}
local MessagingSubscriptions: { [string]: (any) -> () } = {}
local MessagingService = {
    PublishAsync = function(_s: any, topic: string, payload: any)
        table.insert(PublishedGlobalMessages, { Topic = topic, Data = payload })
        local sub = MessagingSubscriptions[topic]
        if sub then
            sub({ Data = payload })
        end
    end,
    SubscribeAsync = function(_s: any, topic: string, cb: (any) -> ())
        MessagingSubscriptions[topic] = cb
    end,
}

local MarketplaceService = {
    ProcessReceipt = nil,
    PromptGamePassPurchaseFinished = createSignal(),
    UserOwnsGamePassAsync = function()
        return false
    end,
    PromptGamePassPurchase = function() end,
}

local PlayersList: { any } = {}
local Players = {
    PlayerAdded = createSignal(),
    PlayerRemoving = createSignal(),
    GetPlayers = function()
        return PlayersList
    end,
    GetPlayerByUserId = function(_s: any, uid: number)
        for _, p in ipairs(PlayersList) do
            if p.UserId == uid then
                return p
            end
        end
        return nil
    end,
    GetPlayerFromCharacter = function(_s: any, char: any)
        for _, p in ipairs(PlayersList) do
            if p.Character == char then
                return p
            end
        end
        return nil
    end,
    GetNameFromUserIdAsync = function(_s: any, uid: number)
        return "Player_" .. tostring(uid)
    end,
}

local ReplicatedStorage = createInstance("ReplicatedStorage", "ReplicatedStorage")
local ServerScriptService = createInstance("ServerScriptService", "ServerScriptService")
local Workspace = createInstance("Workspace", "Workspace")
Workspace.Gravity = 196.2
local Lighting = createInstance("Lighting", "Lighting")
local SoundService = createInstance("SoundService", "SoundService")
local ReplicatedFirst = createInstance("ReplicatedFirst", "ReplicatedFirst")
ReplicatedFirst.RemoveDefaultLoadingScreen = function() end
local StarterPlayer = createInstance("StarterPlayer", "StarterPlayer")
local StarterPlayerScripts = createInstance("StarterPlayerScripts", "StarterPlayerScripts")
StarterPlayerScripts.Parent = StarterPlayer

local RunService = {
    IsStudio = function()
        return true
    end,
    IsServer = function()
        return true
    end,
    RenderStepped = createSignal(),
}

local TweenService = {
    Create = function(_s: any, inst: any, _info: any, props: { [string]: any })
        return {
            Completed = createSignal(),
            Play = function()
                for k, v in pairs(props) do
                    inst[k] = v
                end
            end,
        }
    end,
}

local UserInputService = {
    InputBegan = createSignal(),
    TouchEnabled = false,
    KeyboardEnabled = true,
}

local ProximityPromptService = {
    PromptTriggered = createSignal(),
}

local ServicesMap: { [string]: any } = {
    Players = Players,
    Workspace = Workspace,
    ReplicatedStorage = ReplicatedStorage,
    ServerScriptService = ServerScriptService,
    DataStoreService = DataStoreService,
    MessagingService = MessagingService,
    MarketplaceService = MarketplaceService,
    CollectionService = CollectionService,
    RunService = RunService,
    TweenService = TweenService,
    Lighting = Lighting,
    SoundService = SoundService,
    ReplicatedFirst = ReplicatedFirst,
    StarterPlayer = StarterPlayer,
    UserInputService = UserInputService,
    ProximityPromptService = ProximityPromptService,
}

local GameObj = {
    GetService = function(_s: any, name: string)
        return ServicesMap[name]
    end,
    BindToClose = function() end,
    IsLoaded = function()
        return true
    end,
    Loaded = createSignal(),
}

-- Task mock: execute spawn immediately ONLY for synchronous non-infinite loops?
-- Better: defer / skip infinite `while true do task.wait(...)` loops cleanly in headless tests!
local TaskGlobal = {
    wait = function(_secs: number?)
        return 0.016
    end,
    spawn = function(_fn: any, ...: any)
        -- Headless tests call service methods & Step() directly without background while-true loops
        return nil
    end,
    delay = function(_secs: number, fn: any)
        if type(fn) == "function" then
            fn()
        end
    end,
}

function Mock.CreatePlayer(userId: number, name: string, startPos: any?): any
    local p = createInstance("Player", name)
    p.UserId = userId
    p.DisplayName = name
    p.Parent = Players

    local char = createInstance("Model", name)
    local hrp = createInstance("Part", "HumanoidRootPart")
    hrp.CFrame = newCFrame(startPos or newVector3(0, 5, 0))
    hrp.Position = hrp.CFrame.Position
    hrp.Parent = char
    local head = createInstance("Part", "Head")
    head.CFrame = newCFrame((startPos or newVector3(0, 5, 0)) + newVector3(0, 2, 0))
    head.Parent = char
    local hum = createInstance("Humanoid", "Humanoid")
    hum.WalkSpeed = 18
    hum.Parent = char
    char.PrimaryPart = hrp
    p.Character = char

    table.insert(PlayersList, p)
    return p
end

function Mock.RemovePlayer(player: any)
    for i, p in ipairs(PlayersList) do
        if p == player then
            table.remove(PlayersList, i)
            break
        end
    end
end

-- Helper exposed to test runner
Mock.PublishedGlobalMessages = PublishedGlobalMessages
Mock.Globals = {
    game = GameObj,
    workspace = Workspace,
    Instance = { new = createInstance },
    Vector3 = Vector3Global,
    Vector2 = Vector2Global,
    CFrame = CFrameGlobal,
    Color3 = Color3Global,
    UDim = UDimGlobal,
    UDim2 = UDim2Global,
    NumberRange = NumberRangeGlobal,
    ColorSequence = ColorSequenceGlobal,
    NumberSequence = NumberSequenceGlobal,
    NumberSequenceKeypoint = NumberSequenceKeypointGlobal,
    TweenInfo = TweenInfoGlobal,
    Enum = EnumGlobal,
    Random = RandomGlobal,
    task = TaskGlobal,
    warn = print,
}

return Mock
