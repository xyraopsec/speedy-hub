--[[ SPEEDY x SerhiiUI | branded showcase (TEST BRANCH ONLY)
   Speedy theme + Lucide icons + key gate + config saving.
   Production files on master are untouched. ]]

local SerhiiUI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/CoderSerg/serhiiui/refs/heads/main/src/SerhiiUI.lua"
))()

-- ── Custom logo ──────────────────────────────────────────────
-- 1. Upload logo.png to Roblox (Creator Hub > Images) to get an asset ID.
-- 2. Replace 0 below with that ID. Until then the zap icon is used.
local SPEEDY_LOGO_ID = 0
if SPEEDY_LOGO_ID ~= 0 then
  SerhiiUI:AddIcons({ speedy = "rbxassetid://" .. SPEEDY_LOGO_ID })
end

-- ── Speedy theme (matches loader red + dashboard mono) ───────
SerhiiUI:CreateTheme("Speedy", {
  Background   = Color3.fromHex("#0d0d10"),
  Element      = Color3.fromHex("#17171c"),
  ElementHover = Color3.fromHex("#232028"),
  Text         = Color3.fromHex("#ffffff"),
  SubText      = Color3.fromHex("#a7a7b0"),
  Accent       = Color3.fromHex("#ff1a1a"),
})
SerhiiUI:SetTheme("Speedy")

-- ── Window ───────────────────────────────────────────────────
local Window = SerhiiUI:CreateWindow({
  Title = "Speedy Hub",
  SubTitle = "Driving Empire",
  Icon = SPEEDY_LOGO_ID ~= 0 and "speedy" or "zap",
  Size = UDim2.fromOffset(600, 460),
  ToggleKey = Enum.KeyCode.RightShift,
  ConfigFolder = "SpeedyHub/configs",
  KeySystem = {
    Title = "Speedy Hub",
    Note = "Demo build — key is: speedy123",
    Key = { "speedy123" },
    SaveKey = true,
    Folder = "SpeedyHub",
    GetKey = "https://discord.gg/speedy",
  },
})
if not Window then return end

-- ── Home ─────────────────────────────────────────────────────
local Home = Window:Tab({ Title = "Home", Icon = "house" })
Home:Paragraph({
  Title = "Welcome to Speedy",
  Icon = "info",
  Desc = "Car & moto scripts with one shared look. Everything below is live — flip toggles, drag sliders, switch themes.",
})
Home:Button({ Title = "Join Discord", Desc = "Copies invite to clipboard", Icon = "bell", Callback = function()
  if setclipboard then setclipboard("discord.gg/speedy") end
  SerhiiUI:Notify({ Title = "Speedy", Content = "Discord invite copied!" })
end })
Home:Divider()
Home:Text({ Title = "Tip: RightShift hides the window.", Muted = true })

-- ── Cars ─────────────────────────────────────────────────────
local Cars = Window:Tab({ Title = "Cars", Icon = "car" })
Cars:Section({ Title = "Performance" })
Cars:Toggle({ Title = "Auto Drive", Desc = "Steers the car for you", Icon = "navigation", Default = false, Flag = "AutoDrive", Callback = function(v) print("AutoDrive:", v) end })
Cars:Slider({ Title = "Max Speed", Icon = "gauge", Value = { Min = 50, Max = 300, Default = 150 }, Step = 5, Flag = "MaxSpeed", Callback = function(v) print("Speed:", v) end })
Cars:Dropdown({ Title = "Engine", Desc = "Power curve preset", Icon = "cog", Values = { "Stock", "Sport", "Race" }, Default = "Stock", Flag = "Engine", Callback = function(v) print("Engine:", v) end })
Cars:Section({ Title = "Teleport" })
Cars:Input({ Title = "Waypoint", Desc = "Named teleport target", Icon = "map-pin", Placeholder = "e.g. Dealership", Flag = "Waypoint", Callback = function(text, enter) if enter then print("Go to:", text) end end })

-- ── Moto ─────────────────────────────────────────────────────
local Moto = Window:Tab({ Title = "Moto", Icon = "bike" })
Moto:Section({ Title = "Bike setup" })
Moto:Toggle({ Title = "Wheelie assist", Desc = "Holds the balance point", Icon = "arrow-up", Default = false, Flag = "Wheelie", Callback = function(v) print("Wheelie:", v) end })
Moto:Slider({ Title = "Grip", Icon = "circle-dot", Value = { Min = 0, Max = 100, Default = 70 }, Step = 1, Flag = "Grip", Callback = function(v) print("Grip:", v) end })
Moto:Keybind({ Title = "Stunt key", Icon = "keyboard", Default = Enum.KeyCode.G, Flag = "StuntKey", Callback = function() print("Stunt!") end })
Moto:Colorpicker({ Title = "Bike glow", Icon = "paintbrush", Default = Color3.fromRGB(255, 26, 26), Flag = "Glow", Callback = function(c) print("glow:", c) end })

-- ── Settings ─────────────────────────────────────────────────
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
Settings:Section({ Title = "Appearance" })
Settings:Dropdown({ Title = "Theme", Desc = "Live-switch the whole UI", Icon = "palette", Values = SerhiiUI:GetThemes(), Default = "Speedy", Callback = function(name) SerhiiUI:SetTheme(name) end })
Settings:Section({ Title = "Configs" })
Settings:Button({ Title = "Save config", Desc = "Writes flagged values to disk", Icon = "save", Callback = function()
  Window.Config:Save("default")
  SerhiiUI:Notify({ Title = "Speedy", Content = "Config saved." })
end })
Settings:Button({ Title = "Load config", Desc = "Restores flagged values", Icon = "folder-open", Callback = function()
  Window.Config:Load("default")
  SerhiiUI:Notify({ Title = "Speedy", Content = "Config loaded." })
end })
Settings:Section({ Title = "Loader" })
Settings:Code({ Title = "Loader loadstring", Code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/Loader.lua"))()' })
Settings:Button({ Title = "Unload UI", Desc = "Destroys the window", Icon = "log-out", Callback = function() Window:Destroy() end })

SerhiiUI:Notify({ Title = "Speedy Hub", Content = "Loaded — enjoy!", Duration = 4 })
