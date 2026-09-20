local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local rebirthEvent = ReplicatedStorage
	:WaitForChild("Events")
	:WaitForChild("Rebirth")

local merchantEvent = ReplicatedStorage
	:WaitForChild("MerchantPurchase")

--// STATES
local rebirthEnabled = false
local merchantEnabled = false
local movementEnabled = false
local minimized = false
local unloaded = false
local closeArmed = false

local walkingToEgg = false
local walkGeneration = 0
local outOfStockConnection = nil

--// SETTINGS
local REBIRTH_INTERVAL = 1

local MERCHANT_INTERVAL = 10
local MERCHANT_ITEM_DELAY = 1

local TP_INTERVAL = 45
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

--// GUI
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
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

--// TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 0, 40)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.Text = "STEAL EGGS"
title.TextColor3 = Color3.fromRGB(255, 210, 60)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

--// MINIMIZE
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.fromOffset(35, 30)
minimizeButton.Position = UDim2.new(1, -75, 0, 7)
minimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
minimizeButton.Text = "−"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 18
minimizeButton.Parent = frame

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 6)
minimizeCorner.Parent = minimizeButton

--// CLOSE
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(35, 30)
closeButton.Position = UDim2.new(1, -38, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

--// BUTTON CREATOR
local function createToggle(text, y)
	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1, -20, 0, 40)
	button.Position = UDim2.fromOffset(10, y)

	button.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
	button.TextColor3 = Color3.new(1, 1, 1)

	button.Text = text .. ": OFF"

	button.Font = Enum.Font.GothamBold
	button.TextSize = 15

	button.BorderSizePixel = 0
	button.Parent = frame

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 7)
	c.Parent = button

	return button
end

local rebirthToggle = createToggle("AUTO REBIRTH", 55)
local merchantToggle = createToggle("AUTO MERCHANT", 105)
local movementToggle = createToggle("2 MIN WALK", 155)

--// BUTTON STATE
local function updateButton(button, name, enabled)
	button.Text = name .. ": " .. (enabled and "ON" or "OFF")

	if enabled then
		button.BackgroundColor3 = Color3.fromRGB(45, 150, 75)
	else
		button.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
	end
end

--// OUT OF STOCK FILTER
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

	for _, obj in ipairs(playerGui:GetDescendants()) do
		hideOutOfStock(obj)
	end

	outOfStockConnection = playerGui.DescendantAdded:Connect(function(obj)
		task.defer(function()
			if merchantEnabled and not unloaded then
				hideOutOfStock(obj)
			end
		end)
	end)
end

--// MERCHANT
local function buyAllMerchant()
	for _, itemName in ipairs(merchantItems) do
		if unloaded or not merchantEnabled then
			break
		end

		pcall(function()
			merchantEvent:FireServer(itemName)
		end)

		task.wait(MERCHANT_ITEM_DELAY)
	end
end

--// GET CLOSEST AUTUMN EGG
local function getClosestEgg()
	local eggsFolder = workspace:FindFirstChild("MyLocalEggs")

	if not eggsFolder then
		return nil
	end

	local character = player.Character

	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root then
		return nil
	end

	local closestEgg = nil
	local closestDistance = math.huge

	for _, egg in ipairs(eggsFolder:GetChildren()) do
		if egg:IsA("MeshPart") and egg.Name == "Autumn Egg" then
			local distance = (root.Position - egg.Position).Magnitude

			if distance < closestDistance then
				closestDistance = distance
				closestEgg = egg
			end
		end
	end

	return closestEgg
end

--// WALK TO ONE EGG
local function walkToEgg(egg)
	if unloaded or not movementEnabled then
		return false
	end

	local character = player.Character

	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return false
	end

	if not egg or not egg.Parent then
		return false
	end

	local myGeneration = walkGeneration

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 4
	})

	local success = pcall(function()
		path:ComputeAsync(root.Position, egg.Position)
	end)

	--// If pathfinding fails, use MoveTo as fallback
	if not success or path.Status ~= Enum.PathStatus.Success then
		if unloaded or not movementEnabled or myGeneration ~= walkGeneration then
			return false
		end

		humanoid:MoveTo(egg.Position)

		local startTime = os.clock()

		while os.clock() - startTime < 5 do
			if unloaded or not movementEnabled then
				return false
			end

			if myGeneration ~= walkGeneration then
				return false
			end

			if not egg.Parent then
				return false
			end

			if (root.Position - egg.Position).Magnitude <= 5 then
				return true
			end

			task.wait(0.05)
		end

		return false
	end

	--// Follow path
	for _, waypoint in ipairs(path:GetWaypoints()) do

		if unloaded or not movementEnabled then
			return false
		end

		if myGeneration ~= walkGeneration then
			return false
		end

		if not egg.Parent then
			return false
		end

		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end

		humanoid:MoveTo(waypoint.Position)

		local startTime = os.clock()

		while os.clock() - startTime < 3 do

			if unloaded or not movementEnabled then
				return false
			end

			if myGeneration ~= walkGeneration then
				return false
			end

			if not egg.Parent then
				return false
			end

			if (root.Position - waypoint.Position).Magnitude <= 4 then
				break
			end

			task.wait(0.05)
		end
	end

	return true
end

--// AUTO STEAL LOOP
--// THIS NEVER ENDS WHILE AUTO STEAL IS ON
task.spawn(function()

	while not unloaded do

		if movementEnabled then

			if not walkingToEgg then

				local egg = getClosestEgg()

				if egg then
					walkingToEgg = true

					--// Walk to the current egg
					walkToEgg(egg)

					--// IMPORTANT:
					--// Do NOT wait for the old egg.
					--// Immediately search for another one.
					walkingToEgg = false
				else
					--// No egg currently available
					task.wait(0.25)
				end
			end

		else
			task.wait(0.1)
		end

		task.wait(0.05)
	end
end)

--// DEPOSIT TELEPORT LOOP
task.spawn(function()

	while not unloaded do

		task.wait(TP_INTERVAL)

		if unloaded then
			break
		end

		--// ONLY teleport while AutoSteal is enabled
		if movementEnabled then

			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if root then

				--// Invalidate whatever path is currently running
				walkGeneration += 1

				--// Allow the main loop to start again
				walkingToEgg = false

				--// Deposit
				root.CFrame = CFrame.new(TP_POSITION)

				--// Give Roblox a moment to update the character
				task.wait(0.25)

				--// IMPORTANT:
				--// We DO NOT manually start walking here.
				--// The permanent AutoSteal loop will automatically
				--// find the closest egg again.
			end
		end
	end
end)

--// AUTO REBIRTH
task.spawn(function()

	while not unloaded do

		if rebirthEnabled then

			pcall(function()
				rebirthEvent:FireServer(1)
			end)

			task.wait(REBIRTH_INTERVAL)

		else
			task.wait(0.1)
		end
	end
end)

--// AUTO MERCHANT
task.spawn(function()

	while not unloaded do

		if merchantEnabled then

			task.spawn(function()
				buyAllMerchant()
			end)

			task.wait(MERCHANT_INTERVAL)

		else
			task.wait(0.1)
		end
	end
end)

--// REBIRTH BUTTON
rebirthToggle.MouseButton1Click:Connect(function()

	if unloaded then
		return
	end

	rebirthEnabled = not rebirthEnabled

	updateButton(
		rebirthToggle,
		"AUTO REBIRTH",
		rebirthEnabled
	)
end)

--// MERCHANT BUTTON
merchantToggle.MouseButton1Click:Connect(function()

	if unloaded then
		return
	end

	merchantEnabled = not merchantEnabled

	updateButton(
		merchantToggle,
		"AUTO MERCHANT",
		merchantEnabled
	)

	--// Out-of-stock filter ONLY exists while merchant is enabled
	setOutOfStockFilter(merchantEnabled)

	--// Start an immediate purchase cycle
	if merchantEnabled then
		task.spawn(function()
			buyAllMerchant()
		end)
	end
end)

--// AUTO STEAL BUTTON
movementToggle.MouseButton1Click:Connect(function()

	if unloaded then
		return
	end

	movementEnabled = not movementEnabled

	updateButton(
		movementToggle,
		"2 MIN WALK",
		movementEnabled
	)

	if not movementEnabled then

		--// Cancel current walking operation
		walkGeneration += 1
		walkingToEgg = false

	else

		--// Force a fresh search immediately
		walkGeneration += 1
		walkingToEgg = false
	end
end)

--// MINIMIZE
minimizeButton.MouseButton1Click:Connect(function()

	if unloaded then
		return
	end

	minimized = not minimized

	if minimized then

		frame.Size = MINI_SIZE

		rebirthToggle.Visible = false
		merchantToggle.Visible = false
		movementToggle.Visible = false

		minimizeButton.Text = "+"
	else

		frame.Size = FULL_SIZE

		rebirthToggle.Visible = true
		merchantToggle.Visible = true
		movementToggle.Visible = true

		minimizeButton.Text = "−"
	end
end)

--// CLOSE
closeButton.MouseButton1Click:Connect(function()

	if unloaded then
		return
	end

	if not closeArmed then

		closeArmed = true

		closeButton.Text = "?"
		closeButton.BackgroundColor3 = Color3.fromRGB(180, 120, 35)

		task.delay(2, function()

			if not unloaded and closeArmed then

				closeArmed = false

				closeButton.Text = "X"
				closeButton.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
			end
		end)

		return
	end

	--// FULL SHUTDOWN
	unloaded = true

	rebirthEnabled = false
	merchantEnabled = false
	movementEnabled = false

	--// Cancel any current walk
	walkGeneration += 1
	walkingToEgg = false

	--// Remove stock filter
	if outOfStockConnection then
		outOfStockConnection:Disconnect()
		outOfStockConnection = nil
	end

	gui:Destroy()
end)

--// INITIAL STATES
updateButton(rebirthToggle, "AUTO REBIRTH", false)
updateButton(merchantToggle, "AUTO MERCHANT", false)
updateButton(movementToggle, "2 MIN WALK", false)
