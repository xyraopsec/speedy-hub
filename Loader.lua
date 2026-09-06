--[[ SPEEDY HUB | Loader v4.0 - Backend-driven game list + Key System ]]
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
getgenv().SpeedyConfig = { Version = "v4.0", Discord = "https://discord.gg/q5En862zuM" }
getgenv().SpeedyBackend = "https://dashboard-ten-peach-19.vercel.app"

local currentGameId = game.GameId
local currentPlaceId = game.PlaceId
local backend = getgenv().SpeedyBackend

-- HWID detection for machine binding (safe across executors)
local function getHWID()
    local id = nil
    pcall(function()
        if gethwid then id = gethwid()
        elseif getexecutorhwid then id = getexecutorhwid()
        elseif identifyexecutor then
            local name = identifyexecutor()
            id = game:GetService("RbxAnalyticsService"):GetClientId() .. "_" .. tostring(name)
        else
            id = game:GetService("RbxAnalyticsService"):GetClientId()
        end
    end)
    return id or ("FALLBACK_" .. tostring(LocalPlayer.UserId))
end

-- Key storage (file-based persistence so users don't re-enter keys every launch)
local KEY_FILE = "speedy_hub_key.txt"
local function loadSavedKey()
    local key = nil
    pcall(function()
        if readfile and isfile and isfile(KEY_FILE) then
            key = readfile(KEY_FILE)
            if key then key = string.gsub(key, "%s+", "") end
        end
    end)
    return (key and #key > 0) and key or nil
end

local function saveKey(key)
    pcall(function()
        if writefile then
            writefile(KEY_FILE, tostring(key))
        end
    end)
end

-- Validate key against backend (checks expiry, hwid binding, executions)
local function checkKey(keyStr)
    if not keyStr or #keyStr == 0 then return false, "No key provided" end
    local cleanKey = string.gsub(keyStr, "%s+", "")
    local hwid = getHWID()
    local payload = HttpService:JSONEncode({ key = cleanKey, hwid = hwid })
    local success, response = pcall(function()
        local req = (syn and syn.request) or (http and http.request) or request
        if req then
            local res = req({
                Url = backend .. "/api/keys/validate",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload,
            })
            return HttpService:JSONDecode(res.Body)
        else
            -- Fallback if executor lacks POST request support
            return { ok = true, keyId = "compat" }
        end
    end)
    if success and response and response.ok then
        saveKey(cleanKey)
        getgenv().SpeedyLicenseKey = cleanKey
        return true, "Success"
    else
        local reason = (response and response.reason) or "Validation failed"
        return false, reason
    end
end

-- Fetch games from backend during loading (with empty fallback)
local Games = {}
local gamesReady = false
task.spawn(function()
    pcall(function()
        local res = game:HttpGet(backend.."/api/games")
        local list = HttpService:JSONDecode(res)
        if list and #list > 0 then
            Games = {}
            for _, g in ipairs(list) do
                table.insert(Games, {
                    Name = g.name,
                    GameId = tonumber(g.universeId) or 0,
                    PlaceId = tonumber(g.placeId) or 0,
                    Thumb = "rbxthumb://type=GameThumbnail&id="..g.placeId.."&w=768&h=432",
                })
            end
        end
    end)
    gamesReady = true
end)

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
local HubLabel = Instance.new("TextLabel", LogoFrame) HubLabel.Position=UDim2.fromOffset(150,96) HubLabel.Size=UDim2.fromOffset(360,22) HubLabel.BackgroundTransparency=1 HubLabel.Text="H U B  —  CAR & MOTO" HubLabel.Font=Enum.Font.GothamMedium HubLabel.TextSize=13 HubLabel.TextColor3=Color3.new(1,1,1) HubLabel.TextTransparency=1 HubLabel.TextXAlignment=Enum.TextXAlignment.Left
task.spawn(function() task.wait(0.72) TweenService:Create(SpeedyLabel, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextTransparency=0, Position=UDim2.fromOffset(148,8)}):Play() TweenService:Create(Shadow, TweenInfo.new(0.75), {TextTransparency=0.85}):Play() task.wait(0.18) TweenService:Create(HubLabel, TweenInfo.new(0.62, Enum.EasingStyle.Quad), {TextTransparency=0.38}):Play() end)
local BarBG = Instance.new("Frame", Phase1) BarBG.AnchorPoint=Vector2.new(0.5,0) BarBG.Position=UDim2.fromScale(0.5,0.68) BarBG.Size=UDim2.fromOffset(380,7) BarBG.BackgroundColor3=Color3.fromRGB(255,255,255) BarBG.BackgroundTransparency=0.85 BarBG.BorderSizePixel=0 Instance.new("UICorner",BarBG).CornerRadius=UDim.new(1,0)
local Bar = Instance.new("Frame", BarBG) Bar.Size=UDim2.fromScale(0,1) Bar.BackgroundColor3=Color3.fromRGB(255,26,26) Bar.BorderSizePixel=0 Instance.new("UICorner",Bar).CornerRadius=UDim.new(1,0) local BG=Instance.new("UIGradient",Bar) BG.Color=ColorSequence.new(Color3.fromRGB(255,26,26),Color3.fromRGB(255,92,26))
local LoadingLabel = Instance.new("TextLabel", Phase1) LoadingLabel.AnchorPoint=Vector2.new(0.5,0) LoadingLabel.Position=UDim2.fromScale(0.5,0.78) LoadingLabel.Size=UDim2.fromOffset(380,18) LoadingLabel.BackgroundTransparency=1 LoadingLabel.Text="LOADING  •  0%" LoadingLabel.Font=Enum.Font.GothamBold LoadingLabel.TextSize=11 LoadingLabel.TextColor3=Color3.new(1,1,1) LoadingLabel.TextTransparency=0.4
local VersionLabel = Instance.new("TextLabel", Phase1) VersionLabel.AnchorPoint=Vector2.new(0.5,0) VersionLabel.Position=UDim2.fromScale(0.5,0.88) VersionLabel.Size=UDim2.fromOffset(380,14) VersionLabel.BackgroundTransparency=1 VersionLabel.Text="v4.0  •  discord.gg/q5En862zuM" VersionLabel.Font=Enum.Font.Gotham VersionLabel.TextSize=10 VersionLabel.TextColor3=Color3.new(1,1,1) VersionLabel.TextTransparency=0.65
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
local HS=Instance.new("TextLabel",HC) HS.Position=UDim2.fromOffset(0,20) HS.Size=UDim2.new(1,0,0,12) HS.BackgroundTransparency=1 HS.Text="CAR & MOTO  •  LOADING..." HS.Font=Enum.Font.GothamMedium HS.TextSize=11 HS.TextColor3=Color3.new(1,1,1) HS.TextTransparency=0.45 HS.TextXAlignment=Enum.TextXAlignment.Center
local Divider=Instance.new("Frame",MainBox) Divider.Position=UDim2.fromOffset(28,76) Divider.Size=UDim2.new(1,-56,0,1) Divider.BackgroundColor3=Color3.fromRGB(255,255,255) Divider.BackgroundTransparency=0.92 Divider.ZIndex=2
local Scroll=Instance.new("ScrollingFrame",MainBox) Scroll.Position=UDim2.fromOffset(28,92) Scroll.Size=UDim2.new(1,-56,1,-110) Scroll.BackgroundTransparency=1 Scroll.BorderSizePixel=0 Scroll.ScrollBarThickness=3 Scroll.ScrollBarImageTransparency=0.6 Scroll.CanvasSize=UDim2.fromOffset(0,0) Scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y Scroll.ZIndex=2
local Grid=Instance.new("UIGridLayout",Scroll) Grid.CellSize=UDim2.fromOffset(205, 150) Grid.CellPadding=UDim2.fromOffset(16,16) Grid.FillDirectionMaxCells=4 Grid.HorizontalAlignment=Enum.HorizontalAlignment.Center
local Pad=Instance.new("UIPadding",Scroll) Pad.PaddingTop=UDim.new(0,10) Pad.PaddingBottom=UDim.new(0,12)
-- Credits footer (compact, no scroll, matches GameTemplate INK 18,20,22)
local Footer = Instance.new("Frame", MainBox)
Footer.Size = UDim2.new(1, -56, 0, 32)
Footer.Position = UDim2.new(0, 28, 1, -40)
Footer.BackgroundColor3 = Color3.fromRGB(18, 20, 22)
Footer.BorderSizePixel = 0
Footer.ZIndex = 2
Instance.new("UICorner", Footer).CornerRadius = UDim.new(0, 8)
local FooterGrad = Instance.new("UIGradient", Footer)
FooterGrad.Color = ColorSequence.new(Color3.fromRGB(28, 28, 32), Color3.fromRGB(18, 20, 22))
FooterGrad.Rotation = 90
local FooterStroke = Instance.new("UIStroke", Footer)
FooterStroke.Color = Color3.fromRGB(255,255,255)
FooterStroke.Transparency = 0.88
FooterStroke.Thickness = 1
local FooterList = Instance.new("UIListLayout", Footer)
FooterList.FillDirection = Enum.FillDirection.Horizontal
FooterList.HorizontalAlignment = Enum.HorizontalAlignment.Center
FooterList.VerticalAlignment = Enum.VerticalAlignment.Center
FooterList.Padding = UDim.new(0, 10)
Instance.new("UIPadding", Footer).PaddingTop = UDim.new(0, 4)
Instance.new("UIPadding", Footer).PaddingBottom = UDim.new(0, 4)
local function footerChip(iconFile, text)
    local chip = Instance.new("Frame", Footer)
    chip.Size = UDim2.new(0, 0, 0, 18)
    chip.AutomaticSize = Enum.AutomaticSize.X
    chip.BackgroundTransparency = 1
    chip.ZIndex = 3
    local l = Instance.new("UIListLayout", chip)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.VerticalAlignment = Enum.VerticalAlignment.Center
    l.Padding = UDim.new(0, 6)
    -- avatar if executor supports getcustomasset
    local avatar
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or request
        if req and writefile and getcustomasset and isfile and iconFile then
            if not isfile("speedy-foot-"..iconFile) then
                local res = req({Url="https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/"..iconFile, Method="GET"})
                if res and res.Body and #res.Body>100 then writefile("speedy-foot-"..iconFile, res.Body) end
            end
            avatar = getcustomasset("speedy-foot-"..iconFile)
        end
    end)
    if avatar then
        local img = Instance.new("ImageLabel", chip)
        img.Size = UDim2.fromOffset(16,16)
        img.BackgroundTransparency = 1
        img.Image = avatar
        img.BorderSizePixel = 0
        Instance.new("UICorner", img).CornerRadius = UDim.new(1,0)
    end
    local lbl = Instance.new("TextLabel", chip)
    lbl.Size = UDim2.new(0, 0, 0, 14)
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(210,210,220)
    return chip
end
footerChip("xyrapfp.png", "Script: @xyra")
footerChip("luahook.png", "UI: yes! (luahook)")
footerChip("raikou.png", "Infra: Raikou")
footerChip("chinese.png", "Beta: カメルツ [PL/EN]")

local function createCard(data,i)
    local isCurrent=(data.GameId==currentGameId)or(data.PlaceId==currentPlaceId)
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
    local Overlay=Instance.new("Frame",Card) Overlay.Size=UDim2.new(1,0,0.56) Overlay.Position=UDim2.new(0,0,1,-0.56) Overlay.BackgroundColor3=Color3.fromRGB(0,0,0) Overlay.BorderSizePixel=0 Overlay.ZIndex=4 Instance.new("UICorner",Overlay).CornerRadius=UDim.new(0,20)
    local OverGrad=Instance.new("UIGradient",Overlay) OverGrad.Color=ColorSequence.new(Color3.fromRGB(0,0,0),Color3.fromRGB(0,0,0)) OverGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.15,0.5),NumberSequenceKeypoint.new(1,0.14)}) OverGrad.Rotation=90
    local Fix=Instance.new("Frame",Overlay) Fix.Size=UDim2.new(1,0,0,16) Fix.Position=UDim2.new(0,0,1,-8) Fix.BackgroundColor3=Color3.fromRGB(0,0,0) Fix.BorderSizePixel=0 Fix.ZIndex=3
    local Title=Instance.new("TextLabel",Card) Title.Size=UDim2.new(1,-16,0,30) Title.Position=UDim2.new(0,8,1,-42) Title.BackgroundTransparency=1 Title.Text=data.Name Title.Font=Enum.Font.GothamBold Title.TextSize=13 Title.TextColor3=Color3.new(1,1,1) Title.TextWrapped=true Title.TextYAlignment=Enum.TextYAlignment.Bottom Title.TextXAlignment=Enum.TextXAlignment.Center Title.ZIndex=6
    local Tag=Instance.new("TextLabel",Card) Tag.Size=UDim2.new(1,-16,0,10) Tag.Position=UDim2.new(0,8,1,-14) Tag.BackgroundTransparency=1 Tag.Text="TAP TO LOAD" Tag.Font=Enum.Font.GothamMedium Tag.TextSize=8 Tag.TextColor3=Color3.new(1,1,1) Tag.TextXAlignment=Enum.TextXAlignment.Center Tag.ZIndex=6
    Title.TextTransparency=1
    Tag.TextTransparency=1
    Overlay.BackgroundTransparency=1
    Fix.BackgroundTransparency=1
    local BlurDim=Instance.new("Frame",Card) BlurDim.Size=UDim2.fromScale(1,1) BlurDim.BackgroundColor3=Color3.fromRGB(10,10,12) BlurDim.BackgroundTransparency=1 BlurDim.BorderSizePixel=0 BlurDim.ZIndex=4 Instance.new("UICorner",BlurDim).CornerRadius=UDim.new(0,20)

    if isCurrent then local B=Instance.new("TextLabel",Card) B.Position=UDim2.fromOffset(8,8) B.Size=UDim2.fromOffset(68,16) B.BackgroundColor3=Color3.fromRGB(255,26,26) B.Text="• PLAYING" B.Font=Enum.Font.GothamBold B.TextSize=8 B.TextColor3=Color3.new(1,1,1) B.ZIndex=5 Instance.new("UICorner",B).CornerRadius=UDim.new(1,0) end

    local Hit=Instance.new("TextButton",Card) Hit.Size=UDim2.fromScale(1,1) Hit.BackgroundTransparency=1 Hit.Text="" Hit.ZIndex=7 Hit.AutoButtonColor=false

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
        local HttpService2 = game:GetService("HttpService")
        local plr = game.Players.LocalPlayer
        local activeKey = getgenv().SpeedyLicenseKey or loadSavedKey() or ""
        local userHwid = getHWID()

        pcall(function()
            local body = HttpService2:JSONEncode({
                universeId = tostring(data.GameId),
                placeId = tostring(data.PlaceId),
                userId = tostring(plr.UserId),
                username = plr.Name,
                key = activeKey,
            })
            local req = (syn and syn.request) or (http and http.request) or request
            if req then
                req({ Url=backend.."/api/executions", Method="POST", Headers={["Content-Type"]="application/json"}, Body=body })
            else
                pcall(function() game:HttpGet(backend.."/api/executions?universeId="..data.GameId.."&placeId="..data.PlaceId.."&userId="..plr.UserId) end)
            end
        end)

        local fetched=false
        pcall(function()
            local url = backend.."/api/scripts?universeId="..tostring(data.GameId).."&key="..HttpService2:UrlEncode(activeKey).."&hwid="..HttpService2:UrlEncode(userHwid)
            local res = game:HttpGet(url)
            local dataJ = HttpService2:JSONDecode(res)
            if dataJ and dataJ.code and #dataJ.code>10 then
                fetched=true
                pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Speedy Hub", Text="Loaded "..data.Name.." v"..(dataJ.version or "?"), Duration=3}) end)
                loadstring(dataJ.code)()
            elseif dataJ and dataJ.error then
                pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Speedy Hub", Text="Access Denied: " .. tostring(dataJ.error), Duration=5}) end)
            end
        end)
        if not fetched then
            pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Speedy Hub",Text="Failed to load payload for "..data.Name,Duration=4}) end)
            print("[Speedy] No backend script or key invalid for "..data.Name.." ("..data.GameId..")")
        end
    end)
    return Card
end

local RedDot, YellowDot, GreenDot
RedDot=dot(Color3.fromRGB(255,95,87),"✕",function() TweenService:Create(Phase2,TweenInfo.new(0.28),{GroupTransparency=1}):Play() TweenService:Create(Blur,TweenInfo.new(0.28),{Size=0}):Play() TweenService:Create(Dim,TweenInfo.new(0.28),{BackgroundTransparency=1}):Play() task.wait(0.28) ScreenGui:Destroy() Blur:Destroy() end)
YellowDot=dot(Color3.fromRGB(255,189,46),"—",function() TweenService:Create(Phase2,TweenInfo.new(0.3),{GroupTransparency=1,Position=UDim2.fromScale(0.5,0.44)}):Play() task.wait(0.3) Phase2.Visible=false TweenService:Create(Blur,TweenInfo.new(0.3),{Size=6}):Play() end)
GreenDot=dot(Color3.fromRGB(40,200,64),"⤢",function() local b=Phase2.Size.X.Offset==880 TweenService:Create(Phase2,TweenInfo.new(0.4,Enum.EasingStyle.Back),{Size=b and UDim2.fromOffset(980,680) or UDim2.fromOffset(880,620)}):Play() end)

-- Phase 1 loading bar + wait for games fetch
task.spawn(function()
    local d=2.6
    for i=0,100 do
        Bar.Size=UDim2.fromScale(i/100,1)
        LoadingLabel.Text=string.format("LOADING  •  %d%%",i)
        if i==30 then LoadingLabel.Text="LOADING ASSETS  •  30%" end
        if i==68 then LoadingLabel.Text="FETCHING GAMES  •  68%" end
        if i==92 then LoadingLabel.Text="READY  •  92%" end
        task.wait(d/100)
    end
    LoadingLabel.Text="READY  •  100%"
    task.wait(0.32)

    -- Wait for games fetch to complete (up to 3s extra)
    local waitStart = tick()
    while not gamesReady and (tick() - waitStart) < 3 do task.wait(0.1) end

    -- Transition to Key UI or Phase 2
    local saved = loadSavedKey()
    local keyValid = false
    if saved then
        LoadingLabel.Text="VALIDATING KEY..."
        local ok, _ = checkKey(saved)
        keyValid = ok
    end

    TweenService:Create(Phase1,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{GroupTransparency=1}):Play()
    task.wait(0.38)
    Phase1.Visible=false

    local function showPhase2()
        -- Update subtitle with game count
        HS.Text="CAR & MOTO  •  "..#Games.." GAMES"

        -- Populate cards from backend
        if #Games > 0 then
            for i,g in ipairs(Games) do createCard(g,i) end
        else
            local empty = Instance.new("TextLabel", Scroll)
            empty.Size=UDim2.fromOffset(300,60)
            empty.Position=UDim2.fromOffset(0,80)
            empty.AnchorPoint=Vector2.new(0.5,0)
            empty.BackgroundTransparency=1
            empty.Text="No games configured.\nAdd scripts in the dashboard."
            empty.Font=Enum.Font.GothamMedium
            empty.TextSize=13
            empty.TextColor3=Color3.new(1,1,1)
            empty.TextTransparency=0.5
            empty.TextWrapped=true
            empty.TextXAlignment=Enum.TextXAlignment.Center
            empty.ZIndex=4
        end

        Phase2.Visible=true Phase2.GroupTransparency=1 MainBox.Size=UDim2.fromOffset(900,640)
        TweenService:Create(Phase2,TweenInfo.new(0.68,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{GroupTransparency=0}):Play()
        TweenService:Create(MainBox,TweenInfo.new(0.68,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromScale(1,1)}):Play()
        TweenService:Create(Dim,TweenInfo.new(0.45),{BackgroundTransparency=0.30}):Play()
    end

    if keyValid then
        showPhase2()
    else
        local DISCORD_LINK = getgenv().SpeedyConfig.Discord or "https://discord.gg/q5En862zuM"
        local okWind, WindUI = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/article-hub-studio/WindUI-Skibidi/main/dist/main.lua"))()
        end)
        if (not okWind or not WindUI) then
            okWind, WindUI = pcall(function()
                return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
            end)
        end
        if okWind and WindUI and WindUI.CreateWindow then
            TweenService:Create(Phase1, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {GroupTransparency=0.45}):Play()
            local Window
            local didUnlock = false
            pcall(function()
                if WindUI.Themes and WindUI.Themes.Dark then
                    WindUI.Themes.Dark.Accent = Color3.fromRGB(255, 26, 26)
                    WindUI.Themes.Dark.Primary = Color3.fromRGB(255, 26, 26)
                end
                if WindUI.AddTheme then
                    WindUI:AddTheme("SpeedyRed", {
                        Accent = Color3.fromRGB(255, 26, 26),
                        Primary = Color3.fromRGB(255, 26, 26),
                        Dialog = Color3.fromRGB(255, 26, 26),
                    })
                end
            end)
            Window = WindUI:CreateWindow({
                Title = "Speedy Hub",
                Icon = "shield-check",
                Author = nil,
                Folder = "SpeedyHub",
                Size = UDim2.fromOffset(680, 580),
                Transparent = false,
                Theme = "SpeedyRed",
                HideSearchBar = true,
                Topbar = { Height = 44, ButtonsType = "Mac" },
                OpenButton = { Enabled = false },
                KeySystem = {
                    Title = "Access",
                    Note = "HWID-bound  \xE2\x80\xA2  24h\nTap Get Key to copy Discord, grab your key there and paste below.",
                    SaveKey = false,
                    URL = DISCORD_LINK,
                    KeyValidator = function(rawKey)
                        local k = string.gsub(rawKey or "", "%s+", "")
                        if #k == 0 then return false, "Paste your license key." end
                        local ok, msg = checkKey(k)
                        if ok then
                            if didUnlock then return true end
                            didUnlock = true
                            task.spawn(function()
                                TweenService:Create(Phase1, TweenInfo.new(0.20, Enum.EasingStyle.Quad), {GroupTransparency=1}):Play()
                                task.wait(0.25)
                                Phase1.Visible = true
                                Phase1.GroupTransparency = 1
                                LogoFrame.Position = UDim2.fromScale(0.5,0.14)
                                SpeedyLabel.TextTransparency = 1
                                SpeedyLabel.Position = UDim2.fromOffset(148,18)
                                Shadow.TextTransparency = 1
                                HubLabel.TextTransparency = 1
                                for _,b in ipairs(barFrames) do
                                    b.Size = UDim2.fromOffset(54,0)
                                    b.Position = UDim2.fromOffset(0,45)
                                    b.BackgroundTransparency = 1
                                    b.Rotation = -28
                                end
                                Bar.Size = UDim2.fromScale(0,1)
                                LoadingLabel.Text = "LOADING  \xE2\x80\xA2  0%"
                                TweenService:Create(Phase1,TweenInfo.new(0.45,Enum.EasingStyle.Quad),{GroupTransparency=0}):Play()
                                TweenService:Create(LogoFrame,TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0.5,0.08)}):Play()
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
                                task.spawn(function() task.wait(0.72) TweenService:Create(SpeedyLabel, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextTransparency=0, Position=UDim2.fromOffset(148,8)}):Play() TweenService:Create(Shadow, TweenInfo.new(0.75), {TextTransparency=0.85}):Play() task.wait(0.18) TweenService:Create(HubLabel, TweenInfo.new(0.62, Enum.EasingStyle.Quad), {TextTransparency=0.38}):Play() end)
                                for i=0,100,10 do Bar.Size=UDim2.fromScale(i/100,1) task.wait(0.018) end
                                task.wait(0.25)
                                TweenService:Create(Phase1,TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),{GroupTransparency=1}):Play()
                                task.wait(0.35)
                                Phase1.Visible = false
                                pcall(function() Window:Destroy() end)
                                pcall(function() WindUI:Destroy() end)
                                showPhase2()
                            end)
                            return true
                        else
                            return false, tostring(msg or "Invalid or expired key")
                        end
                    end,
                    Thumbnail = nil,
                },
            })
            task.spawn(function()
                for _=1,40 do
                    task.wait(0.1)
                    pcall(function()
                        local roots = {game:GetService("CoreGui"), game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")}
                        for _,root in ipairs(roots) do
                            for _,o in ipairs(root:GetDescendants()) do
                                if (o:IsA("Frame") or o:IsA("CanvasGroup")) and o.AbsolutePosition.Y < 55 and o.AbsolutePosition.X > 400 then
                                    if o.Size.Y.Offset < 34 and o.Size.X.Offset < 90 and o.Size.X.Offset > 18 and o.Size.Y.Offset > 10 then
                                        pcall(function() o.Visible = false end)
                                    end
                                end
                                if o:IsA("Frame") and o.BackgroundColor3 then
                                    local c = o.BackgroundColor3
                                    if (math.floor(c.R*255)==37 and math.floor(c.G*255)==122 and math.floor(c.B*255)==247) or (math.floor(c.R*255)==3 and math.floor(c.G*255)==155 and math.floor(c.B*255)==229) then
                                        o.BackgroundColor3 = Color3.fromRGB(255,26,26)
                                        local g = o:FindFirstChildWhichIsA("UIGradient")
                                        if g then g.Color = ColorSequence.new(Color3.fromRGB(255,26,26)) end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        else
            local KeyUI = Instance.new("CanvasGroup", ScreenGui)
            KeyUI.Name = "KeyVaultFallback"
            KeyUI.AnchorPoint = Vector2.new(0.5, 0.5)
            KeyUI.Position = UDim2.fromScale(0.5, 0.5)
            KeyUI.Size = UDim2.fromOffset(560, 520)
            KeyUI.BackgroundTransparency = 1
            KeyUI.GroupTransparency = 1
            KeyUI.ZIndex = 10
            local kCard = Instance.new("Frame", KeyUI)
            kCard.Name = "Shell"
            kCard.Size = UDim2.fromScale(1, 1)
            kCard.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
            kCard.BackgroundTransparency = 0.12
            kCard.BorderSizePixel = 0
            kCard.ZIndex = 11
            Instance.new("UICorner", kCard).CornerRadius = UDim.new(0, 24)
            local kStroke = Instance.new("UIStroke", kCard)
            kStroke.Color = Color3.fromRGB(255,255,255)
            kStroke.Transparency = 0.88
            kStroke.Thickness = 1.2
            local fbTitle = Instance.new("TextLabel", kCard)
            fbTitle.Size = UDim2.new(1,-40,0,28)
            fbTitle.Position = UDim2.fromOffset(20,28)
            fbTitle.BackgroundTransparency = 1
            fbTitle.Text = "Speedy Hub - Key Required"
            fbTitle.Font = Enum.Font.GothamBlack
            fbTitle.TextSize = 18
            fbTitle.TextColor3 = Color3.new(1,1,1)
            local fbNote = Instance.new("TextLabel", kCard)
            fbNote.Size = UDim2.new(1,-40,0,40)
            fbNote.Position = UDim2.fromOffset(20,62)
            fbNote.BackgroundTransparency = 1
            fbNote.Text = "WindUI failed to load. Copy Discord, get key there."
            fbNote.Font = Enum.Font.Gotham
            fbNote.TextSize = 12
            fbNote.TextColor3 = Color3.fromRGB(150,150,165)
            fbNote.TextWrapped = true
            local fbBtn = Instance.new("TextButton", kCard)
            fbBtn.Size = UDim2.new(1,-40,0,44)
            fbBtn.Position = UDim2.fromOffset(20, 120)
            fbBtn.BackgroundColor3 = Color3.fromRGB(88,101,242)
            fbBtn.Text = "Copy Discord"
            fbBtn.Font = Enum.Font.GothamBold
            fbBtn.TextSize = 13
            fbBtn.TextColor3 = Color3.new(1,1,1)
            Instance.new("UICorner", fbBtn).CornerRadius = UDim.new(0,12)
            fbBtn.MouseButton1Click:Connect(function()
                pcall(function() if setclipboard then setclipboard(DISCORD_LINK) end end)
                fbBtn.Text = "Copied!"
                task.wait(1.5) fbBtn.Text = "Copy Discord"
            end)
            local fbShow = Instance.new("TextButton", kCard)
            fbShow.Size = UDim2.new(1,-40,0,44)
            fbShow.Position = UDim2.fromOffset(20, 172)
            fbShow.BackgroundColor3 = Color3.fromRGB(255,26,26)
            fbShow.Text = "I have a key - Enter"
            fbShow.Font = Enum.Font.GothamBold
            fbShow.TextSize = 13
            fbShow.TextColor3 = Color3.new(1,1,1)
            Instance.new("UICorner", fbShow).CornerRadius = UDim.new(0,12)
            fbShow.MouseButton1Click:Connect(function()
                KeyUI:Destroy()
                TweenService:Create(Phase1, TweenInfo.new(0.3), {GroupTransparency=1}):Play()
                task.wait(0.3) Phase1.Visible=false
                showPhase2()
            end)
            TweenService:Create(KeyUI, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {GroupTransparency=0}):Play()
        end
    end
 end)



game:GetService("UserInputService").InputBegan:Connect(function(inp,gp) if gp then return end if inp.KeyCode==Enum.KeyCode.Escape then if Phase2.Visible and Phase2.GroupTransparency<0.5 then RedDot:Activate() else TweenService:Create(Phase1,TweenInfo.new(0.3),{GroupTransparency=1}):Play() TweenService:Create(Blur,TweenInfo.new(0.3),{Size=0}):Play() TweenService:Create(Dim,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play() task.wait(0.3) ScreenGui:Destroy() Blur:Destroy() end end end)
print("[Speedy v4.0] Backend-driven game list • fetching from "..backend)
