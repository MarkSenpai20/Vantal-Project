--[[ 
    VANTAL STUDIOS - SIMPLE WHITELIST SYSTEM
    How to use:
    1. Host a text file on a site like GitHub Gists or Pastebin (Raw link).
    2. Put the UserIDs of people who paid in that file (one per line).
    3. Replace 'WHITELIST_URL' below with your raw link.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- CONFIGURATION
local WHITELIST_URL = "https://raw.githubusercontent.com/MarkSenpai20/Vantal-Project/refs/heads/main/whitelist.txt"
local SCRIPT_NAME = "Vantal FPS Troll Edition V4.2"

local function checkWhitelist()
    local success, response = pcall(function()
        return game:HttpGet(WHITELIST_URL)
    end)

    if success then
        -- Check if the player's UserID is in the text file
        if string.find(response, tostring(LocalPlayer.UserId)) then
            print("[" .. SCRIPT_NAME .. "]: Whitelist Verified. Welcome, " .. LocalPlayer.Name .. "!")
            return true
        else
            warn("[" .. SCRIPT_NAME .. "]: Access Denied. UserID " .. LocalPlayer.UserId .. " not whitelisted.")
            LocalPlayer:Kick("Unauthorized User: Please purchase a license from Vantal Studios.")
            return false
        end
    else
        warn("[" .. SCRIPT_NAME .. "]: Failed to connect to whitelist server.")
        return false
    end
end

-- RUN CHECK
if checkWhitelist() then
	
	--[[ 
    DELTA RIVALS HOOK - TROLL EDITION V4.2 (RADIUS UPDATE)
    Created by: MJ
    
    UPDATES:
    - ADDED "Priority Radius": Logic now prioritizes enemies within 50 studs.
    - If no one is in radius, it targets the closest person outside radius.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CLEANUP
if CoreGui:FindFirstChild("DeltaRivalsPanel") then
    CoreGui.DeltaRivalsPanel:Destroy()
end

--------------------------------------------------------------------------------
-- 1. SETTINGS & HELPERS
--------------------------------------------------------------------------------
local activeLoops = {}
local settings = {
    FFAMode = false, -- Default OFF (Safety)
    PriorityRadius = 50 -- [NEW] The radius to check first (Studs)
}

local function stopFeature(name)
    if activeLoops[name] then
        activeLoops[name]:Disconnect()
        activeLoops[name] = nil
    end
    -- Reset Physics
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.Velocity = Vector3.zero
            root.RotVelocity = Vector3.zero
        end
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

-- ENEMY CHECK (UPDATED FOR FFA)
local function isEnemy(p)
    if not p or not p.Parent or p == LocalPlayer then return false end
    
    -- If FFA Mode is ON, everyone is an enemy
    if settings.FFAMode then return true end
    
    -- Normal Team Check
    if LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then return false end
    if LocalPlayer.TeamColor and p.TeamColor and LocalPlayer.TeamColor == p.TeamColor then return false end
    
    return true
end

-- [MODIFIED] TARGETING LOGIC
local function getNearestEnemy()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    
    -- Bucket 1: Enemies INSIDE radius
    local bestTargetInRadius = nil
    local bestDistInRadius = math.huge

    -- Bucket 2: Enemies OUTSIDE radius
    local bestTargetGlobal = nil
    local bestDistGlobal = math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
                
                -- Check if inside Priority Radius
                if dist <= settings.PriorityRadius then
                    -- Find the closest one INSIDE the radius
                    if dist < bestDistInRadius then
                        bestDistInRadius = dist
                        bestTargetInRadius = p
                    end
                else
                    -- Find the closest one OUTSIDE the radius
                    if dist < bestDistGlobal then
                        bestDistGlobal = dist
                        bestTargetGlobal = p
                    end
                end
            end
        end
    end
    
    -- Priority Logic: Return Inside Radius target first. If nil, return Global target.
    if bestTargetInRadius then
        return bestTargetInRadius, bestDistInRadius
    else
        return bestTargetGlobal, bestDistGlobal
    end
end

--------------------------------------------------------------------------------
-- 2. GUI SETUP
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaRivalsPanel"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- OPEN BUTTON
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Parent = ScreenGui; OpenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25); OpenButton.Position = UDim2.new(0, 10, 0.5, -25); OpenButton.Size = UDim2.new(0, 50, 0, 50); OpenButton.Font = Enum.Font.GothamBold; OpenButton.Text = "OPEN"; OpenButton.TextColor3 = Color3.fromRGB(0, 255, 0); OpenButton.TextSize = 14; OpenButton.Visible = false; OpenButton.BorderSizePixel = 0
local OpenCorner = Instance.new("UICorner"); OpenCorner.CornerRadius = UDim.new(0, 8); OpenCorner.Parent = OpenButton

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); MainFrame.BorderSizePixel = 0; MainFrame.Position = UDim2.new(0.5, -200, 0.5, -225); MainFrame.Size = UDim2.new(0, 400, 0, 480); MainFrame.ClipsDescendants = true
local UICorner = Instance.new("UICorner"); UICorner.CornerRadius = UDim.new(0, 10); UICorner.Parent = MainFrame

-- HEADER
local Header = Instance.new("Frame"); Header.Parent = MainFrame; Header.BackgroundColor3 = Color3.fromRGB(30, 30, 35); Header.Size = UDim2.new(1, 0, 0, 40)
local HeaderTitle = Instance.new("TextLabel"); HeaderTitle.Parent = Header; HeaderTitle.BackgroundTransparency = 1; HeaderTitle.Position = UDim2.new(0, 15, 0, 0); HeaderTitle.Size = UDim2.new(1, -120, 1, 0); HeaderTitle.Font = Enum.Font.GothamBold; HeaderTitle.Text = "RIVALS <font color=\"rgb(0,255,0)\">V4.2 RADIUS</font>"; HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255); HeaderTitle.TextSize = 18; HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left; HeaderTitle.RichText = true

local MinButton = Instance.new("TextButton"); MinButton.Parent = Header; MinButton.BackgroundTransparency = 1; MinButton.Position = UDim2.new(1, -80, 0, 0); MinButton.Size = UDim2.new(0, 40, 0, 40); MinButton.Font = Enum.Font.GothamBold; MinButton.Text = "-"; MinButton.TextColor3 = Color3.fromRGB(200, 200, 200); MinButton.TextSize = 24
local CloseButton = Instance.new("TextButton"); CloseButton.Parent = Header; CloseButton.BackgroundTransparency = 1; CloseButton.Position = UDim2.new(1, -40, 0, 0); CloseButton.Size = UDim2.new(0, 40, 0, 40); CloseButton.Font = Enum.Font.GothamBold; CloseButton.Text = "X"; CloseButton.TextColor3 = Color3.fromRGB(150, 150, 150); CloseButton.TextSize = 18

-- SCROLL
local Content = Instance.new("ScrollingFrame"); Content.Parent = MainFrame; Content.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Content.BackgroundTransparency = 1; Content.BorderSizePixel = 0; Content.Position = UDim2.new(0, 0, 0, 40); Content.Size = UDim2.new(1, 0, 1, -40); Content.ScrollBarThickness = 4
local UIListLayout = Instance.new("UIListLayout"); UIListLayout.Parent = Content; UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0, 5)
local UIPadding = Instance.new("UIPadding"); UIPadding.Parent = Content; UIPadding.PaddingBottom = UDim.new(0, 10); UIPadding.PaddingLeft = UDim.new(0, 10); UIPadding.PaddingRight = UDim.new(0, 10); UIPadding.PaddingTop = UDim.new(0, 10)

MinButton.MouseButton1Click:Connect(function() MainFrame.Visible = false; OpenButton.Visible = true end)
OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = true; OpenButton.Visible = false end)
CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local function CreateSection(text)
    local Label = Instance.new("TextLabel"); Label.Parent = Content; Label.BackgroundTransparency = 1; Label.Size = UDim2.new(1, 0, 0, 30); Label.Font = Enum.Font.GothamBold; Label.Text = string.upper(text); Label.TextColor3 = Color3.fromRGB(100, 100, 100); Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; return Label
end

local function CreateToggle(text, description, callback)
    local ToggleFrame = Instance.new("Frame"); ToggleFrame.Parent = Content; ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35); ToggleFrame.Size = UDim2.new(1, 0, 0, 60)
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 6); Corner.Parent = ToggleFrame
    local Title = Instance.new("TextLabel"); Title.Parent = ToggleFrame; Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0, 10, 0, 10); Title.Size = UDim2.new(1, -60, 0, 20); Title.Font = Enum.Font.GothamMedium; Title.Text = text; Title.TextColor3 = Color3.fromRGB(230, 230, 230); Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left
    local Desc = Instance.new("TextLabel"); Desc.Parent = ToggleFrame; Desc.BackgroundTransparency = 1; Desc.Position = UDim2.new(0, 10, 0, 30); Desc.Size = UDim2.new(1, -60, 0, 20); Desc.Font = Enum.Font.Gotham; Desc.Text = description; Desc.TextColor3 = Color3.fromRGB(150, 150, 150); Desc.TextSize = 11; Desc.TextXAlignment = Enum.TextXAlignment.Left
    local Button = Instance.new("TextButton"); Button.Parent = ToggleFrame; Button.BackgroundColor3 = Color3.fromRGB(50, 50, 55); Button.Position = UDim2.new(1, -50, 0.5, -10); Button.Size = UDim2.new(0, 40, 0, 20); Button.Text = ""
    local BtnCorner = Instance.new("UICorner"); BtnCorner.CornerRadius = UDim.new(1, 0); BtnCorner.Parent = Button
    local Indicator = Instance.new("Frame"); Indicator.Parent = Button; Indicator.BackgroundColor3 = Color3.fromRGB(200, 200, 200); Indicator.Position = UDim2.new(0, 2, 0.5, -8); Indicator.Size = UDim2.new(0, 16, 0, 16)
    local IndCorner = Instance.new("UICorner"); IndCorner.CornerRadius = UDim.new(1, 0); IndCorner.Parent = Indicator
    local toggled = false
    Button.MouseButton1Click:Connect(function() 
        toggled = not toggled
        if toggled then 
            Button.BackgroundColor3 = Color3.fromRGB(0, 170, 0); Indicator:TweenPosition(UDim2.new(1, -18, 0.5, -8), "Out", "Quad", 0.1, true) 
        else 
            Button.BackgroundColor3 = Color3.fromRGB(50, 50, 55); Indicator:TweenPosition(UDim2.new(0, 2, 0.5, -8), "Out", "Quad", 0.1, true) 
        end
        task.spawn(function()
            local success, err = pcall(callback, toggled)
            if not success then warn("Error: "..tostring(err)) end
        end)
    end)
end

--------------------------------------------------------------------------------
-- 3. FEATURES
--------------------------------------------------------------------------------

CreateSection("Settings")

-- [FFA MODE]
CreateToggle("FFA Mode", "Target EVERYONE (Use if script isn't working)", function(state)
    settings.FFAMode = state
    if state then print("[VANTAL]: FFA Mode Enabled. Targeting ALL players.") else print("[VANTAL]: Team Check Enabled.") end
end)

-- [RADIUS TOGGLE OPTIONAL - Can be added if you want to switch range]
CreateToggle("Close Range Only", "Sets priority radius to 25 studs", function(state)
    if state then settings.PriorityRadius = 25 else settings.PriorityRadius = 50 end
    print("[VANTAL]: Priority Radius set to " .. settings.PriorityRadius)
end)

CreateSection("Combat")

CreateToggle("Camera Head Lock", "Locks camera to nearest enemy head", function(state)
    local name = "Aimbot"
    if state then
        activeLoops[name] = RunService.RenderStepped:Connect(function()
            local target, dist = getNearestEnemy()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
            end
        end)
    else stopFeature(name) end
end)

CreateToggle("Auto Dodge", "Teleports sideways if aimed at", function(state)
    local name = "AutoDodge"
    local lastDodge = 0
    local cooldown = 0.5
    
    if state then
        activeLoops[name] = RunService.RenderStepped:Connect(function()
            local target, dist = getNearestEnemy()
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
            
            if target and target.Character then
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = LocalPlayer.Character.HumanoidRootPart
                
                if tRoot then
                    local enemyLook = tRoot.CFrame.LookVector
                    local dirToMe = (myRoot.Position - tRoot.Position).Unit
                    local dot = enemyLook:Dot(dirToMe)
                    
                    if dot > 0.95 and (tick() - lastDodge > cooldown) then
                        lastDodge = tick()
                        local dodgeVector = myRoot.CFrame.RightVector * 5
                        if math.random(1, 2) == 1 then dodgeVector = -dodgeVector end
                        myRoot.CFrame = myRoot.CFrame + dodgeVector
                    end
                end
            end
        end)
    else stopFeature(name) end
end)

CreateSection("Annoyance")

CreateToggle("Stalker Mode", "Follows enemy from 6 studs behind", function(state)
    local name = "Stalker"
    if state then
        activeLoops[name] = RunService.RenderStepped:Connect(function()
            local target, dist = getNearestEnemy()
            if not LocalPlayer.Character then return end
            
            if target and target.Character then
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if tRoot and myRoot then
                    myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 2, 6)
                    myRoot.Velocity = Vector3.zero
                    for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
                end
            end
        end)
    else stopFeature(name) end
end)

CreateToggle("Haunt Mode", "Teleport behind looking enemies", function(state)
    local name = "Haunt"
    if state then
        activeLoops[name] = RunService.RenderStepped:Connect(function()
            local target, dist = getNearestEnemy()
            if not LocalPlayer.Character then return end
            
            if target and target.Character then
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if tRoot and myRoot then
                    local enemyLook = tRoot.CFrame.LookVector
                    local dirToMe = (myRoot.Position - tRoot.Position).Unit
                    local dot = enemyLook:Dot(dirToMe)
                    if dot > 0.2 then 
                        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 5)
                        myRoot.Velocity = Vector3.zero
                    end
                end
            end
        end)
    else stopFeature(name) end
end)

CreateToggle("Ride Enemy", "Stick to nearest enemy back", function(state)
    local name = "Ride"
    if state then
        activeLoops[name] = RunService.RenderStepped:Connect(function()
            local target, dist = getNearestEnemy()
            if not LocalPlayer.Character then return end
            
            if target and target.Character then
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if tRoot and myRoot then 
                    myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 2, 2)
                    myRoot.Velocity = Vector3.zero 
                end
            end
        end)
    else stopFeature(name) end
end)

CreateSection("Visuals")

CreateToggle("X-Ray Vision", "See enemies through walls", function(state)
    if state then
        for _, p in pairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then 
                local h = Instance.new("Highlight", p.Character); h.Name = "VantalESP"; h.FillColor = Color3.fromRGB(255, 0, 0); h.OutlineColor = Color3.fromRGB(255, 255, 255); h.FillTransparency = 0.5 
            end
        end
        activeLoops["ESP"] = Players.PlayerAdded:Connect(function(p) 
            p.CharacterAdded:Connect(function(char) 
                if isEnemy(p) then
                    local h = Instance.new("Highlight", char); h.Name = "VantalESP"; h.FillColor = Color3.fromRGB(255, 0, 0) 
                end
            end) 
        end)
    else
        if activeLoops["ESP"] then activeLoops["ESP"]:Disconnect() end
        for _, p in pairs(Players:GetPlayers()) do if p.Character then for _, v in pairs(p.Character:GetChildren()) do if v.Name == "VantalESP" then v:Destroy() end end end end
    end
end)

-- DRAG LOGIC
local dragging, dragInput, dragStart, startPos
local function update(input) local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = MainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

print("[VANTAL FPS]: V4.2 Priority Radius Loaded.")

	
    print("Main script is now executing...")
    
    -- (Your Vantal FPS Troll Edition code goes here)
end
