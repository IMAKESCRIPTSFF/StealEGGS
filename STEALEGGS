local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local rebirthEvent = ReplicatedStorage
	:WaitForChild("Events")
	:WaitForChild("Rebirth")

local enabled = false
local minimized = false
local unloaded = false
local closeArmed = false
local interval = 1

local gui = Instance.new("ScreenGui")
gui.Name = "StealEggsGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 120)
frame.Position = UDim2.new(0.5, -120, 0.5, -60)
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

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -30, 0, 45)
toggle.Position = UDim2.fromOffset(15, 58)
toggle.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
toggle.Text = "AUTO REBIRTH: OFF"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 15
toggle.Parent = frame

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

toggle.MouseButton1Click:Connect(function()
	enabled = not enabled
	toggle.Text = "AUTO REBIRTH: " .. (enabled and "ON" or "OFF")
	toggle.BackgroundColor3 = enabled
		and Color3.fromRGB(45, 150, 75)
		or Color3.fromRGB(150, 45, 45)
end)

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	toggle.Visible = not minimized
	frame.Size = minimized
		and UDim2.fromOffset(240, 45)
		or UDim2.fromOffset(240, 120)
	minimize.Text = minimized and "+" or "−"
end)

close.MouseButton1Click:Connect(function()
	if closeArmed then
		unloaded = true
		enabled = false
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

task.spawn(function()
	while not unloaded do
		if enabled then
			rebirthEvent:FireServer(1)
		end
		task.wait(interval)
	end
end)
