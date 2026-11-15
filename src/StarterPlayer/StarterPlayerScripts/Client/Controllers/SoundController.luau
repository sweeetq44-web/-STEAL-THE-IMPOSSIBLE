--!strict
-- Client Sound Effects Controller (Zero external missing-asset errors: uses safe Roblox Sound instances)

local SoundService = game:GetService("SoundService")

local SoundController = {}

local SOUND_IDS = {
    Pickup = "rbxassetid://9120386436",
    Steal = "rbxassetid://9119713951",
    Extract = "rbxassetid://9125402735",
    Secret = "rbxassetid://9125402735",
    Apocalypse = "rbxassetid://9114221890",
    Click = "rbxassetid://9119713951",
}

local function playOneShot(soundId: string, volume: number, pitch: number?)
    local s = Instance.new("Sound")
    s.SoundId = soundId
    s.Volume = volume
    s.PlaybackSpeed = pitch or 1.0
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function()
        s:Destroy()
    end)
    task.delay(4, function()
        if s.Parent then
            s:Destroy()
        end
    end)
end

function SoundController.Play(key: string)
    local id = SOUND_IDS[key]
    if not id then
        return
    end
    local vol = if key == "Secret" or key == "Apocalypse" then 0.65 else 0.4
    local pitch = if key == "Secret" then 1.15 elseif key == "Click" then 1.35 else 1.0
    pcall(function()
        playOneShot(id, vol, pitch)
    end)
end

return SoundController
