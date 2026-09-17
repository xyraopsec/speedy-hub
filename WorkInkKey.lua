--[[ SPEEDY HUB | Work.ink key gate (shared module, minimalist)
   Usage (single user-facing loadstring per game script):
     local GetKey = loadstring(game:HttpGet(
       "https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/WorkInkKey.lua"
     ))()
     local token = GetKey() -- blocks until valid, returns token string
     if not token then return end

   Icons: Lucide via rbxassetid (Snxdfer map) — key 10723416652,
   shield-check 10734951367, copy 10709812159, check 10709790644,
   arrow-right 10709768347.
   Validation uses ONLY the public endpoint. Never put a Work.ink API key in Lua. ]]

local KEY_LINK = "https://work.ink/2YOe/key"
local KEY_FILE = "speedy_workink_key.txt"

local ICON_KEY = "rbxassetid://10723416652"
local ICON_SHIELD = "rbxassetid://10734951367"
local ICON_COPY = "rbxassetid://10709812159"
local ICON_CHECK = "rbxassetid://10709790644"
local ICON_ARROW = "rbxassetid://10709768347"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local RED = Color3.fromRGB(255, 46, 46)
local INK = Color3.fromRGB(18, 20, 22)
local PANEL = Color3.fromRGB(28, 30, 36)

local function httpGet(url)
  local req = (syn and syn.request) or (http and http.request) or request
  if req then
    local ok, res = pcall(req, { Url = url, Method = "GET" })
    if ok and res and res.Body then return res.Body end
    return nil
  end
  local ok, body = pcall(function() return game:HttpGet(url) end)
  if ok then return body end
  return nil
end

local function validate(token)
  if not token or #token < 8 then return false end
  local body = httpGet("https://work.ink/_api/v2/token/isValid/" .. token)
  if not body then return false end
  local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
  if ok and data and data.valid == true then return true end
  return false
end

local function loadSaved()
  local key = nil
  pcall(function()
    if readfile and isfile and isfile(KEY_FILE) then
      key = readfile(KEY_FILE)
      if key then key = string.gsub(key, "%s+", "") end
    end
  end)
  return (key and #key > 0) and key or nil
end

local function saveKey(key)
  pcall(function()
    if writefile then writefile(KEY_FILE, tostring(key)) end
  end)
end

return function()
  local saved = loadSaved()
  if saved and validate(saved) then return saved end

  local done, result = false, nil
  local gui = Instance.new("ScreenGui")
  gui.Name = "SpeedyKeyGate"
  gui.ResetOnSpawn = false
  gui.IgnoreGuiInset = true
  gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  gui.Parent = PlayerGui

  local dim = Instance.new("Frame", gui)
  dim.Size = UDim2.fromScale(1, 1)
  dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
  dim.BackgroundTransparency = 0.45
  dim.BorderSizePixel = 0

  local card = Instance.new("Frame", gui)
  card.AnchorPoint = Vector2.new(0.5, 0.5)
  card.Position = UDim2.fromScale(0.5, 0.5)
  card.Size = UDim2.fromOffset(340, 252)
  card.BackgroundColor3 = INK
  card.BorderSizePixel = 0
  Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
  local stroke = Instance.new("UIStroke", card)
  stroke.Color = Color3.fromRGB(255, 255, 255)
  stroke.Transparency = 0.9

  local iconBox = Instance.new("Frame", card)
  iconBox.Size = UDim2.fromOffset(40, 40)
  iconBox.Position = UDim2.fromOffset(24, 22)
  iconBox.BackgroundColor3 = RED
  iconBox.BackgroundTransparency = 0.9
  iconBox.BorderSizePixel = 0
  Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 12)
  local iconStroke = Instance.new("UIStroke", iconBox)
  iconStroke.Color = RED
  iconStroke.Transparency = 0.55
  local icon = Instance.new("ImageLabel", iconBox)
  icon.Size = UDim2.fromOffset(20, 20)
  icon.Position = UDim2.fromOffset(10, 10)
  icon.BackgroundTransparency = 1
  icon.Image = ICON_KEY
  icon.ImageColor3 = RED

  local title = Instance.new("TextLabel", card)
  title.Size = UDim2.new(1, -84, 0, 22)
  title.Position = UDim2.fromOffset(72, 24)
  title.BackgroundTransparency = 1
  title.Text = "Speedy Hub"
  title.Font = Enum.Font.GothamBold
  title.TextSize = 17
  title.TextColor3 = Color3.new(1, 1, 1)
  title.TextXAlignment = Enum.TextXAlignment.Left

  local sub = Instance.new("TextLabel", card)
  sub.Size = UDim2.new(1, -84, 0, 14)
  sub.Position = UDim2.fromOffset(72, 46)
  sub.BackgroundTransparency = 1
  sub.Text = "Enter your key to continue"
  sub.Font = Enum.Font.Gotham
  sub.TextSize = 12
  sub.TextColor3 = Color3.fromRGB(150, 150, 165)
  sub.TextXAlignment = Enum.TextXAlignment.Left

  local field = Instance.new("Frame", card)
  field.Size = UDim2.new(1, -48, 0, 46)
  field.Position = UDim2.fromOffset(24, 84)
  field.BackgroundColor3 = PANEL
  field.BorderSizePixel = 0
  Instance.new("UICorner", field).CornerRadius = UDim.new(0, 10)
  local fieldStroke = Instance.new("UIStroke", field)
  fieldStroke.Color = Color3.fromRGB(255, 255, 255)
  fieldStroke.Transparency = 0.9

  local box = Instance.new("TextBox", field)
  box.Size = UDim2.new(1, -44, 1, 0)
  box.Position = UDim2.fromOffset(14, 0)
  box.BackgroundTransparency = 1
  box.Font = Enum.Font.Code
  box.PlaceholderText = "Paste key…"
  box.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
  box.Text = ""
  box.TextColor3 = Color3.new(1, 1, 1)
  box.TextSize = 13
  box.ClearTextOnFocus = false
  box.TextXAlignment = Enum.TextXAlignment.Left
  box.Focused:Connect(function()
    TweenService:Create(fieldStroke, TweenInfo.new(0.18), { Color = RED, Transparency = 0.35 }):Play()
  end)
  box.FocusLost:Connect(function()
    TweenService:Create(fieldStroke, TweenInfo.new(0.18), { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9 }):Play()
  end)

  local status = Instance.new("TextLabel", card)
  status.Size = UDim2.new(1, -48, 0, 14)
  status.Position = UDim2.fromOffset(24, 134)
  status.BackgroundTransparency = 1
  status.Text = ""
  status.Font = Enum.Font.Gotham
  status.TextSize = 11
  status.TextColor3 = Color3.fromRGB(229, 72, 77)
  status.TextXAlignment = Enum.TextXAlignment.Left

  local go = Instance.new("TextButton", card)
  go.Size = UDim2.new(1, -48, 0, 42)
  go.Position = UDim2.fromOffset(24, 154)
  go.BackgroundColor3 = RED
  go.BorderSizePixel = 0
  go.Font = Enum.Font.GothamSemibold
  go.Text = "Continue  →"
  go.TextColor3 = Color3.new(1, 1, 1)
  go.TextSize = 14
  go.AutoButtonColor = false
  Instance.new("UICorner", go).CornerRadius = UDim.new(0, 10)
  go.MouseEnter:Connect(function() TweenService:Create(go, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play() end)
  go.MouseLeave:Connect(function() TweenService:Create(go, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play() end)

  local get = Instance.new("TextButton", card)
  get.Size = UDim2.new(1, -48, 0, 18)
  get.Position = UDim2.fromOffset(24, 204)
  get.BackgroundTransparency = 1
  get.Font = Enum.Font.Gotham
  get.Text = "No key? Get one free"
  get.TextColor3 = Color3.fromRGB(140, 140, 155)
  get.TextSize = 12
  get.AutoButtonColor = false
  get.MouseEnter:Connect(function() get.TextColor3 = Color3.new(1, 1, 1) end)
  get.MouseLeave:Connect(function() get.TextColor3 = Color3.fromRGB(140, 140, 155) end)

  get.MouseButton1Click:Connect(function()
    pcall(function() if setclipboard then setclipboard(KEY_LINK) end end)
    get.Text = "Link copied — complete it in your browser"
    task.delay(2, function() if get.Parent then get.Text = "No key? Get one free" end end)
  end)

  local function fail(msg)
    status.TextColor3 = Color3.fromRGB(229, 72, 77)
    status.Text = msg
    go.Text = "Continue  →"
  end

  go.MouseButton1Click:Connect(function()
    local t = string.gsub(box.Text or "", "%s+", "")
    if #t == 0 then fail("Paste your key first.") return end
    go.Text = "Checking…"
    if validate(t) then
      saveKey(t)
      status.TextColor3 = Color3.fromRGB(87, 242, 135)
      status.Text = "Welcome back."
      go.Text = "Continue  →"
      result = t
      task.wait(0.35)
      gui:Destroy()
      done = true
    else
      fail("That key didn't work. Get a fresh one below.")
    end
  end)
  box.FocusLost:Connect(function(enter) if enter then go:Activate() end end)

  card.Size = UDim2.fromOffset(320, 238)
  TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(340, 252) }):Play()

  repeat task.wait() until done
  return result
end
