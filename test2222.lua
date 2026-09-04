--[[

    SPEEDY UI
    Clean / Readable Edition
    No background blur
    Opaque interface
    High contrast
    Same basic API:
        CreateWindow
        AddTab
        AddParagraph
        AddButton
        AddToggle
        AddSlider
        AddDropdown
        AddInput
        AddSection
        AddKeybind
        Notify

]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- REMOVE BLUR
--========================================================--

for _, obj in ipairs(Lighting:GetChildren()) do
    if obj:IsA("BlurEffect") then
        obj:Destroy()
    end
end

--========================================================--
-- THEME
--========================================================--

local Theme = {
    Background = Color3.fromRGB(18, 20, 24),
    Panel = Color3.fromRGB(25, 28, 34),
    Panel2 = Color3.fromRGB(31, 35, 42),
    Border = Color3.fromRGB(52, 57, 67),

    Text = Color3.fromRGB(245, 247, 250),
    SubText = Color3.fromRGB(165, 172, 184),

    Accent = Color3.fromRGB(90, 145, 255),
    AccentDark = Color3.fromRGB(57, 102, 205),

    Success = Color3.fromRGB(85, 205, 125),
    Danger = Color3.fromRGB(220, 80, 80),

    White = Color3.fromRGB(255, 255, 255),
}

--========================================================--
-- HELPERS
--========================================================--

local function New(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    if parent then
        object.Parent = parent
    end

    return object
end

local function Corner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

local function Stroke(parent, color, thickness)
    return New("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = 0,
    }, parent)
end

local function Padding(parent, amount)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, amount),
        PaddingBottom = UDim.new(0, amount),
        PaddingLeft = UDim.new(0, amount),
        PaddingRight = UDim.new(0, amount),
    }, parent)
end

local function Tween(object, properties, duration)
    TweenService:Create(
        object,
        TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    ):Play()
end

--========================================================--
-- LIBRARY
--========================================================--

local SpeedyUI = {}
SpeedyUI.__index = SpeedyUI

function SpeedyUI:CreateWindow(config)

    config = config or {}

    local self = setmetatable({}, SpeedyUI)

    self.Title = config.Title or "Speedy Hub"
    self.SubTitle = config.SubTitle or ""
    self.ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift

    -- Remove previous Speedy UI
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("SpeedyUI")
    if old then
        old:Destroy()
    end

    --====================================================--
    -- SCREEN GUI
    --====================================================--

    self.Gui = New("ScreenGui", {
        Name = "SpeedyUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    --====================================================--
    -- MAIN WINDOW
    --====================================================--

    self.Main = New("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(760, 480),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),

        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0,

        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, self.Gui)

    Corner(self.Main, 12)
    Stroke(self.Main, Theme.Border, 1)

    --====================================================--
    -- TOP BAR
    --====================================================--

    self.TopBar = New("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, self.Main)

    -- Fake window buttons
    local buttons = {
        {Color = Color3.fromRGB(235, 87, 87)},
        {Color = Color3.fromRGB(235, 183, 71)},
        {Color = Color3.fromRGB(82, 196, 116)},
    }

    for i, info in ipairs(buttons) do
        New("Frame", {
            Size = UDim2.fromOffset(12, 12),
            Position = UDim2.new(0, 18 + ((i - 1) * 20), 0, 26),
            BackgroundColor3 = info.Color,
            BorderSizePixel = 0,
        }, self.TopBar)
    end

    self.TitleLabel = New("TextLabel", {
        Size = UDim2.new(1, -180, 0, 24),
        Position = UDim2.new(0, 90, 0, 11),

        BackgroundTransparency = 1,

        Text = self.Title,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.TopBar)

    self.SubTitleLabel = New("TextLabel", {
        Size = UDim2.new(1, -180, 0, 18),
        Position = UDim2.new(0, 90, 0, 34),

        BackgroundTransparency = 1,

        Text = self.SubTitle,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.TopBar)

    --====================================================--
    -- SIDEBAR
    --====================================================--

    self.Sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 175, 1, -64),
        Position = UDim2.new(0, 0, 0, 64),

        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, self.Main)

    self.TabHolder = New("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.fromOffset(10, 10),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        ScrollBarThickness = 0,
        CanvasSize = UDim2.fromOffset(0, 0),

        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, self.Sidebar)

    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.TabHolder)

    --====================================================--
    -- CONTENT
    --====================================================--

    self.Content = New("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, -190, 1, -84),
        Position = UDim2.new(0, 185, 0, 74),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Border,

        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, self.Main)

    Padding(self.Content, 4)

    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.Content)

    self.Tabs = {}
    self.ActiveTab = nil

    --====================================================--
    -- TOGGLE
    --====================================================--

    UIS.InputBegan:Connect(function(input, processed)

        if processed then
            return
        end

        if input.KeyCode == self.ToggleKey then
            self.Gui.Enabled = not self.Gui.Enabled
        end
    end)

    return self
end

--========================================================--
-- TABS
--========================================================--

function SpeedyUI:AddTab(name)

    local tab = {}

    tab.Name = name

    -- Tab button
    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),

        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0,

        BorderSizePixel = 0,

        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.SubText,

        AutoButtonColor = false,
    }, self.TabHolder)

    Corner(button, 7)

    local indicator = New("Frame", {
        Size = UDim2.fromOffset(3, 20),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),

        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,

        BorderSizePixel = 0,
    }, button)

    Corner(indicator, 3)

    local content = New("Frame", {
        Name = name .. "_Content",
        Size = UDim2.new(1, 0, 0, 0),

        BackgroundTransparency = 1,

        Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, self.Content)

    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)

    tab.Content = content
    tab.Button = button
    tab.Indicator = indicator

    function tab:Select()
        for _, other in ipairs(self.Tabs) do
            other.Content.Visible = false
            other.Button.TextColor3 = Theme.SubText
            other.Button.BackgroundColor3 = Theme.Panel
            other.Indicator.BackgroundTransparency = 1
        end

        content.Visible = true
        button.TextColor3 = Theme.Text
        button.BackgroundColor3 = Theme.Panel2
        indicator.BackgroundTransparency = 0

        self.ActiveTab = tab
    end

    function tab:AddSection(title)
        return SpeedyUI._AddSection(content, title)
    end

    function tab:AddParagraph(data)
        return SpeedyUI._AddParagraph(content, data)
    end

    function tab:AddButton(data)
        return SpeedyUI._AddButton(content, data)
    end

    function tab:AddToggle(data)
        return SpeedyUI._AddToggle(content, data)
    end

    function tab:AddSlider(data)
        return SpeedyUI._AddSlider(content, data)
    end

    function tab:AddDropdown(data)
        return SpeedyUI._AddDropdown(content, data)
    end

    function tab:AddInput(data)
        return SpeedyUI._AddInput(content, data)
    end

    function tab:AddKeybind(data)
        return SpeedyUI._AddKeybind(content, data)
    end

    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        tab:Select()
    end

    button.MouseButton1Click:Connect(function()
        tab:Select()
    end)

    return tab
end

--========================================================--
-- SECTION
--========================================================--

function SpeedyUI._AddSection(parent, title)

    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 32),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, parent)

    local label = New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),

        BackgroundTransparency = 1,

        Text = string.upper(title),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Theme.Accent,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    return frame
end

--========================================================--
-- PARAGRAPH
--========================================================--

function SpeedyUI._AddParagraph(parent, data)

    data = data or {}

    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 92),

        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,

        AutomaticSize = Enum.AutomaticSize.Y,
    }, parent)

    Corner(frame, 9)
    Stroke(frame, Theme.Border, 1)
    Padding(frame, 15)

    local title = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 25),

        BackgroundTransparency = 1,

        Text = data.Title or "Information",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local content = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 30),

        BackgroundTransparency = 1,

        Text = data.Content or "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.SubText,

        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,

        AutomaticSize = Enum.AutomaticSize.Y,
    }, frame)

    return frame
end

--========================================================--
-- BUTTON
--========================================================--

function SpeedyUI._AddButton(parent, data)

    data = data or {}

    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 48),

        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,

        Text = data.Title or "Button",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.Text,

        AutoButtonColor = false,
    }, parent)

    Corner(button, 8)
    Stroke(button, Theme.Border, 1)

    button.MouseEnter:Connect(function()
        Tween(button, {
            BackgroundColor3 = Theme.Panel2
        })
    end)

    button.MouseLeave:Connect(function()
        Tween(button, {
            BackgroundColor3 = Theme.Panel
        })
    end)

    button.MouseButton1Click:Connect(function()
        if data.Callback then
            task.spawn(data.Callback)
        end
    end)

    return button
end

--========================================================--
-- TOGGLE
--========================================================--

function SpeedyUI._AddToggle(parent, data)

    data = data or {}

    local enabled = data.Default == true

    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 62),

        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, parent)

    Corner(frame, 8)
    Stroke(frame, Theme.Border, 1)

    local title = New("TextLabel", {
        Size = UDim2.new(1, -75, 0, 23),
        Position = UDim2.fromOffset(14, 9),

        BackgroundTransparency = 1,

        Text = data.Title or "Toggle",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local desc = New("TextLabel", {
        Size = UDim2.new(1, -75, 0, 18),
        Position = UDim2.fromOffset(14, 32),

        BackgroundTransparency = 1,

        Text = data.Description or "",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.SubText,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local toggle = New("TextButton", {
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -14, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),

        BackgroundColor3 = enabled and Theme.Accent or Theme.Border,
        BorderSizePixel = 0,

        Text = "",
        AutoButtonColor = false,
    }, frame)

    Corner(toggle, 11)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(16, 16),

        Position = enabled
            and UDim2.new(1, -19, 0.5, 0)
            or UDim2.new(0, 19, 0.5, 0),

        AnchorPoint = Vector2.new(0.5, 0.5),

        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
    }, toggle)

    Corner(knob, 9)

    local function update()

        Tween(toggle, {
            BackgroundColor3 = enabled and Theme.Accent or Theme.Border
        })

        Tween(knob, {
            Position = enabled
                and UDim2.new(1, -19, 0.5, 0)
                or UDim2.new(0, 19, 0.5, 0)
        })

        if data.Callback then
            task.spawn(data.Callback, enabled)
        end
    end

    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        update()
    end)

    return {
        Set = function(_, value)
            enabled = value == true
            update()
        end,

        Get = function()
            return enabled
        end
    }
end

--========================================================--
-- SLIDER
--========================================================--

function SpeedyUI._AddSlider(parent, data)

    data = data or {}

    local min = data.Min or 0
    local max = data.Max or 100
    local value = math.clamp(data.Default or min, min, max)

    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 76),

        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, parent)

    Corner(frame, 8)
    Stroke(frame, Theme.Border, 1)

    local title = New("TextLabel", {
        Size = UDim2.new(1, -80, 0, 22),
        Position = UDim2.fromOffset(14, 9),

        BackgroundTransparency = 1,

        Text = data.Title or "Slider",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local valueLabel = New("TextLabel", {
        Size = UDim2.fromOffset(60, 22),
        Position = UDim2.new(1, -14, 0, 9),
        AnchorPoint = Vector2.new(1, 0),

        BackgroundTransparency = 1,

        Text = tostring(value),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Accent,

        TextXAlignment = Enum.TextXAlignment.Right,
    }, frame)

    local bar = New("Frame", {
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 0, 52),

        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
    }, frame)

    Corner(bar, 4)

    local fill = New("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),

        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, bar)

    Corner(fill, 4)

    local dragging = false

    local function setValueFromX(x)

        local percent = math.clamp(
            (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0,
            1
        )

        value = math.floor(min + ((max - min) * percent) + 0.5)

        fill.Size = UDim2.new(percent, 0, 1, 0)
        valueLabel.Text = tostring(value)

        if data.Callback then
            task.spawn(data.Callback, value)
        end
    end

    bar.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setValueFromX(input.Position.X)
        end
    end)

    UIS.InputChanged:Connect(function(input)

        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setValueFromX(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return {
        Set = function(_, newValue)
            value = math.clamp(newValue, min, max)

            local percent = (value - min) / (max - min)

            fill.Size = UDim2.new(percent, 0, 1, 0)
            valueLabel.Text = tostring(value)

            if data.Callback then
                task.spawn(data.Callback, value)
            end
        end,

        Get = function()
            return value
        end
    }
end

--========================================================--
-- DROPDOWN
--========================================================--

function SpeedyUI._AddDropdown(parent, data)

    data = data or {}

    local options = data.Options or {}
    local selected = data.Default or options[1] or "None"

    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 56),

        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,

        ClipsDescendants = true,
    }, parent)

    Corner(frame, 8)
    Stroke(frame, Theme.Border, 1)

    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 56),

        BackgroundTransparency = 1,

        Text = "",
        AutoButtonColor = false,
    }, frame)

    local title = New("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.fromOffset(14, 0),

        BackgroundTransparency = 1,

        Text = data.Title or "Dropdown",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)

    local selectedLabel = New("TextLabel", {
        Size = UDim2.new(0.45, -20, 1, 0),
        Position = UDim2.new(0.55, 0, 0, 0),

        BackgroundTransparency = 1,

        Text = selected,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.SubText,

        TextXAlignment = Enum.TextXAlignment.Right,
    }, button)

    local optionsFrame = New("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.fromOffset(10, 62),

        BackgroundColor3 = Theme.Panel2,
        BorderSizePixel = 0,

        AutomaticSize = Enum.AutomaticSize.Y,
    }, frame)

    Corner(optionsFrame, 6)
    Padding(optionsFrame, 5)

    New("UIListLayout", {
        Padding = UDim.new(0, 4),
    }, optionsFrame)

    for _, option in ipairs(options) do

        local optionButton = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),

            BackgroundColor3 = Theme.Panel2,
            BorderSizePixel = 0,

            Text = option,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Theme.Text,

            AutoButtonColor = false,
        }, optionsFrame)

        Corner(optionButton, 5)

        optionButton.MouseButton1Click:Connect(function()

            selected = option
            selectedLabel.Text = option

            frame.Size = UDim2.new(1, 0, 0, 56)

            if data.Callback then
                task.spawn(data.Callback, option)
            end
        end)
    end

    local open = false

    button.MouseButton1Click:Connect(function()

        open = not open

        if open then
            local totalHeight = 62 + optionsFrame.AbsoluteSize.Y + 10

            Tween(frame, {
                Size = UDim2.new(1, 0, 0, totalHeight)
            })
        else
            Tween(frame, {
                Size = UDim2.new(1, 0, 0, 56)
            })
        end
    end)

    return {
        Set = function(_, option)
            selected = option
            selectedLabel.Text = option

            if data.Callback then
                task.spawn(data.Callback, option)
            end
        end,

        Get = function()
            return selected
        end,
    }
end

--========================================================--
-- INPUT
--========================================================--

function SpeedyUI._AddInput(parent, data)

    data = data or {}

    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 74),

        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, parent)

    Corner(frame, 8)
    Stroke(frame, Theme.Border, 1)

    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.fromOffset(14, 8),

        BackgroundTransparency = 1,

        Text = data.Title or "Input",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local input = New("TextBox", {
        Size = UDim2.new(1, -28, 0, 32),
        Position = UDim2.fromOffset(14, 36),

        BackgroundColor3 = Theme.Panel2,
        BorderSizePixel = 0,

        PlaceholderText = data.Placeholder or "",
        PlaceholderColor3 = Theme.SubText,

        Text = "",
        TextColor3 = Theme.Text,

        Font = Enum.Font.Gotham,
        TextSize = 12,

        ClearTextOnFocus = false,
    }, frame)

    Corner(input, 6)
    Stroke(input, Theme.Border, 1)

    Padding(input, 10)

    input.FocusLost:Connect(function(enterPressed)

        if data.Callback then
            task.spawn(data.Callback, input.Text, enterPressed)
        end
    end)

    return input
end

--========================================================--
-- KEYBIND
--========================================================--

function SpeedyUI._AddKeybind(parent, data)

    data = data or {}

    local currentKey = data.Default or Enum.KeyCode.F

    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 56),

        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, parent)

    Corner(frame, 8)
    Stroke(frame, Theme.Border, 1)

    New("TextLabel", {
        Size = UDim2.new(0.65, 0, 1, 0),
        Position = UDim2.fromOffset(14, 0),

        BackgroundTransparency = 1,

        Text = data.Title or "Keybind",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local keyButton = New("TextButton", {
        Size = UDim2.fromOffset(92, 32),
        Position = UDim2.new(1, -14, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),

        BackgroundColor3 = Theme.Panel2,
        BorderSizePixel = 0,

        Text = currentKey.Name,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.Text,

        AutoButtonColor = false,
    }, frame)

    Corner(keyButton, 6)
    Stroke(keyButton, Theme.Border, 1)

    local listening = false

    keyButton.MouseButton1Click:Connect(function()

        listening = true
        keyButton.Text = "Press key..."

        local connection
        connection = UIS.InputBegan:Connect(function(input)

            if input.UserInputType == Enum.UserInputType.Keyboard then

                currentKey = input.KeyCode
                keyButton.Text = currentKey.Name

                listening = false
                connection:Disconnect()

                if data.Callback then
                    task.spawn(data.Callback, currentKey)
                end
            end
        end)
    end)

    return {
        Set = function(_, key)
            currentKey = key
            keyButton.Text = key.Name
        end,

        Get = function()
            return currentKey
        end,
    }
end

--========================================================--
-- NOTIFY
--========================================================--

function SpeedyUI:Notify(data)

    data = data or {}

    local holder = self.Gui:FindFirstChild("Notifications")

    if not holder then
        holder = New("Frame", {
            Name = "Notifications",
            Size = UDim2.fromOffset(320, 500),
            Position = UDim2.new(1, -20, 1, -20),
            AnchorPoint = Vector2.new(1, 1),

            BackgroundTransparency = 1,
        }, self.Gui)

        local layout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
        }, holder)
    end

    local notification = New("Frame", {
        Size = UDim2.fromOffset(300, 70),

        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, holder)

    Corner(notification, 8)
    Stroke(notification, Theme.Border, 1)

    New("TextLabel", {
        Size = UDim2.new(1, -24, 0, 23),
        Position = UDim2.fromOffset(12, 9),

        BackgroundTransparency = 1,

        Text = data.Title or "Speedy Hub",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, notification)

    New("TextLabel", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.fromOffset(12, 34),

        BackgroundTransparency = 1,

        Text = data.Content or "",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.SubText,

        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, notification)

    task.delay(data.Duration or 3, function()

        if notification and notification.Parent then
            Tween(notification, {
                BackgroundTransparency = 1
            }, 0.2)

            task.wait(0.2)
            notification:Destroy()
        end
    end)
end

--========================================================--
-- DESTROY
--========================================================--

function SpeedyUI:Destroy()

    if self.Gui then
        self.Gui:Destroy()
    end
end

return SpeedyUI
