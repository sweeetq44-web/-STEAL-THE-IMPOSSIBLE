--!strict
-- Shared UI Styling & Reusable Component Builders

local UITheme = {}

UITheme.Colors = {
    BgDark = Color3.fromRGB(14, 17, 28),
    BgCard = Color3.fromRGB(22, 27, 44),
    BgHover = Color3.fromRGB(32, 39, 64),
    Stroke = Color3.fromRGB(64, 78, 120),
    Cyan = Color3.fromRGB(0, 235, 255),
    Gold = Color3.fromRGB(255, 205, 55),
    Green = Color3.fromRGB(48, 225, 138),
    Red = Color3.fromRGB(255, 72, 88),
    Purple = Color3.fromRGB(185, 85, 255),
    TextMain = Color3.fromRGB(245, 248, 255),
    TextMuted = Color3.fromRGB(165, 178, 208),
}

function UITheme.AddCorner(inst: GuiObject, radius: number?)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = inst
end

function UITheme.AddStroke(inst: GuiObject, color: Color3?, thickness: number?)
    local s = Instance.new("UIStroke")
    s.Color = color or UITheme.Colors.Stroke
    s.Thickness = thickness or 1.5
    s.Parent = inst
    return s
end

function UITheme.MakeButton(props: {
    Text: string,
    Size: UDim2,
    Position: UDim2?,
    Color: Color3?,
    TextColor: Color3?,
    Parent: Instance,
    FontSize: number?,
}): TextButton
    local btn = Instance.new("TextButton")
    btn.Size = props.Size
    btn.Position = props.Position or UDim2.fromOffset(0, 0)
    btn.BackgroundColor3 = props.Color or UITheme.Colors.BgCard
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = props.TextColor or UITheme.Colors.TextMain
    btn.TextSize = props.FontSize or 15
    btn.Text = props.Text
    btn.TextWrapped = true
    UITheme.AddCorner(btn, 9)
    UITheme.AddStroke(btn, UITheme.Colors.Stroke, 1.4)
    btn.Parent = props.Parent
    return btn
end

function UITheme.CreateModal(name: string, titleText: string, parent: Instance, accentColor: Color3?): (Frame, ScrollingFrame, TextButton, TextLabel)
    local panel = Instance.new("Frame")
    panel.Name = name
    panel.Size = UDim2.fromScale(0.68, 0.72)
    panel.Position = UDim2.fromScale(0.16, 0.14)
    panel.BackgroundColor3 = UITheme.Colors.BgDark
    panel.BackgroundTransparency = 0.04
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 20
    UITheme.AddCorner(panel, 14)
    UITheme.AddStroke(panel, accentColor or UITheme.Colors.Cyan, 2)
    panel.Parent = parent

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(420, 320)
    sizeConstraint.MaxSize = Vector2.new(980, 720)
    sizeConstraint.Parent = panel

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 52)
    header.BackgroundColor3 = UITheme.Colors.BgCard
    header.BorderSizePixel = 0
    header.ZIndex = 21
    UITheme.AddCorner(header, 14)
    header.Parent = panel

    local title = Instance.new("TextLabel")
    title.Name = "TitleLabel"
    title.Size = UDim2.new(1, -64, 1, 0)
    title.Position = UDim2.fromOffset(18, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 21
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = accentColor or UITheme.Colors.Cyan
    title.Text = titleText
    title.ZIndex = 22
    title.Parent = header

    local closeBtn = UITheme.MakeButton({
        Text = "✕",
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.new(1, -46, 0, 7),
        Color = UITheme.Colors.Red,
        Parent = header,
        FontSize = 18,
    })
    closeBtn.ZIndex = 22

    local body = Instance.new("ScrollingFrame")
    body.Name = "Body"
    body.Size = UDim2.new(1, -24, 1, -66)
    body.Position = UDim2.fromOffset(12, 58)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.ScrollBarThickness = 6
    body.CanvasSize = UDim2.fromOffset(0, 0)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.ZIndex = 21
    body.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = body

    return panel, body, closeBtn, title
end

return UITheme
