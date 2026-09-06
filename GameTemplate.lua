--[[ SPEEDY HUB | game script template (PRODUCTION)
   HOW TO USE FOR A NEW GAME:
   1. Copy this file -> <GameName>.lua (keep this Home page EXACTLY as-is).
   2. Add your game tabs after the Home block (copy the Cars tab pattern).
   3. Push to master. The loader serves it per universe via the dashboard.
   Home layout (locked): game square + executor square, slim Discord bar,
   full-width credits. Logo/art fetched from GitHub — no uploads needed. ]]
local Env = getgenv()

-- Clean up an old Library only if it actually supports Unload
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
local gameName, placeId = "Unknown game", game.PlaceId
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

-- ── Brand assets (GitHub first, manual asset ID as override) ─
-- Executor logos: add "Name" = "rbxassetid://..." lines as you make them.
local SPEEDY_LOGO_ID = 0
-- Executor logo files in the repo (matched case-insensitively).
-- Add a new PNG + one line here whenever a new executor logo drops.
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

-- Discord server logo lives in the repo (discord-logo.png)
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
Library:ChangeTheme("Accent", Color3.fromRGB(255, 46, 46)) -- Speedy red

-- ── Window ───────────────────────────────────────────────────
local Window = Library:Window({ Name = "Speedy Hub", SubName = gameName, Logo = Logo, ExpiresSeconds = 24 * 60 * 60 })
local Watermark = Library:Watermark("Speedy Hub | " .. username, Logo)

-- ── Home: hand-built to the mockup ───────────────────────────
local tabIcons = {}
local Home = Window:Page({ Name = "Home", Icon = "house" })
tabIcons[Home] = "house"

-- ── Home: hand-built to the mockup ───────────────────────────
-- Stellar stacks sections vertically, so the two-column + full-width
-- credits layout below is built from raw instances in Stellar's style.
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
  local l = mk("UIListLayout", { Padding = UDim.new(0, pad or 8), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
  return l
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

-- Top row: game square (left) + executor square (right)
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

-- Second row: slim full-width Discord bar
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

-- Credits: full width along the bottom
flowOrder = flowOrder + 1
local creditsBox = card(column, flowOrder, 182)
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

-- ── Cars ─────────────────────────────────────────────────────
local Cars = Window:Page({ Name = "Cars", Icon = "car" })
tabIcons[Cars] = "car"
local Perf = Cars:Section({ Name = "Performance", Side = 1 })
Perf:Toggle({ Name = "Auto Drive", Flag = "AutoDrive", Callback = function(v) print("AutoDrive:", v) end })
Perf:Slider({ Name = "Max Speed", Flag = "MaxSpeed", Default = 150, Min = 50, Max = 300, Suffix = "", Callback = function(v) print("Speed:", v) end })
Perf:Dropdown({ Name = "Engine", Flag = "Engine", Items = { "Stock", "Sport", "Race" }, Default = "Stock", Multi = false, Callback = function(v) print("Engine:", v) end })
local Visuals = Cars:Section({ Name = "Visuals", Side = 2 })
Visuals:Toggle({ Name = "Car ESP", Flag = "CarESP", Callback = function(v) print("CarESP:", v) end })
Visuals:Label("ESP color"):Colorpicker({ Flag = "ESPGColor", Default = Color3.fromRGB(255, 46, 46), Callback = function(v) print("esp:", v) end })
local Tp = Cars:Section({ Name = "Teleport", Side = 1 })
Tp:Textbox({ Name = "Waypoint", Placeholder = "e.g. Dealership", Flag = "Waypoint", Callback = function(v) print("Go to:", v) end })

-- ── Moto ─────────────────────────────────────────────────────
local Moto = Window:Page({ Name = "Moto", Icon = "bike" })
tabIcons[Moto] = "bike"
local Bike = Moto:Section({ Name = "Bike setup", Side = 1 })
Bike:Toggle({ Name = "Wheelie assist", Flag = "Wheelie", Callback = function(v) print("Wheelie:", v) end })
Bike:Slider({ Name = "Grip", Flag = "Grip", Default = 70, Min = 0, Max = 100, Suffix = "", Callback = function(v) print("Grip:", v) end })
Bike:Label("Stunt key"):Keybind({ Name = "Stunt", Flag = "StuntKey", Mode = "Toggle", Default = Enum.KeyCode.G, Callback = function(v) print("Stunt:", v) end })
local Glow = Moto:Section({ Name = "Style", Side = 2 })
Glow:Label("Bike glow"):Colorpicker({ Flag = "Glow", Default = Color3.fromRGB(255, 46, 46), Callback = function(v) print("glow:", v) end })

-- ── Players ──────────────────────────────────────────────────
local Plrs = Window:Page({ Name = "Players", Icon = "users" })
tabIcons[Plrs] = "users"
local TpP = Plrs:Section({ Name = "Teleport", Side = 1 })
TpP:Textbox({ Name = "Player name", Placeholder = "e.g. Builderman", Flag = "TpTarget", Callback = function() end })
TpP:Button({ Name = "Teleport to player", Callback = function()
  local needle = Library.Flags and Library.Flags.TpTarget
  if type(needle) == "table" then needle = needle.Value end
  if type(needle) ~= "string" or needle == "" then return end
  needle = string.lower(needle)
  local target = nil
  for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and string.find(string.lower(p.Name), needle, 1, true) then target = p break end
  end
  pcall(function()
    local hrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local mine = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and mine then mine.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
  end)
end })
local Here = Plrs:Section({ Name = "In server", Side = 2 })
do
  local names, n = {}, 0
  pcall(function()
    for _, p in ipairs(Players:GetPlayers()) do
      if p ~= LocalPlayer then
        n = n + 1
        if #names < 8 then table.insert(names, p.Name) end
      end
    end
  end)
  Here:Label(n > 0 and (n .. " other(s): " .. table.concat(names, ", ")) or "Nobody else here.")
end

-- Re-resolve tab icons once the Lucide pack has arrived (first load is slow)
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
print("[Speedy x Stellar] loaded — accent red, cards live")
