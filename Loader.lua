--[[ SPEEDY HUB | Loader v3.2 - Bigger cards + hover fix ]]
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
getgenv().SpeedyConfig = { Version = "v3.8", Discord = "discord.gg/speedy" }
getgenv().SpeedyBackend = "https://dashboard-ten-peach-19.vercel.app" -- clean backend, no Loader.lua edits needed

local Games = {
    { Name = "Driving Empire",           GameId = 1202096104, PlaceId = 3357602286,  Thumb = "rbxthumb://type=GameThumbnail&id=3357602286&w=768&h=432" },
    { Name = "Greenville",               GameId = 371263894,  PlaceId = 891852901,   Thumb = "rbxthumb://type=GameThumbnail&id=891852901&w=768&h=432" },
    { Name = "Southwest Florida",        GameId = 1223555379, PlaceId = 1948063469,  Thumb = "rbxthumb://type=GameThumbnail&id=1948063469&w=768&h=432" },
    { Name = "Ultimate Driving",         GameId = 5370313807, PlaceId = 5481977539,  Thumb = "rbxthumb://type=GameThumbnail&id=5481977539&w=768&h=432" },
    { Name = "Vehicle Simulator",        GameId = 128894195,  PlaceId = 1713919481,  Thumb = "rbxthumb://type=GameThumbnail&id=1713919481&w=768&h=432" },
    { Name = "Pacifico 2",               GameId = 8710553023, PlaceId = 8710555530,  Thumb = "rbxthumb://type=GameThumbnail&id=8710555530&w=768&h=432" },
    { Name = "Midnight Racing: Tokyo",   GameId = 142823291,  PlaceId = 8668473321,  Thumb = "rbxthumb://type=GameThumbnail&id=8668473321&w=768&h=432" },
    { Name = "Car Crushers 2",           GameId = 654732683,  PlaceId = 654732683,   Thumb = "rbxthumb://type=GameThumbnail&id=654732683&w=768&h=432" },
    { Name = "Vehicle Legends",          GameId = 1480782352, PlaceId = 4566572536,  Thumb = "rbxthumb://type=GameThumbnail&id=4566572536&w=768&h=432" },
    { Name = "ER:LC",                    GameId = 2534724415, PlaceId = 2534724715,  Thumb = "rbxthumb://type=GameThumbnail&id=2534724715&w=768&h=432" },
    { Name = "Taxi Boss",                GameId = 1047336831, PlaceId = 6690848885,  Thumb = "rbxthumb://type=GameThumbnail&id=6690848885&w=768&h=432" },
    { Name = "Drift Paradise",           GameId = 13322300479,PlaceId = 13322300479, Thumb = "rbxthumb://type=GameThumbnail&id=13322300479&w=768&h=432" },
    { Name = "Car Dealership Tycoon",    GameId = 605887098,  PlaceId = 1554960397,  Thumb = "rbxthumb://type=GameThumbnail&id=1554960397&w=768&h=432" },
    { Name = "Jailbreak",                GameId = 606849621,  PlaceId = 606849621,   Thumb = "rbxthumb://type=GameThumbnail&id=606849621&w=768&h=432" },
    { Name = "A Dusty Trip",             GameId = 5650396773, PlaceId = 16389395869, Thumb = "rbxthumb://type=GameThumbnail&id=16389395869&w=768&h=432" },
    { Name = "Driving Simulator",        GameId = 4646475446, PlaceId = 4727715908,  Thumb = "rbxthumb://type=GameThumbnail&id=4727715908&w=768&h=432" },
    { Name = "Automotive Tycoon",        GameId = 3108293283, PlaceId = 3286570058,  Thumb = "rbxthumb://type=GameThumbnail&id=3286570058&w=768&h=432" },
    { Name = "Moto Trackday Project",    GameId = 10570812351,PlaceId = 10570812351, Thumb = "rbxthumb://type=GameThumbnail&id=10570812351&w=768&h=432" },
    { Name = "Motorcycle Mayhem",        GameId = 891380602,  PlaceId = 891380733,   Thumb = "rbxthumb://type=GameThumbnail&id=891380733&w=768&h=432" },
    { Name = "Car Factory Tycoon",       GameId = 2167018139, PlaceId = 2167018139,  Thumb = "rbxthumb://type=GameThumbnail&id=2167018139&w=768&h=432" },
}
local currentGameId = game.GameId
local currentPlaceId = game.PlaceId
if PlayerGui:FindFirstChild("SpeedyLoader") then PlayerGui.SpeedyLoader:Destroy() end
for _,v in ipairs(Lighting:GetChildren()) do if v.Name=="SpeedyBlur" then v:Destroy() end end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedyLoader"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Blur = Instance.new("BlurEffect")
Blur.Name = "SpeedyBlur"
Blur.Size = 0
Blur.Parent = Lighting
TweenService:Create(Blur, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Size = 24}):Play()

local Dim = Instance.new("Frame", ScreenGui)
Dim.Size = UDim2.fromScale(1,1)
Dim.BackgroundColor3 = Color3.fromRGB(6,8,12)
Dim.BackgroundTransparency = 1
Dim.BorderSizePixel = 0
TweenService:Create(Dim, TweenInfo.new(0.7), {BackgroundTransparency = 0.32}):Play()

-- PHASE 1
local Phase1 = Instance.new("CanvasGroup", ScreenGui)
Phase1.AnchorPoint = Vector2.new(0.5,0.5)
Phase1.Position = UDim2.fromScale(0.5,0.5)
Phase1.Size = UDim2.fromOffset(600, 280)
Phase1.BackgroundTransparency = 1
local LogoFrame = Instance.new("Frame", Phase1)
LogoFrame.AnchorPoint = Vector2.new(0.5,0)
LogoFrame.Position = UDim2.fromScale(0.5, 0.08)
LogoFrame.Size = UDim2.fromOffset(520, 140)
LogoFrame.BackgroundTransparency = 1
local Bars = Instance.new("Frame", LogoFrame)
Bars.Size = UDim2.fromOffset(130, 90)
Bars.Position = UDim2.fromOffset(-6, 26)
Bars.BackgroundTransparency = 1
local barFrames={}
for i=0,2 do local b=Instance.new("Frame", Bars) b.Size=UDim2.fromOffset(54,90) b.Position=UDim2.fromOffset(i*36,0) b.BackgroundColor3=Color3.fromRGB(255,26,26) b.BorderSizePixel=0 b.Rotation=-18 Instance.new("UICorner",b).CornerRadius=UDim.new(0,6) b.BackgroundTransparency=1 b.Size=UDim2.fromOffset(54,0) b.Position=UDim2.fromOffset(i*36,45) b.Rotation=-28 table.insert(barFrames,b) end
-- cool stagger animation for the 3 logo bars - LONGER
task.spawn(function()
    for idx,b in ipairs(barFrames) do
        b.BackgroundTransparency=1
        TweenService:Create(b, TweenInfo.new(0.88, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.fromOffset(54,90), Position=UDim2.fromOffset((idx-1)*36,0), BackgroundTransparency=0, Rotation=-18}):Play()
        task.wait(0.18)
        TweenService:Create(b, TweenInfo.new(0.26, Enum.EasingStyle.Sine), {Rotation=-16}):Play() task.wait(0.12) TweenService:Create(b, TweenInfo.new(0.26), {Rotation=-18}):Play()
    end
    task.wait(0.12)
    for _,b in ipairs(barFrames) do TweenService:Create(b, TweenInfo.new(0.38, Enum.EasingStyle.Quad), {BackgroundColor3=Color3.fromRGB(255,62,62)}):Play() end task.wait(0.22)
    for _,b in ipairs(barFrames) do TweenService:Create(b, TweenInfo.new(0.38), {BackgroundColor3=Color3.fromRGB(255,26,26)}):Play() end
end)
local SpeedyLabel = Instance.new("TextLabel", LogoFrame) SpeedyLabel.Position=UDim2.fromOffset(148,8) SpeedyLabel.Size=UDim2.fromOffset(360,92) SpeedyLabel.BackgroundTransparency=1 SpeedyLabel.Text="SPEEDY" SpeedyLabel.Font=Enum.Font.GothamBlack SpeedyLabel.TextSize=78 SpeedyLabel.TextColor3=Color3.new(1,1,1) SpeedyLabel.TextXAlignment=Enum.TextXAlignment.Left SpeedyLabel.TextTransparency=1 SpeedyLabel.Position=UDim2.fromOffset(148,18)
local Shadow = Instance.new("TextLabel", LogoFrame) Shadow.Position=UDim2.fromOffset(151,11) Shadow.Size=UDim2.fromOffset(360,92) Shadow.BackgroundTransparency=1 Shadow.Text="SPEEDY" Shadow.Font=Enum.Font.GothamBlack Shadow.TextSize=78 Shadow.TextColor3=Color3.fromRGB(255,26,26) Shadow.TextTransparency=1 Shadow.ZIndex=0 Shadow.TextXAlignment=Enum.TextXAlignment.Left
local HubLabel = Instance.new("TextLabel", LogoFrame) HubLabel.Position=UDim2.fromOffset(150,96) HubLabel.Size=UDim2.fromOffset(360,22) HubLabel.BackgroundTransparency=1 HubLabel.Text="H U B  —  CAR & MOTO COLLECTION" HubLabel.Font=Enum.Font.GothamMedium HubLabel.TextSize=13 HubLabel.TextColor3=Color3.new(1,1,1) HubLabel.TextTransparency=1 HubLabel.TextXAlignment=Enum.TextXAlignment.Left
task.spawn(function() task.wait(0.72) TweenService:Create(SpeedyLabel, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextTransparency=0, Position=UDim2.fromOffset(148,8)}):Play() TweenService:Create(Shadow, TweenInfo.new(0.75), {TextTransparency=0.85}):Play() task.wait(0.18) TweenService:Create(HubLabel, TweenInfo.new(0.62, Enum.EasingStyle.Quad), {TextTransparency=0.38}):Play() end)
local BarBG = Instance.new("Frame", Phase1) BarBG.AnchorPoint=Vector2.new(0.5,0) BarBG.Position=UDim2.fromScale(0.5,0.68) BarBG.Size=UDim2.fromOffset(380,7) BarBG.BackgroundColor3=Color3.fromRGB(255,255,255) BarBG.BackgroundTransparency=0.85 BarBG.BorderSizePixel=0 Instance.new("UICorner",BarBG).CornerRadius=UDim.new(1,0)
local Bar = Instance.new("Frame", BarBG) Bar.Size=UDim2.fromScale(0,1) Bar.BackgroundColor3=Color3.fromRGB(255,26,26) Bar.BorderSizePixel=0 Instance.new("UICorner",Bar).CornerRadius=UDim.new(1,0) local BG=Instance.new("UIGradient",Bar) BG.Color=ColorSequence.new(Color3.fromRGB(255,26,26),Color3.fromRGB(255,92,26))
local LoadingLabel = Instance.new("TextLabel", Phase1) LoadingLabel.AnchorPoint=Vector2.new(0.5,0) LoadingLabel.Position=UDim2.fromScale(0.5,0.78) LoadingLabel.Size=UDim2.fromOffset(380,18) LoadingLabel.BackgroundTransparency=1 LoadingLabel.Text="LOADING  •  0%" LoadingLabel.Font=Enum.Font.GothamBold LoadingLabel.TextSize=11 LoadingLabel.TextColor3=Color3.new(1,1,1) LoadingLabel.TextTransparency=0.4
local VersionLabel = Instance.new("TextLabel", Phase1) VersionLabel.AnchorPoint=Vector2.new(0.5,0) VersionLabel.Position=UDim2.fromScale(0.5,0.88) VersionLabel.Size=UDim2.fromOffset(380,14) VersionLabel.BackgroundTransparency=1 VersionLabel.Text="v3.8  •  discord.gg/speedy" VersionLabel.Font=Enum.Font.Gotham VersionLabel.TextSize=10 VersionLabel.TextColor3=Color3.new(1,1,1) VersionLabel.TextTransparency=0.65
Phase1.GroupTransparency=1 LogoFrame.Position=UDim2.fromScale(0.5,0.12)
TweenService:Create(Phase1,TweenInfo.new(0.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{GroupTransparency=0}):Play()
TweenService:Create(LogoFrame,TweenInfo.new(0.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0.5,0.08)}):Play()

-- PHASE 2
local Phase2 = Instance.new("CanvasGroup", ScreenGui)
Phase2.AnchorPoint=Vector2.new(0.5,0.5) Phase2.Position=UDim2.fromScale(0.5,0.5) Phase2.Size=UDim2.fromOffset(940, 680) Phase2.BackgroundTransparency=1 Phase2.GroupTransparency=1 Phase2.Visible=false
local MainBox = Instance.new("Frame", Phase2)
MainBox.Size=UDim2.fromScale(1,1) MainBox.BackgroundColor3=Color3.fromRGB(26,26,30) MainBox.BackgroundTransparency=0.55 MainBox.BorderSizePixel=0 MainBox.ZIndex=1 Instance.new("UICorner",MainBox).CornerRadius=UDim.new(0,28)
local Stroke=Instance.new("UIStroke",MainBox) Stroke.Color=Color3.fromRGB(255,255,255) Stroke.Transparency=0.88 Stroke.Thickness=1.2
local Grad=Instance.new("UIGradient",MainBox) Grad.Color=ColorSequence.new(Color3.fromRGB(40,40,46),Color3.fromRGB(18,18,22)) Grad.Rotation=90 Grad.Transparency=NumberSequence.new(0.1,0.1)
local Header=Instance.new("Frame",MainBox) Header.Size=UDim2.new(1,-48,0,52) Header.Position=UDim2.fromOffset(28,20) Header.BackgroundTransparency=1 Header.ZIndex=2
local Controls=Instance.new("Frame",Header) Controls.Size=UDim2.fromOffset(68,16) Controls.Position=UDim2.fromOffset(0,12) Controls.BackgroundTransparency=1 local L=Instance.new("UIListLayout",Controls) L.FillDirection=Enum.FillDirection.Horizontal L.Padding=UDim.new(0,9)
local function dot(color,sym,act) local d=Instance.new("TextButton",Controls) d.Size=UDim2.fromOffset(15,15) d.BackgroundColor3=color d.Text="" d.AutoButtonColor=false Instance.new("UICorner",d).CornerRadius=UDim.new(1,0) local s=Instance.new("UIStroke",d) s.Color=Color3.fromRGB(0,0,0) s.Transparency=0.85 local t=Instance.new("TextLabel",d) t.Size=UDim2.fromScale(1,1) t.BackgroundTransparency=1 t.Text=sym t.Font=Enum.Font.GothamBold t.TextSize=9 t.TextColor3=Color3.fromRGB(60,0,0) t.TextTransparency=1 d.MouseEnter:Connect(function() TweenService:Create(t,TweenInfo.new(0.12),{TextTransparency=0.15}):Play() end) d.MouseLeave:Connect(function() TweenService:Create(t,TweenInfo.new(0.12),{TextTransparency=1}):Play() end) if act then d.MouseButton1Click:Connect(act) end return d end
local HC=Instance.new("Frame",Header) HC.AnchorPoint=Vector2.new(0.5,0) HC.Position=UDim2.fromScale(0.5,0) HC.Size=UDim2.fromOffset(360,34) HC.BackgroundTransparency=1 HC.ZIndex=2
local HT=Instance.new("TextLabel",HC) HT.Size=UDim2.new(1,0,0,18) HT.BackgroundTransparency=1 HT.Text="SPEEDY HUB" HT.Font=Enum.Font.GothamBlack HT.TextSize=18 HT.TextColor3=Color3.new(1,1,1) HT.TextXAlignment=Enum.TextXAlignment.Center
local HS=Instance.new("TextLabel",HC) HS.Position=UDim2.fromOffset(0,20) HS.Size=UDim2.new(1,0,0,12) HS.BackgroundTransparency=1 HS.Text="CAR & MOTO  •  20 GAMES" HS.Font=Enum.Font.GothamMedium HS.TextSize=11 HS.TextColor3=Color3.new(1,1,1) HS.TextTransparency=0.45 HS.TextXAlignment=Enum.TextXAlignment.Center
local Divider=Instance.new("Frame",MainBox) Divider.Position=UDim2.fromOffset(28,76) Divider.Size=UDim2.new(1,-56,0,1) Divider.BackgroundColor3=Color3.fromRGB(255,255,255) Divider.BackgroundTransparency=0.92 Divider.ZIndex=2
local Scroll=Instance.new("ScrollingFrame",MainBox) Scroll.Position=UDim2.fromOffset(28,92) Scroll.Size=UDim2.new(1,-56,1,-110) Scroll.BackgroundTransparency=1 Scroll.BorderSizePixel=0 Scroll.ScrollBarThickness=3 Scroll.ScrollBarImageTransparency=0.6 Scroll.CanvasSize=UDim2.fromOffset(0,0) Scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y Scroll.ZIndex=2
local Grid=Instance.new("UIGridLayout",Scroll) Grid.CellSize=UDim2.fromOffset(205, 150) Grid.CellPadding=UDim2.fromOffset(16,16) Grid.FillDirectionMaxCells=4 Grid.HorizontalAlignment=Enum.HorizontalAlignment.Center
local Pad=Instance.new("UIPadding",Scroll) Pad.PaddingTop=UDim.new(0,10) Pad.PaddingBottom=UDim.new(0,12)

local function createCard(data,i)
    local isCurrent=(data.GameId==currentGameId)or(data.PlaceId==currentPlaceId)
    -- Card container is a Frame, with a TextButton that captures hover/click (more reliable than TextButton background)
    local Card = Instance.new("Frame", Scroll)
    Card.Name=data.Name
    Card.LayoutOrder=i
    Card.Size=UDim2.fromOffset(205,150)
    Card.BackgroundColor3=Color3.fromRGB(18,18,20)
    Card.BackgroundTransparency=0.06
    Card.BorderSizePixel=0
    Card.ClipsDescendants=true
    Card.ZIndex=3
    Instance.new("UICorner",Card).CornerRadius=UDim.new(0,20)
    local CardStroke=Instance.new("UIStroke",Card) CardStroke.Color=isCurrent and Color3.fromRGB(255,26,26) or Color3.fromRGB(255,255,255) CardStroke.Transparency=isCurrent and 0.32 or 0.86 CardStroke.Thickness=isCurrent and 2 or 1.2
    local Img=Instance.new("ImageLabel",Card) Img.Size=UDim2.fromScale(1,1) Img.BackgroundTransparency=1 Img.Image=data.Thumb Img.ScaleType=Enum.ScaleType.Crop Img.ZIndex=3 Instance.new("UICorner",Img).CornerRadius=UDim.new(0,20)
    -- overlay - ALWAYS VISIBLE, title shows without hover, brighter on hover
    local Overlay=Instance.new("Frame",Card) Overlay.Size=UDim2.new(1,0,0.56) Overlay.Position=UDim2.new(0,0,1,-0.56) Overlay.BackgroundColor3=Color3.fromRGB(0,0,0) Overlay.BorderSizePixel=0 Overlay.ZIndex=4 Instance.new("UICorner",Overlay).CornerRadius=UDim.new(0,20)
    local OverGrad=Instance.new("UIGradient",Overlay) OverGrad.Color=ColorSequence.new(Color3.fromRGB(0,0,0),Color3.fromRGB(0,0,0)) OverGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.15,0.5),NumberSequenceKeypoint.new(1,0.14)}) OverGrad.Rotation=90
    local Fix=Instance.new("Frame",Overlay) Fix.Size=UDim2.new(1,0,0,16) Fix.Position=UDim2.new(0,0,1,-8) Fix.BackgroundColor3=Color3.fromRGB(0,0,0) Fix.BorderSizePixel=0 Fix.ZIndex=3
    local Title=Instance.new("TextLabel",Card) Title.Size=UDim2.new(1,-16,0,30) Title.Position=UDim2.new(0,8,1,-42) Title.AnchorPoint=Vector2.new(0,0) Title.BackgroundTransparency=1 Title.Text=data.Name Title.Font=Enum.Font.GothamBold Title.TextSize=13 Title.TextColor3=Color3.new(1,1,1) Title.TextWrapped=true Title.TextYAlignment=Enum.TextYAlignment.Bottom Title.TextXAlignment=Enum.TextXAlignment.Center Title.ZIndex=6
    local Tag=Instance.new("TextLabel",Card) Tag.Size=UDim2.new(1,-16,0,10) Tag.Position=UDim2.new(0,8,1,-14) Tag.BackgroundTransparency=1 Tag.Text="TAP TO LOAD" Tag.Font=Enum.Font.GothamMedium Tag.TextSize=8 Tag.TextColor3=Color3.new(1,1,1) Tag.TextXAlignment=Enum.TextXAlignment.Center Tag.ZIndex=6
    -- hover-only: titles hidden until hover
    Title.TextTransparency=1
    Tag.TextTransparency=1
    Overlay.BackgroundTransparency=1
    Fix.BackgroundTransparency=1
    -- blur dim layer (darkens + blurs thumb on hover so title pops)
    local BlurDim=Instance.new("Frame",Card) BlurDim.Size=UDim2.fromScale(1,1) BlurDim.BackgroundColor3=Color3.fromRGB(10,10,12) BlurDim.BackgroundTransparency=1 BlurDim.BorderSizePixel=0 BlurDim.ZIndex=4 Instance.new("UICorner",BlurDim).CornerRadius=UDim.new(0,20)

    if isCurrent then local B=Instance.new("TextLabel",Card) B.Position=UDim2.fromOffset(8,8) B.Size=UDim2.fromOffset(68,16) B.BackgroundColor3=Color3.fromRGB(255,26,26) B.Text="• PLAYING" B.Font=Enum.Font.GothamBold B.TextSize=8 B.TextColor3=Color3.new(1,1,1) B.ZIndex=5 Instance.new("UICorner",B).CornerRadius=UDim.new(1,0) end

    local Hit=Instance.new("TextButton",Card) Hit.Size=UDim2.fromScale(1,1) Hit.BackgroundTransparency=1 Hit.Text="" Hit.ZIndex=7 Hit.AutoButtonColor=false

    -- entrance - even longer cascade
    Img.ImageTransparency=1
    Card.BackgroundTransparency=1
    CardStroke.Transparency=1
    Card.Size=UDim2.fromOffset(188,136)
    Card.Rotation=0.8
    task.delay(i*0.11, function()
        TweenService:Create(Card,TweenInfo.new(0.85,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(205,150), BackgroundTransparency=0.06, Rotation=0}):Play()
        TweenService:Create(Img,TweenInfo.new(0.85,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageTransparency=0}):Play()
        TweenService:Create(CardStroke,TweenInfo.new(0.85),{Transparency=isCurrent and 0.32 or 0.86}):Play()
    end)

    local hovering=false
    local function show()
        if hovering then return end hovering=true
        TweenService:Create(BlurDim,TweenInfo.new(0.24,Enum.EasingStyle.Quad),{BackgroundTransparency=0.38}):Play()
        TweenService:Create(Overlay,TweenInfo.new(0.24,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0.06}):Play()
        TweenService:Create(Fix,TweenInfo.new(0.24),{BackgroundTransparency=0.06}):Play()
        TweenService:Create(Title,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextTransparency=0, TextSize=14}):Play()
        TweenService:Create(Tag,TweenInfo.new(0.24),{TextTransparency=0.12}):Play()
        TweenService:Create(Card,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(212,157)}):Play()
        TweenService:Create(CardStroke,TweenInfo.new(0.22),{Transparency=0.16}):Play()
        TweenService:Create(Img,TweenInfo.new(0.24),{ImageColor3=Color3.fromRGB(170,170,175)}):Play()
    end
    local function hide()
        hovering=false
        TweenService:Create(BlurDim,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{BackgroundTransparency=1}):Play()
        TweenService:Create(Overlay,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
        TweenService:Create(Fix,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
        TweenService:Create(Title,TweenInfo.new(0.22),{TextTransparency=1, TextSize=13}):Play()
        TweenService:Create(Tag,TweenInfo.new(0.22),{TextTransparency=1}):Play()
        TweenService:Create(Card,TweenInfo.new(0.28,Enum.EasingStyle.Quad),{Size=UDim2.fromOffset(205,150)}):Play()
        TweenService:Create(CardStroke,TweenInfo.new(0.28),{Transparency=isCurrent and 0.32 or 0.86}):Play()
        TweenService:Create(Img,TweenInfo.new(0.28),{ImageColor3=Color3.fromRGB(255,255,255)}):Play()
    end
    Hit.MouseEnter:Connect(show)
    Hit.MouseLeave:Connect(hide)
    Hit.MouseButton1Click:Connect(function()
        TweenService:Create(Card,TweenInfo.new(0.1,Enum.EasingStyle.Quad),{Size=UDim2.fromOffset(198,143)}):Play()
        TweenService:Create(Img,TweenInfo.new(0.18),{ImageColor3=Color3.fromRGB(170,170,170)}):Play()
        task.wait(0.12)
        TweenService:Create(Phase2,TweenInfo.new(0.42,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{GroupTransparency=1}):Play()
        TweenService:Create(MainBox,TweenInfo.new(0.42,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.fromOffset(880,620)}):Play()
        TweenService:Create(Dim,TweenInfo.new(0.42),{BackgroundTransparency=1}):Play()
        TweenService:Create(Blur,TweenInfo.new(0.42),{Size=0}):Play()
        task.wait(0.42)
        Phase2.Visible=false ScreenGui:Destroy() Blur:Destroy()
        -- backend: log execution + fetch script (you never touch Loader.lua)
        local backend = getgenv().SpeedyBackend or "https://dashboard-ten-peach-19.vercel.app"
        local HttpService = game:GetService("HttpService")
        local plr = game.Players.LocalPlayer
        -- log execution (fire and forget)
        pcall(function()
            local body = HttpService:JSONEncode({ universeId=tostring(data.GameId), placeId=tostring(data.PlaceId), userId=tostring(plr.UserId), username=plr.Name })
            local req = (syn and syn.request) or (http and http.request) or request
            if req then
                req({ Url=backend.."/api/executions", Method="POST", Headers={["Content-Type"]="application/json"}, Body=body })
            else
                -- fallback: HttpService can't POST easily, use HttpGet via log pixel
                pcall(function() game:HttpGet(backend.."/api/executions?universeId="..data.GameId.."&placeId="..data.PlaceId.."&userId="..plr.UserId) end)
            end
        end)
        -- fetch & run script for this game
        local fetched=false
        pcall(function()
            local url = backend.."/api/scripts?universeId="..tostring(data.GameId)
            local res = game:HttpGet(url)
            local dataJ = HttpService:JSONDecode(res)
            if dataJ and dataJ.code and #dataJ.code>10 then
                fetched=true
                pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Speedy Hub", Text="Loaded "..data.Name.." v"..(dataJ.version or "?"), Duration=3}) end)
                loadstring(dataJ.code)()
            end
        end)
        if not fetched then
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Speedy Hub",Text="No script yet for "..data.Name.." — add in dashboard /scripts",Duration=4}) end)
            print("[Speedy] No backend script for "..data.Name.." ("..data.GameId..") — add at "..backend.."/scripts?game="..data.Name)
        end
    end)
    return Card
end
for i,g in ipairs(Games) do createCard(g,i) end

local RedDot, YellowDot, GreenDot
RedDot=dot(Color3.fromRGB(255,95,87),"✕",function() TweenService:Create(Phase2,TweenInfo.new(0.28),{GroupTransparency=1}):Play() TweenService:Create(Blur,TweenInfo.new(0.28),{Size=0}):Play() TweenService:Create(Dim,TweenInfo.new(0.28),{BackgroundTransparency=1}):Play() task.wait(0.28) ScreenGui:Destroy() Blur:Destroy() end)
YellowDot=dot(Color3.fromRGB(255,189,46),"—",function() TweenService:Create(Phase2,TweenInfo.new(0.3),{GroupTransparency=1,Position=UDim2.fromScale(0.5,0.44)}):Play() task.wait(0.3) Phase2.Visible=false TweenService:Create(Blur,TweenInfo.new(0.3),{Size=6}):Play() end)
GreenDot=dot(Color3.fromRGB(40,200,64),"⤢",function() local b=Phase2.Size.X.Offset==880 TweenService:Create(Phase2,TweenInfo.new(0.4,Enum.EasingStyle.Back),{Size=b and UDim2.fromOffset(980,680) or UDim2.fromOffset(880,620)}):Play() end)

task.spawn(function() local d=2.6 for i=0,100 do Bar.Size=UDim2.fromScale(i/100,1) LoadingLabel.Text=string.format("LOADING  •  %d%%",i) if i==30 then LoadingLabel.Text="LOADING ASSETS  •  30%" end if i==68 then LoadingLabel.Text="PREPARING GARAGE  •  68%" end if i==92 then LoadingLabel.Text="READY  •  92%" end task.wait(d/100) end LoadingLabel.Text="READY  •  100%" task.wait(0.32) TweenService:Create(Phase1,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{GroupTransparency=1}):Play() task.wait(0.38) Phase1.Visible=false Phase2.Visible=true Phase2.GroupTransparency=1 MainBox.Size=UDim2.fromOffset(900,640) TweenService:Create(Phase2,TweenInfo.new(0.68,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{GroupTransparency=0}):Play() TweenService:Create(MainBox,TweenInfo.new(0.68,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromScale(1,1)}):Play() TweenService:Create(Dim,TweenInfo.new(0.45),{BackgroundTransparency=0.30}):Play() end)
game:GetService("UserInputService").InputBegan:Connect(function(inp,gp) if gp then return end if inp.KeyCode==Enum.KeyCode.Escape then if Phase2.Visible and Phase2.GroupTransparency<0.5 then RedDot:Activate() else TweenService:Create(Phase1,TweenInfo.new(0.3),{GroupTransparency=1}):Play() TweenService:Create(Blur,TweenInfo.new(0.3),{Size=0}):Play() TweenService:Create(Dim,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play() task.wait(0.3) ScreenGui:Destroy() Blur:Destroy() end end end)
print("[Speedy v3.2] Bigger cards 200x145 • hover titles fixed via Hit button")
