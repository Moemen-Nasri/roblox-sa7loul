-- sa7loul | Survive the Killer V2
-- Support version v2.31.0

local configs = {
    savedConfigs = {},
    currentConfigName = "Default"
}

local defaultSettings = {
    Speed = 16, 
    speedEnabled = false,
    speedDisableOnDown = true,
    Fly = false, 
    flySpeed = 50,
    Noclip = false,
    DoubleJump = false,
    KillerChanceX3 = false,
    ESP = false,
    ESPExits = false,
    ESPTraps = false,
    NoFog = false,
    Fullbright = false,
    AutoLoot = false,
    returnHomeAfterLoot = true,
    KillAura = false,
    killAuraRadius = 10,
    AutoReviveLegit = false,
    AutoReviveRisky = false,
    AutoReviveSelf = false,
    selfReviveCooldown = 7,
    selfReviveMode = "Random",
    AutoEscape = false,
    AntiAFK = false,
    AntiTrap = false,
    PanicTP = false
}

local userScripts = {}

local function LoadUserScripts()
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile("sa7loul_Scripts.json"))
    end)
    if success and data then
        userScripts = data
    end
end

local function SaveUserScripts()
    pcall(function()
        writefile("sa7loul_Scripts.json", game:GetService("HttpService"):JSONEncode(userScripts))
    end)
end

LoadUserScripts()

local more_scripts = {
    {
        name = "sa7loul V1.4",
        script = "loadstring(game:HttpGet('https://raw.githubusercontent.com/AuriXDev/VHubs/refs/heads/main/old/STK_V1_4.lua'))()"
    },
    {
        name = "Infinite Yield",
        script = "loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()"
    }
}

local lp = game:FindService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- DESIGN COLORS — soft rose & teal palette
local ACCENT = Color3.fromRGB(255, 94, 148)      -- soft rose
local ACCENT_DARK = Color3.fromRGB(196, 60, 106)
local TEAL = Color3.fromRGB(61, 224, 200)
local BG_MAIN = Color3.fromRGB(13, 14, 20)
local BG_PANEL = Color3.fromRGB(19, 20, 30)
local BG_ELEMENT = Color3.fromRGB(28, 30, 44)
local BG_HOVER = Color3.fromRGB(40, 43, 62)
local TEXT_PRIMARY = Color3.fromRGB(248, 248, 252)
local TEXT_SECONDARY = Color3.fromRGB(165, 168, 190)
local TEXT_DIM = Color3.fromRGB(95, 98, 125)
local BORDER_COLOR = Color3.fromRGB(40, 42, 62)

local function notif(str, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "⏤ sa7loul V2",
            Text = str,
            Duration = dur or 3
        })
    end)
end

local settings = {}
for k, v in pairs(defaultSettings) do
    settings[k] = v
end

local spinActive = false
local spinSpeed = 20
local bringActive = false
local bringAllActive = false
local FlingActive = false
local viewing = nil
local viewDied = nil
local viewChanged = nil
local flyConnection = nil
local noclipConnection = nil
local brightLoop = nil
local lootConnection = nil
local killAuraConnection = nil
local reviveLegitConnection = nil
local selfReviveConnection = nil
local autoEscapeConnection = nil
local noFogConnection = nil
local antiAFKConnection = nil
local antiTrapConnection = nil
local panicTPConnection = nil
local espObjects = {}
local espExitObjects = {}
local espTrapObjects = {}
local savedHomePosition = nil
local isReviving = false
local lastSelfReviveTime = 0
local espCache = {}
local CurrentTab = "About"
local lastEscapeTime = 0
local timerActive = false
local panicTPCooldown = 0
local playerListCache = {}
local playerListContainer = nil
local selectedPlayer = nil
local selectedPlayerLabel = nil
local bringOrigins = {}
local flyFx = {}
local voiceFx = {active = false, hub = nil, saved = {}}
local invisActive = false
local invisConn = nil
local invisSaved = {}
local adminRemotesCache = nil
local unpack2 = table.unpack or unpack

local function AddPressAnim(btn)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = btn.Size - UDim2.new(0.01, 0, 0.01, 0)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {Size = btn.Size + UDim2.new(0.01, 0, 0.01, 0)}):Play()
    end)
end

local function GetSelectedPlayer()
    if selectedPlayer and selectedPlayer.Parent then return selectedPlayer end
    return nil
end

local function SetSelectedPlayer(player)
    selectedPlayer = player
    if selectedPlayerLabel then
        if GetSelectedPlayer() then
            selectedPlayerLabel.Text = "👤 Player: " .. selectedPlayer.Name
        else
            selectedPlayerLabel.Text = "👤 Player: None"
        end
    end
end

local function CyclePlayer()
    local players = game.Players:GetPlayers()
    if #players == 0 then
        SetSelectedPlayer(nil)
        return
    end
    if not GetSelectedPlayer() then
        SetSelectedPlayer(players[1])
    else
        for i, p in ipairs(players) do
            if p == selectedPlayer then
                SetSelectedPlayer(players[i % #players + 1])
                break
            end
        end
    end
end

local function GetPlayerByName(name)
    local found = nil
    local lowerName = name:lower()
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player.Name:lower():sub(1, #lowerName) == lowerName or player.DisplayName:lower():sub(1, #lowerName) == lowerName then
            found = player
            break
        end
    end
    return found
end

local function IsPlayerDowned(player)
    if not player or not player.Character then return false end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local bleedOut = rootPart:FindFirstChild("BleedOutHealth")
    return bleedOut and bleedOut.Enabled
end

local function IsPlayerInLobby(player)
    if not player or not player.Team then return false end
    return player.Team.Name:lower() == "lobby" or player.Team.TeamColor == BrickColor.new("White")
end

local function IsSurvivor()
    if not lp.Team then return false end
    local teamName = lp.Team.Name:lower()
    if teamName == "lobby" or teamName == "spectator" or lp.Team.TeamColor == BrickColor.new("White") then
        return false
    end
    local isKiller = (lp.Team and lp.Team.TeamColor == BrickColor.new("Really red")) or false
    return not isKiller
end

local function GetPlayerTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

local function FindMap()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:FindFirstChild("LootSpawns") or child:FindFirstChild("ExitGateways") or child:FindFirstChild("Exits") then
            return child
        end
    end
    return nil
end

local function StartBring(targetName)
    local target = GetPlayerByName(targetName)
    if not (target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then
        notif("Player not found", 2)
        return
    end
    if bringActive then StopBring() end
    bringActive = true
    notif("Bringing: " .. target.Name, 2)
    
    coroutine.wrap(function()
        local bp = nil
        local hum = nil
        local originSaved = false
        
        local function SaveOrigin()
            if not bringOrigins[target] and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local save = {root = target.Character.HumanoidRootPart.CFrame, parts = {}}
                for _, part in ipairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then save.parts[part] = part.CFrame end
                end
                bringOrigins[target] = save
            end
        end
        
        while bringActive and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") do
            local targetRoot = target.Character.HumanoidRootPart
            local myRoot = lp.Character.HumanoidRootPart
            
            if not originSaved then
                SaveOrigin()
                originSaved = true
            end
            
            if not bp or bp.Parent ~= targetRoot then
                if bp and bp.Parent then bp:Destroy() end
                bp = Instance.new("BodyPosition")
                bp.Name = "BringHold"
                bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bp.P = 60000
                bp.D = 5000
                bp.Position = targetRoot.Position
                bp.Parent = targetRoot
            end
            
            hum = target.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = true end
            
            local targetPos = myRoot.Position + (myRoot.CFrame.LookVector * 4)
            targetPos = Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z)
            bp.Position = targetPos
            
            RunService.RenderStepped:Wait()
        end
        
        if bp and bp.Parent then bp:Destroy() end
        if hum then hum.PlatformStand = false end
        bringActive = false
        notif("Bring stopped", 2)
    end)()
end

local function StopBring()
    bringActive = false
    notif("Bring stopped", 2)
end

local function StartView(targetName)
    local target = GetPlayerByName(targetName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        if viewDied then viewDied:Disconnect() end
        if viewChanged then viewChanged:Disconnect() end
        
        viewing = target
        workspace.CurrentCamera.CameraSubject = viewing.Character
        notif("Watching: " .. target.Name, 2)
        
        viewDied = target.CharacterAdded:Connect(function()
            repeat task.wait() until target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            workspace.CurrentCamera.CameraSubject = target.Character
        end)
        
        viewChanged = workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
            if viewing and viewing.Character then
                workspace.CurrentCamera.CameraSubject = viewing.Character
            end
        end)
    else
        notif("Player not found", 2)
    end
end

local function StopView()
    if viewing then
        viewing = nil
        notif("View stopped", 2)
    end
    if viewDied then viewDied:Disconnect(); viewDied = nil end
    if viewChanged then viewChanged:Disconnect(); viewChanged = nil end
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        workspace.CurrentCamera.CameraSubject = lp.Character.Humanoid
    end
end

local function FreezePlayer(name)
    local target = GetPlayerByName(name)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local root = target.Character.HumanoidRootPart
        if not root:FindFirstChild("FreezeHold") then
            local bp = Instance.new("BodyPosition")
            bp.Name = "FreezeHold"
            bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bp.P = 60000
            bp.D = 10000
            bp.Position = root.Position
            bp.Parent = root
        end
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
        for _, part in pairs(target.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.Anchored = true end
        end
        notif("Frozen: " .. target.Name, 2)
    else
        notif("Player not found", 2)
    end
end

local function ThawPlayer(name)
    local target = GetPlayerByName(name)
    if target and target.Character then
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local hold = root:FindFirstChild("FreezeHold")
            if hold then hold:Destroy() end
        end
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        for _, part in pairs(target.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.Anchored = false end
        end
        notif("Unfrozen: " .. target.Name, 2)
    else
        notif("Player not found", 2)
    end
end

local function SetSettingsAttribute(name, value)
    if not lp then return end
    local settingsFolder = lp:FindFirstChild("Settings")
    if not settingsFolder then
        settingsFolder = Instance.new("Folder")
        settingsFolder.Name = "Settings"
        settingsFolder.Parent = lp
    end
    settingsFolder:SetAttribute(name, value)
end

local function UpdateDoubleJump()
    SetSettingsAttribute("double_jump", settings.DoubleJump)
end

local function UpdateKillerChance()
    SetSettingsAttribute("killer_chance_3x", settings.KillerChanceX3)
end

local function UpdateFly()
    if settings.Fly then
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = RunService.RenderStepped:Connect(function()
            if not settings.Fly or not lp.Character then return end
            local root = lp.Character.HumanoidRootPart
            if not root then return end
            local bg = root:FindFirstChild("BodyGyro") or Instance.new("BodyGyro")
            local bv = root:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
            bg.P = 9e4; bg.Parent = root; bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = root.CFrame
            bv.Parent = root; bv.MaxForce = Vector3.new(9e9,9e9,9e9); bv.Velocity = Vector3.new(0,0,0)
            lp.Character.Humanoid.PlatformStand = true
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0,-1,0) end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            local cam = workspace.CurrentCamera
            bv.Velocity = (cam.CFrame.LookVector * moveDir.Z + cam.CFrame.RightVector * moveDir.X + cam.CFrame.UpVector * moveDir.Y) * settings.flySpeed
            bg.CFrame = cam.CFrame
        end)
    else
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local root = lp.Character.HumanoidRootPart
            local bg = root:FindFirstChild("BodyGyro"); if bg then bg:Destroy() end
            local bv = root:FindFirstChild("BodyVelocity"); if bv then bv:Destroy() end
            lp.Character.Humanoid.PlatformStand = false
        end
    end
end

local function UpdateESP()
    if not settings.ESP then
        for _, obj in pairs(espObjects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        espObjects = {}
        espCache = {}
        return
    end

    local currentPlayers = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp then
            local color = GetPlayerTeamColor(player)
            local hasChar = player.Character ~= nil and player.Character:FindFirstChild("HumanoidRootPart") ~= nil
            currentPlayers[player.Name] = {team = color, hasChar = hasChar}
        end
    end
    
    local needUpdate = false
    for name, data in pairs(currentPlayers) do
        if not espCache[name] or espCache[name].team ~= data.team or espCache[name].hasChar ~= data.hasChar then
            needUpdate = true
            break
        end
    end
    for name in pairs(espCache) do
        if not currentPlayers[name] then
            needUpdate = true
            break
        end
    end
    
    if not needUpdate then return end
    espCache = currentPlayers
    
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    espObjects = {}

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local color = GetPlayerTeamColor(player)
            local highlight = Instance.new("Highlight")
            highlight.Adornee = player.Character
            highlight.FillTransparency = 1
            highlight.OutlineColor = color
            highlight.OutlineTransparency = 0.3
            highlight.Parent = player.Character
            table.insert(espObjects, highlight)
        end
    end
end

local function UpdateESPExits()
    for _, obj in pairs(espExitObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    espExitObjects = {}
    
    if not settings.ESPExits then return end
    
    local map = FindMap()
    if not map then return end
    
    local exitsFolder = map:FindFirstChild("Exits")
    if not exitsFolder then
        exitsFolder = map:FindFirstChild("ExitGateways")
        if not exitsFolder then return end
    end
    
    local isTimerActive = false
    local playerGui = lp:FindFirstChild("PlayerGui")
    if playerGui then
        local topBar = playerGui:FindFirstChild("TopBar")
        if topBar then
            local roundTimer = topBar:FindFirstChild("RoundTimer")
            if roundTimer then
                local extra = roundTimer:FindFirstChild("Extra")
                if extra then
                    local gradient = extra:FindFirstChild("Gradient")
                    if gradient then
                        local uiGradient = gradient:FindFirstChild("UIGradient")
                        if not uiGradient then
                            uiGradient = gradient:FindFirstChild("UI Gradient")
                        end
                        if uiGradient then
                            local color = uiGradient.Color
                            if color and color.Keypoints then
                                for _, keypoint in ipairs(color.Keypoints) do
                                    local c = keypoint.Value
                                    local r = math.round(c.R * 10) / 10
                                    local g = math.round(c.G * 10) / 10
                                    local b = math.round(c.B * 10) / 10
                                    if not (r == 0 and g == 0 and b == 0) then
                                        isTimerActive = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    local fillColor = isTimerActive and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 180, 60)
    local outlineColor = isTimerActive and Color3.fromRGB(60, 220, 100) or Color3.fromRGB(220, 150, 40)
    
    for _, gateway in ipairs(exitsFolder:GetChildren()) do
        if gateway.Name == "ExitGateway" or gateway:IsA("Model") then
            local doorway = gateway:FindFirstChild("Doorway")
            if doorway then
                for _, part in ipairs(doorway:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local highlight = Instance.new("Highlight")
                        highlight.Adornee = part
                        highlight.FillColor = fillColor
                        highlight.FillTransparency = 0.4
                        highlight.OutlineColor = outlineColor
                        highlight.OutlineTransparency = 0.2
                        highlight.Parent = part
                        table.insert(espExitObjects, highlight)
                    end
                end
                
                local doorwayHighlight = Instance.new("Highlight")
                doorwayHighlight.Adornee = doorway
                doorwayHighlight.FillColor = fillColor
                doorwayHighlight.FillTransparency = 0.1
                doorwayHighlight.OutlineColor = outlineColor
                doorwayHighlight.OutlineTransparency = 0.4
                doorwayHighlight.Parent = doorway
                table.insert(espExitObjects, doorwayHighlight)
            end
        end
    end
end

local function UpdateESPTraps()
    for _, obj in pairs(espTrapObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    espTrapObjects = {}
    
    if not settings.ESPTraps then return end
    
    local traps = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Trap" then
            table.insert(traps, child)
        end
    end
    
    if #traps == 0 then return end
    
    local fillColor = Color3.fromRGB(255, 100, 80)
    local outlineColor = Color3.fromRGB(220, 70, 50)
    
    for _, trap in ipairs(traps) do
        local highlight = Instance.new("Highlight")
        highlight.Adornee = trap
        highlight.FillColor = fillColor
        highlight.FillTransparency = 0.3
        highlight.OutlineColor = outlineColor
        highlight.OutlineTransparency = 0.3
        highlight.Parent = trap
        table.insert(espTrapObjects, highlight)
        
        for _, part in ipairs(trap:GetDescendants()) do
            if part:IsA("BasePart") then
                local partHighlight = Instance.new("Highlight")
                partHighlight.Adornee = part
                partHighlight.FillColor = fillColor
                partHighlight.FillTransparency = 0.5
                partHighlight.OutlineColor = outlineColor
                partHighlight.OutlineTransparency = 0.2
                partHighlight.Parent = part
                table.insert(espTrapObjects, partHighlight)
            end
        end
    end
end

local function RemoveTraps()
    local traps = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "Trap" then
            table.insert(traps, child)
        end
    end
    
    for _, trap in ipairs(traps) do
        local trigger = trap:FindFirstChild("HitBox")
        if trigger then
            pcall(function()
                trigger:Destroy()
            end)
        end
    end
end

local function TeleportToExit()
    local map = FindMap()
    if not map then
        for _, child in ipairs(workspace:GetChildren()) do
            if child:FindFirstChild("Exits") or child:FindFirstChild("ExitGateways") then
                map = child
                break
            end
        end
    end
    if not map then
        notif("Map not found!", 2)
        return false
    end
    
    local exitPosition = nil
    
    local exitsFolder = map:FindFirstChild("Exits")
    if exitsFolder then
        for _, gateway in ipairs(exitsFolder:GetChildren()) do
            if gateway.Name == "ExitGateway" then
                local trigger = gateway:FindFirstChild("Trigger")
                if trigger and trigger:IsA("BasePart") then
                    exitPosition = trigger.Position
                    break
                end
            end
        end
    end
    
    if not exitPosition then
        local exits = map:FindFirstChild("ExitGateways")
        if exits then
            for _, gateway in ipairs(exits:GetChildren()) do
                local trigger = gateway:FindFirstChild("Trigger")
                if trigger and trigger:IsA("BasePart") then
                    exitPosition = trigger.Position
                    break
                end
            end
        end
    end
    
    if not exitPosition then
        for _, child in ipairs(workspace:GetChildren()) do
            local trigger = child:FindFirstChild("Trigger")
            if trigger and trigger:IsA("BasePart") then
                exitPosition = trigger.Position
                break
            end
        end
    end
    
    if not exitPosition then
        notif("Exit not found!", 2)
        return false
    end
    
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = CFrame.new(exitPosition + Vector3.new(0, 3, 0))
        notif("Teleported to exit!", 2)
        return true
    else
        notif("Character not found!", 2)
        return false
    end
end

local function CheckTimerColors()
    local playerGui = lp:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local topBar = playerGui:FindFirstChild("TopBar")
    if not topBar then return false end
    
    local roundTimer = topBar:FindFirstChild("RoundTimer")
    if not roundTimer then return false end
    
    local extra = roundTimer:FindFirstChild("Extra")
    if not extra then return false end
    
    local gradient = extra:FindFirstChild("Gradient")
    if not gradient then return false end
    
    local uiGradient = gradient:FindFirstChild("UIGradient")
    if not uiGradient then
        uiGradient = gradient:FindFirstChild("UI Gradient")
    end
    if not uiGradient then return false end
    
    local color = uiGradient.Color
    if not color then return false end
    
    if color.Keypoints then
        for _, keypoint in ipairs(color.Keypoints) do
            local c = keypoint.Value
            local r = math.round(c.R * 10) / 10
            local g = math.round(c.G * 10) / 10
            local b = math.round(c.B * 10) / 10
            if not (r == 0 and g == 0 and b == 0) then
                return true
            end
        end
    end
    
    return false
end

local function AutoEscapeLoop()
    if not settings.AutoEscape then return end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    
    if not IsSurvivor() then return end
    
    if tick() - lastEscapeTime < 1 then return end
    
    local wasTimerActive = timerActive
    timerActive = CheckTimerColors()
    
    if timerActive ~= wasTimerActive then
        UpdateESPExits()
    end
    
    if timerActive then
        TeleportToExit()
        lastEscapeTime = tick()
    end
end

local function CheckPanicTP()
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    if tick() - panicTPCooldown < 3 then return end
    
    local playerGui = lp:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local gameHUD = playerGui:FindFirstChild("GameHUD")
    if not gameHUD then return end
    
    local spottedEye = gameHUD:FindFirstChild("SpottedEye")
    if not spottedEye then return end
    
    if spottedEye.Visible == true then
        local lootPositions = {}
        local myPos = lp.Character.HumanoidRootPart.Position
        
        local map = nil
        for _, child in ipairs(workspace:GetChildren()) do
            if child:FindFirstChild("LootSpawns") then
                map = child
                break
            end
        end
        
        if map then
            local lootFolder = map:FindFirstChild("LootSpawns")
            if lootFolder then
                for _, child in ipairs(lootFolder:GetChildren()) do
                    if child:IsA("BasePart") then
                        table.insert(lootPositions, child.Position)
                    end
                end
            end
        end
        
        if #lootPositions == 0 then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower():find("loot") then
                    table.insert(lootPositions, obj.Position)
                end
            end
        end
        
        if #lootPositions > 0 then
            local farthestLoot = nil
            local farthestDist = -math.huge
            
            for _, pos in ipairs(lootPositions) do
                local dist = (pos - myPos).Magnitude
                if dist > farthestDist then
                    farthestDist = dist
                    farthestLoot = pos
                end
            end
            
            if farthestLoot then
                lp.Character.HumanoidRootPart.CFrame = CFrame.new(farthestLoot + Vector3.new(0, 3, 0))
                panicTPCooldown = tick()
                notif("Panic TP: Teleported to farthest loot!", 2)
            end
        end
    end
end

local function KillAuraLoop()
    local isKiller = (lp.Team and lp.Team.TeamColor == BrickColor.new("Really red")) or false
    if not isKiller then return end

    local closest = nil
    local minDist = math.huge
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local bleedOut = player.Character.HumanoidRootPart:FindFirstChild("BleedOutHealth")
                if not bleedOut or not bleedOut.Enabled then
                    local dist = (player.Character.HumanoidRootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDist and dist <= settings.killAuraRadius then
                        minDist = dist
                        closest = player
                    end
                end
            end
        end
    end

    if closest then
        local forward = lp.Character.HumanoidRootPart.CFrame.LookVector
        closest.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + (forward * 3)
        task.wait(0.05)
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, Enum.UserInputType.MouseButton1, 0)
        task.wait()
        vim:SendMouseButtonEvent(0, 0, 0, false, Enum.UserInputType.MouseButton1, 0)
    end
end

local function StartBringAll()
    if bringAllActive then StopBringAll() end
    bringAllActive = true
    notif("Bring All: bringing everyone", 2)
    
    coroutine.wrap(function()
        local drags = {}
        while bringAllActive and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") do
            local myRoot = lp.Character.HumanoidRootPart
            local alive = {}
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    table.insert(alive, player)
                end
            end
            
            for i, player in ipairs(alive) do
                local root = player.Character.HumanoidRootPart
                
                if not bringOrigins[player] then
                    local save = {root = root.CFrame, parts = {}}
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then save.parts[part] = part.CFrame end
                    end
                    bringOrigins[player] = save
                end
                
                local bp = drags[player]
                if not bp or not bp.Parent or bp.Parent ~= root then
                    if bp and bp.Parent then bp:Destroy() end
                    bp = Instance.new("BodyPosition")
                    bp.Name = "BringAllHold"
                    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bp.P = 40000
                    bp.D = 8000
                    bp.Position = root.Position
                    bp.Parent = root
                    drags[player] = bp
                end
                
                local angle = ((i - 1) / #alive) * math.pi * 2
                local offset = Vector3.new(math.cos(angle) * 6, 0, math.sin(angle) * 6)
                local targetPos = myRoot.Position + offset
                local delta = targetPos - root.Position
                if delta.Magnitude > 4 then delta = delta.Unit * 4 end
                bp.Position = targetPos
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part ~= root then
                        part.Anchored = true
                        part.CFrame = part.CFrame + delta
                    end
                end
                root.Anchored = true
                root.CFrame = CFrame.new(targetPos)
                root.AssemblyLinearVelocity = Vector3.zero
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = true end
            end
            
            RunService.RenderStepped:Wait()
        end
        
        for player, bp in pairs(drags) do
            if bp and bp.Parent then bp:Destroy() end
            if player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
            end
        end
        bringAllActive = false
        notif("Bring All stopped", 2)
    end)()
end

local function StopBringAll()
    bringAllActive = false
end

local function UnbringPlayer(player)
    local save = bringOrigins[player]
    if save then
        bringOrigins[player] = nil
        local ok = pcall(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local root = player.Character.HumanoidRootPart
                if root:FindFirstChild("BringHold") then
                    root.BringHold:Destroy()
                end
                if root:FindFirstChild("BringAllHold") then
                    root.BringAllHold:Destroy()
                end
                local bp = Instance.new("BodyPosition")
                bp.Name = "UnbringTP"
                bp.P = 9e9
                bp.D = 2e4
                bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bp.Position = save.root.Position
                bp.Parent = root
                task.wait(0.2)
                if bp.Parent then bp:Destroy() end
            end
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end)
        if ok then return true end
    end
    return false
end

local function UnbringSelected()
    if bringActive then StopBring() end
    if bringAllActive then StopBringAll() end
    task.wait(0.15)
    local restored = 0
    for player, _ in pairs(bringOrigins) do
        if UnbringPlayer(player) then restored = restored + 1 end
    end
    if restored > 0 then
        notif("Unbrought " .. restored .. " player(s)", 2)
    else
        notif("Nothing to unbring", 2)
    end
end

local function ScanAdminRemotes()
    if adminRemotesCache then return adminRemotesCache end
    adminRemotesCache = {}
    local roots = {game:GetService("ReplicatedStorage"), workspace:FindFirstChild("ServerStorage"), game:GetService("ServerScriptService")}
    for _, root in ipairs(roots) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                    local n = string.lower(obj.Name)
                    if n:match("fly") or n:match("noclip") or n:match("admin") or n:match("command")
                        or n:match("^cmd") or n:match("perm") or n:match("panel") or n:match("give") or n:match("staff") then
                        table.insert(adminRemotesCache, obj)
                    end
                end
            end
        end
    end
    return adminRemotesCache
end

local function TryFireAdminRemote(target)
    local remotes = ScanAdminRemotes()
    if #remotes == 0 then return false end
    local payloads = {
        {"fly", true}, {"noclip", true},
        {"fly", target.Name}, {"noclip", target.Name},
        {"fly", target.Name, true}, {"noclip", target.Name, true},
        {"fly", target}, {"noclip", target},
        {"fly", target.UserId, true}, {"noclip", target.UserId, true},
        {"Fly", target.Name}, {"Noclip", target.Name},
        {"givefly", target.Name}, {"givenoclip", target.Name},
        {"Fly", target}, {"Noclip", target}
    }
    for _, remote in ipairs(remotes) do
        for _, args in ipairs(payloads) do
            local fired = pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer(unpack2(args))
                else
                    remote:FireServer(unpack2(args))
                end
            end)
            if fired then return true end
        end
        local firedRaw = pcall(function()
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer(target)
            else
                remote:FireServer(target)
            end
        end)
        if firedRaw then return true end
    end
    return false
end

local function GiveFlyNoClip()
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
        notif("No character", 2)
        return
    end
    local fx = flyFx[lp]
    if fx then
        if fx.connection then fx.connection:Disconnect() end
        if lp.Character then
            for _, part in ipairs(lp.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
        flyFx[lp] = nil
        notif("Fly+NoClip OFF", 2)
        return
    end
    
    local speed = settings.flySpeed or 50
    local conn = RunService.RenderStepped:Connect(function(dt)
        local chr = lp.Character
        if not (chr and chr:FindFirstChild("HumanoidRootPart")) then return end
        local root = chr.HumanoidRootPart
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0, -1, 0) end
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * speed * dt
            root.CFrame = root.CFrame + moveDir
        end
        root.AssemblyLinearVelocity = Vector3.zero
        for _, part in ipairs(chr:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        local hum = chr:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
    end)
    flyFx[lp] = {connection = conn}
    notif("Fly+NoClip ON (WASD + Space/LCtrl)", 2)
end

local function ToggleMicBypass()
    local lpPlayer = lp
    if not lpPlayer then return end
    if voiceFx.active then
        for _, w in ipairs(voiceFx.saved) do
            pcall(function()
                if w and w.Wire and not w.Wire.Parent and w.OriginalParent then
                    w.Wire.Parent = w.OriginalParent
                end
            end)
        end
        if voiceFx.hub and voiceFx.hub.Parent then
            pcall(function() voiceFx.hub:Destroy() end)
        end
        voiceFx = {}
        notif("Mic Bypass OFF", 2)
        return
    end
    
    local ok, enabled = pcall(function()
        return game:GetService("VoiceChatService"):IsVoiceEnabledForUserIdAsync(lpPlayer.UserId)
    end)
    if not ok or not enabled then
        notif("Voice chat not enabled on your account", 3)
        return
    end
    
    for i = 1, 3 do
        pcall(function() game:GetService("VoiceChatService"):joinVoice() end)
        task.wait(0.1)
    end
    
    local input = nil
    for _, root in ipairs({lpPlayer, lpPlayer.Character, workspace, game:GetService("CoreGui")}) do
        if root and not input then
            input = root:FindFirstChildOfClass("AudioDeviceInput")
        end
    end
    if not input then
        local created
        created, input = pcall(function()
            local i = Instance.new("AudioDeviceInput")
            i.Name = "Sa7loulMic"
            i.Parent = lpPlayer
            return i
        end)
        if not created or not input then
            voiceFx = {active = true, hub = nil, saved = {}}
            notif("Mic Bypass ON (reconnect only)", 3)
            return
        end
    end
    pcall(function() input.Player = lpPlayer end)
    
    local saved = {}
    for _, w in ipairs(lpPlayer:GetDescendants()) do
        if w:IsA("Wire") and w.SourceInstance == input then
            table.insert(saved, {Wire = w, OriginalParent = w.Parent})
            w.Parent = nil
        end
    end
    
    if lpPlayer.Character and lpPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = lpPlayer.Character.HumanoidRootPart
        local hub = Instance.new("Part")
        hub.Name = "VoiceHub"
        hub.Size = Vector3.new(1, 1, 1)
        hub.Transparency = 1
        hub.CanCollide = false
        hub.Anchored = false
        hub.Parent = root
        local motor = Instance.new("Motor6D")
        motor.Part0 = root
        motor.Part1 = hub
        motor.C0 = CFrame.new(0, 0, 0)
        motor.Parent = root
        
        local source = input
        local pitchOk, pitch = pcall(function()
            local p = Instance.new("AudioPitchShifter")
            p.Name = "Sa7loulPitch"
            p.Pitch = 1.4
            p.Parent = hub
            return p
        end)
        if pitchOk and pitch then
            local w1 = Instance.new("Wire")
            w1.Name = "Sa7loulW1"
            w1.SourceInstance = source
            w1.TargetInstance = pitch
            w1.Parent = hub
            source = pitch
        end
        local emitter = Instance.new("AudioEmitter")
        emitter.Name = "Sa7loulEmitter"
        emitter.Parent = hub
        local w2 = Instance.new("Wire")
        w2.Name = "Sa7loulW2"
        w2.SourceInstance = source
        w2.TargetInstance = emitter
        w2.Parent = hub
        
        voiceFx = {hub = hub, saved = saved, active = true}
        notif("🎤 Mic Bypass ON", 2)
    else
        notif("No character — enter a game first", 2)
    end
end

local function ScanUnbanRemotes()
    local remotes = {}
    local roots = {game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), workspace:FindFirstChild("ServerStorage")}
    for _, root in ipairs(roots) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local n = string.lower(obj.Name)
                    if n:match("ban") or n:match("unban") or n:match("kick") or n:match("mod")
                        or n:match("whitelist") or n:match("admin") or n:match("panel") or n:match("command") then
                        table.insert(remotes, obj)
                    end
                end
            end
        end
    end
    return remotes
end

local function TryUnban()
    local remotes = ScanUnbanRemotes()
    if #remotes == 0 then
        notif("No admin/ban remotes found", 2)
        return
    end
    local payloads = {
        {"unban", lp.UserId}, {"unban", lp.Name},
        {"unban", lp.UserId, true}, {"unban", lp.Name, true},
        {"Unban", lp.UserId}, {"Unban", lp.Name},
        {"unban", lp}, {"whitelist", lp.UserId}, {"whitelist", lp.Name},
        {"unban", lp.UserId, "0"}
    }
    local hits = 0
    for _, remote in ipairs(remotes) do
        for _, args in ipairs(payloads) do
            local fired = pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer(unpack2(args))
                else
                    remote:FireServer(unpack2(args))
                end
            end)
            if fired then hits = hits + 1 end
        end
        local raw = pcall(function()
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer(lp)
            else
                remote:FireServer(lp)
            end
        end)
        if raw then hits = hits + 1 end
    end
    notif("Unban attempts fired: " .. hits, 2)
end

local function RejoinFresh()
    notif("Rejoining...", 2)
    task.wait(0.5)
    local ok = pcall(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end)
    if not ok then
        pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
    end
end

local function isKillerNearby(position, radius)
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local isKiller = (player.Team and player.Team.TeamColor == BrickColor.new("Really red")) or false
            if isKiller then
                local dist = (player.Character.HumanoidRootPart.Position - position).Magnitude
                if dist <= radius then
                    return true
                end
            end
        end
    end
    return false
end

local function AutoReviveLegitLoop()
    if not settings.AutoReviveLegit then return end
    if isReviving then return end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = lp.Character.HumanoidRootPart
    local myBleedOut = myRoot:FindFirstChild("BleedOutHealth")
    if myBleedOut and myBleedOut.Enabled then return end
    
    if lp.Team then
        local teamName = lp.Team.Name:lower()
        if teamName == "lobby" or teamName == "spectator" or lp.Team.TeamColor == BrickColor.new("White") then
            return
        end
    end

    local closest = nil
    local minDist = math.huge
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local bleedOut = rootPart:FindFirstChild("BleedOutHealth")
                if bleedOut and bleedOut.Enabled then
                    local dist = (rootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = {player = player, rootPart = rootPart, bleedOut = bleedOut}
                    end
                end
            end
        end
    end
    
    if closest then
        if isKillerNearby(closest.rootPart.Position, 15) then
            return
        end
        
        isReviving = true
        local myHomePos = lp.Character.HumanoidRootPart.CFrame
        
        local wasFlying = settings.Fly
        local wasNoclip = settings.Noclip
        if wasFlying then settings.Fly = false; UpdateFly() end
        if wasNoclip then settings.Noclip = false; if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end end
        
        local forward = closest.rootPart.CFrame.LookVector
        lp.Character.HumanoidRootPart.CFrame = closest.rootPart.CFrame + (forward * 2)
        task.wait(0.1)
        
        notif("Reviving: " .. closest.player.Name, 2)
        
        local bleedOut = closest.bleedOut
        local startTime = tick()
        while bleedOut and bleedOut.Enabled and (tick() - startTime) <= 15 do
            task.wait(0.5)
        end
        
        if bleedOut and not bleedOut.Enabled then
            notif(closest.player.Name .. " revived!", 2)
        else
            notif("Revive time ended for " .. closest.player.Name, 2)
        end
        
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = myHomePos
            notif("Returned home", 2)
        end
        
        if wasFlying then settings.Fly = true; UpdateFly() end
        if wasNoclip then settings.Noclip = true; 
            if noclipConnection then noclipConnection:Disconnect() end
            noclipConnection = RunService.Stepped:Connect(function()
                if settings.Noclip and lp.Character then
                    for _, part in pairs(lp.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        end
        
        isReviving = false
    end
end

local function AutoReviveRiskyOneUse()
    if isReviving then return end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then 
        notif("You need a character!", 2)
        return 
    end
    
    local myRoot = lp.Character.HumanoidRootPart
    local myBleedOut = myRoot:FindFirstChild("BleedOutHealth")
    if myBleedOut and myBleedOut.Enabled then
        notif("You are down! Can't revive others.", 2)
        return
    end
    
    if lp.Team then
        local teamName = lp.Team.Name:lower()
        if teamName == "lobby" or teamName == "spectator" or lp.Team.TeamColor == BrickColor.new("White") then
            notif("You are in the lobby!", 2)
            return
        end
    end

    local closest = nil
    local minDist = math.huge
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local bleedOut = rootPart:FindFirstChild("BleedOutHealth")
                if bleedOut and bleedOut.Enabled then
                    if not (player.Team and (player.Team.Name:lower() == "lobby" or player.Team.TeamColor == BrickColor.new("White"))) then
                        local dist = (rootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            closest = {player = player, rootPart = rootPart, bleedOut = bleedOut}
                        end
                    end
                end
            end
        end
    end
    
    if not closest then
        notif("No downed players!", 2)
        return
    end
    
    local killerNearby = false
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local isKiller = (player.Team and player.Team.TeamColor == BrickColor.new("Really red")) or false
            if isKiller then
                local dist = (player.Character.HumanoidRootPart.Position - closest.rootPart.Position).Magnitude
                if dist <= 15 then
                    killerNearby = true
                    break
                end
            end
        end
    end
    
    if killerNearby then
        notif("Killer nearby! Revive cancelled.", 2)
        return
    end
    
    isReviving = true
    local myHomePos = lp.Character.HumanoidRootPart.CFrame
    
    local wasFlying = settings.Fly
    local wasNoclip = settings.Noclip
    if wasFlying then settings.Fly = false; UpdateFly() end
    if wasNoclip then 
        settings.Noclip = false
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    end
    
    local forward = closest.rootPart.CFrame.LookVector
    lp.Character.HumanoidRootPart.CFrame = closest.rootPart.CFrame + (forward * 2)
    task.wait(0.2)
    
    notif("Risky revive: reviving " .. closest.player.Name, 2)
    
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(0.1)
    vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    task.wait(0.3)
    
    if savedHomePosition then
        lp.Character.HumanoidRootPart.CFrame = savedHomePosition + Vector3.new(0, 0, 3)
    else
        lp.Character.HumanoidRootPart.CFrame = myHomePos
    end
    task.wait(0.3)
    
    vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(0.1)
    vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    task.wait(0.2)
    
    notif("Revived " .. closest.player.Name .. " successfully!", 2)
    
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = myHomePos
        notif("Returned home", 2)
    end
    
    if wasFlying then settings.Fly = true; UpdateFly() end
    if wasNoclip then 
        settings.Noclip = true
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if settings.Noclip and lp.Character then
                for _, part in pairs(lp.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
    
    isReviving = false
end

local function AutoReviveSelfLoop()
    if not settings.AutoReviveSelf then return end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    if tick() - lastSelfReviveTime < settings.selfReviveCooldown then return end
    
    local myPos = lp.Character.HumanoidRootPart.Position
    local myBleedOut = lp.Character.HumanoidRootPart:FindFirstChild("BleedOutHealth")
    
    if myBleedOut and myBleedOut.Enabled then
        local target = nil
        
        if settings.selfReviveMode == "Farthest" then
            local farthestDist = -math.huge
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local isKiller = (player.Team and player.Team.TeamColor == BrickColor.new("Really red")) or false
                    if not isKiller and not IsPlayerInLobby(player) and not IsPlayerDowned(player) then
                        local dist = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
                        if dist > farthestDist then
                            farthestDist = dist
                            target = player.Character.HumanoidRootPart
                        end
                    end
                end
            end
        else
            local survivors = {}
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local isKiller = (player.Team and player.Team.TeamColor == BrickColor.new("Really red")) or false
                    if not isKiller and not IsPlayerInLobby(player) and not IsPlayerDowned(player) then
                        table.insert(survivors, player.Character.HumanoidRootPart)
                    end
                end
            end
            if #survivors > 0 then
                target = survivors[math.random(1, #survivors)]
            end
        end
        
        if target then
            lp.Character.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 0, 5)
            lastSelfReviveTime = tick()
            notif("Teleported to a survivor", 2)
        elseif savedHomePosition then
            lp.Character.HumanoidRootPart.CFrame = savedHomePosition
            lastSelfReviveTime = tick()
            notif("Teleported home", 2)
        else
            notif("No valid target", 2)
        end
    end
end

local function UpdateNoFog()
    if settings.NoFog then
        if noFogConnection then noFogConnection:Disconnect() end
        noFogConnection = RunService.Heartbeat:Connect(function()
            if settings.NoFog then
                Lighting.FogEnd = 100000
                for _, v in pairs(Lighting:GetDescendants()) do 
                    if v:IsA("Atmosphere") then v:Destroy() end 
                end
            end
        end)
    else
        if noFogConnection then noFogConnection:Disconnect(); noFogConnection = nil end
        Lighting.FogEnd = 1000
    end
end

local function AutoCollectLoot()
    local map = FindMap()
    if not map then return end
    local lootFolder = map:FindFirstChild("LootSpawns")
    if not lootFolder then return end

    local lootList = {}
    for _, child in ipairs(lootFolder:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(lootList, child)
        end
    end
    if #lootList == 0 then return end

    local myPos = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position or Vector3.new()
    table.sort(lootList, function(a, b)
        return (a.Position - myPos).Magnitude < (b.Position - myPos).Magnitude
    end)

    if savedHomePosition == nil and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        savedHomePosition = lp.Character.HumanoidRootPart.CFrame
        notif("Home position saved", 2)
    end

    for _, lootPart in ipairs(lootList) do
        if not settings.AutoLoot then break end
        if lootPart and lootPart.Parent and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(lootPart.Position + Vector3.new(0, 3, 0))
            task.wait(0.25)
        end
    end
end

local function ReturnToHome()
    if savedHomePosition and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = savedHomePosition
        savedHomePosition = nil
    end
end

local function UpdateSpin(state)
    spinActive = state
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local root = lp.Character.HumanoidRootPart
        local existingSpin = root:FindFirstChild("Spinning")
        if existingSpin then existingSpin:Destroy() end
        
        if state then
            local Spin = Instance.new("BodyAngularVelocity")
            Spin.Name = "Spinning"
            Spin.Parent = root
            Spin.MaxTorque = Vector3.new(0, math.huge, 0)
            Spin.AngularVelocity = Vector3.new(0, spinSpeed, 0)
            notif("Spin: On", 2)
        else
            notif("Spin: Off", 2)
        end
    end
end

local function AddUserScript(name, script)
    if name == "" or script == "" then
        notif("Name and script are required", 2)
        return false
    end
    
    for _, s in ipairs(userScripts) do
        if s.name:lower() == name:lower() then
            notif("Script with the same name exists", 2)
            return false
        end
    end
    
    local valid, err = SafeLoadScript(script)
    if not valid then
        notif("Invalid script: " .. tostring(err), 3)
        return false
    end
    
    table.insert(userScripts, {name = name, script = script})
    SaveUserScripts()
    UpdateRightContent()
    notif("Added: " .. name, 2)
    return true
end

local function RemoveUserScript(index)
    if index > 0 and index <= #userScripts then
        local name = userScripts[index].name
        table.remove(userScripts, index)
        SaveUserScripts()
        UpdateRightContent()
        notif("Deleted: " .. name, 2)
        return true
    end
    return false
end

local function SafeLoadScript(scriptData)
    local success, result = pcall(function()
        return loadstring(scriptData)
    end)
    if success and result then
        local execSuccess, execErr = pcall(result)
        if not execSuccess then
            return false, execErr
        end
        return true, nil
    else
        return false, "Invalid script code"
    end
end

local function SaveConfig(name)
    local configData = {}
    for k, v in pairs(settings) do
        configData[k] = v
    end
    configData.userScripts = userScripts
    
    local configsFolder = "sa7loul_Configs"
    if not isfolder(configsFolder) then
        makefolder(configsFolder)
    end
    
    local success, err = pcall(function()
        writefile(configsFolder .. "/" .. name .. ".json", HttpService:JSONEncode(configData))
    end)
    
    if success then
        notif("Config saved: " .. name, 2)
        return true
    else
        notif("Failed to save config: " .. tostring(err), 3)
        return false
    end
end

local function LoadConfig(name)
    local configsFolder = "sa7loul_Configs"
    if not isfolder(configsFolder) then
        notif("No configs folder", 2)
        return false
    end
    
    local success, data = pcall(function()
        local content = readfile(configsFolder .. "/" .. name .. ".json")
        return HttpService:JSONDecode(content)
    end)
    
    if success and data then
        for k, v in pairs(data) do
            if k ~= "userScripts" then
                settings[k] = v
            end
        end
        
        if data.userScripts then
            userScripts = data.userScripts
            SaveUserScripts()
        end
        
        UpdateAllFeatures()
        notif("Config loaded: " .. name, 2)
        return true
    else
        notif("Failed to load config", 3)
        return false
    end
end

local function GetConfigList()
    local configsFolder = "sa7loul_Configs"
    if not isfolder(configsFolder) then
        makefolder(configsFolder)
        return {}
    end
    
    local files = {}
    for _, file in ipairs(listfiles(configsFolder)) do
        local name = file:match("([^/]+)%.json$")
        if name then
            table.insert(files, name)
        end
    end
    return files
end

local function DeleteConfig(name)
    local configsFolder = "sa7loul_Configs"
    if isfolder(configsFolder) then
        pcall(function()
            delfile(configsFolder .. "/" .. name .. ".json")
            notif("Config deleted: " .. name, 2)
        end)
    end
end

local function UpdateAllFeatures()
    if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = settings.Speed
    end
    
    UpdateFly()
    
    if settings.Noclip then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if settings.Noclip and lp.Character then
                for _, part in pairs(lp.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    end
    
    UpdateDoubleJump()
    UpdateKillerChance()
    espCache = {}
    UpdateESP()
    UpdateESPExits()
    UpdateESPTraps()
    UpdateNoFog()
    
    if settings.Fullbright then
        if brightLoop then brightLoop:Disconnect() end
        brightLoop = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        end)
    else
        if brightLoop then brightLoop:Disconnect(); brightLoop = nil end
    end
    
    if settings.AutoLoot then
        savedHomePosition = nil
        if lootConnection then lootConnection:Disconnect() end
        lootConnection = RunService.Heartbeat:Connect(function()
            if settings.AutoLoot and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                AutoCollectLoot()
            end
        end)
    else
        if lootConnection then lootConnection:Disconnect(); lootConnection = nil end
        if settings.returnHomeAfterLoot then ReturnToHome() else savedHomePosition = nil end
    end
    
    if settings.KillAura then
        if killAuraConnection then killAuraConnection:Disconnect() end
        killAuraConnection = RunService.Heartbeat:Connect(function()
            if settings.KillAura and lp.Character and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0 then
                KillAuraLoop()
            end
        end)
    else
        if killAuraConnection then killAuraConnection:Disconnect(); killAuraConnection = nil end
    end
    
    if settings.AutoReviveLegit then
        if reviveLegitConnection then reviveLegitConnection:Disconnect() end
        reviveLegitConnection = RunService.Heartbeat:Connect(AutoReviveLegitLoop)
    else
        if reviveLegitConnection then reviveLegitConnection:Disconnect(); reviveLegitConnection = nil end
    end
    
    if settings.AutoReviveSelf then
        if selfReviveConnection then selfReviveConnection:Disconnect() end
        selfReviveConnection = RunService.Heartbeat:Connect(AutoReviveSelfLoop)
    else
        if selfReviveConnection then selfReviveConnection:Disconnect(); selfReviveConnection = nil end
    end
    
    if settings.AutoEscape then
        if autoEscapeConnection then autoEscapeConnection:Disconnect() end
        autoEscapeConnection = RunService.Heartbeat:Connect(AutoEscapeLoop)
    else
        if autoEscapeConnection then autoEscapeConnection:Disconnect(); autoEscapeConnection = nil end
    end
    
    if settings.AntiAFK then
        if antiAFKConnection then antiAFKConnection:Disconnect() end
        antiAFKConnection = RunService.Heartbeat:Connect(function()
            if settings.AntiAFK then
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                task.wait(0.05)
                vim:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                task.wait(15)
            end
        end)
    else
        if antiAFKConnection then antiAFKConnection:Disconnect(); antiAFKConnection = nil end
    end
    
    if settings.AntiTrap then
        if antiTrapConnection then antiTrapConnection:Disconnect() end
        antiTrapConnection = RunService.Heartbeat:Connect(function()
            if settings.AntiTrap then
                RemoveTraps()
            end
        end)
    else
        if antiTrapConnection then antiTrapConnection:Disconnect(); antiTrapConnection = nil end
    end
    
    if settings.PanicTP then
        if panicTPConnection then panicTPConnection:Disconnect() end
        panicTPConnection = RunService.Heartbeat:Connect(function()
            if settings.PanicTP then
                CheckPanicTP()
            end
        end)
    else
        if panicTPConnection then panicTPConnection:Disconnect(); panicTPConnection = nil end
    end
end

local lastUpdate = 0
local function PeriodicUpdates()
    if tick() - lastUpdate >= 0.05 then
        lastUpdate = tick()
        if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
            if settings.speedDisableOnDown and lp:GetAttribute("Crawling") == true then
                lp.Character.Humanoid.WalkSpeed = 10
            else
                lp.Character.Humanoid.WalkSpeed = settings.Speed
            end
        end
    end
    PeriodicESPUpdate()
end

local lastESPUpdate = 0
local function PeriodicESPUpdate()
    if tick() - lastESPUpdate >= 0.5 then
        lastESPUpdate = tick()
        UpdateESP()
        UpdateESPExits()
        UpdateESPTraps()
        UpdatePlayerList()
    end
end

-- ============================================================
-- REDESIGNED UI — high quality with animation
-- ============================================================

local h = Instance.new("ScreenGui")
h.Name = "sa7loul_STK"
h.Parent = game:GetService("CoreGui")
h.ResetOnSpawn = false
h.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- MAIN WINDOW
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = h
Main.Active = true
Main.Draggable = true
Main.BackgroundColor3 = BG_MAIN
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, -320, 0.3, 0)
Main.Size = UDim2.new(0, 640, 0, 520)
Main.BackgroundTransparency = 1

-- opening animation
TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0
}):Play()

-- SHADOW
local shadow = Instance.new("Frame")
shadow.Parent = Main
shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
shadow.BorderSizePixel = 0
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundTransparency = 0.7
shadow.ZIndex = -1
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 16)

-- MAIN CORNER
local mainCorner = Instance.new("UICorner", Main)
mainCorner.CornerRadius = UDim.new(0, 14)

-- TOP BAR
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = Main
TopBar.BackgroundColor3 = BG_PANEL
TopBar.BackgroundTransparency = 0
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.ClipsDescendants = true
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 14)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TopBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "✦ sa7loul | STK V2"
TitleLabel.TextColor3 = ACCENT
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextYAlignment = Enum.TextYAlignment.Center

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -42, 0, 8)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = TEXT_SECONDARY
CloseBtn.TextSize = 18
CloseBtn.MouseEnter:Connect(function() 
    TweenService:Create(CloseBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextColor3 = ACCENT}):Play()
end)
CloseBtn.MouseLeave:Connect(function() 
    TweenService:Create(CloseBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextColor3 = TEXT_SECONDARY}):Play()
end)
CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 640, 0, 0),
        Position = UDim2.new(0.5, -320, 0.3, 0)
    }):Play()
    task.wait(0.3)
    h:Destroy()
end)

-- MINIMIZE (shrinks the window instead of hiding)
local minimized = false
local MinimBtn = Instance.new("TextButton")
MinimBtn.Parent = TopBar
MinimBtn.BackgroundTransparency = 1
MinimBtn.Position = UDim2.new(1, -80, 0, 8)
MinimBtn.Size = UDim2.new(0, 30, 0, 30)
MinimBtn.Font = Enum.Font.GothamBold
MinimBtn.Text = "–"
MinimBtn.TextColor3 = TEXT_SECONDARY
MinimBtn.TextSize = 18
MinimBtn.MouseEnter:Connect(function()
    TweenService:Create(MinimBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextColor3 = TEAL}):Play()
end)
MinimBtn.MouseLeave:Connect(function()
    TweenService:Create(MinimBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextColor3 = TEXT_SECONDARY}):Play()
end)
MinimBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        local absPos = Main.AbsolutePosition
        local screen = h.AbsoluteSize
        local minX = math.clamp(absPos.X, 0, screen.X - 230)
        local minY = math.clamp(absPos.Y, 0, screen.Y - 40)
        Main.Position = UDim2.fromOffset(minX, minY)
        Main.Size = UDim2.new(0, 230, 0, 40)
        LeftMenu.Visible = false
        RightContent.Visible = false
        MinimBtn.Size = UDim2.new(1, 0, 1, 0)
        MinimBtn.Position = UDim2.new(0, 0, 0, 0)
        MinimBtn.Text = "✚"
    else
        LeftMenu.Visible = true
        RightContent.Visible = true
        Main.Size = UDim2.new(0, 640, 0, 520)
        MinimBtn.Size = UDim2.new(0, 30, 0, 30)
        MinimBtn.Position = UDim2.new(1, -80, 0, 8)
        MinimBtn.Text = "–"
    end
end)

-- LEFT MENU — redesigned with icons and better spacing
local LeftMenu = Instance.new("ScrollingFrame")
LeftMenu.Name = "LeftMenu"
LeftMenu.Parent = Main
LeftMenu.BackgroundColor3 = BG_PANEL
LeftMenu.BackgroundTransparency = 0.4
LeftMenu.BorderSizePixel = 0
LeftMenu.Position = UDim2.new(0, 0, 0, 48)
LeftMenu.Size = UDim2.new(0, 160, 1, -48)
LeftMenu.ScrollBarThickness = 0
LeftMenu.CanvasSize = UDim2.new(0, 0, 0, 0)
LeftMenu.AutomaticCanvasSize = Enum.AutomaticSize.Y

local menuPadding = Instance.new("UIPadding")
menuPadding.Parent = LeftMenu
menuPadding.PaddingLeft = UDim.new(0, 12)
menuPadding.PaddingTop = UDim.new(0, 12)
Instance.new("UIListLayout", LeftMenu).Padding = UDim.new(0, 4)

-- tab names with icons
local MenuItems = {
    {key = "  About", label = "ℹ️ About"},
    {key = "  Player", label = "🧑 Player"},
    {key = "  World", label = "🌍 World"},
    {key = "  Players", label = "👥 Players"},
    {key = "  Revive", label = "💉 Revive"},
    {key = "  Fun", label = "🎮 Fun"},
    {key = "  More", label = "📦 Extras"},
    {key = "  Settings", label = "⚙️ Settings"}
}
local MenuButtons = {}

for i, item in ipairs(MenuItems) do
    local btn = Instance.new("TextButton")
    btn.Parent = LeftMenu
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, -8, 0, 34)
    btn.LayoutOrder = i
    btn.Font = Enum.Font.GothamBold
    btn.Text = item.label
    btn.TextColor3 = TEXT_SECONDARY
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextYAlignment = Enum.TextYAlignment.Center
    
    local indicator = Instance.new("Frame")
    indicator.Parent = btn
    indicator.BackgroundColor3 = ACCENT
    indicator.BorderSizePixel = 0
    indicator.Size = UDim2.new(0, 4, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.BackgroundTransparency = 1
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)
    indicator.Visible = false
    
    local tabKey = item.key
    btn.MouseButton1Click:Connect(function()
        CurrentTab = tabKey
        for _, b in pairs(MenuButtons) do
            b.TextColor3 = TEXT_SECONDARY
            local ind = b:FindFirstChildWhichIsA("Frame")
            if ind then 
                TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                ind.Visible = false
            end
        end
        btn.TextColor3 = TEXT_PRIMARY
        indicator.Visible = true
        TweenService:Create(indicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        UpdateRightContent()
    end)
    table.insert(MenuButtons, btn)
end

-- activate first tab
local firstBtn = MenuButtons[1]
firstBtn.TextColor3 = TEXT_PRIMARY
local firstInd = firstBtn:FindFirstChildWhichIsA("Frame")
if firstInd then 
    firstInd.Visible = true
    firstInd.BackgroundTransparency = 0
end

-- RIGHT CONTENT
local RightContent = Instance.new("ScrollingFrame")
RightContent.Name = "RightContent"
RightContent.Parent = Main
RightContent.BackgroundColor3 = BG_MAIN
RightContent.BackgroundTransparency = 0.6
RightContent.BorderSizePixel = 0
RightContent.Position = UDim2.new(0, 160, 0, 48)
RightContent.Size = UDim2.new(1, -160, 1, -48)
RightContent.ScrollBarThickness = 4
RightContent.ScrollBarImageColor3 = ACCENT
RightContent.CanvasSize = UDim2.new(0, 0, 0, 0)
RightContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
RightContent.ClipsDescendants = true

local contentPadding = Instance.new("UIPadding")
contentPadding.Parent = RightContent
contentPadding.PaddingLeft = UDim.new(0, 22)
contentPadding.PaddingRight = UDim.new(0, 22)
contentPadding.PaddingTop = UDim.new(0, 14)
contentPadding.PaddingBottom = UDim.new(0, 20)

local ContentLayout = Instance.new("UIListLayout", RightContent)
ContentLayout.Padding = UDim.new(0, 20)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- HELPERS with animations

local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Parent = parent
    section.BackgroundTransparency = 1
    section.Size = UDim2.new(1, 0, 0, 0) 
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.LayoutOrder = #parent:GetChildren()
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = section
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 24)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = ACCENT
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    
    local line = Instance.new("Frame")
    line.Parent = section
    line.BackgroundColor3 = BORDER_COLOR
    line.BorderSizePixel = 0
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0, 26)
    
    local itemsContainer = Instance.new("Frame")
    itemsContainer.Parent = section
    itemsContainer.BackgroundTransparency = 1
    itemsContainer.Position = UDim2.new(0, 0, 0, 32)
    itemsContainer.Size = UDim2.new(1, 0, 0, 0)
    itemsContainer.AutomaticSize = Enum.AutomaticSize.Y
    
    local listLayout = Instance.new("UIListLayout", itemsContainer)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    return itemsContainer
end

local function CreateToggle(parent, text, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.LayoutOrder = #parent:GetChildren()

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT_PRIMARY
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center

    local toggleBg = Instance.new("Frame")
    toggleBg.Parent = frame
    toggleBg.BorderSizePixel = 0
    toggleBg.Position = UDim2.new(1, -40, 0.5, -10)
    toggleBg.Size = UDim2.new(0, 38, 0, 20)
    toggleBg.BackgroundColor3 = defaultValue and ACCENT or Color3.fromRGB(55, 55, 70)
    toggleBg.BackgroundTransparency = 0.8
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

    local toggleKnob = Instance.new("Frame")
    toggleKnob.Parent = toggleBg
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Position = defaultValue and UDim2.new(1, -17, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    toggleKnob.Size = UDim2.new(0, 16, 0, 16)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleKnob.BackgroundTransparency = 0.1
    Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)
    
    local knobTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local state = defaultValue
    local clickArea = Instance.new("TextButton")
    clickArea.Parent = frame
    clickArea.BackgroundTransparency = 1
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.Text = ""
    
    clickArea.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBg, knobTweenInfo, {
            BackgroundColor3 = state and ACCENT or Color3.fromRGB(55, 55, 70)
        }):Play()
        TweenService:Create(toggleKnob, knobTweenInfo, {
            Position = state and UDim2.new(1, -17, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        callback(state)
    end)
    
    return frame
end

local function CreateButton(parent, text, callback, size)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BorderSizePixel = 0
    btn.Size = size or UDim2.new(1, 0, 0, 34)
    btn.LayoutOrder = #parent:GetChildren()
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = TEXT_PRIMARY
    btn.TextSize = 12
    btn.BackgroundColor3 = BG_ELEMENT
    btn.BackgroundTransparency = 0.6
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.TextYAlignment = Enum.TextYAlignment.Center
    
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() 
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    end)
    btn.MouseLeave:Connect(function() 
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
    end)
    return btn
end

local function CreateLabel(parent, text, color)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 24)
    label.LayoutOrder = #parent:GetChildren()
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color or TEXT_PRIMARY
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    return label
end

local function CreateTextBox(parent, placeholder)
    local box = Instance.new("TextBox")
    box.Parent = parent
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1, 0, 0, 34)
    box.LayoutOrder = #parent:GetChildren()
    box.BackgroundColor3 = BG_ELEMENT
    box.BackgroundTransparency = 0.6
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = TEXT_DIM
    box.Text = ""
    box.TextColor3 = TEXT_PRIMARY
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    
    local padding = Instance.new("UIPadding")
    padding.Parent = box
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    
    local boxCorner = Instance.new("UICorner", box)
    boxCorner.CornerRadius = UDim.new(0, 8)
    
    box.Focused:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
    end)
    return box
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.LayoutOrder = #parent:GetChildren()

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Size = UDim2.new(1, -50, 0, 18)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = TEXT_PRIMARY
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -40, 0, 0)
    valueLabel.Size = UDim2.new(0, 40, 0, 18)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = ACCENT
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Parent = frame
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Position = UDim2.new(0, 0, 0, 26)
    sliderTrack.Size = UDim2.new(1, 0, 0, 4)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    sliderTrack.BackgroundTransparency = 0.6
    Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderTrack
    sliderFill.BorderSizePixel = 0
    sliderFill.BackgroundColor3 = ACCENT
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundTransparency = 0.3
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Parent = sliderTrack
    knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BackgroundTransparency = 0.2
    knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Text = ""
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local currentValue = default

    local function updateSlider(input)
        local mousePos = input.Position.X
        local sliderPos = sliderTrack.AbsolutePosition.X
        local sliderWidth = sliderTrack.AbsoluteSize.X
        local t = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
        currentValue = min + (max - min) * t
        currentValue = math.floor(currentValue * 10) / 10
        
        valueLabel.Text = tostring(currentValue)
        TweenService:Create(sliderFill, TweenInfo.new(0.1), {Size = UDim2.new(t, 0, 1, 0)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.1), {Position = UDim2.new(t, -7, 0.5, -7)}):Play()
        callback(currentValue)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
            dragging = true
        end
    end)

    return frame
end

local function CreatePlayerEntry(parent, player)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundColor3 = BG_ELEMENT
    frame.BackgroundTransparency = 0.9
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.LayoutOrder = #parent:GetChildren()
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local isSelected = (selectedPlayer == player)
    
    local function ApplySelectionStyle(selected)
        frame.BorderSizePixel = selected and 2 or 0
        frame.BorderColor3 = ACCENT
        frame.BackgroundTransparency = selected and 0.75 or 0.9
        frame.BackgroundColor3 = selected and ACCENT_DARK or BG_ELEMENT
    end
    ApplySelectionStyle(isSelected)
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.24, 0, 1, 0)
    label.Position = UDim2.new(0.54, 0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = player.Name
    label.TextColor3 = TEXT_PRIMARY
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.BackgroundTransparency = 1
    statusLabel.Size = UDim2.new(0.16, 0, 1, 0)
    statusLabel.Position = UDim2.new(0.78, 0, 0, 0)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextColor3 = TEXT_SECONDARY
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    
    if player == lp then
        statusLabel.Text = "✦ You"
        statusLabel.TextColor3 = ACCENT
    elseif IsPlayerDowned(player) then
        statusLabel.Text = "💀 Down"
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    elseif IsPlayerInLobby(player) then
        statusLabel.Text = "🟤 Lobby"
        statusLabel.TextColor3 = TEXT_DIM
    else
        statusLabel.Text = ""
    end
    
    if player == selectedPlayer and player ~= lp then
        statusLabel.Text = (statusLabel.Text ~= "" and statusLabel.Text .. " " or "") .. "✓"
        statusLabel.TextColor3 = ACCENT
    end
    
    if player ~= lp then
        local btnRow = Instance.new("Frame")
        btnRow.Parent = frame
        btnRow.BackgroundTransparency = 1
        btnRow.Size = UDim2.new(0.52, 0, 1, 0)
        btnRow.Position = UDim2.new(0, 0, 0, 0)
        
        local rowLayout = Instance.new("UIListLayout", btnRow)
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        rowLayout.Padding = UDim.new(0, 4)
        
        local function createToggleBtn(icon, color, onColor, callback)
            local btn = Instance.new("TextButton")
            btn.Parent = btnRow
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(0, 30, 0, 26)
            btn.Font = Enum.Font.GothamBold
            btn.Text = icon
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 13
            btn.BackgroundColor3 = color
            btn.BackgroundTransparency = 0.3
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            local state = false
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.BackgroundColor3 = state and onColor or color
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = state and 0 or 0.3}):Play()
                callback(state)
            end)
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = state and 0 or 0.3}):Play()
            end)
            AddPressAnim(btn)
            return btn
        end
        
        createToggleBtn("🔗", ACCENT, ACCENT_DARK, function(on)
            if on then StartBring(player.Name) else StopBring() end
        end)
        createToggleBtn("🌀", TEAL, Color3.fromRGB(30, 150, 130), function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                notif("Teleported to: " .. player.Name, 2)
            else
                notif("Player not found", 2)
            end
        end)
        createToggleBtn("🦅", Color3.fromRGB(120, 90, 255), Color3.fromRGB(80, 50, 220), function()
            GiveFlyNoClip()
        end)
        createToggleBtn("👁", Color3.fromRGB(50, 160, 255), Color3.fromRGB(30, 110, 200), function(on)
            if on then StartView(player.Name) else StopView() end
        end)
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            SetSelectedPlayer(player)
        end
    end)
    
    frame.MouseEnter:Connect(function()
        if selectedPlayer ~= player then
            TweenService:Create(frame, TweenInfo.new(0.1), {BackgroundTransparency = 0.8}):Play()
        end
    end)
    frame.MouseLeave:Connect(function()
        if selectedPlayer ~= player then
            TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.9}):Play()
        end
    end)
    
    return frame
end

local function UpdatePlayerList()
    if CurrentTab ~= "  Players" then return end
    if not playerListContainer then return end
    
    for _, child in ipairs(playerListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local players = game:GetService("Players"):GetPlayers()
    table.sort(players, function(a, b)
        if a == lp then return true end
        if b == lp then return false end
        return a.Name < b.Name
    end)
    
    if #players == 0 then
        CreateLabel(playerListContainer, "No players in server", TEXT_SECONDARY)
        return
    end
    
    for _, player in ipairs(players) do
        CreatePlayerEntry(playerListContainer, player)
    end
end

local function ClearRightContent()
    for _, child in ipairs(RightContent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("ScrollingFrame") then 
            child:Destroy() 
        end
    end
end

function UpdateRightContent()
    ClearRightContent()
    
    if CurrentTab == "  About" then
        local aboutSection = CreateSection(RightContent, "ℹ️ Info")
        CreateLabel(aboutSection, "⏤ sa7loul | Survive the Killer", ACCENT).TextSize = 18
        CreateLabel(aboutSection, "Version V2.31", TEXT_SECONDARY).TextSize = 11
        CreateLabel(aboutSection, "⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯", TEXT_DIM).TextSize = 10
        
        local changesHeader = CreateLabel(aboutSection, "📋 Changelog:", TEXT_PRIMARY)
        changesHeader.TextSize = 13
        
        local changes = {
            "✦ V2.31 — Full redesign",
            "✦ Added animations to all elements",
            "✦ Soft and attractive colors",
            "✦ Full UI in English",
            "✦ Performance and responsiveness improved",
            "",
            "✦ V2 — Settings tab",
            "✦ Fun tab",
            "✦ Anti-trap system",
            "✦ Panic TP",
            "✦ Config save/load",
            "✦ Script manager",
            "✦ UI improvements",
            "",
            "✦ V1.4 — Auto Escape",
            "✦ ESP for exits and traps",
            "✦ Disable speed on fall",
            "✦ Auto Revive improved",
            "",
            "✦ V1.3 — New UI",
            "✦ Killer Chance X3",
            "",
            "✦ V1.2 — Double Jump",
            "",
            "✦ V1.1 — Auto Revive",
            "",
            "✦ V1 — Launch"
        }
        for _, line in ipairs(changes) do
            local l = CreateLabel(aboutSection, "  " .. line, Color3.fromRGB(190, 190, 210))
            l.TextSize = 11; l.Font = Enum.Font.Gotham
        end
        
        CreateLabel(aboutSection, "", Color3.fromRGB(50,50,50))
        CreateLabel(aboutSection, "👤 Developer: sa7loul", TEXT_SECONDARY).TextSize = 11
        CreateLabel(aboutSection, "🧪 Testers: Probka & Lysyy", TEXT_SECONDARY).TextSize = 11

    elseif CurrentTab == "  Player" then
        local movementSection = CreateSection(RightContent, "🏃 Movement")
        CreateToggle(movementSection, "Speed Boost", settings.speedEnabled, function(val)
            settings.speedEnabled = val
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = val and settings.Speed or 16
            end
        end)
        CreateSlider(movementSection, "Speed", 16, 50, settings.Speed, function(val)
            settings.Speed = val
            if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.WalkSpeed = val
            end
        end)
        CreateToggle(movementSection, "Disable speed when down", settings.speedDisableOnDown, function(val)
            settings.speedDisableOnDown = val
        end)
        CreateToggle(movementSection, "Flight", settings.Fly, function(val)
            settings.Fly = val
            UpdateFly()
        end)
        CreateSlider(movementSection, "Flight speed", 20, 200, settings.flySpeed, function(val)
            settings.flySpeed = val
        end)
        CreateToggle(movementSection, "Noclip", settings.Noclip, function(val)
            settings.Noclip = val
            if val then
                if noclipConnection then noclipConnection:Disconnect() end
                noclipConnection = RunService.Stepped:Connect(function()
                    if settings.Noclip and lp.Character then
                        for _, part in pairs(lp.Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            else
                if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
            end
        end)
        CreateToggle(movementSection, "Auto Escape", settings.AutoEscape, function(val)
            settings.AutoEscape = val
            if val then
                if autoEscapeConnection then autoEscapeConnection:Disconnect() end
                autoEscapeConnection = RunService.Heartbeat:Connect(AutoEscapeLoop)
            else
                if autoEscapeConnection then autoEscapeConnection:Disconnect(); autoEscapeConnection = nil end
            end
        end)
        
        CreateToggle(movementSection, "Panic TP", settings.PanicTP, function(val)
            settings.PanicTP = val
            if val then
                if panicTPConnection then panicTPConnection:Disconnect() end
                panicTPConnection = RunService.Heartbeat:Connect(function()
                    if settings.PanicTP then
                        CheckPanicTP()
                    end
                end)
            else
                if panicTPConnection then panicTPConnection:Disconnect(); panicTPConnection = nil end
            end
        end)
        
        local bypassSection = CreateSection(RightContent, "🎫 Bypass")
        CreateToggle(movementSection, "👻 Invisible", invisActive, function(val)
            invisActive = val
            if val then
                if invisConn then invisConn:Disconnect() end
                invisSaved = {}
                local function hide()
                    if not invisActive or not lp.Character then return end
                    for _, part in ipairs(lp.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if not invisSaved[part] then invisSaved[part] = part.Transparency end
                            if part.Transparency < 1 then part.Transparency = 1 end
                        end
                    end
                end
                invisConn = RunService.RenderStepped:Connect(hide)
                RunService.Heartbeat:Connect(hide)
                RunService.Stepped:Connect(hide)
            else
                if invisConn then invisConn:Disconnect(); invisConn = nil end
                if lp.Character then
                    for part, tr in pairs(invisSaved) do
                        if part and part.Parent then
                            pcall(function() part.Transparency = tr end)
                        end
                    end
                end
                invisSaved = {}
            end
        end)
        CreateToggle(bypassSection, "Double Jump", settings.DoubleJump, function(val)
            settings.DoubleJump = val
            UpdateDoubleJump()
        end)
        CreateToggle(bypassSection, "Killer Chance X3", settings.KillerChanceX3, function(val)
            settings.KillerChanceX3 = val
            UpdateKillerChance()
        end)
        
        local combatSection = CreateSection(RightContent, "⚔️ Combat")
        CreateToggle(combatSection, "Kill Aura", settings.KillAura, function(val)
            settings.KillAura = val
            if val then
                if killAuraConnection then killAuraConnection:Disconnect() end
                killAuraConnection = RunService.Heartbeat:Connect(function()
                    if settings.KillAura and lp.Character and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0 then
                        KillAuraLoop()
                    end
                end)
            else
                if killAuraConnection then killAuraConnection:Disconnect(); killAuraConnection = nil end
            end
        end)
        CreateSlider(combatSection, "Kill Aura radius", 8, 80, settings.killAuraRadius, function(val)
            settings.killAuraRadius = val
        end)
        
    elseif CurrentTab == "  World" then
        local visualSection = CreateSection(RightContent, "👁️ Visuals")
        CreateToggle(visualSection, "Player ESP", settings.ESP, function(val)
            settings.ESP = val
            espCache = {}
            UpdateESP()
        end)
        CreateToggle(visualSection, "Exit ESP", settings.ESPExits, function(val)
            settings.ESPExits = val
            UpdateESPExits()
        end)
        CreateToggle(visualSection, "Trap ESP", settings.ESPTraps, function(val)
            settings.ESPTraps = val
            UpdateESPTraps()
        end)
        CreateToggle(visualSection, "Remove fog", settings.NoFog, function(val)
            settings.NoFog = val
            UpdateNoFog()
        end)
        CreateToggle(visualSection, "Fullbright", settings.Fullbright, function(val)
            settings.Fullbright = val
            if val then
                if brightLoop then brightLoop:Disconnect() end
                brightLoop = RunService.RenderStepped:Connect(function()
                    Lighting.Brightness = 2
                    Lighting.ClockTime = 14
                    Lighting.GlobalShadows = false
                    Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
                end)
            else
                if brightLoop then brightLoop:Disconnect(); brightLoop = nil end
            end
        end)
        
        CreateToggle(visualSection, "Anti-Trap", settings.AntiTrap, function(val)
            settings.AntiTrap = val
            if val then
                if antiTrapConnection then antiTrapConnection:Disconnect() end
                antiTrapConnection = RunService.Heartbeat:Connect(function()
                    if settings.AntiTrap then
                        RemoveTraps()
                    end
                end)
            else
                if antiTrapConnection then antiTrapConnection:Disconnect(); antiTrapConnection = nil end
            end
        end)
        
        local lootSection = CreateSection(RightContent, "📦 Auto Loot")
        CreateToggle(lootSection, "Auto collect loot", settings.AutoLoot, function(val)
            settings.AutoLoot = val
            if val then
                savedHomePosition = nil
                if lootConnection then lootConnection:Disconnect() end
                lootConnection = RunService.Heartbeat:Connect(function()
                    if settings.AutoLoot and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        AutoCollectLoot()
                    end
                end)
            else
                if lootConnection then lootConnection:Disconnect(); lootConnection = nil end
                if settings.returnHomeAfterLoot then ReturnToHome() else savedHomePosition = nil end
            end
        end)
        CreateToggle(lootSection, "Return home after looting", settings.returnHomeAfterLoot, function(val)
            settings.returnHomeAfterLoot = val
        end)
        
        local teleportSection = CreateSection(RightContent, "🌀 Teleport")
        CreateButton(teleportSection, "Teleport to exit", TeleportToExit)
        CreateButton(teleportSection, "Teleport to lobby", function()
            local lobby = workspace:FindFirstChild("_Lobby")
            if lobby then
                local decor = lobby:FindFirstChild("Decor")
                if decor then
                    local knifeStatue = decor:FindFirstChild("KnifeStatue")
                    if knifeStatue and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.CFrame = CFrame.new(knifeStatue.Position + Vector3.new(0, 30, 0))
                        notif("Teleported to lobby!", 2)
                    end
                end
            end
        end)
        
    elseif CurrentTab == "  Players" then
        playerListContainer = CreateSection(RightContent, "👥 Player list")
        local selectHint = CreateLabel(playerListContainer, "Click row to select · 🔗 Bring 🌀 TP 🦅 Fly+NoClip 👁 Spectate (click again = OFF)", TEXT_DIM)
        selectHint.TextSize = 10
        UpdatePlayerList()
        
        local refreshBtn = CreateButton(RightContent, "🔄 Refresh list", function()
            UpdatePlayerList()
        end)
        refreshBtn.Size = UDim2.new(0.48, 0, 0, 30)
        
        local stopAllBtn = CreateButton(RightContent, "⏹ Stop all", function()
            StopView()
            StopBring()
            StopBringAll()
            notif("All operations stopped", 2)
        end)
        stopAllBtn.Size = UDim2.new(0.48, 0, 0, 30)
        
    elseif CurrentTab == "  Revive" then
        local reviveSection = CreateSection(RightContent, "💉 Revive modes")
        CreateToggle(reviveSection, "Auto revive (Safe)", settings.AutoReviveLegit, function(val)
            settings.AutoReviveLegit = val
            if val then
                if reviveLegitConnection then reviveLegitConnection:Disconnect() end
                reviveLegitConnection = RunService.Heartbeat:Connect(AutoReviveLegitLoop)
            else
                if reviveLegitConnection then reviveLegitConnection:Disconnect(); reviveLegitConnection = nil end
            end
        end)
        CreateButton(reviveSection, "⚡ Risky revive (one-time)", function()
            AutoReviveRiskyOneUse()
        end)
        
        local selfReviveSection = CreateSection(RightContent, "🔄 Self revive")
        CreateToggle(selfReviveSection, "Auto self revive", settings.AutoReviveSelf, function(val)
            settings.AutoReviveSelf = val
            if val then
                if selfReviveConnection then selfReviveConnection:Disconnect() end
                selfReviveConnection = RunService.Heartbeat:Connect(AutoReviveSelfLoop)
            else
                if selfReviveConnection then selfReviveConnection:Disconnect(); selfReviveConnection = nil end
            end
        end)
        CreateSlider(selfReviveSection, "Cooldown", 1, 10, settings.selfReviveCooldown, function(val)
            settings.selfReviveCooldown = val
        end)
        
        local function setSelfReviveMode(mode)
            settings.selfReviveMode = mode
            notif("Revive mode: " .. mode, 2)
        end
        CreateButton(selfReviveSection, "🔄 Random", function() setSelfReviveMode("Random") end)
        CreateButton(selfReviveSection, "📏 Farthest", function() setSelfReviveMode("Farthest") end)
        
    elseif CurrentTab == "  Fun" then
        local funSection = CreateSection(RightContent, "🎮 Fun commands")
        
        selectedPlayerLabel = Instance.new("TextButton")
        selectedPlayerLabel.Parent = funSection
        selectedPlayerLabel.BorderSizePixel = 0
        selectedPlayerLabel.Size = UDim2.new(1, 0, 0, 30)
        selectedPlayerLabel.Font = Enum.Font.GothamBold
        selectedPlayerLabel.Text = "👤 Player: None"
        selectedPlayerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectedPlayerLabel.TextSize = 12
        selectedPlayerLabel.BackgroundColor3 = TEAL
        selectedPlayerLabel.BackgroundTransparency = 0.3
        local pickerCorner = Instance.new("UICorner", selectedPlayerLabel)
        pickerCorner.CornerRadius = UDim.new(0, 8)
        selectedPlayerLabel.MouseButton1Click:Connect(CyclePlayer)
        selectedPlayerLabel.MouseEnter:Connect(function() 
            TweenService:Create(selectedPlayerLabel, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        selectedPlayerLabel.MouseLeave:Connect(function() 
            TweenService:Create(selectedPlayerLabel, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        AddPressAnim(selectedPlayerLabel)
        if not GetSelectedPlayer() then CyclePlayer() end
        
        local btnRow1 = Instance.new("Frame")
        btnRow1.Parent = funSection
        btnRow1.BackgroundTransparency = 1
        btnRow1.Size = UDim2.new(1, 0, 0, 38)
        btnRow1.LayoutOrder = #funSection:GetChildren()
        
        local rowLayout1 = Instance.new("UIListLayout", btnRow1)
        rowLayout1.FillDirection = Enum.FillDirection.Horizontal
        rowLayout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout1.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout1.Padding = UDim.new(0, 8)
        
        local flingBtn = Instance.new("TextButton")
        flingBtn.Parent = btnRow1
        flingBtn.BorderSizePixel = 0
        flingBtn.Size = UDim2.new(0.48, 0, 0, 32)
        flingBtn.Font = Enum.Font.GothamBold
        flingBtn.Text = "🚀 Fling"
        flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        flingBtn.TextSize = 12
        flingBtn.BackgroundColor3 = ACCENT
        flingBtn.BackgroundTransparency = 0.3
        local flingCorner = Instance.new("UICorner", flingBtn)
        flingCorner.CornerRadius = UDim.new(0, 8)
        flingBtn.MouseButton1Click:Connect(function()
            local target = GetSelectedPlayer()
            if target then
                local function startFling()
                    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        if FlingActive then return end
                        FlingActive = true
                        notif("Fling: " .. target.Name, 2)
                        local thrust = Instance.new('BodyThrust', lp.Character.HumanoidRootPart)
                        thrust.Force = Vector3.new(9999, 9999, 9999)
                        thrust.Name = "YeetForce"
                        
                        coroutine.wrap(function()
                            while FlingActive and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") do
                                lp.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
                                thrust.Location = target.Character.HumanoidRootPart.Position
                                RunService.Heartbeat:Wait()
                            end
                            thrust:Destroy()
                            if FlingActive then notif("Fling stopped", 2) end
                            FlingActive = false
                        end)()
                    else
                        notif("Player not found", 2)
                    end
                end
                startFling()
            else
                notif("Select a player first", 2)
            end
        end)
        flingBtn.MouseEnter:Connect(function() 
            TweenService:Create(flingBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        flingBtn.MouseLeave:Connect(function() 
            TweenService:Create(flingBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        
        local stopFlingBtn = Instance.new("TextButton")
        stopFlingBtn.Parent = btnRow1
        stopFlingBtn.BorderSizePixel = 0
        stopFlingBtn.Size = UDim2.new(0.48, 0, 0, 32)
        stopFlingBtn.Font = Enum.Font.GothamBold
        stopFlingBtn.Text = "⏹ Stop fling"
        stopFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stopFlingBtn.TextSize = 12
        stopFlingBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        stopFlingBtn.BackgroundTransparency = 0.3
        local stopCorner = Instance.new("UICorner", stopFlingBtn)
        stopCorner.CornerRadius = UDim.new(0, 8)
        stopFlingBtn.MouseButton1Click:Connect(function()
            FlingActive = false
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local thrust = lp.Character.HumanoidRootPart:FindFirstChild("YeetForce")
                if thrust then thrust:Destroy() end
            end
            notif("Fling stopped", 2)
        end)
        stopFlingBtn.MouseEnter:Connect(function() 
            TweenService:Create(stopFlingBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        stopFlingBtn.MouseLeave:Connect(function() 
            TweenService:Create(stopFlingBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        
        local btnRow2 = Instance.new("Frame")
        btnRow2.Parent = funSection
        btnRow2.BackgroundTransparency = 1
        btnRow2.Size = UDim2.new(1, 0, 0, 38)
        btnRow2.LayoutOrder = #funSection:GetChildren()
        
        local rowLayout2 = Instance.new("UIListLayout", btnRow2)
        rowLayout2.FillDirection = Enum.FillDirection.Horizontal
        rowLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout2.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout2.Padding = UDim.new(0, 8)
        
        local freezeBtn = Instance.new("TextButton")
        freezeBtn.Parent = btnRow2
        freezeBtn.BorderSizePixel = 0
        freezeBtn.Size = UDim2.new(0.48, 0, 0, 32)
        freezeBtn.Font = Enum.Font.GothamBold
        freezeBtn.Text = "❄️ Freeze"
        freezeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        freezeBtn.TextSize = 12
        freezeBtn.BackgroundColor3 = Color3.fromRGB(50, 170, 255)
        freezeBtn.BackgroundTransparency = 0.3
        local freezeCorner = Instance.new("UICorner", freezeBtn)
        freezeCorner.CornerRadius = UDim.new(0, 8)
        freezeBtn.MouseButton1Click:Connect(function()
            local target = GetSelectedPlayer()
            if target then FreezePlayer(target.Name) else notif("Select a player first", 2) end
        end)
        freezeBtn.MouseEnter:Connect(function() 
            TweenService:Create(freezeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        freezeBtn.MouseLeave:Connect(function() 
            TweenService:Create(freezeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        
        local thawBtn = Instance.new("TextButton")
        thawBtn.Parent = btnRow2
        thawBtn.BorderSizePixel = 0
        thawBtn.Size = UDim2.new(0.48, 0, 0, 32)
        thawBtn.Font = Enum.Font.GothamBold
        thawBtn.Text = "🔥 Unfreeze"
        thawBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        thawBtn.TextSize = 12
        thawBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 50)
        thawBtn.BackgroundTransparency = 0.3
        local thawCorner = Instance.new("UICorner", thawBtn)
        thawCorner.CornerRadius = UDim.new(0, 8)
        thawBtn.MouseButton1Click:Connect(function()
            local target = GetSelectedPlayer()
            if target then ThawPlayer(target.Name) else notif("Select a player first", 2) end
        end)
        thawBtn.MouseEnter:Connect(function() 
            TweenService:Create(thawBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        thawBtn.MouseLeave:Connect(function() 
            TweenService:Create(thawBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        
        local btnRow3 = Instance.new("Frame")
        btnRow3.Parent = funSection
        btnRow3.BackgroundTransparency = 1
        btnRow3.Size = UDim2.new(1, 0, 0, 38)
        btnRow3.LayoutOrder = #funSection:GetChildren()
        
        local rowLayout3 = Instance.new("UIListLayout", btnRow3)
        rowLayout3.FillDirection = Enum.FillDirection.Horizontal
        rowLayout3.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout3.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout3.Padding = UDim.new(0, 8)
        
        local viewBtn = Instance.new("TextButton")
        viewBtn.Parent = btnRow3
        viewBtn.BorderSizePixel = 0
        viewBtn.Size = UDim2.new(0.48, 0, 0, 32)
        viewBtn.Font = Enum.Font.GothamBold
        viewBtn.Text = "👁️ View"
        viewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        viewBtn.TextSize = 12
        viewBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 255)
        viewBtn.BackgroundTransparency = 0.3
        local viewCorner = Instance.new("UICorner", viewBtn)
        viewCorner.CornerRadius = UDim.new(0, 8)
        viewBtn.MouseButton1Click:Connect(function()
            local target = GetSelectedPlayer()
            if target then StartView(target.Name) else notif("Select a player first", 2) end
        end)
        viewBtn.MouseEnter:Connect(function() 
            TweenService:Create(viewBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        viewBtn.MouseLeave:Connect(function() 
            TweenService:Create(viewBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        
        local unviewBtn = Instance.new("TextButton")
        unviewBtn.Parent = btnRow3
        unviewBtn.BorderSizePixel = 0
        unviewBtn.Size = UDim2.new(0.48, 0, 0, 32)
        unviewBtn.Font = Enum.Font.GothamBold
        unviewBtn.Text = "⏹ Stop view"
        unviewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        unviewBtn.TextSize = 12
        unviewBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        unviewBtn.BackgroundTransparency = 0.3
        local unviewCorner = Instance.new("UICorner", unviewBtn)
        unviewCorner.CornerRadius = UDim.new(0, 8)
        unviewBtn.MouseButton1Click:Connect(StopView)
        unviewBtn.MouseEnter:Connect(function() 
            TweenService:Create(unviewBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        unviewBtn.MouseLeave:Connect(function() 
            TweenService:Create(unviewBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        
        local btnRow4 = Instance.new("Frame")
        btnRow4.Parent = funSection
        btnRow4.BackgroundTransparency = 1
        btnRow4.Size = UDim2.new(1, 0, 0, 38)
        btnRow4.LayoutOrder = #funSection:GetChildren()
        
        local rowLayout4 = Instance.new("UIListLayout", btnRow4)
        rowLayout4.FillDirection = Enum.FillDirection.Horizontal
        rowLayout4.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout4.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout4.Padding = UDim.new(0, 8)
        
        local bringBtn = Instance.new("TextButton")
        bringBtn.Parent = btnRow4
        bringBtn.BorderSizePixel = 0
        bringBtn.Size = UDim2.new(0.48, 0, 0, 32)
        bringBtn.Font = Enum.Font.GothamBold
        bringBtn.Text = "🔗 Bring"
        bringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        bringBtn.TextSize = 12
        bringBtn.BackgroundColor3 = ACCENT
        bringBtn.BackgroundTransparency = 0.3
        local bringCorner = Instance.new("UICorner", bringBtn)
        bringCorner.CornerRadius = UDim.new(0, 8)
        bringBtn.MouseButton1Click:Connect(function()
            local target = GetSelectedPlayer()
            if target then StartBring(target.Name) else notif("Select a player first", 2) end
        end)
        bringBtn.MouseEnter:Connect(function() 
            TweenService:Create(bringBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        bringBtn.MouseLeave:Connect(function() 
            TweenService:Create(bringBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        
        local stopBringBtn = Instance.new("TextButton")
        stopBringBtn.Parent = btnRow4
        stopBringBtn.BorderSizePixel = 0
        stopBringBtn.Size = UDim2.new(0.48, 0, 0, 32)
        stopBringBtn.Font = Enum.Font.GothamBold
        stopBringBtn.Text = "⏹ Stop bring"
        stopBringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stopBringBtn.TextSize = 12
        stopBringBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        stopBringBtn.BackgroundTransparency = 0.3
        local stopCorner2 = Instance.new("UICorner", stopBringBtn)
        stopCorner2.CornerRadius = UDim.new(0, 8)
        stopBringBtn.MouseButton1Click:Connect(StopBring)
        stopBringBtn.MouseEnter:Connect(function() 
            TweenService:Create(stopBringBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        stopBringBtn.MouseLeave:Connect(function() 
            TweenService:Create(stopBringBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        
        local btnRow5 = Instance.new("Frame")
        btnRow5.Parent = funSection
        btnRow5.BackgroundTransparency = 1
        btnRow5.Size = UDim2.new(1, 0, 0, 38)
        btnRow5.LayoutOrder = #funSection:GetChildren()
        
        local rowLayout5 = Instance.new("UIListLayout", btnRow5)
        rowLayout5.FillDirection = Enum.FillDirection.Horizontal
        rowLayout5.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout5.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout5.Padding = UDim.new(0, 8)
        
        local bringAllBtn = Instance.new("TextButton")
        bringAllBtn.Parent = btnRow5
        bringAllBtn.BorderSizePixel = 0
        bringAllBtn.Size = UDim2.new(0.31, 0, 0, 32)
        bringAllBtn.Font = Enum.Font.GothamBold
        bringAllBtn.Text = "🔗 Bring All"
        bringAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        bringAllBtn.TextSize = 12
        bringAllBtn.BackgroundColor3 = ACCENT
        bringAllBtn.BackgroundTransparency = 0.3
        local bringAllCorner = Instance.new("UICorner", bringAllBtn)
        bringAllCorner.CornerRadius = UDim.new(0, 8)
        bringAllBtn.MouseButton1Click:Connect(StartBringAll)
        bringAllBtn.MouseEnter:Connect(function() 
            TweenService:Create(bringAllBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        bringAllBtn.MouseLeave:Connect(function() 
            TweenService:Create(bringAllBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        AddPressAnim(bringAllBtn)
        
        local unbringBtn = Instance.new("TextButton")
        unbringBtn.Parent = btnRow5
        unbringBtn.BorderSizePixel = 0
        unbringBtn.Size = UDim2.new(0.31, 0, 0, 32)
        unbringBtn.Font = Enum.Font.GothamBold
        unbringBtn.Text = "🔙 Unbring"
        unbringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        unbringBtn.TextSize = 12
        unbringBtn.BackgroundColor3 = TEAL
        unbringBtn.BackgroundTransparency = 0.3
        local unbringCorner = Instance.new("UICorner", unbringBtn)
        unbringCorner.CornerRadius = UDim.new(0, 8)
        unbringBtn.MouseButton1Click:Connect(UnbringSelected)
        unbringBtn.MouseEnter:Connect(function() 
            TweenService:Create(unbringBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        unbringBtn.MouseLeave:Connect(function() 
            TweenService:Create(unbringBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        AddPressAnim(unbringBtn)
        
        local stopBringAllBtn = Instance.new("TextButton")
        stopBringAllBtn.Parent = btnRow5
        stopBringAllBtn.BorderSizePixel = 0
        stopBringAllBtn.Size = UDim2.new(0.31, 0, 0, 32)
        stopBringAllBtn.Font = Enum.Font.GothamBold
        stopBringAllBtn.Text = "⏹ Stop Bring All"
        stopBringAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stopBringAllBtn.TextSize = 12
        stopBringAllBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        stopBringAllBtn.BackgroundTransparency = 0.3
        local stopBringAllCorner = Instance.new("UICorner", stopBringAllBtn)
        stopBringAllCorner.CornerRadius = UDim.new(0, 8)
        stopBringAllBtn.MouseButton1Click:Connect(StopBringAll)
        stopBringAllBtn.MouseEnter:Connect(function() 
            TweenService:Create(stopBringAllBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        stopBringAllBtn.MouseLeave:Connect(function() 
            TweenService:Create(stopBringAllBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        AddPressAnim(stopBringAllBtn)
        
        CreateToggle(funSection, "🌀 Spin", spinActive, function(val)
            spinActive = val
            UpdateSpin(val)
        end)
        
        CreateSlider(funSection, "Spin speed", 1, 300, spinSpeed, function(val)
            spinSpeed = val
            if spinActive and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local root = lp.Character.HumanoidRootPart
                local spin = root:FindFirstChild("Spinning")
                if spin then
                    spin.AngularVelocity = Vector3.new(0, spinSpeed, 0)
                end
            end
        end)
        
    elseif CurrentTab == "  More" then
        local scriptsSection = CreateSection(RightContent, "📦 External scripts")
        
        local addRow = Instance.new("Frame")
        addRow.Parent = scriptsSection
        addRow.BackgroundTransparency = 1
        addRow.Size = UDim2.new(1, 0, 0, 34)
        addRow.LayoutOrder = #scriptsSection:GetChildren()
        
        local nameBox = Instance.new("TextBox")
        nameBox.Parent = addRow
        nameBox.BorderSizePixel = 0
        nameBox.Size = UDim2.new(0.35, -4, 1, 0)
        nameBox.Position = UDim2.new(0, 0, 0, 0)
        nameBox.BackgroundColor3 = BG_ELEMENT
        nameBox.BackgroundTransparency = 0.6
        nameBox.Font = Enum.Font.Gotham
        nameBox.PlaceholderText = "Name"
        nameBox.PlaceholderColor3 = TEXT_DIM
        nameBox.Text = ""
        nameBox.TextColor3 = TEXT_PRIMARY
        nameBox.TextSize = 11
        nameBox.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 6)
        
        local urlBox = Instance.new("TextBox")
        urlBox.Parent = addRow
        urlBox.BorderSizePixel = 0
        urlBox.Size = UDim2.new(0.5, -4, 1, 0)
        urlBox.Position = UDim2.new(0.36, 0, 0, 0)
        urlBox.BackgroundColor3 = BG_ELEMENT
        urlBox.BackgroundTransparency = 0.6
        urlBox.Font = Enum.Font.Gotham
        urlBox.PlaceholderText = "URL or code"
        urlBox.PlaceholderColor3 = TEXT_DIM
        urlBox.Text = ""
        urlBox.TextColor3 = TEXT_PRIMARY
        urlBox.TextSize = 11
        urlBox.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", urlBox).CornerRadius = UDim.new(0, 6)
        
        local addBtn = Instance.new("TextButton")
        addBtn.Parent = addRow
        addBtn.BorderSizePixel = 0
        addBtn.Size = UDim2.new(0.13, -4, 1, 0)
        addBtn.Position = UDim2.new(0.87, 0, 0, 0)
        addBtn.Font = Enum.Font.GothamBold
        addBtn.Text = "+"
        addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        addBtn.TextSize = 18
        addBtn.BackgroundColor3 = ACCENT
        addBtn.BackgroundTransparency = 0.3
        addBtn.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 6)
        
        addBtn.MouseButton1Click:Connect(function()
            if nameBox.Text ~= "" and urlBox.Text ~= "" then
                local scriptContent = urlBox.Text
                if scriptContent:match("^https?://") then
                    scriptContent = 'loadstring(game:HttpGet("' .. scriptContent .. '"))()'
                end
                AddUserScript(nameBox.Text, scriptContent)
                nameBox.Text = ""
                urlBox.Text = ""
            else
                notif("Fill the fields", 2)
            end
        end)
        addBtn.MouseEnter:Connect(function() 
            TweenService:Create(addBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        addBtn.MouseLeave:Connect(function() 
            TweenService:Create(addBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
        end)
        
        for _, scriptData in ipairs(more_scripts) do
            local btn = Instance.new("TextButton")
            btn.Parent = scriptsSection
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(1, 0, 0, 34)
            btn.LayoutOrder = #scriptsSection:GetChildren()
            btn.Font = Enum.Font.GothamBold
            btn.Text = "📜 " .. scriptData.name
            btn.TextColor3 = TEXT_PRIMARY
            btn.TextSize = 12
            btn.BackgroundColor3 = BG_ELEMENT
            btn.BackgroundTransparency = 0.6
            btn.TextXAlignment = Enum.TextXAlignment.Center
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            btn.MouseButton1Click:Connect(function()
                notif("Loading: " .. scriptData.name, 2)
                local success, err = pcall(function()
                    local func = loadstring(scriptData.script)
                    if func then
                        func()
                    else
                        notif("Load failed", 3)
                    end
                end)
                if not success and err then
                    notif("Error: " .. tostring(err), 3)
                end
            end)
            btn.MouseEnter:Connect(function() 
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
            end)
            btn.MouseLeave:Connect(function() 
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
            end)
        end
        
        if #userScripts > 0 then
            local userSection = CreateSection(RightContent, "📁 Your scripts")
            for i, scriptData in ipairs(userScripts) do
                local frame = Instance.new("Frame")
                frame.Parent = userSection
                frame.BackgroundTransparency = 1
                frame.Size = UDim2.new(1, 0, 0, 34)
                frame.LayoutOrder = #userSection:GetChildren()
                
                local btn = Instance.new("TextButton")
                btn.Parent = frame
                btn.BorderSizePixel = 0
                btn.Size = UDim2.new(1, -30, 1, 0)
                btn.Font = Enum.Font.GothamBold
                btn.Text = "📜 " .. scriptData.name
                btn.TextColor3 = TEXT_PRIMARY
                btn.TextSize = 12
                btn.BackgroundColor3 = BG_ELEMENT
                btn.BackgroundTransparency = 0.6
                btn.TextXAlignment = Enum.TextXAlignment.Center
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
                btn.MouseButton1Click:Connect(function()
                    notif("Loading: " .. scriptData.name, 2)
                    local success, err = pcall(function()
                        local func = loadstring(scriptData.script)
                        if func then
                            func()
                        else
                            notif("Load failed", 3)
                        end
                    end)
                    if not success and err then
                        notif("Error: " .. tostring(err), 3)
                    end
                end)
                btn.MouseEnter:Connect(function() 
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
                end)
                btn.MouseLeave:Connect(function() 
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
                end)
                
                local removeBtn = Instance.new("TextButton")
                removeBtn.Parent = frame
                removeBtn.BorderSizePixel = 0
                removeBtn.Position = UDim2.new(1, -26, 0, 2)
                removeBtn.Size = UDim2.new(0, 24, 1, -4)
                removeBtn.Font = Enum.Font.GothamBold
                removeBtn.Text = "✕"
                removeBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
                removeBtn.TextSize = 14
                removeBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
                removeBtn.BackgroundTransparency = 0.5
                removeBtn.TextXAlignment = Enum.TextXAlignment.Center
                removeBtn.ZIndex = 2
                Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 6)
                removeBtn.MouseButton1Click:Connect(function()
                    RemoveUserScript(i)
                end)
                removeBtn.MouseEnter:Connect(function() 
                    TweenService:Create(removeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
                end)
                removeBtn.MouseLeave:Connect(function() 
                    TweenService:Create(removeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play()
                end)
            end
        end
        
    elseif CurrentTab == "  Settings" then
        local configSection = CreateSection(RightContent, "⚙️ Configs")
        
        local nameFrame = Instance.new("Frame")
        nameFrame.Parent = configSection
        nameFrame.BackgroundTransparency = 1
        nameFrame.Size = UDim2.new(1, 0, 0, 34)
        nameFrame.LayoutOrder = #configSection:GetChildren()
        
        local configNameBox = Instance.new("TextBox")
        configNameBox.Parent = nameFrame
        configNameBox.BorderSizePixel = 0
        configNameBox.Size = UDim2.new(1, 0, 1, 0)
        configNameBox.BackgroundColor3 = BG_ELEMENT
        configNameBox.BackgroundTransparency = 0.6
        configNameBox.Font = Enum.Font.Gotham
        configNameBox.PlaceholderText = "Config name"
        configNameBox.PlaceholderColor3 = TEXT_DIM
        configNameBox.Text = "Default"
        configNameBox.TextColor3 = TEXT_PRIMARY
        configNameBox.TextSize = 12
        configNameBox.TextXAlignment = Enum.TextXAlignment.Left
        
        local namePadding = Instance.new("UIPadding")
        namePadding.Parent = configNameBox
        namePadding.PaddingLeft = UDim.new(0, 12)
        namePadding.PaddingRight = UDim.new(0, 12)
        
        local boxCorner = Instance.new("UICorner", configNameBox)
        boxCorner.CornerRadius = UDim.new(0, 8)
        
        local btnRow = Instance.new("Frame")
        btnRow.Parent = configSection
        btnRow.BackgroundTransparency = 1
        btnRow.Size = UDim2.new(1, 0, 0, 38)
        btnRow.LayoutOrder = #configSection:GetChildren()
        
        local rowLayout = Instance.new("UIListLayout", btnRow)
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.Padding = UDim.new(0, 6)
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local btnWidth = UDim2.new(0.32, -4, 1, 0)
        
        CreateButton(btnRow, "💾 Save", function()
            local configName = configNameBox.Text
            if configName == "" then configName = "Default" end
            SaveConfig(configName)
        end, btnWidth)
        
        CreateButton(btnRow, "📂 Load", function()
            local configName = configNameBox.Text
            if configName == "" then configName = "Default" end
            LoadConfig(configName)
            UpdateRightContent()
        end, btnWidth)
        
        CreateButton(btnRow, "🗑️ Delete", function()
            local configName = configNameBox.Text
            if configName == "" then configName = "Default" end
            DeleteConfig(configName)
        end, btnWidth)
        
        local configListSection = CreateSection(RightContent, "📋 Saved configs")
        local configsList = GetConfigList()
        if #configsList > 0 then
            for _, name in ipairs(configsList) do
                CreateButton(configListSection, "📄 " .. name, function()
                    configNameBox.Text = name
                    LoadConfig(name)
                    UpdateRightContent()
                end)
            end
        else
            CreateLabel(configListSection, "No saved configs", TEXT_SECONDARY)
        end
        
        local unbanSection = CreateSection(RightContent, "🛡️ Unban")
        CreateButton(unbanSection, "🛡️ Try Unban", TryUnban)
        CreateButton(unbanSection, "🔁 Rejoin fresh", RejoinFresh)
        CreateLabel(unbanSection, "DataStore (permanent) bans can't be removed by any script", TEXT_DIM)
        
        local miscSection = CreateSection(RightContent, "🔧 Other")
        CreateToggle(miscSection, "Anti-AFK", settings.AntiAFK, function(val)
            settings.AntiAFK = val
            if val then
                if antiAFKConnection then antiAFKConnection:Disconnect() end
                antiAFKConnection = RunService.Heartbeat:Connect(function()
                    if settings.AntiAFK then
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                        task.wait(0.05)
                        vim:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                        task.wait(15)
                    end
                end)
            else
                if antiAFKConnection then antiAFKConnection:Disconnect(); antiAFKConnection = nil end
            end
        end)
        CreateButton(miscSection, "🎤 Mic Bypass", ToggleMicBypass)
        
        local footerFrame = Instance.new("Frame")
        footerFrame.Parent = RightContent
        footerFrame.BackgroundTransparency = 1
        footerFrame.Size = UDim2.new(1, 0, 0, 60)
        footerFrame.LayoutOrder = 999999
        
        local footerLabel1 = Instance.new("TextLabel")
        footerLabel1.Parent = footerFrame
        footerLabel1.BackgroundTransparency = 1
        footerLabel1.Size = UDim2.new(1, 0, 0, 22)
        footerLabel1.Position = UDim2.new(0, 0, 0, 8)
        footerLabel1.Font = Enum.Font.GothamBold
        footerLabel1.Text = "Supports STK v2.31.0"
        footerLabel1.TextColor3 = TEXT_SECONDARY
        footerLabel1.TextSize = 11
        footerLabel1.TextXAlignment = Enum.TextXAlignment.Center

        local footerLabel2 = Instance.new("TextLabel")
        footerLabel2.Parent = footerFrame
        footerLabel2.BackgroundTransparency = 1
        footerLabel2.Size = UDim2.new(1, 0, 0, 22)
        footerLabel2.Position = UDim2.new(0, 0, 0, 32)
        footerLabel2.Font = Enum.Font.GothamBold
        footerLabel2.Text = "❤️ Thank you"
        footerLabel2.TextColor3 = ACCENT
        footerLabel2.TextSize = 12
        footerLabel2.TextXAlignment = Enum.TextXAlignment.Center
    end
end

-- PLAYER EVENTS

game:GetService("Players").PlayerAdded:Connect(function()
    task.wait(0.3)
    if CurrentTab == "  Players" then
        UpdatePlayerList()
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function()
    task.wait(0.3)
    if CurrentTab == "  Players" then
        UpdatePlayerList()
    end
end)

lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if settings.speedEnabled and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = settings.Speed
    end
    espCache = {}
    UpdateESP()
    UpdateDoubleJump()
    UpdateKillerChance()
    if CurrentTab == "  Players" then
        task.wait(0.5)
        UpdatePlayerList()
    end
end)

-- INIT

local updateConnection = RunService.Stepped:Connect(PeriodicUpdates)

workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "ExitGateways" or descendant.Name == "Doorway" or descendant.Name == "Frame" then
        task.wait(0.5)
        UpdateESPExits()
    end
    if descendant.Name == "Trap" then
        task.wait(0.5)
        UpdateESPTraps()
    end
end)

workspace.DescendantRemoved:Connect(function()
    task.wait(0.5)
    UpdateESPExits()
    UpdateESPTraps()
end)

UpdateNoFog()
UpdateESP()
UpdateESPExits()
UpdateESPTraps()
UpdateDoubleJump()
UpdateKillerChance()
UpdateRightContent()
UpdateAllFeatures()

notif("✨ sa7loul V2 — loaded", 3)
