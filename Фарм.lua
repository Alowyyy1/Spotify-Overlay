-- Made by RIP#6666

-- FPSBooster: запускается автоматически при старте скрипта
_G.Settings = {
    Players = {
        ["Ignore Me"] = true,
        ["Ignore Others"] = true
    },
    Meshes = {
        Destroy = false,
        LowDetail = true
    },
    Images = {
        Invisible = true,
        LowDetail = false,
        Destroy = false,
    },
    ["No Particles"] = true,
    ["No Camera Effects"] = true,
    ["No Explosions"] = true,
    ["No Clothes"] = true,
    ["Low Water Graphics"] = true,
    ["No Shadows"] = true,
    ["Low Rendering"] = true,
    ["Low Quality Parts"] = true
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/CasperFlyModz/discord.gg-rips/main/FPSBooster.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local points = {
    {
        name = "Тауэр",
        cf = CFrame.new(
            -799.108093, 70.9666443, -714.930481,
            -0.735691309, -0.00431889528, 0.677303553,
            1.27888768e-06, 0.999979734, 0.00637768721,
            -0.677317381, 0.00469300849, -0.735676289
        )
    }
}

local teleportActive = true
local selectedPoint = 1
local running = true
local hpThreshold = 99 -- Дефолтное значение, теперь можно менять через UI

local targetPlayerName = ""
local killLimit = 0
local killLimitEnabled = false
local initialKills = 0
local stopTeleportOnLimit = false

local menuVisible = true
local connections = {}

local function fadeMenu(frame, show)
    frame.Visible = show
end

local function hideOtherCharacters()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character.Parent == Workspace then
            plr.Character.Parent = nil
        end
    end
end

local function checkKillLimit()
    if not killLimitEnabled or targetPlayerName == "" or killLimit <= 0 then
        stopTeleportOnLimit = false
        return true
    end
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer then
        stopTeleportOnLimit = false
        return true
    end
    local leaderstats = targetPlayer:FindFirstChild("leaderstats")
    local kills = leaderstats and leaderstats:FindFirstChild("Kills")
    local currentKills = kills and kills.Value or 0
    if currentKills - initialKills >= killLimit then
        stopTeleportOnLimit = true
        teleportActive = false
        return false
    end
    stopTeleportOnLimit = false
    return true
end

local function resetKillCounter()
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if targetPlayer then
        local leaderstats = targetPlayer:FindFirstChild("leaderstats")
        local kills = leaderstats and leaderstats:FindFirstChild("Kills")
        initialKills = kills and kills.Value or 0
    end
    killLimitEnabled = true
end

local function teleport()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if char and hrp then
        hrp.CFrame = points[selectedPoint].cf
        hideOtherCharacters()
    end
end

local function autoKillOnLimit()
    while running do
        if killLimitEnabled and targetPlayerName ~= "" and killLimit > 0 then
            local targetPlayer = Players:FindFirstChild(targetPlayerName)
            if targetPlayer and targetPlayer.Character then
                local leaderstats = targetPlayer:FindFirstChild("leaderstats")
                local kills = leaderstats and leaderstats:FindFirstChild("Kills")
                local currentKills = kills and kills.Value or 0
                if currentKills - initialKills >= killLimit then
                    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid.Health = 0
                    end
                end
            end
        end
        wait(0.2)
    end
end
spawn(autoKillOnLimit)

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "TeleportMenuUI"
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 320) -- увеличено для нового окна
frame.Position = UDim2.new(0.2, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 45, 70)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Visible = menuVisible
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 32)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 0.8
title.BackgroundColor3 = Color3.fromRGB(60, 90, 180)
title.Text = "Телепорт-меню"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0

local teleportStatusLabel = Instance.new("TextLabel")
teleportStatusLabel.Parent = frame
teleportStatusLabel.Size = UDim2.new(1, 0, 0, 22)
teleportStatusLabel.Position = UDim2.new(0, 0, 0, 32)
teleportStatusLabel.BackgroundTransparency = 1
teleportStatusLabel.Text = "Статус телепорта: включен"
teleportStatusLabel.TextColor3 = Color3.fromRGB(180,255,180)
teleportStatusLabel.TextSize = 15
teleportStatusLabel.Font = Enum.Font.GothamBold

local btn = Instance.new("TextButton")
btn.Parent = frame
btn.Size = UDim2.new(1, -20, 0, 32)
btn.Position = UDim2.new(0, 10, 0, 54)
btn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
btn.Text = points[1].name
btn.TextSize = 19
btn.TextColor3 = Color3.new(1,1,1)
btn.Font = Enum.Font.Gotham
btn.BorderSizePixel = 0
btn.AutoButtonColor = true
btn.MouseButton1Click:Connect(function()
    selectedPoint = 1
    teleport()
end)

local playerNameLabel = Instance.new("TextLabel")
playerNameLabel.Parent = frame
playerNameLabel.Size = UDim2.new(1, -20, 0, 20)
playerNameLabel.Position = UDim2.new(0, 10, 0, 94)
playerNameLabel.BackgroundTransparency = 1
playerNameLabel.Text = "Ник игрока:"
playerNameLabel.TextColor3 = Color3.new(1,1,1)
playerNameLabel.TextSize = 15
playerNameLabel.Font = Enum.Font.Gotham

local playerNameTextBox = Instance.new("TextBox")
playerNameTextBox.Parent = frame
playerNameTextBox.Size = UDim2.new(1, -20, 0, 25)
playerNameTextBox.Position = UDim2.new(0, 10, 0, 116)
playerNameTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
playerNameTextBox.TextColor3 = Color3.new(1,1,1)
playerNameTextBox.Text = targetPlayerName
playerNameTextBox.PlaceholderText = "Введите ник"
playerNameTextBox.TextSize = 15
playerNameTextBox.Font = Enum.Font.Gotham
playerNameTextBox.BorderSizePixel = 1

local killLimitLabel = Instance.new("TextLabel")
killLimitLabel.Parent = frame
killLimitLabel.Size = UDim2.new(1, -20, 0, 20)
killLimitLabel.Position = UDim2.new(0, 10, 0, 146)
killLimitLabel.BackgroundTransparency = 1
killLimitLabel.Text = "Лимит килов:"
killLimitLabel.TextColor3 = Color3.new(1,1,1)
killLimitLabel.TextSize = 15
killLimitLabel.Font = Enum.Font.Gotham

local killLimitTextBox = Instance.new("TextBox")
killLimitTextBox.Parent = frame
killLimitTextBox.Size = UDim2.new(1, -20, 0, 25)
killLimitTextBox.Position = UDim2.new(0, 10, 0, 168)
killLimitTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
killLimitTextBox.TextColor3 = Color3.new(1,1,1)
killLimitTextBox.Text = tostring(killLimit)
killLimitTextBox.PlaceholderText = "Введите лимит"
killLimitTextBox.TextSize = 15
killLimitTextBox.Font = Enum.Font.Gotham
killLimitTextBox.BorderSizePixel = 1

-- Новый UI для минимального HP (урон)
local minHPLabel = Instance.new("TextLabel")
minHPLabel.Parent = frame
minHPLabel.Size = UDim2.new(1, -20, 0, 20)
minHPLabel.Position = UDim2.new(0, 10, 0, 198)
minHPLabel.BackgroundTransparency = 1
minHPLabel.Text = "Мин. HP для автосмерти:"
minHPLabel.TextColor3 = Color3.new(1,1,1)
minHPLabel.TextSize = 15
minHPLabel.Font = Enum.Font.Gotham

local minHPTextBox = Instance.new("TextBox")
minHPTextBox.Parent = frame
minHPTextBox.Size = UDim2.new(0.6, -10, 0, 25)
minHPTextBox.Position = UDim2.new(0, 10, 0, 220)
minHPTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
minHPTextBox.TextColor3 = Color3.new(1,1,1)
minHPTextBox.Text = tostring(hpThreshold)
minHPTextBox.PlaceholderText = "1-99"
minHPTextBox.TextSize = 15
minHPTextBox.Font = Enum.Font.Gotham
minHPTextBox.BorderSizePixel = 1

local applyHPButton = Instance.new("TextButton")
applyHPButton.Parent = frame
applyHPButton.Size = UDim2.new(0.4, -10, 0, 25)
applyHPButton.Position = UDim2.new(0.6, 20, 0, 220)
applyHPButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
applyHPButton.Text = "Apply"
applyHPButton.TextSize = 15
applyHPButton.Font = Enum.Font.GothamBold
applyHPButton.TextColor3 = Color3.new(1,1,1)
applyHPButton.BorderSizePixel = 0
applyHPButton.AutoButtonColor = true

applyHPButton.MouseButton1Click:Connect(function()
    local num = tonumber(minHPTextBox.Text)
    if num and num >= 1 and num <= 99 then
        hpThreshold = math.floor(num)
        minHPTextBox.Text = tostring(hpThreshold)
        minHPTextBox.BackgroundColor3 = Color3.fromRGB(50, 70, 50)
    else
        minHPTextBox.Text = tostring(hpThreshold)
        minHPTextBox.BackgroundColor3 = Color3.fromRGB(70, 50, 50)
    end
end)

local resetButton = Instance.new("TextButton")
resetButton.Parent = frame
resetButton.Size = UDim2.new(1, -20, 0, 28)
resetButton.Position = UDim2.new(0, 10, 0, 250)
resetButton.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
resetButton.Text = "Reset (сбросить счетчик)"
resetButton.TextSize = 14
resetButton.Font = Enum.Font.GothamBold
resetButton.TextColor3 = Color3.new(1,1,1)
resetButton.AutoButtonColor = true
resetButton.BorderSizePixel = 0

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = frame
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 282)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Статус: лимит не установлен"
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.Gotham

local function updateStatus()
    if stopTeleportOnLimit then
        teleportStatusLabel.Text = "Статус телепорта: ОТКЛЮЧЕН (лимит достигнут)"
        teleportStatusLabel.TextColor3 = Color3.fromRGB(255,60,60)
        statusLabel.Text = "Статус: лимит достигнут, автотелепорт выключен!"
        statusLabel.TextColor3 = Color3.fromRGB(255,60,60)
        return
    end
    if not killLimitEnabled or targetPlayerName == "" or killLimit <= 0 then
        teleportStatusLabel.Text = teleportActive and "Статус телепорта: ВКЛЮЧЕН" or "Статус телепорта: ВЫКЛЮЧЕН"
        teleportStatusLabel.TextColor3 = teleportActive and Color3.fromRGB(180,255,180) or Color3.fromRGB(255,60,60)
        statusLabel.Text = "Статус: лимит не установлен"
        statusLabel.TextColor3 = Color3.new(1,1,1)
        return
    end
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    local leaderstats = targetPlayer and targetPlayer:FindFirstChild("leaderstats")
    local kills = leaderstats and leaderstats:FindFirstChild("Kills")
    local currentKills = kills and kills.Value or 0
    local remaining = killLimit - (currentKills - initialKills)
    if remaining > 0 then
        teleportStatusLabel.Text = teleportActive and "Статус телепорта: ВКЛЮЧЕН" or "Статус телепорта: ВЫКЛЮЧЕН"
        teleportStatusLabel.TextColor3 = teleportActive and Color3.fromRGB(180,255,180) or Color3.fromRGB(255,60,60)
        statusLabel.Text = "Статус: осталось " .. remaining .. " килов"
        statusLabel.TextColor3 = Color3.fromRGB(90,255,90)
    else
        teleportStatusLabel.Text = "Статус телепорта: ОТКЛЮЧЕН (лимит достигнут)"
        teleportStatusLabel.TextColor3 = Color3.fromRGB(255,60,60)
        statusLabel.Text = "Статус: лимит достигнут, автотелепорт выключен!"
        statusLabel.TextColor3 = Color3.fromRGB(255,60,60)
    end
end

playerNameTextBox.FocusLost:Connect(function()
    targetPlayerName = playerNameTextBox.Text
    if targetPlayerName ~= "" and killLimit > 0 then
        resetKillCounter()
    end
    checkKillLimit()
    updateStatus()
end)

killLimitTextBox.FocusLost:Connect(function()
    local num = tonumber(killLimitTextBox.Text)
    if num and num > 0 then
        killLimit = math.floor(num)
        killLimitTextBox.Text = tostring(killLimit)
        if targetPlayerName ~= "" then
            resetKillCounter()
        end
    else
        killLimit = 0
        killLimitTextBox.Text = "0"
    end
    checkKillLimit()
    updateStatus()
end)

resetButton.MouseButton1Click:Connect(function()
    targetPlayerName = ""
    killLimit = 0
    playerNameTextBox.Text = ""
    killLimitTextBox.Text = "0"
    killLimitEnabled = false
    initialKills = 0
    stopTeleportOnLimit = false
    teleportActive = true
    updateStatus()
end)

spawn(function()
    while running do
        checkKillLimit()
        if teleportActive then
            teleport()
        end
        wait(8)
    end
end)

spawn(function()
    while running do
        updateStatus()
        wait(1)
    end
end)

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
        menuVisible = not menuVisible
        fadeMenu(frame, menuVisible)
    elseif not gameProcessed and input.KeyCode == Enum.KeyCode.U then
        teleportActive = not teleportActive
        updateStatus()
    end
end))

local deleting = false
local deleteHoldStart = 0
local deleteText
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.P and not deleting then
        deleting = true
        deleteHoldStart = tick()
        if not deleteText then
            deleteText = Instance.new("TextLabel")
            deleteText.Size = UDim2.new(1, 0, 0, 40)
            deleteText.Position = UDim2.new(0, 0, 0.45, 0)
            deleteText.BackgroundTransparency = 1
            deleteText.TextColor3 = Color3.new(1,0,0)
            deleteText.Font = Enum.Font.GothamBold
            deleteText.TextSize = 38
            deleteText.TextStrokeTransparency = 0.3
            deleteText.TextStrokeColor3 = Color3.new(0.3,0,0)
            deleteText.Text = ""
            deleteText.Parent = gui
        end
        deleteText.Text = "Удаление через 3"
        deleteText.Visible = true
        local conn, endConn
        conn = RunService.RenderStepped:Connect(function()
            if not running then if conn then conn:Disconnect() end return end
            local held = tick() - deleteHoldStart
            local left = 3 - held
            if left > 0 then
                deleteText.Text = "Удаление через " .. tostring(math.ceil(left))
            else
                running = false
                for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
                if conn then conn:Disconnect() end
                if endConn then endConn:Disconnect() end
                deleteText.Visible = false
                pcall(function() gui:Destroy() end)
                pcall(function() script:Destroy() end)
            end
        end)
        endConn = UserInputService.InputEnded:Connect(function(i)
            if i.KeyCode == Enum.KeyCode.P then
                deleting = false
                deleteText.Visible = false
                if conn then conn:Disconnect() end
                if endConn then endConn:Disconnect() end
            end
        end)
    end
end))

LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    if teleportActive then
        teleport()
    end
end)
if LocalPlayer.Character then
    wait(1)
    if teleportActive then
        teleport()
    end
end

local function setZeroHPOnKnock()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    while humanoid.Parent and running do
        if humanoid.Health > 0 and humanoid.Health < hpThreshold then
            humanoid.Health = 0
        end
        wait(0.2)
    end
end
LocalPlayer.CharacterAdded:Connect(function()
    spawn(setZeroHPOnKnock)
end)
if LocalPlayer.Character then
    spawn(setZeroHPOnKnock)
end