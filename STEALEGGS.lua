local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local rebirthEvent = ReplicatedStorage
	:WaitForChild("Events")
	:WaitForChild("Rebirth")
local merchantEvent = ReplicatedStorage:WaitForChild("MerchantPurchase")

local rebirthEnabled = false
local merchantEnabled = false
local minimized = false
local unloaded = false
local closeArmed = false

local REBIRTH_INTERVAL = 1
local MERCHANT_INTERVAL = 300 -- 5 minutes

local FULL_SIZE = UDim2.fromOffset(240, 165)
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

local gui = Instance.new("ScreenGui")
gui.Name = "StealEggsGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = FULL_SIZE
frame.Position = UDim2.new(0.5, -120, 0.5, -82)
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

local function buyAllMerchant()
	for _, itemName in ipairs(merchantItems) do
		merchantEvent:FireServer(itemName)
		task.wait(0.1)
	end
end

rebirthToggle.MouseButton1Click:Connect(function()
	rebirthEnabled = not rebirthEnabled
	rebirthToggle.Text = "AUTO REBIRTH: " .. (rebirthEnabled and "ON" or "OFF")
	rebirthToggle.BackgroundColor3 = rebirthEnabled
		and Color3.fromRGB(45, 150, 75)
		or Color3.fromRGB(150, 45, 45)
end)

merchantToggle.MouseButton1Click:Connect(function()
	merchantEnabled = not merchantEnabled
	merchantToggle.Text = "AUTO MERCHANT: " .. (merchantEnabled and "ON" or "OFF")
	merchantToggle.BackgroundColor3 = merchantEnabled
		and Color3.fromRGB(45, 150, 75)
		or Color3.fromRGB(150, 45, 45)

	if merchantEnabled then
		task.spawn(buyAllMerchant) -- buy instantly on enable
	end
end)

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	rebirthToggle.Visible = not minimized
	merchantToggle.Visible = not minimized
	frame.Size = minimized and MINI_SIZE or FULL_SIZE
	minimize.Text = minimized and "+" or "−"
end)

close.MouseButton1Click:Connect(function()
	if closeArmed then
		unloaded = true
		rebirthEnabled = false
		merchantEnabled = false
		gui:Destroy()
		return
	end

	closeArmed = true
	close.Text = "?"
	close.BackgroundColor3 = Color3.fromRGB(220, 120, 35)

	task.delay(2, function()
		if unloaded then return end
		closeArmed = false
		close.Text = "X"
		close.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
	end)
end)

-- Auto Rebirth loop
task.spawn(function()
	while not unloaded do
		if rebirthEnabled then
			rebirthEvent:FireServer(1)
		end
		task.wait(REBIRTH_INTERVAL)
	end
end)

-- Auto Merchant loop (every 5 min)
task.spawn(function()
	while not unloaded do
		local elapsed = 0
		while elapsed < MERCHANT_INTERVAL and not unloaded do
			task.wait(1)
			elapsed += 1
		end
		if merchantEnabled and not unloaded then
			buyAllMerchant()
		end
	end
end)
