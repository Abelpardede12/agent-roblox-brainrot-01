-- BRAINROT BASE RUSH -- client HUD.
-- A ScreenGui over the 3D world: Cash and income up top (kept clear of the
-- top-left corner where Roblox draws its own menu), the tsunami countdown,
-- Shop and Rebirth buttons, a carrying indicator and event notifications.
-- The client only displays and asks; the server owns every number.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyEggRemote = remotes:WaitForChild("BuyEgg")
local rebirthRemote = remotes:WaitForChild("RequestRebirth")
local notifyRemote = remotes:WaitForChild("Notify")
local waveRemote = remotes:WaitForChild("WaveState")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function rounded(frame, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = frame
end

local function makeLabel(parent, name, size, position, anchor, color, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor or Vector2.new(0.5, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.TextSize = textSize
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.Parent = parent
	return label
end

-- Top-center money panel.
local panel = Instance.new("Frame")
panel.Name = "MoneyPanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 8)
panel.Size = UDim2.fromOffset(340, 74)
panel.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
panel.BackgroundTransparency = 0.25
panel.BorderSizePixel = 0
panel.Parent = gui
rounded(panel, 14)

local cashLabel = makeLabel(panel, "Cash", UDim2.new(1, 0, 0, 42), UDim2.new(0.5, 0, 0, 2),
	Vector2.new(0.5, 0), Color3.fromRGB(120, 255, 140), 32)
local incomeLabel = makeLabel(panel, "Income", UDim2.new(1, 0, 0, 26), UDim2.new(0.5, 0, 0, 44),
	Vector2.new(0.5, 0), Color3.fromRGB(255, 230, 120), 20)

-- Top-right rebirth chip.
local rebirthChip = Instance.new("Frame")
rebirthChip.Name = "RebirthChip"
rebirthChip.AnchorPoint = Vector2.new(1, 0)
rebirthChip.Position = UDim2.new(1, -10, 0, 8)
rebirthChip.Size = UDim2.fromOffset(170, 40)
rebirthChip.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
rebirthChip.BackgroundTransparency = 0.25
rebirthChip.BorderSizePixel = 0
rebirthChip.Parent = gui
rounded(rebirthChip, 12)
local rebirthLabel = makeLabel(rebirthChip, "Rebirths", UDim2.new(1, 0, 1, 0), UDim2.new(0.5, 0, 0, 0),
	Vector2.new(0.5, 0), Color3.fromRGB(230, 190, 255), 20)

-- Tsunami chip under the money panel.
local waveChip = Instance.new("Frame")
waveChip.Name = "WaveChip"
waveChip.AnchorPoint = Vector2.new(0.5, 0)
waveChip.Position = UDim2.new(0.5, 0, 0, 90)
waveChip.Size = UDim2.fromOffset(340, 38)
waveChip.BackgroundColor3 = Color3.fromRGB(30, 80, 140)
waveChip.BackgroundTransparency = 0.25
waveChip.BorderSizePixel = 0
waveChip.Parent = gui
rounded(waveChip, 12)
local waveLabel = makeLabel(waveChip, "Wave", UDim2.new(1, 0, 1, 0), UDim2.new(0.5, 0, 0, 0),
	Vector2.new(0.5, 0), Color3.fromRGB(255, 255, 255), 21)

-- Bottom-right action buttons.
local function makeButton(name, position, color, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = position
	button.Size = UDim2.fromOffset(230, 56)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.FredokaOne
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.TextStrokeTransparency = 0.5
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = gui
	rounded(button, 14)
	return button
end

local eggButton = makeButton("BuyEgg", UDim2.new(1, -10, 1, -76), Color3.fromRGB(40, 170, 80),
	string.format("BELI TELUR - %s", Config.FormatCash(Config.EggPrice)))
local rebirthButton = makeButton("Rebirth", UDim2.new(1, -10, 1, -10), Color3.fromRGB(140, 70, 220), "REBIRTH")

eggButton.MouseButton1Click:Connect(function()
	buyEggRemote:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)

-- Bottom-center carrying indicator.
local carryLabel = makeLabel(gui, "Carrying", UDim2.fromOffset(560, 34), UDim2.new(0.5, 0, 1, -44),
	Vector2.new(0.5, 1), Color3.fromRGB(255, 255, 255), 21)

-- Center notification banner.
local notifyFrame = Instance.new("Frame")
notifyFrame.Name = "Notify"
notifyFrame.AnchorPoint = Vector2.new(0.5, 0)
notifyFrame.Position = UDim2.new(0.5, 0, 0, 150)
notifyFrame.Size = UDim2.fromOffset(620, 52)
notifyFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
notifyFrame.BackgroundTransparency = 1
notifyFrame.BorderSizePixel = 0
notifyFrame.Parent = gui
rounded(notifyFrame, 14)
local notifyLabel = makeLabel(notifyFrame, "Text", UDim2.new(1, -16, 1, 0), UDim2.new(0.5, 0, 0, 0),
	Vector2.new(0.5, 0), Color3.fromRGB(255, 255, 255), 22)
notifyLabel.TextTransparency = 1

local notifyToken = 0
notifyRemote.OnClientEvent:Connect(function(text)
	notifyToken += 1
	local token = notifyToken
	notifyLabel.Text = text
	notifyFrame.BackgroundTransparency = 0.25
	notifyLabel.TextTransparency = 0
	task.wait(3.2)
	if token == notifyToken then
		TweenService:Create(notifyFrame, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(notifyLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
	end
end)

-- Wave state from the server.
local wavePhase = "idle"
local waveSeconds = Config.WaveIdleSeconds
waveRemote.OnClientEvent:Connect(function(phase, secondsLeft)
	wavePhase = phase
	waveSeconds = secondsLeft
end)

local function formatTime(s)
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

-- Refresh loop.
local stats = player:WaitForChild("leaderstats")
local cashValue = stats:WaitForChild("Cash")
local rebirthValue = stats:WaitForChild("Rebirths")

while true do
	cashLabel.Text = "Cash: " .. Config.FormatCash(cashValue.Value)
	local income = player:GetAttribute("IncomePerSec") or 0
	local rebirths = rebirthValue.Value
	incomeLabel.Text = string.format("+%s / detik  (x%d rebirth)", Config.FormatCash(income), Config.IncomeMultiplier(rebirths))
	rebirthLabel.Text = string.format("Rebirth: %d", rebirths)
	rebirthButton.Text = string.format("REBIRTH - %s", Config.FormatCash(Config.RebirthCost(rebirths)))

	local carrying = player:GetAttribute("Carrying")
	if carrying and carrying ~= "" then
		carryLabel.Text = "Membawa: " .. carrying .. " - sentuh pad kosong di base-mu!"
	else
		carryLabel.Text = "Sentuh brainrot liar di jalan untuk menangkapnya!"
	end

	if wavePhase == "warning" then
		waveChip.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		waveLabel.Text = string.format("TSUNAMI %s - PULANG KE BASE!", formatTime(waveSeconds))
	elseif wavePhase == "sweep" then
		waveChip.BackgroundColor3 = Color3.fromRGB(30, 110, 220)
		waveLabel.Text = "TSUNAMI LEWAT! Tahan di base!"
	else
		waveChip.BackgroundColor3 = Color3.fromRGB(30, 80, 140)
		waveLabel.Text = "Tsunami berikutnya: " .. formatTime(waveSeconds)
	end

	task.wait(0.2)
end
