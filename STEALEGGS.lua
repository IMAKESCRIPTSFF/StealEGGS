local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local rebirthEvent = ReplicatedStorage
    :WaitForChild("Events")
    :WaitForChild("Rebirth")

local merchantEvent = ReplicatedStorage:WaitForChild("MerchantPurchase")

--------------------------------------------------
-- STATE
--------------------------------------------------

local rebirthEnabled = false
local merchantEnabled = false
local movementEnabled = false
local minimized = false
local unloaded = false
local closeArmed = false

local walkingToEgg = false
local outOfStockConnection = nil

-- Used to invalidate an old path after teleporting
local walkGeneration = 0

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local REBIRTH_INTERVAL = 1

local MERCHANT_INTERVAL = 10
local MERCHANT_ITEM_DELAY = 1

local TP_INTERVAL = 60
local TP_POSITION = Vector3.new(3, -19, -712)

local FULL_SIZE = UDim2.fromOffset(240, 210)
local MINI_SIZE = UDim2.fromOffset(240, 45)

local merchantItems = {
    "WinterEgg",
    "HeavenEgg",
    "HellEgg",
    "MagmaEgg",
    "Coin",
    "Luck",
    "Speed",
    "Mega"
}

--------------------------------------------------
-- GUI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "StealEggsGUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = FULL_SIZE
frame.Position = UDim2.new(0.5, -120, 0.5, -105)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 0, 45)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "STEAL EGGS"
title.TextColor3 = Color3.fromRGB(255, 215, 70)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(30, 30)
minimize.Position = UDim2.new(1, -68, 0, 7)
minimize.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
minimize.Text = "−"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 20
minimize.Parent = frame

Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 7)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 30)
close.Position = UDim2.new(1, -35, 0, 7)
close.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 15
close.Parent = frame

Instance.new("UICorner", close).CornerRadius = UDim.new(0, 7)

--------------------------------------------------
-- REBIRTH BUTTON
--------------------------------------------------

local rebirthToggle = Instance.new("TextButton")
rebirthToggle.Size = UDim2.new(1, -30, 0, 40)
rebirthToggle.Position = UDim2.fromOffset(15, 55)
rebirthToggle.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
rebirthToggle.Text = "AUTO REBIRTH: OFF"
rebirthToggle.TextColor3 = Color3.new(1, 1, 1)
rebirthToggle.Font = Enum.Font.GothamBold
rebirthToggle.TextSize = 15
rebirthToggle.Parent = frame

Instance.new("UICorner", rebirthToggle).CornerRadius = UDim.new(0, 8)

--------------------------------------------------
-- MERCHANT BUTTON
--------------------------------------------------

local merchantToggle = Instance.new("TextButton")
merchantToggle.Size = UDim2.new(1, -30, 0, 40)
merchantToggle.Position = UDim2.fromOffset(15, 105)
merchantToggle.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
merchantToggle.Text = "AUTO MERCHANT: OFF"
merchantToggle.TextColor3 = Color3.new(1, 1, 1)
merchantToggle.Font = Enum.Font.GothamBold
merchantToggle.TextSize = 15
merchantToggle.Parent = frame

Instance.new("UICorner", merchantToggle).CornerRadius = UDim.new(0, 8)

--------------------------------------------------
-- AUTOSTEAL BUTTON
--------------------------------------------------

local movementToggle = Instance.new("TextButton")
movementToggle.Size = UDim2.new(1, -30, 0, 40)
movementToggle.Position = UDim2.fromOffset(15, 155)
movementToggle.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
movementToggle.Text = "2 MIN WALK: OFF"
movementToggle.TextColor3 = Color3.new(1, 1, 1)
movementToggle.Font = Enum.Font.GothamBold
movementToggle.TextSize = 15
movementToggle.Parent = frame

Instance.new("UICorner", movementToggle).CornerRadius = UDim.new(0, 8)

--------------------------------------------------
-- OUT OF STOCK FILTER
--------------------------------------------------

local function hideOutOfStock(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        if obj.Text == "Out of stock!" then
            obj.Visible = false
        end
    end
end

local function setOutOfStockFilter(enabled)

    if outOfStockConnection then
        outOfStockConnection:Disconnect()
        outOfStockConnection = nil
    end

    if not enabled then
        return
    end

    -- Hide existing messages
    for _, obj in ipairs(playerGui:GetDescendants()) do
        hideOutOfStock(obj)
    end

    -- Hide new messages
    outOfStockConnection = playerGui.DescendantAdded:Connect(function(obj)

        task.defer(function()

            if merchantEnabled and not unloaded then
                hideOutOfStock(obj)
            end

        end)

    end)
end

--------------------------------------------------
-- MERCHANT
--------------------------------------------------

local function buyAllMerchant()

    for _, itemName in ipairs(merchantItems) do

        if not merchantEnabled or unloaded then
            break
        end

        merchantEvent:FireServer(itemName)

        task.wait(MERCHANT_ITEM_DELAY)
    end
end

--------------------------------------------------
-- FIND CLOSEST AUTUMN EGG
--------------------------------------------------

local function getClosestEgg()

    local eggsFolder = workspace:FindFirstChild("MyLocalEggs")

    if not eggsFolder then
        return nil
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return nil
    end

    local closestEgg = nil
    local closestDistance = math.huge

    for _, egg in ipairs(eggsFolder:GetChildren()) do

        if egg:IsA("MeshPart") and egg.Name == "Autumn Egg" then

            local distance =
                (root.Position - egg.Position).Magnitude

            if distance < closestDistance then

                closestDistance = distance
                closestEgg = egg

            end
        end
    end

    return closestEgg
end

--------------------------------------------------
-- WALK TO EGG
--------------------------------------------------

local function walkToClosestEgg()

    if unloaded or not movementEnabled then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    local humanoid =
        character:FindFirstChildOfClass("Humanoid")

    local root =
        character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then
        return
    end

    local egg = getClosestEgg()

    if not egg then
        return
    end

    walkingToEgg = true

    local currentGeneration = walkGeneration

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 4
    })

    local success = pcall(function()
        path:ComputeAsync(
            root.Position,
            egg.Position
        )
    end)

    if success and path.Status == Enum.PathStatus.Success then

        for _, waypoint in ipairs(path:GetWaypoints()) do

            if unloaded
                or not movementEnabled
                or currentGeneration ~= walkGeneration
                or not egg.Parent then

                walkingToEgg = false
                return
            end

            if waypoint.Action ==
                Enum.PathWaypointAction.Jump then

                humanoid.Jump = true
            end

            humanoid:MoveTo(waypoint.Position)

            -- Timeout instead of waiting forever
            local startTime = os.clock()

            while os.clock() - startTime < 2 do

                if unloaded
                    or not movementEnabled
                    or currentGeneration ~= walkGeneration
                    or not egg.Parent then

                    walkingToEgg = false
                    return
                end

                if
                    (root.Position - waypoint.Position).Magnitude
                    < 4
                then
                    break
                end

                task.wait(0.05)
            end
        end

    else

        if movementEnabled
            and currentGeneration == walkGeneration then

            humanoid:MoveTo(egg.Position)

        end
    end

    walkingToEgg = false
end

--------------------------------------------------
-- CONTINUOUS AUTOSTEAL LOOP
--------------------------------------------------

task.spawn(function()

    while not unloaded do

        if movementEnabled and not walkingToEgg then

            local egg = getClosestEgg()

            if egg then

                walkToClosestEgg()

                -- Wait for this egg to disappear
                while movementEnabled
                    and not unloaded
                    and egg.Parent do

                    task.wait(0.1)
                end

            else

                task.wait(0.25)

            end

        else

            task.wait(0.1)

        end
    end
end)

--------------------------------------------------
-- AUTO REBIRTH BUTTON
--------------------------------------------------

rebirthToggle.MouseButton1Click:Connect(function()

    rebirthEnabled = not rebirthEnabled

    rebirthToggle.Text =
        "AUTO REBIRTH: "
        .. (rebirthEnabled and "ON" or "OFF")

    rebirthToggle.BackgroundColor3 =
        rebirthEnabled
        and Color3.fromRGB(45, 150, 75)
        or Color3.fromRGB(150, 45, 45)

end)

--------------------------------------------------
-- AUTO MERCHANT BUTTON
--------------------------------------------------

merchantToggle.MouseButton1Click:Connect(function()

    merchantEnabled = not merchantEnabled

    merchantToggle.Text =
        "AUTO MERCHANT: "
        .. (merchantEnabled and "ON" or "OFF")

    merchantToggle.BackgroundColor3 =
        merchantEnabled
        and Color3.fromRGB(45, 150, 75)
        or Color3.fromRGB(150, 45, 45)

    setOutOfStockFilter(merchantEnabled)

    if merchantEnabled then
        task.spawn(buyAllMerchant)
    end
end)

--------------------------------------------------
-- AUTOSTEAL TOGGLE
--------------------------------------------------

movementToggle.MouseButton1Click:Connect(function()

    movementEnabled = not movementEnabled

    movementToggle.Text =
        "2 MIN WALK: "
        .. (movementEnabled and "ON" or "OFF")

    movementToggle.BackgroundColor3 =
        movementEnabled
        and Color3.fromRGB(45, 150, 75)
        or Color3.fromRGB(150, 45, 45)

    -- Invalidate any old path when turning AutoSteal off
    if not movementEnabled then
        walkGeneration += 1
        walkingToEgg = false
    end

end)

--------------------------------------------------
-- MINIMIZE
--------------------------------------------------

minimize.MouseButton1Click:Connect(function()

    minimized = not minimized

    rebirthToggle.Visible = not minimized
    merchantToggle.Visible = not minimized
    movementToggle.Visible = not minimized

    frame.Size =
        minimized and MINI_SIZE or FULL_SIZE

    minimize.Text =
        minimized and "+" or "−"

end)

--------------------------------------------------
-- CLOSE
--------------------------------------------------

close.MouseButton1Click:Connect(function()

    if closeArmed then

        unloaded = true

        rebirthEnabled = false
        merchantEnabled = false
        movementEnabled = false

        walkGeneration += 1
        walkingToEgg = false

        if outOfStockConnection then

            outOfStockConnection:Disconnect()
            outOfStockConnection = nil

        end

        gui:Destroy()

        return
    end

    closeArmed = true

    close.Text = "?"
    close.BackgroundColor3 =
        Color3.fromRGB(220, 120, 35)

    task.delay(2, function()

        if unloaded then
            return
        end

        closeArmed = false

        close.Text = "X"
        close.BackgroundColor3 =
            Color3.fromRGB(160, 45, 45)

    end)

end)

--------------------------------------------------
-- AUTO REBIRTH LOOP
--------------------------------------------------

task.spawn(function()

    while not unloaded do

        if rebirthEnabled then
            rebirthEvent:FireServer(1)
        end

        task.wait(REBIRTH_INTERVAL)

    end
end)

--------------------------------------------------
-- AUTO MERCHANT LOOP
--------------------------------------------------

task.spawn(function()

    while not unloaded do

        task.wait(MERCHANT_INTERVAL)

        if merchantEnabled and not unloaded then
            task.spawn(buyAllMerchant)
        end

    end
end)

--------------------------------------------------
-- TELEPORT EVERY 60 SECONDS
-- ONLY WHILE AUTOSTEAL IS ON
--------------------------------------------------

task.spawn(function()

    while not unloaded do

        task.wait(TP_INTERVAL)

        if movementEnabled and not unloaded then

            -- Invalidate the old walking path
            walkGeneration += 1
            walkingToEgg = false

            local character = player.Character

            local root =
                character
                and character:FindFirstChild("HumanoidRootPart")

            if root then

                -- Teleport
                root.CFrame =
                    CFrame.new(TP_POSITION)

                -- Allow position to update
                task.wait(0.2)

                if movementEnabled and not unloaded then

                    -- Explicitly start searching again
                    local newEgg = getClosestEgg()

                    if newEgg then

                        task.spawn(function()

                            walkToClosestEgg()

                        end)

                    end
                end
            end
        end
    end
end)
