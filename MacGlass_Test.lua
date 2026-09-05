--[[ MACGLASS | TEST — loads MacGlass.lua from the `test` branch.
   Test version only. Production (SpeedyUI.lua on master) is untouched. ]]
local UI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/xyraopsec/speedy-hub/test/MacGlass.lua?v=1.0"
))()

local Window = UI:CreateWindow({ ToggleKey = Enum.KeyCode.RightShift })

Window:AddSection("Main")
local Components = Window:AddTab("Components")
Window:AddSection("Settings")
local Settings = Window:AddTab("Edit", "✎")

Components:AddSection("Non Interactable")
Components:AddParagraph({
  Title = "Paragraph",
  Content = "insert any important text here.",
})

Components:AddSection("Interactable")
Components:AddButton({
  Title = "Button", Description = "clicking",
  Callback = function() print("Button clicked") end,
})
Components:AddSlider({
  Title = "Slider", Description = "sliding",
  Min = 0, Max = 100, Default = 55,
  Callback = function(v) print("Slider:", v) end,
})
Components:AddToggle({
  Title = "Toggle", Description = "switchy",
  Default = false,
  Callback = function(v) print("Toggle:", v) end,
})
Components:AddInput({
  Title = "Input", Description = "insert",
  Placeholder = "insert",
  Callback = function(text, enter)
    if enter then print("Input:", text) end
  end,
})

Settings:AddSection("Keybinds")
Settings:AddKeybind({
  Title = "Panic key", Default = Enum.KeyCode.F,
  Callback = function() print("Panic! Disable everything") end,
})
Settings:AddSection("Session")
Settings:AddButton({
  Title = "Unload UI",
  Callback = function() Window:Destroy() end,
})

UI:Notify({ Title = "MacGlass", Content = "v1.0 test loaded!", Duration = 4 })
