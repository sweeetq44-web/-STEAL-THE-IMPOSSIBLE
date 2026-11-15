--!strict
-- Client Gameplay Actions (Tackle/Steal, Gadget Use, Return Home)
-- Plus real-time 3D item animation: The Last Eye tracking nearest player & Time Eater reverse spin!

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local Localization = require(Shared.Localization)

local UITheme = require(script.Parent.UITheme)
local HUDController = require(script.Parent.HUDController)

local ActionController = {}
local tackleCooldownUntil = 0
local tackleBtn: TextButton
local gadgetBtn: TextButton

local function triggerTackleSteal()
    if os.clock() < tackleCooldownUntil then
        return
    end
    tackleCooldownUntil = os.clock() + 1.2
    Remotes.GetEvent("RequestTackleSteal"):FireServer()

    -- Snappy visual dash lunge on client responsiveness
    local char = Players.LocalPlayer.Character
    local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    if hrp then
        hrp.AssemblyLinearVelocity += hrp.CFrame.LookVector * 36 + Vector3.new(0, 6, 0)
    end
end

local function triggerFirstOwnedGadget()
    local profile = HUDController.CurrentProfile
    if not profile then
        return
    end
    -- Priority order of owned gadgets
    for _, gid in ipairs({ "speed_coil", "phase_dash", "magnet_radar", "frost_bolas" }) do
        if profile.OwnedGadgets[gid] then
            Remotes.GetEvent("RequestUseGadget"):FireServer(gid)
            return
        end
    end
end

function ActionController.Init(rootGui: ScreenGui)
    local isTouchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local actionPanel = Instance.new("Frame")
    actionPanel.Name = "ActionButtons"
    actionPanel.Size = UDim2.fromOffset(170, 146)
    actionPanel.Position = UDim2.new(1, -184, 1, if isTouchOnly then -270 else -218)
    actionPanel.BackgroundTransparency = 1
    actionPanel.Parent = rootGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = actionPanel

    tackleBtn = UITheme.MakeButton({
        Text = "⚡ STEAL [E]",
        Size = UDim2.fromOffset(168, 44),
        Color = UITheme.Colors.Red,
        Parent = actionPanel,
        FontSize = 15,
    })
    tackleBtn.MouseButton1Click:Connect(triggerTackleSteal)

    gadgetBtn = UITheme.MakeButton({
        Text = "📡 GADGET [Q]",
        Size = UDim2.fromOffset(168, 40),
        Color = UITheme.Colors.Cyan,
        TextColor = Color3.fromRGB(12, 16, 26),
        Parent = actionPanel,
        FontSize = 14,
    })
    gadgetBtn.MouseButton1Click:Connect(triggerFirstOwnedGadget)

    local homeBtn = UITheme.MakeButton({
        Text = "🏠 HOME [H]",
        Size = UDim2.fromOffset(168, 36),
        Color = UITheme.Colors.BgCard,
        Parent = actionPanel,
        FontSize = 13,
    })
    homeBtn.MouseButton1Click:Connect(function()
        Remotes.GetEvent("RequestReturnHome"):FireServer()
    end)

    HUDController.OnLanguageChange(function(lang)
        tackleBtn.Text = "⚡ " .. Localization.Get("TACKLE_BTN", lang) .. " [E]"
        gadgetBtn.Text = "📡 " .. Localization.Get("GADGET_BTN", lang) .. " [Q]"
        homeBtn.Text = "🏠 " .. Localization.Get("RETURN_HOME", lang) .. " [H]"
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
            triggerTackleSteal()
        elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonY then
            triggerFirstOwnedGadget()
        elseif input.KeyCode == Enum.KeyCode.H then
            Remotes.GetEvent("RequestReturnHome"):FireServer()
        end
    end)

    -- Live 3D Visual Animations (The Last Eye tracks nearest player! Time Eater hands spin backwards!)
    RunService.RenderStepped:Connect(function(dt)
        -- 1. The Last Eye Tracking Iris ("Oyuncuyu takip eden gizemli göz")
        for _, iris in ipairs(CollectionService:GetTagged("TrackingEyeIris")) do
            if iris:IsA("BasePart") and iris.Parent then
                local model = iris.Parent :: Model
                local core = model:FindFirstChild("Sclera") :: BasePart?
                if core then
                    local bestTargetPos: Vector3? = nil
                    local bestDist = 85
                    for _, plr in ipairs(Players:GetPlayers()) do
                        local ch = plr.Character
                        local head = if ch then ch:FindFirstChild("Head") :: BasePart? else nil
                        if head then
                            local d = (head.Position - core.Position).Magnitude
                            if d < bestDist then
                                bestDist = d
                                bestTargetPos = head.Position
                            end
                        end
                    end
                    if bestTargetPos then
                        local dir = (bestTargetPos - core.Position).Unit
                        local irisCF = CFrame.lookAt(core.Position + dir * (core.Size.X * 0.42), bestTargetPos)
                        iris.CFrame = irisCF
                        local pupil = model:FindFirstChild("VoidPupil") :: BasePart?
                        if pupil then
                            pupil.CFrame = CFrame.lookAt(core.Position + dir * (core.Size.X * 0.50), bestTargetPos)
                        end
                    end
                end
            end
        end

        -- 2. Time Eater / Clockwork reverse rotation
        for _, hand in ipairs(CollectionService:GetTagged("ReverseClockHand")) do
            if hand:IsA("BasePart") and hand.Parent then
                hand.CFrame = hand.CFrame * CFrame.Angles(0, 0, dt * 3.5)
            end
        end
    end)
end

return ActionController
