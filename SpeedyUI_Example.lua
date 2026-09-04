--[[ SPEEDY UI | Example — copy this shape for every game script ]]
-- ?v= cache buster: bump this every time SpeedyUI.lua changes, so the
-- executor never serves a stale cached copy of the library.
local SpeedyUI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/SpeedyUI.lua?v=1.2"
))()

local Window = SpeedyUI:CreateWindow({
  Title = "Speedy Hub",
  SubTitle = "Driving Empire",
  ToggleKey = Enum.KeyCode.RightShift, -- press to show / hide
})

-- Tabs ---------------------------------------------------------------
local Home = Window:AddTab("Home")
local Cars = Window:AddTab("Cars")
local Settings = Window:AddTab("Settings")

-- Home ---------------------------------------------------------------
Home:AddParagraph({
  Title = "Welcome to Speedy",
  Content = "All features below run on the shared SpeedyUI library — same look on every game.",
})
Home:AddButton({
  Title = "Join Discord",
  Callback = function()
    if setclipboard then setclipboard("discord.gg/speedy") end
    SpeedyUI:Notify({ Title = "Speedy", Content = "Discord invite copied!" })
  end,
})

-- Cars ---------------------------------------------------------------
Cars:AddSection("Performance")
Cars:AddToggle({
  Title = "Auto Drive", Description = "Steers the car for you",
  Default = false,
  Callback = function(v) print("AutoDrive:", v) end,
})
local speed = Cars:AddSlider({
  Title = "Max Speed", Min = 50, Max = 300, Default = 150,
  Callback = function(v) print("Speed:", v) end,
})
Cars:AddDropdown({
  Title = "Engine", Options = { "Stock", "Sport", "Race" }, Default = "Stock",
  Callback = function(v) print("Engine:", v) end,
})

Cars:AddSection("Teleport")
Cars:AddInput({
  Title = "Waypoint name", Placeholder = "e.g. Dealership",
  Callback = function(text, enter)
    if enter then print("Go to:", text) end
  end,
})

-- Settings -----------------------------------------------------------
Settings:AddKeybind({
  Title = "Panic key", Default = Enum.KeyCode.F,
  Callback = function() print("Panic! Disable everything") end,
})
Settings:AddButton({
  Title = "Unload UI",
  Callback = function() Window:Destroy() end,
})

SpeedyUI:Notify({ Title = "Speedy Hub", Content = "Loaded — enjoy!", Duration = 4 })
