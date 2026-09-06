-- Speedy Hub | Main.lua (Template)
-- This is loaded by Loader.lua after game detection
-- Put your per-game scripts here. Loader passes gameName & isSupported

local SupportedGames = {
    ["Driving Empire"] = { Script = "https://raw.githubusercontent.com/.../DrivingEmpire.lua" },
    ["Greenville"] = { Script = "https://raw.githubusercontent.com/.../Greenville.lua" },
    -- add your 20 games here
}

-- Example Hub UI using Fluent (https://github.com/dawid-scripts/Fluent)
-- Replace with your preferred library: Fluent / WindUI / Rayfield

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Speedy Hub " .. (getgenv().SpeedyConfig and getgenv().SpeedyConfig.Version or "v1.0.0"),
    SubTitle = "Car & Motorcycle Collection • 20 Games",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "home" }),
    Cars = Window:AddTab({ Title = "Cars", Icon = "car" }),
    Moto = Window:AddTab({ Title = "Motorcycles", Icon = "bike" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Window:SelectTab(1)

Tabs.Home:AddParagraph({
    Title = "🏁 Welcome to Speedy",
    Content = "Supports 20 games — mostly cars & motorcycles.\nDetected: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
})

Tabs.Home:AddButton({
    Title = "Join Discord",
    Description = "Copy invite",
    Callback = function()
        if setclipboard then setclipboard("discord.gg/xJgtyW9z3j") end
        Fluent:Notify({ Title = "Speedy", Content = "Discord copied!", Duration = 3 })
    end
})

-- Example per-game loader logic
local currentName = "Unknown"
pcall(function() currentName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)

if SupportedGames[currentName] then
    Tabs.Home:AddParagraph({ Title = "✓ Supported Game", Content = currentName .. " features loaded below." })
else
    Tabs.Home:AddParagraph({ Title = "Universal", Content = "No specific script for this game — showing universal car/moto tools." })
end

-- Add your universal sections here
Tabs.Cars:AddToggle("SpeedToggle", { Title = "Auto Speed", Default = false, Callback = function(v) print("Speed", v) end })
Tabs.Moto:AddSlider("MotoSpeed", { Title = "Bike Speed Multiplier", Default = 1, Min = 1, Max = 5, Rounding = 1, Callback = function(v) end })

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("SpeedyHub")
SaveManager:SetFolder("SpeedyHub/speed")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Fluent:Notify({ Title = "Speedy Hub", Content = "Loaded! Enjoy 🏁", Duration = 4 })
