--[[ SPEEDY x SerhiiUI | branded showcase v2 (TEST BRANCH ONLY)
   Redesign notes (from cheat-menu + dark-UI research):
   - Surfaces are blue-grey dark, never pure black (no halation)
   - Text is off-white, not pure white (less sear, same contrast)
   - ONE accent: Speedy red, slightly lightened for dark surfaces
   - Sections + Dividers create rhythm; every control earns its row
   Production files on master are untouched. ]]

local SerhiiUI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/CoderSerg/serhiiui/refs/heads/main/src/SerhiiUI.lua"
))()

-- ── Custom logo ──────────────────────────────────────────────
-- 1. Upload logo.png to Roblox (Creator Hub > Images) to get an asset ID.
-- 2. Replace 0 below with that ID. Until then, no icon (clean text).
local SPEEDY_LOGO_ID = 0
if SPEEDY_LOGO_ID ~= 0 then
  SerhiiUI:AddIcons({ speedy = "rbxassetid://" .. SPEEDY_LOGO_ID })
end

-- ── Speedy theme v2 ──────────────────────────────────────────
SerhiiUI:CreateTheme("Speedy", {
  Background   = Color3.fromHex("#101014"),
  Element      = Color3.fromHex("#17171d"),
  ElementHover = Color3.fromHex("#202028"),
  Text         = Color3.fromHex("#ededf0"),
  SubText      = Color3.fromHex("#9c9ca8"),
  Accent       = Color3.fromHex("#ff2e2e"),
})
SerhiiUI:SetTheme("Speedy")

-- ── Window ───────────────────────────────────────────────────
local Window = SerhiiUI:CreateWindow({
  Title = "Speedy Hub",
  SubTitle = "Driving Empire · v1.0",
  Icon = SPEEDY_LOGO_ID ~= 0 and "speedy" or nil,
  Size = UDim2.fromOffset(600, 460),
  ToggleKey = Enum.KeyCode.RightShift,
  ConfigFolder = "SpeedyHub/configs",
})
SerhiiUI:SetTheme("Speedy") -- re-apply after build so every element picks it up

-- ── Live context (game + executor) ───────────────────────────
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

-- ── Home ─────────────────────────────────────────────────────
local Home = Window:Tab({ Title = "Home", Icon = "house" })
Home:Paragraph({
  Title = gameName,
  Icon = "info",
  Desc = "Executor: " .. execName .. " · Configs + theme live below.",
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
Home:Text({ Title = "RightShift hides the window. Settings tab holds themes + configs.", Muted = true })

-- ── Cars ─────────────────────────────────────────────────────
local Cars = Window:Tab({ Title = "Cars" })
Cars:Section({ Title = "Performance" })
Cars:Toggle({ Title = "Auto Drive", Desc = "Steers the car for you", Icon = "power", Default = false, Flag = "AutoDrive", Callback = function(v) print("AutoDrive:", v) end })
Cars:Slider({ Title = "Max Speed", Desc = "Studs per second", Icon = "gauge", Value = { Min = 50, Max = 300, Default = 150 }, Step = 5, Flag = "MaxSpeed", Callback = function(v) print("Speed:", v) end })
Cars:Dropdown({ Title = "Engine", Desc = "Power curve preset", Values = { "Stock", "Sport", "Race" }, Default = "Stock", Flag = "Engine", Callback = function(v) print("Engine:", v) end })
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
Settings:Section({ Title = "Session" })
Settings:Button({ Title = "Minimize", Desc = "Collapse to the floating button", Icon = "minus", Callback = function() Window:Minimize() end })
Settings:Button({ Title = "Unload UI", Desc = "Destroys the window", Icon = "x", Callback = function() Window:Destroy() end })
Settings:Divider()
Settings:Text({ Title = "Speedy Hub · loader + dashboard linked.", Muted = true })

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
