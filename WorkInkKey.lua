--[[ SPEEDY HUB | Work.ink key gate (shared module)
   Usage (single user-facing loadstring per game script):
     local GetKey = loadstring(game:HttpGet(
       "https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/WorkInkKey.lua"
     ))()
     local token = GetKey() -- blocks until valid, returns token string
     if not token then return end
     -- ... rest of game script ...

   Flow: saved token file -> public validate -> native dialog (Get Key copies link, paste, Verify) -> save -> return.
   Validation uses ONLY the public endpoint. Never put a Work.ink API key in Lua. ]]

local KEY_LINK = "https://work.ink/2YOe/key"
local KEY_FILE = "speedy_workink_key.txt"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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
  -- 1) Saved token fast path
  local saved = loadSaved()
  if saved and validate(saved) then return saved end

  -- 2) Dialog (native, no dependencies)
  local done, result = false, nil
  local gui = Instance.new("ScreenGui")
  gui.Name = "SpeedyKeyGate"
  gui.ResetOnSpawn = false
  gui.IgnoreGuiInset = true
  gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  gui.Parent = PlayerGui

  local dim = Instance.new("Frame", gui)
  dim.Size = UDim2.fromScale(1, 1)
  dim.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
  dim.BackgroundTransparency = 0.35
  dim.BorderSizePixel = 0

  local card = Instance.new("Frame", gui)
  card.AnchorPoint = Vector2.new(0.5, 0.5)
  card.Position = UDim2.fromScale(0.5, 0.5)
  card.Size = UDim2.fromOffset(420, 300)
  card.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
  card.BorderSizePixel = 0
  Instance.new("UICorner", card).CornerRadius = UDim.new(0, 20)
  local stroke = Instance.new("UIStroke", card)
  stroke.Color = Color3.fromRGB(255, 255, 255)
  stroke.Transparency = 0.88

  local accent = Instance.new("Frame", card)
  accent.Size = UDim2.new(1, -48, 0, 2)
  accent.Position = UDim2.fromOffset(24, 0)
  accent.BackgroundColor3 = Color3.fromRGB(255, 26, 26)
  accent.BorderSizePixel = 0
  Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

  local title = Instance.new("TextLabel", card)
  title.Size = UDim2.new(1, -48, 0, 26)
  title.Position = UDim2.fromOffset(24, 18)
  title.BackgroundTransparency = 1
  title.Text = "Speedy Vault"
  title.Font = Enum.Font.GothamBlack
  title.TextSize = 20
  title.TextColor3 = Color3.new(1, 1, 1)
  title.TextXAlignment = Enum.TextXAlignment.Left

  local sub = Instance.new("TextLabel", card)
  sub.Size = UDim2.new(1, -48, 0, 32)
  sub.Position = UDim2.fromOffset(24, 44)
  sub.BackgroundTransparency = 1
  sub.Text = "Tap Get Key, complete the steps, paste your token below."
  sub.Font = Enum.Font.Gotham
  sub.TextSize = 12
  sub.TextColor3 = Color3.fromRGB(150, 150, 165)
  sub.TextXAlignment = Enum.TextXAlignment.Left
  sub.TextWrapped = true

  local field = Instance.new("Frame", card)
  field.Size = UDim2.new(1, -48, 0, 50)
  field.Position = UDim2.fromOffset(24, 88)
  field.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
  field.BorderSizePixel = 0
  Instance.new("UICorner", field).CornerRadius = UDim.new(0, 12)
  local fieldStroke = Instance.new("UIStroke", field)
  fieldStroke.Color = Color3.fromRGB(255, 255, 255)
  fieldStroke.Transparency = 0.9

  local box = Instance.new("TextBox", field)
  box.Size = UDim2.new(1, -24, 1, 0)
  box.Position = UDim2.fromOffset(12, 0)
  box.BackgroundTransparency = 1
  box.Font = Enum.Font.Code
  box.PlaceholderText = "Paste key token here"
  box.PlaceholderColor3 = Color3.fromRGB(70, 70, 82)
  box.Text = ""
  box.TextColor3 = Color3.new(1, 1, 1)
  box.TextSize = 13
  box.ClearTextOnFocus = false
  box.TextXAlignment = Enum.TextXAlignment.Left
  box.Focused:Connect(function()
    TweenService:Create(fieldStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 26, 26), Transparency = 0.4 }):Play()
  end)
  box.FocusLost:Connect(function()
    TweenService:Create(fieldStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9 }):Play()
  end)

  local status = Instance.new("TextLabel", card)
  status.Size = UDim2.new(1, -48, 0, 16)
  status.Position = UDim2.fromOffset(24, 144)
  status.BackgroundTransparency = 1
  status.Text = ""
  status.Font = Enum.Font.GothamMedium
  status.TextSize = 11
  status.TextColor3 = Color3.fromRGB(229, 72, 77)
  status.TextXAlignment = Enum.TextXAlignment.Left

  local function btn(text, bg, x, w)
    local b = Instance.new("TextButton", card)
    b.Size = UDim2.fromOffset(w, 44)
    b.Position = UDim2.fromOffset(x, 168)
    b.BackgroundColor3 = bg
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 13
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0.12 }):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play() end)
    return b
  end

  local getBtn = btn("Get Key", Color3.fromRGB(30, 30, 38), 24, 180)
  local goBtn = btn("Verify", Color3.fromRGB(255, 26, 26), 212, 184)

  getBtn.MouseButton1Click:Connect(function()
    pcall(function() if setclipboard then setclipboard(KEY_LINK) end end)
    local orig = getBtn.Text
    getBtn.Text = "Copied!"
    task.delay(1.6, function() if getBtn.Parent then getBtn.Text = orig end end)
  end)

  goBtn.MouseButton1Click:Connect(function()
    local t = string.gsub(box.Text or "", "%s+", "")
    if #t == 0 then
      status.Text = "Paste your token first."
      return
    end
    goBtn.Text = "Checking..."
    local ok = validate(t)
    if ok then
      saveKey(t)
      status.TextColor3 = Color3.fromRGB(87, 242, 135)
      status.Text = "Unlocked!"
      result = t
      task.wait(0.4)
      gui:Destroy()
      done = true
    else
      goBtn.Text = "Verify"
      status.TextColor3 = Color3.fromRGB(229, 72, 77)
      status.Text = "Invalid or expired key."
    end
  end)
  box.FocusLost:Connect(function(enter) if enter then goBtn:Activate() end end)

  card.Size = UDim2.fromOffset(400, 284)
  TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(420, 300) }):Play()

  repeat task.wait() until done
  return result
end
