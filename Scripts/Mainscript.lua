--[[
    BREAKDOOR - COMPLETE ALL-IN-ONE SCRIPT (FIXED)
    Version: 2.2
    Features:
        - Fly (GUI only - F key removed)
        - Speed Boost (G key)
        - ESP (GUI only - E key removed)
        - Auto-TP to Presents (L key) - WORKS WITH "Gift" MODELS
        - Teleport Now button
        - Draggable GUI with sliders
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ========================================================================
--  CONFIGURATION
-- ========================================================================

local CONFIG = {
    FLY_SPEED = 75,
    WALK_SPEED_MULTIPLIER = 10,
    MIN_FLY_SPEED = 10,
    MAX_FLY_SPEED = 200,
    MIN_WALK_MULTIPLIER = 1,
    MAX_WALK_MULTIPLIER = 25,
    TELEPORT_COOLDOWN = 3,
    KEYBINDS = {
        speed = Enum.KeyCode.G,
        autoLoot = Enum.KeyCode.L,
    },
}

-- ========================================================================
--  VARIABLES
-- ========================================================================

local flying = false
local speedBoost = false
local espEnabled = true
local autoLootEnabled = false
local defaultWalkSpeed = humanoid.WalkSpeed
local currentFlySpeed = CONFIG.FLY_SPEED
local currentWalkMultiplier = CONFIG.WALK_SPEED_MULTIPLIER
local lastTeleportTime = 0
local espObjects = {}

print("🔑 Keybinds: G=Speed, L=Auto-Loot | Fly/ESP = GUI only")
print("🎁 Looking for 'Gift' models inside 'Airdropbox_XX'...")

-- ========================================================================
--  AIRDROP SYSTEM (FIXED FOR "GIFT" MODELS)
-- ========================================================================

local function findAirdrops()
    local airdrops = {}
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- Look for "Gift" models (your presents!)
        if obj:IsA("Model") and obj.Name == "Gift" then
            table.insert(airdrops, obj)
        end
        
        -- Look for "Gift" parts
        if obj:IsA("BasePart") and obj.Name == "Gift" then
            table.insert(airdrops, obj)
        end
        
        -- Look inside Airdropbox models
        if obj:IsA("Model") and string.find(obj.Name, "Airdropbox") then
            for _, child in ipairs(obj:GetChildren()) do
                if child.Name == "Gift" then
                    table.insert(airdrops, child)
                end
            end
            -- Also add the Airdropbox itself as fallback
            table.insert(airdrops, obj)
        end
        
        -- Check for other gift-related names (fallback)
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if string.find(name, "gift") or string.find(name, "present") or 
               string.find(name, "airdrop") or string.find(name, "crate") then
                table.insert(airdrops, obj)
            end
        end
    end
    
    return airdrops
end

local function findNearestAirdrop()
    local airdrops = findAirdrops()
    local nearest = nil
    local nearestDist = math.huge
    
    for _, airdrop in ipairs(airdrops) do
        if airdrop and airdrop.Parent then
            local airdropPos = nil
            
            if airdrop:IsA("BasePart") then
                airdropPos = airdrop.Position
            elseif airdrop:IsA("Model") then
                -- Try to find a part inside the model
                local primaryPart = airdrop:FindFirstChild("Head") or 
                                   airdrop:FindFirstChild("HumanoidRootPart") or
                                   airdrop:FindFirstChild("MainPart") or
                                   airdrop:FindFirstChild("RootPart") or
                                   airdrop:FindFirstChild("Part")
                
                if not primaryPart then
                    for _, child in ipairs(airdrop:GetChildren()) do
                        if child:IsA("BasePart") then
                            primaryPart = child
                            break
                        end
                    end
                end
                
                if primaryPart then
                    airdropPos = primaryPart.Position
                else
                    local modelCFrame = airdrop:GetPivot()
                    if modelCFrame then
                        airdropPos = modelCFrame.Position
                    end
                end
            end
            
            if airdropPos and rootPart then
                local dist = (rootPart.Position - airdropPos).Magnitude
                if dist < nearestDist then
                    nearest = airdrop
                    nearestDist = dist
                end
            end
        end
    end
    
    return nearest, nearestDist
end

local function teleportToAirdrop(airdrop)
    if not airdrop or not airdrop.Parent then 
        return false, "Airdrop not found"
    end
    
    local currentTime = tick()
    if currentTime - lastTeleportTime < CONFIG.TELEPORT_COOLDOWN then
        return false, "Cooldown: " .. math.ceil(CONFIG.TELEPORT_COOLDOWN - (currentTime - lastTeleportTime)) .. "s"
    end
    
    local teleportPos = nil
    
    if airdrop:IsA("BasePart") then
        teleportPos = airdrop.Position + Vector3.new(0, 5, 0)
    elseif airdrop:IsA("Model") then
        local primaryPart = airdrop:FindFirstChild("Head") or 
                           airdrop:FindFirstChild("HumanoidRootPart") or
                           airdrop:FindFirstChild("MainPart") or
                           airdrop:FindFirstChild("RootPart") or
                           airdrop:FindFirstChild("Part")
        
        if not primaryPart then
            for _, child in ipairs(airdrop:GetChildren()) do
                if child:IsA("BasePart") then
                    primaryPart = child
                    break
                end
            end
        end
        
        if primaryPart then
            teleportPos = primaryPart.Position + Vector3.new(0, 5, 0)
        else
            local modelCFrame = airdrop:GetPivot()
            if modelCFrame then
                teleportPos = modelCFrame.Position + Vector3.new(0, 5, 0)
            end
        end
    end
    
    if not teleportPos then
        return false, "Could not find airdrop position"
    end
    
    -- Teleport
    rootPart.CFrame = CFrame.new(teleportPos)
    lastTeleportTime = currentTime
    
    -- Visual effect
    local effect = Instance.new("Part")
    effect.Name = "TeleportEffect"
    effect.Size = Vector3.new(10, 10, 10)
    effect.Position = teleportPos
    effect.Anchored = true
    effect.CanCollide = false
    effect.BrickColor = BrickColor.new("Bright blue")
    effect.Material = Enum.Material.Neon
    effect.Transparency = 0.5
    effect.Parent = workspace
    
    game:GetService("Debris"):AddItem(effect, 0.5)
    for i = 1, 10 do
        effect.Transparency = effect.Transparency + 0.05
        effect.Size = effect.Size + Vector3.new(1, 1, 1)
        task.wait(0.05)
    end
    effect:Destroy()
    
    return true, "Teleported to " .. airdrop.Name .. "!"
end

-- Auto-Loot loop
task.spawn(function()
    while true do
        if autoLootEnabled then
            local airdrop, dist = findNearestAirdrop()
            if airdrop then
                local success, message = teleportToAirdrop(airdrop)
                if success then
                    statusLabel.Text = "📍 Teleported to " .. airdrop.Name .. "! (" .. math.floor(dist or 0) .. "m)"
                else
                    statusLabel.Text = "⏳ " .. message
                end
            else
                statusLabel.Text = "❌ No presents found!"
            end
            task.wait(CONFIG.TELEPORT_COOLDOWN)
        else
            task.wait(1)
        end
    end
end)

-- ========================================================================
--  ESP SYSTEM
-- ========================================================================

local function createESP(targetPlayer)
    if targetPlayer == player then return end
    if espObjects[targetPlayer] then return end
    
    local targetCharacter = targetPlayer.Character
    if not targetCharacter then return end
    
    local espData = {}
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = targetCharacter
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Color3.new(1, 1, 0)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = targetCharacter:WaitForChild("Head")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = billboard
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 18
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Parent = billboard
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    distLabel.TextSize = 14
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    
    local healthBg = Instance.new("Frame")
    healthBg.Parent = billboard
    healthBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    healthBg.BackgroundTransparency = 0.5
    healthBg.Size = UDim2.new(1, 0, 0.15, 0)
    healthBg.Position = UDim2.new(0, 0, 0, -0.2)
    healthBg.BorderSizePixel = 0
    
    local healthBar = Instance.new("Frame")
    healthBar.Parent = healthBg
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBar.BackgroundTransparency = 0.1
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BorderSizePixel = 0
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Parent = healthBg
    healthLabel.BackgroundTransparency = 1
    healthLabel.Size = UDim2.new(1, 0, 1, 0)
    healthLabel.Text = "100%"
    healthLabel.TextColor3 = Color3.new(1, 1, 1)
    healthLabel.TextSize = 11
    healthLabel.Font = Enum.Font.GothamBold
    healthLabel.TextStrokeTransparency = 0.5
    
    local function updateHealth()
        local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
        if targetHumanoid and targetHumanoid.Health then
            local healthPercent = targetHumanoid.Health / targetHumanoid.MaxHealth
            healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
            healthLabel.Text = math.floor(targetHumanoid.Health) .. "%"
            
            if healthPercent > 0.6 then
                healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
            elseif healthPercent > 0.3 then
                healthBar.BackgroundColor3 = Color3.new(1, 1, 0)
            else
                healthBar.BackgroundColor3 = Color3.new(1, 0, 0)
            end
        end
    end
    
    local function updateDistance()
        if character and character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (rootPart.Position - targetRoot.Position).Magnitude
                distLabel.Text = math.floor(distance) .. "m"
                
                if distance < 50 then
                    distLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
                elseif distance < 100 then
                    distLabel.TextColor3 = Color3.new(1, 1, 0)
                else
                    distLabel.TextColor3 = Color3.new(0.2, 1, 0.2)
                end
            end
        end
    end
    
    espData.highlight = highlight
    espData.billboard = billboard
    espData.healthBar = healthBar
    espData.healthLabel = healthLabel
    espData.distLabel = distLabel
    espData.updateHealth = updateHealth
    espData.updateDistance = updateDistance
    espData.targetPlayer = targetPlayer
    
    espObjects[targetPlayer] = espData
    updateHealth()
    
    return espData
end

local function removeESP(targetPlayer)
    local espData = espObjects[targetPlayer]
    if espData then
        if espData.highlight then espData.highlight:Destroy() end
        if espData.billboard then espData.billboard:Destroy() end
        espObjects[targetPlayer] = nil
    end
end

local function clearAllESP()
    for targetPlayer, _ in pairs(espObjects) do
        removeESP(targetPlayer)
    end
    espObjects = {}
end

local function toggleESP()
    espEnabled = not espEnabled
    
    if espEnabled then
        for _, targetPlayer in ipairs(game.Players:GetPlayers()) do
            if targetPlayer ~= player then
                createESP(targetPlayer)
            end
        end
        print("👁️ ESP: ON")
    else
        clearAllESP()
        print("👁️ ESP: OFF")
    end
end

-- Update ESP loop
game:GetService("RunService").Heartbeat:Connect(function()
    if not espEnabled then return end
    
    for targetPlayer, espData in pairs(espObjects) do
        if targetPlayer and targetPlayer.Character and targetPlayer.Character.Parent then
            espData.updateHealth()
            espData.updateDistance()
        else
            removeESP(targetPlayer)
        end
    end
end)

-- Handle new players
game.Players.PlayerAdded:Connect(function(newPlayer)
    if espEnabled and newPlayer ~= player then
        task.wait(1)
        createESP(newPlayer)
    end
end)

game.Players.PlayerRemoving:Connect(function(leavingPlayer)
    removeESP(leavingPlayer)
end)

-- ========================================================================
--  FLY SYSTEM
-- ========================================================================

local bodyVelocity = nil
local bodyGyro = nil

local function startFly()
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    bodyVelocity.P = 1000
    bodyVelocity.Parent = rootPart
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
    bodyGyro.P = 10000
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    
    humanoid.PlatformStand = true
    humanoid.Sit = false
    humanoid.AutoRotate = false
    
    flying = true
end

local function stopFly()
    if bodyVelocity then 
        bodyVelocity:Destroy() 
        bodyVelocity = nil
    end
    if bodyGyro then 
        bodyGyro:Destroy() 
        bodyGyro = nil
    end
    humanoid.PlatformStand = false
    humanoid.AutoRotate = true
    flying = false
end

-- ========================================================================
--  CREATE GUI
-- ========================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui
screenGui.Name = "BreakDoorGUI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.12)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderColor3 = Color3.new(0.3, 0.8, 1)
mainFrame.BorderSizePixel = 2
mainFrame.Size = UDim2.new(0, 280, 0, 340)
mainFrame.Position = UDim2.new(0, 20, 0, 100)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Selectable = true

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Parent = mainFrame
titleBar.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.Position = UDim2.new(0, 0, 0, 0)

local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = titleBar
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "✈️ BreakDoor Controls"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 5, 0, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = Instance.new("TextButton")
closeButton.Parent = titleBar
closeButton.BackgroundColor3 = Color3.new(0.8, 0.1, 0.1)
closeButton.BorderSizePixel = 0
closeButton.Size = UDim2.new(0, 25, 1, -2)
closeButton.Position = UDim2.new(1, -27, 0, 1)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 14
closeButton.Font = Enum.Font.GothamBold
closeButton.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

-- ============ FLY BUTTON & SLIDER ============

local flyButton = Instance.new("TextButton")
flyButton.Parent = mainFrame
flyButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
flyButton.BorderSizePixel = 0
flyButton.Size = UDim2.new(0.9, 0, 0, 32)
flyButton.Position = UDim2.new(0.05, 0, 0.09, 0)
flyButton.Text = "✈️ Fly: OFF"
flyButton.TextColor3 = Color3.new(1, 1, 1)
flyButton.TextSize = 15
flyButton.Font = Enum.Font.GothamBold

local flySpeedLabel = Instance.new("TextLabel")
flySpeedLabel.Parent = mainFrame
flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.Text = "Fly Speed: 75"
flySpeedLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
flySpeedLabel.TextSize = 12
flySpeedLabel.Font = Enum.Font.Gotham
flySpeedLabel.Size = UDim2.new(0.4, 0, 0, 20)
flySpeedLabel.Position = UDim2.new(0.05, 0, 0.21, 0)
flySpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local flySpeedValue = Instance.new("TextLabel")
flySpeedValue.Parent = mainFrame
flySpeedValue.BackgroundTransparency = 1
flySpeedValue.Text = "75"
flySpeedValue.TextColor3 = Color3.new(0.3, 0.8, 1)
flySpeedValue.TextSize = 14
flySpeedValue.Font = Enum.Font.GothamBold
flySpeedValue.Size = UDim2.new(0.15, 0, 0, 20)
flySpeedValue.Position = UDim2.new(0.8, 0, 0.21, 0)
flySpeedValue.TextXAlignment = Enum.TextXAlignment.Right

local flySlider = Instance.new("Frame")
flySlider.Parent = mainFrame
flySlider.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
flySlider.BorderSizePixel = 0
flySlider.Size = UDim2.new(0.8, 0, 0, 6)
flySlider.Position = UDim2.new(0.1, 0, 0.25, 0)

local flySliderFill = Instance.new("Frame")
flySliderFill.Parent = flySlider
flySliderFill.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
flySliderFill.BorderSizePixel = 0
flySliderFill.Size = UDim2.new(0.5, 0, 1, 0)

local flySliderButton = Instance.new("TextButton")
flySliderButton.Parent = flySlider
flySliderButton.BackgroundColor3 = Color3.new(0.3, 0.8, 1)
flySliderButton.BorderSizePixel = 0
flySliderButton.Size = UDim2.new(0, 14, 0, 14)
flySliderButton.Position = UDim2.new(0.5, -7, -0.6, 0)
flySliderButton.Text = ""
flySliderButton.AutoButtonColor = false

-- ============ SPEED BUTTON & SLIDER ============

local speedButton = Instance.new("TextButton")
speedButton.Parent = mainFrame
speedButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.3)
speedButton.BorderSizePixel = 0
speedButton.Size = UDim2.new(0.9, 0, 0, 32)
speedButton.Position = UDim2.new(0.05, 0, 0.33, 0)
speedButton.Text = "🏃 Speed x10: OFF"
speedButton.TextColor3 = Color3.new(1, 1, 1)
speedButton.TextSize = 15
speedButton.Font = Enum.Font.GothamBold

local walkSpeedLabel = Instance.new("TextLabel")
walkSpeedLabel.Parent = mainFrame
walkSpeedLabel.BackgroundTransparency = 1
walkSpeedLabel.Text = "Walk Multiplier: 10x"
walkSpeedLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
walkSpeedLabel.TextSize = 12
walkSpeedLabel.Font = Enum.Font.Gotham
walkSpeedLabel.Size = UDim2.new(0.4, 0, 0, 20)
walkSpeedLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
walkSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local walkSpeedValue = Instance.new("TextLabel")
walkSpeedValue.Parent = mainFrame
walkSpeedValue.BackgroundTransparency = 1
walkSpeedValue.Text = "10x"
walkSpeedValue.TextColor3 = Color3.new(0.3, 0.9, 0.3)
walkSpeedValue.TextSize = 14
walkSpeedValue.Font = Enum.Font.GothamBold
walkSpeedValue.Size = UDim2.new(0.15, 0, 0, 20)
walkSpeedValue.Position = UDim2.new(0.8, 0, 0.45, 0)
walkSpeedValue.TextXAlignment = Enum.TextXAlignment.Right

local walkSlider = Instance.new("Frame")
walkSlider.Parent = mainFrame
walkSlider.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
walkSlider.BorderSizePixel = 0
walkSlider.Size = UDim2.new(0.8, 0, 0, 6)
walkSlider.Position = UDim2.new(0.1, 0, 0.49, 0)

local walkSliderFill = Instance.new("Frame")
walkSliderFill.Parent = walkSlider
walkSliderFill.BackgroundColor3 = Color3.new(0.2, 0.8, 0.3)
walkSliderFill.BorderSizePixel = 0
walkSliderFill.Size = UDim2.new(0.4, 0, 1, 0)

local walkSliderButton = Instance.new("TextButton")
walkSliderButton.Parent = walkSlider
walkSliderButton.BackgroundColor3 = Color3.new(0.3, 0.9, 0.3)
walkSliderButton.BorderSizePixel = 0
walkSliderButton.Size = UDim2.new(0, 14, 0, 14)
walkSliderButton.Position = UDim2.new(0.4, -7, -0.6, 0)
walkSliderButton.Text = ""
walkSliderButton.AutoButtonColor = false

-- ============ ESP BUTTON ============

local espButton = Instance.new("TextButton")
espButton.Parent = mainFrame
espButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.8)
espButton.BorderSizePixel = 0
espButton.Size = UDim2.new(0.9, 0, 0, 32)
espButton.Position = UDim2.new(0.05, 0, 0.57, 0)
espButton.Text = "👁️ ESP: ON"
espButton.TextColor3 = Color3.new(1, 1, 1)
espButton.TextSize = 15
espButton.Font = Enum.Font.GothamBold

-- ============ AUTO-LOOT BUTTON ============

local autoLootButton = Instance.new("TextButton")
autoLootButton.Parent = mainFrame
autoLootButton.BackgroundColor3 = Color3.new(0.8, 0.6, 0)
autoLootButton.BorderSizePixel = 0
autoLootButton.Size = UDim2.new(0.9, 0, 0, 32)
autoLootButton.Position = UDim2.new(0.05, 0, 0.69, 0)
autoLootButton.Text = "🎁 Auto-TP Presents: OFF"
autoLootButton.TextColor3 = Color3.new(1, 1, 1)
autoLootButton.TextSize = 14
autoLootButton.Font = Enum.Font.GothamBold

-- ============ TELEPORT NOW BUTTON ============

local teleportNowButton = Instance.new("TextButton")
teleportNowButton.Parent = mainFrame
teleportNowButton.BackgroundColor3 = Color3.new(0.2, 0.4, 1)
teleportNowButton.BorderSizePixel = 0
teleportNowButton.Size = UDim2.new(0.9, 0, 0, 28)
teleportNowButton.Position = UDim2.new(0.05, 0, 0.81, 0)
teleportNowButton.Text = "📍 Teleport to Nearest Present NOW"
teleportNowButton.TextColor3 = Color3.new(1, 1, 1)
teleportNowButton.TextSize = 13
teleportNowButton.Font = Enum.Font.GothamBold

-- ============ STATUS LABEL ============

statusLabel = Instance.new("TextLabel")
statusLabel.Parent = mainFrame
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready | Press L for Auto-Loot"
statusLabel.TextColor3 = Color3.new(0.6, 0.9, 0.6)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0.90, 0)
statusLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ========================================================================
--  SLIDER FUNCTIONS
-- ========================================================================

local function updateFlySlider(value)
    local percent = (value - CONFIG.MIN_FLY_SPEED) / (CONFIG.MAX_FLY_SPEED - CONFIG.MIN_FLY_SPEED)
    flySliderFill.Size = UDim2.new(percent, 0, 1, 0)
    flySliderButton.Position = UDim2.new(percent, -7, -0.6, 0)
    flySpeedValue.Text = tostring(math.round(value))
    flySpeedLabel.Text = "Fly Speed: " .. tostring(math.round(value))
    currentFlySpeed = value
end

local function updateWalkSlider(value)
    local percent = (value - CONFIG.MIN_WALK_MULTIPLIER) / (CONFIG.MAX_WALK_MULTIPLIER - CONFIG.MIN_WALK_MULTIPLIER)
    walkSliderFill.Size = UDim2.new(percent, 0, 1, 0)
    walkSliderButton.Position = UDim2.new(percent, -7, -0.6, 0)
    walkSpeedValue.Text = tostring(math.round(value)) .. "x"
    walkSpeedLabel.Text = "Walk Multiplier: " .. tostring(math.round(value)) .. "x"
    currentWalkMultiplier = value
    
    if speedBoost then
        humanoid.WalkSpeed = defaultWalkSpeed * value
    end
end

-- Fly Slider Dragging
local flyDragging = false
flySliderButton.MouseButton1Down:Connect(function()
    flyDragging = true
end)

flySliderButton.MouseButton1Up:Connect(function()
    flyDragging = false
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if flyDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position
        local sliderAbsPos = flySlider.AbsolutePosition
        local sliderSize = flySlider.AbsoluteSize
        
        local percent = math.clamp((mousePos.X - sliderAbsPos.X) / sliderSize.X, 0, 1)
        local value = CONFIG.MIN_FLY_SPEED + (CONFIG.MAX_FLY_SPEED - CONFIG.MIN_FLY_SPEED) * percent
        updateFlySlider(value)
    end
end)

-- Walk Slider Dragging
local walkDragging = false
walkSliderButton.MouseButton1Down:Connect(function()
    walkDragging = true
end)

walkSliderButton.MouseButton1Up:Connect(function()
    walkDragging = false
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if walkDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position
        local sliderAbsPos = walkSlider.AbsolutePosition
        local sliderSize = walkSlider.AbsoluteSize
        
        local percent = math.clamp((mousePos.X - sliderAbsPos.X) / sliderSize.X, 0, 1)
        local value = CONFIG.MIN_WALK_MULTIPLIER + (CONFIG.MAX_WALK_MULTIPLIER - CONFIG.MIN_WALK_MULTIPLIER) * percent
        updateWalkSlider(math.round(value))
    end
end)

-- ========================================================================
--  TOGGLE FUNCTIONS
-- ========================================================================

local function toggleFly()
    if flying then
        stopFly()
        flyButton.Text = "✈️ Fly: OFF"
        flyButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
        statusLabel.Text = "Status: Grounded | Press L for Auto-Loot"
        statusLabel.TextColor3 = Color3.new(0.6, 0.9, 0.6)
    else
        startFly()
        flyButton.Text = "✈️ Fly: ON"
        flyButton.BackgroundColor3 = Color3.new(0, 0.8, 0.2)
        statusLabel.Text = "Status: Flying | Press L for Auto-Loot"
        statusLabel.TextColor3 = Color3.new(0, 1, 0)
    end
end

local function toggleSpeed()
    speedBoost = not speedBoost
    
    if speedBoost then
        humanoid.WalkSpeed = defaultWalkSpeed * currentWalkMultiplier
        speedButton.Text = "🏃 Speed x" .. tostring(math.round(currentWalkMultiplier)) .. ": ON"
        speedButton.BackgroundColor3 = Color3.new(0, 0.8, 0.2)
    else
        humanoid.WalkSpeed = defaultWalkSpeed
        speedButton.Text = "🏃 Speed x" .. tostring(math.round(currentWalkMultiplier)) .. ": OFF"
        speedButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.3)
    end
end

local function toggleAutoLoot()
    autoLootEnabled = not autoLootEnabled
    autoLootButton.Text = autoLootEnabled and "🎁 Auto-TP Presents: ON" or "🎁 Auto-TP Presents: OFF"
    autoLootButton.BackgroundColor3 = autoLootEnabled and Color3.new(0, 0.8, 0.2) or Color3.new(0.8, 0.6, 0)
    
    if autoLootEnabled then
        statusLabel.Text = "🎁 Auto-Loot: ON - Teleporting to presents!"
    else
        statusLabel.Text = "🎁 Auto-Loot: OFF"
    end
    print("🎁 Auto-Loot: " .. (autoLootEnabled and "ON" or "OFF"))
end

-- Button clicks
flyButton.MouseButton1Click:Connect(toggleFly)
speedButton.MouseButton1Click:Connect(toggleSpeed)

-- ESP Button click
espButton.MouseButton1Click:Connect(function()
    toggleESP()
    espButton.Text = espEnabled and "👁️ ESP: ON" or "👁️ ESP: OFF"
    espButton.BackgroundColor3 = espEnabled and Color3.new(0.8, 0.2, 0.8) or Color3.new(0.3, 0.3, 0.3)
end)

-- Auto-Loot Button click
autoLootButton.MouseButton1Click:Connect(toggleAutoLoot)

-- Teleport Now Button click
teleportNowButton.MouseButton1Click:Connect(function()
    local airdrop, dist = findNearestAirdrop()
    if airdrop then
        local success, message = teleportToAirdrop(airdrop)
        if success then
            statusLabel.Text = "📍 Teleported to " .. airdrop.Name .. "! (" .. math.floor(dist or 0) .. "m)"
        else
            statusLabel.Text = "❌ " .. message
        end
    else
        statusLabel.Text = "❌ No presents found!"
    end
end)

-- ========================================================================
--  KEYBINDS
-- ========================================================================

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- G = Toggle Speed
    if input.KeyCode == CONFIG.KEYBINDS.speed then
        toggleSpeed()
    end
    
    -- L = Toggle Auto-Loot
    if input.KeyCode == CONFIG.KEYBINDS.autoLoot then
        toggleAutoLoot()
    end
    
    -- NOTE: E key does NOTHING (ESP is GUI only)
    -- NOTE: F key does NOTHING (Fly is GUI only)
end)

-- ========================================================================
--  FLY MOVEMENT
-- ========================================================================

game:GetService("RunService").Heartbeat:Connect(function()
    if flying and character and character.Parent then
        if not bodyVelocity or not bodyVelocity.Parent then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
            bodyVelocity.P = 1000
            bodyVelocity.Parent = rootPart
        end
        
        if not bodyGyro or not bodyGyro.Parent then
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
            bodyGyro.P = 10000
            bodyGyro.Parent = rootPart
        end
        
        bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(0, 1, 0))
        
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new(0, 0, 0)
        
        local forward = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local up = camera.CFrame.UpVector
        
        forward = Vector3.new(forward.X, 0, forward.Z).Unit
        right = Vector3.new(right.X, 0, right.Z).Unit
        
        local userInput = game:GetService("UserInputService")
        
        if userInput:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + forward
        end
        if userInput:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - forward
        end
        if userInput:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - right
        end
        if userInput:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + right
        end
        if userInput:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if userInput:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * currentFlySpeed
        end
        
        bodyVelocity.Velocity = moveDirection
    end
end)

-- ========================================================================
--  CHARACTER RESPAWN
-- ========================================================================

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    defaultWalkSpeed = humanoid.WalkSpeed
    
    if flying then
        stopFly()
    end
    
    speedBoost = false
    autoLootEnabled = false
    humanoid.WalkSpeed = defaultWalkSpeed
    
    flyButton.Text = "✈️ Fly: OFF"
    flyButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
    speedButton.Text = "🏃 Speed x" .. tostring(math.round(currentWalkMultiplier)) .. ": OFF"
    speedButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.3)
    autoLootButton.Text = "🎁 Auto-TP Presents: OFF"
    autoLootButton.BackgroundColor3 = Color3.new(0.8, 0.6, 0)
    statusLabel.Text = "Status: Ready | Press L for Auto-Loot"
    statusLabel.TextColor3 = Color3.new(0.6, 0.9, 0.6)
end)

-- ========================================================================
--  INITIALIZATION
-- ========================================================================

-- Initial slider setup
updateFlySlider(CONFIG.FLY_SPEED)
updateWalkSlider(CONFIG.WALK_SPEED_MULTIPLIER)

-- Initial ESP setup
task.wait(1)
for _, targetPlayer in ipairs(game.Players:GetPlayers()) do
    if targetPlayer ~= player then
        createESP(targetPlayer)
    end
end

print("✅ BreakDoor COMPLETE Script Loaded!")
print("🟢 === FEATURES ===")
print("🟢 Fly: GUI Button ONLY (F key removed)")
print("🟢 Speed Toggle: G key OR GUI Button")
print("🟢 ESP: GUI Button ONLY (E key removed)")
print("🟢 Auto-Loot: L key OR GUI Button (Teleports to 'Gift' models)")
print("🟢 Teleport Now: GUI Button (Instant teleport)")
print("🟢 Drag sliders to adjust speeds")
print("🟢 Drag the title bar to move GUI")
print("")
print("🎁 Searching for 'Gift' models...")

-- Find and display presents on load
task.wait(0.5)
local airdrops = findAirdrops()
if #airdrops > 0 then
    print("✅ Found " .. #airdrops .. " presents/airdrops!")
    for i, p in ipairs(airdrops) do
        print("  " .. i .. ". " .. p.Name .. " (" .. p.ClassName .. ")")
    end
else
    print("⚠️ No 'Gift' models found. Make sure they exist in the game.")
end