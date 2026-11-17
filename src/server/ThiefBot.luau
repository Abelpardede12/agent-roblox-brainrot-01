-- THREAT 2 -- the MALING BOT. Every few minutes this NPC burglar runs at a
-- player's base, grabs the best brainrot on its pads and sprints for the
-- map edge. Touch him while he carries it and he drops it and flees;
-- if he reaches the edge, the brainrot is gone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))

local ThiefBot = {}

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = parent
	return p
end

local function buildBot(): (Model, Part)
	local model = Instance.new("Model")
	model.Name = "MalingBot"
	local dark = Color3.fromRGB(35, 35, 45)
	local root = part(model, "Root", Vector3.new(2.2, 2.6, 1.3), CFrame.new(0, 2.6, 0), dark)
	root.CanTouch = true
	for _, side in ipairs({ -1, 1 }) do
		part(model, "Leg", Vector3.new(0.8, 1.4, 0.9), CFrame.new(side * 0.55, 0.7, 0), Color3.fromRGB(20, 20, 28))
		local eye = part(model, "Eye", Vector3.new(0.3, 0.3, 0.3), CFrame.new(side * 0.4, 4.35, 0.62),
			Color3.fromRGB(255, 255, 255))
		eye.Shape = Enum.PartType.Ball
	end
	local head = part(model, "Head", Vector3.new(1.9, 1.7, 1.9), CFrame.new(0, 4.3, 0), Color3.fromRGB(240, 200, 160))
	head.Shape = Enum.PartType.Ball
	part(model, "Mask", Vector3.new(2, 0.6, 2), CFrame.new(0, 4.45, 0), Color3.fromRGB(15, 15, 20), Enum.Material.SmoothPlastic)
	local sack = part(model, "Sack", Vector3.new(1.8, 2, 1.2), CFrame.new(0, 3, -1.1), Color3.fromRGB(150, 120, 80))
	sack.Shape = Enum.PartType.Ball

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(200, 44)
	gui.StudsOffset = Vector3.new(0, 6.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 70, 70)
	label.TextStrokeTransparency = 0.3
	label.Text = "MALING BOT!"
	label.Parent = gui

	model.PrimaryPart = root
	-- Ground-origin placement, the same convention as BrainrotFactory:
	-- parts are built around (0, 0, 0) and re-posed from their local CFrames.
	local parts = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, { part = descendant, localCFrame = descendant.CFrame })
		end
	end
	return model, root, parts
end

local botGround = CFrame.new(0, 0, -1000)
local botParts = {}

local function placeBot(groundCFrame: CFrame)
	botGround = groundCFrame
	for _, entry in ipairs(botParts) do
		entry.part.CFrame = groundCFrame * entry.localCFrame
	end
end

local function moveTowards(target: Vector3, speed: number, dt: number): number
	local pos = botGround.Position
	local delta = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
	local dist = delta.Magnitude
	if dist > 0.05 then
		local step = math.min(dist, speed * dt)
		local newPos = pos + delta.Unit * step
		local look = Vector3.new(newPos.X + delta.X, pos.Y, newPos.Z + delta.Z)
		placeBot(CFrame.lookAt(newPos, look))
	end
	return dist
end

-- hooks: { notifyAll(text), notifyPlayer(player, text),
--          stealFromPad(record), dropStolen(record, position), loseStolen(record) }
function ThiefBot.Start(hooks)
	State.thief.nextAt = os.clock() + Config.ThiefFirstSeconds

	local botModel, botRoot, parts = buildBot()
	botParts = parts
	botModel.Parent = Workspace
	placeBot(CFrame.new(0, 0, -1000)) -- parked far away until needed
	State.thief.model = botModel

	local touchDebounce = false
	botRoot.Touched:Connect(function(hit)
		if touchDebounce then
			return
		end
		local thief = State.thief
		if not thief.active or thief.phase ~= "flee" or not thief.record then
			return
		end
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		touchDebounce = true
		local record = thief.record
		thief.record = nil
		thief.phase = "escape"
		hooks.dropStolen(record, botGround.Position)
		hooks.notifyAll("Maling Bot menjatuhkan curiannya dan kabur!")
		task.wait(1)
		touchDebounce = false
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			local thief = State.thief
			if thief.active then
				continue
			end
			if os.clock() < thief.nextAt then
				continue
			end
			-- Pick the richest pad brainrot among present players.
			local bestPlayer, bestRecord = nil, nil
			for player, data in pairs(State.players) do
				for _, record in pairs(data.pads) do
					if record and (not bestRecord or record.income > bestRecord.income) then
						bestPlayer, bestRecord = player, record
					end
				end
			end
			if not bestPlayer or not bestRecord then
				thief.nextAt = os.clock() + 45
				continue
			end

			thief.active = true
			thief.target = bestPlayer
			thief.record = nil
			thief.phase = "toBase"
			-- Spawn at a random map edge.
			local edge = math.random(1, 4)
			local spawnPos = ({
				Vector3.new(-205, 0, math.random(-80, 80)),
				Vector3.new(205, 0, math.random(-80, 80)),
				Vector3.new(math.random(-80, 80), 0, -205),
				Vector3.new(math.random(-80, 80), 0, 205),
			})[edge]
			thief.escapePoint = spawnPos
			placeBot(CFrame.new(spawnPos))
			hooks.notifyAll("MALING BOT terlihat! Dia mengincar base " .. bestPlayer.DisplayName .. "!")

			task.spawn(function()
				if not bestRecord.model then
					State.thief.phase = "escape"
				end
				local padPos = bestRecord.ground.Position
				-- Run to the pad.
				while State.thief.phase == "toBase" do
					local dt = task.wait(0.05)
					if not State.players[bestPlayer] or bestRecord.state ~= "Pad" then
						State.thief.phase = "escape"
						break
					end
					if moveTowards(padPos, Config.ThiefSpeed, dt) < 4 then
						hooks.stealFromPad(bestRecord)
						State.thief.record = bestRecord
						State.thief.phase = "flee"
						hooks.notifyPlayer(bestPlayer, "MALING! Dia mencuri " .. bestRecord.def.name .. " dari base-mu! Kejar dan sentuh dia!")
					end
				end
				-- Flee with the loot (or escape empty-handed after a drop).
				while State.thief.phase == "flee" or State.thief.phase == "escape" do
					local dt = task.wait(0.05)
					local record = State.thief.record
					if record and record.model then
						record.place(botGround * CFrame.new(0, 6.4, 0))
					end
					if moveTowards(State.thief.escapePoint, Config.ThiefSpeed + 4, dt) < 5 then
						break
					end
				end
				-- Resolution at the edge.
				local record = State.thief.record
				if record then
					State.thief.record = nil
					hooks.loseStolen(record)
					if State.players[bestPlayer] then
						hooks.notifyPlayer(bestPlayer, "Maling Bot kabur membawa " .. record.def.name .. "...")
					end
				end
				placeBot(CFrame.new(0, 0, -1000))
				State.thief.active = false
				State.thief.phase = "idle"
				State.thief.target = nil
				State.thief.nextAt = os.clock() + math.random(Config.ThiefMinGapSeconds, Config.ThiefMaxGapSeconds)
			end)
		end
	end)
end

return ThiefBot
