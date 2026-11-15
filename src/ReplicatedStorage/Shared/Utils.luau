--!strict
-- Utility functions, number/time formatting, deep copy, and anti-exploit rate limiting

local Utils = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }

function Utils.FormatCash(amount: number): string
    local n = math.floor(amount)
    if n < 0 then
        return "-" .. Utils.FormatCash(-n)
    end
    if n < 1000 then
        return "$" .. tostring(n)
    end
    local idx = 1
    local val = n
    while val >= 1000 and idx < #SUFFIXES do
        val = val / 1000
        idx += 1
    end
    if val >= 100 then
        return string.format("$%.0f%s", val, SUFFIXES[idx])
    elseif val >= 10 then
        return string.format("$%.1f%s", val, SUFFIXES[idx])
    else
        return string.format("$%.2f%s", val, SUFFIXES[idx])
    end
end

function Utils.FormatTime(seconds: number): string
    local s = math.max(0, math.floor(seconds))
    local mins = math.floor(s / 60)
    local secs = s % 60
    return string.format("%02d:%02d", mins, secs)
end

function Utils.DeepCopy<T>(orig: T): T
    if type(orig) ~= "table" then
        return orig
    end
    local copy: { [any]: any } = {}
    for k, v in pairs(orig :: any) do
        copy[Utils.DeepCopy(k)] = Utils.DeepCopy(v)
    end
    return (copy :: any) :: T
end

function Utils.GenerateUid(prefix: string?): string
    local p = prefix or "item"
    local randA = math.random(100000, 999999)
    local randB = math.random(1000, 9999)
    return string.format("%s_%d_%d_%d", p, math.floor(os.clock() * 1000), randA, randB)
end

function Utils.PickRandom<T>(list: { T }, rng: Random?): T?
    if #list == 0 then
        return nil
    end
    local idx = if rng then rng:NextInteger(1, #list) else math.random(1, #list)
    return list[idx]
end

-- Server-side anti-spam RateLimiter per Player UserId + action key
export type RateLimiter = {
    _buckets: { [string]: number },
    Check: (self: RateLimiter, userId: number, action: string, minInterval: number, nowOverride: number?) -> boolean,
    ClearPlayer: (self: RateLimiter, userId: number) -> (),
}

function Utils.CreateRateLimiter(): RateLimiter
    local self = {
        _buckets = {} :: { [string]: number },
    }

    function self:Check(userId: number, action: string, minInterval: number, nowOverride: number?): boolean
        local now = nowOverride or os.clock()
        local key = tostring(userId) .. ":" .. action
        local last = self._buckets[key]
        if last ~= nil and (now - last) < minInterval then
            return false
        end
        self._buckets[key] = now
        return true
    end

    function self:ClearPlayer(userId: number)
        local prefix = tostring(userId) .. ":"
        for k in pairs(self._buckets) do
            if string.sub(k, 1, #prefix) == prefix then
                self._buckets[k] = nil
            end
        end
    end

    return self :: RateLimiter
end

return table.freeze(Utils)
