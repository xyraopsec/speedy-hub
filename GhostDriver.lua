--[[ SPEEDY HUB | Ghost Driver (PRODUCTION)
   GameId 10173311467 | Tilted Vehicles
   Verified live via executor (PRE-ALPHA Ghost Driver, PlaceId 137228775846):
   - Remotes.RequestGarageData (RemoteFunction) :InvokeServer() -> {["Stratton 585 TS"]={SerialNumber=...}, ...} (15 cars)
   - Remotes.SpawnCarEvent (RemoteEvent) :FireServer("Car Name") -> spawns "<User>_<Car>" with DriveSeat (verified Stratton 585 TS)
   - Car model: A-Chassis Tune ModuleScript (Horsepower=1200, Redline=8500, FinalDrive=3.2) + A-Chassis Interface/Values (Horsepower/RPM/Gear/Throttle live)
   - Server speed ceiling: ReplicatedStorage.CarSpeedLimits (DEFAULT_MPH=228, HEADROOM=1.6, upgradeScale=sqrt(clamp(BaseHP/StockHP,1,2))) — do NOT velocity-hack, kick risk
   - Stock car attrs: only 14 (OwnerName/SpawnComplete/BaseRedline 8500/etc), NO nitrous attrs — nitrous needs Bottle mod, skipped v1
   - Humanoid.WalkSpeed set works (tested 50), car:PivotTo works (moved +9Y), spawns at (-933,-646,-51) / lobby (-3611,136,-25)
   Home layout kept EXACTLY from GameTemplate. ]]

local Env = getgenv()

if type(Env.Library) == "table" then
  if type(Env.Library.Unload) == "function" then
    pcall(function() Env.Library:Unload() end)
  end
  Env.Library = nil
end

local Source = game:HttpGet(
  "https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Stellar/Library.lua"
)
local Loader, LoadError = loadstring(Source)
if not Loader then error("Failed to load Stellar Library: " .. tostring(LoadError)) end

local Library = Loader()
if type(Library) ~= "table" then error("Stellar Library did not return a valid table") end
Env.Library = Library

-- ── Live context ─────────────────────────────────────────────
local gameName, placeId = "Ghost Driver", game.PlaceId
pcall(function()
  gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)
local execName = "Unknown executor"
pcall(function()
  local id = identifyexecutor()
  if type(id) == "table" then execName = tostring(id[1] or "Unknown executor")
  elseif type(id) == "string" and id ~= "" then execName = id end
end)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local username = LocalPlayer and LocalPlayer.DisplayName or "User"

-- ── Brand assets ─────────────────────────────────────────────
local SPEEDY_LOGO_ID = 0
local EXECUTOR_FILES = {
  potassium = "potassium.png",
  real = "real.png",
  ronix = "ronix.png",
  seliware = "seliware.png",
  solara = "solara.png",
  synapsez = "synapsez.png",
  volt = "volt.png",
  wave = "wave.png",
}
local CONTRIBUTOR_AVATARS = {
  xyra = "xyrapfp.png",
  luahook = "luahook.png",
  raikou = "raikou.png",
  kameltz = "chinese.png",
}

local function githubImage(url, file)
  local asset = nil
  pcall(function()
    local req = (syn and syn.request) or (http and http.request) or request
    if req and writefile and getcustomasset then
      local res = req({ Url = url, Method = "GET" })
      if res and res.Body and #res.Body > 100 then
        writefile(file, res.Body)
        asset = getcustomasset(file)
      end
    end
  end)
  return asset
end

local Logo = SPEEDY_LOGO_ID ~= 0 and ("rbxassetid://" .. SPEEDY_LOGO_ID)
  or githubImage("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/icon.png", "speedy-logo.png")
local DiscordLogo = githubImage("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/discord-logo.png", "speedy-discord.png")

local function execLogoFor(name)
  if type(name) ~= "string" then return nil end
  local f = EXECUTOR_FILES[string.lower(name)]
  if not f then return nil end
  return githubImage("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/" .. f, "speedy-exec-" .. f)
end
local execLogo = execLogoFor(execName)
local gameThumb = "rbxthumb://type=GameThumbnail&id=" .. tostring(placeId) .. "&w=768&h=432"

-- ── Accent ───────────────────────────────────────────────────
Library:ChangeTheme("Accent", Color3.fromRGB(255, 46, 46))

-- ── Window ───────────────────────────────────────────────────
local Window = Library:Window({ Name = "Speedy Hub", SubName = gameName, Logo = Logo, ExpiresSeconds = 24 * 60 * 60 })
local Watermark = Library:Watermark("Speedy Hub | " .. username, Logo)

-- ── Home: locked layout from GameTemplate ────────────────────
local tabIcons = {}
local Home = Window:Page({ Name = "Home", Icon = "house" })
tabIcons[Home] = "house"

local column = Home.Items["Column"].Instance
local INK = Color3.fromRGB(18, 20, 22)
local flowOrder = 0

local function mk(class, props, parent)
  local o = Instance.new(class)
  for k, v in pairs(props) do pcall(function() o[k] = v end) end
  o.Parent = parent
  return o
end

local function flowList(parent, pad)
  return mk("UIListLayout", { Padding = UDim.new(0, pad or 8), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
end

local function flowPad(parent, px)
  mk("UIPadding", {
    PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, px or 10), PaddingRight = UDim.new(0, px or 10),
  }, parent)
end

local function card(parent, order, h)
  local f = mk("Frame", {
    Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = INK,
    BorderSizePixel = 0, LayoutOrder = order,
  }, parent)
  mk("UICorner", { CornerRadius = UDim.new(0, 6) }, f)
  flowList(f, 6)
  flowPad(f, 10)
  return f
end

local function cardHeader(parent, order, icon, title)
  local h = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
    BorderSizePixel = 0, LayoutOrder = order,
  }, parent)
  if type(icon) == "string" and icon ~= "" then
    local ic = mk("ImageLabel", {
      Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1,
      AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
      Image = icon, BorderSizePixel = 0,
    }, h)
    mk("UICorner", { CornerRadius = UDim.new(0, 4) }, ic)
  end
  mk("TextLabel", {
    Size = UDim2.new(1, -26, 1, 0), Position = UDim2.fromOffset(26, 0),
    BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold,
    TextSize = 15, TextColor3 = Color3.new(1, 1, 1),
    TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
  }, h)
  return h
end

local function cardBanner(parent, order, image, height)
  if type(image) ~= "string" or image == "" then return nil end
  local img = mk("ImageLabel", {
    Size = UDim2.new(1, 0, 0, height or 120),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.6,
    BorderSizePixel = 0, Image = image, ScaleType = Enum.ScaleType.Crop,
    LayoutOrder = order,
  }, parent)
  mk("UICorner", { CornerRadius = UDim.new(0, 8) }, img)
  return img
end

local function cardLabel(parent, order, text, dim)
  return mk("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
    Text = text, Font = dim and Enum.Font.Gotham or Enum.Font.GothamSemibold,
    TextSize = dim and 13 or 14,
    TextColor3 = dim and Color3.fromRGB(165, 165, 175) or Color3.new(1, 1, 1),
    TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
    LayoutOrder = order,
  }, parent)
end

local function cardButton(parent, order, text, cb)
  local b = mk("TextButton", {
    Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(30, 32, 38),
    BorderSizePixel = 0, Text = text, Font = Enum.Font.GothamSemibold,
    TextSize = 13, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
    LayoutOrder = order,
  }, parent)
  mk("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
  b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(40, 42, 50) end)
  b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(30, 32, 38) end)
  b.MouseButton1Click:Connect(function() pcall(cb) end)
  return b
end

flowOrder = flowOrder + 1
local topRow = mk("Frame", {
  Size = UDim2.new(1, 0, 0, 240), BackgroundTransparency = 1,
  BorderSizePixel = 0, LayoutOrder = flowOrder,
}, column)
local gameBox = mk("Frame", {
  Size = UDim2.new(0.5, -5, 1, 0), BackgroundColor3 = INK,
  BorderSizePixel = 0,
}, topRow)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, gameBox)
flowList(gameBox, 8)
flowPad(gameBox, 12)
cardHeader(gameBox, 1, gameThumb, gameName)
cardBanner(gameBox, 2, gameThumb, 100)
cardLabel(gameBox, 3, "Place ID: " .. tostring(placeId), false)
cardButton(gameBox, 4, "Copy place ID", function()
  if setclipboard then setclipboard(tostring(placeId)) end
end)

local execBox = mk("Frame", {
  Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0),
  BackgroundColor3 = INK, BorderSizePixel = 0,
}, topRow)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, execBox)
flowList(execBox, 8)
flowPad(execBox, 12)
cardHeader(execBox, 1, execLogo, execName)
if execLogo then cardBanner(execBox, 2, execLogo, 120) end
cardLabel(execBox, 3, "Running this session", false)

flowOrder = flowOrder + 1
local discordRow = mk("Frame", {
  Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = INK,
  BorderSizePixel = 0, LayoutOrder = flowOrder,
}, column)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, discordRow)
if DiscordLogo then
  local dl = mk("ImageLabel", {
    Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0),
    Image = DiscordLogo, BorderSizePixel = 0,
  }, discordRow)
  mk("UICorner", { CornerRadius = UDim.new(0, 8) }, dl)
end
mk("TextLabel", {
  Size = UDim2.new(1, -230, 0, 18), Position = UDim2.fromOffset(62, 12),
  BackgroundTransparency = 1, Text = "OFFICIAL DISCORD COMMUNITY",
  Font = Enum.Font.GothamSemibold, TextSize = 13,
  TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left,
  BorderSizePixel = 0,
}, discordRow)
mk("TextLabel", {
  Size = UDim2.new(1, -230, 0, 16), Position = UDim2.fromOffset(62, 32),
  BackgroundTransparency = 1, Text = "Connect, chat, and get support.",
  Font = Enum.Font.Gotham, TextSize = 12,
  TextColor3 = Color3.fromRGB(165, 165, 175),
  TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
}, discordRow)
local dj = mk("TextButton", {
  Size = UDim2.new(0, 150, 0, 32),
  AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
  BackgroundColor3 = Color3.fromRGB(30, 32, 38), BorderSizePixel = 0,
  Text = "JOIN DISCORD", Font = Enum.Font.GothamSemibold, TextSize = 13,
  TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
}, discordRow)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, dj)
dj.MouseEnter:Connect(function() dj.BackgroundColor3 = Color3.fromRGB(40, 42, 50) end)
dj.MouseLeave:Connect(function() dj.BackgroundColor3 = Color3.fromRGB(30, 32, 38) end)
dj.MouseButton1Click:Connect(function()
  pcall(function() if setclipboard then setclipboard("discord.gg/q5En862zuM") end end)
end)

flowOrder = flowOrder + 1
local creditsBox = card(column, flowOrder, 155)
column.ScrollingEnabled = false
column.ScrollBarThickness = 0
column.AutomaticCanvasSize = Enum.AutomaticSize.None
column.CanvasSize = UDim2.new(0, 0, 0, 0)
cardHeader(creditsBox, 1, execLogo, "Credits")
local creditRows = {
  { "Script Developed by:", "@xyra (xyraopsec)", "xyra" },
  { "UI/UX Design by:", "yes! (luahook)", "luahook" },
  { "Beta Testing:", "カメルツ (time_distute) [PL, EN]", "kameltz" },
  { "Hosting and Infrastructure:", "Raikou (raikou_0)", "raikou" },
}
for i, row in ipairs(creditRows) do
  local r = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 19), BackgroundTransparency = 1,
    BorderSizePixel = 0, LayoutOrder = 10 + i,
  }, creditsBox)
  mk("TextLabel", {
    Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1,
    Text = row[1], Font = Enum.Font.Gotham, TextSize = 13,
    TextColor3 = Color3.fromRGB(210, 210, 220),
    TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
  }, r)
  local avatarKey = row[3]
  local avatarFile = avatarKey and CONTRIBUTOR_AVATARS[avatarKey]
  local avatarAsset = avatarFile and githubImage("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/" .. avatarFile, "speedy-avatar-" .. avatarFile)
  if avatarAsset then
    local img = mk("ImageLabel", {
      Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
      Image = avatarAsset, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, r)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, img)
    mk("TextLabel", {
      Size = UDim2.new(1, -22, 1, 0), BackgroundTransparency = 1,
      Text = row[2], Font = Enum.Font.GothamSemibold, TextSize = 13,
      TextColor3 = Color3.new(1, 1, 1),
      TextXAlignment = Enum.TextXAlignment.Right, BorderSizePixel = 0,
    }, r)
  else
    mk("TextLabel", {
      Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
      Text = row[2], Font = Enum.Font.GothamSemibold, TextSize = 13,
      TextColor3 = Color3.new(1, 1, 1),
      TextXAlignment = Enum.TextXAlignment.Right, BorderSizePixel = 0,
    }, r)
  end
end

-- ── Ghost Driver: verified remotes only ──────────────────────
local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local SpawnCarEvent = Remotes:WaitForChild("SpawnCarEvent")
local RequestGarageData = Remotes:WaitForChild("RequestGarageData")

local function myCar()
  for _, m in ipairs(workspace:GetChildren()) do
    if m:IsA("Model") and string.find(m.Name, LocalPlayer.Name, 1, true) and m:FindFirstChild("DriveSeat", true) then
      return m
    end
  end
  return nil
end

local function garageNames()
  local ok, res = pcall(function() return RequestGarageData:InvokeServer() end)
  if not ok or type(res) ~= "table" then return { "Stratton 585 TS" } end
  local names = {}
  for k in pairs(res) do table.insert(names, tostring(k)) end
  table.sort(names)
  return #names > 0 and names or { "Stratton 585 TS" }
end

-- Garage ── SpawnCarEvent:FireServer("<Car Name>") verified live
local Garage = Window:Page({ Name = "Garage", Icon = "car" })
tabIcons[Garage] = "car"
local SpawnSec = Garage:Section({ Name = "Spawn", Side = 1 })
local carList = garageNames()
SpawnSec:Dropdown({ Name = "My cars", Flag = "GCar", Items = carList, Default = carList[1], Multi = false, Callback = function() end })
SpawnSec:Button({ Name = "Spawn selected car", Callback = function()
  local sel = Library.Flags and Library.Flags.GCar
  if type(sel) == "table" then sel = sel.Value end
  if type(sel) ~= "string" or sel == "" then sel = carList[1] end
  pcall(function() SpawnCarEvent:FireServer(sel) end)
end })
SpawnSec:Button({ Name = "Refresh garage list", Callback = function()
  local names = garageNames()
  local dd = SpawnSec:Dropdown({ Name = "My cars", Flag = "GCar", Items = names, Default = names[1], Multi = false, Callback = function() end })
  if dd then print("[Speedy] Garage refreshed:", #names) end
end })

-- Character ── Humanoid.WalkSpeed set verified live (50 ok)
local Char = Window:Page({ Name = "Character", Icon = "users" })
tabIcons[Char] = "users"
local Move = Char:Section({ Name = "Movement", Side = 1 })
Move:Slider({ Name = "WalkSpeed", Flag = "Walk", Default = 32, Min = 16, Max = 150, Suffix = "", Callback = function(v)
  pcall(function()
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = v end
  end)
end })
Move:Slider({ Name = "JumpPower", Flag = "Jump", Default = 50, Min = 50, Max = 300, Suffix = "", Callback = function(v)
  pcall(function()
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = v h.UseJumpPower = true end
  end)
end })
local FlySec = Char:Section({ Name = "Fly", Side = 2 })
local flying = false
FlySec:Toggle({ Name = "Fly (E to rise, Q to sink)", Flag = "Fly", Callback = function(v)
  flying = v
  pcall(function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if v then
      local bv = Instance.new("BodyVelocity")
      bv.Name = "SpeedyFly"
      bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
      bv.Velocity = Vector3.new(0, 0, 0)
      bv.Parent = hrp
      local bg = Instance.new("BodyGyro")
      bg.Name = "SpeedyGyro"
      bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
      bg.Parent = hrp
      task.spawn(function()
        local UIS = game:GetService("UserInputService")
        while flying and hrp.Parent do
          local cam = workspace.CurrentCamera
          local dir = Vector3.new(0, 0, 0)
          if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
          if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
          if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
          if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
          if UIS:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
          if UIS:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end
          if dir.Magnitude > 0 then dir = dir.Unit * 80 end
          local b = hrp:FindFirstChild("SpeedyFly")
          if b then b.Velocity = dir end
          local g = hrp:FindFirstChild("SpeedyGyro")
          if g then g.CFrame = cam.CFrame end
          task.wait()
        end
      end)
    else
      local b = hrp:FindFirstChild("SpeedyFly")
      if b then b:Destroy() end
      local g = hrp:FindFirstChild("SpeedyGyro")
      if g then g:Destroy() end
    end
  end)
end })

-- Teleport ── car:PivotTo verified live (moved +9Y), spawns verified
local MPH_TABLE = {
  ["Bullseye Helly"] = 204, ["Castellani Specchiera"] = 215, ["Eisenhardt G43"] = 186,
  ["Granadino Relámpago Fox Spec"] = 228, ["Kitsuni LX"] = 165, ["Rangy Helly"] = 180,
  ["Reinhardt RT32"] = 210, ["Shelly LZ1"] = 212, ["Sorg Varkis"] = 90,
  ["Takama F10 GT"] = 215, ["Trailhawk Helly"] = 180, ["Vector W8 Twin Turbo"] = 218,
  ["Voss RT10 TT"] = 215, ["Weinchen V120"] = 175, ["Weinchen V20"] = 177,
  ["Weinchen V80"] = 180, ["Wulfbrecht RZ7"] = 168,
}
local function carBaseName(full)
  for name in pairs(MPH_TABLE) do
    if full:sub(-#name) == name then return name end
  end
  return full:match("^[^_]+_(.+)$") or full
end
local function speedCeiling(car)
  local base = carBaseName(car.Name)
  local mph = MPH_TABLE[base] or 228
  local scale = 1
  local bHP, sHP = car:GetAttribute("BaseHorsepower"), car:GetAttribute("StockHorsepower")
  if bHP and sHP and tonumber(sHP) and tonumber(sHP) > 0 then
    scale = math.sqrt(math.clamp(tonumber(bHP) / tonumber(sHP), 1, 2))
  end
  return math.floor(mph * 1.6 * scale + 0.5), base
end
local function notify(title, text, dur)
  pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text, Duration = dur or 4 })
  end)
end
local function goTo(cf)
  pcall(function()
    local car = myCar()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if car and hum and hum.Seated then car:PivotTo(cf + Vector3.new(0, 3, 0))
    else
      local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
      if hrp then hrp.CFrame = cf end
    end
  end)
end
local TP = Window:Page({ Name = "Drive", Icon = "map-pin" })
tabIcons[TP] = "map-pin"
local TpP = TP:Section({ Name = "Teleport", Side = 1 })
TpP:Button({ Name = "Dealership", Callback = function() goTo(CFrame.new(-3611, 148, -25)) end })
TpP:Button({ Name = "Highway race", Callback = function() goTo(CFrame.new(-3595, 151, -175)) end })
TpP:Button({ Name = "Spawn", Callback = function() goTo(CFrame.new(-933, -640, -51)) end })
TpP:Button({ Name = "Teleport to my car", Callback = function()
  pcall(function()
    local car = myCar()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if car and hrp then hrp.CFrame = car:GetPivot() + Vector3.new(0, 5, 0)
    elseif not car then notify("Speedy", "No car spawned — use Garage first") end
  end)
end })
local Here = TP:Section({ Name = "Car", Side = 2 })
Here:Button({ Name = "Bring my car to me", Callback = function()
  pcall(function()
    local car = myCar()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if car and hrp then car:PivotTo(hrp.CFrame + Vector3.new(0, 3, 6))
    elseif not car then notify("Speedy", "No car spawned — use Garage first") end
  end)
end })
Here:Button({ Name = "Police lights", Callback = function()
  pcall(function()
    local r = game.ReplicatedStorage.Packages.Remotes.Networking:FindFirstChild("RE/Car/PoliceLightsToggle", true)
      or game.ReplicatedStorage.Remotes:FindFirstChild("PoliceLightsToggle")
    if r then r:FireServer() else notify("Speedy", "No police mods on this car") end
  end)
end })
Here:Button({ Name = "My speed + safe max", Callback = function()
  pcall(function()
    local car = myCar()
    if not car then notify("Speedy", "Not in a car") return end
    local iface = car:FindFirstChild("A-Chassis Interface", true)
    local vel = iface and iface:FindFirstChild("Values") and iface.Values:FindFirstChild("Velocity")
    local studs = vel and vel.Value.Magnitude or 0
    local mph = math.floor(studs * 0.35 + 0.5)
    local max, base = speedCeiling(car)
    notify("Speedy", string.format("%s: %d MPH now / %d max safe", base, mph, max), 5)
  end)
end })

-- Re-resolve tab icons once the Lucide pack has arrived
task.delay(5, function()
  pcall(function()
    for page, name in pairs(tabIcons) do
      local items = page.Items
      local w = items and items.Icon
      local img = w and w.Instance
      local resolved = Library:ResolveIcon(name)
      if img and type(resolved) == "string" and resolved:match("^rbxasset") then
        img.Image = resolved
      end
    end
  end)
end)

Library:CreateSettingsPage(Window, Watermark)
print("[Speedy x Ghost Driver] loaded — verified remotes only, no speed hack (server ceiling)")
