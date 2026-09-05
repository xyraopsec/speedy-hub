--[[ SPEEDY UI v2.0 | TEST — loads veryud.lua from the `test` branch.
   Test version only. Production (SpeedyUI.lua on master) is untouched. ]]
local SpeedyUI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/xyraopsec/speedy-hub/test/veryudfix.lua?v=2.0fix2"
))()

local Window = SpeedyUI:CreateWindow({
  Title = "Speedy Hub",
  SubTitle = "TEST BUILD",
  ToggleKey = Enum.KeyCode.RightShift,
})

local Home = Window:AddTab("Home")
local Cars = Window:AddTab("Cars")
local Settings = Window:AddTab("Settings")

Home:AddParagraph({
  Title = "v2.0 test build",
  Content = "If you see this, the test branch loadstring works.",
})
Home:AddButton({
  Title = "Join Discord",
  Callback = function()
    if setclipboard then setclipboard("discord.gg/speedy") end
    SpeedyUI:Notify({ Title = "Speedy", Content = "Discord invite copied!" })
  end,
})

Cars:AddSection("Performance")
Cars:AddToggle({
  Title = "Auto Drive", Description = "Steers the car for you",
  Default = false,
  Callback = function(v) print("AutoDrive:", v) end,
})
Cars:AddSlider({
  Title = "Max Speed", Min = 50, Max = 300, Default = 150,
  Callback = function(v) print("Speed:", v) end,
})
Cars:AddDropdown({
  Title = "Engine", Options = { "Stock", "Sport", "Race" }, Default = "Stock",
  Callback = function(v) print("Engine:", v) end,
})
Cars:AddInput({
  Title = "Waypoint name", Placeholder = "e.g. Dealership",
  Callback = function(text, enter)
    if enter then print("Go to:", text) end
  end,
})

Settings:AddKeybind({
  Title = "Panic key", Default = Enum.KeyCode.F,
  Callback = function() print("Panic! Disable everything") end,
})
Settings:AddButton({
  Title = "Unload UI",
  Callback = function() Window:Destroy() end,
})

SpeedyUI:Notify({ Title = "Speedy Hub", Content = "v2.0 test loaded!", Duration = 4 })
