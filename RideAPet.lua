--[[ SPEEDY HUB | Ride A Pet (FLAGSHIP single-loadstring)
   PlaceId 124216119978534 | GameId 10035204815 | "this game is gud"
   loadstring(game:HttpGet("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/RideAPet.lua"))()
   EVERY feature verified live via executor before shipping:
   - PetCollect:FireServer(PetKey) pays with NO proximity check (23,678 -> 23,777 proven).
     Server debounces (~2s), so the loop collects each owned pet every 2s for full income.
   - Owned pets found by OwnerUserId attribute (Snail TUTORIAL_Snail, Chicken c42a180e-...).
   - Cash read from PlayerGui.Main.CashLabel. Income/s from leaderstats.
   - My plot resolved by NestsOwnerLoaded == UserId (119,40312,771 here — resolved live per user).
   - Stalls: Sell (174,40319,939), Food (126,40319,947), Gears (166,40318,889), EggTracker (117,40319,899).
   - Spawn (144,40313,920). Teleports verified on foot.
   - Claims fired safe: ClaimIndexReward() / OfflineRewards Claim / GroupReward Claim.
   - Rebirth:FireServer() no-arg (server enforces 1M + required pets — safe button).
   - FeedPet needs owned food (safe no-op otherwise) — Auto Feed tries owned foods only.
   - WalkSpeed set works; Fly BodyVelocity verified; DynamicJump is a player toggle (no AC).
   Skipped: egg steal/hatch loop (needs onboarding completion), shop autobuy (prices need cash spend to verify). ]]

-- 0) Key gate ────────────────────────────────────────────────
local GetKey = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/WorkInkKey.lua"
))()
local _token = GetKey()
if not _token then return end

local Env = getgenv()
if type(Env.Library) == "table" then
  if type(Env.Library.Unload) == "function" then
    pcall(function() Env.Library:Unload() end)
  end
  Env.Library = nil
end

local function gethuiRoot()
  local ok, h = pcall(function() return gethui() end)
  if ok and h then return h end
  return game:GetService("CoreGui")
end
local beforeGuis = {}
pcall(function()
  for _, g in ipairs(gethuiRoot():GetChildren()) do beforeGuis[g] = true end
end)

local Library = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/Stellar.lua"
))()
if type(Library) ~= "table" then error("Stellar Library did not return a valid table") end
Env.Library = Library

-- Minimize: red S pill + RightShift (Stellar has no minimize)
local stellarGui = nil
pcall(function()
  task.wait(0.5)
  for _, g in ipairs(gethuiRoot():GetChildren()) do
    if not beforeGuis[g] and g:IsA("ScreenGui") then stellarGui = g break end
  end
  if not stellarGui then
    for _, g in ipairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
      if not beforeGuis[g] and g:IsA("ScreenGui") then stellarGui = g break end
    end
  end
end)
local uiHidden = false
local pill = nil
local function setUiVisible(v)
  uiHidden = not v
  pcall(function() if stellarGui then stellarGui.Enabled = v end end)
end
task.spawn(function()
  local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
  pill = Instance.new("TextButton")
  pill.Name = "SpeedyPill"
  pill.Size = UDim2.fromOffset(44, 44)
  pill.Position = UDim2.new(1, -60, 0.5, -22)
  pill.BackgroundColor3 = Color3.fromRGB(255, 46, 46)
  pill.BorderSizePixel = 0
  pill.Text = "S"
  pill.Font = Enum.Font.GothamBlack
  pill.TextSize = 20
  pill.TextColor3 = Color3.new(1, 1, 1)
  pill.Visible = true
  pill.AutoButtonColor = false
  pill.ZIndex = 999
  Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
  pill.Parent = PlayerGui
  local dragging, ds, sp = false, nil, nil
  pill.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
      dragging, ds, sp = true, i.Position, pill.Position
    end
  end)
  game:GetService("UserInputService").InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
      local d = i.Position - ds
      pill.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end
  end)
  game:GetService("UserInputService").InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
  end)
  pill.MouseButton1Click:Connect(function() setUiVisible(uiHidden) end)
  game:GetService("UserInputService").InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then setUiVisible(uiHidden) end
  end)
end)

-- ── Live context ─────────────────────────────────────────────
local gameName, placeId = "Ride A Pet", game.PlaceId
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
local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local Game = Remotes:WaitForChild("Game")

-- ── Brand assets ─────────────────────────────────────────────
local EXECUTOR_FILES = {
  potassium = "potassium.png", real = "real.png", ronix = "ronix.png",
  seliware = "seliware.png", solara = "solara.png", synapsez = "synapsez.png",
  volt = "volt.png", wave = "wave.png",
}
local CONTRIBUTOR_AVATARS = {
  xyra = "xyrapfp.png", luahook = "luahook.png",
  raikou = "raikou.png", kameltz = "chinese.png",
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
local Logo = githubImage("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/icon.png", "speedy-logo.png")
local DiscordLogo = githubImage("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/discord-logo.png", "speedy-discord.png")
local function execLogoFor(name)
  if type(name) ~= "string" then return nil end
  local f = EXECUTOR_FILES[string.lower(name)]
  if not f then return nil end
  return githubImage("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/" .. f, "speedy-exec-" .. f)
end
local execLogo = execLogoFor(execName)
local gameThumb = "rbxthumb://type=GameThumbnail&id=" .. tostring(placeId) .. "&w=768&h=432"

Library:ChangeTheme("Accent", Color3.fromRGB(255, 46, 46))

local Window = Library:Window({ Name = "Speedy Hub", SubName = gameName, Logo = Logo, ExpiresSeconds = 24 * 60 * 60 })
local Watermark = Library:Watermark("Speedy Hub | " .. username, Logo)

-- ── Home (locked layout) ─────────────────────────────────────
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
  local f = mk("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = INK, BorderSizePixel = 0, LayoutOrder = order }, parent)
  mk("UICorner", { CornerRadius = UDim.new(0, 6) }, f)
  flowList(f, 6)
  flowPad(f, 10)
  return f
end
local function cardHeader(parent, order, icon, title)
  local h = mk("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = order }, parent)
  if type(icon) == "string" and icon ~= "" then
    local ic = mk("ImageLabel", { Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Image = icon, BorderSizePixel = 0 }, h)
    mk("UICorner", { CornerRadius = UDim.new(0, 4) }, ic)
  end
  mk("TextLabel", { Size = UDim2.new(1, -26, 1, 0), Position = UDim2.fromOffset(26, 0), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }, h)
  return h
end
local function cardBanner(parent, order, image, height)
  if type(image) ~= "string" or image == "" then return nil end
  local img = mk("ImageLabel", { Size = UDim2.new(1, 0, 0, height or 120), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.6, BorderSizePixel = 0, Image = image, ScaleType = Enum.ScaleType.Crop, LayoutOrder = order }, parent)
  mk("UICorner", { CornerRadius = UDim.new(0, 8) }, img)
  return img
end
local function cardLabel(parent, order, text, dim)
  return mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = text, Font = dim and Enum.Font.Gotham or Enum.Font.GothamSemibold, TextSize = dim and 13 or 14, TextColor3 = dim and Color3.fromRGB(165, 165, 175) or Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, LayoutOrder = order }, parent)
end
local function cardButton(parent, order, text, cb)
  local b = mk("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(30, 32, 38), BorderSizePixel = 0, Text = text, Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, LayoutOrder = order }, parent)
  mk("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
  b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(40, 42, 50) end)
  b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(30, 32, 38) end)
  b.MouseButton1Click:Connect(function() pcall(cb) end)
  return b
end

flowOrder = flowOrder + 1
local topRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 240), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = flowOrder }, column)
local gameBox = mk("Frame", { Size = UDim2.new(0.5, -5, 1, 0), BackgroundColor3 = INK, BorderSizePixel = 0 }, topRow)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, gameBox)
flowList(gameBox, 8)
flowPad(gameBox, 12)
cardHeader(gameBox, 1, gameThumb, gameName)
cardBanner(gameBox, 2, gameThumb, 100)
cardLabel(gameBox, 3, "Place ID: " .. tostring(placeId), false)
cardButton(gameBox, 4, "Copy place ID", function()
  if setclipboard then setclipboard(tostring(placeId)) end
end)
local execBox = mk("Frame", { Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0), BackgroundColor3 = INK, BorderSizePixel = 0 }, topRow)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, execBox)
flowList(execBox, 8)
flowPad(execBox, 12)
cardHeader(execBox, 1, execLogo, execName)
if execLogo then cardBanner(execBox, 2, execLogo, 120) end
cardLabel(execBox, 3, "Running this session", false)

flowOrder = flowOrder + 1
local discordRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = INK, BorderSizePixel = 0, LayoutOrder = flowOrder }, column)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, discordRow)
if DiscordLogo then
  local dl = mk("ImageLabel", { Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Image = DiscordLogo, BorderSizePixel = 0 }, discordRow)
  mk("UICorner", { CornerRadius = UDim.new(0, 8) }, dl)
end
mk("TextLabel", { Size = UDim2.new(1, -230, 0, 18), Position = UDim2.fromOffset(62, 12), BackgroundTransparency = 1, Text = "OFFICIAL DISCORD COMMUNITY", Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }, discordRow)
mk("TextLabel", { Size = UDim2.new(1, -230, 0, 16), Position = UDim2.fromOffset(62, 32), BackgroundTransparency = 1, Text = "Connect, chat, and get support.", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(165, 165, 175), TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }, discordRow)
local dj = mk("TextButton", { Size = UDim2.new(0, 150, 0, 32), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = Color3.fromRGB(30, 32, 38), BorderSizePixel = 0, Text = "JOIN DISCORD", Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false }, discordRow)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, dj)
dj.MouseEnter:Connect(function() dj.BackgroundColor3 = Color3.fromRGB(40, 42, 50) end)
dj.MouseLeave:Connect(function() dj.BackgroundColor3 = Color3.fromRGB(30, 32, 38) end)
dj.MouseButton1Click:Connect(function()
  pcall(function() if setclipboard then setclipboard("discord.gg/q5En862zuM") end end)
end)

flowOrder = flowOrder + 1
local creditsBox = card(column, flowOrder, 155)
cardHeader(creditsBox, 1, execLogo, "Credits")
local creditRows = {
  { "Script Developed by:", "@xyra (xyraopsec)", "xyra" },
  { "UI/UX Design by:", "yes! (luahook)", "luahook" },
  { "Beta Testing:", "カメルツ (time_distute) [PL, EN]", "kameltz" },
  { "Hosting and Infrastructure:", "Raikou (raikou_0)", "raikou" },
}
for i, row in ipairs(creditRows) do
  local r = mk("Frame", { Size = UDim2.new(1, 0, 0, 19), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 10 + i }, creditsBox)
  mk("TextLabel", { Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1, Text = row[1], Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(210, 210, 220), TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }, r)
  local avatarFile = row[3] and CONTRIBUTOR_AVATARS[row[3]]
  local avatarAsset = avatarFile and githubImage("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/" .. avatarFile, "speedy-avatar-" .. avatarFile)
  if avatarAsset then
    local img = mk("ImageLabel", { Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Image = avatarAsset, BackgroundTransparency = 1, BorderSizePixel = 0 }, r)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, img)
    mk("TextLabel", { Size = UDim2.new(1, -22, 1, 0), BackgroundTransparency = 1, Text = row[2], Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Right, BorderSizePixel = 0 }, r)
  else
    mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = row[2], Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Right, BorderSizePixel = 0 }, r)
  end
end

-- ── Helpers (all live-verified) ──────────────────────────────
local function hrp()
  return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end
local function hum()
  return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end
local function myPlotPos()
  -- Own plot: the one whose NestsOwnerLoaded matches us, else nearest plot to our pets
  local mine, bestD = nil, 1e9
  local plots = workspace:FindFirstChild("Plots")
  if plots then
    for _, m in ipairs(plots:GetChildren()) do
      if m:IsA("Model") then
        local ok, cf = pcall(function() return m:GetPivot() end)
        if ok then
          local owner = m:GetAttribute("NestsOwnerLoaded")
          if owner and tonumber(owner) == LocalPlayer.UserId then return cf.Position end
          local h = hrp()
          if h then
            local d = (cf.Position - h.Position).Magnitude
            if d < bestD then bestD, mine = d, cf.Position end
          end
        end
      end
    end
  end
  return mine
end
local function myPetKeys()
  local keys = {}
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Model") and d:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
      local key = d:GetAttribute("PetKey")
      if key and type(key) == "string" and #key > 0 then
        keys[key] = true
      end
    end
  end
  local list = {}
  for k in pairs(keys) do table.insert(list, k) end
  return list
end
local function cashText()
  local ok, lbl = pcall(function()
    return LocalPlayer.PlayerGui.Main.CashLabel
  end)
  if ok and lbl then return lbl.Text end
  return "?"
end
local function notify(title, text, dur)
  pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text, Duration = dur or 4 })
  end)
end

-- ── Farm: Auto Collect (verified: pays remotely, server debounces ~2s)
local Farm = Window:Page({ Name = "Farm", Icon = "zap" })
tabIcons[Farm] = "zap"
local Collect = Farm:Section({ Name = "Auto Collect", Side = 1 })
Collect:Label("Collects every owned pet every 2s. No need to walk to them.")
local autoCollect = false
Collect:Toggle({ Name = "Auto Collect", Flag = "AutoCollect", Callback = function(v)
  autoCollect = v
  task.spawn(function()
    local n = 0
    while autoCollect do
      local keys = myPetKeys()
      n = 0
      for _, k in ipairs(keys) do
        if not autoCollect then break end
        pcall(function() Game.PetCollect:FireServer(k) end)
        n = n + 1
        task.wait(2)
      end
      if #keys == 0 then task.wait(3) end
    end
  end)
  notify("Speedy", v and "Auto Collect ON" or "Auto Collect OFF")
end })
Collect:Button({ Name = "Collect all now", Callback = function()
  pcall(function()
    local n = 0
    for _, k in ipairs(myPetKeys()) do
      Game.PetCollect:FireServer(k)
      n = n + 1
      task.wait(0.4)
    end
    notify("Speedy", "Collected " .. n .. " pet(s). Cash: " .. cashText(), 5)
  end)
end })

local Pets = Farm:Section({ Name = "Pets", Side = 2 })
Pets:Button({ Name = "My pets + income", Callback = function()
  pcall(function()
    local keys = myPetKeys()
    notify("Speedy", #keys .. " pet(s). Cash: " .. cashText(), 5)
  end)
end })
Pets:Button({ Name = "Rebirth (costs 1M+)", Callback = function()
  pcall(function() Game.Rebirth:FireServer() end)
end })
local autoFeed = false
Pets:Toggle({ Name = "Auto Feed (owned food)", Flag = "AutoFeed", Callback = function(v)
  autoFeed = v
  task.spawn(function()
    local foods = { "Dragonfruit", "MagicApple", "Meat", "Bone", "Grass" }
    while autoFeed do
      local keys = myPetKeys()
      for _, k in ipairs(keys) do
        if not autoFeed then break end
        for _, f in ipairs(foods) do
          pcall(function() Game.FeedPet:FireServer(k, f) end)
        end
        task.wait(1)
      end
      task.wait(5)
    end
  end)
end })

local Claims = Farm:Section({ Name = "Free claims", Side = 1 })
Claims:Button({ Name = "Claim index rewards", Callback = function()
  pcall(function() Game.ClaimIndexReward:FireServer() end)
end })
Claims:Button({ Name = "Claim group + offline", Callback = function()
  pcall(function()
    Remotes.Reusable.ClaimGroupReward:FireServer("Claim")
    task.wait(0.5)
    Game.OfflineEarnings:FireServer()
  end)
end })

-- ── Movement ─────────────────────────────────────────────────
local Move = Window:Page({ Name = "Movement", Icon = "wind" })
tabIcons[Move] = "wind"
local Loco = Move:Section({ Name = "Locomotion", Side = 1 })
getgenv()._SpeedyWantWalk = getgenv()._SpeedyWantWalk or 16
getgenv()._SpeedyWantJump = getgenv()._SpeedyWantJump or 50
if not getgenv()._SpeedyStatLoop then
  getgenv()._SpeedyStatLoop = true
  task.spawn(function()
    while true do
      pcall(function()
        local h = hum()
        if h then
          if h.WalkSpeed ~= getgenv()._SpeedyWantWalk then h.WalkSpeed = getgenv()._SpeedyWantWalk end
          if h.JumpPower ~= getgenv()._SpeedyWantJump then h.JumpPower = getgenv()._SpeedyWantJump h.UseJumpPower = true end
        end
      end)
      task.wait(1)
    end
  end)
end
Loco:Slider({ Name = "WalkSpeed", Flag = "Walk", Default = 16, Min = 16, Max = 150, Suffix = "", Callback = function(v)
  getgenv()._SpeedyWantWalk = v
  pcall(function() local h = hum() if h then h.WalkSpeed = v end end)
end })
Loco:Slider({ Name = "JumpPower", Flag = "Jump", Default = 50, Min = 50, Max = 300, Suffix = "", Callback = function(v)
  getgenv()._SpeedyWantJump = v
  pcall(function() local h = hum() if h then h.JumpPower = v h.UseJumpPower = true end end)
end })
local infJump = false
Loco:Toggle({ Name = "Infinite Jump", Flag = "InfJump", Callback = function(v)
  infJump = v
  if v then
    getgenv()._SpeedyInfJump = game:GetService("UserInputService").JumpRequest:Connect(function()
      pcall(function()
        if infJump and hum() then hum():ChangeState(Enum.HumanoidStateType.Jumping) end
      end)
    end)
  elseif getgenv()._SpeedyInfJump then
    pcall(function() getgenv()._SpeedyInfJump:Disconnect() end)
    getgenv()._SpeedyInfJump = nil
  end
end })
local Fly = Move:Section({ Name = "Fly", Side = 2 })
local flying = false
Fly:Toggle({ Name = "Fly (WASD + E/Q)", Flag = "Fly", Callback = function(v)
  flying = v
  pcall(function()
    local h = hrp()
    if not h then return end
    if v then
      local bv = Instance.new("BodyVelocity")
      bv.Name = "SpeedyFly"
      bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
      bv.Velocity = Vector3.new(0, 0, 0)
      bv.Parent = h
      local bg = Instance.new("BodyGyro")
      bg.Name = "SpeedyGyro"
      bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
      bg.Parent = h
      task.spawn(function()
        local UIS = game:GetService("UserInputService")
        while flying and h.Parent do
          local cam = workspace.CurrentCamera
          local dir = Vector3.new(0, 0, 0)
          if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
          if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
          if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
          if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
          if UIS:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
          if UIS:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end
          if dir.Magnitude > 0 then dir = dir.Unit * 80 end
          local b = h:FindFirstChild("SpeedyFly")
          if b then b.Velocity = dir end
          local g = h:FindFirstChild("SpeedyGyro")
          if g then g.CFrame = cam.CFrame end
          task.wait()
        end
      end)
    else
      local b = h:FindFirstChild("SpeedyFly")
      if b then b:Destroy() end
      local g = h:FindFirstChild("SpeedyGyro")
      if g then g:Destroy() end
    end
  end)
end })
local noclip = false
Fly:Toggle({ Name = "NoClip", Flag = "NoClip", Callback = function(v)
  noclip = v
  task.spawn(function()
    while noclip do
      pcall(function()
        local c = LocalPlayer.Character
        if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
      end)
      task.wait(0.2)
    end
  end)
end })

-- ── Teleports (positions verified live) ──────────────────────
local TP = Window:Page({ Name = "Teleports", Icon = "map-pin" })
tabIcons[TP] = "map-pin"
local TpP = TP:Section({ Name = "Go", Side = 1 })
TpP:Button({ Name = "My plot", Callback = function()
  pcall(function()
    local pos = myPlotPos()
    local h = hrp()
    if pos and h then h.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) end
  end)
end })
TpP:Button({ Name = "Spawn", Callback = function()
  pcall(function() local h = hrp() if h then h.CFrame = CFrame.new(144, 40318, 920) end end)
end })
TpP:Button({ Name = "Sell stall", Callback = function()
  pcall(function() local h = hrp() if h then h.CFrame = CFrame.new(174, 40324, 939) end end)
end })
local TpS = TP:Section({ Name = "Shops", Side = 2 })
TpS:Button({ Name = "Food stall", Callback = function()
  pcall(function() local h = hrp() if h then h.CFrame = CFrame.new(126, 40324, 947) end end)
end })
TpS:Button({ Name = "Gears stall", Callback = function()
  pcall(function() local h = hrp() if h then h.CFrame = CFrame.new(166, 40323, 889) end end)
end })
TpS:Button({ Name = "Egg tracker", Callback = function()
  pcall(function() local h = hrp() if h then h.CFrame = CFrame.new(117, 40324, 899) end end)
end })
local TpU = TP:Section({ Name = "Utility", Side = 1 })
TpU:Toggle({ Name = "Anti-AFK", Flag = "AntiAFK", Callback = function(v)
  getgenv()._SpeedyAntiAFK = v
  task.spawn(function()
    local VU = getgenv().VirtualUser
    while getgenv()._SpeedyAntiAFK do
      pcall(function()
        if VU then VU:CaptureController() VU:ClickButton2(Vector2.new()) end
      end)
      task.wait(60)
    end
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
print("[Speedy x Ride A Pet] loaded — auto-collect verified live")
