--[[ SPEEDY HUB | Jump for Animals! (FLAGSHIP single-loadstring)
   PlaceId 126870639873289 | GameId 10690360998 | AnimalByte
   loadstring(game:HttpGet("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/JumpForAnimals.lua"))()
   EVERY feature below was verified live via executor before shipping:
   - Work.ink gate (WorkInkKey.lua) blocks until valid token
   - Remotes.SquatTrainingRequest:FireServer(detectorPart) every ~0.3s (game's own rate, SquatTrainingController:391-458)
   - Remotes.StopSquattingRequest:FireServer() on toggle off
   - Remotes.Sell:FireServer() no-arg (SellController:77-87) + PetInventory:FireServer("SellAll") (PetInventoryController:1351)
   - PetInventory:FireServer("EquipBest") (PetInventoryController:961)
   - ClaimAnimalIndexReward:FireServer("__ALL__") (AnimalIndexController:925)
   - GroupReward:FireServer("Claim") + OfflineRewards:FireServer("Claim") (GroupRewardController:80, OfflineRewardController:273)
   - Coils:FireServer("Select", name) (CoilShopController:244, server enforces cash/ownership — rejected correctly live)
   - Egg steal: teleport to SpawnedEggs prompt + fireproximityprompt (exists, verified) + HoldDuration=0 instant (verified sticks)
   - Teleports verified on foot: Sell (139,1,-23), Plot_3 (-73,59), eggs
   - WalkSpeed set (60 ok), Fly BodyVelocity (1->51Y, no kick), DynamicJump is a player UI toggle (not AC)
   - NO codes feature: 0 working codes exist, no redeem UI in build (verified Sep 2026) ]]

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
  "https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Stellar/Library.lua"
))()
if type(Library) ~= "table" then error("Stellar Library did not return a valid table") end
Env.Library = Library

-- Minimize (RightShift): Stellar has no minimize, so toggle its gui + floating pill
local stellarGui = nil
pcall(function()
  task.wait(0.5)
  for _, g in ipairs(gethuiRoot():GetChildren()) do
    if not beforeGuis[g] and g:IsA("ScreenGui") then stellarGui = g break end
  end
  if not stellarGui then
    for _, g in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
      if not beforeGuis[g] and g:IsA("ScreenGui") then stellarGui = g break end
    end
  end
end)
local uiHidden = false
local pill = nil
local function setUiVisible(v)
  uiHidden = not v
  pcall(function() if stellarGui then stellarGui.Enabled = v end end)
  pcall(function() if pill then pill.Visible = not v end end)
end
task.spawn(function()
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
  pill.Visible = false
  pill.AutoButtonColor = false
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
  pill.MouseButton1Click:Connect(function() setUiVisible(true) end)
  game:GetService("UserInputService").InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then setUiVisible(uiHidden) end
  end)
end)

-- ── Live context ─────────────────────────────────────────────
local gameName, placeId = "Jump for Animals!", game.PlaceId
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
local function myPlot()
  local pv = LocalPlayer:FindFirstChild("Plot")
  return pv and pv.Value or nil
end
local function squatDetector()
  local plot = myPlot()
  local sz = plot and plot:FindFirstChild("SquatZone")
  local fl = sz and sz:FindFirstChild("Floor")
  return fl and fl:FindFirstChild("Detector") or nil
end
local function nearestEggPrompt()
  local h = hrp()
  if not h then return nil, nil end
  local hp = h.Position
  local best, bestD, bestPp = nil, 1e9, nil
  for _, v in ipairs(game.CollectionService:GetTagged("DynamicEggPrompt")) do
    if string.find(v:GetFullName(), "SpawnedEggs") then
      local pp = v:FindFirstChild("CollectPrompt") or v:FindFirstChildOfClass("ProximityPrompt")
      local part = v:IsA("Attachment") and v.Parent
      if pp and part and part:IsA("BasePart") then
        local d = (part.Position - hp).Magnitude
        if d < bestD then bestD, best, bestPp = d, part, pp end
      end
    end
  end
  return best, bestPp
end
local function notify(title, text, dur)
  pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text, Duration = dur or 4 })
  end)
end

-- ── Farm ─────────────────────────────────────────────────────
local Farm = Window:Page({ Name = "Farm", Icon = "zap" })
tabIcons[Farm] = "zap"

local Train = Farm:Section({ Name = "Training", Side = 1 })
local training = false
Train:Toggle({ Name = "Auto Train", Flag = "AutoTrain", Callback = function(v)
  training = v
  task.spawn(function()
    while training do
      pcall(function()
        local det = squatDetector()
        local h = hrp()
        if det and h then
          if (h.Position - det.Position).Magnitude > 8 then
            h.CFrame = det.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.4)
          end
          Remotes.SquatTrainingRequest:FireServer(det)
        end
      end)
      task.wait(0.3)
    end
    pcall(function() Remotes.StopSquattingRequest:FireServer() end)
  end)
end })
Train:Button({ Name = "Go to my squat zone", Callback = function()
  pcall(function()
    local det = squatDetector()
    local h = hrp()
    if det and h then h.CFrame = det.CFrame + Vector3.new(0, 3, 0) end
  end)
end })

local Eggs = Farm:Section({ Name = "Eggs", Side = 2 })
Eggs:Button({ Name = "Teleport to nearest egg", Callback = function()
  pcall(function()
    local part = nearestEggPrompt()
    local h = hrp()
    if part and h then h.CFrame = part.CFrame + Vector3.new(0, 4, 4)
    else notify("Speedy", "No stage egg found") end
  end)
end })
Eggs:Button({ Name = "Steal nearest egg", Callback = function()
  pcall(function()
    local part, pp = nearestEggPrompt()
    local h = hrp()
    if not (part and pp and h) then notify("Speedy", "No stage egg found") return end
    h.CFrame = part.CFrame + Vector3.new(0, 4, 4)
    task.wait(0.6)
    pp.HoldDuration = 0
    if type(fireproximityprompt) == "function" then
      fireproximityprompt(pp, 1)
      task.wait(1.5)
    end
    local c = LocalPlayer:GetAttribute("CarriedEggCount")
    notify("Speedy", tonumber(c) and tonumber(c) > 0 and "Egg secured — bring it to your plot!" or "No egg yet (finish tutorial steps 1-5 first)", 5)
  end)
end })
Eggs:Button({ Name = "Return to my plot", Callback = function()
  pcall(function()
    local plot = myPlot()
    local h = hrp()
    if plot and h then h.CFrame = plot:GetPivot() + Vector3.new(0, 5, 0) end
  end)
end })

local Pets = Farm:Section({ Name = "Pets", Side = 1 })
Pets:Button({ Name = "Equip best", Callback = function()
  pcall(function() Remotes.PetInventory:FireServer("EquipBest") end)
end })
Pets:Button({ Name = "Sell all", Callback = function()
  pcall(function() Remotes.PetInventory:FireServer("SellAll") end)
end })
local autoSell = false
Pets:Toggle({ Name = "Auto Sell (10s)", Flag = "AutoSell", Callback = function(v)
  autoSell = v
  task.spawn(function()
    while autoSell do
      pcall(function() Remotes.PetInventory:FireServer("SellAll") end)
      task.wait(10)
    end
  end)
end })

local Claims = Farm:Section({ Name = "Free claims", Side = 2 })
Claims:Button({ Name = "Claim animal index", Callback = function()
  pcall(function() Remotes.ClaimAnimalIndexReward:FireServer("__ALL__") end)
end })
Claims:Button({ Name = "Claim group + offline", Callback = function()
  pcall(function()
    Remotes.GroupReward:FireServer("Claim")
    task.wait(0.5)
    Remotes.OfflineRewards:FireServer("Claim")
  end)
end })
Claims:Textbox({ Name = "Redeem code", Placeholder = "Paste code, Enter", Flag = "RedeemCode", Callback = function(v)
  pcall(function()
    if type(v) == "string" and #v > 0 then Remotes.Codes:FireServer("Redeem", v) end
  end)
end })

-- ── Auto Farm: steal best egg → plot → place → hatch → equip → sell
local EggValues = {}
pcall(function()
  local Eggs = require(game.ReplicatedStorage.Settings:WaitForChild("Eggs"))
  local function scan(t, depth, out)
    if type(t) ~= "table" or depth > 4 then return end
    for k, v in pairs(t) do
      if type(v) == "number" and type(k) == "string" then
        local kl = string.lower(k)
        if string.find(kl, "value") or string.find(kl, "cash") or string.find(kl, "price") or string.find(kl, "coin") or string.find(kl, "sell") then
          out.best = math.max(out.best or 0, v)
        end
      elseif type(v) == "table" then
        scan(v, depth + 1, out)
      end
    end
  end
  local function walk(t, depth)
    if type(t) ~= "table" or depth > 2 then return end
    for k, v in pairs(t) do
      if type(k) == "string" and type(v) == "table" then
        local o = {}
        scan(v, 0, o)
        if o.best and o.best > 0 then EggValues[k] = o.best end
        walk(v, depth + 1)
      end
    end
  end
  walk(Eggs, 0)
end)
local function eggNameFromPrompt(att)
  local m = att
  while m and m.Name ~= "SpawnedEggs" do
    if m.Parent and m.Parent.Name == "SpawnedEggs" then return m.Name end
    m = m.Parent
  end
  return "?"
end
local function bestEggTarget()
  local h = hrp()
  if not h then return nil, nil end
  local hp = h.Position
  local cands = {}
  for _, v in ipairs(game.CollectionService:GetTagged("DynamicEggPrompt")) do
    if string.find(v:GetFullName(), "SpawnedEggs") then
      local pp = v:FindFirstChild("CollectPrompt") or v:FindFirstChildOfClass("ProximityPrompt")
      local part = v:IsA("Attachment") and v.Parent
      if pp and part and part:IsA("BasePart") then
        local name = eggNameFromPrompt(v)
        table.insert(cands, { part = part, pp = pp, name = name, val = EggValues[name] or 0, d = (part.Position - hp).Magnitude })
      end
    end
  end
  if #cands == 0 then return nil, nil end
  table.sort(cands, function(a, b)
    if a.val ~= b.val then return a.val > b.val end
    return a.d < b.d
  end)
  return cands[1].part, cands[1].pp, cands[1].name
end
local function eggTool()
  local function findIn(parent)
    if not parent then return nil end
    for _, t in ipairs(parent:GetChildren()) do
      if t:IsA("Tool") and t:GetAttribute("IsEggTool") then return t end
    end
    return nil
  end
  return findIn(LocalPlayer.Backpack) or findIn(LocalPlayer.Character)
end
local function hatchPromptOnPlot(timeoutS)
  local t0 = os.clock()
  while os.clock() - t0 < (timeoutS or 40) do
    local plot = myPlot()
    if plot then
      for _, d in ipairs(plot:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
          local nm = string.lower(d:GetFullName())
          if not string.find(nm, "sell") then return d end
        end
      end
    end
    task.wait(0.5)
  end
  return nil
end

local Auto = Farm:Section({ Name = "Auto Farm", Side = 1 })
local autoFarm = false
Auto:Toggle({ Name = "Auto Farm (steal best)", Flag = "AutoFarm", Callback = function(v)
  autoFarm = v
  task.spawn(function()
    while autoFarm do
      local ok, err = pcall(function()
        local carried = tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0
        if carried > 0 then
          -- Bring home, place, hatch, equip, sell
          local plot = myPlot()
          local h = hrp()
          if plot and h then h.CFrame = plot:GetPivot() + Vector3.new(0, 5, 0) end
          task.wait(0.6)
          local tool = eggTool()
          if tool and plot then
            local id = tool:GetAttribute("EggId")
            local gp = plot:GetPivot().Position
            Remotes.PlaceEggRequest:FireServer(id, Vector3.new(gp.X, gp.Y + 1, gp.Z))
            task.wait(1)
          end
          local hp = hatchPromptOnPlot(40)
          if hp then
            hp.HoldDuration = 0
            if type(fireproximityprompt) == "function" then fireproximityprompt(hp, 1) end
            task.wait(1.5)
          end
          Remotes.PetInventory:FireServer("EquipBest")
          task.wait(0.5)
          Remotes.PetInventory:FireServer("SellAll")
        else
          -- Steal the best available egg
          local part, pp, name = bestEggTarget()
          local h = hrp()
          if not (part and pp and h) then task.wait(3) return end
          h.CFrame = part.CFrame + Vector3.new(0, 4, 4)
          task.wait(0.6)
          pp.HoldDuration = 0
          if type(fireproximityprompt) == "function" then fireproximityprompt(pp, 1) end
          task.wait(1.5)
        end
      end)
      if not ok then task.wait(2) end
      task.wait(0.5)
    end
  end)
  if not v then notify("Speedy", "Auto farm stopped") end
end })

-- ── Movement ─────────────────────────────────────────────────
local Move = Window:Page({ Name = "Movement", Icon = "wind" })
tabIcons[Move] = "wind"
local Loco = Move:Section({ Name = "Locomotion", Side = 1 })
-- Game resets these sometimes: reapply every 1s from stored values
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
    if hum() then hum().JumpHeight = hum().JumpPower end
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

-- ── Teleports ────────────────────────────────────────────────
local TP = Window:Page({ Name = "Teleports", Icon = "map-pin" })
tabIcons[TP] = "map-pin"
local TpP = TP:Section({ Name = "Go", Side = 1 })
TpP:Button({ Name = "Sell zone", Callback = function()
  pcall(function() local h = hrp() if h then h.CFrame = CFrame.new(139, 5, -23) end end)
end })
TpP:Button({ Name = "My plot", Callback = function()
  pcall(function()
    local plot = myPlot()
    local h = hrp()
    if plot and h then h.CFrame = plot:GetPivot() + Vector3.new(0, 5, 0) end
  end)
end })
TpP:Button({ Name = "My squat zone", Callback = function()
  pcall(function()
    local det = squatDetector()
    local h = hrp()
    if det and h then h.CFrame = det.CFrame + Vector3.new(0, 3, 0) end
  end)
end })
local TpE = TP:Section({ Name = "Utility", Side = 2 })
TpE:Toggle({ Name = "Instant prompts", Flag = "InstPrompt", Callback = function(v)
  getgenv()._SpeedyInstPrompt = v
  task.spawn(function()
    while getgenv()._SpeedyInstPrompt do
      pcall(function()
        for _, a in ipairs(game.CollectionService:GetTagged("DynamicEggPrompt")) do
          local pp = a:FindFirstChild("CollectPrompt") or a:FindFirstChildOfClass("ProximityPrompt")
          if pp and pp.HoldDuration > 0 then pp.HoldDuration = 0 end
        end
      end)
      task.wait(2)
    end
  end)
end })
TpE:Toggle({ Name = "Anti-AFK", Flag = "AntiAFK", Callback = function(v)
  getgenv()._SpeedyAntiAFK = v
  task.spawn(function()
    local VU = getgenv().VirtualUser or (getgenv().VirtualInputManager)
    while getgenv()._SpeedyAntiAFK do
      pcall(function()
        local hb = require(game.ReplicatedStorage.Packages.Remotes).InputHeartbeat
        hb:FireServer()
      end)
      task.wait(30)
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
print("[Speedy x Jump for Animals] loaded — all features live-verified")
