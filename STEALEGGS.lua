--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// Remotes
local rebirthEvent = ReplicatedStorage
	:WaitForChild("Events")
	:WaitForChild("Rebirth")

local merchantEvent = ReplicatedStorage
	:WaitForChild("MerchantPurchase")

local collectEggEvent = ReplicatedStorage
	:WaitForChild("Events")
	:WaitForChild("CollectLocalEgg")

--// Settings
local REBIRTH_INTERVAL = 1
local MERCHANT_INTERVAL = 10
local MERCHANT_ITEM_DELAY = 1
local COLLECT_INTERVAL = 0.01

--// States
local rebirthEnabled = false
local merchantEnabled = false
local collectEnabled = false

--// Merchant items
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

--// Remove old GUI if it exists
local oldGui = playerGui:FindFirstChild("StealEggsGUI")
if oldGui then
	oldGui:Destroy()
end

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "StealEggsGUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

--// Main frame
local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(240, 210)
frame.Position = UDim2.new(0.5, -120, 0.5, -105)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = frame

--// Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -45, 0, 40)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "Automation"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

--// Minimize button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.fromOffset(30, 30)
minimizeButton.Position = UDim2.new(1, -70, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 20
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.BorderSizePixel = 0
minimizeButton.Parent = frame

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 7)
minimizeCorner.Parent = minimizeButton

--// Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(30, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 15
closeButton.Font = Enum.Font.GothamBold
closeButton.BorderSizePixel = 0
closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 7)
closeCorner.Parent = closeButton

--// Button creator
local function createToggle(name, text, y)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, -20, 0, 45)
	button.Position = UDim2.fromOffset(10, y)
	button.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
	button.Text = text .. ": OFF"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 15
	button.Font = Enum.Font.GothamBold
	button.BorderSizePixel = 0
	button.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

--// Buttons
local rebirthButton = createToggle(
	"AutoRebirth",
	"Auto Rebirth",
	45
)

local merchantButton = createToggle(
	"AutoMerchant",
	"Auto Merchant",
	95
)

local collectButton = createToggle(
	"AutoCollect",
	"Auto Collect Egg",
	145
)

--// Button state updater
local function updateButton(button, text, state)
	if state then
		button.Text = text .. ": ON"
		button.BackgroundColor3 = Color3.fromRGB(45, 170, 75)
	else
		button.Text = text .. ": OFF"
		button.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
	end
end

--// Auto Rebirth
rebirthButton.MouseButton1Click:Connect(function()
	rebirthEnabled = not rebirthEnabled

	updateButton(
		rebirthButton,
		"Auto Rebirth",
		rebirthEnabled
	)
end)

task.spawn(function()
	while gui.Parent do
		if rebirthEnabled then
			pcall(function()
				rebirthEvent:FireServer(1)
			end)
		end

		task.wait(REBIRTH_INTERVAL)
	end
end)

--// Auto Merchant
merchantButton.MouseButton1Click:Connect(function()
	merchantEnabled = not merchantEnabled

	updateButton(
		merchantButton,
		"Auto Merchant",
		merchantEnabled
	)
end)

task.spawn(function()
	while gui.Parent do
		if merchantEnabled then
			for _, item in ipairs(merchantItems) do
				if not merchantEnabled then
					break
				end

				pcall(function()
					merchantEvent:FireServer(item)
				end)

				task.wait(MERCHANT_ITEM_DELAY)
			end

			-- Wait before starting the next merchant cycle
			local elapsed = 0

			while merchantEnabled and elapsed < MERCHANT_INTERVAL do
				task.wait(0.1)
				elapsed += 0.1
			end
		else
			task.wait(0.1)
		end
	end
end)

--// Auto Collect Local Egg
collectButton.MouseButton1Click:Connect(function()
	collectEnabled = not collectEnabled

	updateButton(
		collectButton,
		"Auto Collect Egg",
		collectEnabled
	)
end)

task.spawn(function()
	while gui.Parent do
		if collectEnabled then
			pcall(function()
				collectEggEvent:FireServer(
					"Zone10",
					"Autumn Egg"
				)
			end)
		end

		task.wait(COLLECT_INTERVAL)
	end
end)

--// Minimize
local minimized = false
local FULL_SIZE = UDim2.fromOffset(240, 210)
local MINI_SIZE = UDim2.fromOffset(240, 45)

minimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		frame.Size = MINI_SIZE

		title.Text = "Automation"

		rebirthButton.Visible = false
		merchantButton.Visible = false
		collectButton.Visible = false

		minimizeButton.Text = "+"
	else
		frame.Size = FULL_SIZE

		rebirthButton.Visible = true
		merchantButton.Visible = true
		collectButton.Visible = true

		minimizeButton.Text = "-"
	end
end)

--// Close
closeButton.MouseButton1Click:Connect(function()
	rebirthEnabled = false
	merchantEnabled = false
	collectEnabled = false

	gui:Destroy()
end)

--// Dragging
local dragging = false
local dragStart
local startPosition

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPosition = frame.Position
	end
end)

frame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local delta = input.Position - dragStart

	frame.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end)
