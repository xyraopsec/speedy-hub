--[[ ============================================================
  SPEEDY UI  v1.0  |  macOS glass interface library for Speedy Hub
  Single-file, loadstring-ready. No dependencies.

  Usage:
    local SpeedyUI = loadstring(game:HttpGet(
      "https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/SpeedyUI.lua"
    ))()

    local Window = SpeedyUI:CreateWindow({
      Title = "Speedy Hub",
      SubTitle = "Driving Empire",
      ToggleKey = Enum.KeyCode.RightShift,
    })
    local Tab = Window:AddTab("Home")
    Tab:AddToggle({ Title = "Auto Farm", Default = false,
      Callback = function(v) print(v) end })
    SpeedyUI:Notify({ Title = "Speedy", Content = "Loaded" })
  ============================================================ ]]

local SpeedyUI = {}

-- Services ----------------------------------------------------
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Theme: matches Loader v4 (frosted 26,26,30 + Speedy red) ----
local Theme = {
  Red        = Color3.fromRGB(255, 26, 26),
  RedSoft    = Color3.fromRGB(255, 62, 62),
  Bg         = Color3.fromRGB(24, 24, 28),
  BgTrans    = 0.3, -- airy glass like the loader; text stays crisp via stroke, no blur
  Inset      = Color3.fromRGB(12, 12, 15),
  RowHover   = Color3.fromRGB(255, 255, 255),
  Text       = Color3.fromRGB(255, 255, 255),
  TextDim    = Color3.fromRGB(255, 255, 255),
  Stroke     = Color3.fromRGB(255, 255, 255),
  RadiusWin  = 20,
  RadiusCtl  = 10,
}

-- Small utilities ------------------------------------------------
local function tween(obj, time, style, dir, props)
  local info = TweenInfo.new(time or 0.22, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
  local t = TweenService:Create(obj, info, props)
  t:Play()
  return t
end

local function pop(obj, amount) -- press feedback
  amount = amount or 0.965
  local orig = obj.Size
  tween(obj, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
    Size = UDim2.new(orig.X.Scale, math.floor(orig.X.Offset * amount), orig.Y.Scale, math.floor(orig.Y.Offset * amount)),
  })
  task.delay(0.09, function()
    if obj and obj.Parent then tween(obj, 0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = orig }) end
  end)
end

local function New(class, props, parent)
  local o = Instance.new(class)
  for k, v in pairs(props or {}) do
    if k ~= "Parent" then
      pcall(function() o[k] = v end)
    end
  end
  o.Parent = parent or props and props.Parent
  return o
end

local function corner(obj, r)
  return New("UICorner", { CornerRadius = UDim.new(0, r or Theme.RadiusCtl) }, obj)
end

local function stroke(obj, color, transparency, thickness)
  return New("UIStroke", {
    Color = color or Theme.Stroke,
    Transparency = transparency == nil and 0.86 or transparency,
    Thickness = thickness or 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
  }, obj)
end

local function label(parent, text, size, font, transparency, align)
  return New("TextLabel", {
    BackgroundTransparency = 1,
    Text = text,
    Font = font or Enum.Font.GothamMedium,
    TextSize = size or 13,
    TextColor3 = Theme.Text,
    TextTransparency = 0, -- forced full white: readable over glass
    TextXAlignment = align or Enum.TextXAlignment.Left,
    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
    TextStrokeTransparency = 0.8,
  }, parent)
end

-- Drag any frame by a handle (mouse + touch) --------------------
local function makeDraggable(frame, handle)
  handle = handle or frame
  local dragging, dragStart, startPos = false, nil, nil
  handle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      dragging, dragStart, startPos = true, input.Position, frame.Position
      input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then dragging = false end
      end)
    end
  end)
  UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
      local d = input.Position - dragStart
      frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
  end)
end

-- Executor-safe parent -------------------------------------------
local function getParent()
  local ok, hui = pcall(function() return gethui() end)
  if ok and hui then return hui end
  local ok2, core = pcall(function() return game:GetService("CoreGui") end)
  if ok2 and core then
    local ok3 = pcall(function() core:GetChildren() end)
    if ok3 then return core end
  end
  return LocalPlayer:WaitForChild("PlayerGui")
end

-- Window ------------------------------------------------------------
function SpeedyUI:CreateWindow(opts)
  opts = opts or {}
  local title = opts.Title or "Speedy Hub"
  local sub = opts.SubTitle or ""
  local size = opts.Size or UDim2.fromOffset(560, 420)
  local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift

  -- Clamp to viewport (mobile safety)
  local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1200, 700)
  size = UDim2.fromOffset(
    math.min(size.X.Offset, vp.X - 24),
    math.min(size.Y.Offset, vp.Y - 24)
  )

  local parent = getParent()
  if parent:FindFirstChild("SpeedyUI") then parent.SpeedyUI:Destroy() end
  for _, v in ipairs(Lighting:GetChildren()) do
    if v.Name == "SpeedyUIBlur" or v.Name == "SpeedyBlur" then v:Destroy() end
  end

  local gui = New("ScreenGui", {
    Name = "SpeedyUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
  }, parent)

  -- No Lighting blur: script UI stays crisp. Old blurs are cleaned above.
  local blur = nil

  -- Frosted shell (matches loader MainBox)
  local shell = New("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.52),
    Size = UDim2.fromOffset(math.floor(size.X.Offset * 0.94), math.floor(size.Y.Offset * 0.94)),
    BackgroundColor3 = Theme.Bg,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    GroupTransparency = 1,
  }, gui)
  corner(shell, Theme.RadiusWin)
  local shellStroke = stroke(shell, Theme.Stroke, 1, 1)
  local shellGrad = New("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(44, 44, 52), Color3.fromRGB(16, 16, 20)),
    Rotation = 90, Transparency = NumberSequence.new(0.1, 0.1),
  }, shell)

  -- Titlebar
  local bar = New("Frame", {
    Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1,
  }, shell)

  -- macOS traffic lights
  local lights = New("Frame", {
    Position = UDim2.fromOffset(16, 15), Size = UDim2.fromOffset(62, 15),
    BackgroundTransparency = 1,
  }, bar)
  local ll = New("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
  }, lights)

  local Window = {
    _gui = gui, _shell = shell, _tabs = {}, _pages = {},
    _open = false, _fullSize = size, _mini = false, _conns = {},
  }

  local function traffic(color, glyph, tip, act)
    local b = New("TextButton", {
      Size = UDim2.fromOffset(14, 14), BackgroundColor3 = color,
      Text = "", AutoButtonColor = false,
    }, lights)
    corner(b, 999)
    New("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.85 }, b)
    local g = label(b, glyph, 8, Enum.Font.GothamBold, 1, Enum.TextXAlignment.Center)
    g.Size = UDim2.fromScale(1, 1)
    g.TextColor3 = Color3.fromRGB(60, 0, 0)
    -- glyphs always visible for readability (no hover fade)
    if act then b.MouseButton1Click:Connect(act) end
    return b
  end

  traffic(Color3.fromRGB(255, 95, 87), "✕", "Close", function() Window:Destroy() end)
  traffic(Color3.fromRGB(255, 189, 46), "—", "Minimize", function() Window:ToggleMini() end)
  traffic(Color3.fromRGB(40, 200, 64), "⤢", "Expand", function() Window:ToggleSize() end)

  -- Centered title block
  local titleWrap = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0),
    Size = UDim2.fromOffset(300, 44), BackgroundTransparency = 1,
  }, bar)
  local t1 = label(titleWrap, title, 15, Enum.Font.GothamBlack, 0, Enum.TextXAlignment.Center)
  t1.Size = UDim2.new(1, 0, 0, 20); t1.Position = UDim2.fromOffset(0, 6)
  local t2 = label(titleWrap, sub, 10, Enum.Font.GothamMedium, 0.3, Enum.TextXAlignment.Center)
  t2.Size = UDim2.new(1, 0, 0, 13); t2.Position = UDim2.fromOffset(0, 27)

  New("Frame", { -- hairline under titlebar
    Position = UDim2.fromOffset(18, 46), Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.92, BorderSizePixel = 0,
  }, shell)

  makeDraggable(shell, bar)

  -- Sidebar + content ----------------------------------------------
  local side = New("Frame", {
    Position = UDim2.fromOffset(18, 58), Size = UDim2.new(0, 148, 1, -72),
    BackgroundTransparency = 1,
  }, shell)
  local sideList = New("UIListLayout", { Padding = UDim.new(0, 4) }, side)

  local content = New("ScrollingFrame", {
    Position = UDim2.fromOffset(178, 58), Size = UDim2.new(1, -196, 1, -72),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageTransparency = 0.55,
    CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
  }, shell)
  New("UIPadding", {
    PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 14),
    PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8),
  }, content)

  local Tab = {}
  Tab.__index = Tab

  function Window:AddTab(name)
    local idx = #self._tabs + 1

    local btn = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.RowHover,
      BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
      LayoutOrder = idx,
    }, side)
    corner(btn, 9)
    local bar = New("Frame", {
      AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
      Size = UDim2.fromOffset(0, 16), BackgroundColor3 = Theme.Red,
      BorderSizePixel = 0, BackgroundTransparency = 0,
    }, btn)
    corner(bar, 999)
    local bl = label(btn, name, 13, Enum.Font.GothamSemibold, 0.3)
    bl.Size = UDim2.new(1, -24, 1, 0); bl.Position = UDim2.fromOffset(14, 0)

    local page = New("CanvasGroup", {
      Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundTransparency = 1, Visible = false, GroupTransparency = 1,
    }, content)
    New("UIListLayout", { Padding = UDim.new(0, 8) }, page)

    local tab = setmetatable({ _btn = btn, _bar = bar, _label = bl, _page = page, _win = self }, Tab)
    table.insert(self._tabs, tab)
    table.insert(self._pages, page)

    local function hover(on)
      if self._active ~= tab then
        tween(btn, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = on and 0.93 or 1 })
      end
    end
    btn.MouseEnter:Connect(function() hover(true) end)
    btn.MouseLeave:Connect(function() hover(false) end)
    btn.MouseButton1Click:Connect(function() self:SelectTab(idx) end)

    if idx == 1 then self:SelectTab(1) end
    return tab
  end

  function Window:SelectTab(idx)
    local tab = self._tabs[idx]
    if not tab then return end
    self._active = tab
    for i, t in ipairs(self._tabs) do
      local on = (i == idx)
      tween(t._btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = on and 0.8 or 1 })
      tween(t._bar, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(on and 3 or 0, 16) })
      tween(t._label, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextTransparency = 0 })
      local pg = self._pages[i]
      if on then
        pg.Visible = true
        pg.Position = UDim2.fromOffset(10, 0)
        tween(pg, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
      else
        tween(pg, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { GroupTransparency = 1 })
        task.delay(0.16, function() pg.Visible = false end)
      end
    end
  end

  -- Open animation (spring pop + fade, like the loader cards) -----
  task.delay(0.05, function()
    tween(shell, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = size, GroupTransparency = 0 })
    tween(shell, 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = Theme.BgTrans })
    tween(shell, 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = UDim2.fromScale(0.5, 0.5) })
    tween(shellStroke, 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.86 })
  end)
  Window._open = true

  -- Element helpers --------------------------------------------------
  local function row(tab, h)
    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, h or 40), BackgroundColor3 = Theme.RowHover,
      BackgroundTransparency = 1, BorderSizePixel = 0,
    }, tab._page)
    corner(r, Theme.RadiusCtl)
    return r
  end

  local function hoverRow(r)
    r.MouseEnter:Connect(function()
      tween(r, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.94 })
    end)
    r.MouseLeave:Connect(function()
      tween(r, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
    end)
  end

  function Tab:AddSection(title)
    local s = label(self._page, string.upper(title), 10, Enum.Font.GothamBold, 0.35)
    s.Size = UDim2.new(1, 0, 0, 14)
    return s
  end

  function Tab:AddLabel(text)
    local r = row(self, 22)
    local l = label(r, text, 12, Enum.Font.Gotham, 0.25)
    l.Size = UDim2.new(1, -20, 1, 0); l.Position = UDim2.fromOffset(10, 0)
    l.TextWrapped = true
    return r
  end

  function Tab:AddParagraph(o)
    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundColor3 = Theme.RowHover, BackgroundTransparency = 0.94,
      BorderSizePixel = 0,
    }, self._page)
    corner(r, Theme.RadiusCtl)
    stroke(r, Theme.Stroke, 0.9, 1)
    New("UIPadding", {
      PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
      PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
    }, r)
    local list = New("UIListLayout", { Padding = UDim.new(0, 4) }, r)
    local t = label(r, o.Title or "", 13, Enum.Font.GothamBold, 0)
    t.Size = UDim2.new(1, 0, 0, 16)
    local c = label(r, o.Content or "", 12, Enum.Font.Gotham, 0.25)
    c.Size = UDim2.new(1, 0, 0, 0); c.AutomaticSize = Enum.AutomaticSize.Y
    c.TextWrapped = true
    return r
  end

  function Tab:AddButton(o)
    local r = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.RowHover,
      BackgroundTransparency = 0.9, Text = "", AutoButtonColor = false,
    }, self._page)
    corner(r, Theme.RadiusCtl)
    stroke(r, Theme.Stroke, 0.88, 1)
    local l = label(r, o.Title or "Button", 13, Enum.Font.GothamSemibold, 0, Enum.TextXAlignment.Center)
    l.Size = UDim2.fromScale(1, 1)
    r.MouseEnter:Connect(function()
      tween(r, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.82 })
    end)
    r.MouseLeave:Connect(function()
      tween(r, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.9 })
    end)
    r.MouseButton1Click:Connect(function()
      pop(r)
      if o.Callback then task.spawn(o.Callback) end
    end)
    return r
  end

  function Tab:AddInput(o)
    o = o or {}
    local r = row(self, 52)
    local t = label(r, o.Title or "Input", 13, Enum.Font.GothamSemibold, 0)
    t.Size = UDim2.new(1, -20, 0, 16); t.Position = UDim2.fromOffset(10, 6)
    local box = New("TextBox", {
      Position = UDim2.fromOffset(10, 26), Size = UDim2.new(1, -20, 0, 0),
      AutomaticSize = Enum.AutomaticSize.None,
      BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.55,
      Text = "", PlaceholderText = o.Placeholder or "Type here...",
      PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
      Font = Enum.Font.Gotham, TextSize = 12,
      TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
      ClearTextOnFocus = false,
    }, r)
    box.Size = UDim2.new(1, -20, 0, 22)
    corner(box, 7)
    stroke(box, Theme.Stroke, 0.88, 1)
    New("UIPadding", {
      PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
    }, box)
    box.FocusLost:Connect(function(enter)
      if o.Callback then task.spawn(o.Callback, box.Text, enter) end
    end)
    local el = { _box = box }
    function el:Set(text) box.Text = text end
    return el
  end

  function Tab:AddToggle(o)
    local state = o.Default == true
    local r = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1,
      Text = "", AutoButtonColor = false,
    }, self._page)
    local t = label(r, o.Title or "Toggle", 13, Enum.Font.GothamSemibold, 0)
    t.Size = UDim2.new(1, -70, 0, 16); t.Position = UDim2.fromOffset(10, 6)
    local d = label(r, o.Description or "", 11, Enum.Font.Gotham, 0.35)
    d.Size = UDim2.new(1, -70, 0, 13); d.Position = UDim2.fromOffset(10, 24)

    -- macOS switch
    local sw = New("Frame", {
      AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
      Size = UDim2.fromOffset(44, 24),
      BackgroundColor3 = state and Theme.Red or Color3.fromRGB(255, 255, 255),
      BackgroundTransparency = state and 0 or 0.82,
      BorderSizePixel = 0,
    }, r)
    corner(sw, 999)
    local knob = New("Frame", {
      AnchorPoint = Vector2.new(0, 0.5),
      Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
      Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.new(1, 1, 1),
      BorderSizePixel = 0,
    }, sw)
    corner(knob, 999)

    local el = { Value = state }
    local function render(animated)
      local ti, ease = animated and 0.22 or 0, Enum.EasingStyle.Back
      tween(sw, ti, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
        BackgroundColor3 = state and Theme.Red or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = state and 0 or 0.82,
      })
      tween(knob, animated and 0.24 or 0, ease, Enum.EasingDirection.Out, {
        Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
      })
    end
    local function flip()
      state = not state
      el.Value = state
      render(true)
      if o.Callback then task.spawn(o.Callback, state) end
    end
    r.MouseButton1Click:Connect(flip)
    hoverRow(r)
    function el:Set(v)
      state = v == true
      el.Value = state
      render(true)
    end
    return el
  end

  function Tab:AddSlider(o)
    local min, max = o.Min or 0, o.Max or 100
    local value = math.clamp(o.Default == nil and min or o.Default, min, max)
    local round = o.Rounding or 0
    local function fmt(v)
      if round <= 0 then return tostring(math.floor(v + 0.5)) end
      return string.format("%." .. round .. "f", v)
    end

    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, BorderSizePixel = 0,
    }, self._page)
    local t = label(r, o.Title or "Slider", 13, Enum.Font.GothamSemibold, 0)
    t.Size = UDim2.new(1, -70, 0, 16); t.Position = UDim2.fromOffset(10, 4)
    local val = label(r, fmt(value), 12, Enum.Font.GothamBold, 0.15, Enum.TextXAlignment.Right)
    val.Size = UDim2.new(0, 50, 0, 16); val.AnchorPoint = Vector2.new(1, 0)
    val.Position = UDim2.new(1, -10, 0, 4)

    local track = New("TextButton", {
      Position = UDim2.fromOffset(10, 32), Size = UDim2.new(1, -20, 0, 14),
      BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
    }, r)
    local rail = New("Frame", {
      AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
      Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BackgroundTransparency = 0.82, BorderSizePixel = 0,
    }, track)
    corner(rail, 999)
    local fill = New("Frame", {
      Size = UDim2.fromScale((value - min) / math.max(1e-6, max - min), 1),
      BackgroundColor3 = Theme.Red, BorderSizePixel = 0,
    }, rail)
    corner(fill, 999)
    local knob = New("Frame", {
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.fromScale((value - min) / math.max(1e-6, max - min), 0.5),
      Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1),
      BorderSizePixel = 0,
    }, track)
    corner(knob, 999)
    stroke(knob, Color3.fromRGB(0, 0, 0), 0.85, 1)

    local el = { Value = value }
    local dragging = false
    local function apply(v, fire)
      value = math.clamp(v, min, max)
      el.Value = value
      local a = (value - min) / math.max(1e-6, max - min)
      fill.Size = UDim2.fromScale(a, 1)
      knob.Position = UDim2.fromScale(a, 0.5)
      val.Text = fmt(value)
      if fire and o.Callback then task.spawn(o.Callback, value) end
    end
    local function fromInput(input)
      local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
      local v = min + rel * (max - min)
      if round > 0 then
        local m = 10 ^ round
        v = math.floor(v * m + 0.5) / m
      else
        v = math.floor(v + 0.5)
      end
      apply(v, true)
    end
    track.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        tween(knob, 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(17, 17) })
        fromInput(input)
      end
    end)
    UserInputService.InputEnded:Connect(function(input)
      if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = false
        tween(knob, 0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(14, 14) })
      end
    end)
    UserInputService.InputChanged:Connect(function(input)
      if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        fromInput(input)
      end
    end)
    function el:Set(v) apply(v, false) end
    return el
  end

  function Tab:AddDropdown(o)
    local options = o.Options or {}
    local current = o.Default or options[1]
    local open = false

    local wrap = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundTransparency = 1,
    }, self._page)

    local head = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.RowHover,
      BackgroundTransparency = 0.93, Text = "", AutoButtonColor = false,
    }, wrap)
    corner(head, Theme.RadiusCtl)
    stroke(head, Theme.Stroke, 0.88, 1)
    local t = label(head, o.Title or "Dropdown", 13, Enum.Font.GothamSemibold, 0)
    t.Size = UDim2.new(1, -20, 0, 16); t.Position = UDim2.fromOffset(10, 5)
    local c = label(head, tostring(current or "—"), 11, Enum.Font.Gotham, 0.3)
    c.Name = "Current"; c.Size = UDim2.new(1, -34, 0, 13); c.Position = UDim2.fromOffset(10, 24)
    local chev = label(head, "›", 16, Enum.Font.GothamBold, 0.3, Enum.TextXAlignment.Center)
    chev.Name = "Chev"; chev.Size = UDim2.fromOffset(16, 16)
    chev.AnchorPoint = Vector2.new(1, 0.5); chev.Position = UDim2.new(1, -10, 0.5, 0)
    chev.Rotation = 90

    local list = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundColor3 = Color3.fromRGB(14, 14, 17), BackgroundTransparency = 0.12,
      BorderSizePixel = 0, Visible = false, ClipsDescendants = true,
    }, wrap)
    corner(list, Theme.RadiusCtl)
    stroke(list, Theme.Stroke, 0.86, 1)
    local listPad = New("UIPadding", {
      PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
      PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
    }, list)
    local listLayout = New("UIListLayout", { Padding = UDim.new(0, 2) }, list)

    local el = { Value = current }
    local function setCurrent(v, fire)
      current = v
      el.Value = v
      c.Text = tostring(v)
      for _, b in ipairs(list:GetChildren()) do
        if b:IsA("TextButton") then
          local on = (b.Name == tostring(v))
          b.BackgroundTransparency = on and 0.85 or 1
          local dot = b:FindFirstChild("Dot")
          if dot then dot.BackgroundTransparency = on and 0 or 1 end
        end
      end
      if fire and o.Callback then task.spawn(o.Callback, v) end
    end

    local function setOpen(v)
      open = v
      list.Visible = true
      if v then
        list.Size = UDim2.new(1, 0, 0, 0)
        tween(chev, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Rotation = 270 })
        task.delay(0.02, function()
          list.AutomaticSize = Enum.AutomaticSize.Y
        end)
      else
        tween(chev, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Rotation = 90 })
        list.AutomaticSize = Enum.AutomaticSize.None
        tween(list, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = UDim2.new(1, 0, 0, 0) })
        task.delay(0.17, function()
          if not open then list.Visible = false end
        end)
      end
    end

    local function rebuild(opts)
      for _, ch in ipairs(list:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
      end
      for _, opt in ipairs(opts) do
        local b = New("TextButton", {
          Name = tostring(opt), Size = UDim2.new(1, 0, 0, 30),
          BackgroundColor3 = Theme.RowHover, BackgroundTransparency = 1,
          Text = "", AutoButtonColor = false,
        }, list)
        corner(b, 7)
        local dot = New("Frame", {
          Name = "Dot", AnchorPoint = Vector2.new(0, 0.5),
          Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(6, 6),
          BackgroundColor3 = Theme.Red, BorderSizePixel = 0,
          BackgroundTransparency = (tostring(opt) == tostring(current)) and 0 or 1,
        }, b)
        corner(dot, 999)
        local bl = label(b, tostring(opt), 12, Enum.Font.GothamMedium, 0.15)
        bl.Size = UDim2.new(1, -32, 1, 0); bl.Position = UDim2.fromOffset(24, 0)
        b.MouseEnter:Connect(function()
          tween(b, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.9 })
        end)
        b.MouseLeave:Connect(function()
          if b.Name ~= tostring(current) then
            tween(b, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
          end
        end)
        b.MouseButton1Click:Connect(function()
          pop(b, 0.98)
          setCurrent(opt, true)
          setOpen(false)
        end)
      end
    end

    head.MouseButton1Click:Connect(function() setOpen(not open) end)
    rebuild(options)
    setCurrent(current, false)

    function el:Set(v) setCurrent(v, false) end
    function el:Refresh(opts)
      options = opts
      rebuild(opts)
      if #opts > 0 and not table.find(opts, current) then setCurrent(opts[1], false) end
    end
    return el
  end

  function Tab:AddKeybind(o)
    local bound = o.Default or Enum.KeyCode.F
    local waiting = false
    local r = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
      Text = "", AutoButtonColor = false,
    }, self._page)
    local t = label(r, o.Title or "Keybind", 13, Enum.Font.GothamSemibold, 0)
    t.Size = UDim2.new(1, -80, 1, 0); t.Position = UDim2.fromOffset(10, 0)
    local pill = New("Frame", {
      AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
      Size = UDim2.fromOffset(56, 24), BackgroundColor3 = Theme.RowHover,
      BackgroundTransparency = 0.85, BorderSizePixel = 0,
    }, r)
    corner(pill, 7)
    stroke(pill, Theme.Stroke, 0.86, 1)
    local pl = label(pill, bound.Name, 11, Enum.Font.GothamBold, 0, Enum.TextXAlignment.Center)
    pl.Size = UDim2.fromScale(1, 1)

    local el = { Value = bound }
    r.MouseButton1Click:Connect(function()
      waiting = true
      pl.Text = "…"
      tween(pill, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.7 })
    end)
    table.insert(Window._conns, UserInputService.InputBegan:Connect(function(input, gpe)
      if waiting then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
          if input.KeyCode == Enum.KeyCode.Escape then
            waiting = false
            pl.Text = bound.Name
          else
            waiting, bound = false, input.KeyCode
            el.Value = bound
            pl.Text = bound.Name
          end
          tween(pill, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.85 })
        end
        return
      end
      if not gpe and input.KeyCode == bound and input.UserInputType == Enum.UserInputType.Keyboard then
        if o.Callback then task.spawn(o.Callback) end
      end
    end))
    function el:Set(k)
      bound = k
      el.Value = k
      pl.Text = k.Name
    end
    hoverRow(r)
    return el
  end

  -- Window methods ------------------------------------------------------
  function Window:Toggle(force)
    local show = force == nil and not self._open or force
    self._open = show
    if show then
      self._gui.Enabled = true
      tween(shell, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = self._curSize or self._fullSize })
      tween(shell, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { GroupTransparency = 0, BackgroundTransparency = Theme.BgTrans })
      tween(shellStroke, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.86 })
    else
      tween(shell, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
        Size = UDim2.fromOffset(
          math.floor((self._curSize or self._fullSize).X.Offset * 0.94),
          math.floor((self._curSize or self._fullSize).Y.Offset * 0.94)),
      })
      tween(shell, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { GroupTransparency = 1 })
      task.delay(0.3, function()
        if not self._open then self._gui.Enabled = false end
      end)
    end
  end

  function Window:ToggleMini()
    self._mini = not self._mini
    side.Visible = not self._mini
    content.Visible = not self._mini
    local target = self._mini and UDim2.fromOffset(self._fullSize.X.Offset, 46 + 36) or (self._curSize or self._fullSize)
    self._curSize = self._mini and self._curSize or target
    tween(shell, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = target })
  end

  function Window:ToggleSize()
    local big = UDim2.fromOffset(720, 520)
    local isBig = self._curSize and self._curSize.X.Offset >= 700
    self._curSize = isBig and self._fullSize or big
    tween(shell, 0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = self._curSize })
  end

  function Window:Destroy()
    tween(shell, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
      Size = UDim2.fromOffset(
        math.floor((self._curSize or self._fullSize).X.Offset * 0.9),
        math.floor((self._curSize or self._fullSize).Y.Offset * 0.9)),
      GroupTransparency = 1,
    })
    if blur then tween(blur, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Size = 0 }) end
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    task.delay(0.32, function()
      pcall(function() gui:Destroy() end)
      pcall(function() if blur then blur:Destroy() end end)
    end)
  end

  table.insert(Window._conns, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == toggleKey and input.UserInputType == Enum.UserInputType.Keyboard then
      Window:Toggle()
    end
  end))

  return Window
end

-- Notifications -------------------------------------------------------
local notifGui, notifStack
local function ensureNotifs()
  if notifStack and notifStack.Parent then return notifStack end
  local parent = getParent()
  if parent:FindFirstChild("SpeedyUINotifs") then parent.SpeedyUINotifs:Destroy() end
  notifGui = New("ScreenGui", {
    Name = "SpeedyUINotifs", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
  }, parent)
  notifStack = New("Frame", {
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.new(0, 290, 1, -36), BackgroundTransparency = 1,
  }, notifGui)
  New("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 10),
  }, notifStack)
  return notifStack
end

function SpeedyUI:Notify(o)
  o = o or {}
  local stack = ensureNotifs()
  local n = New("CanvasGroup", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Theme.Bg, BackgroundTransparency = 1,
    BorderSizePixel = 0, GroupTransparency = 1,
    Position = UDim2.fromOffset(40, 0),
  }, stack)
  corner(n, 14)
  local ns = stroke(n, Theme.Stroke, 1, 1)
  New("UIPadding", {
    PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11),
    PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13),
  }, n)
  New("UIListLayout", { Padding = UDim.new(0, 3) }, n)
  local dot = New("Frame", {
    Size = UDim2.new(0, 26, 0, 3), BackgroundColor3 = Theme.Red, BorderSizePixel = 0,
  }, n)
  corner(dot, 999)
  local t = label(n, o.Title or "Speedy", 13, Enum.Font.GothamBold, 0)
  t.Size = UDim2.new(1, 0, 0, 16)
  local c = label(n, o.Content or "", 12, Enum.Font.Gotham, 0.25)
  c.Size = UDim2.new(1, 0, 0, 0); c.AutomaticSize = Enum.AutomaticSize.Y
  c.TextWrapped = true

  -- Slide in, hold, slide out
  tween(n, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 })
  tween(n, 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = Theme.BgTrans })
  tween(ns, 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.86 })
  local dur = math.clamp(o.Duration or 3.5, 1, 12)
  task.delay(dur, function()
    if not n.Parent then return end
    tween(n, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { GroupTransparency = 1, Position = UDim2.fromOffset(30, 0) })
    task.delay(0.37, function() pcall(function() n:Destroy() end) end)
  end)
  return n
end

return SpeedyUI
