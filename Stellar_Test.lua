--[[ SPEEDY x Stellar | branded showcase (TEST BRANCH ONLY)
   - Logo fetched from GitHub (icon.png) via writefile/getcustomasset — no upload needed
   - Tabs use Lucide icons + a delayed refresh pass once the pack arrives
   - Home: game square (live thumbnail banner) + executor square (logo banner),
     Join Discord below, credits at the bottom
   Production files on master are untouched. ]]
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
local EXECUTOR_LOGOS = {
  -- ["Delta"] = "rbxassetid://123456789",
  -- ["Solara"] = "rbxassetid://123456789",
  -- ["Wave"] = "rbxassetid://123456789",
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
local execLogo = EXECUTOR_LOGOS[execName]
local gameThumb = "rbxthumb://type=GameThumbnail&id=" .. tostring(placeId) .. "&w=768&h=432"

-- ── Accent ───────────────────────────────────────────────────
Library:ChangeTheme("Accent", Color3.fromRGB(255, 46, 46)) -- Speedy red

-- ── Window ───────────────────────────────────────────────────
local Window = Library:Window({ Name = "Speedy Hub", SubName = gameName, Logo = Logo })
local Watermark = Library:Watermark("Speedy Hub | " .. username, Logo)

-- Banner helper: big cropped image stacked on top of a section's content
local function banner(section, image, height)
  local content = section.Items and section.Items.Content and section.Items.Content.Instance
  if not content or type(image) ~= "string" or image == "" then return nil end
  local img = Instance.new("ImageLabel")
  img.Name = "Banner"
  img.Size = UDim2.new(1, 0, 0, height or 120)
  img.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
  img.BackgroundTransparency = 0.6
  img.BorderSizePixel = 0
  img.Image = image
  img.ScaleType = Enum.ScaleType.Crop
  img.LayoutOrder = -1
  local c = Instance.new("UICorner")
  c.CornerRadius = UDim.new(0, 8)
  c.Parent = img
  img.Parent = content
  return img
end

-- ── Home ─────────────────────────────────────────────────────
local tabIcons = {}
local Home = Window:Page({ Name = "Home", Icon = "house" })
tabIcons[Home] = "house"

local GameCard = Home:Section({ Name = gameName, Icon = gameThumb, Side = 1 })
banner(GameCard, gameThumb, 130)
GameCard:Label("Place ID: " .. tostring(placeId))
GameCard:Button({ Name = "Copy place ID", Callback = function()
  if setclipboard then setclipboard(tostring(placeId)) end
end })

local ExecCard = Home:Section({ Name = execName, Icon = execLogo, Side = 2 })
if execLogo then banner(ExecCard, execLogo, 170) end -- tall banner: executor logos get full room
ExecCard:Label("Running this session")

local JoinBox = Home:Section({ Name = "Community", Side = 1 })
JoinBox:Button({ Name = "Join Discord", Callback = function()
  if setclipboard then setclipboard("discord.gg/speedy") end
end })

local Credits = Home:Section({ Name = "Credits", Side = 2 })
Credits:Label("Speedy Hub · loader + dashboard linked")

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
