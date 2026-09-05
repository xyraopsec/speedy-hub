--[[ ============================================================
  MACGLASS v1.0 | dark macOS-glass UI library for Speedy Hub
  Single-file, loadstring-ready. No dependencies.

  Usage:
    local UI = loadstring(game:HttpGet(
      "https://raw.githubusercontent.com/xyraopsec/speedy-hub/test/MacGlass.lua?v=1.0"
    ))()

    local Window = UI:CreateWindow({ Title = "Speedy Hub" })
    local Tab = Window:AddTab("Components")
    Tab:AddToggle({ Title = "Auto Farm", Description = "switchy",
      Callback = function(v) print(v) end })
    UI:Notify({ Title = "Speedy", Content = "Loaded" })
  ============================================================ ]]

local MacGlass = {}
MacGlass.Version = "1.0"
print("[MacGlass] v1.0 loaded")

-- Services --------------------------------------------------------
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Theme: dark glass, white text, red accent -----------------------
local T = {
  WinBg      = Color3.fromRGB(18, 18, 22),
  WinTrans   = 0.28, -- game shows through behind the glass
  SideBg     = Color3.fromRGB(12, 12, 15),
  SideTrans  = 0.15, -- sidebar pane, a touch darker
  RowBg      = Color3.fromRGB(255, 255, 255),
  RowTrans   = 0.94, -- rows: whisper of white
  CardTrans  = 0.87, -- paragraph cards stand off the window
  InsetBg    = Color3.fromRGB(0, 0, 0),
  InsetTrans = 0.5,  -- inputs / switch tracks
  Text       = Color3.fromRGB(255, 255, 255),
  TextSub    = Color3.fromRGB(192, 192, 202),
  TextDim    = Color3.fromRGB(140, 140, 155),
  Red        = Color3.fromRGB(255, 38, 38),
  StrokeT    = 0.88, -- hairline borders
  RWin       = 18,
  RCtl       = 10,
}

-- Utils -----------------------------------------------------------
local function tw(obj, time, style, dir, props)
  local t = TweenService:Create(obj,
    TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
  t:Play()
  return t
end

local function New(class, props, parent)
  local o = Instance.new(class)
  for k, v in pairs(props or {}) do
    if k ~= "Parent" then pcall(function() o[k] = v end) end
  end
  o.Parent = parent or (props and props.Parent)
  return o
end

local function corner(obj, r)
  New("UICorner", { CornerRadius = UDim.new(0, r or T.RCtl) }, obj)
  return obj
end

local function hairline(obj, trans)
  New("UIStroke", {
    Color = Color3.fromRGB(255, 255, 255),
    Transparency = trans or T.StrokeT,
    Thickness = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
  }, obj)
end

-- Full-white label with soft black edge so it reads over glass
local function Lbl(parent, text, size, font, col)
  return New("TextLabel", {
    BackgroundTransparency = 1,
    Text = text or "",
    Font = font or Enum.Font.GothamMedium,
    TextSize = size or 13,
    TextColor3 = col or T.Text,
    TextTransparency = 0,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
    TextStrokeTransparency = 0.75,
  }, parent)
end

local function makeDraggable(frame, handle)
  handle = handle or frame
  local dragging, dragStart, startPos = false, nil, nil
  handle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      dragging, dragStart, startPos = true, input.Position, frame.Position
      input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then dragging = false end
      end)
    end
  end)
  UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
      local d = input.Position - dragStart
      frame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + d.X,
        startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
  end)
end

local function getParent()
  local ok, hui = pcall(function() return gethui() end)
  if ok and hui then return hui end
  local ok2, core = pcall(function() return game:GetService("CoreGui") end)
  if ok2 and core then
    if pcall(function() core:GetChildren() end) then return core end
  end
  return LocalPlayer:WaitForChild("PlayerGui")
end

-- Window ------------------------------------------------------------
function MacGlass:CreateWindow(opts)
  opts = opts or {}
  local size = opts.Size or UDim2.fromOffset(720, 480)
  local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift

  local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1200, 700)
  size = UDim2.fromOffset(math.min(size.X.Offset, vp.X - 24), math.min(size.Y.Offset, vp.Y - 24))

  local parent = getParent()
  if parent:FindFirstChild("MacGlassUI") then parent.MacGlassUI:Destroy() end
  -- Sweep stale blurs + forgotten loader so the game stays bright
  for _, v in ipairs(Lighting:GetChildren()) do
    if v.Name == "SpeedyUIBlur" or v.Name == "SpeedyBlur" then v:Destroy() end
  end
  pcall(function()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 3)
    local stale = pg and pg:FindFirstChild("SpeedyLoader")
    if stale then stale:Destroy() end
  end)

  local gui = New("ScreenGui", {
    Name = "MacGlassUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
  }, parent)

  -- Glass shell
  local shell = New("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.52),
    Size = UDim2.fromOffset(math.floor(size.X.Offset * 0.94), math.floor(size.Y.Offset * 0.94)),
    BackgroundColor3 = T.WinBg,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    GroupTransparency = 1,
  }, gui)
  corner(shell, T.RWin)
  local shellStroke = New("UIStroke", {
    Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Thickness = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
  }, shell)

  local Window = {
    _gui = gui, _shell = shell, _tabs = {}, _pages = {},
    _open = true, _fullSize = size, _mini = false, _conns = {},
  }

  -- Minimal titlebar: traffic lights only, like the reference
  local barH = 44
  local bar = New("Frame", {
    Size = UDim2.new(1, 0, 0, barH), BackgroundTransparency = 1,
  }, shell)

  local lights = New("Frame", {
    Position = UDim2.fromOffset(16, 15), Size = UDim2.fromOffset(62, 15),
    BackgroundTransparency = 1,
  }, bar)
  New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, lights)

  local function traffic(color, glyph, act)
    local b = New("TextButton", {
      Size = UDim2.fromOffset(14, 14), BackgroundColor3 = color,
      Text = "", AutoButtonColor = false,
    }, lights)
    corner(b, 999)
    New("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.85 }, b)
    local g = Lbl(b, glyph, 8, Enum.Font.GothamBold, Color3.fromRGB(60, 0, 0))
    g.Size = UDim2.fromScale(1, 1)
    g.TextXAlignment = Enum.TextXAlignment.Center
    if act then b.MouseButton1Click:Connect(act) end
    return b
  end
  traffic(Color3.fromRGB(255, 95, 87), "✕", function() Window:Destroy() end)
  traffic(Color3.fromRGB(255, 189, 46), "—", function() Window:ToggleMini() end)
  traffic(Color3.fromRGB(40, 200, 64), "⤢", function() Window:ToggleSize() end)

  makeDraggable(shell, bar)

  -- Sidebar pane
  local sideW = 172
  local side = New("Frame", {
    Position = UDim2.fromOffset(0, barH),
    Size = UDim2.new(0, sideW, 1, -barH),
    BackgroundColor3 = T.SideBg,
    BackgroundTransparency = T.SideTrans,
    BorderSizePixel = 0,
  }, shell)
  New("Frame", { -- right hairline
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
    Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9, BorderSizePixel = 0,
  }, side)
  New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, side)
  New("UIPadding", {
    PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
  }, side)

  -- Content scroll
  local content = New("ScrollingFrame", {
    Position = UDim2.fromOffset(sideW, barH),
    Size = UDim2.new(1, -sideW, 1, -barH),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageTransparency = 0.55,
    CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
  }, shell)
  New("UIPadding", {
    PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 18),
    PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 18),
  }, content)

  -- Sidebar groups + tabs ---------------------------------------------
  local Tab = {}; Tab.__index = Tab
  local order = 0
  local function nextOrder() order = order + 1; return order end

  -- Small dim group header in the sidebar ("Main", "Settings")
  function Window:AddSection(name)
    local l = Lbl(side, name, 11, Enum.Font.GothamMedium, T.TextDim)
    l.Size = UDim2.new(1, -8, 0, 20)
    l.Position = UDim2.fromOffset(4, 0)
    l.LayoutOrder = nextOrder()
    return l
  end

  -- Sidebar tab, optional leading icon glyph ("✎"). Page gets a big title.
  function Window:AddTab(name, icon)
    local idx = #self._tabs + 1
    local pill = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 32),
      BackgroundColor3 = T.RowBg, BackgroundTransparency = 1,
      Text = "", AutoButtonColor = false,
      LayoutOrder = nextOrder(),
    }, side)
    corner(pill, 8)

    local ox = 12
    if icon and icon ~= "" then
      local ic = Lbl(pill, icon, 12, Enum.Font.GothamMedium, T.TextDim)
      ic.Size = UDim2.fromOffset(18, 32); ic.Position = UDim2.fromOffset(10, 0)
      ic.TextXAlignment = Enum.TextXAlignment.Center
      ox = 30
    end
    local bl = Lbl(pill, name, 13, Enum.Font.GothamMedium, T.TextDim)
    bl.Size = UDim2.new(1, -ox - 6, 1, 0); bl.Position = UDim2.fromOffset(ox, 0)

    local page = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundTransparency = 1, Visible = false,
    }, content)
    New("UIListLayout", { Padding = UDim.new(0, 8) }, page)
    -- Big page title, like the reference ("Components")
    local h = Lbl(page, name, 22, Enum.Font.GothamBold, T.Text)
    h.Size = UDim2.new(1, 0, 0, 30)

    local tab = setmetatable({ _pill = pill, _label = bl, _page = page, _win = self }, Tab)
    table.insert(self._tabs, tab)
    table.insert(self._pages, page)

    pill.MouseEnter:Connect(function()
      if self._active ~= tab then tw(pill, 0.14, nil, nil, { BackgroundTransparency = 0.9 }) end
    end)
    pill.MouseLeave:Connect(function()
      if self._active ~= tab then tw(pill, 0.16, nil, nil, { BackgroundTransparency = 1 }) end
    end)
    pill.MouseButton1Click:Connect(function() self:SelectTab(idx) end)

    if idx == 1 then task.defer(function() self:SelectTab(1) end) end
    return tab
  end

  function Window:SelectTab(idx)
    local tab = self._tabs[idx]
    if not tab then return end
    self._active = tab
    for i, t in ipairs(self._tabs) do
      local on = (i == idx)
      tw(t._pill, 0.16, nil, nil, { BackgroundTransparency = on and 0.86 or 1 })
      tw(t._label, 0.14, nil, nil, { TextColor3 = on and T.Text or T.TextDim })
      self._pages[i].Visible = on
    end
  end

  -- Open animation: spring pop + fade
  task.delay(0.04, function()
    tw(shell, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
      { Size = size, GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) })
    tw(shell, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
      { BackgroundTransparency = T.WinTrans })
    tw(shellStroke, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
      { Transparency = 0.86 })
  end)

  -- Elements ------------------------------------------------------------
  local function row(parent, h)
    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, h or 48),
      BackgroundColor3 = T.RowBg, BackgroundTransparency = T.RowTrans,
      BorderSizePixel = 0,
    }, parent)
    corner(r, T.RCtl)
    return r
  end

  -- Content section header ("Non Interactable")
  function Tab:AddSection(title)
    local l = Lbl(self._page, title, 14, Enum.Font.GothamSemibold, T.Text)
    l.Size = UDim2.new(1, 0, 0, 20)
    return l
  end

  function Tab:AddLabel(text)
    local r = row(self._page, 30)
    local l = Lbl(r, text, 12, Enum.Font.Gotham, T.TextSub)
    l.Size = UDim2.new(1, -24, 1, 0); l.Position = UDim2.fromOffset(12, 0)
    l.TextWrapped = true
    return r
  end

  function Tab:AddParagraph(o)
    o = o or {}
    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundColor3 = T.RowBg, BackgroundTransparency = T.CardTrans,
      BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)
    hairline(r, 0.9)
    New("UIPadding", {
      PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
      PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
    }, r)
    New("UIListLayout", { Padding = UDim.new(0, 4) }, r)
    if (o.Title or "") ~= "" then
      local t = Lbl(r, o.Title, 13, Enum.Font.GothamBold, T.Text)
      t.Size = UDim2.new(1, 0, 0, 17)
    end
    if (o.Content or "") ~= "" then
      local c = Lbl(r, o.Content, 12, Enum.Font.Gotham, T.TextSub)
      c.Size = UDim2.new(1, 0, 0, 0); c.AutomaticSize = Enum.AutomaticSize.Y
      c.TextWrapped = true
      c.LineHeight = 1.35
    end
    return r
  end

  -- Full-width button row (title + description, whole row clicks)
  function Tab:AddButton(o)
    o = o or {}
    local r = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 48),
      BackgroundColor3 = T.RowBg, BackgroundTransparency = T.RowTrans,
      Text = "", AutoButtonColor = false, BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)
    local t = Lbl(r, o.Title or "Button", 13, Enum.Font.GothamSemibold, T.Text)
    t.Size = UDim2.new(1, -24, 0, 18); t.Position = UDim2.fromOffset(12, 7)
    local d = Lbl(r, o.Description or "clicking", 11, Enum.Font.Gotham, T.TextDim)
    d.Size = UDim2.new(1, -24, 0, 14); d.Position = UDim2.fromOffset(12, 26)
    r.MouseEnter:Connect(function()
      tw(r, 0.14, nil, nil, { BackgroundTransparency = T.RowTrans - 0.06 })
    end)
    r.MouseLeave:Connect(function()
      tw(r, 0.16, nil, nil, { BackgroundTransparency = T.RowTrans })
    end)
    r.MouseButton1Click:Connect(function()
      local orig = r.Size
      tw(r, 0.08, nil, nil, { Size = UDim2.new(1, -6, 0, 46) })
      task.delay(0.09, function()
        if r.Parent then tw(r, 0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = orig }) end
      end)
      if o.Callback then task.spawn(o.Callback) end
    end)
    return r
  end

  -- Toggle row: label left, macOS switch right
  function Tab:AddToggle(o)
    o = o or {}
    local state = o.Default == true
    local r = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 48),
      BackgroundColor3 = T.RowBg, BackgroundTransparency = T.RowTrans,
      Text = "", AutoButtonColor = false, BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)
    local t = Lbl(r, o.Title or "Toggle", 13, Enum.Font.GothamSemibold, T.Text)
    t.Size = UDim2.new(1, -76, 0, 18); t.Position = UDim2.fromOffset(12, 7)
    local d = Lbl(r, o.Description or "", 11, Enum.Font.Gotham, T.TextDim)
    d.Size = UDim2.new(1, -76, 0, 14); d.Position = UDim2.fromOffset(12, 26)

    local sw = New("Frame", {
      AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
      Size = UDim2.fromOffset(46, 26),
      BackgroundColor3 = state and T.Red or Color3.fromRGB(60, 60, 68),
      BackgroundTransparency = state and 0 or 0.25,
      BorderSizePixel = 0,
    }, r)
    corner(sw, 999)
    local knob = New("Frame", {
      AnchorPoint = Vector2.new(0, 0.5),
      Position = state and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
      Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Color3.new(1, 1, 1),
      BorderSizePixel = 0,
    }, sw)
    corner(knob, 999)

    local el = { Value = state }
    local function render(animated)
      tw(sw, animated and 0.2 or 0, nil, nil, {
        BackgroundColor3 = state and T.Red or Color3.fromRGB(60, 60, 68),
        BackgroundTransparency = state and 0 or 0.25,
      })
      tw(knob, animated and 0.24 or 0, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
        Position = state and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
      })
    end
    r.MouseButton1Click:Connect(function()
      state = not state
      el.Value = state
      render(true)
      if o.Callback then task.spawn(o.Callback, state) end
    end)
    function el:Set(v)
      state = v == true
      el.Value = state
      render(true)
    end
    return el
  end

  -- Slider row: label left, track right
  function Tab:AddSlider(o)
    o = o or {}
    local min, max = o.Min or 0, o.Max or 100
    local value = math.clamp(o.Default == nil and min or o.Default, min, max)
    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, 48),
      BackgroundColor3 = T.RowBg, BackgroundTransparency = T.RowTrans,
      BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)
    local t = Lbl(r, o.Title or "Slider", 13, Enum.Font.GothamSemibold, T.Text)
    t.Size = UDim2.new(0, 150, 0, 18); t.Position = UDim2.fromOffset(12, 7)
    local d = Lbl(r, o.Description or "", 11, Enum.Font.Gotham, T.TextDim)
    d.Size = UDim2.new(0, 150, 0, 14); d.Position = UDim2.fromOffset(12, 26)
    local val = Lbl(r, tostring(math.floor(value + 0.5)), 11, Enum.Font.GothamBold, T.TextSub)
    val.Size = UDim2.fromOffset(34, 14)
    val.AnchorPoint = Vector2.new(1, 0.5); val.Position = UDim2.new(1, -14, 0.5, 0)
    val.TextXAlignment = Enum.TextXAlignment.Right

    local track = New("TextButton", {
      AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -56, 0.5, 0),
      Size = UDim2.new(0, 150, 0, 16), BackgroundTransparency = 1,
      Text = "", AutoButtonColor = false,
    }, r)
    local rail = New("Frame", {
      AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
      Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BackgroundTransparency = 0.75, BorderSizePixel = 0,
    }, track)
    corner(rail, 999)
    local fill = New("Frame", {
      Size = UDim2.fromScale((value - min) / math.max(1e-6, max - min), 1),
      BackgroundColor3 = T.Red, BorderSizePixel = 0,
    }, rail)
    corner(fill, 999)
    local knob = New("Frame", {
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.fromScale((value - min) / math.max(1e-6, max - min), 0.5),
      Size = UDim2.fromOffset(15, 15), BackgroundColor3 = Color3.new(1, 1, 1),
      BorderSizePixel = 0,
    }, track)
    corner(knob, 999)

    local el = { Value = value }
    local dragging = false
    local function apply(v, fire)
      value = math.clamp(math.floor(v + 0.5), min, max)
      el.Value = value
      local a = (value - min) / math.max(1e-6, max - min)
      fill.Size = UDim2.fromScale(a, 1)
      knob.Position = UDim2.fromScale(a, 0.5)
      val.Text = tostring(value)
      if fire and o.Callback then task.spawn(o.Callback, value) end
    end
    local function fromInput(input)
      local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
      apply(min + rel * (max - min), true)
    end
    track.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        fromInput(input)
      end
    end)
    UserInputService.InputEnded:Connect(function(input)
      if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = false
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

  -- Input row: label left, inset box right
  function Tab:AddInput(o)
    o = o or {}
    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, 48),
      BackgroundColor3 = T.RowBg, BackgroundTransparency = T.RowTrans,
      BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)
    local t = Lbl(r, o.Title or "Input", 13, Enum.Font.GothamSemibold, T.Text)
    t.Size = UDim2.new(1, -210, 0, 18); t.Position = UDim2.fromOffset(12, 7)
    local d = Lbl(r, o.Description or "", 11, Enum.Font.Gotham, T.TextDim)
    d.Size = UDim2.new(1, -210, 0, 14); d.Position = UDim2.fromOffset(12, 26)
    local box = New("TextBox", {
      AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
      Size = UDim2.new(0, 170, 0, 28),
      BackgroundColor3 = T.InsetBg, BackgroundTransparency = T.InsetTrans,
      Text = "", PlaceholderText = o.Placeholder or "insert",
      PlaceholderColor3 = T.TextDim,
      Font = Enum.Font.Gotham, TextSize = 12,
      TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
      TextStrokeColor3 = Color3.fromRGB(0, 0, 0), TextStrokeTransparency = 0.75,
      ClearTextOnFocus = false, BorderSizePixel = 0,
    }, r)
    corner(box, 8)
    hairline(box, 0.9)
    New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)
    box.FocusLost:Connect(function(enter)
      if o.Callback then task.spawn(o.Callback, box.Text, enter) end
    end)
    local el = { _box = box }
    function el:Set(text) box.Text = text end
    return el
  end

  -- Dropdown row (same row language, expanding option list)
  function Tab:AddDropdown(o)
    o = o or {}
    local options = o.Options or {}
    local current = o.Default or options[1]
    local open = false
    local wrap = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundTransparency = 1,
    }, self._page)
    local head = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 48),
      BackgroundColor3 = T.RowBg, BackgroundTransparency = T.RowTrans,
      Text = "", AutoButtonColor = false, BorderSizePixel = 0,
    }, wrap)
    corner(head, T.RCtl)
    hairline(head, 0.9)
    local t = Lbl(head, o.Title or "Dropdown", 13, Enum.Font.GothamSemibold, T.Text)
    t.Size = UDim2.new(1, -40, 0, 18); t.Position = UDim2.fromOffset(12, 7)
    local c = Lbl(head, tostring(current or "—"), 11, Enum.Font.Gotham, T.TextDim)
    c.Name = "Current"; c.Size = UDim2.new(1, -40, 0, 14); c.Position = UDim2.fromOffset(12, 26)
    local chev = Lbl(head, "›", 16, Enum.Font.GothamBold, T.TextDim)
    chev.Name = "Chev"; chev.Size = UDim2.fromOffset(16, 20)
    chev.AnchorPoint = Vector2.new(1, 0.5); chev.Position = UDim2.new(1, -12, 0.5, 0)
    chev.TextXAlignment = Enum.TextXAlignment.Center
    chev.Rotation = 90
    local list = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundColor3 = Color3.fromRGB(14, 14, 17), BackgroundTransparency = 0.12,
      BorderSizePixel = 0, Visible = false, ClipsDescendants = true,
    }, wrap)
    corner(list, T.RCtl)
    hairline(list, 0.88)
    New("UIPadding", {
      PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
      PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
    }, list)
    New("UIListLayout", { Padding = UDim.new(0, 2) }, list)

    local el = { Value = current }
    local function paint()
      for _, b in ipairs(list:GetChildren()) do
        if b:IsA("TextButton") then
          local on = (b.Name == tostring(current))
          b.BackgroundTransparency = on and 0.82 or 1
          local dot = b:FindFirstChild("Dot")
          if dot then dot.BackgroundTransparency = on and 0 or 1 end
        end
      end
    end
    local function setCurrent(v, fire)
      current = v
      el.Value = v
      c.Text = tostring(v)
      paint()
      if fire and o.Callback then task.spawn(o.Callback, v) end
    end
    local function setOpen(v)
      open = v
      if v then
        list.Visible = true
        tw(chev, 0.16, nil, nil, { Rotation = 270 })
      else
        tw(chev, 0.16, nil, nil, { Rotation = 90 })
        task.delay(0.05, function() if not open then list.Visible = false end end)
      end
    end
    local function rebuild(opts)
      for _, ch in ipairs(list:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
      end
      for _, opt in ipairs(opts) do
        local b = New("TextButton", {
          Name = tostring(opt), Size = UDim2.new(1, 0, 0, 30),
          BackgroundColor3 = T.RowBg, BackgroundTransparency = 1,
          Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        }, list)
        corner(b, 7)
        local dot = New("Frame", {
          Name = "Dot", AnchorPoint = Vector2.new(0, 0.5),
          Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(6, 6),
          BackgroundColor3 = T.Red, BorderSizePixel = 0,
          BackgroundTransparency = (tostring(opt) == tostring(current)) and 0 or 1,
        }, b)
        corner(dot, 999)
        local bl2 = Lbl(b, tostring(opt), 12, Enum.Font.GothamMedium, T.Text)
        bl2.Size = UDim2.new(1, -34, 1, 0); bl2.Position = UDim2.fromOffset(24, 0)
        b.MouseEnter:Connect(function()
          tw(b, 0.12, nil, nil, { BackgroundTransparency = 0.88 })
        end)
        b.MouseLeave:Connect(function() paint() end)
        b.MouseButton1Click:Connect(function()
          setCurrent(opt, true)
          setOpen(false)
        end)
      end
      paint()
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

  -- Keybind row: label left, key pill right
  function Tab:AddKeybind(o)
    o = o or {}
    local bound = o.Default or Enum.KeyCode.F
    local waiting = false
    local r = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 48),
      BackgroundColor3 = T.RowBg, BackgroundTransparency = T.RowTrans,
      Text = "", AutoButtonColor = false, BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)
    local t = Lbl(r, o.Title or "Keybind", 13, Enum.Font.GothamSemibold, T.Text)
    t.Size = UDim2.new(1, -90, 1, 0); t.Position = UDim2.fromOffset(12, 0)
    local pill = New("Frame", {
      AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
      Size = UDim2.fromOffset(60, 26),
      BackgroundColor3 = T.InsetBg, BackgroundTransparency = T.InsetTrans,
      BorderSizePixel = 0,
    }, r)
    corner(pill, 8)
    hairline(pill, 0.88)
    local pl = Lbl(pill, bound.Name, 11, Enum.Font.GothamBold, T.Text)
    pl.Size = UDim2.fromScale(1, 1)
    pl.TextXAlignment = Enum.TextXAlignment.Center
    local el = { Value = bound }
    r.MouseButton1Click:Connect(function()
      waiting = true
      pl.Text = "…"
    end)
    table.insert(Window._conns, UserInputService.InputBegan:Connect(function(input, gpe)
      if waiting then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
          if input.KeyCode ~= Enum.KeyCode.Escape then
            bound = input.KeyCode
            el.Value = bound
          end
          waiting = false
          pl.Text = bound.Name
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
    return el
  end

  -- Window methods ------------------------------------------------------
  function Window:Toggle(force)
    local show = force == nil and not self._open or force
    self._open = show
    if show then
      self._gui.Enabled = true
      tw(shell, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
        { Size = self._curSize or self._fullSize })
      tw(shell, 0.28, nil, nil, { GroupTransparency = 0, BackgroundTransparency = T.WinTrans })
      tw(shellStroke, 0.28, nil, nil, { Transparency = 0.86 })
    else
      tw(shell, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
        Size = UDim2.fromOffset(
          math.floor((self._curSize or self._fullSize).X.Offset * 0.94),
          math.floor((self._curSize or self._fullSize).Y.Offset * 0.94)),
      })
      tw(shell, 0.24, nil, nil, { GroupTransparency = 1 })
      task.delay(0.28, function()
        if not self._open then self._gui.Enabled = false end
      end)
    end
  end

  function Window:ToggleMini()
    self._mini = not self._mini
    local target = self._mini
      and UDim2.fromOffset(self._fullSize.X.Offset, 44 + 20)
      or (self._curSize or self._fullSize)
    if not self._mini then self._curSize = target end
    tw(shell, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = target })
  end

  function Window:ToggleSize()
    local big = UDim2.fromOffset(860, 560)
    local isBig = self._curSize and self._curSize.X.Offset >= 800
    self._curSize = isBig and self._fullSize or big
    tw(shell, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = self._curSize })
  end

  function Window:Destroy()
    tw(shell, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
      Size = UDim2.fromOffset(
        math.floor((self._curSize or self._fullSize).X.Offset * 0.9),
        math.floor((self._curSize or self._fullSize).Y.Offset * 0.9)),
      GroupTransparency = 1,
    })
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    task.delay(0.3, function() pcall(function() gui:Destroy() end) end)
  end

  table.insert(Window._conns, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == toggleKey and input.UserInputType == Enum.UserInputType.Keyboard then
      Window:Toggle()
    end
  end))

  return Window
end

-- Notifications ---------------------------------------------------------
local notifStack
local function ensureNotifs()
  if notifStack and notifStack.Parent then return notifStack end
  local parent = getParent()
  if parent:FindFirstChild("MacGlassNotifs") then parent.MacGlassNotifs:Destroy() end
  local g = New("ScreenGui", {
    Name = "MacGlassNotifs", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
  }, parent)
  notifStack = New("Frame", {
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.new(0, 290, 1, -36), BackgroundTransparency = 1,
  }, g)
  New("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 10),
  }, notifStack)
  return notifStack
end

function MacGlass:Notify(o)
  o = o or {}
  local stack = ensureNotifs()
  local n = New("CanvasGroup", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = T.WinBg, BackgroundTransparency = 1,
    BorderSizePixel = 0, GroupTransparency = 1,
    Position = UDim2.fromOffset(40, 0),
  }, stack)
  corner(n, 14)
  local ns = New("UIStroke", {
    Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Thickness = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
  }, n)
  New("UIPadding", {
    PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11),
    PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13),
  }, n)
  New("UIListLayout", { Padding = UDim.new(0, 3) }, n)
  local dot = New("Frame", {
    Size = UDim2.new(0, 26, 0, 3), BackgroundColor3 = T.Red, BorderSizePixel = 0,
  }, n)
  corner(dot, 999)
  local t = Lbl(n, o.Title or "Speedy", 13, Enum.Font.GothamBold, T.Text)
  t.Size = UDim2.new(1, 0, 0, 16)
  local c = Lbl(n, o.Content or "", 12, Enum.Font.Gotham, T.TextSub)
  c.Size = UDim2.new(1, 0, 0, 0); c.AutomaticSize = Enum.AutomaticSize.Y
  c.TextWrapped = true

  tw(n, 0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
    { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 })
  tw(n, 0.42, nil, nil, { BackgroundTransparency = 0.12 })
  tw(ns, 0.42, nil, nil, { Transparency = 0.86 })
  task.delay(math.clamp(o.Duration or 3.5, 1, 12), function()
    if not n.Parent then return end
    tw(n, 0.32, nil, Enum.EasingDirection.In,
      { GroupTransparency = 1, Position = UDim2.fromOffset(30, 0) })
    task.delay(0.34, function() pcall(function() n:Destroy() end) end)
  end)
  return n
end

return MacGlass
