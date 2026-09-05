--[[ SPEEDY x SerhiiUI | full redesign v3 (TEST BRANCH ONLY)
   Lessons from the legends (skeet / Neverlose / ANUI):
   - Window subtitle carries LIVE context (game + executor), not slogans
   - One accent everywhere; status shown as facts, not badges
   - Players tab with real actions; Settings owns themes + configs + session
   - Two first-party themes (Dark + Light), live-switchable
   Production files on master are untouched. ]]

local SerhiiUI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/CoderSerg/serhiiui/refs/heads/main/src/SerhiiUI.lua"
))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ── Live context ─────────────────────────────────────────────
local gameName = "Unknown game"
pcall(function()
  gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)
local execName = "Unknown executor"
pcall(function()
  local id = identifyexecutor()
  if type(id) == "table" then execName = tostring(id[1] or "Unknown executor")
  elseif type(id) == "string" and id ~= "" then execName = id end
end)

-- ── Custom logo (upload logo.png to Roblox, paste asset ID) ──
local SPEEDY_LOGO_ID = 0
if SPEEDY_LOGO_ID ~= 0 then
  SerhiiUI:AddIcons({ speedy = "rbxassetid://" .. SPEEDY_LOGO_ID })
end

-- ── Speedy Dark ──────────────────────────────────────────────
SerhiiUI:CreateTheme("Speedy Dark", {
  Background   = Color3.fromHex("#101014"),
  Element      = Color3.fromHex("#17171d"),
  ElementHover = Color3.fromHex("#202028"),
  Text         = Color3.fromHex("#ededf0"),
  SubText      = Color3.fromHex("#9c9ca8"),
  Accent       = Color3.fromHex("#ff2e2e"),
})
-- ── Speedy Light ─────────────────────────────────────────────
SerhiiUI:CreateTheme("Speedy Light", {
  Background   = Color3.fromHex("#f2f2f6"),
  Element      = Color3.fromHex("#ffffff"),
  ElementHover = Color3.fromHex("#e6e6ec"),
  Text         = Color3.fromHex("#16161a"),
  SubText      = Color3.fromHex("#55555e"),
  Accent       = Color3.fromHex("#e02020"),
})
SerhiiUI:SetTheme("Speedy Dark")

-- ── Window ───────────────────────────────────────────────────
local Window = SerhiiUI:CreateWindow({
  Title = "Speedy Hub",
  SubTitle = gameName .. " · " .. execName,
  Icon = SPEEDY_LOGO_ID ~= 0 and "speedy" or nil,
  Size = UDim2.fromOffset(620, 470),
  ToggleKey = Enum.KeyCode.RightShift,
  ConfigFolder = "SpeedyHub/configs",
})
SerhiiUI:SetTheme("Speedy Dark") -- re-apply after build so every element picks it up

-- ── Home ─────────────────────────────────────────────────────
local Home = Window:Tab({ Title = "Home", Icon = "house" })
Home:Paragraph({
  Title = "Session",
  Icon = "info",
  Desc = "Game: " .. gameName .. "\nExecutor: " .. execName .. "\nPress RightShift to hide the window.",
})
Home:Section({ Title = "Quick actions" })
Home:Button({ Title = "Join Discord", Desc = "Copies invite to clipboard", Icon = "bell", Callback = function()
  if setclipboard then setclipboard("discord.gg/speedy") end
  SerhiiUI:Notify({ Title = "Speedy", Content = "Discord invite copied!" })
end })
Home:Button({ Title = "Copy loader", Desc = "Loader loadstring to clipboard", Icon = "copy", Callback = function()
  if setclipboard then setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/Loader.lua"))()') end
  SerhiiUI:Notify({ Title = "Speedy", Content = "Loader copied!" })
end })
Home:Divider()
Home:Text({ Title = "Configs save per game. Themes switch live in Settings.", Muted = true })

-- ── Cars ─────────────────────────────────────────────────────
local Cars = Window:Tab({ Title = "Cars" })
Cars:Section({ Title = "Performance" })
Cars:Toggle({ Title = "Auto Drive", Desc = "Steers the car for you", Icon = "power", Default = false, Flag = "AutoDrive", Callback = function(v) print("AutoDrive:", v) end })
Cars:Slider({ Title = "Max Speed", Desc = "Studs per second", Icon = "gauge", Value = { Min = 50, Max = 300, Default = 150 }, Step = 5, Flag = "MaxSpeed", Callback = function(v) print("Speed:", v) end })
Cars:Dropdown({ Title = "Engine", Desc = "Power curve preset", Values = { "Stock", "Sport", "Race" }, Default = "Stock", Flag = "Engine", Callback = function(v) print("Engine:", v) end })
Cars:Section({ Title = "Visuals" })
Cars:Toggle({ Title = "Car ESP", Desc = "Boxes over nearby vehicles", Default = false, Flag = "CarESP", Callback = function(v) print("CarESP:", v) end })
Cars:Colorpicker({ Title = "ESP color", Icon = "paintbrush", Default = Color3.fromRGB(255, 46, 46), Flag = "ESPGColor", Callback = function(c) print("esp:", c) end })
Cars:Section({ Title = "Teleport" })
Cars:Input({ Title = "Waypoint", Desc = "Named teleport target", Placeholder = "e.g. Dealership", Flag = "Waypoint", Callback = function(text, enter) if enter then print("Go to:", text) end end })
Cars:Space({ Height = 4 })

-- ── Moto ─────────────────────────────────────────────────────
local Moto = Window:Tab({ Title = "Moto" })
Moto:Section({ Title = "Bike setup" })
Moto:Toggle({ Title = "Wheelie assist", Desc = "Holds the balance point", Default = false, Flag = "Wheelie", Callback = function(v) print("Wheelie:", v) end })
Moto:Slider({ Title = "Grip", Desc = "Tire friction multiplier", Value = { Min = 0, Max = 100, Default = 70 }, Step = 1, Flag = "Grip", Callback = function(v) print("Grip:", v) end })
Moto:Keybind({ Title = "Stunt key", Desc = "Triggers while held", Icon = "keyboard", Default = Enum.KeyCode.G, Flag = "StuntKey", Callback = function() print("Stunt!") end })
Moto:Colorpicker({ Title = "Bike glow", Desc = "Underglow color", Icon = "paintbrush", Default = Color3.fromRGB(255, 46, 46), Flag = "Glow", Callback = function(c) print("glow:", c) end })

-- ── Players ──────────────────────────────────────────────────
local Plrs = Window:Tab({ Title = "Players", Icon = "users" })
Plrs:Section({ Title = "Teleport" })
local tpBox = Plrs:Input({ Title = "Player name", Desc = "Partial names match", Placeholder = "e.g. Builderman", Flag = "TpTarget", Callback = function() end })
Plrs:Button({ Title = "Teleport to player", Desc = "Uses the name above", Icon = "send", Callback = function()
  local needle = nil
  pcall(function() needle = tpBox:Get() end)
  if type(needle) ~= "string" or needle == "" then
    SerhiiUI:Notify({ Title = "Speedy", Content = "Type a player name first." })
    return
  end
  needle = string.lower(needle)
  local target = nil
  for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and string.find(string.lower(p.Name), needle, 1, true) then target = p break end
  end
  local ok = false
  pcall(function()
    local hrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local mine = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and mine then mine.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) ok = true end
  end)
  SerhiiUI:Notify({ Title = "Speedy", Content = ok and ("Teleported to " .. target.Name) or "Player not found." })
end })
Plrs:Divider()
Plrs:Text({ Title = "In server right now:", Muted = true })
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
  Plrs:Text({ Title = n > 0 and (n .. " other player(s): " .. table.concat(names, ", ")) or "Nobody else here.", Muted = true })
end

-- ── Settings ─────────────────────────────────────────────────
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
Settings:Section({ Title = "Appearance" })
Settings:Dropdown({ Title = "Theme", Desc = "Live-switch the whole UI", Icon = "palette", Values = { "Speedy Dark", "Speedy Light", "Dark", "Light" }, Default = "Speedy Dark", Callback = function(name) SerhiiUI:SetTheme(name) end })
Settings:Section({ Title = "Configs" })
Settings:Button({ Title = "Save config", Desc = "Writes flagged values to disk", Icon = "save", Callback = function()
  Window.Config:Save("default")
  SerhiiUI:Notify({ Title = "Speedy", Content = "Config saved." })
end })
Settings:Button({ Title = "Load config", Desc = "Restores flagged values", Icon = "folder-open", Callback = function()
  Window.Config:Load("default")
  SerhiiUI:Notify({ Title = "Speedy", Content = "Config loaded." })
end })
Settings:Section({ Title = "Session" })
Settings:Button({ Title = "Minimize", Desc = "Collapse to the floating button", Icon = "minus", Callback = function() Window:Minimize() end })
Settings:Button({ Title = "Unload UI", Desc = "Destroys the window", Icon = "x", Callback = function() Window:Destroy() end })
Settings:Divider()
Settings:Code({ Title = "Loader loadstring", Code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/Loader.lua"))()' })

-- Upstream bug workaround: SerhiiUI never sets BackgroundTransparency on its
-- TextBox, so it renders opaque white in EVERY theme. Force it transparent
-- so the themed dark box behind it shows through (scoped to SerhiiUI's GUI).
pcall(function()
  local gui = SerhiiUI.ScreenGui
  if not gui then return end
  local function fix(inst)
    if inst:IsA("TextBox") and inst.BackgroundTransparency == 0 then
      local c = inst.BackgroundColor3
      if c.R > 0.9 and c.G > 0.9 and c.B > 0.9 then
        inst.BackgroundTransparency = 1
      end
    end
    for _, ch in ipairs(inst:GetChildren()) do fix(ch) end
  end
  fix(gui)
end)

SerhiiUI:Notify({ Title = "Speedy Hub", Content = "Loaded.", Duration = 4 })
