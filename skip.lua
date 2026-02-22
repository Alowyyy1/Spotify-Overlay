-- === Взрывы и KillCam (улучшенный вариант с логированием) ===
print("[auto_remove_and_skip_killcam] Запуск скрипта...")

-- === Сервисы ===
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- === Логирование ===
local function logInfo(msg)
    print("[INFO]", msg)
end

local function logWarn(msg)
    warn("[WARN]", msg)
end

local function logError(msg)
    warn("[ERROR]", msg)
end

-- === Удаляем Explosions и Explosives из Game Systems ===
local gameSystems = workspace:FindFirstChild("Game Systems")
if gameSystems then
    logInfo("Найден объект 'Game Systems' — начинаем обработку.")

    local function safeRemove(child)
        if child and (child.Name == "Explosions" or child.Name == "Explosives") then
            local ok, err = pcall(function()
                logInfo("Удаление объекта: " .. child.Name)
                child:Destroy()
            end)
            if not ok then
                logError("Не удалось удалить объект '" .. child.Name .. "': " .. tostring(err))
            end
        end
    end

    -- Удаляем существующие
    for _, child in ipairs(gameSystems:GetChildren()) do
        safeRemove(child)
    end

    -- Следим за появлением новых
    gameSystems.ChildAdded:Connect(function(child)
        task.wait(0.1)
        safeRemove(child)
    end)
else
    logWarn("Объект 'Game Systems' не найден! Возможно, он создается позже.")
end

-- === Автоматический скип KillCam ===
local KillCamSkipEvent_upvr
local success, err = pcall(function()
    KillCamSkipEvent_upvr = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("KillCamSkipEvent", 5)
end)

if not success or not KillCamSkipEvent_upvr then
    logError("Не удалось найти KillCamSkipEvent в ReplicatedStorage.Remotes! " .. tostring(err))
else
    logInfo("KillCamSkipEvent успешно найден.")
end

local function skipKillCam()
    logInfo("KillCamUI обнаружен — выполняется автоматический скип KillCam.")
    if KillCamSkipEvent_upvr then
        local ok, fireErr = pcall(function()
            KillCamSkipEvent_upvr:FireServer()
            task.wait(1)
            KillCamSkipEvent_upvr:FireServer()
        end)
        if not ok then
            logError("Ошибка при попытке скипнуть KillCam: " .. tostring(fireErr))
        else
            logInfo("KillCam успешно пропущен.")
        end
    else
        logWarn("KillCamSkipEvent отсутствует, пропуск KillCam невозможен.")
    end
end

-- Слушаем появление KillCamUI
PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "KillCamUI" then
        skipKillCam()
    end
end)

-- Проверяем, если KillCamUI уже открыт
if PlayerGui:FindFirstChild("KillCamUI") then
    skipKillCam()
end

-- === Отладка ACS Engine ошибок ===
logInfo("Добавляем обработчик ошибок для ACS Engine RemoteEvents.")
game:GetService("LogService").MessageOut:Connect(function(message, messageType)
    if string.find(message, "ACS_Engine") or string.find(message, "ReplicatedStorage") then
        logWarn("ACS Engine сообщение: " .. message)
    end
end)

-- === Сообщение об успешном запуске ===
print("[auto_remove_and_skip_killcam] Скрипт успешно запущен и активен!")
