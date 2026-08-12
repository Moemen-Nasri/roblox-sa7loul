-- ULTRA MINIMAL TEST
print("=== SA7LOUL SCRIPT START ===")

local player = game:GetService("Players").LocalPlayer
print("Player found:", player.Name)

local playerGui = player:WaitForChild("PlayerGui")
print("PlayerGui found")

local gui = Instance.new("ScreenGui")
gui.Name = "TestGui"
gui.Parent = playerGui
print("ScreenGui created and parented")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
frame.Parent = gui
print("Red frame created")

local text = Instance.new("TextLabel")
text.Size = UDim2.new(1, 0, 1, 0)
text.BackgroundTransparency = 1
text.Text = "TEST"
text.TextColor3 = Color3.fromRGB(255, 255, 255)
text.TextSize = 20
text.Parent = frame
print("Text label created")

print("=== SA7LOUL SCRIPT END ===")

-- Test notification
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Test",
        Text = "If you see this, script works!",
        Duration = 5
    })
end)

local configs = {
    savedConfigs = {},
    currentConfigName = "Default"
}

-- ============================================
-- SAHLOUL AUTH SYSTEM
-- ============================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local SaveFileName = "sahloul_auth_data.json"

local function SaveCredentials(data)
    local success = pcall(function()
        writefile(SaveFileName, HttpService:JSONEncode(data))
    end)
    return success
end

local function LoadCredentials()
    local success, data = pcall(function()
        if isfile(SaveFileName) then
            return HttpService:JSONDecode(readfile(SaveFileName))
        end
        return nil
    end)
    if success and data then
        return data
    end
    return nil
end

local function ClearCredentials()
    pcall(function()
        if isfile(SaveFileName) then
            delfile(SaveFileName)
        end
    end)
end



-- ============================================
-- STREAM PROOF SYSTEM (DISABLED BY DEFAULT)
-- ============================================

local StreamProof = {
    active = false,
    originalGuiEnabled = true,
    detectionMethods = {
        obs = false,
        nvidia = false,
        discord = false,
        generic = false
    },
    running = false
}

local function DetectOBS()
    return false -- Disabled by default
end

local function DetectNvidiaOverlay()
    return false -- Disabled by default
end

local function DetectDiscordStreaming()
    return false -- Disabled by default
end

local function DetectGenericRecording()
    return false -- Disabled by default
end

local function UpdateStreamDetection()
    StreamProof.detectionMethods.obs = DetectOBS()
    StreamProof.detectionMethods.nvidia = DetectNvidiaOverlay()
    StreamProof.detectionMethods.discord = DetectDiscordStreaming()
    StreamProof.detectionMethods.generic = DetectGenericRecording()
    
    local anyDetected = StreamProof.detectionMethods.obs or 
                        StreamProof.detectionMethods.nvidia or 
                        StreamProof.detectionMethods.discord or 
                        StreamProof.detection.generic
    
    return anyDetected
end

local function SetGuiVisibility(visible)
    if StreamProof.originalGuiEnabled ~= visible then
        StreamProof.originalGuiEnabled = visible
        
        local success = pcall(function()
            local coreGui = game:GetService("CoreGui")
            local mainGui = coreGui:FindFirstChild("sa7loul_V3")
            if mainGui then
                mainGui.Enabled = visible
            end
        end)
    end
end

local function StartStreamProofDetection()
    if StreamProof.running then return end
    StreamProof.running = true
    
    spawn(function()
        while StreamProof.running do
            local detected = UpdateStreamDetection()
            
            if detected and StreamProof.originalGuiEnabled then
                SetGuiVisibility(false)
                notif("Stream Proof: GUI Hidden", 2)
            elseif not detected and not StreamProof.originalGuiEnabled then
                SetGuiVisibility(true)
                notif("Stream Proof: GUI Visible", 2)
            end
            
            wait(2)
        end
    end)
end

local function StopStreamProofDetection()
    StreamProof.running = false
end

local function ToggleStreamProof()
    StreamProof.active = not StreamProof.active
    settings.StreamProof = StreamProof.active
    
    if StreamProof.active then
        StartStreamProofDetection()
        notif("Stream Proof: Enabled", 2)
    else
        StopStreamProofDetection()
        SetGuiVisibility(true)
        notif("Stream Proof: Disabled", 2)
    end
    return StreamProof.active
end

-- ============================================
-- LOGIN GUI SYSTEM
-- ============================================

local LoginGui = {
    screenGui = nil,
    mainFrame = nil,
    authenticated = false,
    session = nil
}

local function CreateLoginGui()
    local CoreGui = game:GetService("CoreGui")
    
    -- Remove existing login GUI if present
    local existingGui = CoreGui:FindFirstChild("SahloulAuthGUI")
    if existingGui then
        existingGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SahloulAuthGUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = CoreGui
    
    -- Main Container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 15)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "sa7loul Auth"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    -- License Input
    local licenseLabel = Instance.new("TextLabel")
    licenseLabel.Name = "LicenseLabel"
    licenseLabel.Size = UDim2.new(1, -40, 0, 25)
    licenseLabel.Position = UDim2.new(0, 20, 0, 80)
    licenseLabel.BackgroundTransparency = 1
    licenseLabel.Text = "License Key"
    licenseLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    licenseLabel.TextSize = 14
    licenseLabel.Font = Enum.Font.Gotham
    licenseLabel.TextXAlignment = Enum.TextXAlignment.Left
    licenseLabel.Parent = mainFrame
    
    local licenseBox = Instance.new("TextBox")
    licenseBox.Name = "LicenseBox"
    licenseBox.Size = UDim2.new(1, -40, 0, 40)
    licenseBox.Position = UDim2.new(0, 20, 0, 105)
    licenseBox.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    licenseBox.BorderSizePixel = 0
    licenseBox.Text = ""
    licenseBox.PlaceholderText = "XXXX-XXXX-XXXX-XXXX"
    licenseBox.PlaceholderColor3 = Color3.fromRGB(95, 98, 125)
    licenseBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    licenseBox.TextSize = 16
    licenseBox.Font = Enum.Font.Gotham
    licenseBox.Parent = mainFrame
    
    local licenseCorner = Instance.new("UICorner")
    licenseCorner.CornerRadius = UDim.new(0, 8)
    licenseCorner.Parent = licenseBox
    
    local licensePadding = Instance.new("UIPadding")
    licensePadding.PaddingLeft = UDim.new(0, 15)
    licensePadding.PaddingRight = UDim.new(0, 15)
    licensePadding.Parent = licenseBox
    
    -- Remember Me
    local rememberContainer = Instance.new("Frame")
    rememberContainer.Name = "RememberContainer"
    rememberContainer.Size = UDim2.new(1, -40, 0, 25)
    rememberContainer.Position = UDim2.new(0, 20, 0, 155)
    rememberContainer.BackgroundTransparency = 1
    rememberContainer.Parent = mainFrame
    
    local rememberButton = Instance.new("TextButton")
    rememberButton.Name = "RememberButton"
    rememberButton.Size = UDim2.new(0, 20, 0, 20)
    rememberButton.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    rememberButton.BorderSizePixel = 0
    rememberButton.Text = ""
    rememberButton.Parent = rememberContainer
    
    local rememberCorner = Instance.new("UICorner")
    rememberCorner.CornerRadius = UDim.new(0, 4)
    rememberCorner.Parent = rememberButton
    
    local rememberCheck = Instance.new("Frame")
    rememberCheck.Name = "RememberCheck"
    rememberCheck.Size = UDim2.new(0, 12, 0, 12)
    rememberCheck.Position = UDim2.new(0, 4, 0, 4)
    rememberCheck.BackgroundColor3 = Color3.fromRGB(61, 224, 200)
    rememberCheck.BorderSizePixel = 0
    rememberCheck.Visible = false
    rememberCheck.Parent = rememberButton
    
    local rememberCheckCorner = Instance.new("UICorner")
    rememberCheckCorner.CornerRadius = UDim.new(0, 2)
    rememberCheckCorner.Parent = rememberCheck
    
    local rememberLabel = Instance.new("TextLabel")
    rememberLabel.Name = "RememberLabel"
    rememberLabel.Size = UDim2.new(1, -30, 1, 0)
    rememberLabel.Position = UDim2.new(0, 30, 0, 0)
    rememberLabel.BackgroundTransparency = 1
    rememberLabel.Text = "Remember me"
    rememberLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    rememberLabel.TextSize = 14
    rememberLabel.Font = Enum.Font.Gotham
    rememberLabel.TextXAlignment = Enum.TextXAlignment.Left
    rememberLabel.Parent = rememberContainer
    
    -- Login Button
    local loginButton = Instance.new("TextButton")
    loginButton.Name = "LoginButton"
    loginButton.Size = UDim2.new(1, -40, 0, 45)
    loginButton.Position = UDim2.new(0, 20, 0, 190)
    loginButton.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    loginButton.BorderSizePixel = 0
    loginButton.Text = "Login"
    loginButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    loginButton.TextSize = 18
    loginButton.Font = Enum.Font.GothamBold
    loginButton.Parent = mainFrame
    
    local loginCorner = Instance.new("UICorner")
    loginCorner.CornerRadius = UDim.new(0, 10)
    loginCorner.Parent = loginButton
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -40, 0, 30)
    statusLabel.Position = UDim2.new(0, 20, 0, 245)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = mainFrame
    
    -- Stream Proof Toggle (disabled by default)
    local streamProofButton = Instance.new("TextButton")
    streamProofButton.Name = "StreamProofButton"
    streamProofButton.Size = UDim2.new(1, -40, 0, 35)
    streamProofButton.Position = UDim2.new(0, 20, 0, 290)
    streamProofButton.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    streamProofButton.BorderSizePixel = 0
    streamProofButton.Text = "Stream Proof: OFF"
    streamProofButton.TextColor3 = Color3.fromRGB(150, 150, 170)
    streamProofButton.TextSize = 14
    streamProofButton.Font = Enum.Font.Gotham
    streamProofButton.Parent = mainFrame
    
    local streamProofCorner = Instance.new("UICorner")
    streamProofCorner.CornerRadius = UDim.new(0, 8)
    streamProofCorner.Parent = streamProofButton
    
    LoginGui.screenGui = screenGui
    LoginGui.mainFrame = mainFrame
    
    -- Force the GUI to be visible
    screenGui.Enabled = true
    mainFrame.Visible = true
    
    -- Wait a moment and ensure visibility
    spawn(function()
        wait(0.1)
        if screenGui and screenGui.Parent then
            screenGui.Enabled = true
        end
        if mainFrame and mainFrame.Parent then
            mainFrame.Visible = true
        end
    end)
    
    -- Load saved credentials
    local savedCredentials = LoadCredentials()
    local rememberMe = false
    
    if savedCredentials then
        licenseBox.Text = savedCredentials.license or ""
        rememberMe = savedCredentials.rememberMe or false
        rememberCheck.Visible = rememberMe
        if rememberMe then
            rememberButton.BackgroundColor3 = Color3.fromRGB(61, 224, 200)
        end
        
        -- Load stream proof state (but keep it disabled by default)
        if savedCredentials.streamProof ~= nil then
            StreamProof.active = false -- Always start disabled
            settings.StreamProof = false
        end
    end
    
    -- Remember me toggle
    rememberButton.MouseButton1Click:Connect(function()
        rememberMe = not rememberMe
        rememberCheck.Visible = rememberMe
        
        if rememberMe then
            TweenService:Create(rememberButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(61, 224, 200)}):Play()
        else
            TweenService:Create(rememberButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 50)}):Play()
        end
    end)
    
    -- Stream proof toggle
    streamProofButton.MouseButton1Click:Connect(function()
        local isActive = ToggleStreamProof()
        if isActive then
            streamProofButton.Text = "Stream Proof: ON"
            streamProofButton.TextColor3 = Color3.fromRGB(76, 175, 80)
            streamProofButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        else
            streamProofButton.Text = "Stream Proof: OFF"
            streamProofButton.TextColor3 = Color3.fromRGB(150, 150, 170)
            streamProofButton.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        end
    end)
    
    -- Initialize stream proof button state (disabled by default)
    if StreamProof.active then
        streamProofButton.Text = "Stream Proof: ON"
        streamProofButton.TextColor3 = Color3.fromRGB(76, 175, 80)
        streamProofButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    end
    
    -- Login button
    loginButton.MouseButton1Click:Connect(function()
        local license = licenseBox.Text
        
        if license == "" then
            statusLabel.Text = "Error: Please enter a license key"
            statusLabel.TextColor3 = Color3.fromRGB(244, 67, 54)
            return
        end
        
        statusLabel.Text = "Loading..."
        statusLabel.TextColor3 = Color3.fromRGB(61, 224, 200)
        
        -- Real Sahloul Auth integration
        spawn(function()
            local APP_NAME = "s7roblox"
            local APP_SECRET = "5UQZZajX4YOrEnjTS9GwHKFNhM7rQ7tQ"
            
            -- Generate HWID
            local hwid = game:GetService("Players").LocalPlayer.UserId .. "_" .. tick()
            
            -- Make HTTP request to Sahloul Auth API
            local success, result = pcall(function()
                local url = "https://auth.sahloul.dev/api/v1/liclogin"
                local data = {
                    appname = APP_NAME,
                    license = license,
                    hwid = hwid
                }
                
                -- Try multiple methods for HTTP request
                local response = nil
                
                -- Method 1: HttpService:RequestAsync
                local method1Success = pcall(function()
                    response = HttpService:RequestAsync({
                        Url = url,
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json",
                            ["X-Sahloul-App"] = APP_NAME,
                            ["X-Sahloul-Secret"] = APP_SECRET
                        },
                        Body = HttpService:JSONEncode(data)
                    })
                end)
                
                -- Method 2: game:HttpPost (fallback)
                if not method1Success or not response then
                    local method2Success = pcall(function()
                        local body = game:HttpPost(url, HttpService:JSONEncode(data), false, {
                            ["Content-Type"] = "application/json",
                            ["X-Sahloul-App"] = APP_NAME,
                            ["X-Sahloul-Secret"] = APP_SECRET
                        })
                        if body then
                            response = {Success = true, Body = body}
                        end
                    end)
                end
                
                -- Method 3: Fallback to license format validation if HTTP fails
                if not response or not response.Success then
                    -- Fallback: Accept any valid license format for testing
                    if license:match("^%w%w%w%w%-%w%w%w%w%-%w%w%w%w%-%w%w%w%w$") then
                        return {license = license, username = "User", fallback = true}
                    else
                        return nil, "Invalid license format (fallback mode)"
                    end
                end
                
                if response and response.Success then
                    local decodeSuccess, responseData = pcall(function()
                        return HttpService:JSONDecode(response.Body)
                    end)
                    
                    if decodeSuccess and responseData then
                        if responseData.success then
                            return responseData.data
                        else
                            return nil, responseData.message or "Authentication failed"
                        end
                    else
                        return nil, "Invalid response format"
                    end
                else
                    return nil, "Network error: " .. (response and response.StatusCode or "connection failed")
                end
            end)
            
            if success and result then
                LoginGui.authenticated = true
                LoginGui.session = result
                
                -- Save credentials if remember me is enabled
                if rememberMe then
                    SaveCredentials({
                        license = license, 
                        rememberMe = true,
                        streamProof = StreamProof.active
                    })
                else
                    ClearCredentials()
                end
                
                statusLabel.Text = "Success! Welcome, " .. (result.username or "User")
                statusLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
                
                wait(1)
                
                -- Animate out and destroy
                mainFrame:TweenSize(UDim2.new(0, 400, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Back, 0.4, true, function()
                    screenGui:Destroy()
                    LoginGui.screenGui = nil
                    LoginGui.mainFrame = nil
                end)
            else
                local errorMsg = result or "Unknown error"
                statusLabel.Text = "Error: " .. errorMsg
                statusLabel.TextColor3 = Color3.fromRGB(244, 67, 54)
                
                -- Shake animation for error using TweenService
                local originalPos = mainFrame.Position
                local shakeLeft = TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = originalPos + UDim2.new(0, -10, 0, 0)})
                local shakeRight = TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = originalPos + UDim2.new(0, 10, 0, 0)})
                local shakeBack = TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = originalPos})
                
                shakeLeft:Play()
                shakeLeft.Completed:Connect(function()
                    shakeRight:Play()
                    shakeRight.Completed:Connect(function()
                        shakeBack:Play()
                    end)
                end)
            end
        end)
    end)
    
    -- Enter key support
    licenseBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            loginButton.MouseButton1Click:Fire()
        end
    end)
end

local function WaitForAuthentication()
    CreateLoginGui()
    
    -- Wait for authentication
    while not LoginGui.authenticated do
        if not LoginGui.screenGui or not LoginGui.screenGui.Parent then
            -- GUI was destroyed, recreate it
            CreateLoginGui()
        end
        wait(0.1)
    end
    
    -- Start stream proof if it was enabled (but keep it disabled by default)
    if StreamProof.active then
        StartStreamProofDetection()
    end
    
    return LoginGui.session
end

-- ============================================
-- AUTHENTICATION CHECK (TEMPORARY BYPASS FOR TESTING)
-- ============================================

print("Starting script...")
local session = {license = "test-0000-0000-0000", username = "TestUser"} 
print("Session created:", session.username)
-- local session = WaitForAuthentication() -- Disabled temporarily

local defaultSettings = {
    Speed = 16, 
    speedEnabled = false,
    speedDisableOnDown = true,
    Fly = false, 
    flySpeed = 50,
    flyVertical = 1,
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
    PanicTP = false,
    StreamProof = false
}

local userScripts = {}

function LoadUserScripts()
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile("sa7loul_Scripts.json"))
    end)
    if success and data then
        userScripts = data
    end
end

function SaveUserScripts()
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

-- DESIGN COLORS  soft rose & teal palette
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
            Title = " sa7loul V2",
            Text = str,
            Duration = dur or 3
        })
    end)
end

local settings = {}
for k, v in pairs(defaultSettings) do
    settings[k] = v
end

-- Initialize StreamProof from settings (disabled by default)
StreamProof.active = settings.StreamProof or false

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

local bringDistance = 4
local flingForce = 9999

function AddPressAnim(btn)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = btn.Size - UDim2.new(0.01, 0, 0.01, 0)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {Size = btn.Size + UDim2.new(0.01, 0, 0.01, 0)}):Play()
    end)
end

function GetSelectedPlayer()
    if selectedPlayer and selectedPlayer.Parent then return selectedPlayer end
    return nil
end

function SetSelectedPlayer(player)
    selectedPlayer = player
    if selectedPlayerLabel then
        if GetSelectedPlayer() then
            selectedPlayerLabel.Text = "Player: " .. selectedPlayer.Name
        else
            selectedPlayerLabel.Text = "Player: None"
        end
    end
end

function CyclePlayer()
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

function GetPlayerByName(name)
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

function IsPlayerDowned(player)
    if not player or not player.Character then return false end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local bleedOut = rootPart:FindFirstChild("BleedOutHealth")
    return bleedOut and bleedOut.Enabled
end

function IsPlayerInLobby(player)
    if not player or not player.Team then return false end
    return player.Team.Name:lower() == "lobby" or player.Team.TeamColor == BrickColor.new("White")
end

function IsSurvivor()
    if not lp.Team then return false end
    local teamName = lp.Team.Name:lower()
    if teamName == "lobby" or teamName == "spectator" or lp.Team.TeamColor == BrickColor.new("White") then
        return false
    end
    local isKiller = (lp.Team and lp.Team.TeamColor == BrickColor.new("Really red")) or false
    return not isKiller
end

function GetPlayerTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

function FindMap()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:FindFirstChild("LootSpawns") or child:FindFirstChild("ExitGateways") or child:FindFirstChild("Exits") then
            return child
        end
    end
    return nil
end

function StartBring(targetName)
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

function StopBring()
    bringActive = false
    notif("Bring stopped", 2)
end

function StartView(targetName)
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

function StopView()
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

function FreezePlayer(name)
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

function ThawPlayer(name)
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

function SetSettingsAttribute(name, value)
    if not lp then return end
    local settingsFolder = lp:FindFirstChild("Settings")
    if not settingsFolder then
        settingsFolder = Instance.new("Folder")
        settingsFolder.Name = "Settings"
        settingsFolder.Parent = lp
    end
    settingsFolder:SetAttribute(name, value)
end

function UpdateDoubleJump()
    SetSettingsAttribute("double_jump", settings.DoubleJump)
end

function UpdateKillerChance()
    SetSettingsAttribute("killer_chance_3x", settings.KillerChanceX3)
end

function UpdateFly()
    if settings.Fly then
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = RunService.RenderStepped:Connect(function()
            if not settings.Fly then return end
            local char = lp.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not root or not hum or hum.Health <= 0 then return end
            local bg = root:FindFirstChild("BodyGyro") or Instance.new("BodyGyro")
            local bv = root:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
            bg.P = 9e4; bg.Parent = root; bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = root.CFrame
            bv.Parent = root; bv.MaxForce = Vector3.new(9e9,9e9,9e9)
            hum.PlatformStand = true
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0,-1,0) end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            local cam = workspace.CurrentCamera
            bv.Velocity = (cam.CFrame.LookVector * moveDir.Z + cam.CFrame.RightVector * moveDir.X + cam.CFrame.UpVector * moveDir.Y * (settings.flyVertical or 1)) * settings.flySpeed
            bg.CFrame = cam.CFrame
        end)
    else
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local root = lp.Character.HumanoidRootPart
            local bg = root:FindFirstChild("BodyGyro"); if bg then bg:Destroy() end
            local bv = root:FindFirstChild("BodyVelocity"); if bv then bv:Destroy() end
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end
end

local function NoclipApply()
    local char = lp.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

local function NoclipEnable()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if settings.Noclip then NoclipApply() end
    end)
    NoclipApply()
end

local function NoclipDisable()
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
end

function UpdateNoclip()
    if settings.Noclip then NoclipEnable() else NoclipDisable() end
end

function UpdateESP()
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

function UpdateESPExits()
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

function UpdateESPTraps()
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

function RemoveTraps()
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

function TeleportToExit()
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

function CheckTimerColors()
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

function AutoEscapeLoop()
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

function CheckPanicTP()
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

function KillAuraLoop()
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

function StartBringAll()
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

function StopBringAll()
    bringAllActive = false
end

function UnbringPlayer(player)
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

function UnbringSelected()
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

function ScanAdminRemotes()
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

function TryFireAdminRemote(target)
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

function GiveFlyNoClip()
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

function ToggleMicBypass()
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
        notif(" Mic Bypass ON", 2)
    else
        notif("No character  enter a game first", 2)
    end
end

function UnmuteMic()
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

function ScanUnbanRemotes()
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

function TryUnban()
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

function RejoinFresh()
    notif("Rejoining...", 2)
    task.wait(0.5)
    local ok = pcall(function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end)
    if not ok then
        pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
    end
end

local bannedCache = {}
local banListContainer = nil
local storageDump = {}
local banBox = nil
local customBox = nil
local autoUnbanOn = true
local autoRejoinOn = false

function StorageScan()
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
                table.insert(storageDump, obj.ClassName .. " ' " .. obj.Name .. extra)
                count = count + 1
            end
        end
    end
    for _, obj in ipairs({game, lp}) do
        for k, v in pairs(obj:GetAttributes()) do
            if count < 150 then
                table.insert(storageDump, "Attr ' " .. tostring(k) .. " = " .. tostring(v))
                count = count + 1
            end
        end
    end
    notif("Storage scan: " .. #storageDump .. " entries", 2)
    if CurrentTab == "  Ban" then UpdateRightContent() end
end

function FireCustomRemote()
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

function BlastUnban()
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

function DoUnban(name)
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

function FetchBanList()
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
    if CurrentTab == "  Ban" then UpdateRightContent() end
end

function UnbanAllFromList()
    if #bannedCache == 0 then
        notif("Ban list empty  fetch first", 2)
        return
    end
    for _, name in ipairs(bannedCache) do
        DoUnban(name)
        task.wait(0.05)
    end
    notif("Unban fired for all " .. #bannedCache, 2)
end


function isKillerNearby(position, radius)
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

function AutoReviveLegitLoop()
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
        if wasNoclip then settings.Noclip = false; UpdateNoclip() end
        
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
        if wasNoclip then settings.Noclip = true; UpdateNoclip() end
        
        isReviving = false
    end
end

function AutoReviveRiskyOneUse()
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
        UpdateNoclip()
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
        UpdateNoclip()
    end
    
    isReviving = false
end

function AutoReviveSelfLoop()
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

function UpdateNoFog()
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

function AutoCollectLoot()
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

function ReturnToHome()
    if savedHomePosition and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = savedHomePosition
        savedHomePosition = nil
    end
end

function UpdateSpin(state)
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

function AddUserScript(name, script)
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

function RemoveUserScript(index)
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

function SafeLoadScript(scriptData)
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

function SaveConfig(name)
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

function LoadConfig(name)
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

function GetConfigList()
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

function DeleteConfig(name)
    local configsFolder = "sa7loul_Configs"
    if isfolder(configsFolder) then
        pcall(function()
            delfile(configsFolder .. "/" .. name .. ".json")
            notif("Config deleted: " .. name, 2)
        end)
    end
end

function UpdateAllFeatures()
    if settings.speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = settings.Speed
    end
    
    UpdateFly()
    UpdateNoclip()
    
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
function PeriodicUpdates()
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
function PeriodicESPUpdate()
    if tick() - lastESPUpdate >= 0.5 then
        lastESPUpdate = tick()
        UpdateESP()
        UpdateESPExits()
        UpdateESPTraps()
        UpdatePlayerList()
    end
end

-- =====================================================================
-- -----------------------------------------------------------------------
--  NOVA UI FRAMEWORK  sa7loul V3 PREMIUM REDESIGN
--  Dark mode + neon accents | RGB mode | rounded corners | glow
--  Draggable header | search | fluid tab navigation
-- -----------------------------------------------------------------------
local CoreGui    = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local PlayersSvc = game:GetService("Players")

--  THEME 
local UITheme = {
    BG        = Color3.fromRGB(7, 8, 13),
    BG_DEEP   = Color3.fromRGB(10, 12, 19),
    PANEL     = Color3.fromRGB(14, 16, 25),
    ELEMENT   = Color3.fromRGB(23, 26, 38),
    HOVER     = Color3.fromRGB(35, 39, 57),
    TEXT      = Color3.fromRGB(242, 245, 252),
    SUBTEXT   = Color3.fromRGB(150, 157, 182),
    DIM       = Color3.fromRGB(94, 100, 126),
    CYAN      = Color3.fromRGB(0, 229, 255),
    PURPLE    = Color3.fromRGB(132, 96, 255),
    GREEN     = Color3.fromRGB(64, 233, 142),
    RED       = Color3.fromRGB(255, 84, 108),
    AMBER     = Color3.fromRGB(255, 190, 62),
    BORDER    = Color3.fromRGB(38, 42, 60),
    RGB       = false,
    Accent    = Color3.fromRGB(0, 229, 255),
    Hue       = 0.5,
}
local accentListeners = {}
local coreAccentListeners = {}
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

--  ROOT 
local NovaUI = Instance.new("ScreenGui")
NovaUI.Name = "sa7loul_V3"
NovaUI.ResetOnSpawn = false
NovaUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NovaUI.Enabled = true
NovaUI.IgnoreGuiInset = true
NovaUI.Parent = CoreGui

print("NovaUI created and parented to CoreGui")

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Parent = NovaUI
Window.BackgroundColor3 = UITheme.BG
Window.BackgroundTransparency = 0
Window.BorderSizePixel = 0
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.Position = UDim2.fromScale(0.5, 0.5)
Window.Size = UDim2.new(0, 720, 0, 540)
Window.Visible = true

print("Window created and configured")

-- Add a test label to verify GUI is working
local testLabel = Instance.new("TextLabel")
testLabel.Name = "TestLabel"
testLabel.Size = UDim2.new(0, 200, 0, 50)
testLabel.Position = UDim2.new(0.5, -100, 0.5, -25)
testLabel.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
testLabel.Text = "TEST GUI WORKING"
testLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
testLabel.TextSize = 20
testLabel.Font = Enum.Font.GothamBold
testLabel.Parent = NovaUI
print("Test label added")

-- Force visibility after a short delay
spawn(function()
    wait(0.5)
    if NovaUI and NovaUI.Parent then
        NovaUI.Enabled = true
        print("NovaUI.Enabled forced to true")
    end
    if Window and Window.Parent then
        Window.Visible = true
        print("Window.Visible forced to true")
    end
end)
local windowCorner = Instance.new("UICorner", Window)
windowCorner.CornerRadius = UDim.new(0, 16)
local windowStroke = Instance.new("UIStroke", Window)
windowStroke.Thickness = 1
windowStroke.Color = UITheme.BORDER
windowStroke.Transparency = 0.35
local windowGradient = Instance.new("UIGradient", Window)
windowGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, UITheme.BG_DEEP),
    ColorSequenceKeypoint.new(1, UITheme.BG)
})

-- glow halo behind the window
local GlowBlur = Instance.new("BlurEffect")
GlowBlur.Name = "WindowGlow"
GlowBlur.Size = 6
GlowBlur.Parent = Lighting
local glowHalo = Instance.new("Frame")
glowHalo.Name = "GlowHalo"
glowHalo.Parent = Window
glowHalo.BackgroundColor3 = UITheme.BG_DEEP
glowHalo.BackgroundTransparency = 0.6
glowHalo.BorderSizePixel = 0
glowHalo.Size = UDim2.new(1, 24, 1, 24)
glowHalo.Position = UDim2.new(0, -12, 0, -12)
glowHalo.ZIndex = -1
Instance.new("UICorner", glowHalo).CornerRadius = UDim.new(0, 22)

-- top neon accent line
local accentLine = Instance.new("Frame")
accentLine.Name = "AccentLine"
accentLine.Parent = Window
accentLine.BackgroundColor3 = UITheme.Accent
accentLine.BorderSizePixel = 0
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.ZIndex = 10
local accentLineGrad = Instance.new("UIGradient", accentLine)
accentLineGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, UITheme.PURPLE),
    ColorSequenceKeypoint.new(0.5, UITheme.Accent),
    ColorSequenceKeypoint.new(1, UITheme.PURPLE)
})
UITheme:RegisterAccent(function(c)
    accentLineGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, UITheme.PURPLE),
        ColorSequenceKeypoint.new(0.5, c),
        ColorSequenceKeypoint.new(1, UITheme.PURPLE)
    })
end, true)

-- opening animation (simplified)
Window.BackgroundTransparency = 0
Window.Size = UDim2.new(0, 720, 0, 540)
print("Window animation completed")

--  HEADER 
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = Window
Header.BackgroundColor3 = UITheme.PANEL
Header.BackgroundTransparency = 0.15
Header.BorderSizePixel = 0
Header.Size = UDim2.new(1, 0, 0, 54)
Header.ZIndex = 5
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)
local headerGrad = Instance.new("UIGradient", Header)
headerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, UITheme.BG_DEEP),
    ColorSequenceKeypoint.new(0.6, UITheme.PANEL),
    ColorSequenceKeypoint.new(1, UITheme.BG_DEEP)
})
local headerBottom = Instance.new("Frame")
headerBottom.Parent = Header
headerBottom.BackgroundColor3 = UITheme.BORDER
headerBottom.BackgroundTransparency = 0.5
headerBottom.BorderSizePixel = 0
headerBottom.Size = UDim2.new(1, 0, 0, 1)
headerBottom.Position = UDim2.new(0, 0, 1, 0)

-- logo badge (pure UI, renders on every client)
local logoBox = Instance.new("Frame")
logoBox.Parent = Header
logoBox.BackgroundTransparency = 1
logoBox.BorderSizePixel = 0
logoBox.Size = UDim2.new(0, 34, 0, 34)
logoBox.Position = UDim2.new(0, 12, 0.5, -17)
local logoBadge = Instance.new("Frame")
logoBadge.Parent = logoBox
logoBadge.AnchorPoint = Vector2.new(0.5, 0.5)
logoBadge.Position = UDim2.new(0.5, 0, 0.5, 0)
logoBadge.Size = UDim2.new(1, 0, 1, 0)
logoBadge.BackgroundColor3 = UITheme.BG_DEEP
logoBadge.BorderSizePixel = 0
Instance.new("UICorner", logoBadge).CornerRadius = UDim.new(0.32, 0)
local logoGradient = Instance.new("UIGradient", logoBadge)
logoGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, UITheme.PURPLE),
    ColorSequenceKeypoint.new(1, UITheme.Accent)
})
logoGradient.Rotation = 135
local logoStroke = Instance.new("UIStroke", logoBadge)
logoStroke.Thickness = 2
logoStroke.Color = UITheme.Accent
logoStroke.Transparency = 0.25
local logoLetter = Instance.new("TextLabel")
logoLetter.Parent = logoBadge
logoLetter.BackgroundTransparency = 1
logoLetter.Size = UDim2.new(1, 0, 1, 0)
logoLetter.Font = Enum.Font.GothamBlack
logoLetter.Text = "s7"
logoLetter.TextColor3 = Color3.fromRGB(255, 255, 255)
logoLetter.TextSize = 15
logoLetter.TextYAlignment = Enum.TextYAlignment.Center
UITheme:RegisterAccent(function(c)
    logoGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, UITheme.PURPLE),
        ColorSequenceKeypoint.new(1, c)
    })
    logoStroke.Color = c
end, true)

local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = Header
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "sa7loul"
titleLabel.TextColor3 = UITheme.TEXT
titleLabel.TextSize = 19
titleLabel.Size = UDim2.new(0, 120, 0, 20)
titleLabel.Position = UDim2.new(0, 56, 0, 8)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
local titleAccent = Instance.new("TextLabel")
titleAccent.Parent = Header
titleAccent.BackgroundTransparency = 1
titleAccent.Font = Enum.Font.GothamBold
titleAccent.Text = "V3"
titleAccent.TextColor3 = UITheme.Accent
titleAccent.TextSize = 14
titleAccent.Size = UDim2.new(0, 34, 0, 18)
titleAccent.Position = UDim2.new(0, 148, 0, 9)
titleAccent.TextXAlignment = Enum.TextXAlignment.Left
UITheme:RegisterAccent(function(c) titleAccent.TextColor3 = c end, true)

local headerSub = Instance.new("TextLabel")
headerSub.Parent = Header
headerSub.BackgroundTransparency = 1
headerSub.Font = Enum.Font.Gotham
headerSub.Text = "Survive the Killer  Premium"
headerSub.TextColor3 = UITheme.SUBTEXT
headerSub.TextSize = 11
headerSub.Size = UDim2.new(0, 260, 0, 16)
headerSub.Position = UDim2.new(0, 56, 0, 30)
headerSub.TextXAlignment = Enum.TextXAlignment.Left

-- header buttons (minimize / close)
function headerIconButton(text, color)
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
local menuKeyChip = Instance.new("TextButton")
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

local minimizeBtn = headerIconButton("-", UITheme.GREEN)
minimizeBtn.Position = UDim2.new(1, -104, 0.5, -13)
local closeBtn = headerIconButton("x", UITheme.RED)
closeBtn.Position = UDim2.new(1, -72, 0.5, -13)

local minimizedHint = Instance.new("TextLabel")
minimizedHint.Parent = Header
minimizedHint.BackgroundTransparency = 1
minimizedHint.Font = Enum.Font.Gotham
minimizedHint.Text = "minimized -  click  to restore full menu"
minimizedHint.TextColor3 = UITheme.SUBTEXT
minimizedHint.TextSize = 10
minimizedHint.Size = UDim2.new(0, 220, 0, 16)
minimizedHint.Position = UDim2.new(0, 36, 0, 32)
minimizedHint.TextXAlignment = Enum.TextXAlignment.Left
minimizedHint.Visible = false

--  DRAG 
local minimized = false
local dragging = false
local pendingDrag = false
local dragMoved = false
local dragStartPos = Vector2.zero
local dragOffset = Vector2.zero
local dragLockUntil = 0
local suppressBtnClick = 0

local function pointInGui(pos, gui)
    if not gui then return false end
    local p = gui.AbsolutePosition
    local s = gui.AbsoluteSize
    return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end

-- blocks drag when the press lands on an interactive element (buttons, toggles, sliders...)
local function shouldBlockDrag(pos)
    local guis = {}
    local ok = pcall(function()
        guis = GuiService:GetGuiObjectsAtPosition(pos.X, pos.Y)
    end)
    if ok and #guis > 0 then
        for _, g in ipairs(guis) do
            if g:IsA("TextButton") or g:IsA("TextBox") or g:IsA("ImageButton") then
                return true
            end
            if g.GetAttribute and g:GetAttribute("noDrag") then
                return true
            end
        end
    end
    return false
end

local function registerDragStart(pos)
    pendingDrag = true
    dragStartPos = pos
    dragMoved = false
end

local function headerClicked(input)
    local pos = input.Position
    if not pointInGui(pos, Header) then return end
    if minimized then
        if pointInGui(pos, closeBtn) then return end
        ApplyMinimized(false)
        suppressBtnClick = os.clock() + 0.6
        dragLockUntil = os.clock() + 0.6
        return
    end
    if os.clock() < dragLockUntil then return end
    if pointInGui(pos, minimizeBtn) or pointInGui(pos, closeBtn) or pointInGui(pos, menuKeyChip) then return end
    registerDragStart(pos)
end

-- drag from ANYWHERE in the window (except interactive controls)
local function windowDragCheck(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if minimized then return end
    if os.clock() < dragLockUntil then return end
    local pos = input.Position
    if not pointInGui(pos, Window) then return end
    if shouldBlockDrag(pos) then return end
    registerDragStart(pos)
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        headerClicked(input)
    end
end)
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        headerClicked(input)
        windowDragCheck(input)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        pendingDrag = false
        dragMoved = false
    end
end)
RunService.RenderStepped:Connect(function()
    if pendingDrag and not dragging then
        local cur = UserInputService:GetMouseLocation()
        if (cur - dragStartPos).Magnitude > 6 then
            dragging = true
            dragOffset = cur - Vector2.new(Window.AbsolutePosition.X, Window.AbsolutePosition.Y)
        end
    end
    if dragging then
        local pos = UserInputService:GetMouseLocation()
        local sz = Window.AbsoluteSize
        pcall(function()
            -- anchor-point aware positioning: keeps the grab point fixed under the cursor
            Window.Position = UDim2.fromOffset(
                pos.X - dragOffset.X + sz.X * Window.AnchorPoint.X,
                pos.Y - dragOffset.Y + sz.Y * Window.AnchorPoint.Y
            )
        end)
    end
end)

-- minimize / restore
function ApplyMinimized(state)
    minimized = state
    minimizeBtn.Text = state and "" or ""
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
                pcall(UpdateRightContent)
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
    if GlowBlur then pcall(function() GlowBlur:Destroy() end) end
end)

--  SEARCH BAR 
local SearchBar = Instance.new("Frame")
SearchBar.Parent = Window
SearchBar.BackgroundTransparency = 1
SearchBar.Size = UDim2.new(1, -196, 0, 38)
SearchBar.Position = UDim2.new(0, 182, 0, 62)

local searchIcon = Instance.new("TextLabel")
searchIcon.Parent = SearchBar
searchIcon.BackgroundTransparency = 1
searchIcon.Font = Enum.Font.Gotham
searchIcon.Text = "-"
searchIcon.TextColor3 = UITheme.SUBTEXT
searchIcon.TextSize = 18
searchIcon.Size = UDim2.new(0, 30, 1, 0)
searchIcon.TextXAlignment = Enum.TextXAlignment.Center

local SearchBox = Instance.new("TextBox")
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
local searchStroke = Instance.new("UIStroke", SearchBox)
searchStroke.Thickness = 1
searchStroke.Color = UITheme.BORDER
searchStroke.Transparency = 0.4
SearchBox.Focused:Connect(function()
    TweenService:Create(searchStroke, TweenInfo.new(0.15), {Color = UITheme.Accent, Transparency = 0}):Play()
end)
SearchBox.FocusLost:Connect(function()
    TweenService:Create(searchStroke, TweenInfo.new(0.15), {Color = UITheme.BORDER, Transparency = 0.4}):Play()
end)

--  SIDEBAR 
local Sidebar = Instance.new("Frame")
Sidebar.Parent = Window
Sidebar.BackgroundColor3 = UITheme.PANEL
Sidebar.BackgroundTransparency = 0.2
Sidebar.BorderSizePixel = 0
Sidebar.Position = UDim2.new(0, 0, 0, 56)
Sidebar.Size = UDim2.new(0, 170, 1, -56)
Sidebar.ZIndex = 4
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 14)
local sidebarBottom = Instance.new("Frame")
sidebarBottom.Parent = Sidebar
sidebarBottom.BackgroundColor3 = UITheme.BORDER
sidebarBottom.BackgroundTransparency = 0.5
sidebarBottom.BorderSizePixel = 0
sidebarBottom.Size = UDim2.new(1, 0, 0, 1)
sidebarBottom.Position = UDim2.new(0, 0, 1, 0)

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Parent = Sidebar
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 0
SidebarScroll.Size = UDim2.new(1, 0, 1, -56)
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local sidebarList = Instance.new("UIListLayout", SidebarScroll)
sidebarList.Padding = UDim.new(0, 3)
sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", SidebarScroll).PaddingTop = UDim.new(0, 10)

local sidebarTitle = Instance.new("TextLabel")
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

-- verified icon assets (lucide decals on Roblox CDN)
local ICON_ASSETS = {
    home = "rbxassetid://7733960981",
    user = "rbxassetid://7743875962",
    person = "rbxassetid://7743871002",
    heart = "rbxassetid://7733956134",
    globe = "rbxassetid://7733954760",
    users = "rbxassetid://7743876054",
    smile = "rbxassetid://7734059095",
    box = "rbxassetid://7733917120",
    skull = "rbxassetid://7734058599",
    userx = "rbxassetid://7743875879",
    more = "rbxassetid://7734006080",
    gear = "rbxassetid://7734053495",
    compass = "rbxassetid://7733924216",
    eye = "rbxassetid://7733774602",
    zap = "rbxassetid://7733771628",
    target = "rbxassetid://7743872758",
    shield = "rbxassetid://7734056608",
    plane = "rbxassetid://7734037723",
    info = "rbxassetid://7733964719",
    clock = "rbxassetid://7733734848",
    search = "rbxassetid://7734052925",
    arrow_right = "rbxassetid://7733673345",
    wrench = "rbxassetid://7743878358",
    map = "rbxassetid://7733992829",
    key = "rbxassetid://7733965118",
    music = "rbxassetid://7734020554",
    mic = "rbxassetid://7743869805",
    volume = "rbxassetid://7743877487",
    star = "rbxassetid://7734068321",
    flame = "rbxassetid://7733798747",
    hammer = "rbxassetid://7733955511",
    crosshair = "rbxassetid://7733765307",
    lock = "rbxassetid://7733992528",
    radio = "rbxassetid://7743871662",
    scissors = "rbxassetid://7734052570",
    ghost = "rbxassetid://7743868000",
    alert = "rbxassetid://7733658504",
    check = "rbxassetid://7733715400",
    folder = "rbxassetid://7733799185",
    book = "rbxassetid://7733914390",
    paperclip = "rbxassetid://7734021680",
    refresh = "rbxassetid://7734051052",
    download = "rbxassetid://7733770755",
    trash = "rbxassetid://7743873871",
    plus = "rbxassetid://7734042071",
    save = "rbxassetid://7734052335",
    send = "rbxassetid://7734053039",
    navigation = "rbxassetid://7734020989",
    activity = "rbxassetid://7733655755",
    gauge = "rbxassetid://7733799969",
    database = "rbxassetid://7743866778",
    server = "rbxassetid://7734053426",
    package = "rbxassetid://7734021469",
    gift = "rbxassetid://7733946818",
    gamepad = "rbxassetid://7733799901",
    headphones = "rbxassetid://7733956063",
    camera = "rbxassetid://7733708692",
    video = "rbxassetid://7743876610",
    battery = "rbxassetid://7733674820",
    wifi = "rbxassetid://7743878148",
    palette = "rbxassetid://7734021595",
    wand = "rbxassetid://8997388430",
    gem = "rbxassetid://7733942651",
    award = "rbxassetid://7733673987",
    crown = "rbxassetid://7733765398",
    snow = "rbxassetid://7734059180",
    layers = "rbxassetid://7743868936",
    beaker = "rbxassetid://7733674922",
    terminal = "rbxassetid://7743872929",
    code = "rbxassetid://7733749837",
    history = "rbxassetid://7733960880",
}

local SECTION_ICONS = {
    ["Welcome back"] = "home",
    ["Quick access"] = "zap",
    ["Changelog V3"] = "history",
    ["Movement"] = "activity",
    ["Flight & NoClip"] = "plane",
    ["Bypass"] = "shield",
    ["Combat"] = "target",
    ["Powers"] = "zap",
    ["Visuals"] = "eye",
    ["Auto Loot"] = "gem",
    ["Teleport"] = "navigation",
    ["Camera"] = "camera",
    ["Quick teleports"] = "map",
    ["Player list"] = "users",
    ["Revive modes"] = "heart",
    ["Self revive"] = "heart",
    ["Target"] = "crosshair",
    ["Actions"] = "send",
    ["Party"] = "music",
    ["Cuff Items  Spawn / Give / Take"] = "box",
    ["Custom search"] = "search",
    ["Take from target"] = "user",
    ["Troll Target"] = "skull",
    ["Annoy & Fling"] = "flame",
    ["Fake Admin / System Chat"] = "terminal",
    ["Fake Admin (remotes)"] = "key",
    ["Ghost & Tools"] = "ghost",
    ["Screen Chaos"] = "gauge",
    ["Earrape Audio"] = "volume",
    ["Ban Manager"] = "userx",
    ["Banned players"] = "trash",
    ["Storage scan"] = "database",
    ["External scripts"] = "code",
    ["Your scripts"] = "folder",
    ["Keybinds"] = "key",
    ["Theme"] = "palette",
    ["Configs"] = "gear",
    ["Saved configs"] = "save",
    ["Account"] = "shield",
    ["Other"] = "more",
}

local TabItems = {
    { key = "  Home",       icon = "home", label = "Home" },
    { key = "  Player",     icon = "person", label = "Player" },
    { key = "  Revive",     icon = "heart", label = "Revive" },
    { key = "  World",      icon = "globe", label = "World" },
    { key = "  Players",    icon = "users", label = "Players" },
    { key = "  Fun",        icon = "smile", label = "Fun" },
    { key = "  Spawner",    icon = "box", label = "Spawner" },
    { key = "  Troll",      icon = "skull", label = "Troll" },
    { key = "  Ban",        icon = "userx", label = "Ban" },
    { key = "  Extras",     icon = "more", label = "Extras" },
    { key = "  Settings",   icon = "gear", label = "Settings" },
}
local TabButtons = {}

-- sidebar footer (RGB quick switch)
local sidebarFooter = Instance.new("Frame")
sidebarFooter.Parent = Sidebar
sidebarFooter.BackgroundTransparency = 1
sidebarFooter.Size = UDim2.new(1, 0, 0, 40)
sidebarFooter.Position = UDim2.new(0, 0, 1, -46)
local rgbQuick = Instance.new("TextButton")
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
Instance.new("UICorner", rgbQuick).CornerRadius = UDim.new(0, 7)

local tabVisuals = {}
function BuildSidebar()
    for _, item in ipairs(TabItems) do
        local btn = Instance.new("TextButton")
        btn.Parent = SidebarScroll
        btn.BackgroundColor3 = UITheme.ELEMENT
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(1, -12, 0, 34)
        btn.Position = UDim2.new(0, 6, 0, 0)
        btn.LayoutOrder = #SidebarScroll:GetChildren()
        btn.Font = Enum.Font.GothamBold
        btn.Text = "  " .. item.label
        btn.TextColor3 = UITheme.SUBTEXT
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextYAlignment = Enum.TextYAlignment.Center
        btn.AutoButtonColor = false
        Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 34)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local iconImg = Instance.new("ImageLabel")
        iconImg.Parent = btn
        iconImg.BackgroundTransparency = 1
        iconImg.BorderSizePixel = 0
        iconImg.Size = UDim2.new(0, 17, 0, 17)
        iconImg.Position = UDim2.new(0, 10, 0.5, -8.5)
        iconImg.Image = ICON_ASSETS[item.icon] or ICON_ASSETS.more
        iconImg.ImageColor3 = UITheme.SUBTEXT
        iconImg.ScaleType = Enum.ScaleType.Fit
        UITheme:RegisterAccent(function(c) iconImg.ImageColor3 = c end)

        local glowBar = Instance.new("Frame")
        glowBar.Parent = btn
        glowBar.BackgroundColor3 = UITheme.Accent
        glowBar.BorderSizePixel = 0
        glowBar.Size = UDim2.new(0, 3, 0.5, 0)
        glowBar.Position = UDim2.new(0, 0, 0.25, 0)
        glowBar.BackgroundTransparency = 1
        glowBar.ZIndex = 5
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
            SwitchTab(item.key)
        end)
        TabButtons[item.key] = { btn = btn, glow = glowBar, icon = iconImg }
        tabVisuals[item.key] = { btn = btn, glow = glowBar, icon = iconImg }
    end
end
function RefreshTabVisuals()
    for key, vis in pairs(tabVisuals) do
        local active = (CurrentTab == key)
        TweenService:Create(vis.btn, TweenInfo.new(0.18), {
            BackgroundTransparency = active and 0.35 or 1,
            TextColor3 = active and UITheme.TEXT or UITheme.SUBTEXT
        }):Play()
        TweenService:Create(vis.glow, TweenInfo.new(0.18), {
            BackgroundTransparency = active and 0 or 1
        }):Play()
        if vis.icon then
            TweenService:Create(vis.icon, TweenInfo.new(0.18), {
                ImageColor3 = active and UITheme.Accent or UITheme.SUBTEXT
            }):Play()
        end
    end
end

--  CONTENT 
local ContentScroll = Instance.new("ScrollingFrame")
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
local contentLayout = Instance.new("UIListLayout", ContentScroll)
contentLayout.Padding = UDim.new(0, 16)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

--  STATUS BAR 
local statusBar = Instance.new("Frame")
statusBar.Parent = Window
statusBar.BackgroundColor3 = UITheme.PANEL
statusBar.BackgroundTransparency = 0.35
statusBar.BorderSizePixel = 0
statusBar.Position = UDim2.new(0, 182, 1, -26)
statusBar.Size = UDim2.new(1, -194, 0, 26)
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 8)
Instance.new("UIPadding", statusBar).PaddingLeft = UDim.new(0, 10)

local statusLabel = Instance.new("TextLabel")
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

--  COMPONENTS 
local activeRows = {}

function ClearContent()
    activeRows = {}
    UITheme:ClearContentAccents()
    for _, child in ipairs(ContentScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

function RefreshSearch()
    local q = SearchBox.Text:lower()
    for _, h in ipairs(activeRows) do
        local match = (q == "") or (h.tag and h.tag:find(q, 1, true))
        h.Row.Visible = match
    end
end
SearchBox:GetPropertyChangedSignal("Text"):Connect(RefreshSearch)

function trackRow(row, tag)
    local handle = { Row = row, tag = tag and tag:lower() or "" }
    table.insert(activeRows, handle)
    return handle
end

local function Section(parent, title, icon)
    local section = Instance.new("Frame")
    section.Parent = parent
    section.BackgroundColor3 = UITheme.PANEL
    section.BackgroundTransparency = 0.5
    section.BorderSizePixel = 0
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.LayoutOrder = #parent:GetChildren()
    Instance.new("UICorner", section).CornerRadius = UDim.new(0, 12)
    local secStroke = Instance.new("UIStroke", section)
    secStroke.Thickness = 1
    secStroke.Color = UITheme.BORDER
    secStroke.Transparency = 0.5
    UITheme:RegisterAccent(function(c)
        secStroke.Color = c
        secStroke.Transparency = 0.25
    end)
    local secPad = Instance.new("UIPadding", section)
    secPad.PaddingLeft = UDim.new(0, 12)
    secPad.PaddingRight = UDim.new(0, 12)
    secPad.PaddingTop = UDim.new(0, 8)
    secPad.PaddingBottom = UDim.new(0, 10)

    local head = Instance.new("Frame")
    head.Parent = section
    head.BackgroundTransparency = 1
    head.Size = UDim2.new(1, -24, 0, 26)

    local headIcon = nil
    local iconKey = (icon and type(icon) == "string" and (ICON_ASSETS[icon] or SECTION_ICONS[title])) or SECTION_ICONS[title]
    if iconKey then
        headIcon = Instance.new("ImageLabel")
        headIcon.Parent = head
        headIcon.BackgroundTransparency = 1
        headIcon.BorderSizePixel = 0
        headIcon.Size = UDim2.new(0, 16, 0, 16)
        headIcon.Position = UDim2.new(0, 0, 0.5, -8)
        headIcon.Image = (type(iconKey) == "string" and ICON_ASSETS[iconKey]) or iconKey
        headIcon.ImageColor3 = UITheme.SUBTEXT
        headIcon.ScaleType = Enum.ScaleType.Fit
        UITheme:RegisterAccent(function(c) if headIcon and headIcon.Parent then headIcon.ImageColor3 = c end end)
    end

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
    if headIcon then
        titleLabel.Position = UDim2.new(0, 24, 0, 0)
        titleLabel.Size = UDim2.new(1, -114, 1, 0)
    end
    UITheme:RegisterAccent(function(c) titleLabel.TextColor3 = c end)

    local line = Instance.new("Frame")
    line.Parent = head
    line.BackgroundColor3 = UITheme.BORDER
    line.BackgroundTransparency = 0.4
    line.BorderSizePixel = 0
    line.Size = UDim2.new(0.32, 0, 0, 1)
    line.Position = UDim2.new(1, -110, 0.5, 0)

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
        UITheme:RegisterAccent(function(c)
            btn.BackgroundColor3 = c
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

local function TextBox(parent, opts)
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
    UITheme:RegisterAccent(function(c) fill.BackgroundColor3 = c end)

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
    UITheme:RegisterAccent(function(c)
        knobGlow.Color = c
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

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end)
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

    local open = false
    local list = Instance.new("Frame")
    list.Parent = frame
    list.BackgroundColor3 = UITheme.PANEL
    list.BackgroundTransparency = 0
    list.BorderSizePixel = 0
    list.Size = UDim2.new(0, 160, 0, 0)
    list.Position = UDim2.new(1, -160, 0, 32)
    list.ZIndex = 30
    list.ClipsDescendants = true
    list.Visible = false
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", list).Color = UITheme.BORDER
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

    local function close()
        open = false
        list.Visible = false
        TweenService:Create(list, TweenInfo.new(0.15), {Size = UDim2.new(0, 160, 0, 0)}):Play()
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

--  TOGGLE + KEYBIND CHIP 
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
        TweenService:Create(switchKnob, switchAnim, {
            Position = state and UDim2.new(1, -18, 0.5, -7.5) or UDim2.new(0, 3, 0.5, -7.5)
        }):Play()
        TweenService:Create(switchStroke, switchAnim, {
            Color = state and UITheme.Accent or UITheme.BORDER,
            Transparency = state and 0 or 0.3
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
            setVisual()
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
        KeybindsLib.Register(opts.id, {
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
-- 
--  PART 2  KEYBIND MANAGER - SCREEN FX - TROLL ENGINE
-- 

--  KEYBIND MANAGER 
-- Every toggle gets a clickable keybind chip. Click chip   "Press Key..."
-- Backspace/Delete unbinds. Bound key toggles the feature (gameProcessed-safe).
local KeybindsLib = {
    map = {},    -- id -> { set, get, chip, name, key }
    byKey = {},  -- keyCode -> { id, ... }
    activeId = nil,
    timeoutTask = nil,
}
local keybindFile = "sa7loul_Keybinds.json"

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
    self.activeId = id
    local chip = self.map[id] and self.map[id].chip
    if chip and chip.Parent then
        chip.Text = "..."
        chip.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    if self.timeoutTask then self.timeoutTask:Cancel() end
    self.timeoutTask = task.delay(7, function()
        if self.activeId == id then
            self.activeId = nil
            self:RefreshChip(id)
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

-- load saved keybinds from disk (pcall  safe on executors without file io)
local function KeybindsLoadFromDisk()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(keybindFile))
    end)
    if ok and type(data) == "table" then
        KeybindsLib:Restore(data)
        notif("' Keybinds restored", 2)
    end
end

-- global input dispatcher (single connection, created once here)
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

    -- 2) trigger bound features (never while typing in chat / menus)
    if gameProcessed then return end
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

--  SCREEN FX ENGINE 
local ScreenFx = {
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

--  JUMPSCARE BURST  flash + FOV punch + shake + sound
local jumpScareActive = false
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

--  TROLL ENGINE 
local TrollTargetSel = nil
-- Emoji-free mapping: keep players dropdown synced
local trollTargetDropdown = nil

local TrollCfg = {
    fling = false,        -- physics fling
    annoy = false,        -- teleport spam around target
    invis = false,        -- ghost mode
    sneakySeat = false,
    clickTP = false,
    earrape = false,
    earrapeChoice = 1,
    earrapeVolume = 10,
}
local TrollState = {
    flingAng = nil, flingVel = nil, flingConn = nil,
    annoyConn = nil, annoyTimer = 0,
    invisConn = nil, invisSaved = {},
    sneakySeatObj = nil, sneakyConn = nil, sneakySaved = {},
    clickTPLast = 0,
    earrapeSound = nil, earrapeConn = nil,
}

local TROLL_SOUNDS = {
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

--  1) FLING TARGET (physics-based: angular velocity + random linear yeet)
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
    notif(" Troll Fling: ON", 2)
end

local function TrollFlingStop()
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
    notif(" Troll Fling: OFF", 2)
end

-- ' 2) ANNOY LOOP  teleport spam around the target
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
    notif("' Annoy Loop: ON (hops around " .. (TrollGetTarget() and TrollGetTarget().Name or "target") .. ")", 2)
end

local function TrollAnnoyStop()
    TrollCfg.annoy = false
    if TrollHandles and TrollHandles.annoy then pcall(function() TrollHandles.annoy:Set(false, true) end) end
    if TrollState.annoyConn then TrollState.annoyConn:Disconnect(); TrollState.annoyConn = nil end
    notif("' Annoy Loop: OFF", 2)
end

--  3) GHOST MODE (client-side invisibility)
local function TrollInvisStart()
    TrollCfg.invis = true
    if TrollState.invisConn then TrollState.invisConn:Disconnect() end
    TrollState.invisSaved = {}
    local function hide()
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
    notif(" Ghost Mode: ON", 2)
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
    notif(" Ghost Mode: OFF", 2)
end

--  4) SNEAKY SEAT  invisible seat + hide while seated
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
    local function apply(seated)
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
    notif(" Sneaky Seat spawned  you're invisible while seated", 3)
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
    notif(" Sneaky Seat: OFF", 2)
end

--  5) CLICK-TO-TELEPORT TOOL
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
    local char = lp.Character
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
            notif(" Teleported to: " .. target.Name, 1)
        end
    end
end

local function TrollClickTPStart()
    TrollCfg.clickTP = true
    notif(" Click TP: ON  click any player to teleport", 2)
end
local function TrollClickTPStop()
    TrollCfg.clickTP = false
    notif(" Click TP: OFF", 2)
end

--  6) EARRAPE AUDIO SPAM (local sounds)
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
    notif("  Earrape: ON (" .. choice.name .. ")", 2)
end

local function TrollEarrapeStop()
    TrollCfg.earrape = false
    if TrollState.earrapeConn then TrollState.earrapeConn:Disconnect(); TrollState.earrapeConn = nil end
    if TrollState.earrapeSound then
        pcall(function() TrollState.earrapeSound:Stop() end)
        pcall(function() TrollState.earrapeSound:Destroy() end)
        TrollState.earrapeSound = nil
    end
    notif("  Earrape: OFF", 2)
end

--  FAKE ADMIN / SYSTEM MESSAGES (client chat only)
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

--  FAKE ADMIN SCRIPT SPOOF  fires "admin" remotes with a fake server title
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
-- -----------------------------------------------------------------------
--  PART 3  TAB CONTENTS - EVENTS - INIT
-- -----------------------------------------------------------------------

local TrollHandles = {}
local trollTargetOptions = {}
local trollTargetDD = nil

local fpsMeter = 0
local lastFrameTime = os.clock()
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

--  TAB SWITCHING 
function SwitchTab(key)
    CurrentTab = key
    RefreshTabVisuals()
    RefreshSearch()
    ContentScroll.CanvasPosition = Vector2.zero
    UpdateRightContent()
end

--  PLAYERS TAB 
function CreatePlayerEntry(parent, player)
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
        statusLabel.Text = " You"
        statusLabel.TextColor3 = UITheme.Accent
    elseif IsPlayerDowned(player) then
        statusLabel.Text = "' Down"
        statusLabel.TextColor3 = UITheme.RED
    elseif IsPlayerInLobby(player) then
        statusLabel.Text = " Lobby"
        statusLabel.TextColor3 = UITheme.DIM
    else
        statusLabel.Text = "-"
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
            btn.Font = Enum.Font.GothamBold
            btn.Text = icon
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 12
            btn.BackgroundColor3 = color
            btn.BackgroundTransparency = 0.25
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
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
        actionBtn("-", UITheme.CYAN, function()
            if bringActive then
                StopBring()
            else
                StartBring(player.Name)
            end
        end)
        actionBtn("", UITheme.PURPLE, function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                notif("Teleported to: " .. player.Name, 2)
            else
                notif("Player not found", 2)
            end
        end)
        actionBtn("", UITheme.GREEN, function()
            GiveFlyNoClip()
        end)
        actionBtn("'", UITheme.AMBER, function()
            if viewing == player then
                StopView()
            else
                StartView(player.Name)
            end
        end)
        actionBtn("", Color3.fromRGB(80, 170, 255), function()
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

function UpdatePlayerList()
    if CurrentTab ~= "  Players" then return end
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

function RefreshPlayerSideTab()
    if trollTargetDD then RefreshTrollTargetOptions() end
end

--  CUFF ITEM SPAWNER / GIVER 
function IsCuffObject(obj)
    return (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart"))
        and string.lower(obj.Name):find("cuff", 1, true) ~= nil
end

function GetAllCuffItemNames()
    local seen = {}
    local results = {}
    local function scan(root)
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

function FindCuffObject(itemName)
    local function findIn(root)
        if not root then return nil end
        return root:FindFirstChild(itemName, true)
    end
    local obj = findIn(PlayersSvc) or findIn(workspace) or findIn(game:GetService("ReplicatedStorage"))
    if obj and IsCuffObject(obj) then return obj end
    return nil
end

function PositionItemNearPlayer(item, target)
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

function GiveCuffItemToPlayer(itemName, targetPlayer)
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
        notif("Gave - " .. itemName .. "  " .. target.Name, 2)
    else
        notif("Could not give: " .. itemName, 2)
    end
    return ok
end

function SpawnCuffItemForMe(itemName)
    return GiveCuffItemToPlayer(itemName, lp)
end

function TakeCuffsFromTarget(target)
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
        notif("Took - " .. taken .. " cuff item(s) from " .. targetPlayer.Name, 2)
    else
        notif("No cuffs found on " .. targetPlayer.Name, 2)
    end
    return taken
end

function RemoveMyCuffs()
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
    notif(removed > 0 and ("Removed - " .. removed .. " cuff item(s)") or "No cuffs to remove", 2)
end
--  END CUFF CODE 

--  SPAWNER ENGINE (generic items) 
function Normalize(s)
    return string.lower((s or ""):gsub("[ ]", "a"):gsub("[]", "e"):gsub("[]", "i"):gsub("[]", "o"):gsub("[]", "u"):gsub("", "c"):gsub("", "n"):gsub("%s+", " "))
end

function ItemIcon(name)
    local n = Normalize(name)
    local map = {
        { {"knife", "couteau", "cutter", "machete", "cleaver", "dart", "kunai", "stab"}, "" },
        { {"gun", "pistol", "pistolet", "rifle", "fusil", "shotgun", "bazooka"}, "" },
        { {"axe", "hache", "hatchet", "hachoir"}, "" },
        { {"hammer", "marteau", "mallet"}, "" },
        { {"sword", "epee", "katana", "saber"}, "" },
        { {"bat", "batte", "club", "cricket"}, "" },
        { {"ring", "alliance"}, "'" },
        { {"dryer", "seche", "cheveux"}, "" },
        { {"cuff", "menotte"}, "-" },
        { {"locker", "casier", "armoire"}, "-" },
        { {"glove", "gant"}, "" },
        { {"box", "boite"}, "" },
        { {"key", "cle"}, "-" },
        { {"candle", "bougie"}, "-" },
        { {"soap", "savon"}, "" },
        { {"coin", "cash", "money", "loot"}, "'" },
        { {"med", "firstaid", "bandage", "kit", "soin"}, "" },
        { {"armor", "armure", "vest", "gilet"}, "" },
    }
    for _, e in ipairs(map) do
        for _, t in ipairs(e[1]) do
            if n:find(t, 1, true) then return e[2] end
        end
    end
    return ""
end

function ScanItemsByKeyword(keyword)
    local seen = {}
    local results = {}
    local tokens = {}
    for token in string.gmatch(keyword or "", "[^|]+") do
        local t = Normalize(token):gsub(" ", "")
        if t ~= "" then table.insert(tokens, t) end
    end
    if #tokens == 0 then return results end
    local function scan(root)
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

function FindSpawnObject(itemName)
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

function GiveSpawnItemToPlayer(itemName, targetPlayer)
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
        notif("Spawned  " .. itemName .. "  " .. target.Name, 2)
    else
        notif("Could not spawn: " .. itemName, 2)
    end
    return ok
end

function SpawnSpawnItemForMe(itemName)
    return GiveSpawnItemToPlayer(itemName, lp)
end

function TakeSpawnItemsFromTarget(target, keyword)
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
        notif("Took  " .. taken .. " item(s) from " .. targetPlayer.Name, 2)
    else
        notif("No matching items on " .. targetPlayer.Name, 2)
    end
    return taken
end

--  ITEM CATALOG + SNAPSHOT 
-- Live scan finds items currently in the server; the catalog fills in the
-- known STK items so the spawner always shows a full list.
local KNOWN_CATALOG = {
    "Sche-Cheveux", "Seche-Cheveux", "Hair Dryer", "Hairdryer",
    "Coupe-Cheveux", "Hair Cutter", "Rasoir", "Razor",
    "Cuffs", "Cuff", "Menottes", "Menotte", "Handcuffs", "Handcuff",
    "Couteau", "Couteaux", "Knife", "Butcher Knife", "Batte", "Bat", "Hache", "Axe",
    "Pistolet", "Gun", "Pistol", "Marteau", "Hammer", "pe", "Epee", "Sword", "Sabre", "Dague", "Dagger",
    "Casier", "Casiers", "Locker", "Lockers",
    "Gants", "Gant", "Gloves", "Boxing Gloves",
    "Alliance", "Bougie", "Candle", "Savon", "Soap", "Cl", "Cle", "Key",
}
local spawnerItemCache = {}
function CollectItemSnapshot()
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

function TokensOf(keyword)
    local tokens = {}
    for token in string.gmatch(keyword or "", "[^|]+") do
        local t = Normalize(token):gsub(" ", "")
        if t ~= "" then table.insert(tokens, t) end
    end
    return tokens
end

function NameMatchesTokens(name, tokens)
    local norm = Normalize(name):gsub(" ", "")
    if norm:find("ringbox", 1, true) then return false end
    for _, t in ipairs(tokens) do
        if norm:find(t, 1, true) then return true end
    end
    return false
end

function FindItemsByKeyword(keyword, includeCatalog)
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
--  END SPAWNER ENGINE 

--  CONTENT BUILDER 
function UpdateRightContent()
    ClearContent()

    -- ----------- HOME -----------
    if CurrentTab == "  Home" then
        local hero = Section(ContentScroll, "Welcome back", "")
        local greet = Label(hero, "sa7loul V3  Premium redesign", UITheme.TEXT, 17)
        greet.Font = Enum.Font.GothamBold
        Label(hero, "Survive the Killer  full feature suite  press RightShift to hide UI", UITheme.SUBTEXT, 11)
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

        local quick = Section(ContentScroll, "Quick access", "")
        Button(quick, " Player features", function() SwitchTab("  Player") end)
        Button(quick, "  Troll features", function() SwitchTab("  Troll") end)
        Button(quick, " Item spawner", function() SwitchTab("  Spawner") end)
        Button(quick, " Player list", function() SwitchTab("  Players") end)
        Button(quick, " Settings", function() SwitchTab("  Settings") end)

        local info = Section(ContentScroll, "Changelog V3", "")
        local changelog = {
            " V3.2  Design rework & stability",
            " FIXED: full UI not building on some executors (load error)",
            " Reordered tabs: Home - Player - Revive - World - Players",
            " Minimize: small bar stays with  restore button",
            " NEW: Spawner tab (Ring Box / Sche-cheveux / Cuffs / Lockers)",
            " NEW: Jump Power, FOV, Fly+NoClip, TP to downed, random loot TP",
            " NEW: TP to target - Copy tools - Attack target",
            " Redesigned section cards + live status bar (FPS/Ping)",
            " Keybinds on every toggle - RGB mode - search bar",
            " Troll tab (fling, annoy, fake admin, ghost, earrape, click-TP)",
        }
        for _, line in ipairs(changelog) do
            Label(info, line, UITheme.SUBTEXT, 11)
        end
        Label(hero, "", UITheme.DIM, 5)
        Label(hero, "Developer: sa7loul    Tailored for STK v2.31.0", UITheme.DIM, 10)

    -- ----------- PLAYER -----------
    elseif CurrentTab == "  Player" then
        local movement = Section(ContentScroll, "Movement", "")
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
            text = "Speed", min = 16, max = 50, def = settings.Speed,
            onChanged = function(val)
                settings.Speed = val
                if settings.speedEnabled and lp.Character then
                    pcall(function() lp.Character.Humanoid.WalkSpeed = val end)
                end
            end
        })
        ToggleRow(movement, {
            text = "Disable speed when down", id = "speedoff",
            state = settings.speedDisableOnDown,
            onToggle = function(val) settings.speedDisableOnDown = val end
        })
        local flight = Section(ContentScroll, "Flight & NoClip", "plane")
        ToggleRow(flight, {
            text = "Flight", id = "fly", state = settings.Fly,
            desc = "WASD + Space / Left-Control",
            onToggle = function(val)
                settings.Fly = val
                UpdateFly()
            end
        })
        Slider(flight, {
            text = "Flight speed", min = 20, max = 200, def = settings.flySpeed,
            onChanged = function(val) settings.flySpeed = val end
        })
        Slider(flight, {
            text = "Vertical speed", min = 50, max = 300, def = 100,
            onChanged = function(val) settings.flyVertical = val / 100 end
        })
        ToggleRow(flight, {
            text = "Noclip", id = "noclip", state = settings.Noclip,
            desc = "Walk through walls, pairs with Flight",
            onToggle = function(val)
                settings.Noclip = val
                UpdateNoclip()
            end
        })
        Note(flight, "Fly + Noclip work together. Hold Left-Control to dive.")
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
        Button(movement, " Reset gravity (196.2)", function()
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

        local combat = Section(ContentScroll, "Combat", "")
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

        local powers = Section(ContentScroll, "Powers", "")
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
        Button(flyRow, { text = " Fly + NoClip", size = UDim2.new(0.48, 0, 0, 30), accent = true, callback = GiveFlyNoClip })
        Button(flyRow, { text = " Reset jump", size = UDim2.new(0.48, 0, 0, 30), callback = function()
            pcall(function()
                if lp.Character then
                    local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.JumpPower = 50 end
                    notif("Jump power reset to 50", 2)
                end
            end)
        end })

    -- ----------- WORLD -----------
    elseif CurrentTab == "  World" then
        local visuals = Section(ContentScroll, "Visuals", "")
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

        local camera = Section(ContentScroll, "Camera", "-")
        Slider(camera, {
            text = "Field of View", min = 55, max = 120, def = 70,
            onChanged = function(val)
                pcall(function() workspace.CurrentCamera.FieldOfView = val end)
            end
        })
        Button(camera, " Reset FOV (70)", function()
            pcall(function() workspace.CurrentCamera.FieldOfView = 70 end)
            notif("FOV reset to 70", 2)
        end)

        local quickTP = Section(ContentScroll, "Quick teleports", "")
        Button(quickTP, " Nearest downed player", function()
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
        Button(quickTP, " Random loot spot", function()
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

    -- ----------- PLAYERS -----------
    elseif CurrentTab == "  Players" then
        playerListContainer = Section(ContentScroll, "Player list", "")
        Note(playerListContainer, "Click a row to select - - bring -  TP -  fly - ' view -  freeze")
        local row = Instance.new("Frame")
        row.Parent = ContentScroll
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, 0, 0, 34)
        local rowLay = Instance.new("UIListLayout", row)
        rowLay.FillDirection = Enum.FillDirection.Horizontal
        rowLay.Padding = UDim.new(0, 6)
        Button(row, { text = " Refresh", size = UDim2.new(0.48, 0, 0, 30), callback = UpdatePlayerList })
        Button(row, { text = " Stop all", size = UDim2.new(0.48, 0, 0, 30), callback = function()
            StopView()
            StopBring()
            StopBringAll()
            notif("All operations stopped", 2)
        end })
        UpdatePlayerList()

    -- ----------- REVIVE -----------
    elseif CurrentTab == "  Revive" then
        local revive = Section(ContentScroll, "Revive modes", "")
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
        Button(revive, " Risky revive (one-time)", function() AutoReviveRiskyOneUse() end)

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
        Button(modeRow, { text = " Random", size = UDim2.new(0.48, 0, 0, 30), callback = function()
            settings.selfReviveMode = "Random"
            notif("Revive mode: Random", 2)
        end })
        Button(modeRow, { text = " Farthest", size = UDim2.new(0.48, 0, 0, 30), callback = function()
            settings.selfReviveMode = "Farthest"
            notif("Revive mode: Farthest", 2)
        end })

    -- ----------- FUN -----------
    elseif CurrentTab == "  Fun" then
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

        local actions = Section(ContentScroll, "Actions", "")
        local row1 = Instance.new("Frame")
        row1.Parent = actions
        row1.BackgroundTransparency = 1
        row1.Size = UDim2.new(1, 0, 0, 34)
        local lay1 = Instance.new("UIListLayout", row1)
        lay1.FillDirection = Enum.FillDirection.Horizontal
        lay1.Padding = UDim.new(0, 6)
        Button(row1, { text = " Fling", size = UDim2.new(0.48, 0, 0, 32), callback = function()
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
        Button(row1, { text = " Stop fling", size = UDim2.new(0.48, 0, 0, 32), callback = function()
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
        Button(row2, { text = " Freeze", size = UDim2.new(0.48, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if target then FreezePlayer(target.Name) else notif("Select a player first", 2) end
        end })
        Button(row2, { text = " Unfreeze", size = UDim2.new(0.48, 0, 0, 32), callback = function()
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
        Button(row3, { text = "' View", size = UDim2.new(0.48, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if target then StartView(target.Name) else notif("Select a player first", 2) end
        end })
        Button(row3, { text = " Stop view", size = UDim2.new(0.48, 0, 0, 32), callback = StopView })

        local row4 = Instance.new("Frame")
        row4.Parent = actions
        row4.BackgroundTransparency = 1
        row4.Size = UDim2.new(1, 0, 0, 34)
        local lay4 = Instance.new("UIListLayout", row4)
        lay4.FillDirection = Enum.FillDirection.Horizontal
        lay4.Padding = UDim.new(0, 6)
        Button(row4, { text = "- Bring", size = UDim2.new(0.48, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if target then StartBring(target.Name) else notif("Select a player first", 2) end
        end })
        Button(row4, { text = " Stop bring", size = UDim2.new(0.48, 0, 0, 32), callback = StopBring })

        local row5 = Instance.new("Frame")
        row5.Parent = actions
        row5.BackgroundTransparency = 1
        row5.Size = UDim2.new(1, 0, 0, 34)
        local lay5 = Instance.new("UIListLayout", row5)
        lay5.FillDirection = Enum.FillDirection.Horizontal
        lay5.Padding = UDim.new(0, 6)
        Button(row5, { text = "- Bring All", size = UDim2.new(0.31, 0, 0, 32), callback = StartBringAll })
        Button(row5, { text = " Unbring", size = UDim2.new(0.31, 0, 0, 32), callback = UnbringSelected })
        Button(row5, { text = " Stop", size = UDim2.new(0.31, 0, 0, 32), callback = StopBringAll })

        local row6 = Instance.new("Frame")
        row6.Parent = actions
        row6.BackgroundTransparency = 1
        row6.Size = UDim2.new(1, 0, 0, 34)
        local lay6 = Instance.new("UIListLayout", row6)
        lay6.FillDirection = Enum.FillDirection.Horizontal
        lay6.Padding = UDim.new(0, 6)
        Button(row6, { text = " TP to target", size = UDim2.new(0.31, 0, 0, 32), callback = function()
            local target = GetSelectedPlayer()
            if not target then notif("Select a player first", 2) return end
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 3)
                notif("TP to: " .. target.Name, 2)
            else
                notif("Player not found", 2)
            end
        end })
        Button(row6, { text = " Copy tools", size = UDim2.new(0.31, 0, 0, 32), callback = function()
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
        Button(row6, { text = " Attack target", size = UDim2.new(0.31, 0, 0, 32), callback = function()
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
        Button(row7, { text = " Admin fly/no-clip (remotes)", size = UDim2.new(1, 0, 0, 32), accent = true, callback = function()
            local target = GetSelectedPlayer()
            if not target then
                notif("Select a player first", 2)
                return
            end
            if TryFireAdminRemote(target) then
                notif("Admin remotes fired ' " .. target.Name, 2)
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

        -- - CUFF ITEMS  spawner / giver
        local cuffSection = Section(ContentScroll, "Cuff Items  Spawn / Give / Take", "-")
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
                cuffStatus.Text = "- No cuffs found  start a round & rescan"
                Label(cuffRows, "No cuff items in the game right now", UITheme.DIM, 11)
                return
            end
            cuffStatus.Text = "- Found " .. #names .. " cuff item(s)"
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
                    text = "  Spawn me", size = UDim2.new(0.3, 0, 0, 28), accent = true,
                    callback = function() SpawnCuffItemForMe(itemName) end
                })

                Button(row, {
                    text = "Give  " .. (selTarget and selTarget.Name or "None"),
                    size = UDim2.new(0.3, 0, 0, 28),
                    callback = function()
                        local target = GetSelectedPlayer()
                        if not target then
                            notif("Select a player first (' Player button)", 2)
                        else
                            GiveCuffItemToPlayer(itemName, target)
                        end
                    end
                })
            end
        end

        Button(cuffSection, " Rescan cuffs", RebuildCuffList)

        local cuffTargetBox = TextBox(cuffSection, { placeholder = "Give to player name (empty = selected)" })
        Button(cuffSection, " Give every cuff to target", function()
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
            notif("Gave - " .. given .. " cuff item(s)  " .. target.Name, 2)
        end)

        Button(cuffSection, "  Take cuffs from selected player", function()
            TakeCuffsFromTarget(GetSelectedPlayer())
        end)

        Button(cuffSection, "-' Remove my cuffs", RemoveMyCuffs)

        Note(cuffSection, "Auto-detects every item named with 'cuff' (backpacks, hands, map). Pick the target with  Home's player chip or the ' button in Actions.")
        task.defer(RebuildCuffList)

    -- ----------- SPAWNER -----------
    elseif CurrentTab == "  Spawner" then
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
                text = "Give ", size = UDim2.new(0.3, 0, 0, 28),
                callback = function()
                    local target = GetSelectedPlayer()
                    if not target then
                        notif("Pick a target first (' chip)", 2)
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
                    status.Text = title .. "  nothing found (start a round & rescan)"
                    Label(rows, "No items found for: " .. keyword, UITheme.DIM, 11)
                    return
                end
                status.Text = "Found " .. #names .. " item(s): " .. keyword
                for _, itemName in ipairs(names) do
                    MakeItemRow(rows, itemName)
                end
            end
            Button(section, " Rescan", function() CollectItemSnapshot(); rebuild() end)
            task.defer(rebuild)
            return section
        end

        local targetChipSection = Section(ContentScroll, "Target", "'")
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
        Note(targetChipSection, "Pick from the list  scroll it if there are many players")

        CollectItemSnapshot()

        BuildSpawnerCategory("Sche-cheveux (Hair Dryer)", "", "dryer|seche|cheveux|hair")
        BuildSpawnerCategory("Coupe-cheveux (Hair Cutter)", "", "cutter|coupe|rasoir|razor")
        BuildSpawnerCategory("Cuffs", "-", "cuff|menotte")
        BuildSpawnerCategory("Lockers", "-", "locker|casier")
        BuildSpawnerCategory("Gloves", "", "glove|gant")
        BuildSpawnerCategory("Weapons", "-", "knife|cutter|couteau|couteaux|axe|hache|hatchet|bat|batte|hammer|marteau|sword|epee|blade|gun|pistol|pistolet|rifle|fusil|shotgun|machete|machette|cleaver|wrench|dart|kunai|katana|weapon|arme|dague|sabre")

        local customSection = Section(ContentScroll, "Custom search", "")
        local customBox = TextBox(customSection, { placeholder = "Item keyword: e.g. key, candle, soap ..." })
        local customRows = Instance.new("Frame")
        customRows.Parent = customSection
        customRows.BackgroundTransparency = 1
        customRows.Size = UDim2.new(1, 0, 0, 0)
        customRows.AutomaticSize = Enum.AutomaticSize.Y
        customRows.LayoutOrder = #customSection:GetChildren()
        local customRowsLayout = Instance.new("UIListLayout", customRows)
        customRowsLayout.Padding = UDim.new(0, 6)
        customRowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        local function RebuildCustomBox()
            for _, child in ipairs(customRows:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
            end
            local kw = customBox.Text ~= "" and customBox.Text or nil
            if not kw then
                Label(customRows, "Type a keyword then press search", UITheme.DIM, 11)
                return
            end
            local names = ScanItemsByKeyword(kw)
            if #names == 0 then
                Label(customRows, "Nothing found for: " .. kw, UITheme.DIM, 11)
                return
            end
            for _, itemName in ipairs(names) do
                MakeItemRow(customRows, itemName)
            end
        end
        Button(customSection, " Search", RebuildCustomBox)

        local takeSection = Section(ContentScroll, "Take from target", " ")
        local takeBox = TextBox(takeSection, { placeholder = "Take keyword (empty = cuff), from selected player" })
        Button(takeSection, "  Take items", function()
            TakeSpawnItemsFromTarget(GetSelectedPlayer(), takeBox.Text ~= "" and takeBox.Text or "cuff")
        end)

        Note(ContentScroll, "Spawner clones the real in-game item for you or the chosen player. The ' chip above sets the give target.")

    -- ----------- TROLL -----------
    elseif CurrentTab == "  Troll" then
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
        Button(targetSection, " Refresh players", RefreshTrollTargetOptions)

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
        Button(flingSection, " Stop all troll actions", function()
            TrollFlingStop()
            TrollAnnoyStop()
            notif("Troll actions stopped", 2)
        end)

        local chatSection = Section(ContentScroll, "Fake Admin / System Chat", "'")
        local function fakeTargetName()
            local t = TrollGetTarget()
            return t and t.Name or "Player"
        end
        Button(chatSection, "  Fake ban notice", function()
            FakeSystemMessage("[SYSTEM] " .. fakeTargetName() .. " has been banned by an administrator.", Color3.fromRGB(255, 90, 90))
            FakeNotification("Administrator", fakeTargetName() .. " was banned. Reason: Toxic Behavior", 4)
        end)
        Button(chatSection, "' Fake kick notice", function()
            FakeSystemMessage("[SYSTEM] " .. fakeTargetName() .. " was kicked from the server.", Color3.fromRGB(255, 170, 70))
        end)
        Button(chatSection, " Fake server restart", function()
            FakeSystemMessage("[SYSTEM] Server restarting in 10 seconds. Reason: scheduled maintenance.", Color3.fromRGB(255, 120, 60))
            FakeNotification("Server", "Restarting in 10s...", 5)
        end)
        Button(chatSection, "- Fake admin join", function()
            FakeSystemMessage(" sa7loul joined the server. Commands available: !fly !noclip !ban", UITheme.CYAN)
        end)
        local fakeBox = TextBox(chatSection, { placeholder = "Custom fake system message..." })
        Button(chatSection, " Send fake message", function()
            if fakeBox.Text ~= "" then
                FakeSystemMessage(fakeBox.Text, Color3.fromRGB(255, 255, 255))
                fakeBox.Text = ""
            else
                notif("Type a message first", 2)
            end
        end)
        Note(chatSection, "Messages are client-side (only you see them)")

        local adminRemoteSection = Section(ContentScroll, "Fake Admin (remotes)", "-")
        local adminCmdBox = TextBox(adminRemoteSection, { placeholder = "Command: fly / noclip / ban ... (empty = raw fire)" })
        Button(adminRemoteSection, " Fire to troll target", function()
            local t = TrollGetTarget()
            if not t then
                notif("Set a troll target first", 2)
                return
            end
            local cmd = adminCmdBox.Text ~= "" and adminCmdBox.Text or nil
            local fired = FakeAdminCommand(cmd, t.Name)
            notif(cmd and ("Fired '" .. cmd .. "' ' " .. t.Name .. " (" .. fired .. " ok)") or ("Raw fire ' " .. t.Name .. " (" .. fired .. " ok)"), 3)
        end)
        Note(adminRemoteSection, "Sends the command through every admin-looking remote it finds")

        local ghostSection = Section(ContentScroll, "Ghost & Tools", "'")
        ToggleRow(ghostSection, {
            text = "Ghost Mode", id = "ghost", state = TrollCfg.invis,
            desc = "Client-side invisibility for your character",
            onToggle = function(val)
                if val then TrollInvisStart() else TrollInvisStop() end
            end
        })
        ToggleRow(ghostSection, {
            text = "Sneaky Seat", id = "sneakyseat", state = TrollCfg.sneakySeat,
            desc = "Invisible seat  hidden while seated",
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
        Button(ghostSection, "- Bring Target", function()
            local t = TrollGetTarget()
            if t then
                StartBring(t.Name)
            else
                notif("Set a troll target first", 2)
            end
        end)

        local screenSection = Section(ContentScroll, "Screen Chaos", "'")
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
        Button(screenSection, " JUMPSCARE!", JumpScareBurst)

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

    -- ----------- BAN -----------
    elseif CurrentTab == "  Ban" then
        local banSection = Section(ContentScroll, "Ban Manager", "")
        Button(banSection, " Fetch ban list", FetchBanList)
        Button(banSection, " Unban all (list)", UnbanAllFromList)
        Button(banSection, " Scan storage", StorageScan)
        Button(banSection, "' Blast unban (all remotes)", BlastUnban)
        banBox = TextBox(banSection, { placeholder = "Unban by name / ID" })
        Button(banSection, " Unban this", function() DoUnban(banBox.Text) end)
        ToggleRow(banSection, {
            text = " Auto-unban on join", id = "autounban", state = autoUnbanOn,
            keybind = false,
            onToggle = function(val) autoUnbanOn = val end
        })
        ToggleRow(banSection, {
            text = " Auto rejoin on kick", id = "autorejoin", state = autoRejoinOn,
            keybind = false,
            onToggle = function(val) autoRejoinOn = val end
        })
        customBox = TextBox(banSection, { placeholder = "Fire custom: RemoteName,arg1,arg2" })
        Button(banSection, " Fire custom remote", FireCustomRemote)

        banListContainer = Section(ContentScroll, "Banned players", "")
        if #bannedCache > 0 then
            for _, name in ipairs(bannedCache) do
                Button(banListContainer, " " .. name, function() DoUnban(name) end)
            end
        else
            Label(banListContainer, "List empty  press Fetch", UITheme.DIM, 11)
        end
        if #storageDump > 0 then
            local storageSection = Section(ContentScroll, "Storage scan", "-")
            for _, line in ipairs(storageDump) do
                Label(storageSection, line, UITheme.SUBTEXT, 10)
            end
        end
        Note(ContentScroll, "You must be inside the server to fire bans (rejoin before kick)")

    -- ----------- EXTRAS -----------
    elseif CurrentTab == "  Extras" then
        local scriptsSection = Section(ContentScroll, "External scripts", "-")
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
            Button(scriptsSection, " " .. scriptData.name, function()
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
                Button(frameRow, { text = " " .. scriptData.name, size = UDim2.new(0.8, 0, 1, 0), callback = function()
                    notif("Loading: " .. scriptData.name, 2)
                    local success, err = pcall(function()
                        local func = loadstring(scriptData.script)
                        if func then func() else notif("Load failed", 3) end
                    end)
                    if not success and err then notif("Error: " .. tostring(err), 3) end
                end })
                Button(frameRow, { text = "Remove", size = UDim2.new(0.18, 0, 1, 0), callback = function()
                    RemoveUserScript(i)
                end })
            end
        end

    -- ----------- SETTINGS -----------
    elseif CurrentTab == "  Settings" then
        local keySection = Section(ContentScroll, "Keybinds", "")
        Note(keySection, "Click a chip on any toggle ' press the key you want. Backspace/Delete = clear.")
        ToggleRow(keySection, {
            text = "Menu Keybind", id = "menu", state = true,
            desc = "Hides / shows this menu (default RightShift)",
            keybind = true,
            onToggle = function(val)
                Window.Visible = val
            end
        })
        Button(keySection, "-' Reset ALL keybinds", function()
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

        local configSection = Section(ContentScroll, "Configs", "")
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
        Button(configRow, { text = "' Save", size = UDim2.new(0.32, -4, 1, 0), callback = function() SaveConfig(cfgName()) end })
        Button(configRow, { text = " Load", size = UDim2.new(0.32, -4, 1, 0), callback = function()
            LoadConfig(cfgName())
            KeybindsLib:Restore(settings.keybinds)
            UpdateRightContent()
        end })
        Button(configRow, { text = "-' Delete", size = UDim2.new(0.32, -4, 1, 0), callback = function() DeleteConfig(cfgName()) end })

        local configListSection = Section(ContentScroll, "Saved configs", "")
        local configsList = GetConfigList()
        if #configsList > 0 then
            for _, name in ipairs(configsList) do
                Button(configListSection, " " .. name, function()
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
        Button(unbanSection, " Try Unban", TryUnban)
        Button(unbanSection, " Rejoin fresh", RejoinFresh)
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
        ToggleRow(otherSection, {
            text = "Stream Proof", id = "streamproof", state = settings.StreamProof,
            onToggle = function(val)
                settings.StreamProof = val
                if val then
                    StartStreamProofDetection()
                    notif("Stream Proof: Enabled", 2)
                else
                    StopStreamProofDetection()
                    SetGuiVisibility(true)
                    notif("Stream Proof: Disabled", 2)
                end
            end
        })
        Button(otherSection, " Mic Bypass", ToggleMicBypass)
        Button(otherSection, " Unmute mic", UnmuteMic)

        local footer = Instance.new("Frame")
        footer.Parent = ContentScroll
        footer.BackgroundTransparency = 1
        footer.Size = UDim2.new(1, 0, 0, 60)
        footer.LayoutOrder = 999999
        Label(footer, "Supports STK v2.31.0    sa7loul V3 Premium", UITheme.SUBTEXT, 11)
        Label(footer, "Keep it cute, keep it clean -", UITheme.CYAN, 11)
    end
end

--  INIT 
BuildSidebar()
CurrentTab = "  Home"
RefreshTabVisuals()
UpdateRightContent()

-- click-TP dispatcher
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    if CurrentTab == "  Players" then UpdatePlayerList() end
    if CurrentTab == "  Spawner" or CurrentTab == "  Fun" then pcall(UpdateRightContent) end
    RefreshTrollTargetOptions()
end)
PlayersSvc.PlayerRemoving:Connect(function(player)
    task.wait(0.3)
    if CurrentTab == "  Players" then UpdatePlayerList() end
    if CurrentTab == "  Spawner" or CurrentTab == "  Fun" then pcall(UpdateRightContent) end
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

lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if settings.speedEnabled and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = settings.Speed
    end
    espCache = {}
    UpdateESP()
    UpdateDoubleJump()
    UpdateKillerChance()
    UpdateFly()
    UpdateNoclip()
    if TrollCfg.sneakySeat then
        task.wait(0.5)
        TrollSneakySeatStart()
    end
    if CurrentTab == "  Players" then
        task.wait(0.5)
        UpdatePlayerList()
    end
end)

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

UpdateNoFog()
UpdateESP()
UpdateESPExits()
UpdateESPTraps()
UpdateDoubleJump()
UpdateKillerChance()
UpdateAllFeatures()

notif(" sa7loul V3 Premium  loaded | RightShift hides menu", 4)
