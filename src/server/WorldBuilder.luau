-- Builds the whole 3D world procedurally at server start: the grass, the
-- central lane the wild brainrots wander, four player bases with 8 pads
-- each, the egg shop stall, signs and decorations. No toolbox assets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))
local Factory = require(script.Parent:WaitForChild("BrainrotFactory"))

local WorldBuilder = {}

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = parent
	return p
end

local function sign(parent, name, size, cframe, color, text, textColor, face)
	local board = part(parent, name, size, cframe, color, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Parent = gui
	return board, label
end

local BASE_COLORS = {
	Color3.fromRGB(235, 80, 80),
	Color3.fromRGB(70, 140, 255),
	Color3.fromRGB(80, 200, 110),
	Color3.fromRGB(255, 190, 50),
}
local BASE_POSITIONS = {
	Vector3.new(-100, 0, -100),
	Vector3.new(100, 0, -100),
	Vector3.new(-100, 0, 100),
	Vector3.new(100, 0, 100),
}

local function buildBase(parent, index)
	local center = BASE_POSITIONS[index]
	local color = BASE_COLORS[index]
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = parent

	local platform = part(folder, "Platform", Vector3.new(56, 2, 56), CFrame.new(center.X, 0, center.Z),
		Color3.fromRGB(225, 225, 230), Enum.Material.SmoothPlastic)
	-- Colored rim so each base reads from across the map.
	part(folder, "RimN", Vector3.new(56, 2.6, 1.5), CFrame.new(center.X, 0.3, center.Z - 27.5), color, Enum.Material.Neon)
	part(folder, "RimS", Vector3.new(56, 2.6, 1.5), CFrame.new(center.X, 0.3, center.Z + 27.5), color, Enum.Material.Neon)
	part(folder, "RimE", Vector3.new(1.5, 2.6, 56), CFrame.new(center.X + 27.5, 0.3, center.Z), color, Enum.Material.Neon)
	part(folder, "RimW", Vector3.new(1.5, 2.6, 56), CFrame.new(center.X - 27.5, 0.3, center.Z), color, Enum.Material.Neon)

	-- 8 pads, two rows of four.
	local pads = {}
	local n = 0
	for row = 0, 1 do
		for col = 0, 3 do
			n += 1
			local x = center.X + (col - 1.5) * 12
			local z = center.Z + (row == 0 and -9 or 9)
			local pad = part(folder, "Pad" .. n, Vector3.new(9, 0.6, 9), CFrame.new(x, 1.3, z),
				Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic)
			pad.CanCollide = false
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Top
			gui.Parent = pad
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = color
			label.Text = tostring(n)
			label.Parent = gui
			pads[n] = pad
		end
	end

	-- Sign wall on the side facing away from the map center; its Front face
	-- is turned toward the lane so approaching players can read it.
	local awayZ = center.Z > 0 and 26 or -26
	local _, ownerLabel = sign(folder, "Sign", Vector3.new(30, 8, 1.5),
		CFrame.new(center.X, 6, center.Z + awayZ) * CFrame.Angles(0, center.Z > 0 and math.pi or 0, 0),
		color, "BASE " .. index, Color3.fromRGB(255, 255, 255), Enum.NormalId.Front)
	ownerLabel.Name = "OwnerLabel"

	-- Home beacon: a pillar of light in the base color, visible map-wide.
	local beacon = part(folder, "Beacon", Vector3.new(2.5, 90, 2.5), CFrame.new(center.X, 46, center.Z + awayZ * 0.8),
		color, Enum.Material.Neon)
	beacon.Transparency = 0.55
	beacon.CanCollide = false
	beacon.CanTouch = false
	beacon.CanQuery = false

	-- Rebirth crystal on a corner pedestal, with its prompt.
	local crystalPos = Vector3.new(center.X + 22, 0, center.Z + (center.Z > 0 and -22 or 22))
	part(folder, "Pedestal", Vector3.new(4, 2, 4), CFrame.new(crystalPos.X, 1, crystalPos.Z),
		Color3.fromRGB(90, 90, 100), Enum.Material.Slate)
	local crystal = part(folder, "RebirthCrystal", Vector3.new(2.4, 3.6, 2.4),
		CFrame.new(crystalPos.X, 4, crystalPos.Z) * CFrame.Angles(0, math.rad(45), 0),
		Color3.fromRGB(190, 110, 255), Enum.Material.Neon)
	crystal.CanCollide = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RebirthPrompt"
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Kristal Rebirth"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 12
	prompt.Parent = crystal

	State.bases[index] = {
		center = center,
		platform = platform,
		pads = pads,
		signLabel = ownerLabel,
		crystal = crystal,
		rebirthPrompt = prompt,
		owner = nil,
	}
end

local function buildTree(parent, x, z)
	local trunk = part(parent, "Trunk", Vector3.new(1.6, 5, 1.6), CFrame.new(x, 2.5, z),
		Color3.fromRGB(120, 85, 50), Enum.Material.Wood)
	trunk.Shape = Enum.PartType.Cylinder
	local leafColors = { Color3.fromRGB(70, 170, 80), Color3.fromRGB(90, 190, 90), Color3.fromRGB(60, 150, 110) }
	local leaves = part(parent, "Leaves", Vector3.new(6, 6, 6), CFrame.new(x, 8, z),
		leafColors[math.random(1, #leafColors)], Enum.Material.SmoothPlastic)
	leaves.Shape = Enum.PartType.Ball
	part(parent, "LeavesTop", Vector3.new(4, 4, 4), CFrame.new(x + 1, 11, z - 0.5),
		leafColors[math.random(1, #leafColors)], Enum.Material.SmoothPlastic).Shape = Enum.PartType.Ball
end

function WorldBuilder.Build()
	local world = Instance.new("Folder")
	world.Name = "BrainrotWorld"
	world.Parent = Workspace

	-- Grass.
	part(world, "Ground", Vector3.new(400, 2, 400), CFrame.new(0, -1, 0),
		Color3.fromRGB(105, 190, 90), Enum.Material.Grass)

	-- The central lane, running north-south, where the wild ones wander.
	part(world, "Lane", Vector3.new(36, 0.3, 400), CFrame.new(0, 0.05, 0),
		Color3.fromRGB(85, 88, 98), Enum.Material.Asphalt)
	for z = -192, 192, 16 do
		local dash = part(world, "Dash", Vector3.new(1.2, 0.34, 7), CFrame.new(0, 0.06, z),
			Color3.fromRGB(255, 230, 90), Enum.Material.SmoothPlastic)
		dash.CanCollide = false
	end
	-- Rainbow posts along the lane edges.
	local postColors = {
		Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 180, 60), Color3.fromRGB(255, 240, 90),
		Color3.fromRGB(90, 220, 110), Color3.fromRGB(80, 170, 255), Color3.fromRGB(190, 110, 255),
	}
	local ci = 0
	for z = -176, 176, 32 do
		ci += 1
		for _, side in ipairs({ -1, 1 }) do
			local post = part(world, "LanePost", Vector3.new(1.2, 6, 1.2), CFrame.new(side * 20, 3, z),
				postColors[(ci % #postColors) + 1], Enum.Material.Neon)
			post.CanCollide = false
		end
	end

	-- Welcome sign by the spawn, Front turned toward the lane and spawn.
	sign(world, "WelcomeSign", Vector3.new(34, 9, 1.5), CFrame.new(0, 7, 44) * CFrame.Angles(0, math.pi, 0),
		Color3.fromRGB(255, 120, 160), Config.GameName .. "\nTangkap - Simpan - Kabur dari Tsunami!",
		Color3.fromRGB(255, 255, 255), Enum.NormalId.Front)
	part(world, "SignPostL", Vector3.new(1.5, 12, 1.5), CFrame.new(-14, 3, 44), Color3.fromRGB(90, 90, 100), Enum.Material.Metal)
	part(world, "SignPostR", Vector3.new(1.5, 12, 1.5), CFrame.new(14, 3, 44), Color3.fromRGB(90, 90, 100), Enum.Material.Metal)

	-- Bases.
	for i = 1, 4 do
		buildBase(world, i)
	end

	-- The egg shop stall, east of the lane's middle.
	local shop = Instance.new("Folder")
	shop.Name = "EggShop"
	shop.Parent = world
	local sx, sz = 34, 0
	part(shop, "Counter", Vector3.new(14, 3, 5), CFrame.new(sx, 1.5, sz), Color3.fromRGB(160, 110, 60), Enum.Material.Wood)
	for _, dx in ipairs({ -6.5, 6.5 }) do
		for _, dz in ipairs({ -4, 4 }) do
			part(shop, "Post", Vector3.new(1, 9, 1), CFrame.new(sx + dx, 4.5, sz + dz), Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
		end
	end
	local roof = part(shop, "Roof", Vector3.new(17, 1, 12), CFrame.new(sx, 9.5, sz) * CFrame.Angles(0, 0, math.rad(6)),
		Color3.fromRGB(255, 90, 120), Enum.Material.SmoothPlastic)
	roof.CanCollide = false
	sign(shop, "ShopSign", Vector3.new(15, 3.6, 0.8), CFrame.new(sx - 3, 7.4, sz) * CFrame.Angles(0, -math.pi / 2, 0),
		Color3.fromRGB(255, 190, 50), "TOKO TELUR BRAINROT", Color3.fromRGB(90, 50, 0), Enum.NormalId.Front)
	part(shop, "Pedestal", Vector3.new(4, 2.4, 4), CFrame.new(sx, 1.2, sz + 8), Color3.fromRGB(90, 90, 100), Enum.Material.Slate)
	local displayEgg, placeDisplayEgg = Factory.CreateEgg("Legendary", shop)
	placeDisplayEgg(CFrame.new(sx, 2.4, sz + 8))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyEggPrompt"
	prompt.ActionText = "Beli Telur"
	prompt.ObjectText = string.format("Telur Brainrot - %s Cash", Config.FormatCash(Config.EggPrice))
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.Parent = displayEgg:FindFirstChild("Egg")

	-- Trees and clouds for a sky that is not empty.
	local treeSpots = {
		{ -45, -60 }, { -50, 40 }, { 48, -120 }, { 55, 130 }, { -60, 150 }, { 60, -40 },
		{ -150, -30 }, { 150, 30 }, { -160, 60 }, { 165, -70 }, { -40, -160 }, { 42, 175 },
		{ -170, -160 }, { 175, 165 },
	}
	for _, spot in ipairs(treeSpots) do
		buildTree(world, spot[1], spot[2])
	end
	for i = 1, 7 do
		local cx = math.random(-180, 180)
		local cz = math.random(-180, 180)
		local cloud = part(world, "Cloud", Vector3.new(math.random(18, 30), 2.5, math.random(8, 13)),
			CFrame.new(cx, math.random(52, 68), cz), Color3.fromRGB(250, 250, 255), Enum.Material.SmoothPlastic)
		cloud.CanCollide = false
		cloud.CanTouch = false
		cloud.CanQuery = false
		cloud.Transparency = 0.15
	end

	return {
		shopPrompt = prompt,
		shopEgg = displayEgg,
		shopPosition = Vector3.new(sx, 0, sz + 8),
	}
end

return WorldBuilder
