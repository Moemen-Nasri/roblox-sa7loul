-- sa7loul | Survive the Killer V3 Premium
-- Support version v2.31.0
-- BUILD: FIXED-2026-08-15 (telemetry + keybinds gpe fix)

-- file telemetry: writes sa7loul_Debug.txt in the executor workspace so we can
-- see exactly how far the script got inside the game (read it back on the PC)
local dbgLog = {}
local dbgLast = os.clock()
local function Dbg(step, extra)
    dbgLog[#dbgLog + 1] = step .. (extra and (" | " .. tostring(extra)) or "")
    if #dbgLog > 300 then table.remove(dbgLog, 1) end
    if os.clock() - dbgLast > 1.5 then
        dbgLast = os.clock()
        pcall(function() writefile("sa7loul_Debug.txt", table.concat(dbgLog, "\n")) end)
    end
end
pcall(function() writefile("sa7loul_Debug.txt", "CHUNK_START\n") end)
Dbg("CHUNK_START")

-- boot marker - proves the script actually started on the executor
pcall(function()
    warn("[sa7loul] script executing...")
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "sa7loul", Text = "V3 FIXED started" })
end)

configs = {
    savedConfigs = {},
    currentConfigName = "Default"
}

-- forward declarations: these locals are referenced by closures created earlier in the chunk
local StopBring, StopBringAll, SafeLoadScript, scan, SwitchTab, UpdateAllFeatures, UpdatePlayerList, UpdateRightContent, TextBox, ApplyMinimized, PeriodicESPUpdate, close, apply, hide, TrollFlingStop, TrollAnnoyStop, TrollEarrapeStop, minimized

defaultSettings = {
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

userScripts = {}

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

more_scripts = {
    {
        name = "sa7loul V1.4",
        script = "loadstring(game:HttpGet('https://raw.githubusercontent.com/AuriXDev/VHubs/refs/heads/main/old/STK_V1_4.lua'))()"
    },
    {
        name = "Infinite Yield",
        script = "loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()"
    }
}

-- make LocalPlayer nil-safe: wait for it to appear (works on early inject)
local lp = nil
local function RefreshLP()
    if lp and lp.Parent then return true end
    local plrs = game:GetService("Players")
    lp = plrs.LocalPlayer
    if not lp then lp = plrs:GetPlayers()[1] end
    return lp ~= nil
end
for _ = 1, 200 do
    if RefreshLP() then break end
    task.wait(0.05)
end
RefreshLP()
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
Lighting = game:GetService("Lighting")
StarterGui = game:GetService("StarterGui")
TweenService = game:GetService("TweenService")
HttpService = game:GetService("HttpService")

-- DESIGN COLORS a soft rose & teal palette
ACCENT = Color3.fromRGB(255, 94, 148)      -- soft rose
ACCENT_DARK = Color3.fromRGB(196, 60, 106)
TEAL = Color3.fromRGB(61, 224, 200)
BG_MAIN = Color3.fromRGB(13, 14, 20)
BG_PANEL = Color3.fromRGB(19, 20, 30)
BG_ELEMENT = Color3.fromRGB(28, 30, 44)
BG_HOVER = Color3.fromRGB(40, 43, 62)
TEXT_PRIMARY = Color3.fromRGB(248, 248, 252)
TEXT_SECONDARY = Color3.fromRGB(165, 168, 190)
TEXT_DIM = Color3.fromRGB(95, 98, 125)
BORDER_COLOR = Color3.fromRGB(40, 42, 62)

local function notif(str, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "sa7loul V3",
            Text = str,
            Duration = dur or 3
        })
    end)
end

local settings = {}
for k, v in pairs(defaultSettings) do
    settings[k] = v
end

spinActive = false
spinSpeed = 20
bringActive = false
bringAllActive = false
FlingActive = false
viewing = nil
viewDied = nil
viewChanged = nil
flyConnection = nil
noclipConnection = nil
brightLoop = nil
lootConnection = nil
killAuraConnection = nil
reviveLegitConnection = nil
selfReviveConnection = nil
autoEscapeConnection = nil
noFogConnection = nil
antiAFKConnection = nil
antiTrapConnection = nil
panicTPConnection = nil
espObjects = {}
espExitObjects = {}
espTrapObjects = {}
savedHomePosition = nil
isReviving = false
lastSelfReviveTime = 0
espCache = {}
CurrentTab = "Home"
lastEscapeTime = 0
timerActive = false
panicTPCooldown = 0
playerListCache = {}
playerListContainer = nil
selectedPlayer = nil
selectedPlayerLabel = nil
bringOrigins = {}
flyFx = {}
voiceFx = {active = false, hub = nil, saved = {}}
invisActive = false
invisConn = nil
invisSaved = {}
adminRemotesCache = nil
unpack2 = table.unpack or unpack

bringDistance = 4
flingForce = 9999

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
            selectedPlayerLabel.Text = "Player: " .. selectedPlayer.Name
        else
            selectedPlayerLabel.Text = "Player: None"
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
            
            local targetPos = myRoot.Position + (myRoot.CFrame.LookVector * (bringDistance or 4))
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

StopBring = function()
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
                                    local r = math.floor(c.R * 10 + 0.5) / 10
                                    local g = math.floor(c.G * 10 + 0.5) / 10
                                    local b = math.floor(c.B * 10 + 0.5) / 10
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
            local r = math.floor(c.R * 10 + 0.5) / 10
            local g = math.floor(c.G * 10 + 0.5) / 10
            local b = math.floor(c.B * 10 + 0.5) / 10
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

StopBringAll = function()
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
        notif("Mic Bypass ON", 2)
    else
        notif("No character - enter a game first", 2)
    end
end

local function UnmuteMic()
    local vc = game:GetService("VoiceChatService")
    local hits = 0
    notif("Unmute running (30 reconnects)...", 2)
    for i = 1, 30 do
        local ok = pcall(function() vc:joinVoice() end)
        if ok then hits = hits + 1 end
        task.wait(2)
    end
    notif("Unmute done: " .. hits .. " reconnects", 2)
end

local function ScanUnbanRemotes()
    local remotes = {}
    local roots = {game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), game:GetService("ServerStorage"), workspace}
    for _, root in ipairs(roots) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local n = string.lower(obj.Name)
                    if n:match("ban") or n:match("unban") or n:match("kick") or n:match("mod")
                        or n:match("whitelist") or n:match("admin") or n:match("panel") or n:match("command")
                        or n:match("staff") or n:match("mute") then
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
    local uid = tostring(lp.UserId)
    local payloads = {
        {"unban", lp.UserId}, {"unban", lp.Name},
        {"unban", lp.UserId, true}, {"unban", lp.Name, true},
        {"Unban", lp.UserId}, {"Unban", lp.Name},
        {"unbanUser", lp.UserId}, {"unbanByUserId", lp.UserId},
        {"unban", uid}, {"unban", uid, true},
        {"whitelist", lp.UserId}, {"whitelist", lp.Name},
        {"unban", lp}, {"ban", lp.UserId, false}
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
        local raw1 = pcall(function()
            if remote:IsA("RemoteFunction") then remote:InvokeServer(lp)
            else remote:FireServer(lp) end
        end)
        local raw2 = pcall(function()
            if remote:IsA("RemoteFunction") then remote:InvokeServer(lp.UserId)
            else remote:FireServer(lp.UserId) end
        end)
        local raw3 = pcall(function()
            if remote:IsA("RemoteFunction") then remote:InvokeServer(lp.UserId, true)
            else remote:FireServer(lp.UserId, true) end
        end)
        if raw1 then hits = hits + 1 end
        if raw2 then hits = hits + 1 end
        if raw3 then hits = hits + 1 end
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

bannedCache = {}
banListContainer = nil
storageDump = {}
banBox = nil
customBox = nil
autoUnbanOn = true
autoRejoinOn = false

local function StorageScan()
    storageDump = {}
    local roots = {game:GetService("ReplicatedStorage"), workspace}
    local count = 0
    for _, root in ipairs(roots) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if count >= 150 then break end
                local extra = ""
                if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("NumberValue") or obj:IsA("BoolValue") then
                    extra = " = " .. tostring(obj.Value)
                end
                table.insert(storageDump, obj.ClassName .. " | " .. obj.Name .. extra)
                count = count + 1
            end
        end
    end
    for _, obj in ipairs({game, lp}) do
        for k, v in pairs(obj:GetAttributes()) do
            if count < 150 then
                table.insert(storageDump, "Attr | " .. tostring(k) .. " = " .. tostring(v))
                count = count + 1
            end
        end
    end
    notif("Storage scan: " .. #storageDump .. " entries", 2)
    if CurrentTab == "Ban" then UpdateRightContent() end
end

local function FireCustomRemote()
    local input = customBox and customBox.Text or ""
    if input == "" then
        notif("Write: RemoteName,arg1,arg2", 2)
        return
    end
    local parts = {}
    for part in string.gmatch(input, "[^,]+") do
        table.insert(parts, part)
    end
    if #parts == 0 then return end
    local args = {}
    for i = 2, #parts do
        if parts[i]:match("^%-?%d+$") then
            args[i - 1] = tonumber(parts[i])
        else
            args[i - 1] = parts[i]
        end
    end
    local remote = nil
    for _, root in ipairs({game:GetService("ReplicatedStorage"), workspace}) do
        if root and not remote then
            remote = root:FindFirstChild(parts[1], true)
        end
    end
    if not remote or not (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
        notif("Remote not found: " .. parts[1], 2)
        return
    end
    local fired = pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(unpack2(args))
        else
            remote:FireServer(unpack2(args))
        end
    end)
    notif(fired and ("Fired: " .. parts[1] .. " (" .. #args .. " args)") or "Fire failed", 2)
end

local function BlastUnban()
    local target = (banBox and banBox.Text ~= "") and banBox.Text or lp.Name
    local id = tonumber(target) or target
    local remotes = {}
    for _, root in ipairs({game:GetService("ReplicatedStorage"), workspace}) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    table.insert(remotes, obj)
                end
            end
        end
    end
    if #remotes == 0 then
        notif("No remotes found", 2)
        return
    end
    local payloads = {
        {"unban", id}, {"unban", id, true}, {"Unban", id}, {"Unban", id, true},
        {id}, {id, true}, {"unban", id, "0"}, {"ban", id, false}, {"kick", id}
    }
    local hits = 0
    for _, r in ipairs(remotes) do
        for _, args in ipairs(payloads) do
            local fired = pcall(function()
                if r:IsA("RemoteFunction") then
                    r:InvokeServer(unpack2(args))
                else
                    r:FireServer(unpack2(args))
                end
            end)
            if fired then hits = hits + 1 end
        end
    end
    notif("Blast: " .. #remotes .. " remotes, " .. hits .. " fired ok", 2)
end

local function DoUnban(name)
    if not name or name == "" then
        notif("Write a name or ID first", 2)
        return
    end
    local remotes = ScanUnbanRemotes()
    if #remotes == 0 then
        notif("No ban remotes found", 2)
        return
    end
    local id = tonumber(name) or name
    local payloads = {
        {"unban", name}, {"unban", id, true}, {"Unban", name}, {"Unban", id},
        {"unbanUser", id}, {"unbanByUserId", id}, {"unban", id, false},
        {"whitelist", id}, {"unban", id, "0"}
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
                remote:InvokeServer(id)
            else
                remote:FireServer(id)
            end
        end)
        if raw then hits = hits + 1 end
    end
    notif("Unban fired for: " .. name .. " (" .. hits .. ")", 2)
end

local function FetchBanList()
    bannedCache = {}
    local seen = {}
    local function addEntry(entry)
        local name = nil
        if type(entry) == "string" then
            name = entry
        elseif type(entry) == "number" then
            name = tostring(entry)
        elseif typeof(entry) == "Instance" then
            name = entry.Name
        elseif type(entry) == "table" then
            name = entry.Name or entry.name or entry.username or (entry.UserId and tostring(entry.UserId)) or (entry.userId and tostring(entry.userId))
        end
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(bannedCache, name)
        end
    end
    local remotes = {}
    for _, root in ipairs({game:GetService("ReplicatedStorage"), workspace}) do
        if root then
            for _, obj in ipairs(root:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and string.lower(obj.Name):match("ban") then
                    table.insert(remotes, obj)
                end
            end
        end
    end
    for _, r in ipairs(remotes) do
        if r:IsA("RemoteFunction") then
            local ok, res = pcall(function()
                return r:InvokeServer()
            end)
            if ok and type(res) == "table" then
                for _, entry in ipairs(res) do addEntry(entry) end
            end
            if #bannedCache > 0 then break end
            for _, p in ipairs({{"getBans"}, {"GetBans"}, {"getBanList"}, {"GetBanList"}, {"getBannedUsers"}, {"GetBannedUsers"}, {"get"}, {"fetch"}, {"list"}}) do
                local ok2, res2 = pcall(function()
                    return r:InvokeServer(unpack2(p))
                end)
                if ok2 and type(res2) == "table" then
                    for _, entry in ipairs(res2) do addEntry(entry) end
                    if #bannedCache > 0 then break end
                end
            end
        end
        if #bannedCache > 0 then break end
    end
    if #bannedCache == 0 then
        for _, root in ipairs({game:GetService("ReplicatedStorage"), workspace}) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    local n = string.lower(obj.Name)
                    if n:match("ban") or n:match("banned") or n:match("blacklist") then
                        if obj:IsA("Folder") or obj:IsA("Model") then
                            for _, child in ipairs(obj:GetChildren()) do
                                addEntry(child)
                                if child:IsA("IntValue") then addEntry(child.Value) end
                            end
                        elseif obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("NumberValue") then
                            addEntry(obj)
                            if obj:IsA("IntValue") then addEntry(obj.Value) end
                        end
                    end
                end
            end
        end
    end
    if #bannedCache > 0 then
        notif("Found " .. #bannedCache .. " banned player(s)", 2)
    else
        notif("Ban list not exposed (protected)", 2)
    end
    if CurrentTab == "Ban" then UpdateRightContent() end
end

local function UnbanAllFromList()
    if #bannedCache == 0 then
        notif("Ban list empty - fetch first", 2)
        return
    end
    for _, name in ipairs(bannedCache) do
        DoUnban(name)
        task.wait(0.05)
    end
    notif("Unban fired for all " .. #bannedCache, 2)
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

SafeLoadScript = function(scriptData)
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
    local ok = pcall(isfolder, configsFolder)
    if not ok or not isfolder(configsFolder) then
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
    local ok = pcall(isfolder, configsFolder)
    if not ok then return {} end
    if not isfolder(configsFolder) then
        pcall(makefolder, configsFolder)
        return {}
    end
    
    local files = {}
    local ok2, listing = pcall(listfiles, configsFolder)
    if not ok2 or not listing then return {} end
    for _, file in ipairs(listing) do
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

UpdateAllFeatures = function()
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

lastUpdate = 0
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

lastESPUpdate = 0
PeriodicESPUpdate = function()
    if tick() - lastESPUpdate >= 0.5 then
        lastESPUpdate = tick()
        UpdateESP()
        UpdateESPExits()
        UpdateESPTraps()
        UpdatePlayerList()
    end
end

-- =====================================================================
-- a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-
--  NOVA UI FRAMEWORK - sa7loul V3 PREMIUM REDESIGN
--  Dark mode + neon accents | RGB mode | rounded corners | glow
--  Draggable header | search | fluid tab navigation
-- a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-
CoreGui    = game:GetService("CoreGui")
GuiService = game:GetService("GuiService")
SoundService = game:GetService("SoundService")
PlayersSvc = game:GetService("Players")

-- aaaaaaaaaaaaaaaaaaaaaaaaaa THEME aaaaaaaaaaaaaaaaaaaaaaaaaa
UITheme = {
    BG        = Color3.fromRGB(8, 10, 24),
    BG_DEEP   = Color3.fromRGB(13, 11, 34),
    PANEL     = Color3.fromRGB(16, 18, 44),
    ELEMENT   = Color3.fromRGB(26, 29, 60),
    HOVER     = Color3.fromRGB(40, 44, 88),
    TEXT      = Color3.fromRGB(244, 246, 255),
    SUBTEXT   = Color3.fromRGB(152, 158, 200),
    DIM       = Color3.fromRGB(98, 104, 148),
    CYAN      = Color3.fromRGB(0, 229, 255),
    PURPLE    = Color3.fromRGB(132, 96, 255),
    MAGENTA   = Color3.fromRGB(255, 64, 204),
    GREEN     = Color3.fromRGB(64, 233, 142),
    RED       = Color3.fromRGB(255, 84, 108),
    AMBER     = Color3.fromRGB(255, 190, 62),
    BORDER    = Color3.fromRGB(48, 52, 96),
    RGB       = false,
    Accent    = Color3.fromRGB(0, 229, 255),
    Hue       = 0.5,
}
function UITheme:AccentGradient()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, UITheme.Accent),
        ColorSequenceKeypoint.new(1, UITheme.MAGENTA)
    })
end
Dbg("UI_THEME_OK")
function UITheme:RegisterAccentGradient(grad)
    self:RegisterAccent(function(c)
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c),
            ColorSequenceKeypoint.new(1, UITheme.MAGENTA)
        })
    end, true)
end

-- verified lucide decal icons
ICON_ASSETS = {
    home = "rbxassetid://7733960981",
    user = "rbxassetid://7743875962",
    heart = "rbxassetid://7733956134",
    globe = "rbxassetid://7733954760",
    users = "rbxassetid://7743876054",
    smile = "rbxassetid://7734059095",
    box = "rbxassetid://7733917120",
    skull = "rbxassetid://7734058599",
    userx = "rbxassetid://7743875879",
    droplet = "rbxassetid://7733770982",
    more = "rbxassetid://7734006080",
    gear = "rbxassetid://7734053495",
    search = "rbxassetid://7734052925",
    plane = "rbxassetid://7734037723",
    activity = "rbxassetid://7733655755",
    eye = "rbxassetid://7733774602",
    target = "rbxassetid://7743872758",
    zap = "rbxassetid://7733771628",
    shield = "rbxassetid://7734056608",
    map = "rbxassetid://7733992829",
    key = "rbxassetid://7733965118",
    terminal = "rbxassetid://7743872929",
    code = "rbxassetid://7733749837",
    folder = "rbxassetid://7733799185",
    save = "rbxassetid://7734052335",
    database = "rbxassetid://7743866778",
    trash = "rbxassetid://7743873871",
    music = "rbxassetid://7734020554",
    volume = "rbxassetid://7743877487",
    mic = "rbxassetid://7743869805",
    palette = "rbxassetid://7734021595",
    gauge = "rbxassetid://7733799969",
    history = "rbxassetid://7733960880",
    check = "rbxassetid://7733715400",
    crown = "rbxassetid://7733765398",
    star = "rbxassetid://7734068321",
    flame = "rbxassetid://7733798747",
    ghost = "rbxassetid://7743868000",
    snow = "rbxassetid://7734059180",
    compass = "rbxassetid://7733924216",
    hammer = "rbxassetid://7733955511",
    verni = "rbxassetid://7743867310",
}
SECTION_ICONS = {
    ["Flight & NoClip"] = "plane",
    ["Movement"] = "activity",
    ["Kill Aura"] = "target",
    ["ESP"] = "eye",
    ["Extraction"] = "map",
    ["Revive"] = "heart",
    ["Loot"] = "box",
    ["Auto"] = "zap",
    ["Visuals"] = "palette",
    ["Anti"] = "shield",
    ["Bypass"] = "shield",
    ["Auto Loot"] = "box",
    ["Teleport"] = "compass",
    ["Quick teleports"] = "plane",
    ["Self revive"] = "heart",
    ["Target"] = "target",
    ["Combat"] = "target",
    ["Powers"] = "zap",
    ["Player list"] = "users",
    ["Revive modes"] = "heart",
    ["Party"] = "smile",
    ["Custom search"] = "search",
    ["Troll Target"] = "userx",
    ["Annoy & Fling"] = "flame",
    ["Fake Admin / System Chat"] = "terminal",
    ["Ghost & Tools"] = "ghost",
    ["Screen Chaos"] = "eye",
    ["Earrape Audio"] = "music",
    ["Ban Manager"] = "hammer",
    ["Banned players"] = "userx",
    ["Popcorn Burst"] = "flame",
    ["External scripts"] = "code",
    ["Your scripts"] = "folder",
    ["Keybinds"] = "key",
    ["Theme"] = "palette",
    ["Configs"] = "save",
    ["Saved configs"] = "database",
    ["Account"] = "user",
    ["Other"] = "more",
    ["Camera"] = "eye",
    ["Take from target"] = "box",
    ["Fake Admin (remotes)"] = "terminal",
    ["Storage scan"] = "database",
    ["Legacy auto-helpers"] = "zap",
    ["Welcome back"] = "home",
    ["Quick access"] = "zap",
    ["Changelog V3"] = "history",
}
accentListeners = {}
coreAccentListeners = {}
function UITheme:RegisterAccent(fn, core)
    if core then
        table.insert(coreAccentListeners, fn)
    else
        table.insert(accentListeners, fn)
    end
end
function UITheme:ApplyAccent()
    for _, fn in ipairs(coreAccentListeners) do
        pcall(fn, UITheme.Accent)
    end
    for _, fn in ipairs(accentListeners) do
        pcall(fn, UITheme.Accent)
    end
end
function UITheme:ClearContentAccents()
    accentListeners = {}
end
function UITheme:Tick(dt)
    if UITheme.RGB then
        UITheme.Hue = (UITheme.Hue + dt * 0.45) % 1
        UITheme.Accent = Color3.fromHSV(UITheme.Hue, 0.9, 1)
        UITheme:ApplyAccent()
    end
end

-- aaaaaaaaaaaaaaaaaaaaaaaaaa ROOT aaaaaaaaaaaaaaaaaaaaaaaaaa
NovaUI = Instance.new("ScreenGui")
NovaUI.Name = "sa7loul_V3"
NovaUI.ResetOnSpawn = false
NovaUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- safe GUI parent: PlayerGui internals are 100% standard API on any executor,
-- CoreGui only as a fallback. no gethui/syn natives (they crash some executors)
NovaUIParent = nil
pcall(function()
    local lp0 = game:GetService("Players").LocalPlayer
    if lp0 and lp0:FindFirstChild("PlayerGui") then
        NovaUIParent = lp0.PlayerGui
    end
end)
NovaUIParent = NovaUIParent or CoreGui
pcall(function()
    NovaUI.Parent = NovaUIParent
end)
if not NovaUI.Parent then
    NovaUI.Parent = CoreGui
end

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Parent = NovaUI
Window.BackgroundColor3 = UITheme.BG
Window.BackgroundTransparency = 0
Window.BorderSizePixel = 0
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.Position = UDim2.fromScale(0.5, 0.5)
Window.Size = UDim2.new(0, 720, 0, 540)
windowCorner = Instance.new("UICorner", Window)
windowCorner.CornerRadius = UDim.new(0, 8)
windowStroke = Instance.new("UIStroke", Window)
windowStroke.Thickness = 1.5
windowStroke.Color = UITheme.BORDER
windowStroke.Transparency = 0.15
windowStrokeGrad = Instance.new("UIGradient", windowStroke)
windowStrokeGrad.Color = UITheme:AccentGradient()
windowStrokeGrad.Rotation = 45
UITheme:RegisterAccentGradient(windowStrokeGrad)
windowGradient = Instance.new("UIGradient", Window)
windowGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 16, 52)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 14, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 24))
})
windowGradient.Rotation = 130
-- acrylic frosted glass (localized blur - cheap, no full-screen cost)
-- guarded: some executors lack UIBlurEffect, so skip it instead of dying
pcall(function()
    local blur = Instance.new("UIBlurEffect")
    blur.Name = "AcrylicBlur"
    blur.Parent = Window
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BlurSize = 12
    blur.CornerRadius = UDim.new(0, 8)
end)

-- subtle drop shadow glow (no full-screen blur = zero lag)
glowHalo = Instance.new("Frame")
glowHalo.Name = "GlowHalo"
glowHalo.Parent = Window
glowHalo.BackgroundColor3 = UITheme.BG_DEEP
glowHalo.BackgroundTransparency = 0.7
glowHalo.BorderSizePixel = 0
glowHalo.Size = UDim2.new(1, 28, 1, 28)
glowHalo.Position = UDim2.new(0, -14, 0, -14)
glowHalo.ZIndex = -1
Instance.new("UICorner", glowHalo).CornerRadius = UDim.new(0, 16)

-- resize corner (bottom-right)
resizeCorner = Instance.new("TextButton")
resizeCorner.Name = "ResizeCorner"
resizeCorner.Parent = Window
resizeCorner.Size = UDim2.new(0, 20, 0, 20)
resizeCorner.Position = UDim2.new(1, -20, 1, -20)
resizeCorner.BackgroundColor3 = UITheme.Accent
resizeCorner.BackgroundTransparency = 0.8
resizeCorner.BorderSizePixel = 0
resizeCorner.Text = ""
resizeCorner.ZIndex = 10
resizeCorner.AutoButtonColor = false
Instance.new("UICorner", resizeCorner).CornerRadius = UDim.new(0, 4)
resizeCorner.MouseEnter:Connect(function()
    TweenService:Create(resizeCorner, TweenInfo.new(0.1), {BackgroundTransparency = 0.4}):Play()
end)
resizeCorner.MouseLeave:Connect(function()
    TweenService:Create(resizeCorner, TweenInfo.new(0.15), {BackgroundTransparency = 0.8}):Play()
end)
resizeCorner.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if minimized then return end
        registerDragStart(input.Position)
    end
end)

-- top neon accent line
accentLine = Instance.new("Frame")
accentLine.Name = "AccentLine"
accentLine.Parent = Window
accentLine.BackgroundColor3 = UITheme.Accent
accentLine.BorderSizePixel = 0
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.ZIndex = 10
accentLineGrad = Instance.new("UIGradient", accentLine)
accentLineGrad.Color = UITheme:AccentGradient()
accentLineGrad.Rotation = 90
UITheme:RegisterAccentGradient(accentLineGrad)

-- opening animation (non-fatal - UI must never depend on it)
Window.Size = UDim2.new(0, 720, 0, 540)
pcall(function()
    TweenService:Create(Window, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 720, 0, 540)
    }):Play()
end)

-- aaaaaaaaaaaaaaaaaaaaaaaaaa HEADER aaaaaaaaaaaaaaaaaaaaaaaaaa
Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = Window
Header.BackgroundColor3 = UITheme.PANEL
Header.BackgroundTransparency = 0.2
Header.BorderSizePixel = 0
Header.Size = UDim2.new(1, 0, 0, 54)
Header.ZIndex = 5
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)
headerGrad = Instance.new("UIGradient", Header)
headerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 17, 58)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(14, 16, 44)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 12, 34))
})
headerGrad.Rotation = 90
headerBottom = Instance.new("Frame")
headerBottom.Parent = Header
headerBottom.BackgroundColor3 = UITheme.BORDER
headerBottom.BackgroundTransparency = 0.5
headerBottom.BorderSizePixel = 0
headerBottom.Size = UDim2.new(1, 0, 0, 1)
headerBottom.Position = UDim2.new(0, 0, 1, 0)

-- premium logo badge (pure UI)
logoBox = Instance.new("Frame")
logoBox.Name = "LogoBox"
logoBox.Parent = Header
logoBox.BackgroundColor3 = UITheme.BG_DEEP
logoBox.BackgroundTransparency = 0
logoBox.BorderSizePixel = 0
logoBox.Size = UDim2.new(0, 34, 0, 34)
logoBox.Position = UDim2.new(0, 14, 0.5, -17)
logoCorner = Instance.new("UICorner", logoBox)
logoCorner.CornerRadius = UDim.new(0, 9)
logoGrad = Instance.new("UIGradient", logoBox)
logoGrad.Color = UITheme:AccentGradient()
logoGrad.Rotation = 135
UITheme:RegisterAccentGradient(logoGrad)
logoStroke = Instance.new("UIStroke", logoBox)
logoStroke.Thickness = 1.5
logoStroke.Color = UITheme.Accent
logoStroke.Transparency = 0.2
UITheme:RegisterAccent(function(c) logoStroke.Color = c end, true)
logoText = Instance.new("TextLabel")
logoText.Parent = logoBox
logoText.BackgroundTransparency = 1
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.Font = Enum.Font.GothamBlack
logoText.Text = "s7"
logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
logoText.TextSize = 15
logoText.TextStrokeTransparency = 0.3

titleLabel = Instance.new("TextLabel")
titleLabel.Parent = Header
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "sa7loul"
titleLabel.TextColor3 = UITheme.TEXT
titleLabel.TextSize = 19
titleLabel.Size = UDim2.new(0, 120, 0, 20)
titleLabel.Position = UDim2.new(0, 56, 0, 8)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleAccent = Instance.new("TextLabel")
titleAccent.Parent = Header
titleAccent.BackgroundTransparency = 1
titleAccent.Font = Enum.Font.GothamBold
titleAccent.Text = "V3"
titleAccent.TextColor3 = UITheme.Accent
titleAccent.TextSize = 14
titleAccent.Size = UDim2.new(0, 30, 0, 18)
titleAccent.Position = UDim2.new(0, 148, 0, 9)
titleAccent.TextXAlignment = Enum.TextXAlignment.Left
UITheme:RegisterAccent(function(c) titleAccent.TextColor3 = c end, true)

headerSub = Instance.new("TextLabel")
headerSub.Parent = Header
headerSub.BackgroundTransparency = 1
headerSub.Font = Enum.Font.Gotham
headerSub.Text = "Survive the Killer | Premium"
headerSub.TextColor3 = UITheme.SUBTEXT
headerSub.TextSize = 11
headerSub.Size = UDim2.new(0, 260, 0, 16)
headerSub.Position = UDim2.new(0, 36, 0, 30)
headerSub.TextXAlignment = Enum.TextXAlignment.Left

local headerVer = Instance.new("TextLabel")
headerVer.Parent = Header
headerVer.BackgroundTransparency = 1
headerVer.Font = Enum.Font.GothamBold
headerVer.Text = "FIXED v3"
headerVer.TextColor3 = UITheme.GREEN
headerVer.TextSize = 9
headerVer.Size = UDim2.new(0, 60, 0, 12)
headerVer.Position = UDim2.new(1, -64, 0, 32)
headerVer.TextXAlignment = Enum.TextXAlignment.Right

-- header buttons (minimize / close)
local function headerIconButton(text, color)
    local btn = Instance.new("TextButton")
    btn.Parent = Header
    btn.BackgroundColor3 = UITheme.ELEMENT
    btn.BackgroundTransparency = 0.4
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(0, 26, 0, 26)
    btn.Position = UDim2.new(1, -74, 0.5, -13)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = color
    btn.TextSize = 14
    btn.ZIndex = 6
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
    end)
    AddPressAnim(btn)
    return btn
end

-- menu keybind chip shown in header
menuKeyChip = Instance.new("TextButton")
menuKeyChip.Parent = Header
menuKeyChip.BackgroundColor3 = UITheme.ELEMENT
menuKeyChip.BackgroundTransparency = 0.2
menuKeyChip.BorderSizePixel = 0
menuKeyChip.Size = UDim2.new(0, 90, 0, 24)
menuKeyChip.Position = UDim2.new(1, -250, 0.5, -12)
menuKeyChip.Font = Enum.Font.GothamBold
menuKeyChip.Text = "[ MENU: RIGHTSHIFT ]"
menuKeyChip.TextColor3 = UITheme.SUBTEXT
menuKeyChip.TextSize = 10
menuKeyChip.ZIndex = 6
Instance.new("UICorner", menuKeyChip).CornerRadius = UDim.new(0, 7)

minimizeBtn = headerIconButton("-", UITheme.GREEN)
minimizeBtn.Position = UDim2.new(1, -104, 0.5, -13)
closeBtn = headerIconButton("x", UITheme.RED)
closeBtn.Position = UDim2.new(1, -72, 0.5, -13)

minimizedHint = Instance.new("TextLabel")
minimizedHint.Parent = Header
minimizedHint.BackgroundTransparency = 1
minimizedHint.Font = Enum.Font.Gotham
minimizedHint.Text = "minimized -  click + to restore full menu"
minimizedHint.TextColor3 = UITheme.SUBTEXT
minimizedHint.TextSize = 10
minimizedHint.Size = UDim2.new(0, 220, 0, 16)
minimizedHint.Position = UDim2.new(0, 36, 0, 32)
minimizedHint.TextXAlignment = Enum.TextXAlignment.Left
minimizedHint.Visible = false

-- aaaaaaaaaaaaaaaaaaaaaaaaaa DRAG & RESIZE aaaaaaaaaaaaaaaaaaaaaaaaaa
minimized = false
local dragging = false
local resizing = false
local dragStartPos = Vector2.zero
local windowStartPos = Vector2.zero
local resizeStartPos = Vector2.zero
local windowStartSize = Vector2.zero
local dragLockUntil = 0
local suppressBtnClick = 0

local function pointInGui(pos, gui)
    if not gui then return false end
    local p = gui.AbsolutePosition
    local s = gui.AbsoluteSize
    return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if minimized then return end
        if os.clock() < dragLockUntil then return end
        local pos = input.Position
        if pointInGui(pos, minimizeBtn) or pointInGui(pos, closeBtn) or pointInGui(pos, menuKeyChip) then
            return
        end
        dragging = true
        dragStartPos = Vector2.new(pos.X, pos.Y)
        local curPos = Window.AbsolutePosition
        Window.AnchorPoint = Vector2.new(0, 0)
        Window.Position = UDim2.fromOffset(curPos.X, curPos.Y)
        windowStartPos = curPos
    end
end)

resizeCorner.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if minimized then return end
        resizing = true
        resizeStartPos = Vector2.new(input.Position.X, input.Position.Y)
        windowStartSize = Window.AbsoluteSize
        local curPos = Window.AbsolutePosition
        Window.AnchorPoint = Vector2.new(0, 0)
        Window.Position = UDim2.fromOffset(curPos.X, curPos.Y)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if dragging then
            local pos = input.Position
            local delta = Vector2.new(pos.X - dragStartPos.X, pos.Y - dragStartPos.Y)
            local viewport = workspace.CurrentCamera.ViewportSize
            local newX = math.clamp(windowStartPos.X + delta.X, 0, math.max(0, viewport.X - Window.AbsoluteSize.X))
            local newY = math.clamp(windowStartPos.Y + delta.Y, 0, math.max(0, viewport.Y - Window.AbsoluteSize.Y))
            Window.Position = UDim2.fromOffset(newX, newY)
        elseif resizing then
            local pos = input.Position
            local delta = Vector2.new(pos.X - resizeStartPos.X, pos.Y - resizeStartPos.Y)
            local viewport = workspace.CurrentCamera.ViewportSize
            local maxW = math.max(550, viewport.X - Window.AbsolutePosition.X)
            local maxH = math.max(400, viewport.Y - Window.AbsolutePosition.Y)
            local newWidth = math.clamp(windowStartSize.X + delta.X, 550, maxW)
            local newHeight = math.clamp(windowStartSize.Y + delta.Y, 400, maxH)
            Window.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        resizing = false
    end
end)

-- minimize / restore
ApplyMinimized = function(state)
    minimized = state
    minimizeBtn.Text = state and "+" or "-"
    headerSub.Visible = not state
    menuKeyChip.Visible = not state
    minimizedHint.Visible = state
    if state then
        Sidebar.Visible = false
        ContentScroll.Visible = false
        SearchBar.Visible = false
        statusBar.Visible = false
        pcall(function()
            TweenService:Create(Window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 300, 0, 54),
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.fromOffset(14, 14)
            }):Play()
        end)
        task.spawn(function()
            task.wait(0.25)
            if minimized then
                Window.AnchorPoint = Vector2.new(0, 0)
                Window.Position = UDim2.fromOffset(14, 14)
                Window.Size = UDim2.new(0, 300, 0, 54)
            end
        end)
    else
        Sidebar.Visible = true
        ContentScroll.Visible = true
        SearchBar.Visible = true
        statusBar.Visible = true
        pcall(function()
            TweenService:Create(Window, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 720, 0, 540),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5)
            }):Play()
        end)
        task.spawn(function()
            task.wait(0.32)
            if not minimized then
                Window.AnchorPoint = Vector2.new(0.5, 0.5)
                Window.Position = UDim2.fromScale(0.5, 0.5)
                Window.Size = UDim2.new(0, 720, 0, 540)
                if UpdateRightContent then pcall(UpdateRightContent) end
            end
        end)
    end
end
minimizeBtn.MouseButton1Click:Connect(function()
    if os.clock() < suppressBtnClick then return end
    ApplyMinimized(not minimized)
end)

closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Window, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 220, 0, 54)
    }):Play()
    task.wait(0.3)
    NovaUI:Destroy()
end)

-- aaaaaaaaaaaaaaaaaaaaaaaaaa SEARCH BAR aaaaaaaaaaaaaaaaaaaaaaaaaa
SearchBar = Instance.new("Frame")
SearchBar.Parent = Window
SearchBar.BackgroundTransparency = 1
SearchBar.Size = UDim2.new(1, -196, 0, 38)
SearchBar.Position = UDim2.new(0, 182, 0, 62)

searchIcon = Instance.new("ImageLabel")
searchIcon.Parent = SearchBar
searchIcon.BackgroundTransparency = 1
searchIcon.Image = ICON_ASSETS.search
searchIcon.ImageColor3 = UITheme.SUBTEXT
searchIcon.Size = UDim2.new(0, 15, 0, 15)
searchIcon.Position = UDim2.new(0, 8, 0.5, -7.5)

SearchBox = Instance.new("TextBox")
SearchBox.Parent = SearchBar
SearchBox.BackgroundColor3 = UITheme.ELEMENT
SearchBox.BackgroundTransparency = 0.35
SearchBox.BorderSizePixel = 0
SearchBox.Size = UDim2.new(1, -30, 1, 0)
SearchBox.Position = UDim2.new(0, 30, 0, 0)
SearchBox.Font = Enum.Font.Gotham
SearchBox.PlaceholderText = "Search features..."
SearchBox.PlaceholderColor3 = UITheme.DIM
SearchBox.Text = ""
SearchBox.TextColor3 = UITheme.TEXT
SearchBox.TextSize = 12
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIPadding", SearchBox).PaddingLeft = UDim.new(0, 10)
searchStroke = Instance.new("UIStroke", SearchBox)
searchStroke.Thickness = 1
searchStroke.Color = UITheme.BORDER
searchStroke.Transparency = 0.4
SearchBox.Focused:Connect(function()
    TweenService:Create(searchStroke, TweenInfo.new(0.15), {Color = UITheme.Accent, Transparency = 0}):Play()
end)
SearchBox.FocusLost:Connect(function()
    TweenService:Create(searchStroke, TweenInfo.new(0.15), {Color = UITheme.BORDER, Transparency = 0.4}):Play()
end)

-- aaaaaaaaaaaaaaaaaaaaaaaaaa SIDEBAR aaaaaaaaaaaaaaaaaaaaaaaaaa
Sidebar = Instance.new("Frame")
Sidebar.Parent = Window
Sidebar.BackgroundColor3 = UITheme.PANEL
Sidebar.BackgroundTransparency = 0.2
Sidebar.BorderSizePixel = 0
Sidebar.Position = UDim2.new(0, 0, 0, 56)
Sidebar.Size = UDim2.new(0, 170, 1, -56)
Sidebar.ZIndex = 4
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 14)
sidebarBottom = Instance.new("Frame")
sidebarBottom.Parent = Sidebar
sidebarBottom.BackgroundColor3 = UITheme.BORDER
sidebarBottom.BackgroundTransparency = 0.5
sidebarBottom.BorderSizePixel = 0
sidebarBottom.Size = UDim2.new(1, 0, 0, 1)
sidebarBottom.Position = UDim2.new(0, 0, 1, 0)

SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Parent = Sidebar
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 0
SidebarScroll.Size = UDim2.new(1, 0, 1, -56)
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebarList = Instance.new("UIListLayout", SidebarScroll)
sidebarList.Padding = UDim.new(0, 3)
sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", SidebarScroll).PaddingTop = UDim.new(0, 10)

sidebarTitle = Instance.new("TextLabel")
sidebarTitle.Parent = SidebarScroll
sidebarTitle.BackgroundTransparency = 1
sidebarTitle.LayoutOrder = -1
sidebarTitle.Size = UDim2.new(1, -24, 0, 24)
sidebarTitle.Font = Enum.Font.GothamBold
sidebarTitle.Text = "MENU"
sidebarTitle.TextColor3 = UITheme.Accent
sidebarTitle.TextSize = 12
sidebarTitle.TextXAlignment = Enum.TextXAlignment.Left
sidebarTitle.TextYAlignment = Enum.TextYAlignment.Center
UITheme:RegisterAccent(function(c) sidebarTitle.TextColor3 = c end, true)


TabItems = {
    { key = "Home",       icon = "home",   label = "Home" },
    { key = "Player",     icon = "user",   label = "Player" },
    { key = "Revive",     icon = "heart",  label = "Revive" },
    { key = "World",      icon = "globe",  label = "World" },
    { key = "Players",    icon = "users",  label = "Players" },
    { key = "Fun",        icon = "smile",  label = "Fun" },
    { key = "Spawner",    icon = "box",    label = "Spawner" },
    { key = "Troll",      icon = "skull",  label = "Troll" },
    { key = "Ban",        icon = "userx",  label = "Ban" },
    { key = "Tsunami",    icon = "droplet", label = "Tsunami" },
    { key = "Extras",     icon = "more",   label = "Extras" },
    { key = "Settings",   icon = "gear",   label = "Settings" },
}
TabButtons = {}

-- sidebar footer (RGB quick switch)
sidebarFooter = Instance.new("Frame")
sidebarFooter.Parent = Sidebar
sidebarFooter.BackgroundTransparency = 1
sidebarFooter.Size = UDim2.new(1, 0, 0, 40)
sidebarFooter.Position = UDim2.new(0, 0, 1, -46)
sidebarFooter.ZIndex = 8
rgbQuick = Instance.new("TextButton")
rgbQuick.Parent = sidebarFooter
rgbQuick.BackgroundColor3 = UITheme.ELEMENT
rgbQuick.BackgroundTransparency = 0.3
rgbQuick.BorderSizePixel = 0
rgbQuick.Size = UDim2.new(1, -24, 0, 28)
rgbQuick.Position = UDim2.new(0, 12, 0, 4)
rgbQuick.Font = Enum.Font.GothamBold
rgbQuick.Text = "RGB Mode: OFF"
rgbQuick.TextColor3 = UITheme.SUBTEXT
rgbQuick.TextSize = 10
rgbQuick.ZIndex = 9
Instance.new("UICorner", rgbQuick).CornerRadius = UDim.new(0, 7)

-- Adjust SidebarScroll so bottom tabs are not occluded by footer
SidebarScroll.Size = UDim2.new(1, 0, 1, -48)
Instance.new("UIPadding", SidebarScroll).PaddingBottom = UDim.new(0, 50)

tabVisuals = {}
local function BuildSidebar()
    for _, item in ipairs(TabItems) do
        local btn = Instance.new("TextButton")
        btn.Parent = SidebarScroll
        btn.BackgroundColor3 = UITheme.ELEMENT
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(1, -12, 0, 34)
        btn.Position = UDim2.new(0, 6, 0, 0)
        btn.LayoutOrder = #SidebarScroll:GetChildren()
        btn.Text = "  " .. item.label
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = UITheme.SUBTEXT
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextYAlignment = Enum.TextYAlignment.Center
        btn.AutoButtonColor = false
        btn.ZIndex = 5
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local tabGrad = Instance.new("UIGradient", btn)
        tabGrad.Color = UITheme:AccentGradient()
        tabGrad.Rotation = 90
        tabGrad.Transparency = NumberSequence.new(1)

        local iconImg = Instance.new("ImageLabel")
        iconImg.Parent = btn
        iconImg.BackgroundTransparency = 1
        iconImg.Image = ICON_ASSETS[item.icon] or ICON_ASSETS.more
        iconImg.ImageColor3 = UITheme.SUBTEXT
        iconImg.Size = UDim2.new(0, 16, 0, 16)
        iconImg.Position = UDim2.new(0, 12, 0.5, -8)
        iconImg.ZIndex = 6

        local tabLabel = Instance.new("TextLabel")
        tabLabel.Parent = btn
        tabLabel.BackgroundTransparency = 1
        tabLabel.Position = UDim2.new(0, 36, 0, 0)
        tabLabel.Size = UDim2.new(1, -42, 1, 0)
        tabLabel.Font = Enum.Font.GothamBold
        tabLabel.Text = item.label
        tabLabel.TextColor3 = UITheme.SUBTEXT
        tabLabel.TextSize = 12
        tabLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabLabel.TextYAlignment = Enum.TextYAlignment.Center
        tabLabel.ZIndex = 6

        local glowBar = Instance.new("Frame")
        glowBar.Parent = btn
        glowBar.BackgroundColor3 = UITheme.Accent
        glowBar.BorderSizePixel = 0
        glowBar.Size = UDim2.new(0, 3, 0.5, 0)
        glowBar.Position = UDim2.new(0, 0, 0.25, 0)
        glowBar.BackgroundTransparency = 1
        glowBar.ZIndex = 7
        Instance.new("UICorner", glowBar).CornerRadius = UDim.new(1, 0)
        UITheme:RegisterAccent(function(c) glowBar.BackgroundColor3 = c end, true)

        btn.MouseEnter:Connect(function()
            if CurrentTab ~= item.key then
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0.55}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if CurrentTab ~= item.key then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
            end
        end)
        btn.MouseButton1Click:Connect(function()
            if SwitchTab then
                SwitchTab(item.key)
            end
        end)
        TabButtons[item.key] = { btn = btn, glow = glowBar, icon = iconImg, label = tabLabel, grad = tabGrad }
        tabVisuals[item.key] = { btn = btn, glow = glowBar, icon = iconImg, label = tabLabel, grad = tabGrad }
    end
end
local function RefreshTabVisuals()
    if not tabVisuals then return end
    for key, vis in pairs(tabVisuals) do
        local active = (CurrentTab == key)
        TweenService:Create(vis.btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = active and 0.35 or 1
        }):Play()
        if vis.label then
            TweenService:Create(vis.label, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextColor3 = active and UITheme.TEXT or UITheme.SUBTEXT
            }):Play()
        end
        vis.grad.Transparency = active and NumberSequence.new(0.25) or NumberSequence.new(1)
        TweenService:Create(vis.icon, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageColor3 = active and UITheme.TEXT or UITheme.SUBTEXT
        }):Play()
        TweenService:Create(vis.glow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = active and 0 or 1
        }):Play()
    end
end

-- aaaaaaaaaaaaaaaaaaaaaaaaaa CONTENT aaaaaaaaaaaaaaaaaaaaaaaaaa
ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Parent = Window
ContentScroll.BackgroundColor3 = UITheme.BG
ContentScroll.BackgroundTransparency = 0.6
ContentScroll.BorderSizePixel = 0
ContentScroll.Position = UDim2.new(0, 182, 0, 108)
ContentScroll.Size = UDim2.new(1, -194, 1, -154)
ContentScroll.ScrollBarThickness = 4
ContentScroll.ScrollBarImageColor3 = UITheme.Accent
ContentScroll.ScrollBarImageTransparency = 0.4
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroll.ClipsDescendants = true
Instance.new("UIPadding", ContentScroll).PaddingTop = UDim.new(0, 8)
contentLayout = Instance.new("UIListLayout", ContentScroll)
contentLayout.Padding = UDim.new(0, 16)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- aaaaaaaaaaaaaaaaaaaaaaaaaa STATUS BAR aaaaaaaaaaaaaaaaaaaaaaaaaa
statusBar = Instance.new("Frame")
statusBar.Parent = Window
statusBar.BackgroundColor3 = UITheme.PANEL
statusBar.BackgroundTransparency = 0.35
statusBar.BorderSizePixel = 0
statusBar.Position = UDim2.new(0, 182, 1, -26)
statusBar.Size = UDim2.new(1, -194, 0, 26)
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 8)
Instance.new("UIPadding", statusBar).PaddingLeft = UDim.new(0, 10)

statusLabel = Instance.new("TextLabel")
statusLabel.Parent = statusBar
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "FPS: --  |  Ping: --ms  |  Players: --  |  RightShift = hide UI"
statusLabel.TextColor3 = UITheme.SUBTEXT
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
UITheme:RegisterAccent(function(c) statusLabel.TextColor3 = c end, true)

task.spawn(function()
    local lastFrame = os.clock()
    while statusLabel and statusLabel.Parent do
        pcall(function()
            local now = os.clock()
            local fps = 1 / math.max(0.001, now - lastFrame)
            lastFrame = now
            local ping = 0
            pcall(function()
                ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            local activeCount = 0
            for _, v in pairs(settings) do
                if v == true then activeCount = activeCount + 1 end
            end
            statusLabel.Text = "FPS: " .. math.floor(fps) .. "  |  Ping: " .. ping .. "ms  |  Players: " .. #PlayersSvc:GetPlayers() .. "  |  Active toggles: " .. activeCount .. "  |  RightShift = hide UI"
        end)
        task.wait(1)
    end
end)

-- aaaaaaaaaaaaaaaaaaaaaaaaaa COMPONENTS aaaaaaaaaaaaaaaaaaaaaaaaaa
activeRows = {}

local function ClearContent()
    activeRows = {}
    UITheme:ClearContentAccents()
    for _, child in ipairs(ContentScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function RefreshSearch()
    local q = SearchBox.Text:lower()
    for _, h in ipairs(activeRows) do
        local match = (q == "") or (h.tag and h.tag:find(q, 1, true))
        h.Row.Visible = match
    end
end
SearchBox:GetPropertyChangedSignal("Text"):Connect(RefreshSearch)

local function trackRow(row, tag)
    local handle = { Row = row, tag = tag and tag:lower() or "" }
    table.insert(activeRows, handle)
    return handle
end

local function Section(parent, title, icon)
    local section = Instance.new("Frame")
    section.Parent = parent
    section.BackgroundColor3 = UITheme.PANEL
    section.BackgroundTransparency = 0.35
    section.BorderSizePixel = 0
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.LayoutOrder = #parent:GetChildren()
    Instance.new("UICorner", section).CornerRadius = UDim.new(0, 8)
    local secStroke = Instance.new("UIStroke", section)
    secStroke.Thickness = 1
    secStroke.Color = UITheme.BORDER
    secStroke.Transparency = 0.4
    local secStrokeGrad = Instance.new("UIGradient", secStroke)
    secStrokeGrad.Color = UITheme:AccentGradient()
    secStrokeGrad.Rotation = 45
    secStrokeGrad.Transparency = NumberSequence.new(0.4)
    UITheme:RegisterAccentGradient(secStrokeGrad)
    local secPad = Instance.new("UIPadding", section)
    secPad.PaddingLeft = UDim.new(0, 12)
    secPad.PaddingRight = UDim.new(0, 12)
    secPad.PaddingTop = UDim.new(0, 8)
    secPad.PaddingBottom = UDim.new(0, 10)

    local head = Instance.new("Frame")
    head.Parent = section
    head.BackgroundTransparency = 1
    head.Size = UDim2.new(1, -24, 0, 26)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = head
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -90, 1, 0)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = UITheme.TEXT
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center

    local secIcon = nil
    local iconKey = (type(icon) == "string" and ICON_ASSETS[icon]) or (title and SECTION_ICONS[title])
    if iconKey then
        secIcon = Instance.new("ImageLabel")
        secIcon.Parent = head
        secIcon.BackgroundTransparency = 1
        secIcon.Image = ICON_ASSETS[iconKey] or iconKey
        secIcon.ImageColor3 = UITheme.Accent
        secIcon.Size = UDim2.new(0, 16, 0, 16)
        secIcon.Position = UDim2.new(0, 0, 0.5, -8)
        titleLabel.Position = UDim2.new(0, 22, 0, 0)
        UITheme:RegisterAccent(function(c) secIcon.ImageColor3 = c end)
    end

    local line = Instance.new("Frame")
    line.Parent = head
    line.BackgroundColor3 = UITheme.BORDER
    line.BackgroundTransparency = 0.4
    line.BorderSizePixel = 0
    line.Size = UDim2.new(0.32, 0, 0, 1)
    line.Position = UDim2.new(1, -110, 0.5, 0)
    local lineGrad = Instance.new("UIGradient", line)
    lineGrad.Color = UITheme:AccentGradient()
    lineGrad.Rotation = 90
    lineGrad.Transparency = NumberSequence.new(0.4)
    UITheme:RegisterAccentGradient(lineGrad)

    local items = Instance.new("Frame")
    items.Parent = section
    items.BackgroundTransparency = 1
    items.Position = UDim2.new(0, 0, 0, 30)
    items.Size = UDim2.new(1, 0, 0, 0)
    items.AutomaticSize = Enum.AutomaticSize.Y
    local itemLayout = Instance.new("UIListLayout", items)
    itemLayout.Padding = UDim.new(0, 6)
    itemLayout.SortOrder = Enum.SortOrder.LayoutOrder

    return items
end

-- hover helper for pill buttons
local function MakeHover(btn, baseTransparency, hoverTransparency, isAccent)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = hoverTransparency}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundTransparency = isAccent and 0.15 or baseTransparency
        }):Play()
    end)
end

local function Button(parent, opts, thirdArg)
    if type(opts) == "string" then
        opts = { text = opts, callback = thirdArg }
    end
    opts = opts or {}
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BorderSizePixel = 0
    btn.Size = opts.size or UDim2.new(1, 0, 0, 32)
    btn.LayoutOrder = #parent:GetChildren()
    btn.Font = Enum.Font.GothamBold
    btn.Text = opts.text or "Button"
    btn.TextColor3 = opts.accent and Color3.fromRGB(255, 255, 255) or UITheme.TEXT
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = opts.accent and UITheme.Accent or UITheme.ELEMENT
    btn.BackgroundTransparency = opts.accent and 0.15 or 0.35
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1
    stroke.Color = opts.accent and UITheme.Accent or UITheme.BORDER
    stroke.Transparency = 0.7
    if opts.accent then
        local btnGrad = Instance.new("UIGradient", btn)
        btnGrad.Color = UITheme:AccentGradient()
        btnGrad.Rotation = 135
        btnGrad.Transparency = NumberSequence.new(0.15)
        UITheme:RegisterAccentGradient(btnGrad)
        UITheme:RegisterAccent(function(c)
            stroke.Color = c
        end)
    end
    btn.MouseButton1Click:Connect(function()
        pcall(opts.callback)
    end)
    MakeHover(btn, 0.35, 0.1, opts.accent)
    AddPressAnim(btn)
    trackRow(btn, opts.text)
    return btn
end

local function Label(parent, text, color, size)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 22)
    label.LayoutOrder = #parent:GetChildren()
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = color or UITheme.TEXT
    label.TextSize = size or 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.RichText = true
    return label
end

local function Note(parent, text)
    local label = Label(parent, text, UITheme.DIM, 10)
    label.RichText = true
    return label
end

TextBox = function(parent, opts)
    opts = opts or {}
    local box = Instance.new("TextBox")
    box.Parent = parent
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1, 0, 0, 32)
    box.LayoutOrder = #parent:GetChildren()
    box.BackgroundColor3 = UITheme.ELEMENT
    box.BackgroundTransparency = 0.5
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = opts.placeholder or ""
    box.PlaceholderColor3 = UITheme.DIM
    box.Text = opts.initial or ""
    box.TextColor3 = UITheme.TEXT
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", box)
    stroke.Thickness = 1
    stroke.Color = UITheme.BORDER
    stroke.Transparency = 0.5
    box.Focused:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Color = UITheme.Accent, Transparency = 0}):Play()
    end)
    box.FocusLost:Connect(function(enter)
        TweenService:Create(stroke, TweenInfo.new(0.15), {Color = UITheme.BORDER, Transparency = 0.5}):Play()
        if enter and opts.onEnter then
            pcall(opts.onEnter, box.Text)
        end
    end)
    return box
end

local function Slider(parent, opts)
    opts = opts or {}
    local min, max = opts.min or 0, opts.max or 100
    local def = opts.def or min
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.LayoutOrder = #parent:GetChildren()

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -60, 0, 18)
    label.Font = Enum.Font.Gotham
    label.Text = opts.text or ""
    label.TextColor3 = UITheme.TEXT
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0, 56, 0, 18)
    valueLabel.Position = UDim2.new(1, -56, 0, 0)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(def)
    valueLabel.TextColor3 = UITheme.Accent
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    UITheme:RegisterAccent(function(c) valueLabel.TextColor3 = c end)

    local track = Instance.new("Frame")
    track.Parent = frame
    track.BorderSizePixel = 0
    track.Position = UDim2.new(0, 0, 0, 24)
    track.Size = UDim2.new(1, 0, 0, 5)
    track.BackgroundColor3 = UITheme.ELEMENT
    track.BackgroundTransparency = 0.3
    track:SetAttribute("noDrag", true)
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Parent = track
    fill.BorderSizePixel = 0
    fill.BackgroundColor3 = UITheme.Accent
    fill.BackgroundTransparency = 0.1
    fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local fillGrad = Instance.new("UIGradient", fill)
    fillGrad.Color = UITheme:AccentGradient()
    fillGrad.Rotation = 90
    UITheme:RegisterAccentGradient(fillGrad)

    local knob = Instance.new("TextButton")
    knob.Parent = track
    knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BackgroundTransparency = 0.1
    knob.Position = UDim2.new((def - min) / (max - min), -7, 0.5, -7)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Text = ""
    knob.AutoButtonColor = false
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local knobGlow = Instance.new("UIStroke", knob)
    knobGlow.Thickness = 2
    knobGlow.Color = UITheme.Accent
    knobGlow.Transparency = 0.25
    local knobShadow = Instance.new("UIStroke", knob)
    knobShadow.Thickness = 4
    knobShadow.Color = UITheme.Accent
    knobShadow.Transparency = 0.75
    knobShadow.Thickness = 4
    UITheme:RegisterAccent(function(c)
        knobGlow.Color = c
        knobShadow.Color = c
    end)

    local dragging = false
    local current = def
    local decimals = opts.decimals or 0

    local function update(x)
        local x0 = track.AbsolutePosition.X
        local w = track.AbsoluteSize.X
        local t = math.max(0, math.min(1, (x - x0) / w))
        current = min + (max - min) * t
        if decimals == 0 then
            current = math.floor(current)
        else
            current = math.floor(current * 10) / 10
        end
        valueLabel.Text = tostring(current)
        fill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
        knob.Position = UDim2.new((current - min) / (max - min), -7, 0.5, -7)
        if opts.onChanged then pcall(opts.onChanged, current) end
    end

    pcall(function()
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
    end)
    pcall(function()
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(input.Position.X)
            end
        end)
    end)
    pcall(function()
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end)
    pcall(function()
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input.Position.X)
            end
        end)
    end)
    pcall(function()
        knob.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input.Position.X)
            end
        end)
    end)
    pcall(function()
        track.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input.Position.X)
            end
        end)
    end)
    pcall(function()
        knob.MouseButton1Down:Connect(function()
            dragging = true
        end)
        knob.MouseMoved:Connect(function(x)
            if dragging then update(x) end
        end)
    end)
    pcall(function()
        track.MouseButton1Down:Connect(function()
            dragging = true
        end)
        track.MouseMoved:Connect(function(x)
            if dragging then update(x) end
        end)
    end)
    pcall(function()
        RunService.RenderStepped:Connect(function()
            if dragging then
                local okp, mp = pcall(function() return UserInputService:GetMouseLocation() end)
                if okp then update(mp.X) end
            end
        end)
    end)
    pcall(function()
        task.spawn(function()
            while frame and frame.Parent do
                if dragging then
                    local okp, mp = pcall(function() return UserInputService:GetMouseLocation() end)
                    if okp then update(mp.X) end
                end
                task.wait()
            end
        end)
    end)
    Dbg("SLIDER_CREATED", opts.text)
    return frame
end

local function Dropdown(parent, opts)
    opts = opts or {}
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.LayoutOrder = #parent:GetChildren()
    frame.AutomaticSize = Enum.AutomaticSize.Y

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -170, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = opts.text or ""
    label.TextColor3 = UITheme.TEXT
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextButton")
    box.Parent = frame
    box.BackgroundColor3 = UITheme.ELEMENT
    box.BackgroundTransparency = 0.3
    box.BorderSizePixel = 0
    box.Size = UDim2.new(0, 160, 0, 30)
    box.Position = UDim2.new(1, -160, 0, 0)
    box.Font = Enum.Font.GothamBold
    box.TextColor3 = UITheme.TEXT
    box.TextSize = 11
    box.AutoButtonColor = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 10)
    box.TextXAlignment = Enum.TextXAlignment.Left
    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Thickness = 1
    boxStroke.Color = UITheme.BORDER
    boxStroke.Transparency = 0.4
    local boxStrokeGrad = Instance.new("UIGradient", boxStroke)
    boxStrokeGrad.Color = UITheme:AccentGradient()
    boxStrokeGrad.Rotation = 45
    boxStrokeGrad.Transparency = NumberSequence.new(0.4)
    UITheme:RegisterAccentGradient(boxStrokeGrad)
    local chevron = Instance.new("ImageLabel")
    chevron.Parent = box
    chevron.BackgroundTransparency = 1
    chevron.Image = ICON_ASSETS.more
    chevron.ImageColor3 = UITheme.SUBTEXT
    chevron.Size = UDim2.new(0, 12, 0, 12)
    chevron.Position = UDim2.new(1, -18, 0.5, -6)
    chevron.Rotation = 90

    local open = false
    local list = Instance.new("Frame")
    list.Parent = frame
    list.BackgroundColor3 = UITheme.PANEL
    list.BackgroundTransparency = 0.1
    list.BorderSizePixel = 0
    list.Size = UDim2.new(0, 160, 0, 0)
    list.Position = UDim2.new(1, -160, 0, 32)
    list.ZIndex = 30
    list.ClipsDescendants = true
    list.Visible = false
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 8)
    local listStroke = Instance.new("UIStroke", list)
    listStroke.Color = UITheme.BORDER
    listStroke.Transparency = 0.3
    local listScroll = Instance.new("ScrollingFrame")
    listScroll.Parent = list
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel = 0
    listScroll.Size = UDim2.new(1, 0, 1, 0)
    listScroll.ScrollBarThickness = 3
    listScroll.ScrollBarImageTransparency = 0.5
    listScroll.ScrollBarImageColor3 = UITheme.Accent
    listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local listLayout = Instance.new("UIListLayout", listScroll)
    listLayout.Padding = UDim.new(0, 2)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", listScroll).PaddingTop = UDim.new(0, 3)

    local currentIdx = opts.default or 1
    local function setLabel()
        local o = opts.options[currentIdx] or { text = "None" }
        box.Text = (opts.options[currentIdx] ~= nil) and o.text or "None"
    end
    setLabel()

close = function()
        open = false
        list.Visible = false
        TweenService:Create(list, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 160, 0, 0)}):Play()
    end

    box.MouseButton1Click:Connect(function()
        open = not open
        if open then
            for _, child in ipairs(listScroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for i, o in ipairs(opts.options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = listScroll
                optBtn.BackgroundColor3 = UITheme.ELEMENT
                optBtn.BackgroundTransparency = 0.4
                optBtn.BorderSizePixel = 0
                optBtn.Size = UDim2.new(1, -8, 0, 26)
                optBtn.Position = UDim2.new(0, 4, 0, 0)
                optBtn.Font = Enum.Font.Gotham
                optBtn.Text = o.text
                optBtn.TextColor3 = (i == currentIdx) and UITheme.Accent or UITheme.TEXT
                optBtn.TextSize = 11
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.AutoButtonColor = false
                Instance.new("UIPadding", optBtn).PaddingLeft = UDim.new(0, 8)
                Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 6)
                local optGrad = Instance.new("UIGradient", optBtn)
                optGrad.Color = UITheme:AccentGradient()
                optGrad.Rotation = 90
                optGrad.Transparency = NumberSequence.new(i == currentIdx and 0.4 or 1)
                UITheme:RegisterAccentGradient(optGrad)
                optBtn.MouseButton1Click:Connect(function()
                    currentIdx = i
                    setLabel()
                    close()
                    if opts.onChanged then pcall(opts.onChanged, o.value, i) end
                end)
            end
            local h = math.min(#opts.options, 8) * 28 + 6
            list.Visible = true
            TweenService:Create(list, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 160, 0, h)
            }):Play()
        else
            close()
        end
    end)
    return { SetIndex = function(i) currentIdx = i; setLabel() end }
end

-- aaaaaaaaaaaaaaaaaaaaaaaaaa TOGGLE + KEYBIND CHIP aaaaaaaaaaaaaaaaaaaaaaaaaa
local function ToggleRow(parent, opts)
    opts = opts or {}
    local row = Instance.new("Frame")
    row.Parent = parent
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, opts.desc and 44 or 34)
    row.LayoutOrder = #parent:GetChildren()

    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = row
    textLabel.BackgroundTransparency = 1
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.Size = UDim2.new(1, -120, opts.desc and 0.55 or 1, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = opts.text or ""
    textLabel.TextColor3 = UITheme.TEXT
    textLabel.TextSize = 12
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.ClipsDescendants = true

    if opts.desc then
        local descLabel = Instance.new("TextLabel")
        descLabel.Parent = row
        descLabel.BackgroundTransparency = 1
        descLabel.Position = UDim2.new(0, 0, 0.5, 0)
        descLabel.Size = UDim2.new(1, -120, 0.45, 0)
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = opts.desc
        descLabel.TextColor3 = UITheme.DIM
        descLabel.TextSize = 10
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Center
        descLabel.ClipsDescendants = true
    end

    local state = opts.state or false

    -- keybind chip
    local chip = Instance.new("TextButton")
    chip.Parent = row
    chip.BackgroundColor3 = UITheme.ELEMENT
    chip.BackgroundTransparency = 0.4
    chip.BorderSizePixel = 0
    chip.Size = UDim2.new(0, 62, 0, 22)
    chip.Position = UDim2.new(1, -112, 0.5, -11)
    chip.Font = Enum.Font.GothamBold
    chip.Text = "[ NONE ]"
    chip.TextColor3 = UITheme.DIM
    chip.TextSize = 9
    chip.AutoButtonColor = false
    chip.ZIndex = 4
    Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 7)
    if opts.keybind == false then
        chip.Visible = false
    else
        chip.MouseButton1Click:Connect(function()
            if opts.id then
                KeybindsLib:BeginListen(opts.id)
            end
        end)
    end

    -- switch
    local switchBg = Instance.new("Frame")
    switchBg.Parent = row
    switchBg.BackgroundColor3 = Color3.fromRGB(52, 58, 78)
    switchBg.BorderSizePixel = 0
    switchBg.Size = UDim2.new(0, 38, 0, 20)
    switchBg.Position = UDim2.new(1, -44, 0.5, -10)
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    local switchGrad = Instance.new("UIGradient", switchBg)
    switchGrad.Color = UITheme:AccentGradient()
    switchGrad.Rotation = 90
    switchGrad.Transparency = NumberSequence.new(1)
    UITheme:RegisterAccentGradient(switchGrad)
    local switchStroke = Instance.new("UIStroke", switchBg)
    switchStroke.Thickness = 1
    switchStroke.Color = UITheme.BORDER
    switchStroke.Transparency = 0.3

    local switchKnob = Instance.new("Frame")
    switchKnob.Parent = switchBg
    switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    switchKnob.BackgroundTransparency = 0.15
    switchKnob.BorderSizePixel = 0
    switchKnob.Size = UDim2.new(0, 15, 0, 15)
    switchKnob.Position = UDim2.new(0, 3, 0.5, -7.5)
    Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(1, 0)
    local switchKnobGlow = Instance.new("UIStroke", switchKnob)
    switchKnobGlow.Thickness = 2
    switchKnobGlow.Color = UITheme.Accent
    switchKnobGlow.Transparency = 0.6
    UITheme:RegisterAccent(function(c) switchKnobGlow.Color = c end)

    local clickArea = Instance.new("TextButton")
    clickArea.Parent = row
    clickArea.BackgroundTransparency = 1
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.Text = ""
    clickArea.ZIndex = 3

    local switchAnim = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function setVisual()
        TweenService:Create(switchBg, switchAnim, {
            BackgroundColor3 = state and UITheme.Accent or Color3.fromRGB(52, 58, 78)
        }):Play()
        switchGrad.Transparency = state and NumberSequence.new(0.1) or NumberSequence.new(1)
        TweenService:Create(switchKnob, switchAnim, {
            Position = state and UDim2.new(1, -18, 0.5, -7.5) or UDim2.new(0, 3, 0.5, -7.5)
        }):Play()
        TweenService:Create(switchStroke, switchAnim, {
            Color = state and UITheme.Accent or UITheme.BORDER,
            Transparency = state and 0 or 0.3
        }):Play()
        TweenService:Create(switchKnobGlow, switchAnim, {
            Transparency = state and 0 or 0.6
        }):Play()
    end
    setVisual()

    local handle = {
        Row = row,
        Get = function() return state end,
        Set = function(v, silent)
            v = not not v
            if v == state then return end
            state = v
            pcall(setVisual)
            if not silent and opts.onToggle then
                pcall(opts.onToggle, v)
            end
        end,
        Toggle = function()
            handle.Set(not state)
        end,
        text = opts.text or "",
    }

    clickArea.MouseButton1Click:Connect(function()
        handle.Set(not state)
    end)
    clickArea.MouseEnter:Connect(function()
        TweenService:Create(chip, TweenInfo.new(0.1), {BackgroundTransparency = 0.15}):Play()
    end)
    clickArea.MouseLeave:Connect(function()
        TweenService:Create(chip, TweenInfo.new(0.15), {BackgroundTransparency = 0.4}):Play()
    end)

    -- register keybind (unless opts.keybind == false)
    if opts.id and opts.keybind ~= false then
        KeybindsLib:Register(opts.id, {
            set = function(v) handle.Set(v) end,
            get = function() return handle.Get() end,
            chip = chip,
            name = opts.text,
        })
    end
    trackRow(row, (opts.text or "") .. " " .. (opts.desc or ""))
    return handle
end
-- =====================================================================
-- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
--  PART 2 aa KEYBIND MANAGER - SCREEN FX - TROLL ENGINE
-- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

-- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa KEYBIND MANAGER aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- Every toggle gets a clickable keybind chip. Click chip to bind: "Press Key..."
-- Backspace/Delete unbinds. Bound key toggles the feature (gameProcessed-safe).
KeybindsLib = {
    map = {},    -- id -> { set, get, chip, name, key }
    byKey = {},  -- keyCode -> { id, ... }
    activeId = nil,
    timeoutTask = nil,
}
keybindFile = "sa7loul_Keybinds.json"

local function KeyToName(key)
    if not key then return nil end
    local s = tostring(key):gsub("Enum.KeyCode.", "")
    if s == "Backspace" or s == "Delete" or s == "Unknown" then return nil end
    return s
end

function KeybindsLib:RefreshChip(id)
    local e = self.map[id]
    if not e then return end
    local keyName = KeyToName(e.key)
    if e.chip and e.chip.Parent then
        e.chip.Text = "[ " .. (keyName or "NONE") .. " ]"
        TweenService:Create(e.chip, TweenInfo.new(0.15), {
            TextColor3 = keyName and UITheme.Accent or UITheme.DIM,
            BackgroundTransparency = keyName and 0.1 or 0.4
        }):Play()
    end
    if id == "menu" and menuKeyChip and menuKeyChip.Parent then
        menuKeyChip.Text = "[ MENU: " .. (keyName or "NONE") .. " ]"
        menuKeyChip.TextColor3 = keyName and UITheme.Accent or UITheme.SUBTEXT
    end
end

function KeybindsLib:Register(id, entry)
    self.map[id] = entry
    -- re-apply a saved bind for this feature (survives config loads + tab rebuilds)
    if settings.keybinds and settings.keybinds[id] then
        local key = Enum.KeyCode[settings.keybinds[id]]
        if key then
            self:Bind(id, key)
        end
    end
    self:RefreshChip(id)
end

function KeybindsLib:Bind(id, key)
    Dbg("BIND", id .. "=" .. tostring(key))
    local e = self.map[id]
    if not e then return end
    -- remove old binding
    if e.key then
        local list = self.byKey[e.key]
        if list then
            for i, k in ipairs(list) do
                if k == id then table.remove(list, i) break end
            end
            if #list == 0 then self.byKey[e.key] = nil end
        end
    end
    e.key = key
    if key then
        if not self.byKey[key] then self.byKey[key] = {} end
        table.insert(self.byKey[key], id)
    end
    self:RefreshChip(id)
    self:Save()
end

function KeybindsLib:BeginListen(id)
    Dbg("LISTEN", id)
    self.activeId = id
    local chip = self.map[id] and self.map[id].chip
    if chip and chip.Parent then
        chip.Text = "..."
        chip.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    if self.timeoutTask then self.timeoutTask:Cancel() end
    if self._keyPanel then pcall(function() self._keyPanel:Destroy() end); self._keyPanel = nil end
    local POPULAR_KEYS = {
        "Q","W","E","R","T","Y","U","I","O","P",
        "A","S","D","F","G","H","J","K","L",
        "Z","X","C","V","B","N","M",
        "LeftShift","LeftControl","LeftAlt",
        "Space","Tab","One","Two","Three",
        "F1","F2","F3","F4","F5","F6",
    }
    local function closePicker()
        self.activeId = nil
        if self.timeoutTask then self.timeoutTask:Cancel() end
        if self._keyPanel then
            pcall(function() self._keyPanel:Destroy() end)
            self._keyPanel = nil
        end
    end
    local function doBind(keyName)
        if self.activeId ~= id then return end
        closePicker()
        local enum = Enum.KeyCode[keyName]
        if enum then
            self:Bind(id, enum)
            notif("Bound: " .. keyName, 1)
        else
            notif("Unknown key: " .. tostring(keyName), 2)
        end
    end

    local sec = Instance.new("Frame")
    sec.Name = "KeybindPicker"
    sec.Parent = ContentScroll
    sec.BackgroundColor3 = UITheme.PANEL
    sec.BackgroundTransparency = 0.2
    sec.Size = UDim2.new(1, 0, 0, 0)
    sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.LayoutOrder = -1
    self._keyPanel = sec
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0, 8)
    local secStroke = Instance.new("UIStroke", sec)
    secStroke.Thickness = 2
    secStroke.Color = UITheme.ACCENT
    local secPad = Instance.new("UIPadding", sec)
    secPad.PaddingLeft = UDim.new(0, 10)
    secPad.PaddingRight = UDim.new(0, 10)
    secPad.PaddingTop = UDim.new(0, 8)
    secPad.PaddingBottom = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Key: " .. tostring(id)
    title.TextColor3 = UITheme.ACCENT
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = sec

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, 0, 0, 30)
    input.BackgroundColor3 = UITheme.ELEMENT
    input.BackgroundTransparency = 0.3
    input.PlaceholderText = "Type key name & press Enter (Q, LeftShift, Space...)"
    input.PlaceholderColor3 = UITheme.DIM
    input.Text = ""
    input.TextColor3 = UITheme.TEXT
    input.Font = Enum.Font.GothamBold
    input.TextSize = 13
    input.ClearTextOnFocus = true
    input.BorderSizePixel = 0
    input.Parent = sec
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
    local inputStroke = Instance.new("UIStroke", input)
    inputStroke.Color = UITheme.ACCENT
    inputStroke.Thickness = 1

    local function submitInput()
        local txt = input.Text:match("^%s*(.-)%s*$")
        if not txt or txt == "" then return end
        local match = nil
        for _, k in ipairs(POPULAR_KEYS) do
            if k:lower() == txt:lower() then match = k; break end
        end
        if not match then
            local ok, _ = pcall(function() return Enum.KeyCode[txt] end)
            if ok then match = txt end
        end
        if match then
            doBind(match)
        else
            notif("Unknown: " .. txt, 2)
            input.Text = ""
            input:CaptureFocus()
        end
    end

    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then submitInput() end
    end)
    input.ReturnPressed:Connect(function() submitInput() end)

    pcall(function() input:CaptureFocus() end)

    local clrBtn = Instance.new("TextButton")
    clrBtn.Size = UDim2.new(0.45, 0, 0, 26)
    clrBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 40)
    clrBtn.BackgroundTransparency = 0.15
    clrBtn.Text = "Clear"
    clrBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clrBtn.Font = Enum.Font.GothamBold
    clrBtn.TextSize = 11
    clrBtn.AutoButtonColor = false
    clrBtn.BorderSizePixel = 0
    clrBtn.Parent = sec
    Instance.new("UICorner", clrBtn).CornerRadius = UDim.new(0, 5)
    MakeHover(clrBtn, 0.15, 0.0, false)
    clrBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            self.activeId = nil
            if self.timeoutTask then self.timeoutTask:Cancel() end
            self:Bind(id, nil)
            notif("Keybind cleared", 1)
            closePicker()
        end
    end)
    clrBtn.MouseButton1Click:Connect(function()
        self.activeId = nil
        if self.timeoutTask then self.timeoutTask:Cancel() end
        self:Bind(id, nil)
        notif("Keybind cleared", 1)
        closePicker()
    end)

    local xBtn = Instance.new("TextButton")
    xBtn.Size = UDim2.new(0.45, 0, 0, 26)
    xBtn.Position = UDim2.new(0.5, 4, 0, 0)
    xBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
    xBtn.BackgroundTransparency = 0.15
    xBtn.Text = "Cancel"
    xBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    xBtn.Font = Enum.Font.GothamBold
    xBtn.TextSize = 11
    xBtn.AutoButtonColor = false
    xBtn.BorderSizePixel = 0
    xBtn.Parent = sec
    Instance.new("UICorner", xBtn).CornerRadius = UDim.new(0, 5)
    MakeHover(xBtn, 0.15, 0.0, false)
    xBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then closePicker() end
    end)
    xBtn.MouseButton1Click:Connect(function() closePicker() end)

    self.timeoutTask = task.delay(60, function()
        if self.activeId == id then
            self.activeId = nil
            self:RefreshChip(id)
            if self._keyPanel then
                pcall(function() self._keyPanel:Destroy() end)
                self._keyPanel = nil
            end
            notif("Keybind cancelled", 2)
        end
    end)
end

function KeybindsLib:Serialize()
    local data = {}
    for id, e in pairs(self.map) do
        local name = KeyToName(e.key)
        if name then data[id] = name end
    end
    return data
end

function KeybindsLib:Save()
    settings.keybinds = self:Serialize()
    pcall(function()
        writefile(keybindFile, HttpService:JSONEncode(self:Serialize()))
    end)
end

function KeybindsLib:Restore(data)
    if type(data) ~= "table" then return end
    for id, keyName in pairs(data) do
        if self.map[id] then
            local key = Enum.KeyCode[keyName]
            if key then self:Bind(id, key) end
        end
    end
end

function KeybindsLib:ResetAll()
    self.byKey = {}
    for id, e in pairs(self.map) do
        e.key = nil
        self:RefreshChip(id)
    end
    self:Save()
end

-- load saved keybinds from disk (pcall aa safe on executors without file io)
local function KeybindsLoadFromDisk()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(keybindFile))
    end)
    if ok and type(data) == "table" then
        KeybindsLib:Restore(data)
        notif("Keybinds restored", 2)
    end
end

-- global input dispatcher (single connection, created once here)
Dbg("KEYBINDS_LISTENER_SETUP")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.Unknown then return end

    -- 1) listening for a new keybind?
    if KeybindsLib.activeId then
        local id = KeybindsLib.activeId
        KeybindsLib.activeId = nil
        if KeybindsLib.timeoutTask then KeybindsLib.timeoutTask:Cancel() end
        if key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then
            KeybindsLib:Bind(id, nil)
            notif("Keybind cleared", 1)
        else
            KeybindsLib:Bind(id, key)
            notif("Bound: " .. tostring(key):gsub("Enum.KeyCode.", ""), 1)
        end
        return
    end

    -- 2) trigger bound features (never while typing in a textbox)
    if UserInputService:GetFocusedTextBox() then return end
    local list = KeybindsLib.byKey[key]
    if list then
        for _, id in ipairs(list) do
            local e = KeybindsLib.map[id]
            if e and e.set then
                pcall(e.set, not e.get())
            end
        end
    end
end)

-- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa SCREEN FX ENGINE aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
ScreenFx = {
    blurOn = false,
    fovOn = false,
    shakeOn = false,
    rainbowOn = false,
    blurObj = nil,
    rainbowScreen = nil,
    rainbowGrad = nil,
    fxConn = nil,
    baseFov = 70,
}

local function SfxCamera()
    return workspace.CurrentCamera
end

local function SfxEnsureBlur()
    if ScreenFx.blurObj and ScreenFx.blurObj.Parent then return end
    local b = Instance.new("BlurEffect")
    b.Name = "TrollBlur"
    b.Size = 0
    b.Parent = Lighting
    ScreenFx.blurObj = b
end

local function SfxEnsureRainbow()
    if ScreenFx.rainbowScreen and ScreenFx.rainbowScreen.Parent then return end
    local scr = Instance.new("ScreenGui")
    scr.Name = "TrollRainbow"
    scr.IgnoreGuiInset = true
    scr.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    scr.Parent = CoreGui
    local canvas = Instance.new("Frame")
    canvas.Parent = scr
    canvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    canvas.BackgroundTransparency = 0.55
    canvas.BorderSizePixel = 0
    canvas.Size = UDim2.fromScale(1, 1)
    local grad = Instance.new("UIGradient", canvas)
    grad.Rotation = 0
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 60)),
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 170, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(80, 255, 80)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 120, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(180, 60, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 120))
    })
    ScreenFx.rainbowScreen = scr
    ScreenFx.rainbowGrad = grad
end

local function SfxTick(dt)
    dt = dt or 0.016
    -- blur pulse
    if ScreenFx.blurOn then
        SfxEnsureBlur()
        if ScreenFx.blurObj then
            ScreenFx.blurObj.Size = 10 + (math.sin(tick() * 3.1) * 0.5 + 0.5) * 60
        end
    end
    -- fov pulse
    if ScreenFx.fovOn then
        local cam = SfxCamera()
        if cam then
            cam.FieldOfView = ScreenFx.baseFov + math.sin(tick() * 4.2) * 24
        end
    end
    -- rainbow overlay
    if ScreenFx.rainbowOn then
        SfxEnsureRainbow()
        if ScreenFx.rainbowGrad then
            ScreenFx.rainbowGrad.Rotation = (ScreenFx.rainbowGrad.Rotation + dt * 90) % 360
        end
    end
    -- screen shake
    if ScreenFx.shakeOn then
        local cam = SfxCamera()
        if cam then
            local s = 0.35
            cam.CFrame = cam.CFrame * CFrame.new(
                (math.random() - 0.5) * s,
                (math.random() - 0.5) * s,
                (math.random() - 0.5) * s * 0.5
            ) * CFrame.Angles(
                (math.random() - 0.5) * 0.015,
                (math.random() - 0.5) * 0.015,
                0
            )
        end
    end
end

local function SfxRebuild()
    if ScreenFx.fxConn then
        ScreenFx.fxConn:Disconnect()
        ScreenFx.fxConn = nil
    end
    if ScreenFx.blurOn or ScreenFx.fovOn or ScreenFx.shakeOn or ScreenFx.rainbowOn then
        ScreenFx.fxConn = RunService.RenderStepped:Connect(SfxTick)
    else
        -- full cleanup
        if ScreenFx.blurObj then
            pcall(function() ScreenFx.blurObj:Destroy() end)
            ScreenFx.blurObj = nil
        end
        if ScreenFx.rainbowScreen then
            pcall(function() ScreenFx.rainbowScreen:Destroy() end)
            ScreenFx.rainbowScreen = nil
        end
        local cam = SfxCamera()
        if cam and ScreenFx.fovOn == false then
            pcall(function() cam.FieldOfView = ScreenFx.baseFov end)
        end
    end
end

local function SfxSet(flag, on)
    ScreenFx[flag] = on
    if flag == "fovOn" and not on then
        local cam = SfxCamera()
        if cam then pcall(function() cam.FieldOfView = ScreenFx.baseFov end) end
    end
    SfxRebuild()
end

--  deg JUMPSCARE BURST aa flash + FOV punch + shake + sound
jumpScareActive = false
local function JumpScareBurst()
    if jumpScareActive then return end
    local cam = SfxCamera()
    if not cam then return end
    jumpScareActive = true
    local baseFov = cam.FieldOfView or 70

    local flashScreen = Instance.new("ScreenGui")
    flashScreen.Name = "TrollJumpScare"
    flashScreen.IgnoreGuiInset = true
    flashScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    flashScreen.Parent = CoreGui
    local white = Instance.new("Frame")
    white.Parent = flashScreen
    white.Size = UDim2.fromScale(1, 1)
    white.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    white.BackgroundTransparency = 1
    white.BorderSizePixel = 0
    local red = white:Clone()
    red.Parent = flashScreen
    red.BackgroundColor3 = Color3.fromRGB(255, 0, 45)

    local sfx = nil
    if TrollCfg.earrape and TrollState.earrapeSound and TrollState.earrapeSound.Parent then
        sfx = TrollState.earrapeSound
    else
        sfx = Instance.new("Sound")
        sfx.SoundId = "rbxassetid://1847056112"
        sfx.Volume = 9
        sfx.Parent = flashScreen
    end
    pcall(function() if sfx then sfx:Play() end end)

    local t0 = os.clock()
    local DUR = 2.4
    local conn = RunService.RenderStepped:Connect(function()
        local elapsed = os.clock() - t0
        if elapsed >= DUR then
            conn:Disconnect()
            pcall(function() cam.FieldOfView = baseFov end)
            pcall(function() flashScreen:Destroy() end)
            jumpScareActive = false
            return
        end
        local t = elapsed / DUR
        pcall(function()
            cam.FieldOfView = baseFov + math.sin(t * 6.5) * 34 * (1 - t) + 6
            white.BackgroundTransparency = 1 - (math.max(0, math.sin(t * math.pi * 2.3)) * (1 - t))
            red.BackgroundTransparency = 1 - (math.max(0, math.sin(t * math.pi * 5 + 1)) * 0.5 * (1 - t))
            cam.CFrame = cam.CFrame * CFrame.new(
                (math.random() - 0.5) * 1.6,
                (math.random() - 0.5) * 1.3,
                0
            ) * CFrame.Angles(
                (math.random() - 0.5) * 0.03,
                (math.random() - 0.5) * 0.03,
                0
            )
        end)
    end)
end

-- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa TROLL ENGINE aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
TrollTargetSel = nil
-- Emoji-free mapping: keep players dropdown synced
trollTargetDropdown = nil

TrollCfg = {
    fling = false,        -- physics fling
    annoy = false,        -- teleport spam around target
    invis = false,        -- ghost mode
    sneakySeat = false,
    clickTP = false,
    earrape = false,
    earrapeChoice = 1,
    earrapeVolume = 10,
}
TrollState = {
    flingAng = nil, flingVel = nil, flingConn = nil,
    annoyConn = nil, annoyTimer = 0,
    invisConn = nil, invisSaved = {},
    sneakySeatObj = nil, sneakyConn = nil, sneakySaved = {},
    clickTPLast = 0,
    earrapeSound = nil, earrapeConn = nil,
}

TROLL_SOUNDS = {
    { name = "Air Horn",      id = "rbxassetid://5834027169" },
    { name = "Emergency Alarm", id = "rbxassetid://1847056112" },
    { name = "Yippee",        id = "rbxassetid://5462315380" },
    { name = "Vine Boom",     id = "rbxassetid://6694328105" },
    { name = "Bruh",          id = "rbxassetid://3274732880" },
}

-- helpers
local function TrollGetTarget()
    if TrollTargetSel and TrollTargetSel.Parent then
        return TrollTargetSel
    end
    return nil
end

local function TrollTargetChar()
    local t = TrollGetTarget()
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        return t.Character.HumanoidRootPart
    end
    return nil
end

local function TrollMyRoot()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        return lp.Character.HumanoidRootPart
    end
    return nil
end

-- 1) FLING TARGET (physics-based: angular velocity + random linear yeet)
local function TrollFlingStart()
    TrollCfg.fling = true
    if TrollState.flingConn then TrollState.flingConn:Disconnect() end
    TrollState.flingTimer = 0
    TrollState.flingConn = RunService.Heartbeat:Connect(function(dt)
        local tRoot = TrollTargetChar()
        local myRoot = TrollMyRoot()
        if not (tRoot and myRoot) then
            TrollCfg.fling = false
            TrollFlingStop()
            return
        end
        -- my character rides the target (forces collision fling)
        myRoot.CFrame = tRoot.CFrame
        -- angular velocity
        if not TrollState.flingAng or TrollState.flingAng.Parent ~= tRoot then
            if TrollState.flingAng then pcall(function() TrollState.flingAng:Destroy() end) end
            local bav = Instance.new("BodyAngularVelocity")
            bav.Name = "TrollFlingAng"
            bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bav.AngularVelocity = Vector3.new(0, 70, 30)
            bav.Parent = tRoot
            TrollState.flingAng = bav
        end
        if not TrollState.flingVel or TrollState.flingVel.Parent ~= tRoot then
            if TrollState.flingVel then pcall(function() TrollState.flingVel:Destroy() end) end
            local bv = Instance.new("BodyVelocity")
            bv.Name = "TrollFlingVel"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.P = 40000
            bv.Velocity = Vector3.zero
            bv.Parent = tRoot
            TrollState.flingVel = bv
        end
        TrollState.flingTimer = TrollState.flingTimer + dt
        if TrollState.flingTimer >= 0.35 then
            TrollState.flingTimer = 0
            if TrollState.flingAng then
                TrollState.flingAng.AngularVelocity = Vector3.new(
                    (math.random() - 0.5) * 90,
                    90 + math.random() * 60,
                    (math.random() - 0.5) * 90
                )
            end
            if TrollState.flingVel then
                local dir = (Vector3.new(math.random() - 0.5, 1.2, math.random() - 0.5)).Unit
                TrollState.flingVel.Velocity = dir * (60 + math.random() * 80)
            end
        end
    end)
    notif("Troll Fling: ON", 2)
end

TrollFlingStop = function()
    TrollCfg.fling = false
    if TrollHandles and TrollHandles.fling then pcall(function() TrollHandles.fling:Set(false, true) end) end
    if TrollState.flingConn then TrollState.flingConn:Disconnect(); TrollState.flingConn = nil end
    if TrollState.flingAng then pcall(function() TrollState.flingAng:Destroy() end); TrollState.flingAng = nil end
    if TrollState.flingVel then pcall(function() TrollState.flingVel:Destroy() end); TrollState.flingVel = nil end
    local tRoot = TrollTargetChar()
    if tRoot then
        local hum = tRoot.Parent:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.PlatformStand = false end) end
    end
    notif("Troll Fling: OFF", 2)
end

-- 2) ANNOY LOOP - teleport spam around the target
local function TrollAnnoyStart()
    TrollCfg.annoy = true
    if TrollState.annoyConn then TrollState.annoyConn:Disconnect() end
    TrollState.annoyTimer = 0
    TrollState.annoyConn = RunService.Heartbeat:Connect(function(dt)
        local tRoot = TrollTargetChar()
        local myRoot = TrollMyRoot()
        if not (tRoot and myRoot) then
            TrollCfg.annoy = false
            TrollAnnoyStop()
            return
        end
        TrollState.annoyTimer = TrollState.annoyTimer + dt
        if TrollState.annoyTimer >= 0.28 then
            TrollState.annoyTimer = 0
            local ang = math.random() * math.pi * 2
            local radius = 2 + math.random() * 3.5
            local offset = Vector3.new(
                math.cos(ang) * radius,
                1 + math.random() * 2.5,
                math.sin(ang) * radius
            )
            myRoot.CFrame = CFrame.new(tRoot.Position + offset)
        end
    end)
    notif("Annoy Loop: ON (hopping around " .. (TrollGetTarget() and TrollGetTarget().Name or "target") .. ")", 2)
end

TrollAnnoyStop = function()
    TrollCfg.annoy = false
    if TrollHandles and TrollHandles.annoy then pcall(function() TrollHandles.annoy:Set(false, true) end) end
    if TrollState.annoyConn then TrollState.annoyConn:Disconnect(); TrollState.annoyConn = nil end
    notif("Annoy Loop: OFF", 2)
end

-- 3) GHOST MODE (client-side invisibility)
local function TrollInvisStart()
    TrollCfg.invis = true
    if TrollState.invisConn then TrollState.invisConn:Disconnect() end
    TrollState.invisSaved = {}
hide = function()
        if not TrollCfg.invis or not lp.Character then return end
        for _, part in ipairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if TrollState.invisSaved[part] == nil then
                    TrollState.invisSaved[part] = part.Transparency
                end
                if part.Transparency < 1 then part.Transparency = 1 end
            end
        end
    end
    TrollState.invisConn = RunService.RenderStepped:Connect(hide)
    notif("Ghost Mode: ON", 2)
end

local function TrollInvisStop()
    TrollCfg.invis = false
    if TrollState.invisConn then TrollState.invisConn:Disconnect(); TrollState.invisConn = nil end
    if lp.Character then
        for part, tr in pairs(TrollState.invisSaved) do
            if part and part.Parent then
                pcall(function() part.Transparency = tr end)
            end
        end
    end
    TrollState.invisSaved = {}
    notif("Ghost Mode: OFF", 2)
end

-- 4) SNEAKY SEAT - invisible seat + hide while seated
local function TrollSneakySeatStart()
    TrollCfg.sneakySeat = true
    local root = TrollMyRoot()
    if not root then
        TrollCfg.sneakySeat = false
        notif("Need a character first", 2)
        return
    end
    -- create invisible seat in front
    local seat = Instance.new("Seat")
    seat.Name = "SneakySeat"
    seat.Size = Vector3.new(4, 0.6, 4)
    seat.Transparency = 1
    seat.CanCollide = false
    seat.Anchored = true
    seat.Position = root.Position - root.CFrame.LookVector * 3
    seat.Parent = workspace
    TrollState.sneakySeatObj = seat
    -- hide while seated / restore when standing
    local hum = lp.Character:FindFirstChildOfClass("Humanoid")
    TrollState.sneakySaved = {}
apply = function(seated)
        if not TrollCfg.sneakySeat or not lp.Character then return end
        for _, part in ipairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if TrollState.sneakySaved[part] == nil then
                    TrollState.sneakySaved[part] = part.Transparency
                end
                part.Transparency = seated and 1 or TrollState.sneakySaved[part]
            end
        end
    end
    if hum then
        TrollState.sneakyConn = hum.Seated:Connect(apply)
        pcall(function() hum:Sit(seat) end)
        task.wait(0.3)
        if not hum.Seated then
            pcall(function()
                root.CFrame = seat.CFrame * CFrame.new(0, 1.4, 0)
                hum.Sit = true
            end)
        end
    end
    notif("Sneaky Seat spawned - you're invisible while seated", 3)
end

local function TrollSneakySeatStop()
    TrollCfg.sneakySeat = false
    if TrollState.sneakyConn then TrollState.sneakyConn:Disconnect(); TrollState.sneakyConn = nil end
    if TrollState.sneakySeatObj then pcall(function() TrollState.sneakySeatObj:Destroy() end); TrollState.sneakySeatObj = nil end
    if lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.Sit = false end) end
        for part, tr in pairs(TrollState.sneakySaved) do
            if part and part.Parent then
                pcall(function() part.Transparency = tr end)
            end
        end
    end
    TrollState.sneakySaved = {}
    notif("Sneaky Seat: OFF", 2)
end

-- 5) CLICK-TO-TELEPORT TOOL
local function TrollClickTPFire()
    if os.clock() - TrollState.clickTPLast < 0.45 then return end
    local root = TrollMyRoot()
    local cam = workspace.CurrentCamera
    if not (root and cam) then return end
    local m = UserInputService:GetMouseLocation()
    -- skip if over any GUI object
    local guis = {}
    local ok = pcall(function()
        guis = GuiService:GetGuiObjectsAtPosition(m.X, m.Y)
    end)
    if ok and #guis > 0 then return end
    local ray = cam:ViewportPointToRay(m.X, m.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = lp and lp.Character
    if char then params.FilterDescendantsInstances = { char } end
    local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    if result and result.Instance then
        local hit = result.Instance
        local target = nil
        for _, p in ipairs(PlayersSvc:GetPlayers()) do
            if p ~= lp and p.Character and hit:IsDescendantOf(p.Character) then
                target = p
                break
            end
        end
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            root.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3.5)
            TrollState.clickTPLast = os.clock()
            notif("Teleported to: " .. target.Name, 1)
        end
    end
end

local function TrollClickTPStart()
    TrollCfg.clickTP = true
    notif("Click TP: ON - click any player to teleport", 2)
end
local function TrollClickTPStop()
    TrollCfg.clickTP = false
    notif("Click TP: OFF", 2)
end

-- 6) EARRAPE AUDIO SPAM (local sounds)
local function TrollEarrapeStart()
    TrollCfg.earrape = true
    local choice = TROLL_SOUNDS[TrollCfg.earrapeChoice] or TROLL_SOUNDS[1]
    if not TrollState.earrapeSound or not TrollState.earrapeSound.Parent then
        local s = Instance.new("Sound")
        s.Name = "TrollEarrape"
        s.SoundId = choice.id
        s.Volume = TrollCfg.earrapeVolume
        s.Looped = true
        s.Parent = CoreGui
        TrollState.earrapeSound = s
    end
    local s = TrollState.earrapeSound
    s.Volume = TrollCfg.earrapeVolume
    pcall(function() s:Play() end)
    if TrollState.earrapeConn then TrollState.earrapeConn:Disconnect() end
    TrollState.earrapeConn = RunService.Heartbeat:Connect(function(dt)
        if not TrollCfg.earrape then return end
        if not TrollState.earrapeSound or not TrollState.earrapeSound.Parent then
            TrollCfg.earrape = false
            TrollEarrapeStop()
            return
        end
        -- random pitch wobble + re-trigger for maximum chaos
        if not TrollState.earrapeSound.IsPlaying then
            pcall(function() TrollState.earrapeSound:Play() end)
        end
        if math.random() < dt then
            pcall(function()
                TrollState.earrapeSound.PlaybackSpeed = 0.8 + math.random() * 0.7
                TrollState.earrapeSound.TimePosition = math.random() * 1.5
            end)
        end
    end)
    notif("Earrape: ON (" .. choice.name .. ")", 2)
end

TrollEarrapeStop = function()
    TrollCfg.earrape = false
    if TrollState.earrapeConn then TrollState.earrapeConn:Disconnect(); TrollState.earrapeConn = nil end
    if TrollState.earrapeSound then
        pcall(function() TrollState.earrapeSound:Stop() end)
        pcall(function() TrollState.earrapeSound:Destroy() end)
        TrollState.earrapeSound = nil
    end
    notif("Earrape: OFF", 2)
end

-- FAKE ADMIN / SYSTEM MESSAGES (client chat only)
local function FakeSystemMessage(text, color)
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = text,
            Color = color or Color3.fromRGB(255, 120, 120),
            Font = Enum.Font.GothamBold,
            TextSize = 18
        })
    end)
end

local function FakeNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 4
        })
    end)
end

-- FAKE ADMIN SCRIPT SPOOF - fires "admin" remotes with a fake server title
local function FakeAdminCommand(cmd, targetName)
    local remotes = ScanAdminRemotes()
    local fired = 0
    for _, r in ipairs(remotes) do
        local args = cmd and { cmd, targetName } or { targetName }
        local ok = pcall(function()
            if r:IsA("RemoteFunction") then
                r:InvokeServer(unpack2(args))
            else
                r:FireServer(unpack2(args))
            end
        end)
        if ok then fired = fired + 1 end
    end
    return fired
end
-- =====================================================================
-- a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-
--  PART 3 a TAB CONTENTS - EVENTS - INIT
-- a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-a-

TrollHandles = {}
trollTargetOptions = {}
trollTargetDD = nil

fpsMeter = 0
lastFrameTime = os.clock()
RunService.RenderStepped:Connect(function()
    local now = os.clock()
    fpsMeter = 1 / math.max(0.001, now - lastFrameTime)
    lastFrameTime = now
end)

local function RefreshTrollTargetOptions()
    for i = #trollTargetOptions, 1, -1 do table.remove(trollTargetOptions, i) end
    for _, p in ipairs(PlayersSvc:GetPlayers()) do
        if p ~= lp then
            table.insert(trollTargetOptions, { text = p.Name, value = p })
        end
    end
    if not TrollTargetSel and #trollTargetOptions > 0 then
        TrollTargetSel = trollTargetOptions[1].value
    end
    if trollTargetDD then
        if TrollTargetSel then
            for i, o in ipairs(trollTargetOptions) do
                if o.value == TrollTargetSel then
                    trollTargetDD:SetIndex(i)
                    return
                end
            end
        end
        if #trollTargetOptions > 0 then
            trollTargetDD:SetIndex(1)
        end
    end
end

-- aaaaaaaaaaaaaaaaaaaaaaaaaa TAB SWITCHING aaaaaaaaaaaaaaaaaaaaaaaaaa
SwitchTab = function(key)
    CurrentTab = key
    RefreshTabVisuals()
    RefreshSearch()
    ContentScroll.CanvasPosition = Vector2.zero
    if UpdateRightContent then
        UpdateRightContent()
    end
end

-- aaaaaaaaaaaaaaaaaaaaaaaaaa PLAYERS TAB aaaaaaaaaaaaaaaaaaaaaaaaaa
local function CreatePlayerEntry(parent, player)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundColor3 = UITheme.ELEMENT
    frame.BackgroundTransparency = 0.45
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.LayoutOrder = #parent:GetChildren()
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local selected = (selectedPlayer == player)
    local function applyStyle()
        if selected then
            frame.BackgroundColor3 = UITheme.Accent
            frame.BackgroundTransparency = 0.75
        else
            frame.BackgroundColor3 = UITheme.ELEMENT
            frame.BackgroundTransparency = 0.45
        end
    end
    applyStyle()
    UITheme:RegisterAccent(function()
        if selected then
            frame.BackgroundColor3 = UITheme.Accent
        end
    end)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = frame
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0, 130, 1, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = (player == lp) and UITheme.Accent or UITheme.TEXT
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = frame
    statusLabel.BackgroundTransparency = 1
    statusLabel.Size = UDim2.new(0, 110, 1, 0)
    statusLabel.Position = UDim2.new(0, 145, 0, 0)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextColor3 = UITheme.SUBTEXT
    statusLabel.TextSize = 10
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    if player == lp then
        statusLabel.Text = "You"
        statusLabel.TextColor3 = UITheme.Accent
    elseif IsPlayerDowned(player) then
        statusLabel.Text = "Down"
        statusLabel.TextColor3 = UITheme.RED
    elseif IsPlayerInLobby(player) then
        statusLabel.Text = "Lobby"
        statusLabel.TextColor3 = UITheme.DIM
    else
        statusLabel.Text = "In game"
    end

    -- action buttons
    if player ~= lp then
        local actions = Instance.new("UIListLayout")
        actions.Parent = frame
        actions.FillDirection = Enum.FillDirection.Horizontal
        actions.HorizontalAlignment = Enum.HorizontalAlignment.Right
        actions.VerticalAlignment = Enum.VerticalAlignment.Center
        actions.HorizontalFlex = Enum.UIFlexAlignment.Fill
        actions.Padding = UDim.new(0, 4)

        local function actionBtn(icon, color, callback)
            local btn = Instance.new("TextButton")
            btn.Parent = frame
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(0, 28, 0, 24)
            btn.Text = ""
            btn.BackgroundColor3 = color
            btn.BackgroundTransparency = 0.25
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            local ic = Instance.new("ImageLabel")
            ic.Parent = btn
            ic.BackgroundTransparency = 1
            ic.Image = ICON_ASSETS[icon] or ICON_ASSETS.more
            ic.ImageColor3 = Color3.fromRGB(255, 255, 255)
            ic.Size = UDim2.new(0, 14, 0, 14)
            ic.Position = UDim2.new(0.5, -7, 0.5, -7)
            ic.ZIndex = 3
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.25}):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                pcall(callback)
            end)
            return btn
        end
        actionBtn("target", UITheme.CYAN, function()
            if bringActive then
                StopBring()
            else
                StartBring(player.Name)
            end
        end)
        actionBtn("map", UITheme.PURPLE, function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                notif("Teleported to: " .. player.Name, 2)
            else
                notif("Player not found", 2)
            end
        end)
        actionBtn("plane", UITheme.GREEN, function()
            GiveFlyNoClip()
        end)
        actionBtn("eye", UITheme.AMBER, function()
            if viewing == player then
                StopView()
            else
                StartView(player.Name)
            end
        end)
        actionBtn("snow", Color3.fromRGB(80, 170, 255), function()
            FreezePlayer(player.Name)
        end)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            selected = true
            applyStyle()
            SetSelectedPlayer(player)
            task.delay(0.6, function()
                if frame and frame.Parent and selectedPlayer ~= player then
                    selected = false
                    applyStyle()
                end
            end)
        end
    end)
    return frame
end

UpdatePlayerList = function()
    if CurrentTab ~= "Players" then return end
    if not playerListContainer then return end
    for _, child in ipairs(playerListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local players = PlayersSvc:GetPlayers()
    table.sort(players, function(a, b)
        if a == lp then return true end
        if b == lp then return false end
        return a.Name < b.Name
    end)
    if #players == 0 then
        Label(playerListContainer, "No players in server", UITheme.SUBTEXT, 11)
        return
    end
    for _, player in ipairs(players) do
        CreatePlayerEntry(playerListContainer, player)
    end
end

local function RefreshPlayerSideTab()
    if trollTargetDD then RefreshTrollTargetOptions() end
end

-- aaaaaaaaaaaaaaaaaaaaaaaaaa CUFF ITEM SPAWNER / GIVER aaaaaaaaaaaaaaaaaaaaaaaaaa
local function IsCuffObject(obj)
    return (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart"))
        and string.lower(obj.Name):find("cuff", 1, true) ~= nil
end

local function GetAllCuffItemNames()
    local seen = {}
    local results = {}
scan = function(root)
        if not root then return end
        for _, obj in ipairs(root:GetDescendants()) do
            if IsCuffObject(obj) and not seen[obj.Name] then
                seen[obj.Name] = true
                table.insert(results, obj.Name)
            end
        end
    end
    scan(workspace)
    scan(game:GetService("ReplicatedStorage"))
    local players = PlayersSvc:GetPlayers()
    for _, player in ipairs(players) do
        scan(player:FindFirstChild("Backpack"))
        local chr = player.Character
        if chr and chr.Parent then scan(chr) end
    end
    for _, name in ipairs({"Cuffs", "Cuff", "Menottes", "Menotte", "Handcuffs", "Handcuff"}) do
        if not seen[name] then
            seen[name] = true
            table.insert(results, name)
        end
    end
    return results
end

local function FindCuffObject(itemName)
    local function findIn(root)
        if not root then return nil end
        return root:FindFirstChild(itemName, true)
    end
    local obj = findIn(PlayersSvc) or findIn(workspace) or findIn(game:GetService("ReplicatedStorage"))
    if obj and IsCuffObject(obj) then return obj end
    return nil
end

local function PositionItemNearPlayer(item, target)
    local base = item
    if item:IsA("Model") then
        base = item:FindFirstChild("PrimaryPart")
            or item:FindFirstChildWhichIsA("BasePart")
    end
    if not base then return end
    local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local anchor = targetRoot and targetRoot.CFrame
        or (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.CFrame)
        or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame)
        or CFrame.new(0, 50, 0)
    local ok = pcall(function()
        if item:IsA("BasePart") then
            base.CFrame = anchor * CFrame.new(0, 1, 4)
        else
            item:PivotTo(anchor * CFrame.new(0, 1, 4))
        end
    end)
    return ok
end

local function GiveCuffItemToPlayer(itemName, targetPlayer)
    local target = targetPlayer or lp
    if not target then
        notif("No target player", 2)
        return false
    end
    local source = FindCuffObject(itemName)
    if not source then
        notif("Cuff item not in game: " .. itemName, 2)
        return false
    end
    local ok = pcall(function()
        local item = source:Clone()
        if item:IsA("Tool") then
            local backpack = target:FindFirstChild("Backpack")
            if backpack then
                item.Parent = backpack
                local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:EquipTool(item) end) end
            else
                item.Parent = workspace
                PositionItemNearPlayer(item, target)
            end
        else
            item.Parent = workspace
            PositionItemNearPlayer(item, target)
        end
    end)
    if ok then
        notif("Gave " .. itemName .. " to " .. target.Name, 2)
    else
        notif("Could not give: " .. itemName, 2)
    end
    return ok
end

local function SpawnCuffItemForMe(itemName)
    return GiveCuffItemToPlayer(itemName, lp)
end

local function TakeCuffsFromTarget(target)
    local targetPlayer = target or lp
    local taken = 0
    local function grabFrom(root)
        if not root then return end
        for _, obj in ipairs(root:GetChildren()) do
            if IsCuffObject(obj) then
                if GiveCuffItemToPlayer(obj.Name, lp) then taken = taken + 1 end
            end
        end
        for _, obj in ipairs(root:GetChildren()) do
            if obj:IsA("Tool") then grabFrom(obj) end
        end
    end
    if targetPlayer.Character then grabFrom(targetPlayer.Character) end
    grabFrom(targetPlayer:FindFirstChild("Backpack"))
    if taken > 0 then
        notif("Took " .. taken .. " cuff item(s) from " .. targetPlayer.Name, 2)
    else
        notif("No cuffs found on " .. targetPlayer.Name, 2)
    end
    return taken
end

local function RemoveMyCuffs()
    local removed = 0
    local function clearFrom(root)
        if not root then return end
        for _, obj in ipairs(root:GetChildren()) do
            if IsCuffObject(obj) then
                pcall(function() obj:Destroy() end)
                removed = removed + 1
            end
        end
    end
    clearFrom(lp:FindFirstChild("Backpack"))
    if lp.Character then clearFrom(lp.Character) end
    notif(removed > 0 and ("Removed " .. removed .. " cuff item(s)") or "No cuffs to remove", 2)
end
-- aaaaaaaaaaaaaaaaaaaaaaaaaa END CUFF CODE aaaaaaaaaaaaaaaaaaaaaaaaaa

-- aaaaaaaaaaaaaaaaaaaaaaaaaa SPAWNER ENGINE (generic items) aaaaaaaaaaaaaaaaaaaaaaaaaa
local function Normalize(s)
    return string.lower((s or ""):gsub("[\195\160\195\161\195\162\195\164\195\163\195\165]", "a"):gsub("[\195\168\195\169\195\170\195\171]", "e"):gsub("[\195\172\195\173\195\174\195\175]", "i"):gsub("[\195\178\195\179\195\180\195\182\195\181]", "o"):gsub("[\195\185\195\186\195\187\195\188]", "u"):gsub("\195\167", "c"):gsub("\195\177", "n"):gsub("%s+", " "))
end

local function ItemIcon(name)
    local n = Normalize(name)
    local map = {
        { {"knife", "couteau", "cutter", "machete", "cleaver", "dart", "kunai", "stab"}, "K" },
        { {"gun", "pistol", "pistolet", "rifle", "fusil", "shotgun", "bazooka"}, "G" },
        { {"axe", "hache", "hatchet", "hachoir"}, "A" },
        { {"hammer", "marteau", "mallet"}, "H" },
        { {"sword", "epee", "katana", "saber"}, "S" },
        { {"bat", "batte", "club", "cricket"}, "B" },
        { {"ring", "alliance"}, "R" },
        { {"dryer", "seche", "cheveux"}, "D" },
        { {"cuff", "menotte"}, "C" },
        { {"locker", "casier", "armoire"}, "L" },
        { {"glove", "gant"}, "G" },
        { {"box", "boite"}, "B" },
        { {"key", "cle"}, "K" },
        { {"candle", "bougie"}, "C" },
        { {"soap", "savon"}, "S" },
        { {"coin", "cash", "money", "loot"}, "$" },
        { {"med", "firstaid", "bandage", "kit", "soin"}, "+" },
        { {"armor", "armure", "vest", "gilet"}, "A" },
    }
    for _, e in ipairs(map) do
        for _, t in ipairs(e[1]) do
            if n:find(t, 1, true) then return e[2] end
        end
    end
    return ""
end

local function ScanItemsByKeyword(keyword)
    local seen = {}
    local results = {}
    local tokens = {}
    for token in string.gmatch(keyword or "", "[^|]+") do
        local t = Normalize(token):gsub(" ", "")
        if t ~= "" then table.insert(tokens, t) end
    end
    if #tokens == 0 then return results end
scan = function(root)
        if not root then return end
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart"))
                    and not seen[obj.Name] then
                    local norm = Normalize(obj.Name):gsub(" ", "")
                    for _, t in ipairs(tokens) do
                        if norm:find(t, 1, true) then
                            seen[obj.Name] = true
                            table.insert(results, obj.Name)
                            break
                        end
                    end
                end
            end
        end)
    end
    scan(workspace)
    scan(game:GetService("ReplicatedStorage"))
    scan(game:GetService("ReplicatedFirst"))
    scan(game:GetService("ServerStorage"))
    local players = PlayersSvc:GetPlayers()
    for _, player in ipairs(players) do
        scan(player:FindFirstChild("Backpack"))
        local chr = player.Character
        if chr and chr.Parent then scan(chr) end
    end
    return results
end

local function FindSpawnObject(itemName)
    local function findIn(root)
        if not root then return nil end
        local obj = root:FindFirstChild(itemName, true)
        if obj and (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart")) then
            return obj
        end
        return nil
    end
    return findIn(PlayersSvc) or findIn(workspace) or findIn(game:GetService("ReplicatedStorage"))
        or findIn(game:GetService("ReplicatedFirst")) or findIn(game:GetService("ServerStorage"))
end

local function GiveSpawnItemToPlayer(itemName, targetPlayer)
    local target = targetPlayer or lp
    if not target then
        notif("No target player", 2)
        return false
    end
    local source = FindSpawnObject(itemName)
    if not source then
        notif("Item not in game: " .. itemName, 2)
        return false
    end
    local ok = pcall(function()
        local item = source:Clone()
        if item:IsA("Tool") then
            local backpack = target:FindFirstChild("Backpack")
            if backpack then
                item.Parent = backpack
                local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:EquipTool(item) end) end
            else
                item.Parent = workspace
                PositionItemNearPlayer(item, target)
            end
        else
            for _, part in ipairs(item:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = false end
            end
            local base = item:FindFirstChild("PrimaryPart") or item:FindFirstChildWhichIsA("BasePart")
            if base then base.Anchored = false end
            item.Parent = workspace
            PositionItemNearPlayer(item, target)
        end
    end)
    if ok then
        notif("Spawned " .. itemName .. " for " .. target.Name, 2)
    else
        notif("Could not spawn: " .. itemName, 2)
    end
    return ok
end

local function SpawnSpawnItemForMe(itemName)
    return GiveSpawnItemToPlayer(itemName, lp)
end

local function TakeSpawnItemsFromTarget(target, keyword)
    local targetPlayer = target or lp
    local taken = 0
    local lowerKey = string.lower(keyword or "cuff")
    local function grabFrom(root)
        if not root then return end
        for _, obj in ipairs(root:GetChildren()) do
            if (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart"))
                and string.lower(obj.Name):find(lowerKey, 1, true) then
                if GiveSpawnItemToPlayer(obj.Name, lp) then taken = taken + 1 end
            end
        end
        for _, obj in ipairs(root:GetChildren()) do
            if obj:IsA("Tool") then grabFrom(obj) end
        end
    end
    if targetPlayer.Character then grabFrom(targetPlayer.Character) end
    grabFrom(targetPlayer:FindFirstChild("Backpack"))
    if taken > 0 then
        notif("Took " .. taken .. " item(s) from " .. targetPlayer.Name, 2)
    else
        notif("No matching items on " .. targetPlayer.Name, 2)
    end
    return taken
end

-- aaaaaaaaaaaaaaaaaaaaaaaaaa ITEM CATALOG + SNAPSHOT aaaaaaaaaaaaaaaaaaaaaaaaaa
-- Live scan finds items currently in the server; the catalog fills in the
-- known STK items so the spawner always shows a full list.
KNOWN_CATALOG = {
    "Sche-Cheveux", "Seche-Cheveux", "Hair Dryer", "Hairdryer",    "Coupe-Cheveux", "Hair Cutter", "Rasoir", "Razor",
    "Cuffs", "Cuff", "Menottes", "Menotte", "Handcuffs", "Handcuff",
    "Couteau", "Couteaux", "Knife", "Butcher Knife", "Batte", "Bat", "Hache", "Axe",
    "Pistolet", "Gun", "Pistol", "Marteau", "Hammer", "Epee", "Sword", "Sabre", "Dague", "Dagger",
    "Casier", "Casiers", "Locker", "Lockers",
    "Gants", "Gant", "Gloves", "Boxing Gloves",
    "Alliance", "Bougie", "Candle", "Savon", "Soap", "Cle", "Key",
}
spawnerItemCache = {}
local function CollectItemSnapshot()
    spawnerItemCache = {}
    local function add(root)
        if not root then return end
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart") then
                    spawnerItemCache[obj.Name] = true
                end
            end
        end)
    end
    add(workspace)
    add(game:GetService("ReplicatedStorage"))
    add(game:GetService("ReplicatedFirst"))
    add(game:GetService("ServerStorage"))
    for _, player in ipairs(PlayersSvc:GetPlayers()) do
        add(player:FindFirstChild("Backpack"))
        local chr = player.Character
        if chr and chr.Parent then add(chr) end
    end
end

local function TokensOf(keyword)
    local tokens = {}
    for token in string.gmatch(keyword or "", "[^|]+") do
        local t = Normalize(token):gsub(" ", "")
        if t ~= "" then table.insert(tokens, t) end
    end
    return tokens
end

local function NameMatchesTokens(name, tokens)
    local norm = Normalize(name):gsub(" ", "")
    if norm:find("ringbox", 1, true) then return false end
    for _, t in ipairs(tokens) do
        if norm:find(t, 1, true) then return true end
    end
    return false
end

local function FindItemsByKeyword(keyword, includeCatalog)
    local tokens = TokensOf(keyword)
    if #tokens == 0 then return {} end
    local seen = {}
    local results = {}
    for name in pairs(spawnerItemCache) do
        if NameMatchesTokens(name, tokens) and not seen[name] then
            seen[name] = true
            table.insert(results, name)
        end
    end
    table.sort(results)
    if includeCatalog then
        for _, name in ipairs(KNOWN_CATALOG) do
            if not seen[name] and NameMatchesTokens(name, tokens) then
                seen[name] = true
                table.insert(results, name)
            end
        end
    end
    return results
end
-- aaaaaaaaaaaaaaaaaaaaaaaaaa END SPAWNER ENGINE aaaaaaaaaaaaaaaaaaaaaaaaaa

-- =====================================================================
--  TSUNAMI ENGINE - auto helpers + Popcorn Burst minigame (world & GUI)
-- =====================================================================
TsunamiVim = game:GetService("VirtualInputManager")

tsunamiCfg = {
    on = false,          -- auto collect coins/cash/loot
    clicker = false,     -- auto clicker at mouse position
    popcorn = false,     -- popcorn GUI auto-click
    god = false,         -- god mode (health & stamina)
    autojump = false,    -- auto jump
    safe = false,        -- safe TP (back to grounded spot)
    mgBot = false,       -- minigame bot (fish/cast/reel/play)
    c4 = false,          -- C4 clicker (col/cell/slot/connect)
    collectDelay = 0.35,
    popCooldown = 0.35,
    safeDelay = 2,
    mgBotDelay = 0.8,
    c4Delay = 1.2,
    c4Col = 0,
}
tsunamiStatusLabel = nil
tsunamiConn = nil
tsunamiTimers = {}
tsunamiSafeSpot = nil

local function TsunamiClickAt(x, y)
    pcall(function()
        TsunamiVim:SendMouseButtonEvent(x, y, 0, true, Enum.UserInputType.MouseButton1, 0)
        TsunamiVim:SendMouseButtonEvent(x, y, 0, false, Enum.UserInputType.MouseButton1, 0)
    end)
end

local function TsunamiGuiButtons()
    local out = {}
    local roots = { lp:FindFirstChild("PlayerGui"), CoreGui }
    for _, root in ipairs(roots) do
        if root then
            pcall(function()
                for _, obj in ipairs(root:GetDescendants()) do
                    if obj:IsA("TextButton") and obj.Visible and obj.AbsoluteSize.X > 10 and obj.AbsoluteSize.Y > 10
                        and NovaUI and not obj:IsDescendantOf(NovaUI) then
                        table.insert(out, obj)
                    end
                end
            end)
        end
    end
    return out
end

local function UpdateTsunamiStatus()
    if not tsunamiStatusLabel or not tsunamiStatusLabel.Parent then return end
    local parts = {}
    if tsunamiCfg.on then table.insert(parts, "Collect") end
    if tsunamiCfg.clicker then table.insert(parts, "Clicker") end
    if tsunamiCfg.popcorn then table.insert(parts, "PopcornGUI") end
    if tsunamiCfg.god then table.insert(parts, "God") end
    if tsunamiCfg.autojump then table.insert(parts, "Jump") end
    if tsunamiCfg.safe then table.insert(parts, "SafeTP") end
    if tsunamiCfg.mgBot then table.insert(parts, "MG-Bot") end
    if tsunamiCfg.c4 then table.insert(parts, "C4") end
    tsunamiStatusLabel.Text = #parts > 0 and ("Active: " .. table.concat(parts, " | ")) or "All OFF"
end

local function TsunamiHeartbeat(dt)
    local c = tsunamiCfg

    if c.on then
        tsunamiTimers.collect = (tsunamiTimers.collect or 0) + dt
        if tsunamiTimers.collect >= c.collectDelay then
            tsunamiTimers.collect = 0
            local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local best, bestD = nil, math.huge
                pcall(function()
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and obj:IsDescendantOf(workspace) and not obj.Anchored and obj.Transparency < 0.8 then
                            local n = string.lower(obj.Name)
                            if n:find("coin") or n:find("cash") or n:find("loot") or n:find("token") or n:find("star") or n:find("money") then
                                local d = (obj.Position - myRoot.Position).Magnitude
                                if d < bestD then best, bestD = obj, d end
                            end
                        end
                    end
                end)
                if best then
                    myRoot.CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 0))
                end
            end
        end
    end

    if c.clicker then
        tsunamiTimers.clicker = (tsunamiTimers.clicker or 0) + dt
        if tsunamiTimers.clicker >= 0.06 then
            tsunamiTimers.clicker = 0
            local m = UserInputService:GetMouseLocation()
            TsunamiClickAt(m.X, m.Y)
        end
    end

    if c.popcorn then
        tsunamiTimers.popcorn = (tsunamiTimers.popcorn or 0) + dt
        if tsunamiTimers.popcorn >= c.popCooldown then
            tsunamiTimers.popcorn = 0
            for _, b in ipairs(TsunamiGuiButtons()) do
                local n = string.lower(b.Name)
                if n:find("pop") or n:find("ring") or n:find("circle") or n:find("grain") or n:find("corn") or n:find("kernel") then
                    local p, s = b.AbsolutePosition, b.AbsoluteSize
                    TsunamiClickAt(p.X + s.X / 2, p.Y + s.Y / 2)
                    break
                end
            end
        end
    end

    if c.god then
        tsunamiTimers.god = (tsunamiTimers.god or 0) + dt
        if tsunamiTimers.god >= 0.25 then
            tsunamiTimers.god = 0
            local chr = lp.Character
            if chr then
                local hum = chr:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health < hum.MaxHealth then pcall(function() hum.Health = hum.MaxHealth end) end
                for _, v in ipairs(chr:GetDescendants()) do
                    if v:IsA("IntValue") or v:IsA("NumberValue") then
                        local n = string.lower(v.Name)
                        if n:find("stamina") or n:find("energy") or n:find("thirst") or n:find("hunger") then
                            pcall(function()
                                if v:IsA("IntValue") then v.Value = 100 else v.Value = v.Value + 50 end
                            end)
                        end
                    end
                end
                for k, _ in pairs(chr:GetAttributes()) do
                    local n = string.lower(tostring(k))
                    if n:find("stamina") or n:find("energy") or n:find("thirst") or n:find("hunger") then
                        pcall(function() chr:SetAttribute(k, 100) end)
                    end
                end
            end
        end
    end

    if c.autojump then
        tsunamiTimers.jump = (tsunamiTimers.jump or 0) + dt
        if tsunamiTimers.jump >= 0.6 then
            tsunamiTimers.jump = 0
            pcall(function()
                TsunamiVim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                TsunamiVim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
        end
    end

    if c.safe then
        local chr = lp.Character
        if chr then
            local hum = chr:FindFirstChildOfClass("Humanoid")
            local rp = chr:FindFirstChild("HumanoidRootPart")
            if hum and rp and hum.FloorMaterial ~= Enum.Material.Air then
                tsunamiSafeSpot = rp.Position
            end
        end
        tsunamiTimers.safe = (tsunamiTimers.safe or 0) + dt
        if tsunamiTimers.safe >= c.safeDelay then
            tsunamiTimers.safe = 0
            if tsunamiSafeSpot and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    lp.Character.HumanoidRootPart.CFrame = CFrame.new(tsunamiSafeSpot + Vector3.new(0, 2, 0))
                end)
            end
        end
    end

    if c.mgBot then
        tsunamiTimers.mg = (tsunamiTimers.mg or 0) + dt
        if tsunamiTimers.mg >= c.mgBotDelay then
            tsunamiTimers.mg = 0
            for _, b in ipairs(TsunamiGuiButtons()) do
                local n = string.lower(b.Name)
                if n:find("fish") or n:find("cast") or n:find("reel") or n:find("play") or n:find("next") or n:find("claim") then
                    local p, s = b.AbsolutePosition, b.AbsoluteSize
                    TsunamiClickAt(p.X + s.X / 2, p.Y + s.Y / 2)
                    break
                end
            end
        end
    end

    if c.c4 then
        tsunamiTimers.c4 = (tsunamiTimers.c4 or 0) + dt
        if tsunamiTimers.c4 >= c.c4Delay then
            tsunamiTimers.c4 = 0
            for _, b in ipairs(TsunamiGuiButtons()) do
                local n = string.lower(b.Name)
                if n:find("col") or n:find("cell") or n:find("slot") or n:find("connect") or n:find("bomb") then
                    if c.c4Col <= 0 or n:find(tostring(c.c4Col), 1, true) then
                        local p, s = b.AbsolutePosition, b.AbsoluteSize
                        TsunamiClickAt(p.X + s.X / 2, p.Y + s.Y / 2)
                        break
                    end
                end
            end
        end
    end
end

local function RebuildTsunami()
    local any = tsunamiCfg.on or tsunamiCfg.clicker or tsunamiCfg.popcorn or tsunamiCfg.god
        or tsunamiCfg.autojump or tsunamiCfg.safe or tsunamiCfg.mgBot or tsunamiCfg.c4
    if any then
        if not tsunamiConn then
            tsunamiConn = RunService.Heartbeat:Connect(TsunamiHeartbeat)
        end
    else
        if tsunamiConn then tsunamiConn:Disconnect(); tsunamiConn = nil end
    end
    UpdateTsunamiStatus()
end

-- -------------------------------------------------------------
-- Popcorn Burst minigame (world table + kernel clicking)
-- -------------------------------------------------------------
PopcornBurstAPI = {
    active = false, statusLabel = nil, conn = nil,
    root = nil, center = Vector3.zero,
    kernels = {}, indicator = nil, seat = nil,
    throwCount = 0, myScore = 0, botScore = 0, tokens = 0,
    roundLen = 10,
}

function PopcornBurstAPI.SetStatusLabel(label)
    PopcornBurstAPI.statusLabel = label
end

function PopcornBurstAPI.IsActive()
    return PopcornBurstAPI.active
end

function PopcornBurstAPI.UpdateStatus()
    local api = PopcornBurstAPI
    if not api.statusLabel or not api.statusLabel.Parent then return end
    if api.active then
        api.statusLabel.Text = "Popcorn Burst: ON | You: " .. api.myScore .. " | Bot: " .. api.botScore .. " | Tokens: " .. api.tokens
    else
        api.statusLabel.Text = "Popcorn Burst: OFF"
    end
end

function PopcornBurstAPI.Start()
    local api = PopcornBurstAPI
    if api.active then return end
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        notif("Need a character first", 2)
        return
    end
    if api.root and api.root.Parent then pcall(function() api.root:Destroy() end) end
    api.root = nil
    api.kernels = {}
    api.throwCount = 0
    api.myScore = 0
    api.botScore = 0

    local model = Instance.new("Model")
    model.Name = "PopcornTable"
    model.Parent = workspace

    local center = myRoot.Position + myRoot.CFrame.LookVector * 8
    api.center = center

    local top = Instance.new("Part")
    top.Name = "TableTop"
    top.Size = Vector3.new(12, 0.6, 12)
    top.Position = center
    top.Anchored = true
    top.CanCollide = false
    top.Material = Enum.Material.SmoothPlastic
    top.Color = Color3.fromRGB(35, 38, 56)
    top.Transparency = 0.15
    top.Parent = model

    local function makePart(name, size, pos, color)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Position = pos
        p.Anchored = true
        p.CanCollide = false
        p.Material = Enum.Material.Neon
        p.Color = color
        p.Transparency = 0.15
        p.Parent = model
        return p
    end

    for i = 1, 4 do
        local ang = (i - 1) / 4 * math.pi * 2
        local legPos = center + Vector3.new(math.cos(ang) * 5, -2.4, math.sin(ang) * 5)
        makePart("Leg" .. i, Vector3.new(0.7, 4.2, 0.7), legPos, Color3.fromRGB(60, 64, 92))
    end

    local plate = makePart("Plate", Vector3.new(0.2, 10.8, 10.8), center + Vector3.new(0, 1.1, 0), Color3.fromRGB(28, 30, 44))
    plate.Shape = Enum.PartType.Cylinder
    plate.Orientation = Vector3.new(0, 0, 90)
    plate.Transparency = 0.85

    for i = 0, 15 do
        local ang = i / 16 * math.pi * 2
        makePart("RingBox", Vector3.new(0.45, 0.45, 0.45), center + Vector3.new(math.cos(ang) * 5, 1.35, math.sin(ang) * 5), Color3.fromRGB(0, 200, 255))
    end

    local kernelPositions = {
        { math.cos(0) * 4.2, math.sin(0) * 4.2 },
        { math.cos(math.pi / 2) * 4.2, math.sin(math.pi / 2) * 4.2 },
        { math.cos(math.pi) * 4.2, math.sin(math.pi) * 4.2 },
        { math.cos(math.pi * 1.5) * 4.2, math.sin(math.pi * 1.5) * 4.2 },
    }
    for i, kp in ipairs(kernelPositions) do
        local kernel = makePart("Kernel" .. i, Vector3.new(1.4, 1.4, 1.4), center + Vector3.new(kp[1], 1.4, kp[2]), Color3.fromRGB(255, 200, 80))
        kernel.Shape = Enum.PartType.Ball
        api.kernels[i] = kernel
    end

    api.indicator = makePart("Indicator", Vector3.new(0.9, 0.9, 0.9), center + Vector3.new(4.5, 1.4, 0), Color3.fromRGB(255, 84, 108))
    api.indicator.Shape = Enum.PartType.Ball

    local seat = Instance.new("Part")
    seat.Name = "PopcornSeat"
    seat.Size = Vector3.new(6, 0.5, 6)
    seat.Position = center - myRoot.CFrame.LookVector * 2 + Vector3.new(0, 0.2, 0)
    seat.Anchored = true
    seat.CanCollide = false
    seat.Transparency = 1
    seat.Parent = model
    api.seat = seat

    api.root = model
    api.active = true
    local lastStatus = 0
    api.conn = RunService.RenderStepped:Connect(function()
        if api.indicator and api.indicator.Parent and api.active then
            local ang = tick() * 1.3
            api.indicator.CFrame = CFrame.new(center + Vector3.new(math.cos(ang) * 4.5, 1.4, math.sin(ang) * 4.5))
        end
        if tick() - lastStatus > 0.5 then
            lastStatus = tick()
            api:UpdateStatus()
        end
    end)
    notif("Popcorn Burst: ON - click kernels when the ring meets them (E = sit)", 4)
    api:UpdateStatus()
end

function PopcornBurstAPI.TryHit(part)
    local api = PopcornBurstAPI
    if not api.active or not part then return false end
    for i, k in ipairs(api.kernels) do
        if k == part then
            api:RegisterThrow(i)
            return true
        end
    end
    return false
end

function PopcornBurstAPI.TrySit()
    local api = PopcornBurstAPI
    if not api.active then return end
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if myRoot and hum and api.seat and api.seat.Parent then
        if (myRoot.Position - api.seat.Position).Magnitude < 12 then
            pcall(function() hum:Sit(api.seat) end)
        end
    end
end

function PopcornBurstAPI.RegisterThrow(kernelIndex)
    local api = PopcornBurstAPI
    local kernel = api.kernels[kernelIndex]
    local ind = api.indicator
    if not (kernel and ind and ind.Parent) then return end
    local vK = (kernel.Position - api.center).Unit
    local vI = (ind.Position - api.center).Unit
    local dot = math.clamp(vK:Dot(vI), -1, 1)
    local deg = math.deg(math.acos(dot))
    local score, tag = 0, "MISS"
    if deg <= 8 then score, tag = 100, "PERFECT"
    elseif deg <= 20 then score, tag = 50, "GREAT"
    elseif deg <= 40 then score, tag = 20, "GOOD"
    end
    api.myScore = api.myScore + score
    api.throwCount = api.throwCount + 1
    api.botScore = api.botScore + math.random(0, 70)
    notif("Popcorn: " .. tag .. " +" .. score .. " | you: " .. api.myScore .. " | bot: " .. api.botScore, 1.5)
    pcall(function()
        TweenService:Create(kernel, TweenInfo.new(0.3), {
            Color = score >= 50 and Color3.fromRGB(64, 233, 142) or (score > 0 and Color3.fromRGB(255, 190, 62) or Color3.fromRGB(255, 84, 108)),
            Transparency = 0,
        }):Play()
    end)
    if api.throwCount >= api.roundLen then
        local gain = api.myScore > api.botScore and 10 or (api.myScore == api.botScore and 5 or 2)
        api.tokens = api.tokens + gain
        notif("Popcorn round over | you: " .. api.myScore .. " | bot: " .. api.botScore .. " | +" .. gain .. " tokens", 3)
        api.throwCount = 0
        api.myScore = 0
        api.botScore = 0
        for _, k in ipairs(api.kernels) do
            if k and k.Parent then
                pcall(function()
                    TweenService:Create(k, TweenInfo.new(0.3), { Color = Color3.fromRGB(255, 200, 80) }):Play()
                end)
            end
        end
    end
    api:UpdateStatus()
end

function PopcornBurstAPI.Stop()
    local api = PopcornBurstAPI
    if not api.active then return end
    api.active = false
    if api.conn then api.conn:Disconnect(); api.conn = nil end
    if api.root and api.root.Parent then pcall(function() api.root:Destroy() end) end
    api.root = nil
    api.kernels = {}
    api.indicator = nil
    api.seat = nil
    if lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Seated then pcall(function() hum.Sit = false end) end
    end
    api:UpdateStatus()
    notif("Popcorn Burst: OFF", 2)
end

-- aaaaaaaaaaaaaaaaaaaaaaaaaa CONTENT BUILDER aaaaaaaaaaaaaaaaaaaaaaaaaa
UpdateRightContent = function()
    ClearContent()
    local function BuildHomeTab()
        local hero = Section(ContentScroll, "Welcome back", "home")
        local greet = Label(hero, "sa7loul V3 | Premium redesign", UITheme.TEXT, 17)
        greet.Font = Enum.Font.GothamBold
        Label(hero, "Survive the Killer | full feature suite | press RightShift to hide UI", UITheme.SUBTEXT, 11)
        Label(hero, "", UITheme.DIM, 5)
        local statsLabel = Label(hero, "FPS: --  |  Ping: --ms  |  Players: --", UITheme.CYAN, 12)
        UITheme:RegisterAccent(function(c) statsLabel.TextColor3 = c end)
        task.spawn(function()
            while statsLabel and statsLabel.Parent do
                local ping = 0
                pcall(function()
                    ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                statsLabel.Text = "FPS: " .. math.floor(fpsMeter) .. "  |  Ping: " .. ping .. "ms  |  Players: " .. #PlayersSvc:GetPlayers()
                task.wait(1)
            end
        end)

        local quick = Section(ContentScroll, "Quick access", "zap")
        Button(quick, "Player features", function() SwitchTab("Player") end)
        Button(quick, "Troll features", function() SwitchTab("Troll") end)
        Button(quick, "Item spawner", function() SwitchTab("Spawner") end)
        Button(quick, "Player list", function() SwitchTab("Players") end)
        Button(quick, "Settings", function() SwitchTab("Settings") end)

        local info = Section(ContentScroll, "Changelog V3", "history")
        local changelog = {
            "V3.2 | Design rework & stability",
            "FIXED: full UI not building on some executors (load error)",
            "Reordered tabs: Home - Player - Revive - World - Players",
            "Minimize: small bar stays with a restore button",
            "NEW: Spawner tab (Ring Box / Sche-cheveux / Cuffs / Lockers)",
            "NEW: Jump Power, FOV, Fly+NoClip, TP to downed, random loot TP",
            "NEW: TP to target - Copy tools - Attack target",
            "Redesigned section cards + live status bar (FPS/Ping)",
            "Keybinds on every toggle - RGB mode - search bar",
            "Troll tab (fling, annoy, fake admin, ghost, earrape, click-TP)",
        }
        for _, line in ipairs(changelog) do
            Label(info, line, UITheme.SUBTEXT, 11)
        end
        Label(hero, "", UITheme.DIM, 5)
        Label(hero, "Developer: sa7loul  |  Tailored for STK v2.31.0", UITheme.DIM, 10)

    -- a-a-a-a-a-a-a-a-a-a-a- PLAYER a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildPlayerTab()
        local movement = Section(ContentScroll, "Movement", "activity")
        local speedHandle = ToggleRow(movement, {
            text = "Speed Boost", id = "speed",
            state = settings.speedEnabled,
            onToggle = function(val)
                settings.speedEnabled = val
                pcall(function()
                    if lp.Character then
                        lp.Character.Humanoid.WalkSpeed = val and settings.Speed or 16
                    end
                end)
            end
        })
        Slider(movement, {
            text = "Walk Speed Slider (Max 200)", min = 16, max = 200, def = settings.Speed,
            onChanged = function(val)
                settings.Speed = val
                if settings.speedEnabled and lp.Character then
                    pcall(function() lp.Character.Humanoid.WalkSpeed = val end)
                end
            end
        })
        ToggleRow(movement, {
            text = "Fly", id = "fly", state = settings.Fly,
            desc = "WASD + Space / LeftControl",
            onToggle = function(val)
                settings.Fly = val
                UpdateFly()
            end
        })
        Slider(movement, {
            text = "Flight speed", min = 20, max = 200, def = settings.flySpeed,
            onChanged = function(val) settings.flySpeed = val end
        })
        ToggleRow(movement, {
            text = "Noclip", id = "noclip", state = settings.Noclip,
            onToggle = function(val)
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
            end
        })
        ToggleRow(movement, {
            text = "Fly + Noclip", id = "flynoclip", state = false,
            desc = "Fly TNV — fly and noclip together",
            onToggle = function(val)
                settings.Fly = val
                settings.Noclip = val
                UpdateFly()
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
            end
        })
        ToggleRow(movement, {
            text = "Disable speed when down", id = "speedoff",
            state = settings.speedDisableOnDown,
            onToggle = function(val) settings.speedDisableOnDown = val end
        })
        Slider(movement, {
            text = "Gravity", min = 0, max = 196.2, def = 196.2, decimals = 1,
            onChanged = function(val)
                pcall(function() workspace.Gravity = val end)
            end
        })
        Slider(movement, {
            text = "Swim Speed", min = 10, max = 100, def = 50,
            onChanged = function(val)
                pcall(function()
                    if lp.Character then
                        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                        if hum then hum.SwimSpeed = val end
                    end
                end)
            end
        })
        Button(movement, "Reset gravity (196.2)", function()
            pcall(function() workspace.Gravity = 196.2 end)
            notif("Gravity reset", 2)
        end)
        ToggleRow(movement, {
            text = "Auto Escape", id = "autoesc", state = settings.AutoEscape,
            desc = "Teleports to exit when the timer starts",
            onToggle = function(val)
                settings.AutoEscape = val
                if val then
                    if autoEscapeConnection then autoEscapeConnection:Disconnect() end
                    autoEscapeConnection = RunService.Heartbeat:Connect(AutoEscapeLoop)
                else
                    if autoEscapeConnection then autoEscapeConnection:Disconnect(); autoEscapeConnection = nil end
                end
            end
        })
        ToggleRow(movement, {
            text = "Panic TP", id = "panictp", state = settings.PanicTP,
            desc = "Auto-TP away when spotted",
            onToggle = function(val)
                settings.PanicTP = val
                if val then
                    if panicTPConnection then panicTPConnection:Disconnect() end
                    panicTPConnection = RunService.Heartbeat:Connect(function()
                        if settings.PanicTP then CheckPanicTP() end
                    end)
                else
                    if panicTPConnection then panicTPConnection:Disconnect(); panicTPConnection = nil end
                end
            end
        })

        local bypass = Section(ContentScroll, "Bypass", "")
        ToggleRow(bypass, {
            text = "Double Jump", id = "dbljump", state = settings.DoubleJump,
            onToggle = function(val)
                settings.DoubleJump = val
                UpdateDoubleJump()
            end
        })
        ToggleRow(bypass, {
            text = "Killer Chance X3", id = "killer3x", state = settings.KillerChanceX3,
            onToggle = function(val)
                settings.KillerChanceX3 = val
                UpdateKillerChance()
            end
        })

        local combat = Section(ContentScroll, "Combat", "target")
        local killauraHandle = ToggleRow(combat, {
            text = "Kill Aura", id = "killaura", state = settings.KillAura,
            onToggle = function(val)
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
            end
        })
        Slider(combat, {
            text = "Kill Aura radius", min = 8, max = 80, def = settings.killAuraRadius,
            onChanged = function(val) settings.killAuraRadius = val end
        })

        local powers = Section(ContentScroll, "Powers", "zap")
        Slider(powers, {
            text = "Jump Power", min = 20, max = 160, def = 50,
            onChanged = function(val)
                pcall(function()
                    if lp.Character then
                        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum.UseJumpPower = true
                            hum.JumpPower = val
                        end
                    end
                end)
            end
        })
        local flyRow = Instance.new("Frame")
        flyRow.Parent = powers
        flyRow.BackgroundTransparency = 1
        flyRow.Size = UDim2.new(1, 0, 0, 34)
        local flyLay = Instance.new("UIListLayout", flyRow)
        flyLay.FillDirection = Enum.FillDirection.Horizontal
        flyLay.Padding = UDim.new(0, 6)
        Button(flyRow, { text = "Fly + NoClip", size = UDim2.new(0.48, 0, 0, 30), accent = true, callback = GiveFlyNoClip })
        Button(flyRow, { text = "Reset jump", size = UDim2.new(0.48, 0, 0, 30), callback = function()
            pcall(function()
                if lp.Character then
                    local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.JumpPower = 50 end
                    notif("Jump power reset to 50", 2)
                end
            end)
        end })

    -- a-a-a-a-a-a-a-a-a-a-a- WORLD a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildWorldTab()
        local visuals = Section(ContentScroll, "Visuals", "eye")
        ToggleRow(visuals, {
            text = "Player ESP", id = "esp", state = settings.ESP,
            onToggle = function(val)
                settings.ESP = val
                espCache = {}
                UpdateESP()
            end
        })
        ToggleRow(visuals, {
            text = "Exit ESP", id = "espexits", state = settings.ESPExits,
            onToggle = function(val)
                settings.ESPExits = val
                UpdateESPExits()
            end
        })
        ToggleRow(visuals, {
            text = "Trap ESP", id = "esptraps", state = settings.ESPTraps,
            onToggle = function(val)
                settings.ESPTraps = val
                UpdateESPTraps()
            end
        })
        ToggleRow(visuals, {
            text = "Remove fog", id = "nofog", state = settings.NoFog,
            onToggle = function(val)
                settings.NoFog = val
                UpdateNoFog()
            end
        })
        ToggleRow(visuals, {
            text = "Fullbright", id = "fullbright", state = settings.Fullbright,
            onToggle = function(val)
                settings.Fullbright = val
                if val then
                    if brightLoop then brightLoop:Disconnect() end
                    brightLoop = RunService.RenderStepped:Connect(function()
                        Lighting.Brightness = 2
                        Lighting.ClockTime = 14
                        Lighting.GlobalShadows = false
                        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                    end)
                else
                    if brightLoop then brightLoop:Disconnect(); brightLoop = nil end
                end
            end
        })
        ToggleRow(visuals, {
            text = "Anti-Trap", id = "antitrap", state = settings.AntiTrap,
            desc = "Destroys trap hitboxes",
            onToggle = function(val)
                settings.AntiTrap = val
                if val then
                    if antiTrapConnection then antiTrapConnection:Disconnect() end
                    antiTrapConnection = RunService.Heartbeat:Connect(function()
                        if settings.AntiTrap then RemoveTraps() end
                    end)
                else
                    if antiTrapConnection then antiTrapConnection:Disconnect(); antiTrapConnection = nil end
                end
            end
        })

        local loot = Section(ContentScroll, "Auto Loot", "")
        ToggleRow(loot, {
            text = "Auto collect loot", id = "loot", state = settings.AutoLoot,
            onToggle = function(val)
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
            end
        })
        ToggleRow(loot, {
            text = "Return home after looting", id = "loothome",
            state = settings.returnHomeAfterLoot,
            onToggle = function(val) settings.returnHomeAfterLoot = val end
        })

        local tp = Section(ContentScroll, "Teleport", "")
        Button(tp, "Teleport to exit", TeleportToExit)
        Button(tp, "Teleport to lobby", function()
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

        local camera = Section(ContentScroll, "Camera", "")
        Slider(camera, {
            text = "Field of View", min = 55, max = 120, def = 70,
            onChanged = function(val)
                pcall(function() workspace.CurrentCamera.FieldOfView = val end)
            end
        })
        Button(camera, "Reset FOV (70)", function()
            pcall(function() workspace.CurrentCamera.FieldOfView = 70 end)
            notif("FOV reset to 70", 2)
        end)

        local quickTP = Section(ContentScroll, "Quick teleports", "")
        Button(quickTP, "Nearest downed player", function()
            local best, bestDist = nil, math.huge
            for _, p in ipairs(PlayersSvc:GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and IsPlayerDowned(p) then
                    local d = (p.Character.HumanoidRootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                    if d < bestDist then best, bestDist = p, d end
                end
            end
            if best and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = best.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 3)
                notif("TP to downed: " .. best.Name, 2)
            else
                notif("No downed players found", 2)
            end
        end)
        Button(quickTP, "Random loot spot", function()
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
            local loot = {}
            local map = nil
            for _, child in ipairs(workspace:GetChildren()) do
                if child:FindFirstChild("LootSpawns") then map = child break end
            end
            if map and map:FindFirstChild("LootSpawns") then
                for _, spot in ipairs(map.LootSpawns:GetChildren()) do
                    if spot:IsA("BasePart") then table.insert(loot, spot.Position) end
                end
            end
            if #loot == 0 then
                notif("No loot spots found", 2)
                return
            end
            local pos = loot[math.random(1, #loot)]
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            notif("TP to random loot!", 2)
        end)

    -- a-a-a-a-a-a-a-a-a-a-a- PLAYERS a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildPlayersTab()
        playerListContainer = Section(ContentScroll, "Player list", "users")
        Note(playerListContainer, "Click a row to select - bring, TP, fly, view, freeze")
        local row = Instance.new("Frame")
        row.Parent = ContentScroll
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, 0, 0, 34)
        local rowLay = Instance.new("UIListLayout", row)
        rowLay.FillDirection = Enum.FillDirection.Horizontal
        rowLay.Padding = UDim.new(0, 6)
        Button(row, { text = "Refresh", size = UDim2.new(0.48, 0, 0, 30), callback = UpdatePlayerList })
        Button(row, { text = "Stop all", size = UDim2.new(0.48, 0, 0, 30), callback = function()
            StopView()
            StopBring()
            StopBringAll()
            notif("All operations stopped", 2)
        end })
        UpdatePlayerList()

    -- a-a-a-a-a-a-a-a-a-a-a- REVIVE a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildReviveTab()
        local revive = Section(ContentScroll, "Revive modes", "heart")
        ToggleRow(revive, {
            text = "Auto revive (Safe)", id = "autoRevive", state = settings.AutoReviveLegit,
            desc = "Revives the nearest downed survivor when safe",
            onToggle = function(val)
                settings.AutoReviveLegit = val
                if val then
                    if reviveLegitConnection then reviveLegitConnection:Disconnect() end
                    reviveLegitConnection = RunService.Heartbeat:Connect(AutoReviveLegitLoop)
                else
                    if reviveLegitConnection then reviveLegitConnection:Disconnect(); reviveLegitConnection = nil end
                end
            end
        })
        Button(revive, "Risky revive (one-time)", function() AutoReviveRiskyOneUse() end)

        local selfRevive = Section(ContentScroll, "Self revive", "")
        ToggleRow(selfRevive, {
            text = "Auto self revive", id = "selfRevive", state = settings.AutoReviveSelf,
            desc = "Teleports you to a survivor while downed",
            onToggle = function(val)
                settings.AutoReviveSelf = val
                if val then
                    if selfReviveConnection then selfReviveConnection:Disconnect() end
                    selfReviveConnection = RunService.Heartbeat:Connect(AutoReviveSelfLoop)
                else
                    if selfReviveConnection then selfReviveConnection:Disconnect(); selfReviveConnection = nil end
                end
            end
        })
        Slider(selfRevive, {
            text = "Cooldown", min = 1, max = 10, def = settings.selfReviveCooldown,
            onChanged = function(val) settings.selfReviveCooldown = val end
        })
        local modeRow = Instance.new("Frame")
        modeRow.Parent = selfRevive
        modeRow.BackgroundTransparency = 1
        modeRow.Size = UDim2.new(1, 0, 0, 34)
        local modeLay = Instance.new("UIListLayout", modeRow)
        modeLay.FillDirection = Enum.FillDirection.Horizontal
        modeLay.Padding = UDim.new(0, 6)
        Button(modeRow, { text = "Random", size = UDim2.new(0.48, 0, 0, 30), callback = function()
            settings.selfReviveMode = "Random"
            notif("Revive mode: Random", 2)
        end })
        Button(modeRow, { text = "Farthest", size = UDim2.new(0.48, 0, 0, 30), callback = function()
            settings.selfReviveMode = "Farthest"
            notif("Revive mode: Farthest", 2)
        end })

    -- a-a-a-a-a-a-a-a-a-a-a- FUN a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildFunTab()
        local fun = Section(ContentScroll, "Target", "")
        selectedPlayerLabel = Instance.new("TextButton")
        selectedPlayerLabel.Parent = fun
        selectedPlayerLabel.BorderSizePixel = 0
        selectedPlayerLabel.Size = UDim2.new(1, 0, 0, 32)
        selectedPlayerLabel.Font = Enum.Font.GothamBold
        selectedPlayerLabel.Text = "Player: None"
        selectedPlayerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectedPlayerLabel.TextSize = 12
        selectedPlayerLabel.BackgroundColor3 = UITheme.Accent
        selectedPlayerLabel.BackgroundTransparency = 0.2
        selectedPlayerLabel.AutoButtonColor = false
        Instance.new("UICorner", selectedPlayerLabel).CornerRadius = UDim.new(0, 8)
        UITheme:RegisterAccent(function(c) selectedPlayerLabel.BackgroundColor3 = c end)
        selectedPlayerLabel.MouseButton1Click:Connect(CyclePlayer)
        AddPressAnim(selectedPlayerLabel)
        if not GetSelectedPlayer() then CyclePlayer() end

        local actions = Section(ContentScroll, "Actions", "zap")
        local row1 = Instance.new("Frame")
        row1.Parent = actions
        row1.BackgroundTransparency = 1
        row1.Size = UDim2.new(1, 0, 0, 34)
        local lay1 = Instance.new("UIListLayout", row1)
        lay1.FillDirection = Enum.FillDirection.Horizontal
        lay1.Padding = UDim.new(0, 6)
        Button(row1, { text = "Fling", size = UDim2.new(0.48, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if not target then notif("Select a player first", 2) return end
            if FlingActive then notif("Fling already active", 2) return end
            FlingActive = true
            notif("Fling: " .. target.Name, 2)
            local thrust = nil
            pcall(function()
                thrust = Instance.new("BodyThrust", lp.Character.HumanoidRootPart)
                thrust.Force = Vector3.new(flingForce, flingForce, flingForce)
                thrust.Name = "YeetForce"
            end)
            coroutine.wrap(function()
                while FlingActive and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") do
                    lp.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
                    if thrust then thrust.Location = target.Character.HumanoidRootPart.Position end
                    RunService.Heartbeat:Wait()
                end
                if thrust and thrust.Parent then pcall(function() thrust:Destroy() end) end
                FlingActive = false
            end)()
        end })
        Button(row1, { text = "Stop fling", size = UDim2.new(0.48, 0, 0, 32), callback = function()
            FlingActive = false
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local thrust = lp.Character.HumanoidRootPart:FindFirstChild("YeetForce")
                if thrust then pcall(function() thrust:Destroy() end) end
            end
            notif("Fling stopped", 2)
        end })

        local row2 = Instance.new("Frame")
        row2.Parent = actions
        row2.BackgroundTransparency = 1
        row2.Size = UDim2.new(1, 0, 0, 34)
        local lay2 = Instance.new("UIListLayout", row2)
        lay2.FillDirection = Enum.FillDirection.Horizontal
        lay2.Padding = UDim.new(0, 6)
        Button(row2, { text = "Freeze", size = UDim2.new(0.48, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if target then FreezePlayer(target.Name) else notif("Select a player first", 2) end
        end })
        Button(row2, { text = "Unfreeze", size = UDim2.new(0.48, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if target then ThawPlayer(target.Name) else notif("Select a player first", 2) end
        end })

        local row3 = Instance.new("Frame")
        row3.Parent = actions
        row3.BackgroundTransparency = 1
        row3.Size = UDim2.new(1, 0, 0, 34)
        local lay3 = Instance.new("UIListLayout", row3)
        lay3.FillDirection = Enum.FillDirection.Horizontal
        lay3.Padding = UDim.new(0, 6)
        Button(row3, { text = "View", size = UDim2.new(0.48, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if target then StartView(target.Name) else notif("Select a player first", 2) end
        end })
        Button(row3, { text = "Stop view", size = UDim2.new(0.48, 0, 0, 32), callback = StopView })

        local row4 = Instance.new("Frame")
        row4.Parent = actions
        row4.BackgroundTransparency = 1
        row4.Size = UDim2.new(1, 0, 0, 34)
        local lay4 = Instance.new("UIListLayout", row4)
        lay4.FillDirection = Enum.FillDirection.Horizontal
        lay4.Padding = UDim.new(0, 6)
        Button(row4, { text = "Bring", size = UDim2.new(0.48, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if target then StartBring(target.Name) else notif("Select a player first", 2) end
        end })
        Button(row4, { text = "Stop bring", size = UDim2.new(0.48, 0, 0, 32), callback = StopBring })

        local row5 = Instance.new("Frame")
        row5.Parent = actions
        row5.BackgroundTransparency = 1
        row5.Size = UDim2.new(1, 0, 0, 34)
        local lay5 = Instance.new("UIListLayout", row5)
        lay5.FillDirection = Enum.FillDirection.Horizontal
        lay5.Padding = UDim.new(0, 6)
        Button(row5, { text = "Bring All", size = UDim2.new(0.31, 0, 0, 32), callback = StartBringAll })
        Button(row5, { text = "Unbring", size = UDim2.new(0.31, 0, 0, 32), callback = UnbringSelected })
        Button(row5, { text = "Stop", size = UDim2.new(0.31, 0, 0, 32), callback = StopBringAll })

        local row6 = Instance.new("Frame")
        row6.Parent = actions
        row6.BackgroundTransparency = 1
        row6.Size = UDim2.new(1, 0, 0, 34)
        local lay6 = Instance.new("UIListLayout", row6)
        lay6.FillDirection = Enum.FillDirection.Horizontal
        lay6.Padding = UDim.new(0, 6)
        Button(row6, { text = "TP to target", size = UDim2.new(0.31, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if not target then notif("Select a player first", 2) return end
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 3)
                notif("TP to: " .. target.Name, 2)
            else
                notif("Player not found", 2)
            end
        end })
        Button(row6, { text = "Copy tools", size = UDim2.new(0.31, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if not target then notif("Select a player first", 2) return end
            local copied = 0
            local backpack = target:FindFirstChild("Backpack")
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        pcall(function()
                            tool:Clone().Parent = lp:FindFirstChild("Backpack")
                            copied = copied + 1
                        end)
                    end
                end
            end
            if target.Character then
                for _, tool in ipairs(target.Character:GetChildren()) do
                    if tool:IsA("Tool") then
                        pcall(function()
                            tool:Clone().Parent = lp:FindFirstChild("Backpack")
                            copied = copied + 1
                        end)
                    end
                end
            end
            notif(copied > 0 and ("Copied " .. copied .. " tool(s) from " .. target.Name) or "No tools found on " .. target.Name, 2)
        end })
        Button(row6, { text = "Attack target", size = UDim2.new(0.31, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if not target then notif("Select a player first", 2) return end
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local forward = lp.Character.HumanoidRootPart.CFrame.LookVector
                target.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame + (forward * 3)
                task.wait(0.05)
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(0, 0, 0, true, Enum.UserInputType.MouseButton1, 0)
                task.wait()
                vim:SendMouseButtonEvent(0, 0, 0, false, Enum.UserInputType.MouseButton1, 0)
                notif("Attack: " .. target.Name, 2)
            else
                notif("Player not found", 2)
            end
        end })

        local row7 = Instance.new("Frame")
        row7.Parent = actions
        row7.BackgroundTransparency = 1
        row7.Size = UDim2.new(1, 0, 0, 34)
        local lay7 = Instance.new("UIListLayout", row7)
        lay7.FillDirection = Enum.FillDirection.Horizontal
        lay7.Padding = UDim.new(0, 6)
        Button(row7, { text = "Admin fly/no-clip (remotes)", size = UDim2.new(1, 0, 0, 32), accent = true, callback = function()
            local target = GetSelectedPlayer()
            if not target then
                notif("Select a player first", 2)
                return
            end
            if TryFireAdminRemote(target) then
                notif("Admin remotes fired at " .. target.Name, 2)
            else
                notif("No admin remotes found", 3)
            end
        end })

        local spinSection = Section(ContentScroll, "Party", "")
        local spinHandle = ToggleRow(spinSection, {
            text = "Spin", id = "spin", state = spinActive,
            onToggle = function(val)
                spinActive = val
                UpdateSpin(val)
            end
        })
        Slider(spinSection, {
            text = "Spin speed", min = 1, max = 300, def = spinSpeed,
            onChanged = function(val)
                spinSpeed = val
                if spinActive and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    local spin = lp.Character.HumanoidRootPart:FindFirstChild("Spinning")
                    if spin then spin.AngularVelocity = Vector3.new(0, spinSpeed, 0) end
                end
            end
        })
        Slider(spinSection, {
            text = "Bring distance", min = 1, max = 12, def = bringDistance,
            onChanged = function(val) bringDistance = val end
        })
        Slider(spinSection, {
            text = "Fling force", min = 1000, max = 50000, def = flingForce,
            onChanged = function(val) flingForce = val end
        })

        -- CUFF ITEMS - spawner / giver
        local cuffSection = Section(ContentScroll, "Cuff Items - Spawn / Give / Take", "")
        local cuffStatus = Label(cuffSection, "Scanning for cuffs...", UITheme.SUBTEXT, 11)
        local cuffPlayerOptions = {}
        for i = #cuffPlayerOptions, 1, -1 do cuffPlayerOptions[i] = nil end
        for _, p in ipairs(PlayersSvc:GetPlayers()) do
            table.insert(cuffPlayerOptions, { text = p.Name, value = p })
        end
        Dropdown(cuffSection, {
            text = "Give to player",
            options = cuffPlayerOptions,
            default = 1,
            onChanged = function(value)
                SetSelectedPlayer(value)
                notif("Cuff target: " .. (value and value.Name or "None"), 2)
            end
        })
        local cuffRows = Instance.new("Frame")
        cuffRows.Parent = cuffSection
        cuffRows.BackgroundTransparency = 1
        cuffRows.Size = UDim2.new(1, 0, 0, 0)
        cuffRows.AutomaticSize = Enum.AutomaticSize.Y
        cuffRows.LayoutOrder = #cuffSection:GetChildren()
        local cuffListLayout = Instance.new("UIListLayout", cuffRows)
        cuffListLayout.Padding = UDim.new(0, 6)
        cuffListLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local function RebuildCuffList()
            for _, child in ipairs(cuffRows:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            local names = GetAllCuffItemNames()
            if #names == 0 then
                cuffStatus.Text = "No cuffs found - start a round & rescan"
                Label(cuffRows, "No cuff items in the game right now", UITheme.DIM, 11)
                return
            end
            cuffStatus.Text = "Found " .. #names .. " cuff item(s)"
            local selTarget = GetSelectedPlayer()
            for _, itemName in ipairs(names) do
                local row = Instance.new("Frame")
                row.Parent = cuffRows
                row.BackgroundTransparency = 1
                row.Size = UDim2.new(1, 0, 0, 34)
                row.LayoutOrder = #cuffRows:GetChildren()
                local rowLayout = Instance.new("UIListLayout", row)
                rowLayout.FillDirection = Enum.FillDirection.Horizontal
                rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                rowLayout.Padding = UDim.new(0, 6)

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Parent = row
                nameLabel.BackgroundTransparency = 1
                nameLabel.Size = UDim2.new(0.36, 0, 1, 0)
                nameLabel.Font = Enum.Font.Gotham
                nameLabel.Text = itemName
                nameLabel.TextColor3 = UITheme.TEXT
                nameLabel.TextSize = 11
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

                Button(row, {
                    text = "Spawn me", size = UDim2.new(0.3, 0, 0, 28), accent = true,
                    callback = function() SpawnCuffItemForMe(itemName) end
                })

                Button(row, {
                    text = "Give to: " .. (selTarget and selTarget.Name or "None"),
                    size = UDim2.new(0.3, 0, 0, 28),
                    callback = function()
                        local target = GetSelectedPlayer()
                        if not target then
                            notif("Select a player first ( Player button)", 2)
                        else
                            GiveCuffItemToPlayer(itemName, target)
                        end
                    end
                })
            end
        end

        Button(cuffSection, "Rescan cuffs", RebuildCuffList)

        local cuffTargetBox = TextBox(cuffSection, { placeholder = "Give to player name (empty = selected)" })
        Button(cuffSection, "Give every cuff to target", function()
            local name = cuffTargetBox.Text ~= "" and cuffTargetBox.Text or nil
            local target = name and GetPlayerByName(name) or GetSelectedPlayer() or lp
            if not target then
                notif("Type a name or select a player", 2)
                return
            end
            local names = GetAllCuffItemNames()
            if #names == 0 then
                notif("No cuffs found in the game", 2)
                return
            end
            local given = 0
            for _, itemName in ipairs(names) do
                if GiveCuffItemToPlayer(itemName, target) then given = given + 1 end
            end
            notif("Gave " .. given .. " cuff item(s) to " .. target.Name, 2)
        end)

        Button(cuffSection, "Take cuffs from selected player", function()
            TakeCuffsFromTarget(GetSelectedPlayer())
        end)

        Button(cuffSection, "Remove my cuffs", RemoveMyCuffs)

        Note(cuffSection, "Auto-detects every item named 'cuff' (backpacks, hands, map). Pick the target with the Home player chip or the button in Actions.")
        task.defer(RebuildCuffList)

    -- a-a-a-a-a-a-a-a-a-a-a- SPAWNER a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildSpawnerTab()
        local function MakeTargetChip(section)
            local chip = Instance.new("TextButton")
            chip.Parent = section
            chip.BorderSizePixel = 0
            chip.Size = UDim2.new(1, 0, 0, 32)
            chip.Font = Enum.Font.GothamBold
            chip.Text = "Give to: " .. (GetSelectedPlayer() and GetSelectedPlayer().Name or "None (click me)")
            chip.TextColor3 = Color3.fromRGB(255, 255, 255)
            chip.TextSize = 12
            chip.AutoButtonColor = false
            chip.BackgroundColor3 = UITheme.Accent
            chip.BackgroundTransparency = 0.2
            Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 8)
            UITheme:RegisterAccent(function(c) chip.BackgroundColor3 = c end)
            chip.MouseButton1Click:Connect(function()
                CyclePlayer()
                chip.Text = "Give to: " .. (GetSelectedPlayer() and GetSelectedPlayer().Name or "None")
            end)
            AddPressAnim(chip)
            return chip
        end

        local function MakeItemRow(parent, itemName)
            local row = Instance.new("Frame")
            row.Parent = parent
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, 34)
            row.LayoutOrder = #parent:GetChildren()
            local rowLayout = Instance.new("UIListLayout", row)
            rowLayout.FillDirection = Enum.FillDirection.Horizontal
            rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            rowLayout.Padding = UDim.new(0, 6)

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Parent = row
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size = UDim2.new(0.36, 0, 1, 0)
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.Text = ItemIcon(itemName) .. "  " .. itemName
            nameLabel.TextColor3 = UITheme.TEXT
            nameLabel.TextSize = 11
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

            Button(row, {
                text = "Spawn", size = UDim2.new(0.3, 0, 0, 28), accent = true,
                callback = function() SpawnSpawnItemForMe(itemName) end
            })
            Button(row, {
                text = "Give", size = UDim2.new(0.3, 0, 0, 28),
                callback = function()
                    local target = GetSelectedPlayer()
                    if not target then
                        notif("Pick a target first (chip)", 2)
                    else
                        GiveSpawnItemToPlayer(itemName, target)
                    end
                end
            })
        end

        local function BuildSpawnerCategory(title, icon, keyword)
            local section = Section(ContentScroll, title, icon)
            local status = Label(section, "Scanning...", UITheme.SUBTEXT, 11)
            local rows = Instance.new("Frame")
            rows.Parent = section
            rows.BackgroundTransparency = 1
            rows.Size = UDim2.new(1, 0, 0, 0)
            rows.AutomaticSize = Enum.AutomaticSize.Y
            rows.LayoutOrder = #section:GetChildren()
            local rowsLayout = Instance.new("UIListLayout", rows)
            rowsLayout.Padding = UDim.new(0, 6)
            rowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            local function rebuild()
                for _, child in ipairs(rows:GetChildren()) do
                    if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
                end
                local names = FindItemsByKeyword(keyword, true)
                if #names == 0 then
                    status.Text = title .. " | nothing found (start a round & rescan)"
                    Label(rows, "No items found for: " .. keyword, UITheme.DIM, 11)
                    return
                end
                status.Text = "Found " .. #names .. " item(s): " .. keyword
                for _, itemName in ipairs(names) do
                    MakeItemRow(rows, itemName)
                end
            end
            Button(section, "Rescan", function() CollectItemSnapshot(); rebuild() end)
            task.defer(rebuild)
            return section
        end

        local targetChipSection = Section(ContentScroll, "Target", "")
        local targetChip = MakeTargetChip(targetChipSection)
        local spawnerPlayerOptions = {}
        for i = #spawnerPlayerOptions, 1, -1 do spawnerPlayerOptions[i] = nil end
        for _, p in ipairs(PlayersSvc:GetPlayers()) do
            table.insert(spawnerPlayerOptions, { text = p.Name, value = p })
        end
        Dropdown(targetChipSection, {
            text = "Give to player",
            options = spawnerPlayerOptions,
            default = 1,
            onChanged = function(value)
                SetSelectedPlayer(value)
                if targetChip then
                    targetChip.Text = "Give to: " .. (value and value.Name or "None (click me)")
                end
                notif("Give target: " .. (value and value.Name or "None"), 2)
            end
        })
        Note(targetChipSection, "Pick from the list, scroll if there are many players")

        CollectItemSnapshot()

        BuildSpawnerCategory("Razor / Cutter", "R", "ciseaux|cesaire|cutter|coupe|razor|scissors|rasoir")

        Note(ContentScroll, "Spawner clones the real in-game item for you or the chosen player. The chip above sets the give target.")

    -- a-a-a-a-a-a-a-a-a-a-a- TROLL a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildTrollTab()
        local targetSection = Section(ContentScroll, "Troll Target", "")
        trollTargetDD = Dropdown(targetSection, {
            text = "Target",
            options = trollTargetOptions,
            default = 1,
            onChanged = function(value)
                TrollTargetSel = value
                notif("Troll target: " .. (value and value.Name or "None"), 2)
            end
        })
        RefreshTrollTargetOptions()
        Button(targetSection, "Refresh players", RefreshTrollTargetOptions)

        local flingSection = Section(ContentScroll, "Annoy & Fling", "")
        TrollHandles.fling = ToggleRow(flingSection, {
            text = "Troll Fling", id = "trollfling", state = TrollCfg.fling,
            desc = "Physics yeet: angular velocity + random force on target",
            onToggle = function(val)
                if val then TrollFlingStart() else TrollFlingStop() end
            end
        })
        TrollHandles.annoy = ToggleRow(flingSection, {
            text = "Annoy Loop", id = "annoy", state = TrollCfg.annoy,
            desc = "Keeps teleporting around your target",
            onToggle = function(val)
                if val then TrollAnnoyStart() else TrollAnnoyStop() end
            end
        })
        Button(flingSection, "Stop all troll actions", function()
            TrollFlingStop()
            TrollAnnoyStop()
            notif("Troll actions stopped", 2)
        end)

        local chatSection = Section(ContentScroll, "Fake Admin / System Chat", "")
        local function fakeTargetName()
            local t = TrollGetTarget()
            return t and t.Name or "Player"
        end
        Button(chatSection, "Fake ban notice", function()
            FakeSystemMessage("[SYSTEM] " .. fakeTargetName() .. " has been banned by an administrator.", Color3.fromRGB(255, 90, 90))
            FakeNotification("Administrator", fakeTargetName() .. " was banned. Reason: Toxic Behavior", 4)
        end)
        Button(chatSection, "Fake kick notice", function()
            FakeSystemMessage("[SYSTEM] " .. fakeTargetName() .. " was kicked from the server.", Color3.fromRGB(255, 170, 70))
        end)
        Button(chatSection, "Fake server restart", function()
            FakeSystemMessage("[SYSTEM] Server restarting in 10 seconds. Reason: scheduled maintenance.", Color3.fromRGB(255, 120, 60))
            FakeNotification("Server", "Restarting in 10s...", 5)
        end)
        Button(chatSection, "Fake admin join", function()
            FakeSystemMessage("sa7loul joined the server. Commands available: !fly !noclip !ban", UITheme.CYAN)
        end)
        local fakeBox = TextBox(chatSection, { placeholder = "Custom fake system message..." })
        Button(chatSection, "Send fake message", function()
            if fakeBox.Text ~= "" then
                FakeSystemMessage(fakeBox.Text, Color3.fromRGB(255, 255, 255))
                fakeBox.Text = ""
            else
                notif("Type a message first", 2)
            end
        end)
        Note(chatSection, "Messages are client-side (only you see them)")

        local adminRemoteSection = Section(ContentScroll, "Fake Admin (remotes)", "")
        local adminCmdBox = TextBox(adminRemoteSection, { placeholder = "Command: fly / noclip / ban ... (empty = raw fire)" })
        Button(adminRemoteSection, "Fire to troll target", function()
            local t = TrollGetTarget()
            if not t then
                notif("Set a troll target first", 2)
                return
            end
            local cmd = adminCmdBox.Text ~= "" and adminCmdBox.Text or nil
            local fired = FakeAdminCommand(cmd, t.Name)
            notif(cmd and ("Fired '" .. cmd .. "' at " .. t.Name .. " (" .. fired .. " ok)") or ("Raw fire at " .. t.Name .. " (" .. fired .. " ok)"), 3)
        end)
        Note(adminRemoteSection, "Sends the command through every admin-looking remote it finds")

        local ghostSection = Section(ContentScroll, "Ghost & Tools", "")
        ToggleRow(ghostSection, {
            text = "Ghost Mode", id = "ghost", state = TrollCfg.invis,
            desc = "Client-side invisibility for your character",
            onToggle = function(val)
                if val then TrollInvisStart() else TrollInvisStop() end
            end
        })
        ToggleRow(ghostSection, {
            text = "Sneaky Seat", id = "sneakyseat", state = TrollCfg.sneakySeat,
            desc = "Invisible seat - hidden while seated",
            onToggle = function(val)
                if val then TrollSneakySeatStart() else TrollSneakySeatStop() end
            end
        })
        ToggleRow(ghostSection, {
            text = "Click TP Tool", id = "clicktp", state = TrollCfg.clickTP,
            desc = "Click any player to teleport to them",
            onToggle = function(val)
                if val then TrollClickTPStart() else TrollClickTPStop() end
            end
        })
        Button(ghostSection, "Bring Target", function()
            local t = TrollGetTarget()
            if t then
                StartBring(t.Name)
            else
                notif("Set a troll target first", 2)
            end
        end)

        local screenSection = Section(ContentScroll, "Screen Chaos", "")
        ToggleRow(screenSection, {
            text = "Blur Pulse", id = "blurfx", state = ScreenFx.blurOn,
            desc = "Extreme pulsing blur",
            onToggle = function(val) SfxSet("blurOn", val) end
        })
        ToggleRow(screenSection, {
            text = "FOV Pulse", id = "fovfx", state = ScreenFx.fovOn,
            desc = "Camera zoom in/out heartbeat",
            onToggle = function(val) SfxSet("fovOn", val) end
        })
        ToggleRow(screenSection, {
            text = "Rainbow Screen", id = "rainbowfx", state = ScreenFx.rainbowOn,
            desc = "Spinning rainbow overlay",
            onToggle = function(val) SfxSet("rainbowOn", val) end
        })
        ToggleRow(screenSection, {
            text = "Screen Shake", id = "shakefx", state = ScreenFx.shakeOn,
            desc = "Constant camera shaking",
            onToggle = function(val) SfxSet("shakeOn", val) end
        })
        Button(screenSection, "JUMPSCARE!", JumpScareBurst)

        local audioSection = Section(ContentScroll, "Earrape Audio", "")
        local earrapeDD = Dropdown(audioSection, {
            text = "Sound",
            options = (function()
                local out = {}
                for i, s in ipairs(TROLL_SOUNDS) do
                    table.insert(out, { text = s.name, value = i })
                end
                return out
            end)(),
            default = TrollCfg.earrapeChoice,
            onChanged = function(_, idx)
                TrollCfg.earrapeChoice = idx
                if TrollCfg.earrape then
                    TrollEarrapeStop()
                    TrollEarrapeStart()
                end
            end
        })
        ToggleRow(audioSection, {
            text = "Earrape Loop", id = "earrape", state = TrollCfg.earrape,
            desc = "MAX-VOLUME local sound spam with random pitch",
            onToggle = function(val)
                if val then TrollEarrapeStart() else TrollEarrapeStop() end
            end
        })
        Slider(audioSection, {
            text = "Volume", min = 1, max = 10, def = TrollCfg.earrapeVolume,
            onChanged = function(val)
                TrollCfg.earrapeVolume = val
                if TrollState.earrapeSound then
                    pcall(function() TrollState.earrapeSound.Volume = val end)
                end
            end
        })
        Note(audioSection, "All effects are client-side & local (FE-safe)")

    -- a-a-a-a-a-a-a-a-a-a-a- BAN a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildBanTab()
        local banSection = Section(ContentScroll, "Ban Manager", "hammer")
        Button(banSection, "Fetch ban list", FetchBanList)
        Button(banSection, "Unban all (list)", UnbanAllFromList)
        Button(banSection, "Scan storage", StorageScan)
        Button(banSection, "Blast unban (all remotes)", BlastUnban)
        banBox = TextBox(banSection, { placeholder = "Unban by name / ID" })
        Button(banSection, "Unban this", function() DoUnban(banBox.Text) end)
        ToggleRow(banSection, {
            text = "Auto-unban on join", id = "autounban", state = autoUnbanOn,
            keybind = false,
            onToggle = function(val) autoUnbanOn = val end
        })
        ToggleRow(banSection, {
            text = "Auto rejoin on kick", id = "autorejoin", state = autoRejoinOn,
            keybind = false,
            onToggle = function(val) autoRejoinOn = val end
        })
        customBox = TextBox(banSection, { placeholder = "Fire custom: RemoteName,arg1,arg2" })
        Button(banSection, "Fire custom remote", FireCustomRemote)

        banListContainer = Section(ContentScroll, "Banned players", "")
        if #bannedCache > 0 then
            for _, name in ipairs(bannedCache) do
                Button(banListContainer, name, function() DoUnban(name) end)
            end
        else
            Label(banListContainer, "List empty - press Fetch", UITheme.DIM, 11)
        end
        if #storageDump > 0 then
            local storageSection = Section(ContentScroll, "Storage scan", "")
            for _, line in ipairs(storageDump) do
                Label(storageSection, line, UITheme.SUBTEXT, 10)
            end
        end
        Note(ContentScroll, "You must be inside the server to fire bans (rejoin before kick)")

    -- a-a-a-a-a-a-a-a-a-a-a- TSUNAMI a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildTsunamiTab()
        local popcornMain = Section(ContentScroll, "Popcorn Burst", "flame")
        local stLabel = Label(popcornMain, "Minigame: OFF", UITheme.CYAN, 12)
        PopcornBurstAPI.SetStatusLabel(stLabel)
        PopcornBurstAPI.UpdateStatus()
        ToggleRow(popcornMain, {
            text = "Play Popcorn Burst", id = "popcorn", state = PopcornBurstAPI.IsActive(),
            keybind = false,
            onToggle = function(val)
                local ok, err = pcall((val and PopcornBurstAPI.Start or PopcornBurstAPI.Stop))
                if not ok then
                    notif("Error: " .. tostring(err), 6)
                end
            end
        })
        Note(popcornMain, "3D table builds in-world - walk to it and press E to sit")
        Note(popcornMain, "Click kernels when the ring meets the target: Perfect +100 | Great +50 | Good +20")
        Note(popcornMain, "1v1 vs Brainrot Bot - +10 win / +2 lose / +5 tie Tokens")

        local legacySection = Section(ContentScroll, "Legacy auto-helpers", "")
        local tsStatusLabel = Label(legacySection, "All OFF", UITheme.SUBTEXT, 11)
        tsunamiStatusLabel = tsStatusLabel
        pcall(RebuildTsunami)
        local function TsSet(field, val)
            tsunamiCfg[field] = val
            pcall(RebuildTsunami)
        end
        ToggleRow(legacySection, {
            text = "Auto Collect", id = "tscollect", state = tsunamiCfg.on,
            desc = "TPs to the nearest coin/cash/loot part",
            keybind = false,
            onToggle = function(val) TsSet("on", val) end
        })
        ToggleRow(legacySection, {
            text = "Auto Clicker", id = "tsclicker", state = tsunamiCfg.clicker,
            desc = "Clicks non-stop at the mouse position",
            keybind = false,
            onToggle = function(val) TsSet("clicker", val) end
        })
        ToggleRow(legacySection, {
            text = "Popcorn auto-click (GUI)", id = "tspopcorn", state = tsunamiCfg.popcorn,
            desc = "Spam-clicks green circle/ring UI elements",
            keybind = false,
            onToggle = function(val) TsSet("popcorn", val) end
        })
        ToggleRow(legacySection, {
            text = "God Mode", id = "tsgod", state = tsunamiCfg.god,
            desc = "Keeps your health & stamina full",
            keybind = false,
            onToggle = function(val) TsSet("god", val) end
        })
        ToggleRow(legacySection, {
            text = "Auto Jump", id = "tsjump", state = tsunamiCfg.autojump,
            desc = "Jumps every 0.6s",
            keybind = false,
            onToggle = function(val) TsSet("autojump", val) end
        })
        ToggleRow(legacySection, {
            text = "Safe TP", id = "tssafe", state = tsunamiCfg.safe,
            desc = "Teleports you to a safe spot every 2s",
            keybind = false,
            onToggle = function(val) TsSet("safe", val) end
        })
        ToggleRow(legacySection, {
            text = "Minigame Bot", id = "tsmg", state = tsunamiCfg.mgBot,
            desc = "Clicks fish/cast/reel/play buttons automatically",
            keybind = false,
            onToggle = function(val) TsSet("mgBot", val) end
        })
        ToggleRow(legacySection, {
            text = "C4 Clicker", id = "tsc4", state = tsunamiCfg.c4,
            desc = "Actives col/cell/slot/connect buttons",
            keybind = false,
            onToggle = function(val) TsSet("c4", val) end
        })
        Slider(legacySection, {
            text = "Collect delay", min = 5, max = 100, def = 35,
            onChanged = function(val) tsunamiCfg.collectDelay = val / 100 end
        })
        Slider(legacySection, {
            text = "Popcorn cooldown", min = 5, max = 100, def = 35,
            onChanged = function(val) tsunamiCfg.popCooldown = val / 100 end
        })
        Slider(legacySection, {
            text = "Safe TP delay", min = 50, max = 500, def = 200,
            onChanged = function(val) tsunamiCfg.safeDelay = val / 100 end
        })
        Slider(legacySection, {
            text = "Minigame bot delay", min = 20, max = 300, def = 80,
            onChanged = function(val) tsunamiCfg.mgBotDelay = val / 100 end
        })
        Slider(legacySection, {
            text = "C4 delay", min = 20, max = 300, def = 120,
            onChanged = function(val) tsunamiCfg.c4Delay = val / 100 end
        })
        Slider(legacySection, {
            text = "C4 column (0 = random)", min = 0, max = 7, def = 0,
            onChanged = function(val) tsunamiCfg.c4Col = val end
        })
        Button(legacySection, "Stop all helpers", function()
            tsunamiCfg.on = false
            tsunamiCfg.clicker = false
            tsunamiCfg.popcorn = false
            tsunamiCfg.god = false
            tsunamiCfg.autojump = false
            tsunamiCfg.safe = false
            tsunamiCfg.mgBot = false
            tsunamiCfg.c4 = false
            pcall(RebuildTsunami)
            notif("Tsunami helpers stopped", 2)
        end)
        Note(legacySection, "Generic auto-clickers - work in any game with GUI buttons. Status refreshes every second.")

    -- a-a-a-a-a-a-a-a-a-a-a- EXTRAS a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildExtrasTab()
        local scriptsSection = Section(ContentScroll, "External scripts", "code")
        local addRow = Instance.new("Frame")
        addRow.Parent = scriptsSection
        addRow.BackgroundTransparency = 1
        addRow.Size = UDim2.new(1, 0, 0, 32)
        local addLay = Instance.new("UIListLayout", addRow)
        addLay.FillDirection = Enum.FillDirection.Horizontal
        addLay.Padding = UDim.new(0, 4)
        local nameBox = Instance.new("TextBox")
        nameBox.Parent = addRow
        nameBox.Size = UDim2.new(0.33, -4, 1, 0)
        nameBox.BackgroundColor3 = UITheme.ELEMENT
        nameBox.BackgroundTransparency = 0.4
        nameBox.BorderSizePixel = 0
        nameBox.Font = Enum.Font.Gotham
        nameBox.PlaceholderText = "Name"
        nameBox.PlaceholderColor3 = UITheme.DIM
        nameBox.Text = ""
        nameBox.TextColor3 = UITheme.TEXT
        nameBox.TextSize = 11
        nameBox.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 6)
        local urlBox = Instance.new("TextBox")
        urlBox.Parent = addRow
        urlBox.Size = UDim2.new(0.52, -4, 1, 0)
        urlBox.BackgroundColor3 = UITheme.ELEMENT
        urlBox.BackgroundTransparency = 0.4
        urlBox.BorderSizePixel = 0
        urlBox.Font = Enum.Font.Gotham
        urlBox.PlaceholderText = "URL or code"
        urlBox.PlaceholderColor3 = UITheme.DIM
        urlBox.Text = ""
        urlBox.TextColor3 = UITheme.TEXT
        urlBox.TextSize = 11
        urlBox.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", urlBox).CornerRadius = UDim.new(0, 6)
        Button(addRow, { text = "+", size = UDim2.new(0.13, -4, 1, 0), callback = function()
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
        end })

        for _, scriptData in ipairs(more_scripts) do
            Button(scriptsSection, scriptData.name, function()
                notif("Loading: " .. scriptData.name, 2)
                local success, err = pcall(function()
                    local func = loadstring(scriptData.script)
                    if func then func() else notif("Load failed", 3) end
                end)
                if not success and err then
                    notif("Error: " .. tostring(err), 3)
                end
            end)
        end

        if #userScripts > 0 then
            local userSection = Section(ContentScroll, "Your scripts", "")
            for i, scriptData in ipairs(userScripts) do
                local frameRow = Instance.new("Frame")
                frameRow.Parent = userSection
                frameRow.BackgroundTransparency = 1
                frameRow.Size = UDim2.new(1, 0, 0, 32)
                local sLay = Instance.new("UIListLayout", frameRow)
                sLay.FillDirection = Enum.FillDirection.Horizontal
                sLay.Padding = UDim.new(0, 6)
                Button(frameRow, { text = scriptData.name, size = UDim2.new(0.8, 0, 1, 0), callback = function()
                    notif("Loading: " .. scriptData.name, 2)
                    local success, err = pcall(function()
                        local func = loadstring(scriptData.script)
                        if func then func() else notif("Load failed", 3) end
                    end)
                    if not success and err then notif("Error: " .. tostring(err), 3) end
                end })
                Button(frameRow, { text = "Delete", size = UDim2.new(0.18, 0, 1, 0), callback = function()
                    RemoveUserScript(i)
                end })
            end
        end

    -- a-a-a-a-a-a-a-a-a-a-a- SETTINGS a-a-a-a-a-a-a-a-a-a-a-
    end

    local function BuildSettingsTab()
        local keySection = Section(ContentScroll, "Keybinds", "key")
        Note(keySection, "Click a chip to set a keybind. Backspace/Delete = clear.")
        ToggleRow(keySection, {
            text = "Hide / Unhide Menu", id = "menu", state = true,
            desc = "Press your keybind to toggle menu visibility",
            keybind = true,
            onToggle = function(val)
                Window.Visible = val
            end
        })
        Button(keySection, "Reset ALL keybinds", function()
            KeybindsLib:ResetAll()
            notif("All keybinds cleared", 2)
        end)

        local themeSection = Section(ContentScroll, "Theme", "")
        ToggleRow(themeSection, {
            text = "RGB Mode", id = "rgb", state = UITheme.RGB,
            keybind = false,
            onToggle = function(val)
                UITheme.RGB = val
                rgbQuick.Text = "RGB Mode: " .. (val and "ON" or "OFF")
                rgbQuick.TextColor3 = val and UITheme.Accent or UITheme.SUBTEXT
                if not val then
                    UITheme.Accent = UITheme.CYAN
                    UITheme:ApplyAccent()
                end
            end
        })

        local configSection = Section(ContentScroll, "Configs", "save")
        local configNameBox = TextBox(configSection, { placeholder = "Config name", initial = "Default" })
        local configRow = Instance.new("Frame")
        configRow.Parent = configSection
        configRow.BackgroundTransparency = 1
        configRow.Size = UDim2.new(1, 0, 0, 34)
        local cfgLay = Instance.new("UIListLayout", configRow)
        cfgLay.FillDirection = Enum.FillDirection.Horizontal
        cfgLay.Padding = UDim.new(0, 6)
        local function cfgName()
            local n = configNameBox.Text
            if n == "" then n = "Default" end
            return n
        end
        Button(configRow, { text = "Save", size = UDim2.new(0.32, -4, 1, 0), callback = function() SaveConfig(cfgName()) end })
        Button(configRow, { text = "Load", size = UDim2.new(0.32, -4, 1, 0), callback = function()
            LoadConfig(cfgName())
            KeybindsLib:Restore(settings.keybinds)
            UpdateRightContent()
        end })
        Button(configRow, { text = "Delete", size = UDim2.new(0.32, -4, 1, 0), callback = function() DeleteConfig(cfgName()) end })

        local configListSection = Section(ContentScroll, "Saved configs", "")
        local configsList = GetConfigList()
        if #configsList > 0 then
            for _, name in ipairs(configsList) do
                Button(configListSection, name, function()
                    configNameBox.Text = name
                    LoadConfig(name)
                    KeybindsLib:Restore(settings.keybinds)
                    UpdateRightContent()
                end)
            end
        else
            Label(configListSection, "No saved configs", UITheme.SUBTEXT, 11)
        end

        local unbanSection = Section(ContentScroll, "Account", "")
        Button(unbanSection, "Try Unban", TryUnban)
        Button(unbanSection, "Rejoin fresh", RejoinFresh)
        Note(unbanSection, "Only works vs remote-based bans")

        local otherSection = Section(ContentScroll, "Other", "")
        ToggleRow(otherSection, {
            text = "Anti-AFK", id = "antiafk", state = settings.AntiAFK,
            onToggle = function(val)
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
            end
        })
        Button(otherSection, "Mic Bypass", ToggleMicBypass)
        Button(otherSection, "Unmute mic", UnmuteMic)

        local footer = Instance.new("Frame")
        footer.Parent = ContentScroll
        footer.BackgroundTransparency = 1
        footer.Size = UDim2.new(1, 0, 0, 60)
        footer.LayoutOrder = 999999
        Label(footer, "Supports STK v2.31.0  |  sa7loul V3 Premium", UITheme.SUBTEXT, 11)
        Label(footer, "Keep it cute, keep it clean -", UITheme.CYAN, 11)
    end

local function SafeBuild(name, fn)
        Dbg("BUILD_START", name)
        local ok, err = pcall(fn)
        if not ok then
            Dbg("BUILD_ERROR", name .. " " .. tostring(err))
            pcall(function() writefile("sa7loul_Debug.txt", table.concat(dbgLog, "\n")) end)
            warn("[sa7loul] build error in " .. name .. ": " .. tostring(err))
            notif("UI error [" .. name .. "]: " .. tostring(err), 10)
            pcall(function()
                local errBox = Instance.new("TextLabel")
                errBox.Name = "BuildErrorBox"
                errBox.Parent = ContentScroll
                errBox.BackgroundColor3 = Color3.fromRGB(70, 18, 30)
                errBox.BackgroundTransparency = 0.2
                errBox.BorderSizePixel = 0
                errBox.Size = UDim2.new(1, -20, 0, 90)
                errBox.Position = UDim2.new(0, 10, 0, 10)
                errBox.ZIndex = 99
                errBox.TextWrapped = true
                errBox.TextXAlignment = Enum.TextXAlignment.Left
                errBox.TextYAlignment = Enum.TextYAlignment.Top
                errBox.Text = "BUILD ERROR [" .. name .. "]: " .. tostring(err)
                errBox.TextColor3 = Color3.fromRGB(255, 130, 130)
                errBox.TextSize = 12
                errBox.Font = Enum.Font.GothamBold
            end)
        else
            Dbg("BUILD_END", name)
        end
    end

    if CurrentTab == "Home" then SafeBuild("Home", BuildHomeTab)
    elseif CurrentTab == "Player" then SafeBuild("Player", BuildPlayerTab)
    elseif CurrentTab == "World" then SafeBuild("World", BuildWorldTab)
    elseif CurrentTab == "Players" then SafeBuild("Players", BuildPlayersTab)
    elseif CurrentTab == "Revive" then SafeBuild("Revive", BuildReviveTab)
    elseif CurrentTab == "Fun" then SafeBuild("Fun", BuildFunTab)
    elseif CurrentTab == "Spawner" then SafeBuild("Spawner", BuildSpawnerTab)
    elseif CurrentTab == "Troll" then SafeBuild("Troll", BuildTrollTab)
    elseif CurrentTab == "Ban" then SafeBuild("Ban", BuildBanTab)
    elseif CurrentTab == "Tsunami" then SafeBuild("Tsunami", BuildTsunamiTab)
    elseif CurrentTab == "Extras" then SafeBuild("Extras", BuildExtrasTab)
    elseif CurrentTab == "Settings" then SafeBuild("Settings", BuildSettingsTab)
    end
end

local function InitTail()
local initErrors = {}
local function TryInit(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        table.insert(initErrors, name .. ": " .. tostring(err))
        warn("[sa7loul] " .. name .. " failed:", err)
    end
    return ok
end
BuildSidebar()
CurrentTab = "Home"
TryInit("RefreshTabVisuals", RefreshTabVisuals)
TryInit("UpdateRightContent", UpdateRightContent)
if #initErrors > 0 then
    local dbg = Instance.new("TextLabel")
    dbg.Parent = Window
    dbg.BackgroundColor3 = Color3.fromRGB(20, 10, 14)
    dbg.BackgroundTransparency = 0.1
    dbg.BorderSizePixel = 0
    dbg.Position = UDim2.new(0, 12, 1, -64)
    dbg.Size = UDim2.new(1, -24, 0, 54)
    dbg.ZIndex = 60
    dbg.TextColor3 = Color3.fromRGB(255, 120, 120)
    dbg.TextSize = 10
    dbg.TextWrapped = true
    dbg.Text = "sa7loul init error: " .. table.concat(initErrors, "  |  ")
end

-- click-TP dispatcher + popcorn burst clicks
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.E and PopcornBurstAPI.active then
            PopcornBurstAPI.TrySit()
        end
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if PopcornBurstAPI.active then
            local cam = workspace.CurrentCamera
            local m = UserInputService:GetMouseLocation()
            if cam then
                local ray = cam:ViewportPointToRay(m.X, m.Y)
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                local chr = lp.Character
                if chr then params.FilterDescendantsInstances = { chr } end
                params.RespectCanCollide = false
                local res = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
                if res and PopcornBurstAPI.TryHit(res.Instance) then
                    return
                end
            end
        end
        if TrollCfg.clickTP then
            TrollClickTPFire()
        end
    end
end)

-- click-to-bind chips already handled inside KeybindsLib; dispatch there too.
-- (single InputBegan used by the keybind manager)

-- players
PlayersSvc.PlayerAdded:Connect(function()
    task.wait(0.3)
    if CurrentTab == "Players" then UpdatePlayerList() end
    if CurrentTab == "Spawner" or CurrentTab == "Fun" then pcall(UpdateRightContent) end
    RefreshTrollTargetOptions()
end)
PlayersSvc.PlayerRemoving:Connect(function(player)
    task.wait(0.3)
    if CurrentTab == "Players" then UpdatePlayerList() end
    if CurrentTab == "Spawner" or CurrentTab == "Fun" then pcall(UpdateRightContent) end
    if TrollTargetSel == player then
        TrollTargetSel = nil
        RefreshTrollTargetOptions()
    end
    if autoRejoinOn and player == lp then
        task.spawn(function()
            task.wait(2)
            RejoinFresh()
        end)
    end
end)

if lp then
lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if settings.speedEnabled and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = settings.Speed
    end
    espCache = {}
    UpdateESP()
    UpdateDoubleJump()
    UpdateKillerChance()
    if TrollCfg.sneakySeat then
        task.wait(0.5)
        TrollSneakySeatStart()
    end
    if CurrentTab == "Players" then
        task.wait(0.5)
        UpdatePlayerList()
    end
end)
end

-- periodic updates (speed enforcement etc.)
RunService.Stepped:Connect(PeriodicUpdates)

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

-- RGB tick
RunService.RenderStepped:Connect(function(dt)
    RefreshLP()
    UITheme:Tick(dt)
end)

-- keybinds: restore from disk / config, then default menu key
KeybindsLoadFromDisk()
if not KeybindsLib.map.menu or not KeybindsLib.map.menu.key then
    KeybindsLib:Bind("menu", Enum.KeyCode.RightShift)
end

-- auto unban race (kept from V2)
task.spawn(function()
    if not autoUnbanOn then return end
    task.wait(2)
    pcall(TryUnban)
    local vc = game:GetService("VoiceChatService")
    for i = 1, 5 do
        pcall(function() vc:joinVoice() end)
        task.wait(0.5)
    end
end)

pcall(UpdateNoFog)
pcall(UpdateESP)
pcall(UpdateESPExits)
pcall(UpdateESPTraps)
pcall(UpdateDoubleJump)
pcall(UpdateKillerChance)
pcall(UpdateAllFeatures)

notif("sa7loul V3 Premium loaded | RightShift hides menu", 4)
end
InitTail()
