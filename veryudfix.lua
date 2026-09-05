--[[ ============================================================
  SPEEDY UI  v2.0  |  macOS-style glass UI library for Speedy Hub
  Single-file, loadstring-ready. No dependencies.

  Usage:
    local SpeedyUI = loadstring(game:HttpGet(
      "https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/SpeedyUI.lua?v=2.1"
    ))()

    local Window = SpeedyUI:CreateWindow({
      Title = "Speedy Hub",
      SubTitle = "Driving Empire",
      ToggleKey = Enum.KeyCode.RightShift,
    })
    local Home = Window:AddTab("Home")
    Home:AddToggle({ Title = "Auto Farm", Default = false,
      Callback = function(v) print(v) end })
    SpeedyUI:Notify({ Title = "Speedy", Content = "Loaded" })
  ============================================================ ]]

local SpeedyUI = {}
SpeedyUI.Version = "2.1"
print("[SpeedyUI] v2.1 loaded — no GroupTransparency, text always readable")

-- ── Services ──────────────────────────────────────────────────
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer

-- ── Design tokens ─────────────────────────────────────────────
-- Rule: window bg at BgTrans=0.12 → game shows through subtly.
-- All text at 0 transparency. Stroke at 0.78 on dark = crisp edge.
local T = {
  -- Core palette
  Red         = Color3.fromRGB(255, 38, 38),
  RedHover    = Color3.fromRGB(255, 68, 68),
  RedDim      = Color3.fromRGB(200, 30, 30),

  -- Window layers
  WinBg       = Color3.fromRGB(16, 16, 20),   -- shell base (near-black)
  WinTrans    = 0.25,                          -- glass: hint of game behind

  SideBg      = Color3.fromRGB(28, 28, 34),   -- sidebar lifted off pure black
  SideTrans   = 0.1,

  RowBg       = Color3.fromRGB(255, 255, 255), -- row tint color (white)
  RowTrans    = 0.94,                          -- 6% white = subtle lift

  InsetBg     = Color3.fromRGB(0, 0, 0),      -- inputs / controls
  InsetTrans  = 0.55,                          -- 45% black = dark inset

  -- Typography
  Text        = Color3.fromRGB(255, 255, 255), -- primary text
  TextSub     = Color3.fromRGB(190, 190, 200), -- secondary / description
  TextDim     = Color3.fromRGB(130, 130, 145), -- tertiary / placeholders

  -- Borders
  Stroke      = Color3.fromRGB(255, 255, 255),
  StrokeTrans = 0.82,                          -- white at 82% on dark = clean edge

  StrokeRed   = Color3.fromRGB(255, 38, 38),
  StrokeRedT  = 0.7,

  -- Geometry
  RWin = 16,   -- window radius
  RCtl = 9,    -- control radius
  RSmall = 6,  -- small pill radius
}

-- ── Helpers ───────────────────────────────────────────────────
local function tw(obj, t, style, dir, props)
  local info = TweenInfo.new(t or 0.22,
    style or Enum.EasingStyle.Quad,
    dir   or Enum.EasingDirection.Out)
  TweenService:Create(obj, info, props):Play()
end

local function springPop(obj)
  local s = obj.Size
  tw(obj, 0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
    { Size = UDim2.new(s.X.Scale, s.X.Offset * 0.95, s.Y.Scale, s.Y.Offset * 0.95) })
  task.delay(0.08, function()
    if obj and obj.Parent then
      tw(obj, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = s })
    end
  end)
end

local function New(class, props, parent)
  local o = Instance.new(class)
  for k, v in pairs(props or {}) do
    if k ~= "Parent" then pcall(function() o[k] = v end) end
  end
  o.Parent = parent
  return o
end

local function corner(obj, r)
  New("UICorner", { CornerRadius = UDim.new(0, r or T.RCtl) }, obj)
  return obj
end

local function addStroke(obj, col, trans, thick)
  New("UIStroke", {
    Color = col or T.Stroke,
    Transparency = trans ~= nil and trans or T.StrokeTrans,
    Thickness = thick or 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
  }, obj)
end

-- Primary label — full white, shadow for depth not readability
local function Lbl(parent, text, size, font, col, align)
  local l = New("TextLabel", {
    BackgroundTransparency = 1,
    Text = text or "",
    Font = font or Enum.Font.GothamMedium,
    TextSize = size or 13,
    TextColor3 = col or T.Text,
    TextTransparency = 0,
    TextXAlignment = align or Enum.TextXAlignment.Left,
    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
    TextStrokeTransparency = 0.55,
  }, parent)
  return l
end

-- Draggable handle
local function makeDraggable(frame, handle)
  handle = handle or frame
  local dragging, dragStart, startPos = false, nil, nil
  handle.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
      dragging, dragStart, startPos = true, inp.Position, frame.Position
      inp.Changed:Connect(function()
        if inp.UserInputState == Enum.UserInputState.End then dragging = false end
      end)
    end
  end)
  UserInputService.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
      local d = inp.Position - dragStart
      frame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + d.X,
        startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
  end)
end

-- Safe GUI parent (gethui > CoreGui > PlayerGui)
local function guiParent()
  local ok, h = pcall(gethui)
  if ok and h then return h end
  local ok2, c = pcall(function() return game:GetService("CoreGui") end)
  if ok2 and c then
    local ok3 = pcall(function() c:GetChildren() end)
    if ok3 then return c end
  end
  return LocalPlayer:WaitForChild("PlayerGui")
end

-- Row hover tween helpers
local function hoverIn(r)
  tw(r, 0.14, nil, nil, { BackgroundTransparency = T.RowTrans - 0.05 })
end
local function hoverOut(r)
  tw(r, 0.18, nil, nil, { BackgroundTransparency = T.RowTrans })
end
local function wireHover(r) r.MouseEnter:Connect(function() hoverIn(r) end) r.MouseLeave:Connect(function() hoverOut(r) end) end

-- ── WINDOW ────────────────────────────────────────────────────
function SpeedyUI:CreateWindow(opts)
  opts = opts or {}
  local title     = opts.Title     or "Speedy Hub"
  local sub       = opts.SubTitle  or ""
  local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
  local vp        = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
  local W         = math.min(opts.Width  or 560, vp.X - 24)
  local H         = math.min(opts.Height or 440, vp.Y - 24)
  local SideW     = 140
  local BarH      = 44

  -- Clean up stale instances
  local parent = guiParent()
  if parent:FindFirstChild("SpeedyUI") then parent.SpeedyUI:Destroy() end
  for _, v in ipairs(Lighting:GetChildren()) do
    if v.Name == "SpeedyUIBlur" or v.Name == "SpeedyBlur" then v:Destroy() end
  end
  pcall(function()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local stale = pg and pg:FindFirstChild("SpeedyLoader")
    if stale then stale:Destroy() end
  end)

  local gui = New("ScreenGui", {
    Name = "SpeedyUI", ResetOnSpawn = false,
    IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
  }, parent)

  -- ── Shell (main window) ──────────────────────────────────────
  -- Plain Frame — CanvasGroup was dimming all child text via GroupTransparency
  local shell = New("Frame", {
    Name = "Shell",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(W * 0.88, H * 0.88),  -- starts small; springs to full
    BackgroundColor3 = T.WinBg,
    BackgroundTransparency = 1,  -- fades in during open animation
    BorderSizePixel = 0,
    ClipsDescendants = true,
  }, gui)
  corner(shell, T.RWin)
  -- Crisp glass border
  addStroke(shell, T.Stroke, T.StrokeTrans, 1)

  -- Very subtle top-to-bottom gradient lightens the top edge (macOS depth cue)
  New("UIGradient", {
    Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0,   Color3.fromRGB(40, 40, 52)),
      ColorSequenceKeypoint.new(1,   Color3.fromRGB(14, 14, 18)),
    }),
    Rotation = 90,
    Transparency = NumberSequence.new(0, 0.04),
  }, shell)

  -- ── Titlebar ─────────────────────────────────────────────────
  local titlebar = New("Frame", {
    Name = "Titlebar",
    Size = UDim2.new(1, 0, 0, BarH),
    BackgroundTransparency = 1,
  }, shell)

  -- macOS traffic lights
  local lights = New("Frame", {
    Position = UDim2.fromOffset(14, 15),
    Size = UDim2.fromOffset(58, 14),
    BackgroundTransparency = 1,
  }, titlebar)
  New("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Center,
  }, lights)

  local Window = {
    _gui = gui, _shell = shell, _tabs = {}, _pages = {},
    _open = false, _mini = false, _conns = {},
    _fullSize = UDim2.fromOffset(W, H),
    _curSize  = UDim2.fromOffset(W, H),
  }

  local function trafficBtn(col, glyph, action)
    local b = New("TextButton", {
      Size = UDim2.fromOffset(12, 12),
      BackgroundColor3 = col,
      Text = "", AutoButtonColor = false,
    }, lights)
    corner(b, 999)
    -- glyph label — visible always for accessibility
    local g = Lbl(b, glyph, 7, Enum.Font.GothamBold,
      Color3.fromRGB(60, 30, 0), Enum.TextXAlignment.Center)
    g.Size = UDim2.fromScale(1, 1)
    g.TextTransparency = 0.5
    b.MouseEnter:Connect(function()
      tw(b, 0.12, nil, nil, { BackgroundColor3 = b.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.15) })
      tw(g, 0.1, nil, nil, { TextTransparency = 0 })
    end)
    b.MouseLeave:Connect(function()
      tw(b, 0.18, nil, nil, { BackgroundColor3 = col })
      tw(g, 0.12, nil, nil, { TextTransparency = 0.5 })
    end)
    if action then b.MouseButton1Click:Connect(action) end
    return b
  end

  trafficBtn(Color3.fromRGB(255, 95,  87),  "✕", function() Window:Destroy() end)
  trafficBtn(Color3.fromRGB(255, 189, 46),  "—", function() Window:ToggleMini() end)
  trafficBtn(Color3.fromRGB(39,  200, 64),  "⤢", function() Window:ToggleSize() end)

  -- Title + subtitle (centered)
  local titleWrap = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.fromScale(0.5, 0),
    Size = UDim2.fromOffset(280, BarH),
    BackgroundTransparency = 1,
  }, titlebar)
  local t1 = Lbl(titleWrap, title, 15, Enum.Font.GothamBlack, T.Text, Enum.TextXAlignment.Center)
  t1.Size = UDim2.new(1, 0, 0, 18)
  t1.Position = UDim2.fromOffset(0, 7)
  if sub ~= "" then
    local t2 = Lbl(titleWrap, sub, 10, Enum.Font.GothamMedium, T.TextDim, Enum.TextXAlignment.Center)
    t2.Size = UDim2.new(1, 0, 0, 12)
    t2.Position = UDim2.fromOffset(0, 27)
  end

  -- Hairline separator below titlebar
  New("Frame", {
    Position = UDim2.fromOffset(0, BarH),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = T.Stroke,
    BackgroundTransparency = 0.88,
    BorderSizePixel = 0,
  }, shell)

  makeDraggable(shell, titlebar)

  -- ── Sidebar ───────────────────────────────────────────────────
  -- Slightly darker pane on the left for tab pills
  local sidePanel = New("Frame", {
    Position = UDim2.fromOffset(0, BarH + 1),
    Size = UDim2.new(0, SideW, 1, -(BarH + 1)),
    BackgroundColor3 = T.SideBg,
    BackgroundTransparency = T.SideTrans,
    BorderSizePixel = 0,
  }, shell)
  -- Right edge hairline separating sidebar from content
  New("Frame", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.fromScale(1, 0),
    Size = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = T.Stroke,
    BackgroundTransparency = 0.88,
    BorderSizePixel = 0,
  }, sidePanel)
  local sideList = New("UIListLayout", {
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
  }, sidePanel)
  New("UIPadding", {
    PaddingTop    = UDim.new(0, 10),
    PaddingLeft   = UDim.new(0, 8),
    PaddingRight  = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
  }, sidePanel)

  -- ── Content area ─────────────────────────────────────────────
  local content = New("ScrollingFrame", {
    Position = UDim2.fromOffset(SideW + 1, BarH + 1),
    Size = UDim2.new(1, -(SideW + 1), 1, -(BarH + 1)),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
  }, shell)
  New("UIPadding", {
    PaddingTop    = UDim.new(0, 12),
    PaddingBottom = UDim.new(0, 16),
    PaddingLeft   = UDim.new(0, 10),
    PaddingRight  = UDim.new(0, 12),
  }, content)

  -- ── Tab system ───────────────────────────────────────────────
  local Tab = {}; Tab.__index = Tab

  function Window:AddTab(name, icon)
    local idx = #self._tabs + 1

    -- Sidebar pill button
    local pill = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 32),
      BackgroundColor3 = T.Red,
      BackgroundTransparency = 1,   -- inactive = transparent
      Text = "", AutoButtonColor = false,
      LayoutOrder = idx,
    }, sidePanel)
    corner(pill, T.RSmall)

    -- Active indicator bar (left edge)
    local bar = New("Frame", {
      AnchorPoint = Vector2.new(0, 0.5),
      Position = UDim2.new(0, 7, 0.5, 0),   -- inside the pill, never clipped
      Size = UDim2.fromOffset(3, 0),
      BackgroundColor3 = T.Red,
      BorderSizePixel = 0,
    }, pill)
    corner(bar, 999)

    -- Tab label (full white, offset clear of the indicator bar)
    local bl = Lbl(pill, name, 13, Enum.Font.GothamSemibold, T.Text)
    bl.Size = UDim2.new(1, -21, 1, 0)
    bl.Position = UDim2.fromOffset(15, 0)

    -- Content page for this tab — plain Frame so GroupTransparency never dims text
    local page = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundTransparency = 1,
      Visible = false,
    }, content)
    New("UIListLayout", { Padding = UDim.new(0, 7) }, page)

    local tab = setmetatable({
      _pill = pill, _bar = bar, _label = bl,
      _page = page, _win = self
    }, Tab)
    table.insert(self._tabs, tab)
    table.insert(self._pages, page)

    pill.MouseEnter:Connect(function()
      if self._active ~= tab then
        tw(pill, 0.14, nil, nil, { BackgroundTransparency = 0.88 })
      end
    end)
    pill.MouseLeave:Connect(function()
      if self._active ~= tab then
        tw(pill, 0.18, nil, nil, { BackgroundTransparency = 1 })
      end
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
      -- Pill background
      tw(t._pill, 0.18, nil, nil, { BackgroundTransparency = on and 0.82 or 1 })
      -- Indicator bar
      tw(t._bar, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
        { Size = UDim2.fromOffset(3, on and 16 or 0) })
      -- Label color (always full white; active shown by pill + bar)
      tw(t._label, 0.15, nil, nil, {
        TextColor3 = T.Text,
        TextTransparency = 0,
      })
      -- Page visibility — instant swap, no GroupTransparency (would dim text)
      local pg = self._pages[i]
      if on then
        pg.Visible = true
      else
        pg.Visible = false
      end
    end
  end

  -- Open animation — spring size pop; NO GroupTransparency (would dim all text)
  -- Shell starts small and invisible via BackgroundTransparency=1; we animate to correct size
  shell.BackgroundTransparency = 1
  shell.Size = UDim2.fromOffset(W * 0.88, H * 0.88)
  task.delay(0.04, function()
    tw(shell, 0.52, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
      { Size = Window._fullSize,
        BackgroundTransparency = T.WinTrans,
        Position = UDim2.fromScale(0.5, 0.5) })
  end)
  Window._open = true

  -- ── Element builders ─────────────────────────────────────────
  -- Standard row frame
  local function row(parent, h)
    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, h or 42),
      BackgroundColor3 = T.RowBg,
      BackgroundTransparency = T.RowTrans,
      BorderSizePixel = 0,
    }, parent)
    corner(r, T.RCtl)
    return r
  end

  -- Section header (all caps, dimmed)
  function Tab:AddSection(title)
    local wrap = New("Frame", {
      Size = UDim2.new(1, 0, 0, 22),
      BackgroundTransparency = 1,
    }, self._page)
    local l = Lbl(wrap, string.upper(title), 10, Enum.Font.GothamBold, T.TextDim)
    l.Size = UDim2.new(1, -4, 1, 0)
    l.Position = UDim2.fromOffset(4, 0)
    -- Red accent line beside the text
    local accent = New("Frame", {
      AnchorPoint = Vector2.new(0, 0.5),
      Position = UDim2.fromOffset(0, 11),
      Size = UDim2.fromOffset(2, 10),
      BackgroundColor3 = T.Red,
      BorderSizePixel = 0,
    }, wrap)
    corner(accent, 999)
    return wrap
  end

  function Tab:AddLabel(text)
    local r = row(self._page, 32)
    local l = Lbl(r, text, 12, Enum.Font.Gotham, T.TextSub)
    l.Size = UDim2.new(1, -20, 1, 0); l.Position = UDim2.fromOffset(10, 0)
    l.TextWrapped = true
    return r
  end

  function Tab:AddParagraph(o)
    o = o or {}
    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundColor3 = T.RowBg,
      BackgroundTransparency = 0.86, -- lifted off the window so it reads as a card
      BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)
    addStroke(r, T.Stroke, T.StrokeTrans + 0.04, 1)
    New("UIPadding", {
      PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
      PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
    }, r)
    New("UIListLayout", { Padding = UDim.new(0, 5) }, r)

    local title = o.Title or ""
    if title ~= "" then
      local t = Lbl(r, title, 13, Enum.Font.GothamBold, T.Text)
      t.Size = UDim2.new(1, 0, 0, 16)
    end
    local content = o.Content or ""
    if content ~= "" then
      local c = Lbl(r, content, 12, Enum.Font.Gotham, T.TextSub)
      c.Size = UDim2.new(1, 0, 0, 0)
      c.AutomaticSize = Enum.AutomaticSize.Y
      c.TextWrapped = true
      c.LineHeight = 1.35
    end
    return r
  end

  function Tab:AddButton(o)
    o = o or {}
    local r = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 36),
      BackgroundColor3 = T.Red,
      BackgroundTransparency = 0.35, -- vivid red, not muddy
      Text = "", AutoButtonColor = false,
      BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)
    addStroke(r, T.StrokeRed, T.StrokeRedT, 1)

    local l = Lbl(r, o.Title or "Button", 13, Enum.Font.GothamSemibold,
      T.Text, Enum.TextXAlignment.Center)
    l.Size = UDim2.fromScale(1, 1)

    r.MouseEnter:Connect(function()
      tw(r, 0.14, nil, nil, { BackgroundTransparency = 0.22 })
    end)
    r.MouseLeave:Connect(function()
      tw(r, 0.18, nil, nil, { BackgroundTransparency = 0.35 })
    end)
    r.MouseButton1Click:Connect(function()
      springPop(r)
      if o.Callback then task.spawn(o.Callback) end
    end)

    if o.Description and o.Description ~= "" then
      r.Size = UDim2.new(1, 0, 0, 50)
      l.Size = UDim2.new(1, -20, 0, 18); l.Position = UDim2.fromOffset(10, 7)
      l.TextXAlignment = Enum.TextXAlignment.Left
      local d = Lbl(r, o.Description, 11, Enum.Font.Gotham, T.TextDim)
      d.Size = UDim2.new(1, -20, 0, 13); d.Position = UDim2.fromOffset(10, 28)
    end
    return r
  end

  function Tab:AddToggle(o)
    o = o or {}
    local state = o.Default == true
    local r = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 44),
      BackgroundColor3 = T.RowBg,
      BackgroundTransparency = T.RowTrans,
      Text = "", AutoButtonColor = false,
      BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)

    -- Title
    local t = Lbl(r, o.Title or "Toggle", 13, Enum.Font.GothamSemibold, T.Text)
    t.Size = UDim2.new(1, -68, 0, 17); t.Position = UDim2.fromOffset(12, 7)

    -- Description
    if o.Description and o.Description ~= "" then
      local d = Lbl(r, o.Description, 11, Enum.Font.Gotham, T.TextSub)
      d.Size = UDim2.new(1, -68, 0, 13); d.Position = UDim2.fromOffset(12, 25)
    end

    -- macOS-style switch
    local track = New("Frame", {
      AnchorPoint = Vector2.new(1, 0.5),
      Position = UDim2.new(1, -12, 0.5, 0),
      Size = UDim2.fromOffset(42, 23),
      BackgroundColor3 = state and T.Red or Color3.fromRGB(60, 60, 70),
      BackgroundTransparency = 0,
      BorderSizePixel = 0,
    }, r)
    corner(track, 999)

    local knob = New("Frame", {
      AnchorPoint = Vector2.new(0, 0.5),
      Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
      Size = UDim2.fromOffset(17, 17),
      BackgroundColor3 = Color3.new(1, 1, 1),
      BorderSizePixel = 0,
    }, track)
    corner(knob, 999)
    -- Knob shadow
    New("UIStroke", {
      Color = Color3.fromRGB(0,0,0), Transparency = 0.65, Thickness = 1,
      ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, knob)

    local el = { Value = state }
    local function render(anim)
      local dur = anim and 0.22 or 0
      tw(track, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
        BackgroundColor3 = state and T.Red or Color3.fromRGB(60, 60, 70),
      })
      tw(knob, anim and 0.24 or 0, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
        Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
      })
    end
    local function flip()
      state = not state; el.Value = state
      render(true)
      if o.Callback then task.spawn(o.Callback, state) end
    end
    r.MouseButton1Click:Connect(flip)
    wireHover(r)
    function el:Set(v) state = v == true; el.Value = state; render(true) end
    return el
  end

  function Tab:AddSlider(o)
    o = o or {}
    local min   = o.Min or 0
    local max   = o.Max or 100
    local rnd   = o.Rounding or 0
    local value = math.clamp(o.Default ~= nil and o.Default or min, min, max)

    local function fmt(v)
      if rnd <= 0 then return tostring(math.floor(v + 0.5)) end
      return string.format("%." .. rnd .. "f", v)
    end

    local r = New("Frame", {
      Size = UDim2.new(1, 0, 0, 54),
      BackgroundColor3 = T.RowBg,
      BackgroundTransparency = T.RowTrans,
      BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)

    local titleLbl = Lbl(r, o.Title or "Slider", 13, Enum.Font.GothamSemibold, T.Text)
    titleLbl.Size = UDim2.new(1, -70, 0, 16); titleLbl.Position = UDim2.fromOffset(12, 6)

    local valLbl = Lbl(r, fmt(value), 12, Enum.Font.GothamBold, T.Red, Enum.TextXAlignment.Right)
    valLbl.AnchorPoint = Vector2.new(1, 0)
    valLbl.Size = UDim2.fromOffset(56, 16); valLbl.Position = UDim2.new(1, -12, 0, 6)

    -- Track area (invisible button so we can capture input anywhere)
    local trackBtn = New("TextButton", {
      Position = UDim2.fromOffset(12, 32),
      Size = UDim2.new(1, -24, 0, 16),
      BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
    }, r)

    -- Rail
    local rail = New("Frame", {
      AnchorPoint = Vector2.new(0, 0.5),
      Position = UDim2.new(0, 0, 0.5, 0),
      Size = UDim2.new(1, 0, 0, 4),
      BackgroundColor3 = Color3.fromRGB(70, 70, 80),
      BackgroundTransparency = 0,
      BorderSizePixel = 0,
    }, trackBtn)
    corner(rail, 999)

    -- Fill
    local fill = New("Frame", {
      Size = UDim2.fromScale((value - min) / math.max(1e-6, max - min), 1),
      BackgroundColor3 = T.Red,
      BorderSizePixel = 0,
    }, rail)
    corner(fill, 999)
    -- Gradient on fill
    New("UIGradient", {
      Color = ColorSequence.new(T.Red, T.RedHover),
      Rotation = 0,
    }, fill)

    -- Knob
    local knob = New("Frame", {
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.fromScale((value - min) / math.max(1e-6, max - min), 0.5),
      Size = UDim2.fromOffset(14, 14),
      BackgroundColor3 = Color3.new(1, 1, 1),
      BorderSizePixel = 0,
    }, trackBtn)
    corner(knob, 999)
    New("UIStroke", {
      Color = Color3.fromRGB(0,0,0), Transparency = 0.7, Thickness = 1,
      ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, knob)

    local el = { Value = value }
    local dragging = false

    local function apply(v, fire)
      value = math.clamp(v, min, max); el.Value = value
      local a = (value - min) / math.max(1e-6, max - min)
      fill.Size = UDim2.fromScale(a, 1)
      knob.Position = UDim2.fromScale(a, 0.5)
      valLbl.Text = fmt(value)
      if fire and o.Callback then task.spawn(o.Callback, value) end
    end

    local function fromInput(inp)
      local rel = math.clamp(
        (inp.Position.X - trackBtn.AbsolutePosition.X) / math.max(1, trackBtn.AbsoluteSize.X), 0, 1)
      local v = min + rel * (max - min)
      if rnd > 0 then
        local m = 10^rnd; v = math.floor(v * m + 0.5) / m
      else
        v = math.floor(v + 0.5)
      end
      apply(v, true)
    end

    trackBtn.InputBegan:Connect(function(inp)
      if inp.UserInputType == Enum.UserInputType.MouseButton1
      or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        tw(knob, 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
          { Size = UDim2.fromOffset(18, 18) })
        fromInput(inp)
      end
    end)
    table.insert(Window._conns, UserInputService.InputEnded:Connect(function(inp)
      if dragging and (inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch) then
        dragging = false
        tw(knob, 0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
          { Size = UDim2.fromOffset(14, 14) })
      end
    end))
    table.insert(Window._conns, UserInputService.InputChanged:Connect(function(inp)
      if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
        fromInput(inp)
      end
    end))

    function el:Set(v) apply(v, false) end
    return el
  end

  function Tab:AddInput(o)
    o = o or {}
    local r = row(self._page, 58)

    local t = Lbl(r, o.Title or "Input", 13, Enum.Font.GothamSemibold, T.Text)
    t.Size = UDim2.new(1, -20, 0, 16); t.Position = UDim2.fromOffset(12, 7)

    local box = New("TextBox", {
      Position = UDim2.fromOffset(12, 30),
      Size = UDim2.new(1, -24, 0, 22),
      BackgroundColor3 = T.InsetBg,
      BackgroundTransparency = T.InsetTrans,
      Text = "",
      PlaceholderText = o.Placeholder or "Type here…",
      PlaceholderColor3 = T.TextDim,
      Font = Enum.Font.Gotham, TextSize = 12,
      TextColor3 = T.Text,
      TextXAlignment = Enum.TextXAlignment.Left,
      ClearTextOnFocus = false,
      BorderSizePixel = 0,
    }, r)
    corner(box, 6)
    addStroke(box, T.Stroke, T.StrokeTrans + 0.04, 1)
    New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)

    box.Focused:Connect(function()
      tw(box, 0.14, nil, nil, { BackgroundTransparency = T.InsetTrans - 0.1 })
    end)
    box.FocusLost:Connect(function(enter)
      tw(box, 0.18, nil, nil, { BackgroundTransparency = T.InsetTrans })
      if o.Callback then task.spawn(o.Callback, box.Text, enter) end
    end)

    local el = { _box = box }
    function el:Set(text) box.Text = text end
    return el
  end

  function Tab:AddDropdown(o)
    o = o or {}
    local options = o.Options or {}
    local current = o.Default or options[1]
    local open = false

    local wrap = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundTransparency = 1,
    }, self._page)
    New("UIListLayout", { Padding = UDim.new(0, 2) }, wrap)

    local head = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 44),
      BackgroundColor3 = T.RowBg,
      BackgroundTransparency = T.RowTrans,
      Text = "", AutoButtonColor = false,
      BorderSizePixel = 0,
    }, wrap)
    corner(head, T.RCtl)

    local titleLbl = Lbl(head, o.Title or "Dropdown", 13, Enum.Font.GothamSemibold, T.Text)
    titleLbl.Size = UDim2.new(1, -34, 0, 17); titleLbl.Position = UDim2.fromOffset(12, 6)

    local currLbl = Lbl(head, tostring(current or "—"), 11, Enum.Font.Gotham, T.TextSub)
    currLbl.Size = UDim2.new(1, -34, 0, 13); currLbl.Position = UDim2.fromOffset(12, 25)

    local chev = Lbl(head, "›", 16, Enum.Font.GothamBold, T.TextDim, Enum.TextXAlignment.Center)
    chev.Size = UDim2.fromOffset(20, 20)
    chev.AnchorPoint = Vector2.new(1, 0.5)
    chev.Position = UDim2.new(1, -10, 0.5, 0)
    chev.Rotation = 90

    local list = New("Frame", {
      Size = UDim2.new(1, 0, 0, 0),
      AutomaticSize = Enum.AutomaticSize.None,
      BackgroundColor3 = Color3.fromRGB(12, 12, 16),
      BackgroundTransparency = 0.06,
      BorderSizePixel = 0,
      Visible = false, ClipsDescendants = true,
    }, wrap)
    corner(list, T.RCtl)
    addStroke(list, T.Stroke, T.StrokeTrans, 1)
    New("UIPadding", {
      PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
      PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
    }, list)
    New("UIListLayout", { Padding = UDim.new(0, 2) }, list)

    local el = { Value = current }

    local function setCurrent(v, fire)
      current = v; el.Value = v
      currLbl.Text = tostring(v)
      for _, b in ipairs(list:GetChildren()) do
        if b:IsA("TextButton") then
          local on = (b.Name == tostring(v))
          tw(b, 0.12, nil, nil, { BackgroundTransparency = on and 0.82 or 1 })
          local dot = b:FindFirstChild("Dot")
          if dot then dot.BackgroundTransparency = on and 0 or 1 end
        end
      end
      if fire and o.Callback then task.spawn(o.Callback, v) end
    end

    local function setOpen(v)
      open = v
      if v then
        list.Visible = true
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        tw(chev, 0.18, nil, nil, { Rotation = 270 })
      else
        tw(chev, 0.18, nil, nil, { Rotation = 90 })
        list.AutomaticSize = Enum.AutomaticSize.None
        tw(list, 0.18, nil, nil, { Size = UDim2.new(1, 0, 0, 0) })
        task.delay(0.2, function() if not open and list.Parent then list.Visible = false end end)
      end
    end

    local function rebuild(opts)
      for _, ch in ipairs(list:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
      end
      for _, opt in ipairs(opts) do
        local b = New("TextButton", {
          Name = tostring(opt),
          Size = UDim2.new(1, 0, 0, 30),
          BackgroundColor3 = T.Red,
          BackgroundTransparency = 1,
          Text = "", AutoButtonColor = false,
        }, list)
        corner(b, 6)
        local dot = New("Frame", {
          Name = "Dot",
          AnchorPoint = Vector2.new(0, 0.5),
          Position = UDim2.new(0, 10, 0.5, 0),
          Size = UDim2.fromOffset(5, 5),
          BackgroundColor3 = T.Red, BorderSizePixel = 0,
          BackgroundTransparency = (tostring(opt) == tostring(current)) and 0 or 1,
        }, b)
        corner(dot, 999)
        local bl = Lbl(b, tostring(opt), 12, Enum.Font.GothamMedium, T.Text)
        bl.Size = UDim2.new(1, -30, 1, 0); bl.Position = UDim2.fromOffset(24, 0)

        b.MouseEnter:Connect(function()
          tw(b, 0.12, nil, nil, { BackgroundTransparency = 0.88 })
        end)
        b.MouseLeave:Connect(function()
          if b.Name ~= tostring(current) then
            tw(b, 0.14, nil, nil, { BackgroundTransparency = 1 })
          end
        end)
        b.MouseButton1Click:Connect(function()
          springPop(b)
          setCurrent(opt, true)
          setOpen(false)
        end)
      end
    end

    head.MouseEnter:Connect(function() tw(head, 0.14, nil, nil, { BackgroundTransparency = T.RowTrans - 0.05 }) end)
    head.MouseLeave:Connect(function() tw(head, 0.18, nil, nil, { BackgroundTransparency = T.RowTrans }) end)
    head.MouseButton1Click:Connect(function() setOpen(not open) end)

    rebuild(options)
    setCurrent(current, false)

    function el:Set(v) setCurrent(v, false) end
    function el:Refresh(opts) options = opts; rebuild(opts); if #opts > 0 and not table.find(opts, current) then setCurrent(opts[1], false) end end
    return el
  end

  function Tab:AddKeybind(o)
    o = o or {}
    local bound = o.Default or Enum.KeyCode.F
    local waiting = false

    local r = New("TextButton", {
      Size = UDim2.new(1, 0, 0, 40),
      BackgroundColor3 = T.RowBg,
      BackgroundTransparency = T.RowTrans,
      Text = "", AutoButtonColor = false,
      BorderSizePixel = 0,
    }, self._page)
    corner(r, T.RCtl)

    local t = Lbl(r, o.Title or "Keybind", 13, Enum.Font.GothamSemibold, T.Text)
    t.Size = UDim2.new(1, -80, 1, 0); t.Position = UDim2.fromOffset(12, 0)

    local pill = New("Frame", {
      AnchorPoint = Vector2.new(1, 0.5),
      Position = UDim2.new(1, -10, 0.5, 0),
      Size = UDim2.fromOffset(58, 24),
      BackgroundColor3 = T.InsetBg,
      BackgroundTransparency = T.InsetTrans,
      BorderSizePixel = 0,
    }, r)
    corner(pill, 6)
    addStroke(pill, T.Stroke, T.StrokeTrans, 1)

    local pl = Lbl(pill, bound.Name, 11, Enum.Font.GothamBold, T.Text, Enum.TextXAlignment.Center)
    pl.Size = UDim2.fromScale(1, 1)

    local el = { Value = bound }
    r.MouseButton1Click:Connect(function()
      waiting = true
      pl.Text = "…"
      tw(pill, 0.14, nil, nil, {
        BackgroundColor3 = T.Red,
        BackgroundTransparency = 0.6,
      })
    end)

    table.insert(Window._conns, UserInputService.InputBegan:Connect(function(inp, gpe)
      if waiting then
        if inp.UserInputType == Enum.UserInputType.Keyboard
        and inp.KeyCode ~= Enum.KeyCode.Unknown then
          if inp.KeyCode == Enum.KeyCode.Escape then
            waiting = false; pl.Text = bound.Name
          else
            waiting = false; bound = inp.KeyCode
            el.Value = bound; pl.Text = bound.Name
          end
          tw(pill, 0.18, nil, nil, {
            BackgroundColor3 = T.InsetBg,
            BackgroundTransparency = T.InsetTrans,
          })
        end
        return
      end
      if not gpe and inp.KeyCode == bound
      and inp.UserInputType == Enum.UserInputType.Keyboard then
        if o.Callback then task.spawn(o.Callback) end
      end
    end))

    wireHover(r)
    function el:Set(k) bound = k; el.Value = k; pl.Text = k.Name end
    return el
  end

  -- ── Window methods ────────────────────────────────────────────
  function Window:Toggle(force)
    local show = force == nil and not self._open or force
    self._open = show
    if show then
      self._gui.Enabled = true
      shell.Visible = true
      tw(shell, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
        { Size = self._curSize, BackgroundTransparency = T.WinTrans })
    else
      tw(shell, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
        Size = UDim2.fromOffset(self._curSize.X.Offset * 0.88, self._curSize.Y.Offset * 0.88),
        BackgroundTransparency = 1,
      })
      task.delay(0.3, function()
        if not self._open then
          self._gui.Enabled = false
          shell.Size = self._curSize
          shell.BackgroundTransparency = T.WinTrans
        end
      end)
    end
  end

  function Window:ToggleMini()
    self._mini = not self._mini
    sidePanel.Visible = not self._mini
    content.Visible  = not self._mini
    local target = self._mini
      and UDim2.fromOffset(self._fullSize.X.Offset, BarH + 1)
      or  (self._curSize or self._fullSize)
    if not self._mini then self._curSize = self._fullSize end
    tw(shell, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = target })
  end

  function Window:ToggleSize()
    local big  = UDim2.fromOffset(720, 520)
    local isBig = self._curSize and self._curSize.X.Offset >= 700
    self._curSize = isBig and self._fullSize or big
    tw(shell, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = self._curSize })
  end

  function Window:Destroy()
    tw(shell, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
      Size = UDim2.fromOffset(self._curSize.X.Offset * 0.88, self._curSize.Y.Offset * 0.88),
      BackgroundTransparency = 1,
    })
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    task.delay(0.32, function() pcall(function() gui:Destroy() end) end)
  end

  table.insert(Window._conns, UserInputService.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.KeyCode == toggleKey
    and inp.UserInputType == Enum.UserInputType.Keyboard then
      Window:Toggle()
    end
  end))

  return Window
end

-- ── Notifications ─────────────────────────────────────────────
local _notifGui, _notifStack

local function ensureNotifs()
  if _notifStack and _notifStack.Parent then return _notifStack end
  local parent = guiParent()
  if parent:FindFirstChild("SpeedyUINotifs") then parent.SpeedyUINotifs:Destroy() end
  _notifGui = New("ScreenGui", {
    Name = "SpeedyUINotifs", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
  }, parent)
  _notifStack = New("Frame", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -16),
    Size = UDim2.new(0, 280, 1, -32),
    BackgroundTransparency = 1,
  }, _notifGui)
  New("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 8),
  }, _notifStack)
  return _notifStack
end

function SpeedyUI:Notify(o)
  o = o or {}
  local stack = ensureNotifs()

  -- Plain Frame — no CanvasGroup so text is never dimmed by GroupTransparency
  local n = New("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Color3.fromRGB(18, 18, 22),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(40, 0),
  }, stack)
  corner(n, 12)
  addStroke(n, T.Stroke, T.StrokeTrans, 1)

  New("UIPadding", {
    PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11),
    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
  }, n)
  New("UIListLayout", { Padding = UDim.new(0, 4) }, n)

  -- Red accent line
  local accent = New("Frame", {
    Size = UDim2.new(0, 24, 0, 3),
    BackgroundColor3 = T.Red, BorderSizePixel = 0,
  }, n)
  corner(accent, 999)

  local tl = Lbl(n, o.Title or "Speedy", 13, Enum.Font.GothamBold, T.Text)
  tl.Size = UDim2.new(1, 0, 0, 16)

  if o.Content and o.Content ~= "" then
    local cl = Lbl(n, o.Content, 12, Enum.Font.Gotham, T.TextSub)
    cl.Size = UDim2.new(1, 0, 0, 0)
    cl.AutomaticSize = Enum.AutomaticSize.Y
    cl.TextWrapped = true
    cl.LineHeight = 1.3
  end

  -- Slide in from right
  tw(n, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
    { Position = UDim2.fromOffset(0, 0) })

  local dur = math.clamp(o.Duration or 3.5, 1, 12)
  task.delay(dur, function()
    if not n.Parent then return end
    tw(n, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In,
      { Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1 })
    task.delay(0.3, function() pcall(function() n:Destroy() end) end)
  end)
  return n
end

return SpeedyUI
